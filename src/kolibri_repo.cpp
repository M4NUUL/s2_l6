std::optional<Person> KolibriRepo::findPersonByPhone(const std::string& phone) {
  const std::string sql =
    "SELECT p.person_id, p.last_name, p.first_name, p.middle_name "
    "FROM kolibri.person_contact c "
    "JOIN kolibri.person p ON p.person_id = c.person_id "
    "WHERE c.contact_type = 'PHONE' AND c.contact_value = $1 "
    "LIMIT 1;";

  auto r = db_.execParams(sql, {phone});
  if (r.empty()) return std::nullopt;

  Person p;
  p.id = r[0][0].as<long>();
  p.last = r[0][1].as<std::string>();
  p.first = r[0][2].as<std::string>();
  if (r[0][3].is_null()) p.middle = std::nullopt;
  else p.middle = r[0][3].as<std::string>();
  return p;