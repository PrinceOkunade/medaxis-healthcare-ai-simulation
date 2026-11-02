CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS warehouse;


SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'warehouse');
