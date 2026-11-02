# Phase 2 validation report

**Evidence:** User-reported outputs from pgAdmin, 2026-11-02. We audited the uploaded SQL but have not independently executed it on a fresh PostgreSQL instance.

| Table | Reported records |
|---|---:|
| raw patients | 2,012 |
| raw admissions | 3,695 |
| raw lab results | 11,027 |
| raw medications | 8,844 |
| raw observations | 11,972 |
| **raw total** | **37,550** |
| dim_patient | 2,000 |
| dim_hospital | 6 |
| dim_diagnosis | 24 |
| dim_date | 4,018 |
| fact_encounter | 3,687 |
| fact_lab_result | 11,027 |
| fact_observation | 11,972 |
| fact_medication | 8,844 |
| secondary diagnosis bridge | 5,617 |

Other results: 2,764 encounters with eight secondary ICD-10 diagnosis codes; zero raw secondary diagnosis links missing in the warehouse. Warehouse patient and encounter duplicate business keys both zero; MER005 incorrectly acute eligible zero. Lab, medication and observation patient-to-encounter mismatches all zero. Earliest/latest clinical dates: 2022-01-03 / 2025-01-05; zero non-null dates missing from dim_date.

**Encounter flags:** VALID 2,750; LOS_MISMATCH 868; MISSING_DISCHARGE_DATE 50; INVALID_DATE_ORDER 19. These are mutually exclusive priority flags, not independent overlapping issue counts.

**Acute modelling exclusions:** MER005 583; missing discharge date 42; invalid date order 13; total 638. Priority logic means these figures do not enumerate all overlapping defects. Provisionally acute eligible: 3,049.

**Medication:** 160 missing end-date keys, all caused by source NULL end dates, not a missing date-dimension lookup. **ICD-10 delimiter check:** 1,886 pipe-delimited admissions, zero comma-delimited admissions.

## Outstanding items
1. The seven SQL scripts do **not** import CSV data automatically. The raw CSVs were loaded manually through pgAdmin; fresh rebuild not yet proven.
2. Raw tables have no ingestion timestamps, source row numbers or conflict-audit trail.
3. Patient and encounter canonical-record rules are provisional and not clinically verified.
4. Single-value data_quality_flag hides multiple simultaneous issues.
5. Add bidirectional source-to-warehouse reconciliation and clinically reviewed eligibility logic.
6. The simulation is not a clinical deployment. The counts above are user-reported executions, not independent tests.

Keep labelled pgAdmin result exports/screenshots as reproducible execution proof.