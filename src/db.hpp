#pragma once
#include <pqxx/pqxx>
#include <string>
#include <vector>

class Db {
public:
  explicit Db(const std::string& connStr);

  pqxx::result query(const std::string& sql);
  void exec(const std::string& sql);

  pqxx::result execParams(const std::string& sql, const std::vector<std::string>& params);

  pqxx::connection& conn() { return conn_; }

private:
  pqxx::connection conn_;
};
