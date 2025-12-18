SET search_path TO kolibri;

DELETE FROM person WHERE person_id=:'id';
SELECT 'OK deleted id=' || :'id' AS result;
