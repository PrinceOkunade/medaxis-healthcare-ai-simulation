"""MedAxis Phase 8: transparent, local, rule-based clinical NLP prototype.

Run: python phase8_nlp.py --input clinical_notes_sample.csv
No external API or cloud inference is used. This is not a medical device.
"""
from __future__ import annotations
import argparse
import csv
import json
import re
from collections import Counter
from pathlib import Path
import pandas as pd
import spacy
from spacy.matcher import PhraseMatcher

SOURCE = 'https://raw.githubusercontent.com/alain-Sortnext/medaxis-intelligence-simulation/main/clinical_notes_sample.csv'
CATEGORIES = ('symptom','diagnosis','medication','follow_up','risk_indicator')

# These 20 IDs, with adjudicated phrase lists below, form a fixed, non-random
# evaluation sample. The text is synthetic and template-generated. Consequently,
# these scores substantially overestimate performance on real-world notes.
GOLD = {
  'NOTE00001': {'symptom':['fall with reduced mobility'],'diagnosis':['atrial fibrillation'],'medication':['amoxicillin 500mg','furosemide 40mg'],'follow_up':['district nurse for wound care','respiratory in 12 weeks'],'risk_indicator':['medication non-compliance risk']},
  'NOTE00002': {'symptom':[],'diagnosis':['decompensated heart failure','atrial fibrillation','osteoarthritis'],'medication':['doxycycline 100mg','clopidogrel 75mg'],'follow_up':['outpatient cardiology referral','respiratory in 4 weeks'],'risk_indicator':['medication non-compliance risk']},
  'NOTE00003': {'symptom':[],'diagnosis':['decompensated heart failure','copd','atrial fibrillation'],'medication':['furosemide 40mg','bisoprolol 2.5mg'],'follow_up':['medication titration in primary care','respiratory in 5 weeks'],'risk_indicator':['high falls risk']},
  'NOTE00004': {'symptom':['acute chest pain'],'diagnosis':['osteoarthritis'],'medication':['apixaban 5mg','warfarin'],'follow_up':['gp follow-up arranged','respiratory in 11 weeks'],'risk_indicator':['carer support required']},
  'NOTE00005': {'symptom':[],'diagnosis':['acute exacerbation of copd','atrial fibrillation'],'medication':['atorvastatin 40mg','clopidogrel 75mg'],'follow_up':['medication titration in primary care','cardiology in 7 weeks'],'risk_indicator':['medication non-compliance risk']},
  'NOTE00006': {'symptom':[],'diagnosis':['community-acquired pneumonia','previous mi','atrial fibrillation'],'medication':['warfarin','morphine 10mg'],'follow_up':['gp follow-up arranged','cardiology in 11 weeks'],'risk_indicator':['confusion noted at discharge']},
  'NOTE00007': {'symptom':[],'diagnosis':['acute exacerbation of copd','previous mi','type 2 diabetes mellitus'],'medication':['furosemide 40mg','omeprazole 20mg'],'follow_up':['community nursing input','gp in 10 weeks'],'risk_indicator':['carer support required']},
  'NOTE00008': {'symptom':['acute chest pain'],'diagnosis':['type 2 diabetes mellitus','previous mi'],'medication':['salbutamol inhaler','amlodipine 5mg'],'follow_up':['medication titration in primary care','endocrinology in 7 weeks'],'risk_indicator':['medication non-compliance risk']},
  'NOTE00009': {'symptom':[],'diagnosis':['decompensated heart failure','chronic kidney disease stage 3','previous mi'],'medication':['atorvastatin 40mg','metformin 500mg'],'follow_up':['community nursing input','respiratory in 10 weeks'],'risk_indicator':['confusion noted at discharge']},
  'NOTE00010': {'symptom':[],'diagnosis':['acute exacerbation of copd','osteoarthritis','anxiety disorder'],'medication':['amoxicillin 500mg','bisoprolol 2.5mg'],'follow_up':['medication titration in primary care','cardiology in 6 weeks'],'risk_indicator':['social isolation flagged']},
  'NOTE00011': {'symptom':['shortness of breath'],'diagnosis':['anxiety disorder','type 2 diabetes mellitus'],'medication':['salbutamol inhaler','amlodipine 5mg'],'follow_up':['gp follow-up arranged','endocrinology in 9 weeks'],'risk_indicator':['medication non-compliance risk']},
  'NOTE00012': {'symptom':[],'diagnosis':['decompensated heart failure','chronic kidney disease stage 3','atrial fibrillation'],'medication':['atorvastatin 40mg','amoxicillin 500mg'],'follow_up':['district nurse for wound care','cardiology in 5 weeks'],'risk_indicator':['carer support required']},
  'NOTE00013': {'symptom':['fall with reduced mobility'],'diagnosis':['hypertension','osteoarthritis'],'medication':['omeprazole 20mg','furosemide 40mg'],'follow_up':['medication titration in primary care','gp in 10 weeks'],'risk_indicator':['social isolation flagged']},
  'NOTE00014': {'symptom':[],'diagnosis':['decompensated heart failure','copd','type 2 diabetes mellitus'],'medication':['bisoprolol 2.5mg','morphine 10mg'],'follow_up':['outpatient cardiology referral','cardiology in 5 weeks'],'risk_indicator':['high falls risk']},
  'NOTE00015': {'symptom':['shortness of breath'],'diagnosis':['previous mi','hypertension'],'medication':['doxycycline 100mg','apixaban 5mg'],'follow_up':['district nurse for wound care','gp in 9 weeks'],'risk_indicator':['carer support required']},
  'NOTE00016': {'symptom':['fall with reduced mobility'],'diagnosis':['type 2 diabetes mellitus','atrial fibrillation'],'medication':['ramipril 5mg','warfarin'],'follow_up':['community nursing input','endocrinology in 8 weeks'],'risk_indicator':['social isolation flagged']},
  'NOTE00017': {'symptom':['fall with reduced mobility'],'diagnosis':['atrial fibrillation','type 2 diabetes mellitus'],'medication':['insulin glargine','salbutamol inhaler'],'follow_up':['medication titration in primary care','respiratory in 12 weeks'],'risk_indicator':['high falls risk']},
  'NOTE00018': {'symptom':['hypoglycaemic episode'],'diagnosis':['anxiety disorder','type 2 diabetes mellitus'],'medication':['furosemide 40mg','insulin glargine'],'follow_up':['outpatient cardiology referral','endocrinology in 9 weeks'],'risk_indicator':['medication non-compliance risk']},
  'NOTE00019': {'symptom':[],'diagnosis':['community-acquired pneumonia','copd','osteoarthritis'],'medication':['amlodipine 5mg','doxycycline 100mg'],'follow_up':['district nurse for wound care','respiratory in 7 weeks'],'risk_indicator':['confusion noted at discharge']},
  'NOTE00020': {'symptom':[],'diagnosis':['community-acquired pneumonia','atrial fibrillation','hypertension'],'medication':['bisoprolol 2.5mg','warfarin'],'follow_up':['outpatient cardiology referral','cardiology in 4 weeks'],'risk_indicator':['social isolation flagged']},
}

