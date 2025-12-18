#include <pqxx/pqxx>

#include <cstdlib>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

static std::string envOr(const char* key, const std::string& defval) {
  const char* v = std::getenv(key);
  return (v && *v) ? std::string(v) : defval;
}

static std::string readLine(const std::string& prompt) {
  std::cout << prompt;
  std::string s;
  std::getline(std::cin, s);
  return s;
}

static std::optional<std::string> readOpt(const std::string& prompt) {
  std::string s = readLine(prompt + " (Enter = пусто): ");
  if (s.empty()) return std::nullopt;
  return s;
}

static long long readId(const std::string& prompt) {
  return std::stoll(readLine(prompt));
}

static void printRow(const pqxx::row& r) {
  for (pqxx::row::size_type i = 0; i < r.size(); ++i) {
    if (i) std::cout << " | ";
    if (r[i].is_null()) std::cout << "NULL";
    else std::cout << r[i].c_str();
  }
  std::cout << "\n";
}


static std::string buildConnStr() {
  // Важно: по умолчанию подключаемся через unix-socket (без host),
  // чтобы не упираться в password auth на -h localhost.
  // Можно переопределить переменными окружения:
  //   PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
  const std::string db   = envOr("PGDATABASE", "kolibri_db");
  const std::string user = envOr("PGUSER",     "m4nuul");
  const std::string host = envOr("PGHOST",     "");          // пусто => socket
  const std::string port = envOr("PGPORT",     "5432");
  const std::string pass = envOr("PGPASSWORD", "");

  std::string cs;
  cs += "dbname=" + db + " user=" + user;
  if (!host.empty()) cs += " host=" + host;
  if (!port.empty()) cs += " port=" + port;
  if (!pass.empty()) cs += " password=" + pass;
  return cs;
}

/*
  === Функционал (ЛР6) ===
  1) Добавление данных (person + docs + phone + edu + profile)
  2) Удаление данных (по person_id, каскадно)
  3) Поиск всех данных по ФИО
  4) Поиск ФИО по телефону
  5) Поиск ИНН по СНИЛС
  6) Обновление телефона
  7) Список последних N персон
  8) Пример GROUP BY + агрегатная функция
  9) Пример JOIN (несколько)
  10) Пример подзапроса / HAVING
*/

static void addPerson(pqxx::connection& conn) {
  std::string last  = readLine("Фамилия: ");
  std::string first = readLine("Имя: ");
  auto middle = readOpt("Отчество");
  auto birth  = readOpt("Дата рождения (YYYY-MM-DD)");
  auto citizenship = readOpt("Гражданство");
  auto org = readOpt("Организация (ВУЗ)");
  auto faculty = readOpt("Факультет/институт");
  auto snils = readOpt("СНИЛС");
  auto inn = readOpt("ИНН");
  auto phone = readOpt("Телефон");
  auto lastEdu = readOpt("Последний документ об образовании");
  auto squad = readOpt("Отряд");
  auto prof = readOpt("Профобучение");
  auto member = readOpt("Членский");

  pqxx::work tx(conn);

  pqxx::params p;
  p.append(last);
  p.append(first);
  if (middle) p.append(*middle); else p.append();
  if (birth)  p.append(*birth);  else p.append();

  auto r = tx.exec_params(
    "INSERT INTO kolibri.person(last_name, first_name, middle_name, birth_date) "
    "VALUES ($1,$2,$3,$4) RETURNING person_id;",
    p
  );
  long long personId = r[0][0].as<long long>();

  if (snils && !snils->empty()) {
    tx.exec_params(
      "INSERT INTO kolibri.person_doc(person_id, doc_type, doc_number) "
      "VALUES ($1,'SNILS',$2) ON CONFLICT DO NOTHING;",
      personId, *snils
    );
  }
  if (inn && !inn->empty()) {
    tx.exec_params(
      "INSERT INTO kolibri.person_doc(person_id, doc_type, doc_number) "
      "VALUES ($1,'INN',$2) ON CONFLICT DO NOTHING;",
      personId, *inn
    );
  }
  if (phone && !phone->empty()) {
    tx.exec_params(
      "INSERT INTO kolibri.person_contact(person_id, contact_type, contact_value, is_primary) "
      "VALUES ($1,'PHONE',$2,true) "
      "ON CONFLICT (contact_type, contact_value) DO UPDATE SET person_id=EXCLUDED.person_id, is_primary=true;",
      personId, *phone
    );
  }

  pqxx::params edu;
  edu.append(personId);
  if (org) edu.append(*org); else edu.append();
  if (faculty) edu.append(*faculty); else edu.append();
  tx.exec_params(
    "INSERT INTO kolibri.education(person_id, organization, faculty) VALUES ($1,$2,$3);",
    edu
  );

  pqxx::params profp;
  profp.append(personId);
  if (citizenship) profp.append(*citizenship); else profp.append();
  if (lastEdu)     profp.append(*lastEdu);     else profp.append();
  if (squad)       profp.append(*squad);       else profp.append();
  if (prof)        profp.append(*prof);        else profp.append();
  if (member)      profp.append(*member);      else profp.append();

  tx.exec_params(
    "INSERT INTO kolibri.person_profile(person_id, citizenship, last_edu_doc, squad, prof_training, membership) "
    "VALUES ($1,$2,$3,$4,$5,$6) "
    "ON CONFLICT (person_id) DO UPDATE SET "
    "citizenship=EXCLUDED.citizenship, "
    "last_edu_doc=EXCLUDED.last_edu_doc, "
    "squad=EXCLUDED.squad, "
    "prof_training=EXCLUDED.prof_training, "
    "membership=EXCLUDED.membership;",
    profp
  );

  tx.commit();
  std::cout << "OK. Добавлен person_id=" << personId << "\n";
}

