#include "kolibri_repo.hpp"

static std::optional<std::string> colOpt(const pqxx::row& r, const char* name) {
  auto f = r[name];
  if (f.is_null()) return std::nullopt;
  return f.c_str();
}

KolibriRepo::KolibriRepo(Db& db) : m_db(db) {}

std::optional<PersonFull> KolibriRepo::findAllByFio(const std::string& last,
                                                    const std::string& first,
                                                    const std::optional<std::string>& middle) {
  pqxx::work tx(m_db.conn());
  pqxx::result res;

  if (middle && !middle->empty()) {
    res = tx.exec_params(R"SQL(
      SELECT
        p.person_id,
        p.last_name, p.first_name, p.middle_name, p.birth_date,
        pr.citizenship,
        sn.doc_number AS snils,
        inn.doc_number AS inn,
        ph.contact_value AS phone,
        e.organization, e.faculty,
        pr.last_edu_doc, pr.squad, pr.prof_training, pr.membership
      FROM kolibri.person p
      LEFT JOIN kolibri.person_profile pr ON pr.person_id=p.person_id
      LEFT JOIN kolibri.person_doc sn ON sn.person_id=p.person_id AND sn.doc_type='SNILS'
      LEFT JOIN kolibri.person_doc inn ON inn.person_id=p.person_id AND inn.doc_type='INN'
      LEFT JOIN kolibri.person_contact ph ON ph.person_id=p.person_id AND ph.contact_type='PHONE'
      LEFT JOIN kolibri.education e ON e.person_id=p.person_id
      WHERE p.last_name=$1 AND p.first_name=$2 AND p.middle_name=$3
      ORDER BY p.person_id DESC
      LIMIT 1;
    )SQL", last, first, *middle);
  } else {
    res = tx.exec_params(R"SQL(
      SELECT
        p.person_id,
        p.last_name, p.first_name, p.middle_name, p.birth_date,
        pr.citizenship,
        sn.doc_number AS snils,
        inn.doc_number AS inn,
        ph.contact_value AS phone,
        e.organization, e.faculty,
        pr.last_edu_doc, pr.squad, pr.prof_training, pr.membership
      FROM kolibri.person p
      LEFT JOIN kolibri.person_profile pr ON pr.person_id=p.person_id
      LEFT JOIN kolibri.person_doc sn ON sn.person_id=p.person_id AND sn.doc_type='SNILS'
      LEFT JOIN kolibri.person_doc inn ON inn.person_id=p.person_id AND inn.doc_type='INN'
      LEFT JOIN kolibri.person_contact ph ON ph.person_id=p.person_id AND ph.contact_type='PHONE'
      LEFT JOIN kolibri.education e ON e.person_id=p.person_id
      WHERE p.last_name=$1 AND p.first_name=$2 AND p.middle_name IS NULL
      ORDER BY p.person_id DESC
      LIMIT 1;
    )SQL", last, first);
  }

  if (res.empty()) return std::nullopt;

  const auto& r = res[0];
  PersonFull out;
  out.person.id = r["person_id"].as<long long>();
  out.person.last = r["last_name"].c_str();
  out.person.first = r["first_name"].c_str();
  out.person.middle = colOpt(r, "middle_name");
  out.person.birth_date = colOpt(r, "birth_date");

  out.citizenship = colOpt(r, "citizenship");
  out.snils = colOpt(r, "snils");
  out.inn = colOpt(r, "inn");
  out.phone = colOpt(r, "phone");
  out.organization = colOpt(r, "organization");
  out.faculty = colOpt(r, "faculty");
  out.last_edu_doc = colOpt(r, "last_edu_doc");
  out.squad = colOpt(r, "squad");
  out.prof_training = colOpt(r, "prof_training");
  out.membership = colOpt(r, "membership");

  return out;
}

std::optional<Person> KolibriRepo::findPersonByPhone(const std::string& phone) {
  pqxx::work tx(m_db.conn());
  auto res = tx.exec_params(R"SQL(
    SELECT p.person_id, p.last_name, p.first_name, p.middle_name, p.birth_date
    FROM kolibri.person_contact c
    JOIN kolibri.person p ON p.person_id=c.person_id
    WHERE c.contact_type='PHONE' AND c.contact_value=$1
    LIMIT 1;
  )SQL", phone);

  if (res.empty()) return std::nullopt;
  const auto& r = res[0];

  Person p;
  p.id = r["person_id"].as<long long>();
  p.last = r["last_name"].c_str();
  p.first = r["first_name"].c_str();
  p.middle = colOpt(r, "middle_name");
  p.birth_date = colOpt(r, "birth_date");
  return p;
}

std::optional<std::string> KolibriRepo::findInnBySnils(const std::string& snils) {
  pqxx::work tx(m_db.conn());
  auto res = tx.exec_params(R"SQL(
    SELECT inn.doc_number AS inn
    FROM kolibri.person_doc sn
    JOIN kolibri.person_doc inn ON inn.person_id=sn.person_id
    WHERE sn.doc_type='SNILS' AND sn.doc_number=$1
      AND inn.doc_type='INN'
    LIMIT 1;
  )SQL", snils);

  if (res.empty()) return std::nullopt;
  return res[0]["inn"].c_str();
}

void KolibriRepo::deletePerson(long long person_id) {
  pqxx::work tx(m_db.conn());
  tx.exec_params("DELETE FROM kolibri.person WHERE person_id=$1;", person_id);
  tx.commit();
}
