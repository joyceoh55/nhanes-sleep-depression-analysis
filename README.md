# SQL and interactive dashboard extension

This repository now includes a SQLite workflow, independent R validation, and an interactive dashboard for NHANES 2017–2018 sleep duration and depressive symptoms.

**Method correction:** CDC specifies MEC examination weights (`WTMEC2YR`) for `DPQ_J`. The new SQL/dashboard extension uses those weights. The original Quarto report and PDF below are retained as historical files and use interview weights; their numerical results are not the corrected dashboard estimates. The extension does not refit or revalidate the historical logistic regression.

## What is included

- `sql/01_prepare_analysis.sql`: joins, PHQ-9 scoring, eligibility flags, and analytic views.
- `sql/02_summaries.sql`: CTEs, conditional logic, CROSS JOIN filter combinations, weighted aggregation, and a window-function comparison with normal sleep.
- `sql/03_quality_checks.sql`: source uniqueness, orphan records, join coverage, and exclusions.
- `scripts/build_data.py`: downloads CDC data and executes the SQLite workflow.
- `scripts/validate_in_r.R`: independently reconstructs the data and validates SQL against R survey calculations.
- `dashboard/`: interactive dashboard source with sleep, sex, and age filters, sample counts, weighted prevalence, confidence intervals, and source inspection.
- `docs/METHODS.md`: cohort, weighting, uncertainty, validation, and limitations.
- `docs/PROJECT_WALKTHROUGH.md`: explanations and interview practice questions.
- `docs/VERIFICATION.md`: completed checks and remaining browser-review limits.

## Reproduce the analysis

```bash
python -m pip install -r requirements.txt
python scripts/build_data.py
```

Install the R packages `foreign`, `survey`, and `jsonlite`, then run:

```bash
Rscript scripts/validate_in_r.R
python -m unittest discover -s tests -p 'test_*.py' -v
node --test tests/dashboard.test.mjs
```

The pipeline downloads public CDC XPORT files into `data/raw/` and creates `data/nhanes.sqlite`. Raw files, the database, and participant-level exports are excluded from Git. Aggregate outputs, source checksums, R session information, and validation receipts are included.

## Validated results

The complete-case sample contains **4,765 adults**, including **427** with PHQ-9 >=10. MEC-weighted prevalence is **8.43%** overall (95% CI **7.34–9.67%**), **6.93%** for normal sleep, **10.65%** for short sleep, and **13.39%** for long sleep. These are historical, cross-sectional estimates and do not establish causality or a clinical diagnosis.

All 4,765 participant records and 48 subgroup summaries were reconciled against an independent reconstruction in R. Confidence intervals use Taylor-linearized survey variance with domain subsetting. See the full methods before interpreting subgroup estimates.

## Authorship and learning

The original R analysis is Joyce Oh's portfolio work. This extension was prepared with AI assistance and includes executable validation. It should be reviewed and understood before representing its techniques as independently mastered skills. This is public-data portfolio experience, not employment experience with a production database.

---

## Historical project description

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
