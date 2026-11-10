# Methods and validation

## Scope

This extension explores sleep duration and depressive symptoms in NHANES 2017–2018. It adds SQLite queries and an interactive dashboard to the existing R portfolio. It does not estimate current prevalence, a causal effect, or a clinical diagnosis.

The source files are CDC's DEMO_J (9,254 rows), DPQ_J (5,533 rows), and SLQ_J (6,161 rows). Each has one row per SEQN. The SQL pipeline starts with demographics and left-joins the other files; all 9,254 demographic rows remain available for the audit. Source SHA-256 checksums and download URLs are retained in `results/source_manifest.json`.

## Outcome and exposure

The PHQ-9 total is the sum of DPQ010–DPQ090, with each response required to be 0–3. Refused (7), don't know (9), and missing responses are treated as missing. A total is calculated only with all nine responses; PHQ-9 >=10 defines the depressive-symptom screening outcome. Missing items never become zero.

SLD012 describes the main sleep period on weekdays/workdays. Categories are short (<7 hours), normal (7–9 hours), and long (>9 hours). The source's boundary codes 2 and 12 represent the respective extreme categories; they are used only for category membership, not interpreted as exact sleep durations. Sleep may exclude naps or other sleeping periods. The PHQ-9 itself contains a sleep item, which creates conceptual overlap with the exposure.

## Cohort and exclusions

Adults age 20 or older must have a complete PHQ-9, usable sleep information, known sex and race/ethnicity, positive MEC weight, and observed survey stratum and PSU. These choices retain the original project's complete-case covariate scope. Race/ethnicity is required for compatibility but is not a dashboard filter. Age is top-coded in the public data; the broad 60+ group avoids treating the top code as an exact oldest age.

Sequential, mutually exclusive exclusions are 3,685 under 20 or missing age, 744 with incomplete PHQ-9, and 60 with missing/invalid sleep. The final sample is 4,765 adults. These sequential counts should not be interpreted as independent missingness rates.

## Weight correction

The historical Quarto report uses WTINT2YR. CDC explicitly states that DPQ_J requires **WTMEC2YR**, because the depression screener was collected in the Mobile Examination Center. This extension uses WTMEC2YR and documents the difference in `results/weight_sensitivity.csv`. The original Quarto file and PDF are preserved as historical artifacts; their numerical results are not substituted for the corrected dashboard estimates.

Weighted prevalence is `SUM(WTMEC2YR * depression) / SUM(WTMEC2YR)` within the complete-case domain. SQL calculates point estimates, counts, and weight totals. It does not compute an ordinary binomial confidence interval and label it survey-adjusted.

## Independent R validation and uncertainty

`scripts/validate_in_r.R` independently reads the original XPORT files with `foreign::read.xport`, merges and derives the cohort in base R, and checks all 13 exported participant columns against SQL. This is a reconstruction from raw sources, not a re-import of SQL-derived outcomes.

The full positive-weight MEC sample defines the survey design using SDMVPSU, SDMVSTRA, and WTMEC2YR. The adult complete-case cohort and each dashboard filter combination are then formed as survey domains. `survey::svymean` validates the SQL point estimates; `survey::svyciprop(method='logit', df=degf(domain))` supplies 95% confidence intervals using Taylor-linearized variance and t critical values.

All 48 combinations (All/three sleep groups × All/two sexes × All/three age groups) were checked. Counts and case counts match exactly; the largest absolute SQL–R prevalence difference is approximately 5e-16. The analytic survey design has 15 degrees of freedom. R 4.5.0 and survey 4.4.2 were used; session information is saved.

## Filtering and interpretation

The dashboard selects a validated domain estimate for the exact filter combination. It never averages subgroup percentages, sums overlapping All/subgroup rows, or recomputes a naive confidence interval. Sample counts are unweighted; prevalence and intervals are survey-weighted. Sources and exports retain the same selected scope as the displayed component.

Complete-case exclusions can affect representativeness despite weighting. Nonresponse, self-reported sleep, residual confounding, and the cross-sectional design limit interpretation. The extension does not refit the historical logistic regression or validate its reported odds ratios.

## Authoritative references

- [CDC DPQ_J codebook and MEC weight requirement](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DPQ_J.htm)
- [CDC SLQ_J codebook and sleep variable definitions](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/SLQ_J.htm)
- [CDC weighting tutorial](https://wwwn.cdc.gov/nchs/nhanes/tutorials/weighting.aspx)
- [CDC variance estimation and domain-analysis tutorial](https://wwwn.cdc.gov/nchs/nhanes/tutorials/varianceestimation.aspx)

