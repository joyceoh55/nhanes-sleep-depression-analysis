import React from 'react';
import {DataComponent,DataTable,Dropdown,EvidenceChart,Filters,MetricCard,Section,SortableItem,SortableRegion,useDashboardTabs,useDataApp} from '../../data-app-public.jsx';
import {SLEEP,SEX,AGE,selectedValue,selectEstimate,selectBreakdown,pct,integer} from './nhanes-data.js';
import './nhanes.css';

/** @type {import('../../data-app-public.jsx').ChartSpec} */
const chart={type:'horizontalBar',x:'group',y:'prevalenceRate',stackable:false,valueDecimals:2,showXAxisLabel:false,showYAxisLabel:false};
const choices={sleep:['all',...SLEEP],sex:['all',...SEX],age:['all',...AGE]};
const labels={sleep:'Sleep category',sex:'Sex',age:'Age group'};
function Intervals({rows}) {
 return <div className="nhanes-intervals" data-reviewed-rows="true">{rows.map(r=><div key={r.group}>
  <strong>{r.group}</strong><span>{pct(r.prevalence)} <span className="nhanes-muted">· n = {integer(r.sample_n)}</span></span>
  <span className="nhanes-muted">95% CI {pct(r.ci_low)}–{pct(r.ci_high)}</span>
 </div>)}</div>;
}
export function DashboardContent() {
 const {queries,filters,setFilter}=useDataApp();
 const {activeTabId}=useDashboardTabs([{id:'explore',label:'Explore',filterIds:['sleep','sex','age']},{id:'validation',label:'Validation and methods',filterIds:[]}]);
 const rows=queries.prevalence?.rows??[];
 const selected=selectEstimate(rows,selectedValue(filters.sleep),selectedValue(filters.sex),selectedValue(filters.age));
 const scopeFilters=Object.entries(labels).map(([id,label])=>({field:`${id}_filter`,label,value:selectedValue(filters[id]),queryIds:['prevalence']}));
 const sleepRows=selectBreakdown(rows,'sleep',filters),sexRows=selectBreakdown(rows,'sex',filters),ageRows=selectBreakdown(rows,'age',filters);
 const sourceRows=selected?[selected]:[];
 const isValidation=activeTabId==='validation';
 return <article className="nhanes-content">
  {!isValidation && <>
   <Filters sticky>{Object.entries(labels).map(([id,label])=><Dropdown key={id} label={label} showLabel value={String(filters[id]??'all')}
     choices={choices[id]} choiceLabels={{all:'All'}} onChange={value=>setFilter(id,value)}/>)}</Filters>
   <p className="nhanes-context" data-editable-id="nhanes-population">NHANES 2017–2018 · Adults age 20+ with complete analysis data · Depressive symptoms defined as PHQ-9 ≥10</p>
   <Section id="nhanes-summary-heading" spacing="none">
    <SortableRegion id="nhanes-summary" variant="canvas" columns={12} spacing="standard" label="Summary metrics"
      rows={[{id:'nhanes-metrics-row',kind:'metrics',items:['sample-n','case-n','weighted-prevalence']}]}>
     <SortableItem id="sample-n" label="Participants" kind="metric" span={4}>
      <MetricCard id="sample-n" queryId="prevalence" title="Participants" value={integer(selected?.sample_n)} displayRows={sourceRows} sourceRows={sourceRows} scopeFilters={scopeFilters} description="Unweighted complete-case sample size for the selected subgroup."/>
     </SortableItem>
     <SortableItem id="case-n" label="Participants with PHQ-9 at least 10" kind="metric" span={4}>
      <MetricCard id="case-n" queryId="prevalence" title="PHQ-9 ≥10" value={integer(selected?.cases_n)} displayRows={sourceRows} sourceRows={sourceRows} scopeFilters={scopeFilters} description="Unweighted participants meeting the depressive-symptom screening threshold; not a clinical diagnosis."/>
     </SortableItem>
     <SortableItem id="weighted-prevalence" label="Weighted prevalence" kind="metric" span={4}>
      <MetricCard id="weighted-prevalence" queryId="prevalence" title="Weighted prevalence" value={pct(selected?.prevalence)} displayRows={sourceRows} sourceRows={sourceRows} scopeFilters={scopeFilters}
       description="MEC weights for participants with PHQ-9 ≥10 divided by total MEC weights in the selected subgroup. This adjusts contributions for the NHANES sampling design.">
        <span className="nhanes-ci-label">95% CI {pct(selected?.ci_low)}–{pct(selected?.ci_high)}</span>
      </MetricCard>
     </SortableItem>
    </SortableRegion>
   </Section>
   <Section id="sleep-comparison-heading" title="Depressive symptoms by sleep duration" spacing="after-metrics">
    <EvidenceChart id="sleep-prevalence" queryId="prevalence" title="Weighted prevalence by sleep category" spec={chart} rows={sleepRows} sourceRows={sleepRows} scopeFilters={scopeFilters} height={200}
      description="Weekday/workday main sleep period: short <7 hours, normal 7–9 hours, long >9 hours. Confidence intervals use survey-design variance.">
      <Intervals rows={sleepRows}/>
    </EvidenceChart>
   </Section>
   <Section id="demographic-comparisons-heading" title="Demographic comparisons" columns={2}>
    <EvidenceChart id="age-prevalence" queryId="prevalence" title="Weighted prevalence by age group" spec={chart} rows={ageRows} sourceRows={ageRows} scopeFilters={scopeFilters} height={200}>
      <Intervals rows={ageRows}/>
    </EvidenceChart>
    <EvidenceChart id="sex-prevalence" queryId="prevalence" title="Weighted prevalence by sex" spec={chart} rows={sexRows} sourceRows={sexRows} scopeFilters={scopeFilters} height={200}>
      <Intervals rows={sexRows}/>
    </EvidenceChart>
   </Section>
   <p className="nhanes-footnote" data-editable-id="nhanes-limitations">Cross-sectional associations do not establish causation. PHQ-9 includes a sleep symptom item. Complete-case exclusions may affect representativeness; estimates describe 2017–2018, not current prevalence.</p>
  </>}
  {isValidation && <>
   <Section id="validation-heading" title="SQL and R reconciliation" spacing="none">
    <DataComponent id="validation-checks" queryId="validation" kind="table" title="Independent validation checks" sourceRows={queries.validation?.rows??[]} displayRows={queries.validation?.rows??[]}>
      <DataTable rows={queries.validation?.rows??[]} columns={[{field:'check',label:'Check'},{field:'result',label:'Result',presentation:'status'}]} searchable={false} label="SQL and R validation checks"/>
    </DataComponent>
   </Section>
   <Section id="cohort-heading" title="Cohort construction">
    <DataComponent id="cohort-flow" queryId="cohort_flow" kind="table" title="Sequential exclusions from the demographic file" sourceRows={queries.cohort_flow?.rows??[]} displayRows={queries.cohort_flow?.rows??[]} description="Overall cohort construction; exploration filters do not apply to this audit.">
      <DataTable rows={queries.cohort_flow?.rows??[]} columns={[{field:'cohort_status',label:'Step'},{field:'sample_n',label:'Participants'}]} searchable={false} label="Sequential participant exclusions"/>
    </DataComponent>
   </Section>
   <section className="nhanes-methods">
    <h2>How to interpret the analysis</h2>
    <p>SQL joins three CDC source files by participant ID, scores complete PHQ-9 responses, applies eligibility rules, and computes weighted numerators and denominators. An independent R reconstruction matches all 4,765 participants and all 48 filter combinations.</p>
    <p>The depression screener was collected in the Mobile Examination Center, so this version uses <strong>WTMEC2YR</strong>. The historical Quarto report used interview weights; its results are retained separately and are not the estimates displayed here.</p>
    <p>R’s survey package calculates 95% logit confidence intervals with Taylor-linearized variance. Domains are formed after defining the full positive-weight MEC survey design, retaining strata and primary sampling units. A filtered view selects a precomputed, validated domain estimate rather than averaging subgroup percentages.</p>
    <p>Sleep duration refers to the main sleeping period on weekdays/workdays and may exclude naps. The study is cross-sectional, PHQ-9 ≥10 is a screening threshold, and complete-case selection may introduce bias.</p>
    <p><a href="https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DPQ_J.htm" target="_blank" rel="noreferrer">CDC depression screener documentation</a> · <a href="https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/SLQ_J.htm" target="_blank" rel="noreferrer">CDC sleep documentation</a></p>
   </section>
  </>}
 </article>;
}
