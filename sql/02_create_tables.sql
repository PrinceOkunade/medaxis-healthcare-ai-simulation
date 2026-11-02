CREATE TABLE IF NOT EXISTS raw.patients (
    "PATIENT_ID" VARCHAR(20),
    "DATE_OF_BIRTH" DATE,
    "GENDER" VARCHAR(20),
    "ETHNICITY" VARCHAR(100),
    "DEPRIVATION_DECILE" INTEGER,
    "PRIMARY_SITE" VARCHAR(20),
    "REGISTRATION_DATE" DATE,
    "POSTCODE_SECTOR" VARCHAR(20)
);


SELECT *
FROM raw.patients
LIMIT 10;

SELECT COUNT(*)
FROM raw.patients;

CREATE TABLE IF NOT EXISTS raw.admissions (
    "ENCOUNTER_ID" VARCHAR(20),
    "PATIENT_ID" VARCHAR(20),
    "ADMISSION_DATE" DATE,
    "DISCHARGE_DATE" DATE,
    "ADM_TYPE" VARCHAR(10),
    "DISCH_DEST" VARCHAR(20),
    "ICD10_PRI" VARCHAR(20),
    "ICD10_SEC" TEXT,
    "LOS_DAYS" INTEGER,
    "DD_FLAG" INTEGER,
    "COMORB_CNT" INTEGER,
    "PREV_ADM_90" INTEGER,
    "30DR" INTEGER,
    "WARD_CODE" VARCHAR(30),
    "SITE_ID" VARCHAR(20)
);

SELECT *
FROM raw.admissions
LIMIT 10;

SELECT COUNT (*)
FROM raw.admissions;

SELECT COUNT(*) AS total_admissions
FROM raw.admissions;



-- Table 3: Laboratory Results
CREATE TABLE IF NOT EXISTS raw.lab_results (
    "LAB_ID" VARCHAR(20),
    "ENCOUNTER_ID" VARCHAR(20),
    "PATIENT_ID" VARCHAR(20),
    "TEST_NAME" VARCHAR(100),
    "RESULT_VALUE" NUMERIC,
    "UNIT" VARCHAR(30),
    "LAB_FLAG" INTEGER,
    "RESULT_DATE" DATE
);

-- Table 4: Medications
CREATE TABLE IF NOT EXISTS raw.medications (
    "MED_ID" VARCHAR(20),
    "ENCOUNTER_ID" VARCHAR(20),
    "PATIENT_ID" VARCHAR(20),
    "MEDICATION" VARCHAR(150),
    "START_DATE" DATE,
    "END_DATE" DATE,
    "ROUTE" VARCHAR(30),
    "STATUS" VARCHAR(30)
);

-- Table 5: Observations
CREATE TABLE IF NOT EXISTS raw.observations (
    "OBS_ID" VARCHAR(20),
    "ENCOUNTER_ID" VARCHAR(20),
    "PATIENT_ID" VARCHAR(20),
    "OBS_TYPE" VARCHAR(100),
    "VALUE" NUMERIC,
    "UNIT" VARCHAR(30),
    "OBS_DATE" DATE
);


SELECT 'patients' AS table_name,
       COUNT(*) AS total_rows
FROM raw.patients

UNION ALL

SELECT 'admissions', COUNT(*)
FROM raw.admissions

UNION ALL

SELECT 'lab_results', COUNT(*)
FROM raw.lab_results

UNION ALL

SELECT 'medications', COUNT(*)
FROM raw.medications

UNION ALL

SELECT 'observations', COUNT(*)
FROM raw.observations;


SELECT 'TOTAL', (
    (SELECT COUNT(*) FROM raw.patients) +
    (SELECT COUNT(*) FROM raw.admissions) +
    (SELECT COUNT(*) FROM raw.lab_results) +
    (SELECT COUNT(*) FROM raw.medications) +
    (SELECT COUNT(*) FROM raw.observations)
);