SET search_path TO kolibri;

-- обязательные: :last :first
-- остальные могут быть пустыми/не заданы (лучше передавать пустые строки)

BEGIN;

WITH p AS (
  INSERT INTO person(last_name, first_name, middle_name, birth_date)
  VALUES (
    :'last',
    :'first',
    NULLIF(:'middle',''),
    CASE WHEN NULLIF(:'birth','') IS NULL THEN NULL ELSE to_date(:'birth','YYYY-MM-DD') END
  )
  RETURNING person_id
)
-- docs + phone + edu + profile делаем от этого person_id
INSERT INTO person_doc(person_id, doc_type, doc_number)
SELECT person_id, 'SNILS', :'snils' FROM p
WHERE NULLIF(:'snils','') IS NOT NULL
ON CONFLICT DO NOTHING;

WITH pid AS (
  SELECT person_id FROM person
  WHERE last_name=:'last' AND first_name=:'first'
  ORDER BY person_id DESC LIMIT 1
)
INSERT INTO person_doc(person_id, doc_type, doc_number)
SELECT person_id, 'INN', :'inn' FROM pid
WHERE NULLIF(:'inn','') IS NOT NULL
ON CONFLICT DO NOTHING;

WITH pid AS (
  SELECT person_id FROM person
  WHERE last_name=:'last' AND first_name=:'first'
  ORDER BY person_id DESC LIMIT 1
)
INSERT INTO person_contact(person_id, contact_type, contact_value, is_primary)
SELECT person_id, 'PHONE', :'phone', true FROM pid
WHERE NULLIF(:'phone','') IS NOT NULL
ON CONFLICT DO NOTHING;

WITH pid AS (
  SELECT person_id FROM person
  WHERE last_name=:'last' AND first_name=:'first'
  ORDER BY person_id DESC LIMIT 1
)
INSERT INTO education(person_id, organization, faculty)
SELECT person_id, NULLIF(:'org',''), NULLIF(:'faculty','')
FROM pid;

WITH pid AS (
  SELECT person_id FROM person
  WHERE last_name=:'last' AND first_name=:'first'
  ORDER BY person_id DESC LIMIT 1
)
INSERT INTO person_profile(person_id, citizenship, last_edu_doc, squad, prof_training, membership)
SELECT person_id,
       NULLIF(:'citizenship',''),
       NULLIF(:'last_edu',''),
       NULLIF(:'squad',''),
       NULLIF(:'prof',''),
       NULLIF(:'member','')
FROM pid
ON CONFLICT (person_id) DO UPDATE SET
  citizenship=EXCLUDED.citizenship,
  last_edu_doc=EXCLUDED.last_edu_doc,
  squad=EXCLUDED.squad,
  prof_training=EXCLUDED.prof_training,
  membership=EXCLUDED.membership;

COMMIT;

SELECT person_id
FROM person
WHERE last_name=:'last' AND first_name=:'first'
ORDER BY person_id DESC
LIMIT 1;
