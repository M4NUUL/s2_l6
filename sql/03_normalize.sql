SET search_path TO kolibri;

BEGIN;

-- Люди (парсим ФИО и дату)
INSERT INTO person(last_name, first_name, middle_name, birth_date)
SELECT
  split_part(fio,' ',1),
  split_part(fio,' ',2),
  NULLIF(split_part(fio,' ',3),''),
  CASE
    WHEN NULLIF(birth_date_raw,'') IS NULL THEN NULL
    ELSE to_date(birth_date_raw,'MM/DD/YYYY')
  END
FROM person_import
WHERE NULLIF(fio,'') IS NOT NULL
ON CONFLICT DO NOTHING;

-- СНИЛС
INSERT INTO person_doc(person_id, doc_type, doc_number)
SELECT p.person_id, 'SNILS', i.snils
FROM person_import i
JOIN person p
  ON p.last_name = split_part(i.fio,' ',1)
 AND p.first_name = split_part(i.fio,' ',2)
 AND (p.middle_name = NULLIF(split_part(i.fio,' ',3),'') OR (p.middle_name IS NULL AND NULLIF(split_part(i.fio,' ',3),'') IS NULL))
WHERE NULLIF(i.snils,'') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ИНН
INSERT INTO person_doc(person_id, doc_type, doc_number)
SELECT p.person_id, 'INN', i.inn
FROM person_import i
JOIN person p
  ON p.last_name = split_part(i.fio,' ',1)
 AND p.first_name = split_part(i.fio,' ',2)
 AND (p.middle_name = NULLIF(split_part(i.fio,' ',3),'') OR (p.middle_name IS NULL AND NULLIF(split_part(i.fio,' ',3),'') IS NULL))
WHERE NULLIF(i.inn,'') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Телефон
INSERT INTO person_contact(person_id, contact_type, contact_value, is_primary)
SELECT p.person_id, 'PHONE', i.phone, true
FROM person_import i
JOIN person p
  ON p.last_name = split_part(i.fio,' ',1)
 AND p.first_name = split_part(i.fio,' ',2)
 AND (p.middle_name = NULLIF(split_part(i.fio,' ',3),'') OR (p.middle_name IS NULL AND NULLIF(split_part(i.fio,' ',3),'') IS NULL))
WHERE NULLIF(i.phone,'') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Образование
INSERT INTO education(person_id, organization, faculty)
SELECT p.person_id, NULLIF(i.organization,''), NULLIF(i.faculty,'')
FROM person_import i
JOIN person p
  ON p.last_name = split_part(i.fio,' ',1)
 AND p.first_name = split_part(i.fio,' ',2)
 AND (p.middle_name = NULLIF(split_part(i.fio,' ',3),'') OR (p.middle_name IS NULL AND NULLIF(split_part(i.fio,' ',3),'') IS NULL));

-- Профиль (upsert)
INSERT INTO person_profile(person_id, citizenship, last_edu_doc, squad, prof_training, membership)
SELECT p.person_id,
       NULLIF(i.citizenship,''),
       NULLIF(i.last_edu_doc,''),
       NULLIF(i.squad,''),
       NULLIF(i.prof_training,''),
       NULLIF(i.membership,'')
FROM person_import i
JOIN person p
  ON p.last_name = split_part(i.fio,' ',1)
 AND p.first_name = split_part(i.fio,' ',2)
 AND (p.middle_name = NULLIF(split_part(i.fio,' ',3),'') OR (p.middle_name IS NULL AND NULLIF(split_part(i.fio,' ',3),'') IS NULL))
ON CONFLICT (person_id) DO UPDATE SET
  citizenship=EXCLUDED.citizenship,
  last_edu_doc=EXCLUDED.last_edu_doc,
  squad=EXCLUDED.squad,
  prof_training=EXCLUDED.prof_training,
  membership=EXCLUDED.membership;

COMMIT;
