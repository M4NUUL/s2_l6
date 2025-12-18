CREATE SCHEMA IF NOT EXISTS kolibri;

DO $$ BEGIN
  CREATE TYPE kolibri.doc_type AS ENUM ('SNILS','INN','PASSPORT','OTHER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE kolibri.contact_type AS ENUM ('PHONE','EMAIL','OTHER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS kolibri.person (
  person_id   BIGSERIAL PRIMARY KEY,
  last_name   TEXT NOT NULL,
  first_name  TEXT NOT NULL,
  middle_name TEXT,
  birth_date  DATE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS kolibri.person_doc (
  doc_id     BIGSERIAL PRIMARY KEY,
  person_id  BIGINT NOT NULL REFERENCES kolibri.person(person_id) ON DELETE CASCADE,
  doc_type   kolibri.doc_type NOT NULL,
  doc_number TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_doc UNIQUE (doc_type, doc_number),
  CONSTRAINT uq_doc_per_person UNIQUE (person_id, doc_type)
);

CREATE TABLE IF NOT EXISTS kolibri.person_contact (
  contact_id    BIGSERIAL PRIMARY KEY,
  person_id     BIGINT NOT NULL REFERENCES kolibri.person(person_id) ON DELETE CASCADE,
  contact_type  kolibri.contact_type NOT NULL,
  contact_value TEXT NOT NULL,
  is_primary    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_contact UNIQUE (contact_type, contact_value)
);

CREATE TABLE IF NOT EXISTS kolibri.education (
  education_id BIGSERIAL PRIMARY KEY,
  person_id    BIGINT NOT NULL REFERENCES kolibri.person(person_id) ON DELETE CASCADE,
  organization TEXT,
  faculty      TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS kolibri.person_profile (
  person_id     BIGINT PRIMARY KEY REFERENCES kolibri.person(person_id) ON DELETE CASCADE,
  citizenship   TEXT,
  last_edu_doc  TEXT,
  squad         TEXT,
  prof_training TEXT,
  membership    TEXT
);

-- вспомогательные индексы
CREATE INDEX IF NOT EXISTS idx_person_name ON kolibri.person(last_name, first_name, middle_name);
CREATE INDEX IF NOT EXISTS idx_doc_lookup ON kolibri.person_doc(doc_type, doc_number);
CREATE INDEX IF NOT EXISTS idx_phone_lookup ON kolibri.person_contact(contact_type, contact_value);
