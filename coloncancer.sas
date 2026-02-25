
 Project: Colon Cancer Case–Control Study (CACO) — SAS
 Design: Case–control (CACO: 1=case, 0=control)
 Overview:
  - Data checks + recoding missing values
  - Derived BMI and categorized BMI/FIBER/AGE
  - Descriptives and t-tests by case status
  - Logistic regression (PROC GENMOD, logit) for unadjusted/adjusted models
  - Interaction models: FIBERCAT×BMICAT, FIBERCAT×EDGP, FIBERCAT×AGEDX10
/*0) USER SETUP (EDIT PATH) */
%let proj = YOUR_PROJECT_FOLDER_PATH;   /* e.g., C:\Users\Reshika\Epi2\caco_project */

/* If your dataset is a .sas7bdat file stored in &proj */
libname A6 "&proj.";
run;

data A6.caco;
  set "&proj./caco.sas7bdat";   /* Rename your file to caco.sas7bdat for simplicity */
run;

/*  1) QC + DESCRIPTIVES */
proc contents data=A6.caco; run;

proc freq data=A6.caco;
  tables CACO EDGP FAMCAN;
run;

proc means data=A6.caco n mean min max;
  var AGEDX INCHES WTMIN5 FIBER;
run;

/* Flag suspicious values */
proc print data=A6.caco;
  where FAMCAN = 9 or WTMIN5 = 999 or
        CACO not in (0, 1) or
        EDGP not in (1, 2, 3) or
        AGEDX < 18 or AGEDX > 100 or
        INCHES < 50 or INCHES > 90 or
        WTMIN5 < 80 or WTMIN5 > 500 or
        FIBER < 0 or FIBER > 100;
  var ID CACO EDGP FAMCAN AGEDX INCHES WTMIN5 FIBER;
run;

/*  2) RECODE MISSING + DERIVE BMI */
data A6.caco_recode;
  set A6.caco;
  if FAMCAN = 9 then FAMCAN = .;
  if WTMIN5 = 999 then WTMIN5 = .;
run;

proc freq data=A6.caco_recode;
  tables FAMCAN WTMIN5;
run;

proc means data=A6.caco_recode n mean min max;
  var AGEDX INCHES WTMIN5 FIBER;
run;

/* BMI = 703*weight(lb)/height(in)^2 */
data A6.caco_recode;
  set A6.caco_recode;
  if WTMIN5 ne . and INCHES ne . then BMI = (703 * WTMIN5) / (INCHES * INCHES);
  else BMI = .;
run;

/* 3) PLOTS*/
proc sort data=A6.caco_recode;
  by CACO;
run;

proc boxplot data=A6.caco_recode;
  plot FIBER*CACO / boxstyle=schematic;
  plot BMI*CACO   / boxstyle=schematic;
  plot AGEDX*CACO / boxstyle=schematic;
run;

/*  4) CATEGORIZATION */
data A6.caco_recode;
  set A6.caco_recode;

  /* BMI categories */
  if BMI < 25 then BMICAT = 1;
  else if 25 <= BMI <= 28 then BMICAT = 2;
  else if BMI > 28 then BMICAT = 3;
  if BMI = . then BMICAT = .;

  /* Fiber categories */
  if FIBER < 3.714 then FIBERCAT = 1;
  else if 3.714 <= FIBER <= 5.473 then FIBERCAT = 2;
  else if FIBER > 5.473 then FIBERCAT = 3;

  /* Age categories (50–79) */
  if 50 <= AGEDX < 60 then AGEDX10 = 1;
  else if 60 <= AGEDX < 70 then AGEDX10 = 2;
  else if 70 <= AGEDX < 80 then AGEDX10 = 3;
run;

proc format;
  value BMICATlabel  1='<25' 2='25-28' 3='>28';
  value FIBERCATlabel 1='<3.714' 2='3.714-5.473' 3='>5.473';
  value AGEDX10label  1='50-59' 2='60-69' 3='70-79';
run;

proc freq data=A6.caco_recode order=formatted;
  tables BMICAT FIBERCAT AGEDX10;
  format BMICAT BMICATlabel. FIBERCAT FIBERCATlabel. AGEDX10 AGEDX10label.;
run;

/*5) T-TESTS BY CASE STATUS*/
proc ttest data=A6.caco_recode; class CACO; var BMI;    run;
proc ttest data=A6.caco_recode; class CACO; var FIBER;  run;
proc ttest data=A6.caco_recode; class CACO; var AGEDX;  run;
proc ttest data=A6.caco_recode; class CACO; var INCHES; run;
proc ttest data=A6.caco_recode; class CACO; var WTMIN5; run;

/* Table 1: continuous */
proc means data=A6.caco_recode n mean stddev min max maxdec=1;
  class CACO;
  var AGEDX BMI FIBER INCHES WTMIN5;
run;

/* Table 1: categorical */
proc freq data=A6.caco_recode;
  tables CACO*(EDGP FAMCAN BMICAT FIBERCAT AGEDX10) / chisq norow nocol;
