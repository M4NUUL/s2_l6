SET search_path TO kolibri;

SELECT inn.doc_number AS inn
FROM person_doc sn
JOIN person_doc inn ON inn.person_id=sn.person_id
WHERE sn.doc_type='SNILS'
  AND sn.doc_number=:'snils'
  AND inn.doc_type='INN';
