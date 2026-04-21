# Sleep Duration and Depressive Symptoms Among U.S. Adults

## Overview
This project examines whether sleep duration is associated with clinically significant depressive symptoms among U.S. adults using NHANES 2017–2018 data.

## Research Question
Is shorter sleep duration associated with higher odds of depressive symptoms among U.S. adults?

## Data Source
National Health and Nutrition Examination Survey (NHANES) 2017–2018:
- Demographics (`DEMO_J`)
- Depression screener (`DPQ_J`)
- Sleep questionnaire (`SLQ_J`)

## Methods
- Outcome: depressive symptoms, defined as PHQ-9 >= 10
- Exposure: sleep duration categorized as:
  - Short sleep: <7 hours
  - Normal sleep: 7–9 hours
  - Long sleep: >9 hours
- Covariates: age, sex, race/ethnicity
- Analysis: survey-weighted descriptive statistics, weighted prevalence estimates, and survey-weighted logistic regression

Survey-weighted methods were used because NHANES uses a complex, multistage sampling design, and weighting helps produce estimates that better represent the U.S. adult population.

## Key Findings
- Weighted depression prevalence was lowest among adults with normal sleep duration.
- Compared with normal sleep, short sleep was associated with higher odds of depressive symptoms.
- Long sleep was also associated with higher odds of depressive symptoms.
- The pattern suggested a U-shaped relationship between sleep duration and depressive symptoms.

## Files
- `R_Proj_portfolio_report_v2.qmd` — Quarto analysis file
- `Sleep Duration and Depressive Symptoms Among U.S. Adults.pdf` — rendered report

## Skills Demonstrated
- Data acquisition in R
- Data cleaning and recoding
- PHQ-9 score construction
- Survey-weighted analysis
- Logistic regression
- Data visualization
- Public health interpretation

## Note
This is a cross-sectional analysis, so the findings describe association rather than causation.