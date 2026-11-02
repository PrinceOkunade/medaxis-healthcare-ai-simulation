
-- Phase 2: Dimension tables
-- 1. Patient dimension

CREATE TABLE IF NOT EXISTS warehouse.dim_patient (
    patient_key INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    patient_id VARCHAR(20) NOT NULL UNIQUE,
    date_of_birth DATE,
    gender VARCHAR(20),
    ethnicity VARCHAR(100),
    deprivation_decile INTEGER,
    primary_site VARCHAR(20),
    registration_date DATE,
    postcode_sector VARCHAR(20)
);


-- 2. Hospital dimension
CREATE TABLE IF NOT EXISTS warehouse.dim_hospital (
    hospital_key INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    site_id VARCHAR(20) NOT NULL UNIQUE,
    hospital_name VARCHAR(150),
    location VARCHAR(100),
    bed_capacity INTEGER,
    specialty VARCHAR(150),
    is_acute_site BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Diagnosis dimension
CREATE TABLE IF NOT EXISTS warehouse.dim_diagnosis (
    diagnosis_key INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    icd10_code VARCHAR(20) NOT NULL UNIQUE,
    diagnosis_description VARCHAR(255)
);

-- 4. Date dimension
CREATE TABLE IF NOT EXISTS warehouse.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    month_name VARCHAR(20)
);


SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'warehouse'
ORDER BY table_name;