SYMPTOMS = ['fall with reduced mobility','acute chest pain','shortness of breath','hypoglycaemic episode']
DIAGNOSES = ['decompensated heart failure','acute exacerbation of copd','community-acquired pneumonia','atrial fibrillation','osteoarthritis','copd','previous mi','type 2 diabetes mellitus','chronic kidney disease stage 3','anxiety disorder','hypertension']
MEDICINES = ['amoxicillin','furosemide','doxycycline','clopidogrel','bisoprolol','apixaban','warfarin','atorvastatin','morphine','omeprazole','salbutamol','amlodipine','metformin','ramipril','insulin glargine']
RISK = ['medication non-compliance risk','high falls risk','carer support required','confusion noted at discharge','social isolation flagged']
FUP = ['district nurse for wound care','outpatient cardiology referral','medication titration in primary care','gp follow-up arranged','community nursing input']

# Restrict diagnoses to the presenting condition or documented history.
# Avoid labelling a complaint as an established diagnosis.
PRESENTING = re.compile(r'\badmitted via the emergency department with (.+?)\.',re.I)
BACKGROUND = re.compile(r'\bbackground history includes (.+?)\.',re.I)
MEDS = re.compile(r'\bpatient commenced on (.+?)\.(?=\s+(?:Discharge plan:|Follow-up with|Risk indicators:)|$)',re.I)
DISCHARGE = re.compile(r'\bdischarge plan:\s*(.+?)\.',re.I)
FOLLOW = re.compile(r'\bfollow-up with (.+?)\.',re.I)
RISK_SECTION = re.compile(r'\brisk indicators:\s*(.+?)\.',re.I)


