# Independent reconstruction from the CDC XPORT files, not from SQL-derived variables.
# Packages: foreign, survey, jsonlite. Run after scripts/build_data.py.
args <- commandArgs(trailingOnly=FALSE)
script <- sub('^--file=', '', args[grepl('^--file=', args)])
root <- normalizePath(file.path(dirname(script), '..'))
suppressPackageStartupMessages({library(foreign); library(survey); library(jsonlite)})
options(survey.lonely.psu='fail')

demo <- read.xport(file.path(root,'data/raw/DEMO_J.xpt'))
dpq <- read.xport(file.path(root,'data/raw/DPQ_J.xpt'))
slq <- read.xport(file.path(root,'data/raw/SLQ_J.xpt'))
phq <- sprintf('DPQ%03d',seq(10,90,10))
stopifnot(!anyDuplicated(demo$SEQN),!anyDuplicated(dpq$SEQN),!anyDuplicated(slq$SEQN))
dpq <- dpq[,c('SEQN',phq)]
for (v in phq) dpq[[v]][!(dpq[[v]] %in% 0:3)] <- NA_real_
dpq$phq9_total <- rowSums(dpq[,phq],na.rm=FALSE)
raw <- merge(merge(demo,dpq[,c('SEQN','phq9_total')],by='SEQN',all.x=TRUE),
             slq[,c('SEQN','SLD012')],by='SEQN',all.x=TRUE)
stopifnot(nrow(raw)==nrow(demo),!anyDuplicated(raw$SEQN))
raw$depression <- ifelse(is.na(raw$phq9_total),NA,as.integer(raw$phq9_total>=10))
raw$sex <- ifelse(raw$RIAGENDR==1,'Male',ifelse(raw$RIAGENDR==2,'Female',NA))
raw$age_group <- ifelse(raw$RIDAGEYR>=60,'60+',
                  ifelse(raw$RIDAGEYR>=40,'40-59',ifelse(raw$RIDAGEYR>=20,'20-39',NA)))
raw$sleep_category <- ifelse(is.na(raw$SLD012) | raw$SLD012<2 | raw$SLD012>12,NA,
                       ifelse(raw$SLD012<7,'Short sleep',ifelse(raw$SLD012<=9,'Normal sleep','Long sleep')))
raw$included <- with(raw,!is.na(RIDAGEYR) & RIDAGEYR>=20 & !is.na(phq9_total) &
  !is.na(sleep_category) & !is.na(sex) & RIDRETH3 %in% c(1,2,3,4,6,7) &
  !is.na(WTMEC2YR) & WTMEC2YR>0 & !is.na(SDMVSTRA) & !is.na(SDMVPSU))
independent <- raw[raw$included,c('SEQN','RIDAGEYR','age_group','sex','RIDRETH3','SDMVSTRA',
  'SDMVPSU','WTMEC2YR','WTINT2YR','phq9_total','depression','SLD012','sleep_category')]
names(independent) <- c('SEQN','age','age_group','sex','race_code','stratum','psu','mec_weight',
  'interview_weight','phq9_total','depression','sleep_hours_code','sleep_category')
independent <- independent[order(independent$SEQN),]
sql <- read.csv(file.path(root,'results/analysis_ready_sql.csv'),check.names=FALSE)
stopifnot(identical(independent$SEQN,as.numeric(sql$SEQN)))
for (v in names(independent)) {
 if (is.numeric(independent[[v]])) stopifnot(isTRUE(all.equal(independent[[v]],as.numeric(sql[[v]]),tolerance=1e-12)))
 else stopifnot(identical(as.character(independent[[v]]),as.character(sql[[v]])))
}

# Keep the full positive-weight MEC design, then form adult complete-case domains.
# This preserves the survey structure when estimating subgroup uncertainty.
full <- raw[!is.na(raw$WTMEC2YR) & raw$WTMEC2YR>0 & !is.na(raw$SDMVPSU) & !is.na(raw$SDMVSTRA),]
design <- svydesign(ids=~SDMVPSU,strata=~SDMVSTRA,weights=~WTMEC2YR,nest=TRUE,data=full)
analytic_design <- subset(design,included)
summaries <- read.csv(file.path(root,'results/summary_sql.csv'),check.names=FALSE)
ci_low <- ci_high <- r_prevalence <- numeric(nrow(summaries))
for (i in seq_len(nrow(summaries))) {
 r <- summaries[i,]
 keep <- with(analytic_design$variables,
   (r$sleep_filter=='All' | sleep_category==r$sleep_filter) &
   (r$sex_filter=='All' | sex==r$sex_filter) &
   (r$age_filter=='All' | age_group==r$age_filter))
 sub <- analytic_design[keep,]
 stopifnot(sum(keep)==r$sample_n,sum(sub$variables$depression)==r$cases_n)
 p <- svymean(~depression,sub)
 r_prevalence[i] <- as.numeric(coef(p))
 stopifnot(abs(r_prevalence[i]-r$prevalence)<1e-12)
 interval <- svyciprop(~depression,sub,method='logit',df=degf(sub))
 bounds <- as.numeric(confint(interval))
 ci_low[i] <- bounds[1]; ci_high[i] <- bounds[2]
}
summaries$r_prevalence <- r_prevalence
summaries$ci_low <- ci_low; summaries$ci_high <- ci_high
summaries$ci_method <- '95% logit CI with Taylor-linearized survey variance and t critical value'
write.csv(summaries,file.path(root,'results/summary_validated.csv'),row.names=FALSE)

# Record the weighting correction without overwriting the historical report.
legacy <- independent
legacy$legacy_numerator <- legacy$interview_weight*legacy$depression
legacy_rates <- aggregate(cbind(legacy_numerator,interview_weight)~sleep_category,legacy,sum)
legacy_rates$legacy_interview_prevalence <- legacy_rates$legacy_numerator/legacy_rates$interview_weight
write.csv(legacy_rates,file.path(root,'results/weight_sensitivity.csv'),row.names=FALSE)
receipt <- list(status='passed',analysis_n=nrow(independent),participant_columns_compared=names(independent),
  summary_combinations_compared=nrow(summaries),max_prevalence_absolute_error=max(abs(r_prevalence-summaries$prevalence)),
  interval_method=unique(summaries$ci_method),design_degrees_freedom=degf(analytic_design),
  R_version=R.version.string,survey_version=as.character(packageVersion('survey')),
  checks=c('Source key uniqueness','Left joins preserve participant grain','Independent R reconstruction matches SQL by ID and all 13 columns',
           'All 48 SQL grouped counts, cases and weighted rates match R survey calculations','CIs use full MEC survey design with domain subsetting'))
write_json(receipt,file.path(root,'results/validation_receipt.json'),auto_unbox=TRUE,pretty=TRUE)
capture.output(sessionInfo(),file=file.path(root,'results/R_session_info.txt'))
print(receipt)
print(summaries[summaries$sex_filter=='All' & summaries$age_filter=='All',c('sleep_filter','sample_n','prevalence','ci_low','ci_high')])

