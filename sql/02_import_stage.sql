SET search_path TO kolibri;

TRUNCATE person_import;

-- ВАЖНО:
-- 1) CSV должен быть с HEADER
-- 2) Разделитель по умолчанию запятая. Если у тебя ; — поменяй DELIMITER.

\copy kolibri.person_import FROM :'csv' CSV HEADER
