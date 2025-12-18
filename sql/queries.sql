-- Набор запросов (для отчёта / демонстрации) — 10 разных целей

-- 1) Все данные по ФИО (LEFT JOIN)
-- параметры: $1 last, $2 first, $3 middle
SELECT
  p.person_id, p.last_name, p.first_name, p.middle_name, p.birth_date,
  pr.citizenship, sn.doc_number AS snils, inn.doc_number AS inn,
  ph.contact_value AS phone, e.organization, e.faculty,
  pr.last_edu_doc, pr.squad, pr.prof_training, pr.membership
FROM kolibri.person p
LEFT JOIN kolibri.person_profile pr ON pr.person_id=p.person_id
LEFT JOIN kolibri.person_doc sn ON sn.person_id=p.person_id AND sn.doc_type='SNILS'
LEFT JOIN kolibri.person_doc inn ON inn.person_id=p.person_id AND inn.doc_type='INN'
LEFT JOIN kolibri.person_contact ph ON ph.person_id=p.person_id AND ph.contact_type='PHONE'
LEFT JOIN kolibri.education e ON e.person_id=p.person_id
WHERE p.last_name=$1 AND p.first_name=$2 AND (($3 IS NULL AND p.middle_name IS NULL) OR p.middle_name=$3);

-- 2) ФИО по телефону (INNER JOIN)
SELECT p.person_id, p.last_name, p.first_name, p.middle_name
FROM kolibri.person_contact c
JOIN kolibri.person p ON p.person_id=c.person_id
WHERE c.contact_type='PHONE' AND c.contact_value=$1;

-- 3) ИНН по СНИЛС (JOIN)
SELECT inn.doc_number AS inn
FROM kolibri.person_doc sn
JOIN kolibri.person_doc inn ON inn.person_id=sn.person_id
WHERE sn.doc_type='SNILS' AND sn.doc_number=$1 AND inn.doc_type='INN';

-- 4) Список последних 5 персон
SELECT person_id, last_name, first_name, middle_name, birth_date
FROM kolibri.person ORDER BY person_id DESC LIMIT 5;

-- 5) Группировка по организации (GROUP BY + COUNT)
SELECT COALESCE(organization,'(не указано)') AS organization, COUNT(*) AS people_count
FROM kolibri.education
GROUP BY COALESCE(organization,'(не указано)')
ORDER BY people_count DESC;

-- 6) Люди, у которых есть и СНИЛС и ИНН (HAVING)
SELECT p.person_id, p.last_name, p.first_name, p.middle_name, COUNT(d.doc_id) AS docs
FROM kolibri.person p
JOIN kolibri.person_doc d ON d.person_id=p.person_id AND d.doc_type IN ('SNILS','INN')
GROUP BY p.person_id, p.last_name, p.first_name, p.middle_name
HAVING COUNT(d.doc_id) >= 2;

-- 7) Поиск дубликатов телефонов (дубликаты по contact_value)
SELECT contact_value, COUNT(*) AS cnt
FROM kolibri.person_contact
WHERE contact_type='PHONE'
GROUP BY contact_value
HAVING COUNT(*) > 1;

-- 8) Подзапрос: люди без документов
SELECT p.person_id, p.last_name, p.first_name
FROM kolibri.person p
WHERE NOT EXISTS (SELECT 1 FROM kolibri.person_doc d WHERE d.person_id=p.person_id);

-- 9) Обновление телефона (пример UPDATE / upsert делается INSERT..ON CONFLICT)
-- 10) Удаление человека (DELETE)
