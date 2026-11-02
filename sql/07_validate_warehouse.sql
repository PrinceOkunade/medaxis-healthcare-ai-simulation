
-- Check patient consistency across clinical fact tables

SELECT
    'lab_results' AS table_name,
    COUNT(*) AS patient_mismatches
FROM warehouse.fact_lab_result l
JOIN warehouse.fact_encounter e
    ON l.encounter_key = e.encounter_key
WHERE l.patient_key <> e.patient_key

UNION ALL

SELECT
    'observations',
    COUNT(*)
FROM warehouse.fact_observation o
JOIN warehouse.fact_encounter e
    ON o.encounter_key = e.encounter_key
WHERE o.patient_key <> e.patient_key

UNION ALL

SELECT
    'medications',
    COUNT(*)
FROM warehouse.fact_medication m
JOIN warehouse.fact_encounter e
    ON m.encounter_key = e.encounter_key
WHERE m.patient_key <> e.patient_key;


-- Validate secondary diagnosis bridge table

SELECT
    COUNT(*) AS total_links,
    COUNT(DISTINCT encounter_key)
        AS encounters_with_secondary_diagnoses,
    COUNT(DISTINCT diagnosis_key)
        AS unique_secondary_diagnoses
FROM warehouse.bridge_encounter_secondary_diagnosis;


-- Verify secondary diagnosis links against raw data

WITH raw_codes AS (
    SELECT DISTINCT
        a."ENCOUNTER_ID",
        TRIM(c.code) AS icd10_code
    FROM raw.admissions a
    CROSS JOIN LATERAL
        regexp_split_to_table(
            COALESCE(a."ICD10_SEC", ''),
            '[|,]'
        ) AS c(code)
    WHERE TRIM(c.code) <> ''
),
warehouse_codes AS (
    SELECT
        e.encounter_id,
        d.icd10_code
    FROM warehouse.bridge_encounter_secondary_diagnosis b
    JOIN warehouse.fact_encounter e
        ON b.encounter_key = e.encounter_key
    JOIN warehouse.dim_diagnosis d
        ON b.diagnosis_key = d.diagnosis_key
)
SELECT
    COUNT(*) AS raw_links_not_in_warehouse
FROM (
    SELECT *
    FROM raw_codes

    EXCEPT

    SELECT *
    FROM warehouse_codes
) missing;



-- Final warehouse record reconciliation

SELECT
    'dim_patient' AS table_name,
    COUNT(*) AS total_records
FROM warehouse.dim_patient

UNION ALL
SELECT 'dim_hospital', COUNT(*)
FROM warehouse.dim_hospital

UNION ALL
SELECT 'dim_diagnosis', COUNT(*)
FROM warehouse.dim_diagnosis

UNION ALL
SELECT 'dim_date', COUNT(*)
FROM warehouse.dim_date

UNION ALL
SELECT 'fact_encounter', COUNT(*)
FROM warehouse.fact_encounter

UNION ALL
SELECT 'fact_lab_result', COUNT(*)
FROM warehouse.fact_lab_result

UNION ALL
SELECT 'fact_observation', COUNT(*)
FROM warehouse.fact_observation

UNION ALL
SELECT 'fact_medication', COUNT(*)
FROM warehouse.fact_medication

ORDER BY table_name;


-- Final validation of encounter data quality

SELECT
    data_quality_flag,
    COUNT(*) AS total_encounters
FROM warehouse.fact_encounter
GROUP BY data_quality_flag
ORDER BY total_encounters DESC;


-- Validate patient-encounter consistency

SELECT
    'lab_results' AS table_name,
    COUNT(*) AS patient_mismatches
FROM warehouse.fact_lab_result l
JOIN warehouse.fact_encounter e
    ON l.encounter_key = e.encounter_key
WHERE l.patient_key <> e.patient_key

UNION ALL

SELECT
    'observations',
    COUNT(*)
FROM warehouse.fact_observation o
JOIN warehouse.fact_encounter e
    ON o.encounter_key = e.encounter_key
WHERE o.patient_key <> e.patient_key

UNION ALL

SELECT
    'medications',
    COUNT(*)
FROM warehouse.fact_medication m
JOIN warehouse.fact_encounter e
    ON m.encounter_key = e.encounter_key
WHERE m.patient_key <> e.patient_key;


-- Final business key and modelling eligibility checks

SELECT
    (SELECT COUNT(*) - COUNT(DISTINCT patient_id)
     FROM warehouse.dim_patient)
        AS duplicate_patient_ids,

    (SELECT COUNT(*) - COUNT(DISTINCT encounter_id)
     FROM warehouse.fact_encounter)
        AS duplicate_encounter_ids,

    (SELECT COUNT(*)
     FROM warehouse.fact_encounter e
     JOIN warehouse.dim_hospital h
       ON e.hospital_key = h.hospital_key
     WHERE h.site_id = 'MER005'
       AND e.is_acute_model_eligible = TRUE)
        AS mer005_incorrectly_eligible;


