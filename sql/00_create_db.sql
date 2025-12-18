-- Создаётся под superuser postgres
-- Если роль m4nuul не создана — создай:
--   sudo -u postgres createuser m4nuul
--   sudo -u postgres psql -c "ALTER USER m4nuul WITH PASSWORD 'm4nuul';"

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname='kolibri_db') THEN
    CREATE DATABASE kolibri_db;
  END IF;
END$$;

GRANT ALL PRIVILEGES ON DATABASE kolibri_db TO m4nuul;
