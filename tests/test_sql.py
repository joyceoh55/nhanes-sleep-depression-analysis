"""Small synthetic edge cases; no downloaded data required."""
from pathlib import Path
import sqlite3, unittest

ROOT=Path(__file__).resolve().parents[1]

class PreparationTests(unittest.TestCase):
 def setUp(self):
  self.db=sqlite3.connect(':memory:')
  self.db.executescript('''CREATE TABLE demographics(SEQN INTEGER PRIMARY KEY,RIDAGEYR INTEGER,RIAGENDR INTEGER,RIDRETH3 INTEGER,SDMVSTRA INTEGER,SDMVPSU INTEGER,WTMEC2YR REAL,WTINT2YR REAL);
  CREATE TABLE depression(SEQN INTEGER PRIMARY KEY,DPQ010 INTEGER,DPQ020 INTEGER,DPQ030 INTEGER,DPQ040 INTEGER,DPQ050 INTEGER,DPQ060 INTEGER,DPQ070 INTEGER,DPQ080 INTEGER,DPQ090 INTEGER);
  CREATE TABLE sleep(SEQN INTEGER PRIMARY KEY,SLD012 REAL);''')
  for i in range(1,10):
   age=19 if i==4 else 35
   weight=None if i==7 else 10.0
   race=None if i==8 else 3
   self.db.execute('INSERT INTO demographics VALUES(?,?,?,?,?,?,?,?)',(i,age,1,race,1,1,weight,10.0))
   scores=[1]*9 if i==1 else [2]*9 if i==2 else [0]*9
   if i==5:scores[0]=7
   if i==9:scores=[1]*8+[2]
   self.db.execute('INSERT INTO depression VALUES('+','.join(['?']*10)+')',[i]+scores)
   self.db.execute('INSERT INTO sleep VALUES(?,?)',(i,None if i==6 else 6 if i==2 else 10 if i==3 else 8))
  self.db.executescript((ROOT/'sql/01_prepare_analysis.sql').read_text())
 def tearDown(self):self.db.close()
 def test_left_join_grain(self):
  self.assertEqual(self.db.execute('SELECT COUNT(*),COUNT(DISTINCT SEQN) FROM cohort_audit').fetchone(),(9,9))
 def test_complete_case_and_exact_threshold(self):
  self.assertEqual(self.db.execute('SELECT SEQN FROM analysis_ready ORDER BY SEQN').fetchall(),[(1,),(2,),(3,),(9,)])
  self.assertEqual(self.db.execute('SELECT phq9_total,depression FROM analysis_ready WHERE SEQN=9').fetchone(),(10,1))
 def test_refusal_does_not_become_zero(self):
  self.assertEqual(self.db.execute('SELECT valid_phq_items,phq9_total FROM phq_scores WHERE SEQN=5').fetchone(),(8,None))
 def test_missing_value_exclusions(self):
  for i,reason in [(6,'3 Missing or invalid sleep'),(7,'5 No positive MEC weight'),(8,'4 Missing demographics')]:
   self.assertEqual(self.db.execute('SELECT cohort_status FROM cohort_audit WHERE SEQN=?',(i,)).fetchone()[0],reason)
 def test_weighted_summary_and_empty_scopes(self):
  cur=self.db.execute((ROOT/'sql/02_summaries.sql').read_text());cols=[c[0] for c in cur.description]
  rows=[dict(zip(cols,r)) for r in cur]
  self.assertEqual(len(rows),48)
  overall=next(r for r in rows if r['sleep_filter']==r['sex_filter']==r['age_filter']=='All')
  self.assertEqual(overall['sample_n'],4);self.assertEqual(overall['cases_n'],2)
  self.assertAlmostEqual(overall['prevalence'],.5)
  empty=next(r for r in rows if r['sex_filter']=='Female' and r['age_filter']=='All' and r['sleep_filter']=='All')
  self.assertEqual(empty['sample_n'],0);self.assertIsNone(empty['prevalence'])

if __name__=='__main__':unittest.main()

