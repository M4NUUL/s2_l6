CREATE SCHEMA IF NOT EXISTS kolibri;
SET search_path TO kolibri;

DO $$ BEGIN
  CREATE TYPE doc_type AS ENUM ('SNILS','INN','PASSPORT','OTHER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE contact_type AS ENUM ('PHONE','EMAIL','OTHER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Люди
CREATE TABLE IF NOT EXISTS person (
  person_id   BIGSERIAL PRIMARY KEY,
  last_name   TEXT NOT NULL,
  first_name  TEXT NOT NULL,
  middle_name TEXT,
  birth_date  DATE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_person UNIQUE (last_name, first_name, middle_name, birth_date)
);

-- Документы
CREATE TABLE IF NOT EXISTS person_doc (
  doc_id     BIGSERIAL PRIMARY KEY,
  person_id  BIGINT NOT NULL REFERENCES person(person_id) ON DELETE CASCADE,
  doc_type   doc_type NOT NULL,
  doc_number TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_doc UNIQUE (doc_type, doc_number),
  CONSTRAINT uq_doc_per_person UNIQUE (person_id, doc_type)
);

-- Контакты (телефон)
CREATE TABLE IF NOT EXISTS person_contact (
  contact_id    BIGSERIAL PRIMARY KEY,
  person_id     BIGINT NOT NULL REFERENCES person(person_id) ON DELETE CASCADE,
  contact_type  contact_type NOT NULL,
  contact_value TEXT NOT NULL,
  is_primary    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_contact UNIQUE (contact_type, contact_value)
);

-- Образование
CREATE TABLE IF NOT EXISTS education (
  education_id BIGSERIAL PRIMARY KEY,
  person_id    BIGINT NOT NULL REFERENCES person(person_id) ON DELETE CASCADE,
  organization TEXT,
  faculty      TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Профиль/прочее из CSV
CREATE TABLE IF NOT EXISTS person_profile (
  person_id     BIGINT PRIMARY KEY REFERENCES person(person_id) ON DELETE CASCADE,
  citizenship   TEXT,
  last_edu_doc  TEXT,
  squad         TEXT,
  prof_training TEXT,
  membership    TEXT
);

-- STAGING под CSV (12 колонок в правильном порядке)
DROP TABLE IF EXISTS person_import;
CREATE TABLE person_import (
  fio             TEXT,
  citizenship      TEXT,
  birth_date_raw   TEXT,   -- MM/DD/YYYY
  organization     TEXT,
  faculty          TEXT,
  snils            TEXT,
  inn              TEXT,
  last_edu_doc     TEXT,
  phone            TEXT,
  squad            TEXT,
  prof_training    TEXT,
  membership       TEXT
);

CREATE INDEX IF NOT EXISTS idx_person_fio ON person(last_name, first_name, middle_name);
CREATE INDEX IF NOT EXISTS idx_doc ON person_doc(doc_type, doc_number);
CREATE INDEX IF NOT EXISTS idx_phone ON person_contact(contact_type, contact_value);
