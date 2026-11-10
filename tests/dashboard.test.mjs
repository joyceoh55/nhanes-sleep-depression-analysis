import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {SLEEP,SEX,AGE,selectEstimate,selectBreakdown} from '../dashboard/src/content/dashboard/nhanes-data.js';
const snapshot=JSON.parse(readFileSync(new URL('../dashboard/src/data.json',import.meta.url),'utf8'));
const rows=snapshot.queries.prevalence.rows;
test('default view uses one overall estimate, not summed overlapping summary rows',()=>{
 const all=selectEstimate(rows);assert.equal(all.sample_n,4765);assert.equal(all.cases_n,427);
 assert.ok(Math.abs(all.prevalence-0.0843197382842377)<1e-12);
});
test('all 48 filter combinations have unique, validated intervals and reconciling breakdowns',()=>{
 for(const sleep of ['all',...SLEEP])for(const sex of ['all',...SEX])for(const age of ['all',...AGE]){
  const f={sleep,sex,age};const s=selectEstimate(rows,sleep==='all'?'All':sleep,sex==='all'?'All':sex,age==='all'?'All':age);
  assert.ok(s);assert.ok(s.ci_low<s.prevalence&&s.prevalence<s.ci_high);
  for(const dimension of ['sleep','sex','age']){
   const parts=selectBreakdown(rows,dimension,f);
   assert.equal(parts.reduce((n,r)=>n+r.sample_n,0),s.sample_n);
   const denominator=parts.reduce((n,r)=>n+r.weight_sum,0);
   const numerator=parts.reduce((n,r)=>n+r.weighted_cases,0);
   assert.ok(Math.abs(numerator/denominator-s.prevalence)<1e-12);
  }
 }
});
test('resetting all filters restores the complete cohort',()=>{
 const filtered=selectBreakdown(rows,'sleep',{sex:'Female',age:'40-59',sleep:'Short sleep'});
 assert.equal(filtered.length,1);assert.ok(filtered[0].sample_n<4765);
 assert.equal(selectBreakdown(rows,'sleep',{sex:'all',age:'all',sleep:'all'}).reduce((n,r)=>n+r.sample_n,0),4765);
});

