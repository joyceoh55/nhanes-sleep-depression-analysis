"""Download CDC XPORT files, build SQLite views and export reproducible evidence.

Run from any directory with Python 3.10+ and pandas/numpy installed.
No credentials or individual medical records from an employer are used.
"""
from pathlib import Path
import hashlib, json, sqlite3, urllib.request
from datetime import datetime, timezone
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[1]
RAW=ROOT/'data/raw'
RESULTS=ROOT/'results'
PHQ=[f'DPQ{i:03d}' for i in range(10,100,10)]
SOURCES={
 'DEMO_J': ['SEQN','RIDAGEYR','RIAGENDR','RIDRETH3','SDMVSTRA','SDMVPSU','WTMEC2YR','WTINT2YR'],
 'DPQ_J': ['SEQN']+PHQ,
 'SLQ_J': ['SEQN','SLD012'],
}
TABLES={'DEMO_J':'demographics','DPQ_J':'depression','SLQ_J':'sleep'}

def build():
 RAW.mkdir(parents=True,exist_ok=True); RESULTS.mkdir(exist_ok=True)
 con=sqlite3.connect(ROOT/'data/nhanes.sqlite')
 manifest=[]
 for name,columns in SOURCES.items():
  path=RAW/f'{name}.xpt'
  url=f'https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/{name}.xpt'
  if not path.exists():
   payload=urllib.request.urlopen(url,timeout=90).read()
   if not payload.startswith(b'HEADER RECORD'): raise ValueError(f'{name}: expected XPORT bytes')
   path.write_bytes(payload)
  df=pd.read_sas(path,format='xport')[columns].copy()
  # pandas' IBM-float XPORT decoder can represent zero as ~5.4e-79.
  # Values this small cannot be meaningful for any selected NHANES variable.
  df=df.mask(df.abs()<1e-50,0)
  assert df.SEQN.notna().all() and df.SEQN.is_unique, f'{name}: duplicate/missing ID'
  integer_columns=[c for c in columns if c not in ['WTMEC2YR','WTINT2YR','SLD012']]
  for c in integer_columns:
   vals=df[c].dropna()
   assert np.allclose(vals,np.round(vals),rtol=0,atol=1e-10),c
   df[c]=df[c].round().astype('Int64')
  if name=='DPQ_J':
   assert all(set(df[c].dropna()).issubset({0,1,2,3,7,9}) for c in PHQ)
  df.to_sql(TABLES[name],con,if_exists='replace',index=False)
  con.execute(f'CREATE UNIQUE INDEX {TABLES[name]}_seqn ON {TABLES[name]}(SEQN)')
  manifest.append({'name':name,'url':url,'rows':len(df),'columns':columns,
                   'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bytes':path.stat().st_size})
 con.executescript((ROOT/'sql/01_prepare_analysis.sql').read_text())
 analytic=pd.read_sql_query('SELECT * FROM analysis_ready ORDER BY SEQN',con)
 analytic.to_csv(RESULTS/'analysis_ready_sql.csv',index=False,float_format='%.15g')
 summary=pd.read_sql_query((ROOT/'sql/02_summaries.sql').read_text(),con)
 summary.to_csv(RESULTS/'summary_sql.csv',index=False,float_format='%.15g')
 exclusions=pd.read_sql_query('SELECT cohort_status,COUNT(*) AS sample_n FROM cohort_audit GROUP BY cohort_status ORDER BY cohort_status',con)
 exclusions.to_csv(RESULTS/'cohort_flow.csv',index=False)
 qc={'raw_rows':{x['name']:x['rows'] for x in manifest},'joined_rows':con.execute('SELECT COUNT(*) FROM cohort_audit').fetchone()[0],
     'analysis_n':len(analytic),'unique_analysis_ids':int(analytic.SEQN.nunique()),
     'depression_orphans':con.execute('SELECT COUNT(*) FROM depression p LEFT JOIN demographics d USING(SEQN) WHERE d.SEQN IS NULL').fetchone()[0],
     'sleep_orphans':con.execute('SELECT COUNT(*) FROM sleep s LEFT JOIN demographics d USING(SEQN) WHERE d.SEQN IS NULL').fetchone()[0],
     'exclusions':exclusions.to_dict('records')}
 assert qc['joined_rows']==qc['raw_rows']['DEMO_J']
 assert qc['unique_analysis_ids']==qc['analysis_n']
 assert qc['depression_orphans']==qc['sleep_orphans']==0
 assert analytic.phq9_total.between(0,27).all() and analytic.mec_weight.gt(0).all()
 assert len(summary)==48
 now=datetime.now(timezone.utc).isoformat()
 (RESULTS/'source_manifest.json').write_text(json.dumps({'retrieved_at':now,'files':manifest},indent=2))
 (RESULTS/'quality_checks.json').write_text(json.dumps(qc,indent=2))
 print(json.dumps(qc,indent=2))
 print(summary.query("sex_filter=='All' and age_filter=='All'")[['sleep_filter','sample_n','cases_n','prevalence']].to_string(index=False))
 con.close()

if __name__=='__main__': build()

