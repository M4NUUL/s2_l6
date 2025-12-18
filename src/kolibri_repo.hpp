#pragma once
#include "db.hpp"
#include <optional>
#include <string>

struct Person {
  long long id{};
  std::string last;
  std::string first;
  std::optional<std::string> middle;
  std::optional<std::string> birth_date;
};

struct PersonFull {
  Person person;
  std::optional<std::string> citizenship;
  std::optional<std::string> snils;
  std::optional<std::string> inn;
  std::optional<std::string> phone;
  std::optional<std::string> organization;
  std::optional<std::string> faculty;
  std::optional<std::string> last_edu_doc;
  std::optional<std::string> squad;
  std::optional<std::string> prof_training;
  std::optional<std::string> membership;
};

class KolibriRepo {
public:
  explicit KolibriRepo(Db& db);

  std::optional<PersonFull> findAllByFio(const std::string& last,
                                        const std::string& first,
                                        const std::optional<std::string>& middle);

  std::optional<Person> findPersonByPhone(const std::string& phone);
  std::optional<std::string> findInnBySnils(const std::string& snils);

  void deletePerson(long long person_id);

private:
  Db& m_db;
};
