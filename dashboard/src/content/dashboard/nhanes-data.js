export const SLEEP = ['Normal sleep','Short sleep','Long sleep'];
export const SEX = ['Female','Male'];
export const AGE = ['20-39','40-59','60+'];
export function selectedValue(value) { return !value || value==='all' ? 'All' : String(value); }
export function selectEstimate(rows, sleep='All', sex='All', age='All') {
  return rows.find(r=>r.sleep_filter===sleep && r.sex_filter===sex && r.age_filter===age);
}
export function selectBreakdown(rows, dimension, filters) {
  const sleep=selectedValue(filters.sleep),sex=selectedValue(filters.sex),age=selectedValue(filters.age);
  const choices=dimension==='sleep' ? SLEEP : dimension==='sex' ? SEX : AGE;
  const selected=dimension==='sleep'?sleep:dimension==='sex'?sex:age;
  return choices.filter(value=>selected==='All'||value===selected).map(value=>{
    const r=selectEstimate(rows,dimension==='sleep'?value:sleep,dimension==='sex'?value:sex,dimension==='age'?value:age);
    return r ? {...r,group:value,prevalenceRate:r.prevalence} : null;
  }).filter(Boolean);
}
export const pct=value=>Number.isFinite(value)?`${(value*100).toFixed(2)}%`:'Unavailable';
export const integer=value=>Number.isFinite(value)?new Intl.NumberFormat('en-US').format(value):'Unavailable';

