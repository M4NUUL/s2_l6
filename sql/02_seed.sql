SET search_path TO kolibri;

INSERT INTO ticket_status(status_code, status_name)
VALUES
 ('NEW','Новое'),
 ('IN_PROGRESS','В работе'),
 ('DONE','Закрыто'),
 ('REJECTED','Отклонено')
ON CONFLICT (status_code) DO NOTHING;

INSERT INTO employee(full_name, role_name, is_active)
VALUES
 ('Иванов Иван Иванович','operator', true),
 ('Петров Пётр Петрович','manager', true)
ON CONFLICT DO NOTHING;
