SET search_path TO kolibri;

-- 1) Поиск человека по ФИО (пример: 'Иванов','Иван')
SELECT person_id, last_name, first_name, middle_name, birth_date
FROM person
WHERE last_name = 'Иванов' AND first_name = 'Иван';

-- 2) Все данные по ФИО: доки + контакты
SELECT p.person_id, p.last_name, p.first_name, p.middle_name,
       d.doc_type, d.doc_number,
       c.contact_type, c.contact_value
FROM person p
LEFT JOIN person_doc d     ON d.person_id = p.person_id
LEFT JOIN person_contact c ON c.person_id = p.person_id
WHERE p.last_name = 'Иванов' AND p.first_name = 'Иван';

-- 3) По телефону найти ФИО
SELECT p.person_id, p.last_name, p.first_name, p.middle_name
FROM person_contact c
JOIN person p ON p.person_id = c.person_id
WHERE c.contact_type='PHONE' AND c.contact_value='+79998887766';

-- 4) По СНИЛС найти ИНН
SELECT inn.doc_number AS inn
FROM person_doc sn
JOIN person_doc inn ON inn.person_id = sn.person_id
WHERE sn.doc_type='SNILS' AND sn.doc_number='123-456-789 00'
  AND inn.doc_type='INN';

-- 5) Список обращений человека
SELECT t.ticket_id, t.title, s.status_name, t.created_at
FROM ticket t
JOIN ticket_status s ON s.status_id = t.status_id
WHERE t.person_id = 1
ORDER BY t.created_at DESC;

-- 6) Обращения "в работе" по сотруднику
SELECT t.ticket_id, p.last_name, p.first_name, t.title, t.created_at
FROM ticket t
JOIN person p ON p.person_id = t.person_id
JOIN ticket_status s ON s.status_id = t.status_id
WHERE t.employee_id = 1 AND s.status_code='IN_PROGRESS';

-- 7) Сколько обращений по статусам (агрегация)
SELECT s.status_code, s.status_name, COUNT(*) AS cnt
FROM ticket t
JOIN ticket_status s ON s.status_id = t.status_id
GROUP BY s.status_code, s.status_name
ORDER BY cnt DESC;

-- 8) HAVING: статусы, где обращений больше 1
SELECT s.status_code, COUNT(*) AS cnt
FROM ticket t
JOIN ticket_status s ON s.status_id = t.status_id
GROUP BY s.status_code
HAVING COUNT(*) > 1;

-- 9) Дубли телефонов (контроль качества данных)
SELECT contact_value, COUNT(*) AS cnt
FROM person_contact
WHERE contact_type='PHONE'
GROUP BY contact_value
HAVING COUNT(*) > 1;

-- 10) Последнее обращение по каждому человеку (LATERAL)
SELECT p.person_id, p.last_name, p.first_name,
       t.ticket_id, s.status_code, t.created_at
FROM person p
LEFT JOIN LATERAL (
  SELECT *
  FROM ticket
  WHERE person_id = p.person_id
  ORDER BY created_at DESC
  LIMIT 1
) t ON true
LEFT JOIN ticket_status s ON s.status_id = t.status_id
ORDER BY p.person_id;
