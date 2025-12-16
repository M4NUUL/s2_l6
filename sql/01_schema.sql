CREATE SCHEMA IF NOT EXISTS kolibri;
SET search_path TO kolibri;

-- Типы
DO $$ BEGIN
  CREATE TYPE doc_type AS ENUM ('SNILS','INN','PASSPORT','OMS','OTHER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE contact_type AS ENUM ('PHONE','EMAIL','TELEGRAM','ADDRESS','OTHER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 1) Люди
CREATE TABLE IF NOT EXISTS person (
  person_id   BIGSERIAL PRIMARY KEY,
  last_name   TEXT NOT NULL,
  first_name  TEXT NOT NULL,
  middle_name TEXT,
  birth_date  DATE,
  gender      CHAR(1) CHECK (gender IN ('M','F')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_person UNIQUE (last_name, first_name, middle_name, birth_date)
);

-- 2) Документы
CREATE TABLE IF NOT EXISTS person_doc (
  doc_id      BIGSERIAL PRIMARY KEY,
  person_id   BIGINT NOT NULL REFERENCES person(person_id) ON DELETE CASCADE,
  doc_type    doc_type NOT NULL,
  doc_number  TEXT NOT NULL,
  issued_by   TEXT,
  issued_date DATE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_doc_global UNIQUE (doc_type, doc_number),
  CONSTRAINT uq_doc_per_person UNIQUE (person_id, doc_type)
);

-- 3) Контакты
CREATE TABLE IF NOT EXISTS person_contact (
  contact_id    BIGSERIAL PRIMARY KEY,
  person_id     BIGINT NOT NULL REFERENCES person(person_id) ON DELETE CASCADE,
  contact_type  contact_type NOT NULL,
  contact_value TEXT NOT NULL,
  is_primary    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_contact_global UNIQUE (contact_type, contact_value)
);

-- 4) Сотрудники
CREATE TABLE IF NOT EXISTS employee (
  employee_id BIGSERIAL PRIMARY KEY,
  full_name   TEXT NOT NULL,
  role_name   TEXT NOT NULL DEFAULT 'operator',
  is_active   BOOLEAN NOT NULL DEFAULT true
);

-- 5) Статусы обращений
CREATE TABLE IF NOT EXISTS ticket_status (
  status_id   SMALLSERIAL PRIMARY KEY,
  status_code TEXT NOT NULL UNIQUE,
  status_name TEXT NOT NULL
);

-- 6) Обращения
CREATE TABLE IF NOT EXISTS ticket (
  ticket_id   BIGSERIAL PRIMARY KEY,
  person_id   BIGINT NOT NULL REFERENCES person(person_id) ON DELETE CASCADE,
  employee_id BIGINT REFERENCES employee(employee_id) ON DELETE SET NULL,
  status_id   SMALLINT NOT NULL REFERENCES ticket_status(status_id),
  title       TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at   TIMESTAMPTZ
);

-- Индексы под быстрый поиск
CREATE INDEX IF NOT EXISTS idx_person_fio
  ON person (last_name, first_name, middle_name);

CREATE INDEX IF NOT EXISTS idx_contact_phone
  ON person_contact (contact_type, contact_value);

CREATE INDEX IF NOT EXISTS idx_doc_type_number
  ON person_doc (doc_type, doc_number);

CREATE INDEX IF NOT EXISTS idx_ticket_person
  ON ticket (person_id);
