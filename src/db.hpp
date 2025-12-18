#pragma once
#include <pqxx/pqxx>
#include <string>

class Db {
public:
  explicit Db(const std::string& connStr);
  pqxx::connection& conn();
private:
  pqxx::connection m_conn;
};