run;

/* 6) LOGISTIC REGRESSION (UNADJUSTED) */
proc genmod data=A6.caco_recode;
  class FIBERCAT (param=ref ref="1") CACO (param=ref ref="0");
  model CACO = FIBERCAT / dist=bin link=logit type3;
  estimate "Fiber 3 vs 1" FIBERCAT 1 0 / exp;
  estimate "Fiber 2 vs 1" FIBERCAT 0 1 / exp;
run;

proc genmod data=A6.caco_recode;
  class AGEDX10 (param=ref ref="1") CACO (param=ref ref="0");
  model CACO = AGEDX10 / dist=bin link=logit type3;
  estimate "Age 70-79 vs 50-59" AGEDX10 1 0 / exp;
  estimate "Age 60-69 vs 50-59" AGEDX10 0 1 / exp;
run;

proc genmod data=A6.caco_recode;
  class BMICAT (param=ref ref="1") CACO (param=ref ref="0");
  model CACO = BMICAT / dist=bin link=logit type3;
  estimate "BMI 25-28 vs <25" BMICAT 1 0 / exp;
  estimate "BMI >28 vs <25"   BMICAT 0 1 / exp;
run;

proc genmod data=A6.caco_recode;
  class FAMCAN (param=ref ref="1") CACO (param=ref ref="0");
  model CACO = FAMCAN / dist=bin link=logit type3;
  estimate "FAMCAN 2 vs 1" FAMCAN 1 / exp;
run;

proc genmod data=A6.caco_recode;
  class EDGP (param=ref ref="3") CACO (param=ref ref="0");
  model CACO = EDGP / dist=bin link=logit type3;
  estimate "EDGP 1 vs 3" EDGP 1 0 / exp;
  estimate "EDGP 2 vs 3" EDGP 0 1 / exp;
run;

/* Continuous fiber: OR per 2.5 increase */
proc genmod data=A6.caco_recode;
  class CACO (param=ref ref="0");
  model CACO = FIBER / dist=bin link=logit type3;
  estimate "OR per 2.5-unit fiber increase" FIBER 2.5 / exp;
run;

/*  7) ADJUSTED MODEL */
proc genmod data=A6.caco_recode;
  class FIBERCAT (param=ref ref="1")
        AGEDX10   (param=ref ref="1")
        EDGP     (param=ref ref="3")
        FAMCAN   (param=ref ref="1")
        BMICAT   (param=ref ref="1");
  model CACO = FIBERCAT AGEDX10 EDGP FAMCAN BMICAT / dist=bin link=logit type3;
  estimate "Fiber 3 vs 1 (adj)" FIBERCAT 1 0 / exp;
  estimate "Fiber 2 vs 1 (adj)" FIBERCAT 0 1 / exp;
run;

/* Continuous fiber adjusted */
proc genmod data=A6.caco_recode;
  class AGEDX10 (param=ref ref="1")
        EDGP   (param=ref ref="3")
        FAMCAN (param=ref ref="1")
        BMICAT (param=ref ref="1")
        CACO   (param=ref ref="0");
  model CACO = FIBER EDGP FAMCAN BMICAT AGEDX10 / dist=bin link=logit type3;
  estimate "OR per 2.5-unit fiber increase (adj)" FIBER 2.5 / exp;
run;

/* 8) INTERACTION MODELS*/

/* FIBERCAT × BMICAT */
proc genmod data=A6.caco_recode;
  class FIBERCAT (param=ref ref="1")
        BMICAT   (param=ref ref="1")
        AGEDX10  (param=ref ref="1")
        EDGP     (param=ref ref="3")
        FAMCAN   (param=ref ref="1")
        CACO     (param=ref ref="0");
  model CACO = FIBERCAT BMICAT FIBERCAT*BMICAT AGEDX10 EDGP FAMCAN / dist=bin link=logit type3;
run;
/* FIBERCAT × EDGP */
proc genmod data=A6.caco_recode;
  class FIBERCAT (param=ref ref="1")
        EDGP     (param=ref ref="3")
        AGEDX10  (param=ref ref="1")
        FAMCAN   (param=ref ref="1")
        BMICAT   (param=ref ref="1")
        CACO     (param=ref ref="0");
  model CACO = FIBERCAT EDGP FIBERCAT*EDGP AGEDX10 FAMCAN BMICAT / dist=bin link=logit type3;
run;

/* FIBERCAT × AGEDX10 */
proc genmod data=A6.caco_recode;
  class FIBERCAT (param=ref ref="1")
        AGEDX10  (param=ref ref="1")
        EDGP     (param=ref ref="3")
        FAMCAN   (param=ref ref="1")
        BMICAT   (param=ref ref="1")
        CACO     (param=ref ref="0");
  model CACO = FIBERCAT AGEDX10 FIBERCAT*AGEDX10 EDGP FAMCAN BMICAT / dist=bin link=logit type3;
run;