static void findAllByFio(pqxx::connection& conn) {
  std::string last  = readLine("Фамилия: ");
  std::string first = readLine("Имя: ");
  auto middle = readOpt("Отчество");

  pqxx::read_transaction tx(conn);

  pqxx::params p;
  p.append(last);
  p.append(first);
  if (middle) p.append(*middle); else p.append();

  auto res = tx.exec_params(
    "SELECT "
    "  p.person_id, p.last_name, p.first_name, p.middle_name, p.birth_date, "
    "  pr.citizenship, "
    "  sn.doc_number AS snils, "
    "  inn.doc_number AS inn, "
    "  ph.contact_value AS phone, "
    "  e.organization, e.faculty, "
    "  pr.last_edu_doc, pr.squad, pr.prof_training, pr.membership "
    "FROM kolibri.person p "
    "LEFT JOIN kolibri.person_profile pr ON pr.person_id=p.person_id "
    "LEFT JOIN kolibri.person_doc sn ON sn.person_id=p.person_id AND sn.doc_type='SNILS' "
    "LEFT JOIN kolibri.person_doc inn ON inn.person_id=p.person_id AND inn.doc_type='INN' "
    "LEFT JOIN kolibri.person_contact ph ON ph.person_id=p.person_id AND ph.contact_type='PHONE' "
    "LEFT JOIN kolibri.education e ON e.person_id=p.person_id "
    "WHERE p.last_name=$1 AND p.first_name=$2 "
    "  AND ( ($3 IS NULL AND p.middle_name IS NULL) OR p.middle_name=$3 ) "
    "ORDER BY p.person_id DESC;",
    p
  );

  if (res.empty()) {
    std::cout << "Не найдено\n";
    return;
  }
  for (const auto& row : res) printRow(row);
}

static void findFioByPhone(pqxx::connection& conn) {
  std::string phone = readLine("Телефон: ");
  pqxx::read_transaction tx(conn);
  auto res = tx.exec_params(
    "SELECT p.person_id, p.last_name, p.first_name, p.middle_name "
    "FROM kolibri.person_contact c "
    "JOIN kolibri.person p ON p.person_id=c.person_id "
    "WHERE c.contact_type='PHONE' AND c.contact_value=$1;",
    phone
  );
  if (res.empty()) {
    std::cout << "Не найдено\n";
    return;
  }
  for (const auto& row : res) printRow(row);
}

static void findInnBySnils(pqxx::connection& conn) {
  std::string snils = readLine("СНИЛС: ");
  pqxx::read_transaction tx(conn);
  auto res = tx.exec_params(
    "SELECT inn.doc_number AS inn "
    "FROM kolibri.person_doc sn "
    "JOIN kolibri.person_doc inn ON inn.person_id=sn.person_id "
    "WHERE sn.doc_type='SNILS' AND sn.doc_number=$1 AND inn.doc_type='INN';",
    snils
  );
  if (res.empty()) {
    std::cout << "ИНН не найден\n";
    return;
  }
  for (const auto& row : res) printRow(row);
}

