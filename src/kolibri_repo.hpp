#pragma once
#include "db.hpp"
#include "models.hpp"
#include <optional>
#include <string>

class KolibriRepo {
public:
  explicit KolibriRepo(Db& db) : db_(db) {}

  // твои ключевые кейсы:
  std::optional<Person> findPersonByFio(const std::string& last,
                                       const std::string& first,
                                       const std::optional<std::string>& middle);

  std::optional<Person> findPersonByPhone(const std::string& phone);     // ФИО по телефону
  std::optional<std::string> findInnBySnils(const std::string& snils);    // ИНН по СНИЛС

  long addPerson(const Person& p);     // добавление
  bool deletePerson(long personId);    // удаление

private:
  Db& db_;
};