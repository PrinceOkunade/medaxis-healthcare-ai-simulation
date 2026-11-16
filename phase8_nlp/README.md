# Phase 8: Clinical NLP prototype (MedAxis simulation)

This is a **local, transparent, rule-based spaCy PhraseMatcher + regular-expression** prototype, **not** an evaluated Hugging Face clinical model. It uses a list of clinical words drawn from the synthetic project notes and section cues. It **does not** perform full clinical NER, context, negation, dosage-route separation, or medical coding.

## Run

1. Open this folder in VS Code.
2. `py -m pip install -r requirements.txt`
3. Download `clinical_notes_sample.csv` from https://raw.githubusercontent.com/alain-Sortnext/medaxis-intelligence-simulation/main/clinical_notes_sample.csv and place beside `phase8_nlp.py` (or let the script attempt download).
4. `py phase8_nlp.py`
5. Inspect `outputs/evaluation_20.json`, `outputs/entities_200.jsonl`, and `outputs/examples_2_notes.json`.

## Evaluation design

20 *fixed*, manually reviewed synthetic notes `NOTE00001`–`NOTE00020`. Gold labels are specified explicitly in the script. Matching uses exact normalized phrases in each category with duplicates collapsed. The category `symptom` means presenting symptom, whereas clinically diagnosed presenting conditions are labelled `diagnosis`; background history diagnoses are also included. Medication extracts are drug name **plus stated dose/form**, not inferred routes. Follow-up combines discharge plan and follow-up appointment. Gold duplicates such as repeated atrial fibrillation are counted once. This synthetic template-based evaluation is substantially easier than clinical free text; it cannot support real clinical accuracy claims. Inspect `errors` for false-positive/false-negative examples; do not manufacture errors.

## Clinical privacy and safety limitations

The included notes are **synthetic**, but contain simulated encounter/patient IDs. Never upload real health records to public GitHub, public model hubs, logs, or an unsecured hosted API. For real protected health information, determine lawful basis and Article 9 condition under UK GDPR, complete DPIA, minimise collection, pseudonymise or de-identify with residual re-identification assessment, encrypt in transit/at rest, restrict access using least privilege, isolate inference in approved infrastructure, implement retention/deletion and audit policies, contractually control processors, and provide clinician review. Redact extracted PHI *before* development/export and assess re-identification through combinations of quasi-identifiers. A public clinical pretrained model can still present data processing/IP and safety concerns if external inference services are used. This project runs only locally and does not transfer texts to Hugging Face servers.

## Git commit (you must perform this)

```
git add medaxis_phase8/phase8_nlp.py medaxis_phase8/requirements.txt medaxis_phase8/README.md
git commit -m "Add Phase 8 synthetic clinical NLP extraction and 20-note evaluation"
git push
```

Once pushed, copy the commit link from your GitHub repository. No commit link is claimed before a push succeeds. Do not commit real clinical text or local outputs containing sensitive patient information.
