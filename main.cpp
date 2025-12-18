#include <pqxx/pqxx>
#include <iostream>
#include <string>
#include <optional>
#include <cstdlib>

static std::string getEnvOrDefault(const char* key, const std::string& defval) {
    const char* v = std::getenv(key);
    return (v && *v) ? std::string(v) : defval;
}

static int readInt(const std::string& prompt) {
    std::cout << prompt;
    std::string s;
    std::getline(std::cin, s);
    return std::stoi(s);
}

static std::string readStr(const std::string& prompt) {
    std::cout << prompt;
    std::string s;
    std::getline(std::cin, s);
    return s;
}

static void listProducts(pqxx::connection& conn) {
    pqxx::read_transaction tx(conn);
    auto res = tx.exec(
        "SELECT p.product_id, p.name, p.brand, c.name AS category, p.price "
        "FROM products p "
        "JOIN categories c ON c.category_id = p.category_id "
        "WHERE p.is_active = TRUE "
        "ORDER BY p.product_id"
    );

    std::cout << "\n--- Products ---\n";
    for (auto row : res) {
        std::cout
            << "#" << row["product_id"].as<int>()
            << " " << row["name"].c_str()
            << " (" << row["brand"].c_str() << ")"
            << " [" << row["category"].c_str() << "]"
            << " price=" << row["price"].as<double>()
            << "\n";
    }
}

static void createOrder(pqxx::connection& conn) {
    int customerId = readInt("Customer ID: ");
    pqxx::work tx(conn);

    // параметризованный INSERT
    auto res = tx.exec_params(
        "INSERT INTO orders(customer_id, status) VALUES ($1, 'new') RETURNING order_id",
        customerId
    );
    tx.commit();

    int orderId = res[0]["order_id"].as<int>();
    std::cout << "Created order: " << orderId << "\n";
}

static void addItem(pqxx::connection& conn) {
    int orderId = readInt("Order ID: ");
    int productId = readInt("Product ID: ");
    int qty = readInt("Qty: ");
    if (qty <= 0) {
        std::cout << "Qty must be > 0\n";
        return;
    }

    pqxx::work tx(conn);

    // берём текущую цену товара
    auto p = tx.exec_params(
        "SELECT price FROM products WHERE product_id = $1 AND is_active = TRUE",
        productId
    );
    if (p.empty()) {
        std::cout << "Product not found or inactive.\n";
        tx.abort();
        return;
    }
    double price = p[0]["price"].as<double>();

    // UPSERT по (order_id, product_id): если уже есть, увеличиваем qty
    tx.exec_params(
        "INSERT INTO order_items(order_id, product_id, qty, unit_price) "
        "VALUES ($1, $2, $3, $4) "
        "ON CONFLICT (order_id, product_id) "
        "DO UPDATE SET qty = order_items.qty + EXCLUDED.qty",
        orderId, productId, qty, price
    );

    tx.commit();
    std::cout << "Item added.\n";
}

static void showOrderTotal(pqxx::connection& conn) {
    int orderId = readInt("Order ID: ");
    pqxx::read_transaction tx(conn);

    auto res = tx.exec_params(
        "SELECT COALESCE(SUM(qty * unit_price), 0) AS total "
        "FROM order_items WHERE order_id = $1",
        orderId
    );

    double total = res[0]["total"].as<double>();
    std::cout << "Order #" << orderId << " total: " << total << "\n";
}

static void updateProductPrice(pqxx::connection& conn) {
    int productId = readInt("Product ID: ");
    double newPrice = std::stod(readStr("New price: "));
    if (newPrice <= 0) {
        std::cout << "Price must be > 0\n";
        return;
    }

    pqxx::work tx(conn);
    auto res = tx.exec_params(
        "UPDATE products SET price = $1 WHERE product_id = $2",
        newPrice, productId
    );
    tx.commit();

    std::cout << "Updated rows: " << res.affected_rows() << "\n";
}

static void deleteOrder(pqxx::connection& conn) {
    int orderId = readInt("Order ID to delete: ");
    pqxx::work tx(conn);

    // orders -> order_items/payments удалятся каскадно (ON DELETE CASCADE)
    auto res = tx.exec_params("DELETE FROM orders WHERE order_id = $1", orderId);
    tx.commit();

    std::cout << "Deleted orders: " << res.affected_rows() << "\n";
}

int main() {
    try {
        std::string dsn = getEnvOrDefault(
            "DATABASE_URL",
            "postgres://postgres:postgres@localhost:5432/techshop"
        );

        pqxx::connection conn(dsn);

        // проверка подключения
        {
            pqxx::read_transaction tx(conn);
            auto r = tx.exec("SELECT NOW() AS now");
            std::cout << "Connected. Server time: " << r[0]["now"].c_str() << "\n";
        }

        while (true) {
            std::cout << "\n=== TechShop C++ CLI ===\n"
                      << "1) List products\n"
                      << "2) Create order\n"
                      << "3) Add item to order\n"
                      << "4) Show order total\n"
                      << "5) Update product price (UPDATE)\n"
                      << "6) Delete order (DELETE)\n"
                      << "0) Exit\n";

            std::string choice = readStr("Choose: ");
            if (choice == "1") listProducts(conn);
            else if (choice == "2") createOrder(conn);
            else if (choice == "3") addItem(conn);
            else if (choice == "4") showOrderTotal(conn);
            else if (choice == "5") updateProductPrice(conn);
            else if (choice == "6") deleteOrder(conn);
            else if (choice == "0") break;
            else std::cout << "Unknown option\n";
        }

        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << "\n";
        return 1;
    }
}
