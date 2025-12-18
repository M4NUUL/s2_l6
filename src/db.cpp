#include "db.hpp"

Db::Db(const std::string& connStr) : m_conn(connStr) {}

pqxx::connection& Db::conn() { return m_conn; }