static void updatePhone(pqxx::connection& conn) {
  long long id = readId("person_id: ");
  std::string newPhone = readLine("Новый телефон: ");

  pqxx::work tx(conn);
  auto res = tx.exec_params(
    "INSERT INTO kolibri.person_contact(person_id, contact_type, contact_value, is_primary) "
    "VALUES ($1,'PHONE',$2,true) "
    "ON CONFLICT (contact_type, contact_value) DO UPDATE SET person_id=EXCLUDED.person_id, is_primary=true;",
    id, newPhone
  );
  tx.commit();
  std::cout << "OK. Обновлено/добавлено: " << res.affected_rows() << "\n";
}

static void deletePerson(pqxx::connection& conn) {
  long long id = readId("person_id для удаления: ");
  pqxx::work tx(conn);
  auto res = tx.exec_params("DELETE FROM kolibri.person WHERE person_id=$1;", id);
  tx.commit();
  std::cout << "OK. Удалено персон: " << res.affected_rows() << "\n";
}

static void listPersons(pqxx::connection& conn) {
  long long n = readId("Сколько строк вывести (например 5): ");
  pqxx::read_transaction tx(conn);
  auto res = tx.exec_params(
    "SELECT person_id, last_name, first_name, middle_name, birth_date "
    "FROM kolibri.person ORDER BY person_id DESC LIMIT $1;",
    n
  );
  for (const auto& row : res) printRow(row);
}

static void groupByOrganization(pqxx::connection& conn) {
  // Пример GROUP BY + COUNT
  pqxx::read_transaction tx(conn);
  auto res = tx.exec(
    "SELECT COALESCE(e.organization,'(не указано)') AS organization, COUNT(*) AS people_count "
    "FROM kolibri.education e "
    "GROUP BY COALESCE(e.organization,'(не указано)') "
    "ORDER BY people_count DESC, organization ASC;"
  );
  for (const auto& row : res) printRow(row);
}

static void peopleWithDocs(pqxx::connection& conn) {
  // Пример подзапроса + HAVING: люди у которых есть и СНИЛС и ИНН
  pqxx::read_transaction tx(conn);
  auto res = tx.exec(
    "SELECT p.person_id, p.last_name, p.first_name, p.middle_name, COUNT(d.doc_id) AS docs "
    "FROM kolibri.person p "
    "JOIN kolibri.person_doc d ON d.person_id=p.person_id AND d.doc_type IN ('SNILS','INN') "
    "GROUP BY p.person_id, p.last_name, p.first_name, p.middle_name "
    "HAVING COUNT(d.doc_id) >= 2 "
    "ORDER BY p.person_id DESC;"
  );
  for (const auto& row : res) printRow(row);
}

int main() {
  try {
    pqxx::connection conn(buildConnStr());

    std::cout << "Connected as: " << conn.username() << "\n";
    while (true) {
      std::cout
        << "\n=== СПО Колибри (PostgreSQL + C++) ===\n"
        << "1) Добавить человека\n"
        << "2) Найти все данные по ФИО\n"
        << "3) Найти ФИО по телефону\n"
        << "4) Найти ИНН по СНИЛС\n"
        << "5) Обновить телефон по person_id\n"
        << "6) Удалить человека по person_id\n"
        << "7) Показать последние N персон\n"
        << "8) GROUP BY организация (агрегация)\n"
        << "9) Люди у которых есть СНИЛС и ИНН (HAVING)\n"
        << "0) Выход\n"
        << "Выбор: ";

      std::string choice;
      std::getline(std::cin, choice);

      if (choice == "0") break;
      else if (choice == "1") addPerson(conn);
      else if (choice == "2") findAllByFio(conn);
      else if (choice == "3") findFioByPhone(conn);
      else if (choice == "4") findInnBySnils(conn);
      else if (choice == "5") updatePhone(conn);
      else if (choice == "6") deletePerson(conn);
      else if (choice == "7") listPersons(conn);
      else if (choice == "8") groupByOrganization(conn);
      else if (choice == "9") peopleWithDocs(conn);
      else std::cout << "Неизвестная команда\n";
    }
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "Fatal error: " << e.what() << "\n";
    return 1;
  }
}
