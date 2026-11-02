
-- PHASE 2: LOAD WAREHOUSE
-- 1. Populate patient dimension

INSERT INTO warehouse.dim_patient (
    patient_id,
    date_of_birth,
    gender,
    ethnicity,
    deprivation_decile,
    primary_site,
    registration_date,
    postcode_sector
)
SELECT DISTINCT ON ("PATIENT_ID")
    "PATIENT_ID",
    "DATE_OF_BIRTH",
    "GENDER",
    "ETHNICITY",
    "DEPRIVATION_DECILE",
    "PRIMARY_SITE",
    "REGISTRATION_DATE",
    "POSTCODE_SECTOR"
FROM raw.patients
WHERE "PATIENT_ID" IS NOT NULL
ORDER BY
    "PATIENT_ID",
    "REGISTRATION_DATE" DESC NULLS LAST,
    "ETHNICITY" ASC NULLS LAST
ON CONFLICT (patient_id) DO NOTHING;


SELECT COUNT(*) AS total_unique_patients
FROM warehouse.dim_patient;


-- 2. Populate hospital dimension

INSERT INTO warehouse.dim_hospital (
    site_id,
    hospital_name,
    location,
    bed_capacity,
    specialty,
    is_acute_site
)
VALUES
('MER001', 'Meridian Royal Infirmary',
 'London SE1', 620, 'General Acute, Trauma', TRUE),

('MER002', 'Meridian City Hospital',
 'Birmingham B4', 480, 'General Acute, Cardiology', TRUE),

('MER003', 'Meridian Northern General',
 'Manchester M13', 390, 'General Acute, Oncology', TRUE),

('MER004', 'Meridian St Anne''s',
 'Bristol BS2', 310, 'General Acute, Orthopaedics', TRUE),

('MER005', 'Meridian Community Hospital',
 'Leeds LS1', 120, 'Step-down, Rehab', FALSE),

('MER006', 'Meridian University Hospital',
 'Dublin D02', 550, 'Teaching, General Acute', TRUE)

ON CONFLICT (site_id) DO NOTHING;


SELECT
    site_id,
    hospital_name,
    bed_capacity,
    is_acute_site
FROM warehouse.dim_hospital
ORDER BY site_id;


-- 3. Populate diagnosis dimension
-- Extract primary and secondary ICD-10 codes

WITH all_diagnoses AS (

    -- Primary diagnoses
    SELECT TRIM("ICD10_PRI") AS icd10_code
    FROM raw.admissions

    UNION

    -- Secondary diagnoses
    SELECT TRIM(code) AS icd10_code
    FROM raw.admissions
    CROSS JOIN LATERAL
        regexp_split_to_table(
            COALESCE("ICD10_SEC", ''),
            '[|,]'
        ) AS code
)

INSERT INTO warehouse.dim_diagnosis (
    icd10_code,
    diagnosis_description
)
SELECT DISTINCT
    icd10_code,
    NULL
FROM all_diagnoses
WHERE icd10_code IS NOT NULL
  AND icd10_code <> ''
ON CONFLICT (icd10_code) DO NOTHING;



SELECT
    COUNT(*) AS total_diagnoses,
    COUNT(DISTINCT icd10_code) AS unique_diagnoses
FROM warehouse.dim_diagnosis;


SELECT *
FROM warehouse.dim_diagnosis
ORDER BY icd10_code
LIMIT 10;


-- 4. Populate date dimension

INSERT INTO warehouse.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    day,
    day_of_week,
    month_name
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER,
    d::DATE,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    EXTRACT(DAY FROM d)::INTEGER,
    EXTRACT(ISODOW FROM d)::INTEGER,
    TO_CHAR(d, 'FMMonth')
FROM generate_series(
    '2020-01-01'::DATE,
    '2030-12-31'::DATE,
    INTERVAL '1 day'
) AS dates(d)
ON CONFLICT (date_key) DO NOTHING;


SELECT
    COUNT(*) AS total_dates,
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date
FROM warehouse.dim_date;


-- Check clinical dates outside dim_date range

