-- 1. СОЗДАНИЕ БАЗЫ ДАННЫХ

-- Создание базы данных для интернет-магазина
CREATE DATABASE techshop;

-- Подключение к созданной базе данных
-- (используется в psql)
-- \c techshop


-- 2. СОЗДАНИЕ ТАБЛИЦ

-- 2.1 Таблица категорий товаров
-- Хранит справочник категорий (смартфоны, ноутбуки и т.д.)
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

-- 2.2 Таблица товаров
-- Содержит информацию о товарах магазина
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES categories(category_id),
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    price NUMERIC(12,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- 2.3 Таблица клиентов
-- Хранит информацию о покупателях
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
);

-- 2.4 Таблица заказов
-- Содержит информацию о заказах клиентов
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    created_at TIMESTAMP DEFAULT NOW(),
    status TEXT
);

-- 2.5 Таблица позиций заказов
-- Хранит товары, входящие в каждый заказ
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    qty INT NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    UNIQUE (order_id, product_id)
);


-- 3. ЗАПОЛНЕНИЕ ТАБЛИЦ ТЕСТОВЫМИ ДАННЫМИ

-- 3.1 Добавление категорий товаров
INSERT INTO categories (name)
VALUES
    ('Смартфоны'),
    ('Ноутбуки'),
    ('Планшеты');

-- 3.2 Добавление товаров
INSERT INTO products (category_id, name, brand, price)
VALUES
    (1, 'Galaxy S24', 'Samsung', 89990),
    (1, 'iPhone 15', 'Apple', 109990),
    (2, 'MacBook Air', 'Apple', 149990);

-- 3.3 Добавление клиентов
INSERT INTO customers (full_name, email)
VALUES
    ('Иван Петров', 'ivan@mail.com'),
    ('Пётр Сидоров', 'petr@mail.com');


-- 4. ПРОСМОТР СОДЕРЖИМОГО ТАБЛИЦ (SELECT)

-- Просмотр всех категорий
SELECT * FROM categories;

-- Просмотр всех товаров
SELECT * FROM products;

-- Просмотр всех клиентов
SELECT * FROM customers;

-- Просмотр всех заказов
SELECT * FROM orders;

-- Просмотр всех позиций заказов
SELECT * FROM order_items;


-- 5. ЗАПРОСЫ С СОЕДИНЕНИЕМ ТАБЛИЦ (JOIN)

-- Вывод списка товаров с указанием категории
SELECT
    p.product_id,
    p.name,
    p.brand,
    p.price,
    c.name AS category
FROM products p
JOIN categories c ON c.category_id = p.category_id;

-- Вывод заказов с именами клиентов
SELECT
    o.order_id,
    c.full_name,
    o.created_at,
    o.status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id;


-- 6. СОЗДАНИЕ ЗАКАЗА И РАБОТА С НИМ

-- Создание нового заказа для клиента
INSERT INTO orders (customer_id, status)
VALUES (1, 'new');

-- Добавление товара в заказ
INSERT INTO order_items (order_id, product_id, qty, unit_price)
VALUES (1, 1, 2, 89990);

-- Добавление второго товара в заказ
INSERT INTO order_items (order_id, product_id, qty, unit_price)
VALUES (1, 2, 1, 109990);


-- 7. АГРЕГАТНЫЕ ФУНКЦИИ И ГРУППИРОВКА

-- Подсчёт общей стоимости заказа
SELECT
    SUM(qty * unit_price) AS total_sum
FROM order_items
WHERE order_id = 1;

-- Подсчёт количества товаров в каждой категории
SELECT
    c.name,
    COUNT(p.product_id) AS product_count
FROM categories c
JOIN products p ON p.category_id = c.category_id
GROUP BY c.name;


-- 8. ОБНОВЛЕНИЕ ДАННЫХ (UPDATE)

-- Обновление цены товара
UPDATE products
SET price = 87990
WHERE product_id = 1;


-- 9. УДАЛЕНИЕ ДАННЫХ (DELETE)

-- Удаление заказа
-- Позиции заказа удаляются автоматически (ON DELETE CASCADE)
DELETE FROM orders
WHERE order_id = 1;


-- 10. ПРОСМОТР СПИСКА ТАБЛИЦ (СПРАВОЧНАЯ ИНФОРМАЦИЯ)

-- Получение списка таблиц схемы public
SELECT
    table_schema AS "Schema",
    table_name AS "Name",
    table_type AS "Type"
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 11. 10 ЗАПРОСОВ К БД

-- 1) Вывести все активные товары вместе с названием категории
SELECT
  p.product_id,
  p.name,
  p.brand,
  p.price,
  c.name AS category
FROM products p
JOIN categories c ON c.category_id = p.category_id
WHERE p.is_active = TRUE
ORDER BY c.name, p.price DESC;

-- 2) Найти товары определённого бренда в диапазоне цен
SELECT product_id, name, brand, price
FROM products
WHERE brand = 'Samsung'
  AND price BETWEEN 30000 AND 120000
ORDER BY price;

-- 3) Показать все категории и сколько товаров в каждой (включая пустые категории)
SELECT
  c.category_id,
  c.name AS category,
  COUNT(p.product_id) AS products_count
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY products_count DESC, c.name;

-- 4) Показать категории, где товаров больше 1 (пример HAVING)
SELECT
  c.name AS category,
  COUNT(p.product_id) AS products_count
FROM categories c
JOIN products p ON p.category_id = c.category_id
GROUP BY c.name
HAVING COUNT(p.product_id) > 1
ORDER BY products_count DESC;

-- 5) Показать заказы конкретного клиента (по customer_id)
SELECT
  o.order_id,
  o.created_at,
  o.status,
  c.full_name,
  c.email
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id = 1
ORDER BY o.created_at DESC;

-- 6) Показать позиции заказа: товар, количество, цена и сумма по позиции
SELECT
  oi.order_id,
  p.name AS product,
  oi.qty,
  oi.unit_price,
  (oi.qty * oi.unit_price) AS line_total
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
WHERE oi.order_id = 1
ORDER BY p.name;

-- 7) Посчитать общую стоимость заказа (агрегатная функция SUM)
SELECT
  oi.order_id,
  COALESCE(SUM(oi.qty * oi.unit_price), 0) AS order_total
FROM order_items oi
WHERE oi.order_id = 1
GROUP BY oi.order_id;

-- 8) Показать ТОП-5 товаров по выручке (qty * unit_price) во всех заказах
SELECT
  p.product_id,
  p.name,
  p.brand,
  SUM(oi.qty) AS total_qty,
  SUM(oi.qty * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name, p.brand
ORDER BY revenue DESC
LIMIT 5;

-- 9) Найти клиентов, которые ещё не делали заказов
SELECT
  c.customer_id,
  c.full_name,
  c.email
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- 10) Найти товары, которые дороже средней цены по магазину (подзапрос)
SELECT
  product_id,
  name,
  brand,
  price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;
