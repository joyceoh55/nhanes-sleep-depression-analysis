# Verification record

## Completed

- Downloaded all three XPORT files directly from CDC and retained SHA-256 checksums.
- Checked unique participant identifiers, source orphans, join grain, derived-variable ranges, positive weights, and sequential exclusions.
- Executed all SQL against actual NHANES data.
- Independently reconstructed the cohort from raw XPORT data in R.
- Matched 4,765 participant records across 13 columns and all 48 grouped summaries.
- Computed survey-adjusted intervals using the full MEC design and domain subsetting.
- Executed SQL edge-case tests covering incomplete PHQ responses, threshold handling, missing data, empty filter combinations, and weighted summaries.
- Executed dashboard data-scope tests across all 48 filter combinations and reset-to-All behavior.
- Passed the Data app's semantic/API and source-shape checks and compiled the dashboard.

## Verification limit

Browser automation was unavailable during this build. Desktop/mobile visual inspection, actual dropdown clicks, tooltips, source-dialog interactions, chart image export, and screenshots have not been verified. The data-scope tests exercise the exact selection helpers used by the application, but do not substitute for browser interaction checks.

The draft pull request should retain this limitation until an actual browser review is completed. No screenshots are represented as having been captured.
