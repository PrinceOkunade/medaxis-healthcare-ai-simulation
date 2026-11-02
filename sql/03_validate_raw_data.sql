
-- Check duplicate patient IDs
SELECT
    'patients' AS table_name,
    COUNT(*) AS total_records,
    COUNT(DISTINCT "PATIENT_ID") AS unique_records,
    COUNT(*) - COUNT(DISTINCT "PATIENT_ID")
        AS duplicate_records
FROM raw.patients

UNION ALL

-- Check duplicate encounter IDs
SELECT
    'admissions',
    COUNT(*),
    COUNT(DISTINCT "ENCOUNTER_ID"),
    COUNT(*) - COUNT(DISTINCT "ENCOUNTER_ID")
FROM raw.admissions;


-- 6. Check impossible hospital admission dates

SELECT COUNT(*) AS invalid_admission_dates
FROM raw.admissions
WHERE "ADMISSION_DATE" > "DISCHARGE_DATE";


-- 7. Check length-of-stay inconsistencies

SELECT COUNT(*) AS los_mismatches
FROM raw.admissions
WHERE "ADMISSION_DATE" IS NOT NULL
  AND "DISCHARGE_DATE" IS NOT NULL
  AND "LOS_DAYS" IS DISTINCT FROM
      ("DISCHARGE_DATE" - "ADMISSION_DATE");


-- 8. Check invalid medication dates

SELECT COUNT(*) AS invalid_medication_dates
FROM raw.medications
WHERE "END_DATE" < "START_DATE";


-- 9. Check secondary diagnosis delimiters

SELECT
    COUNT(*) FILTER (
        WHERE "ICD10_SEC" LIKE '%|%'
    ) AS pipe_delimited,

    COUNT(*) FILTER (
        WHERE "ICD10_SEC" LIKE '%,%'
    ) AS comma_delimited
FROM raw.admissions;


-- 10. Check admissions referencing missing patients

SELECT COUNT(*) AS orphan_admissions
FROM raw.admissions a
LEFT JOIN raw.patients p
    ON a."PATIENT_ID" = p."PATIENT_ID"
WHERE p."PATIENT_ID" IS NULL;


-- 11. Check orphan records in clinical datasets

SELECT
    'lab_results' AS table_name,
    COUNT(*) AS orphan_records
FROM raw.lab_results l
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.admissions a
    WHERE a."ENCOUNTER_ID" = l."ENCOUNTER_ID"
)

UNION ALL

SELECT
    'medications',
    COUNT(*)
FROM raw.medications m
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.admissions a
    WHERE a."ENCOUNTER_ID" = m."ENCOUNTER_ID"
)

UNION ALL

SELECT
    'observations',
    COUNT(*)
FROM raw.observations o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.admissions a
    WHERE a."ENCOUNTER_ID" = o."ENCOUNTER_ID"
);


-- Validate encounters excluded from acute modelling

SELECT
    CASE
        WHEN h.site_id = 'MER005'
            THEN 'MER005 - Rehabilitation site'
        WHEN f.admission_date IS NULL
            THEN 'Missing admission date'
        WHEN f.discharge_date IS NULL
            THEN 'Missing discharge date'
        WHEN f.admission_date > f.discharge_date
            THEN 'Invalid date order'
        ELSE 'Other'
    END AS exclusion_reason,

    COUNT(*) AS total_encounters

FROM warehouse.fact_encounter f

JOIN warehouse.dim_hospital h
    ON f.hospital_key = h.hospital_key

WHERE f.is_acute_model_eligible = FALSE

GROUP BY 1
ORDER BY total_encounters DESC;


-- Verify laboratory results fact table

SELECT
    COUNT(*) AS total_lab_results,
    COUNT(DISTINCT lab_id) AS unique_lab_results,
    COUNT(*) FILTER (
        WHERE result_date_key IS NULL
    ) AS missing_date_keys
FROM warehouse.fact_lab_result;



-- Verify observation fact table

SELECT
    COUNT(*) AS total_observations,
    COUNT(DISTINCT observation_id) AS unique_observations,
    COUNT(*) FILTER (
        WHERE observation_date_key IS NULL
    ) AS missing_date_keys
FROM warehouse.fact_observation;


-- Verify medication fact table

SELECT
    COUNT(*) AS total_medications,
    COUNT(DISTINCT medication_id) AS unique_medications,

    COUNT(*) FILTER (
        WHERE start_date_key IS NULL
    ) AS missing_start_date_keys,

    COUNT(*) FILTER (
        WHERE end_date_key IS NULL
    ) AS missing_end_date_keys

FROM warehouse.fact_medication;


-- Investigate missing medication end-date keys

SELECT
    CASE
        WHEN m."END_DATE" IS NULL
            THEN 'Missing source end date'

        WHEN d.date_key IS NULL
            THEN 'Date not found in dim_date'

        ELSE 'Other'
    END AS missing_reason,

    COUNT(*) AS total_medications

FROM warehouse.fact_medication f

JOIN raw.medications m
    ON f.medication_id = m."MED_ID"

LEFT JOIN warehouse.dim_date d
    ON m."END_DATE" = d.full_date

WHERE f.end_date_key IS NULL

GROUP BY 1
ORDER BY total_medications DESC;



