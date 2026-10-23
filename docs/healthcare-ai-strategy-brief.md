# Healthcare AI Strategy Brief

**Project:** MedAxis Intelligence × Meridian Health Group (SortNext Project Lab simulation)  
**Prepared by:** Prince Okunade

## 1. Three core business problems

**Readmissions:** The 30-day readmission rate is 18.4%, versus a target below 14%. The simulated business case estimates £310,000 saved annually per percentage-point reduction; a 4.4-point reduction implies approximately £1.36 million yearly.

**Patient flow:** Peak bed occupancy is 94.2%, delayed discharges are 22.7%, and average length of stay (LOS) is 6.8 days. The brief values a one-day LOS reduction at 1,840 released bed-days and £2.1 million in annual capacity.

**Planning and documentation:** Emergency demand forecast error is approximately 31%, while clinical note review takes 47 minutes per patient. The charter estimates £9.2 million in total potential annual benefit across improvements; this is not an independently verified outcome.

## 2. Six measurable success metrics

1. Reduce 30-day readmissions from **18.4% to below 14%**.
2. Reduce peak bed occupancy from **94.2% to below 88%**.
3. Reduce delayed discharges from **22.7% to below 12%**.
4. Reduce average LOS from **6.8 to below 5.5 days**.
5. Reduce emergency demand forecast error from **approximately 31% to below 12%** using rolling-origin backtesting.
6. Reduce clinical note review time from **47 to below 15 minutes per patient** in a supervised workflow trial.

A separate safety release gate requires readmission recall **≥0.72**, with calibration and subgroup validation.

## 3. Stakeholder map and decision ownership

**Dr Priya Nair (Meridian CMO):** clinical risk tolerance, human escalation and final clinical sign-off. **James Okafor (MedAxis Data Engineering):** source definitions, pipeline integrity and remediation. **Sophia Reeves (AI Governance):** bias evaluation, model cards, monitoring controls and governance approval. **Marcus Webb (Commercial):** ROI assumptions, delivery milestones and board presentation. **Meridian Legal:** privacy and regulatory assessments. **Data science team:** model design, testing and reproducible evidence.

## 4. Three highest governance risks

**Clinical harm or bias:** Missed high-risk patients and unequal subgroup performance. Mitigate through recall and subgroup audits, calibration, explanations and clinician override.

**Data defects and leakage:** Duplicates, missing dates, inconsistent LOS and Week 68's `PARTIAL_DATA` failure. Apply automated data checks, point-in-time features, temporal validation and quarantine of defective batches.

**Privacy or regulatory failure:** Sensitive clinical notes and potentially regulated medical software. Use de-identification, least-privilege access, audit logs and a DPIA; assess MHRA SaMD and NHS DTAC obligations before real deployment.

## 5. Proposed modelling approach

**Readmission:** Compare regularised logistic regression with gradient boosting; use temporal validation, calibrated probabilities, SHAP and threshold selection to meet recall ≥0.72.

**Demand:** Benchmark seasonal-naive and SARIMAX against lag-based boosting for 14-day forecasts; exclude the Week 68 pipeline anomaly.

**LOS:** Compare Gamma regression and gradient boosting, handle patients still admitted and evaluate MAE by site and ward.

**NLP:** Validate clinical entity extraction and ICD coding on reviewed notes; test a citation-grounded RAG assistant for unsupported or unsafe answers.

## 6. Post-deployment monitoring and escalation

**Daily:** James monitors ingestion failures, missing fields and schema changes; quarantine affected batches if critical-field missingness exceeds **2%** or feeds fail. Clinicians use the existing manual workflow until data are repaired.

**Weekly:** Sophia reviews drift, calibration, subgroup recall and forecast error; outcomes for readmission are evaluated only after the **30-day label window** matures. **PSI >0.20 for two consecutive weeks**, a **subgroup recall gap >0.10**, or forecast error **>12% for two successive evaluation windows** triggers investigation, dataset review and consideration of retraining. Replacements must pass temporal, fairness and clinical validation before approval.

**Emergency intervention:** If confirmed readmission recall falls **below 0.72**, a critical unsafe recommendation appears, or a serious privacy incident occurs, **suspend affected automated recommendations immediately**, alert Dr Nair and Sophia, and revert to clinician-led assessment. Re-enable only after documented root-cause review and clinical sign-off. These are proposed simulation thresholds, not approved hospital policies.

## 7. GitHub repository

https://github.com/PrinceOkunade/medaxis-healthcare-ai-simulation
