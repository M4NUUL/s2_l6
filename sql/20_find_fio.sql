SET search_path TO kolibri;

SELECT
  p.person_id,
  p.last_name, p.first_name, p.middle_name, p.birth_date,
  pr.citizenship,
  sn.doc_number AS snils,
  inn.doc_number AS inn,
  ph.contact_value AS phone,
  e.organization, e.faculty,
  pr.last_edu_doc, pr.squad, pr.prof_training, pr.membership
FROM person p
LEFT JOIN person_profile pr ON pr.person_id=p.person_id
LEFT JOIN person_doc sn ON sn.person_id=p.person_id AND sn.doc_type='SNILS'
LEFT JOIN person_doc inn ON inn.person_id=p.person_id AND inn.doc_type='INN'
LEFT JOIN person_contact ph ON ph.person_id=p.person_id AND ph.contact_type='PHONE'
LEFT JOIN education e ON e.person_id=p.person_id
WHERE p.last_name=:'last'
  AND p.first_name=:'first'
  AND ( (NULLIF(:'middle','') IS NULL AND p.middle_name IS NULL) OR p.middle_name=:'middle' )
ORDER BY p.person_id DESC;