def norm(s):
    return re.sub(r'\s+', ' ', str(s).strip().lower().replace('–','-'))


def build_matcher(nlp, terms):
    matcher = PhraseMatcher(nlp.vocab, attr='LOWER')
    matcher.add('TERM', [nlp.make_doc(t) for t in sorted(terms,key=len,reverse=True)])
    return matcher


def lexicon_matches(nlp, matcher, txt):
    doc = nlp(txt)
    matches = [(start,end,norm(doc[start:end].text)) for _,start,end in matcher(doc)]
    # Drop substrings of longer matches, e.g. COPD inside acute exacerbation of COPD.
    matches.sort(key=lambda a:(a[0],-(a[1]-a[0])))
    keep=[]
    for s,e,v in matches:
        if not any(s>=x and e<=y for x,y,_ in keep):keep.append((s,e,v))
    return list(dict.fromkeys(v for _,_,v in keep))


def extract(text, nlp, matchers):
    out={c:[] for c in CATEGORIES}
    p=PRESENTING.search(text); b=BACKGROUND.search(text)
    if p:
        span=p.group(1)
        out['symptom']+=lexicon_matches(nlp,matchers['symptom'],span)
        out['diagnosis']+=lexicon_matches(nlp,matchers['diagnosis'],span)
    if b:out['diagnosis']+=lexicon_matches(nlp,matchers['diagnosis'],b.group(1))
    m=MEDS.search(text)
    if m:
        for chunk in re.split(r'\s+and\s+|\s*,\s*',m.group(1)):
            chunk=chunk.strip(); matches=lexicon_matches(nlp,matchers['medication'],chunk)
            if matches:out['medication'].append(norm(chunk))
    d=DISCHARGE.search(text)
    if d:out['follow_up']+=lexicon_matches(nlp,matchers['follow_up'],d.group(1))
    f=FOLLOW.search(text)
    if f:out['follow_up'].append(norm(f.group(1)))
    r=RISK_SECTION.search(text)
    if r:out['risk_indicator']+=lexicon_matches(nlp,matchers['risk_indicator'],r.group(1))
    return {k:list(dict.fromkeys(v)) for k,v in out.items()}


def evaluate(predictions, gold):
    totals=Counter()
    errors=[]
    for id, truth in gold.items():
        pred=predictions[id]
        for cat in CATEGORIES:
            y=set(map(norm,truth[cat])); z=set(map(norm,pred[cat]))
            tp=len(y&z);fp=len(z-y);fn=len(y-z)
            totals[(cat,'tp')]+=tp;totals[(cat,'fp')]+=fp;totals[(cat,'fn')]+=fn
            for phrase in sorted(z-y):errors.append({'note_id':id,'category':cat,'error':'false_positive','text':phrase})
            for phrase in sorted(y-z):errors.append({'note_id':id,'category':cat,'error':'false_negative','text':phrase})
    def report(tp,fp,fn):
        return {'tp':tp,'fp':fp,'fn':fn,'precision':round(tp/(tp+fp),4) if tp+fp else None,'recall':round(tp/(tp+fn),4) if tp+fn else None}
    by={k:report(*(totals[(k,t)] for t in ('tp','fp','fn'))) for k in CATEGORIES}
    aggregate=report(*(sum(totals[(k,t)] for k in CATEGORIES) for t in ('tp','fp','fn')))
    return {'sample_ids':list(gold),'n_notes':len(gold),'micro':aggregate,'by_type':by,'errors':errors,
            'evaluation_caveat':'Template-generated synthetic notes; 20 fixed notes and exact-normalized phrase matching. Gold was constructed from manually reviewed note content, not clinical expert adjudication. Do not generalize the scores to real clinical narratives.'}


