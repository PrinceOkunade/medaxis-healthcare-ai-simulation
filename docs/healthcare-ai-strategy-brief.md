# Healthcare AI Strategy Brief

**Project:** MedAxis Intelligence x Meridian Health Group (SortNext Project Lab simulation)  
**Prepared by:** Prince Okunade  
**GitHub:** https://github.com/PrinceOkunade/medaxis-healthcare-ai-simulation

## 1. Three core business problems

**Readmissions:** Meridian's 30-day readmission rate is 18.4%, against a target below 14%. The scenario estimates £310,000 in annual savings for every percentage-point reduction; achieving a 4.4-point reduction would imply approximately £1.36 million annually.

**Capacity and patient flow:** Peak bed occupancy is 94.2%, delayed discharges affect 22.7% of cases, and average length of stay (LOS) is 6.8 days. The charter values a one-day LOS reduction at 1,840 bed-days and £2.1 million in annual operational capacity.

**Demand planning and documentation:** Emergency demand forecasting has approximately 31% error, while reviewing clinical notes takes 47 minutes per patient. Together, the proposed improvements contribute to the charter's estimated £9.2 million total annual opportunity, not an additional independently validated saving.

## 2. Six proposed success metrics

1. **30-day readmission rate:** reduce from 18.4% to below 14%.
2. **Peak bed occupancy:** reduce from 94.2% to below 88%.
3. **Delayed discharge rate:** reduce from 22.7% to below 12%.
4. **Average LOS:** reduce from 6.8 to below 5.5 days.
5. **Emergency demand forecast error:** reduce from about 31% to below 12%, evaluated through rolling-origin backtesting.
6. **Clinical note review time:** reduce from 47 to below 15 minutes per patient in a controlled workflow evaluation.

Clinical safety is a separate release gate: the readmission classifier must achieve recall of at least 0.72 on a held-out test set, alongside acceptable calibration and subgroup performance. The operational targets are simulated objectives, not achieved outcomes.

## 3. Stakeholder and decision ownership

**Dr Priya Nair, Meridian Chief Medical Officer:** clinical usefulness, patient-safety thresholds and final clinical sign-off. **James Okafor, MedAxis Head of Data Engineering:** source-data definitions, ingestion, warehouse integrity and pipeline remediation. **Sophia Reeves, MedAxis Head of AI Governance:** fairness review, model cards, monitoring and governance approval. **Marcus Webb, MedAxis Commercial Director:** benefit assumptions, contractual milestones, ROI case and board presentation. **Meridian legal team:** privacy and regulatory review. **Data science delivery team:** technical design, implementation, evaluation and evidence for these decisions.

## 4. Highest governance risks and mitigations

**Patient safety and bias:** False negatives or disparities across age, ethnicity, deprivation, hospital and ward could cause harm. Report confusion matrices and subgroup recall, calibrate predictions, document limitations and retain human clinical override.

**Poor data quality and leakage:** Missing discharge dates, inconsistent LOS fields, duplicate records and the Week 68 `PARTIAL_DATA` anomaly can distort results. Implement automated validation, point-in-time features, patient-aware temporal splits and exclusion or documented remediation of corrupted periods.

**Privacy and regulatory non-compliance:** Clinical notes and health records require strict controls. Use de-identified data, least-privilege access, audit logs and a DPIA; assess SaMD/MHRA and NHS DTAC applicability before any real-world deployment.

## 5. Proposed modelling approach

**Readmission:** Benchmark regularised logistic regression against gradient boosting; validate temporally, calibrate risk scores, tune the decision threshold to meet recall ≥0.72 and explain outputs with SHAP.

**Demand forecasting:** Compare seasonal-naive and SARIMAX baselines with lag-feature gradient boosting. Use rolling-origin evaluation for the 14-day horizon; investigate and exclude the Week 68 pipeline anomaly.

**Length of stay:** Compare a Gamma regression baseline with gradient-boosted regression, handle ongoing admissions and assess MAE across hospital sites and wards without post-discharge leakage.

**Clinical NLP:** On the 200-note sample, prototype de-identified entity extraction and ICD coding, assessing precision and recall against reviewed labels. For guideline search, evaluate a citation-grounded RAG assistant with unsupported-answer refusal tests.

**Repository:** https://github.com/PrinceOkunade/medaxis-healthcare-ai-simulation
