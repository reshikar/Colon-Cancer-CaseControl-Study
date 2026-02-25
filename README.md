# Colon Cancer Case–Control Study: Fiber, BMI, and Effect Modification (SAS)
## Overview
This project analyzes a case–control dataset to examine the association between dietary fiber intake and colon cancer case status (CACO), including evaluation of effect modification by BMI and other covariates.
## Study Design
- Design: Case–control study  
- Outcome: `CACO` (1 = Case, 0 = Control)
## Key Variables
- Exposure:
  - `FIBER` (continuous) and `FIBERCAT` (categorized)
- Effect modifier (interaction):
  - `BMI` (calculated from weight and height) and `BMICAT` (categorized)
- Covariates:
  - `EDGP` (education)
  - `FAMCAN` (family history of cancer)
  - `AGEDX` / `AGEDX10` (age categories)
## Methods
- Data cleaning and recoding of missing values
- Descriptive statistics (means, frequencies) by case status
- Logistic regression using `PROC GENMOD` with logit link
- Interaction models:
  - `FIBERCAT × BMICAT`
  - `FIBERCAT × EDGP`
  - `FIBERCAT × AGEDX10`
- Odds ratios estimated using `ESTIMATE` statements
## Software
SAS

## Data Availability
Dataset is not included (course-provided / restricted).