WITH clinical_dates AS (
    SELECT "ADMISSION_DATE" AS event_date
    FROM raw.admissions

    UNION ALL

    SELECT "DISCHARGE_DATE"
    FROM raw.admissions

    UNION ALL

    SELECT "RESULT_DATE"
    FROM raw.lab_results

    UNION ALL

    SELECT "OBS_DATE"
    FROM raw.observations

    UNION ALL

    SELECT "START_DATE"
    FROM raw.medications

    UNION ALL

    SELECT "END_DATE"
    FROM raw.medications
)

SELECT
    MIN(event_date) AS earliest_date,
    MAX(event_date) AS latest_date,
    COUNT(*) FILTER (
        WHERE event_date IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM warehouse.dim_date d
              WHERE d.full_date = event_date
          )
    ) AS dates_missing_from_dimension
FROM clinical_dates;


-- 5. Populate fact_encounter
-- Retain one record per encounter ID
-- Flag invalid dates and exclude MER005 from acute modelling

WITH ranked_admissions AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (
            PARTITION BY "ENCOUNTER_ID"
            ORDER BY
                ("ADMISSION_DATE" IS NOT NULL) DESC,
                ("DISCHARGE_DATE" IS NOT NULL) DESC,
                "ADMISSION_DATE" DESC NULLS LAST,
                "DISCHARGE_DATE" DESC NULLS LAST,
                "PATIENT_ID",
                "SITE_ID",
                "ICD10_PRI",
                "ICD10_SEC"
        ) AS rn
    FROM raw.admissions a
)

INSERT INTO warehouse.fact_encounter (
    encounter_id,
    patient_key,
    hospital_key,
    diagnosis_key,
    admission_date_key,
    discharge_date_key,
    admission_date,
    discharge_date,
    admission_type,
    discharge_destination,
    ward_code,
    los_days_source,
    los_days_calculated,
    delayed_discharge_flag,
    comorbidity_count,
    previous_admissions_90,
    readmitted_30_days,
    data_quality_flag,
    is_acute_model_eligible
)
SELECT
    a."ENCOUNTER_ID",
    p.patient_key,
    h.hospital_key,
    d.diagnosis_key,
    ad.date_key,
    dd.date_key,
    a."ADMISSION_DATE",
    a."DISCHARGE_DATE",
    a."ADM_TYPE",
    a."DISCH_DEST",
    a."WARD_CODE",
    a."LOS_DAYS",

    CASE
        WHEN a."DISCHARGE_DATE" >= a."ADMISSION_DATE"
        THEN a."DISCHARGE_DATE" - a."ADMISSION_DATE"
        ELSE NULL
    END,

    a."DD_FLAG",
    a."COMORB_CNT",
    a."PREV_ADM_90",
    a."30DR",

    CASE
        WHEN a."ADMISSION_DATE" > a."DISCHARGE_DATE"
            THEN 'INVALID_DATE_ORDER'
        WHEN a."DISCHARGE_DATE" IS NULL
            THEN 'MISSING_DISCHARGE_DATE'
        WHEN a."LOS_DAYS" IS DISTINCT FROM
             (a."DISCHARGE_DATE" - a."ADMISSION_DATE")
            THEN 'LOS_MISMATCH'
        ELSE 'VALID'
    END,

    CASE
        WHEN h.is_acute_site = FALSE THEN FALSE
        WHEN a."ADMISSION_DATE" IS NULL THEN FALSE
        WHEN a."DISCHARGE_DATE" IS NULL THEN FALSE
        WHEN a."ADMISSION_DATE" > a."DISCHARGE_DATE"
            THEN FALSE
        ELSE TRUE
    END

FROM ranked_admissions a

JOIN warehouse.dim_patient p
    ON a."PATIENT_ID" = p.patient_id

JOIN warehouse.dim_hospital h
    ON a."SITE_ID" = h.site_id

LEFT JOIN warehouse.dim_diagnosis d
    ON a."ICD10_PRI" = d.icd10_code

LEFT JOIN warehouse.dim_date ad
    ON a."ADMISSION_DATE" = ad.full_date

LEFT JOIN warehouse.dim_date dd
    ON a."DISCHARGE_DATE" = dd.full_date

WHERE a.rn = 1

ON CONFLICT (encounter_id) DO NOTHING;


SELECT
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT encounter_id) AS unique_encounters,
    COUNT(*) FILTER (
        WHERE is_acute_model_eligible = FALSE
    ) AS excluded_from_acute_model
