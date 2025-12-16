#include "db.hpp"
#include "repo.hpp"
#include <iostream>
#include <string>
#include <optional>

static std::optional<std::string> readOptional(const std::string& prompt) {
  std::cout << prompt << " (пусто = нет): ";
  std::string s;
  std::getline(std::cin, s);
  if (s.empty()) return std::nullopt;
  return s;
}

int main() {
  try {
    // Поменяй под себя!
    std::string conn =
      "host=localhost port=5432 dbname=kolibri_db user=postgres password=postgres";

    Db db(conn);
    Repo repo(db);

    while (true) {
      std::cout << "\n=== СПО Колибри (БД) ===\n"
                   "1) Добавить человека (ФИО + СНИЛС + ИНН + телефон)\n"
                   "2) Найти ФИО по телефону\n"
                   "3) Найти ИНН по СНИЛС\n"
                   "4) Удалить человека по ID\n"
                   "0) Выход\n"
                   "Выбор: ";

      std::string choice;
      std::getline(std::cin, choice);

      if (choice == "0") break;

      if (choice == "1") {
        std::string last, first, snils, inn, phone;
        std::cout << "Фамилия: "; std::getline(std::cin, last);
        std::cout << "Имя: "; std::getline(std::cin, first);
        auto middle = readOptional("Отчество");
        std::cout << "СНИЛС (пример 123-456-789 00): "; std::getline(std::cin, snils);
        std::cout << "ИНН: "; std::getline(std::cin, inn);
        std::cout << "Телефон (пример +79998887766): "; std::getline(std::cin, phone);

        long id = repo.addPersonWithDocsAndPhone(last, first, middle, snils, inn, phone);
        std::cout << "OK. Добавлен person_id=" << id << "\n";
      }

      else if (choice == "2") {
        std::string phone;
        std::cout << "Телефон: ";
        std::getline(std::cin, phone);

        auto p = repo.findByPhone(phone);
        if (!p) std::cout << "Не найдено\n";
        else {
          std::cout << "Найден: " << p->last << " " << p->first;
          if (p->middle) std::cout << " " << *p->middle;
          std::cout << " (id=" << p->id << ")\n";
        }
      }

      else if (choice == "3") {
        std::string snils;
        std::cout << "СНИЛС: ";
        std::getline(std::cin, snils);

        auto inn = repo.findInnBySnils(snils);
        if (!inn) std::cout << "ИНН не найден\n";
        else std::cout << "ИНН: " << *inn << "\n";
      }

      else if (choice == "4") {
        std::string s;
        std::cout << "person_id: ";
        std::getline(std::cin, s);
        long id = std::stol(s);
        repo.deletePerson(id);
        std::cout << "OK. Удалено (если существовало)\n";
      }

      else {
        std::cout << "Неизвестный пункт\n";
      }
    }

  } catch (const std::exception& e) {
    std::cerr << "Ошибка: " << e.what() << "\n";
    return 1;
  }
  return 0;
}
