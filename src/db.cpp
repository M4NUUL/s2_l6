#include "db.hpp"
#include <stdexcept>

Db::Db(const std::string& connStr) : conn_(connStr) {
  if (!conn_.is_open()) {
    throw std::runtime_error("PostgreSQL connection failed");
  }
}

pqxx::result Db::query(const std::string& sql) {
  pqxx::work tx(conn_);
  auto r = tx.exec(sql);
  tx.commit();
  return r;
}

void Db::exec(const std::string& sql) {
  pqxx::work tx(conn_);
  tx.exec(sql);
  tx.commit();
}

pqxx::result Db::execParams(const std::string& sql, const std::vector<std::string>& params) {
  pqxx::work tx(conn_);
  pqxx::params p;
  for (const auto& v : params) p.append(v);
  auto r = tx.exec_params(sql, p);
  tx.commit();
  return r;
}
