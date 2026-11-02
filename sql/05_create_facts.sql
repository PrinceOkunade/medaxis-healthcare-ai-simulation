
-- PHASE 2: FACT TABLES
-- MedAxis Healthcare Data Warehouse

-- 1. Hospital encounters
CREATE TABLE IF NOT EXISTS warehouse.fact_encounter (
    encounter_key INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    encounter_id VARCHAR(20) NOT NULL UNIQUE,

    patient_key INTEGER NOT NULL
        REFERENCES warehouse.dim_patient(patient_key),

    hospital_key INTEGER NOT NULL
        REFERENCES warehouse.dim_hospital(hospital_key),

    diagnosis_key INTEGER
        REFERENCES warehouse.dim_diagnosis(diagnosis_key),

    admission_date_key INTEGER
        REFERENCES warehouse.dim_date(date_key),

    discharge_date_key INTEGER
        REFERENCES warehouse.dim_date(date_key),

    admission_date DATE,
    discharge_date DATE,
    admission_type VARCHAR(10),
    discharge_destination VARCHAR(20),
    ward_code VARCHAR(30),

    los_days_source INTEGER,
    los_days_calculated INTEGER,

    delayed_discharge_flag INTEGER,
    comorbidity_count INTEGER,
    previous_admissions_90 INTEGER,
    readmitted_30_days INTEGER,

    data_quality_flag VARCHAR(50),
    is_acute_model_eligible BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Laboratory results
CREATE TABLE IF NOT EXISTS warehouse.fact_lab_result (
    lab_key INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    lab_id VARCHAR(20) NOT NULL UNIQUE,

    encounter_key INTEGER NOT NULL
        REFERENCES warehouse.fact_encounter(encounter_key),

    patient_key INTEGER NOT NULL
        REFERENCES warehouse.dim_patient(patient_key),

    result_date_key INTEGER
        REFERENCES warehouse.dim_date(date_key),

    test_name VARCHAR(100),
    result_value NUMERIC,
    unit VARCHAR(30),
    lab_flag INTEGER
);

-- 3. Patient observations
CREATE TABLE IF NOT EXISTS warehouse.fact_observation (
    observation_key INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    observation_id VARCHAR(20) NOT NULL UNIQUE,

    encounter_key INTEGER NOT NULL
        REFERENCES warehouse.fact_encounter(encounter_key),

    patient_key INTEGER NOT NULL
        REFERENCES warehouse.dim_patient(patient_key),

    observation_date_key INTEGER
        REFERENCES warehouse.dim_date(date_key),

    observation_type VARCHAR(100),
    observation_value NUMERIC,
    unit VARCHAR(30)
);

-- 4. Medication records
CREATE TABLE IF NOT EXISTS warehouse.fact_medication (
    medication_key INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    medication_id VARCHAR(20) NOT NULL UNIQUE,

    encounter_key INTEGER NOT NULL
        REFERENCES warehouse.fact_encounter(encounter_key),

    patient_key INTEGER NOT NULL
        REFERENCES warehouse.dim_patient(patient_key),

    start_date_key INTEGER
        REFERENCES warehouse.dim_date(date_key),

    end_date_key INTEGER
        REFERENCES warehouse.dim_date(date_key),

    medication_name VARCHAR(150),
    route VARCHAR(30),
    status VARCHAR(30)
);


SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'warehouse'
ORDER BY table_name;


-- 5. Secondary diagnosis bridge table
-- Connects encounters to multiple diagnoses

CREATE TABLE IF NOT EXISTS
warehouse.bridge_encounter_secondary_diagnosis (
    encounter_key INTEGER NOT NULL
        REFERENCES warehouse.fact_encounter(encounter_key),

    diagnosis_key INTEGER NOT NULL
        REFERENCES warehouse.dim_diagnosis(diagnosis_key),

    PRIMARY KEY (encounter_key, diagnosis_key)
);

