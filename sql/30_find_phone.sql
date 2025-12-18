SET search_path TO kolibri;

SELECT p.person_id, p.last_name, p.first_name, p.middle_name
FROM person_contact c
JOIN person p ON p.person_id=c.person_id
WHERE c.contact_type='PHONE' AND c.contact_value=:'phone';