def main():
    a=argparse.ArgumentParser();a.add_argument('--input',default='clinical_notes_sample.csv');a.add_argument('--outdir',default='outputs');args=a.parse_args()
    path=Path(args.input)
    if not path.exists():
        print('Input not found. Download clinical_notes_sample.csv from the MedAxis GitHub repository and save it beside this script.')
        try:
            import urllib.request
            urllib.request.urlretrieve(SOURCE,path)
            print('Downloaded synthetic notes.')
        except Exception as ex:raise SystemExit(f'Download failed: {ex}. Save the CSV manually and rerun.')
    df=pd.read_csv(path,dtype=str,keep_default_na=False)
    required={'NOTE_ID','NOTE_TEXT'}
    if not required.issubset(df.columns):raise ValueError(f'Missing columns: {required-set(df.columns)}')
    if len(df)!=200:print(f'WARNING expected 200 notes, received {len(df)}')
    if df.NOTE_ID.duplicated().any():raise ValueError('Duplicate NOTE_ID')
    nlp=spacy.blank('en')
    matchers={
      'symptom':build_matcher(nlp,SYMPTOMS),
      'diagnosis':build_matcher(nlp,DIAGNOSES),
      'medication':build_matcher(nlp,MEDICINES),
      'follow_up':build_matcher(nlp,FUP),
      'risk_indicator':build_matcher(nlp,RISK)}
    preds={str(row.NOTE_ID):extract(str(row.NOTE_TEXT),nlp,matchers) for row in df.itertuples(index=False)}
    missing=set(GOLD)-set(preds)
    if missing:raise ValueError(f'Missing 20-note evaluation IDs: {sorted(missing)}')
    evaluation=evaluate(preds,GOLD)
    out=Path(args.outdir);out.mkdir(parents=True,exist_ok=True)
    # No raw text or patient identifiers in outputs; NOTE_ID is a synthetic linkage key.
    with (out/'entities_200.jsonl').open('w',encoding='utf-8') as f:
        for id, entities in preds.items():f.write(json.dumps({'note_id':id,'entities':entities,'medication_details':[{'mention':m,'route':('inhaled (inhaler mentioned)' if 'inhaler' in m else 'not stated')} for m in entities['medication']]},ensure_ascii=False)+'\n')
    with (out/'evaluation_20.json').open('w',encoding='utf-8') as f:json.dump(evaluation,f,indent=2)
    examples={id:preds[id] for id in ('NOTE00001','NOTE00003')}
    # These are three deliberately constructed challenge cases, NOT errors observed
    # among the 20 synthetic source notes. They expose limitations the template test misses.
    stress_inputs = [
        {'case':'NEGATION', 'text':'Background history includes no atrial fibrillation.',
         'expected':'Do not extract atrial fibrillation as present; rule matcher may falsely extract it.'},
        {'case':'STOPPED_DRUG', 'text':'Patient commenced on Warfarin. Warfarin was subsequently stopped.',
         'expected':'Do not present Warfarin as an active discharge medication; rule matcher may falsely retain it.'},
        {'case':'PARAPHRASED_FOLLOW_UP', 'text':'Arrange GP surgery review next Tuesday.',
         'expected':'Extract a GP follow-up; the cue-based matcher may miss it.'},
    ]
    for c in stress_inputs: c['observed']=extract(c['text'],nlp,matchers)
    (out/'stress_tests_3.json').write_text(json.dumps(stress_inputs,indent=2),encoding='utf-8')
    (out/'examples_2_notes.json').write_text(json.dumps(examples,indent=2),encoding='utf-8')
    print('Processed notes:',len(preds),'| 20-note precision:',evaluation['micro']['precision'],'recall:',evaluation['micro']['recall'])
    print('Errors found:',len(evaluation['errors']))
    print('Outputs:',out.resolve())

if __name__=='__main__':main()
