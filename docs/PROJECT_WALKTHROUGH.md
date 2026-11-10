# Explaining this project in an interview

This extension was prepared with AI assistance. Review, run, and understand the scripts before presenting their methods as skills you can perform independently. It is portfolio project work, not professional database or dashboard employment experience.

## Files to open

1. `sql/01_prepare_analysis.sql`: source joins, PHQ-9 scoring, eligibility rules, and an auditable analytic view.
2. `sql/02_summaries.sql`: CTEs, CROSS JOIN filter grid, conditional logic, weighted aggregation, NULLIF division protection, and a window-function benchmark.
3. `sql/03_quality_checks.sql`: uniqueness, orphan records, join coverage, exclusions, and missingness.
4. `scripts/validate_in_r.R`: independent reconstruction and survey-design validation.
5. `dashboard/src/content/dashboard/DashboardContent.jsx`: interactive filters, metrics, comparisons, and source bindings.
6. `results/validation_receipt.json`: what actually passed.

## Questions to practice

**Why join by SEQN?** It is the participant identifier shared by the three NHANES files. Source keys must be unique before joining; otherwise counts and weighted sums can multiply.

**Why keep a left-joined audit view?** It retains people without a depression or sleep record so excluded records remain visible. The final analysis view applies the complete-case criteria separately.

**Why not replace missing PHQ-9 responses with zero?** Zero means a valid “not at all” response. A missing, refused, or unknown item does not mean absence of the symptom.

**Why MEC weights?** DPQ_J was administered at the MEC. CDC directs use of WTMEC2YR, even though the sleep questionnaire was collected in the home.

**What makes these queries more than a basic SELECT?** They combine three source tables, reshape nine PHQ items with UNION ALL, use CTEs and CASE expressions, generate all filter combinations with CROSS JOIN, aggregate weighted numerators/denominators, and calculate a within-scope benchmark with a window function.

**What was validated?** SQL and independently reconstructed R data agree for all included participants and derived variables. All 48 subgroup counts and weighted prevalence estimates agree. Confidence intervals come from R survey methods, not from the SQL weighted mean alone.

**How does the dashboard respond to filters?** A selected combination retrieves its own validated domain estimate. The same scope feeds metrics, charts, source inspection, and exports. Returning to All restores the complete cohort.

**What should not be claimed?** That this establishes causality, diagnoses depression, measures current patient access performance, or demonstrates work with a production healthcare database. It demonstrates a public-data portfolio workflow.

## Resume wording after review and practice

“Extended an NHANES public-health analysis with SQLite joins, CTEs, conditional aggregation, and window functions; reconciled 4,765 participant records and 48 weighted subgroup summaries against an independent R workflow and developed an interactive dashboard with survey-adjusted confidence intervals.”

