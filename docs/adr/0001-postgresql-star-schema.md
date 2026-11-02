# ADR 0001: PostgreSQL star schema

Status: Accepted for the simulated Phase 2 project, with outstanding work.
Date: 2026-11-02

## Context
The healthcare simulation supplies five CSV datasets with duplicate identifiers, missing dates and inconsistent length-of-stay values. Data must support analytics and preserve the original extracts.

## Decision
Use PostgreSQL with a raw staging schema and a warehouse schema. The warehouse has patient, hospital, diagnosis and date dimensions; encounter, laboratory result, observation and medication fact tables; and a bridge linking encounters to multiple secondary diagnosis codes. Use surrogate primary keys and foreign keys. One encounter fact row represents one encounter ID.

Maintain NULL dates and retain source and calculated length of stay. Mark MER005 as a rehabilitation facility and not eligible for acute readmission modelling. Choose canonical patient and encounter rows by deterministic ordering, pending authoritative review.

## FHIR-style mapping
Patient dimension: Patient concept. Encounter fact: Encounter. Diagnosis dimension and bridge: Condition concepts. Laboratory and observation facts: Observation. Medication fact: medication-related concepts. This relational schema is FHIR-inspired, not verified FHIR-compliant.

## Alternatives
A single flat table would duplicate data across multiple clinical events. A fully normalised transactional design makes analytical queries less convenient. A large cloud warehouse is not required for the small simulation data.

## Consequences
Benefits include distinct fact grains, simpler joins and explicit site eligibility. Limitations include manual pgAdmin CSV imports, absent source-row audit metadata, provisional deduplication decisions, a single quality flag per encounter, and the need to validate a clean database rebuild. The scripts are not yet an unattended ingestion pipeline.