FROM warehouse.fact_encounter;


-- 6. Populate laboratory results fact table

INSERT INTO warehouse.fact_lab_result (
    lab_id,
    encounter_key,
    patient_key,
    result_date_key,
    test_name,
    result_value,
    unit,
    lab_flag
)
SELECT
    l."LAB_ID",
    e.encounter_key,
    p.patient_key,
    d.date_key,
    l."TEST_NAME",
    l."RESULT_VALUE",
    l."UNIT",
    l."LAB_FLAG"

FROM raw.lab_results l

JOIN warehouse.fact_encounter e
    ON l."ENCOUNTER_ID" = e.encounter_id

JOIN warehouse.dim_patient p
    ON l."PATIENT_ID" = p.patient_id

LEFT JOIN warehouse.dim_date d
    ON l."RESULT_DATE" = d.full_date

ON CONFLICT (lab_id) DO NOTHING;



-- 7. Populate clinical observations fact table

INSERT INTO warehouse.fact_observation (
    observation_id,
    encounter_key,
    patient_key,
    observation_date_key,
    observation_type,
    observation_value,
    unit
)
SELECT
    o."OBS_ID",
    e.encounter_key,
    p.patient_key,
    d.date_key,
    o."OBS_TYPE",
    o."VALUE",
    o."UNIT"

FROM raw.observations o

JOIN warehouse.fact_encounter e
    ON o."ENCOUNTER_ID" = e.encounter_id

JOIN warehouse.dim_patient p
    ON o."PATIENT_ID" = p.patient_id

LEFT JOIN warehouse.dim_date d
    ON o."OBS_DATE" = d.full_date

ON CONFLICT (observation_id) DO NOTHING;


-- 8. Populate medication fact table

INSERT INTO warehouse.fact_medication (
    medication_id,
    encounter_key,
    patient_key,
    start_date_key,
    end_date_key,
    medication_name,
    route,
    status
)
SELECT
    m."MED_ID",
    e.encounter_key,
    p.patient_key,
    sd.date_key,
    ed.date_key,
    m."MEDICATION",
    m."ROUTE",
    m."STATUS"

FROM raw.medications m

JOIN warehouse.fact_encounter e
    ON m."ENCOUNTER_ID" = e.encounter_id

JOIN warehouse.dim_patient p
    ON m."PATIENT_ID" = p.patient_id

LEFT JOIN warehouse.dim_date sd
    ON m."START_DATE" = sd.full_date

LEFT JOIN warehouse.dim_date ed
    ON m."END_DATE" = ed.full_date

ON CONFLICT (medication_id) DO NOTHING;


-- 9. Populate secondary diagnosis bridge table

WITH ranked_admissions AS (
    SELECT
        "ENCOUNTER_ID",
        "ICD10_SEC",
        ROW_NUMBER() OVER (
            PARTITION BY "ENCOUNTER_ID"
            ORDER BY
                ("ADMISSION_DATE" IS NOT NULL) DESC,
                ("DISCHARGE_DATE" IS NOT NULL) DESC,
                "ADMISSION_DATE" DESC NULLS LAST,
                "DISCHARGE_DATE" DESC NULLS LAST,
                "PATIENT_ID",
                "SITE_ID",
                "ICD10_PRI",
                "ICD10_SEC"
        ) AS rn
    FROM raw.admissions
),
secondary_codes AS (
    SELECT
        a."ENCOUNTER_ID",
        TRIM(c.code) AS icd10_code
    FROM ranked_admissions a
    CROSS JOIN LATERAL
        regexp_split_to_table(
            COALESCE(a."ICD10_SEC", ''),
            '[|,]'
        ) AS c(code)
    WHERE a.rn = 1
)

INSERT INTO
warehouse.bridge_encounter_secondary_diagnosis (
    encounter_key,
    diagnosis_key
)
SELECT DISTINCT
    e.encounter_key,
    d.diagnosis_key
FROM secondary_codes s
JOIN warehouse.fact_encounter e
    ON s."ENCOUNTER_ID" = e.encounter_id
JOIN warehouse.dim_diagnosis d
    ON s.icd10_code = d.icd10_code
WHERE s.icd10_code <> ''
ON CONFLICT (encounter_key, diagnosis_key)
DO NOTHING;





