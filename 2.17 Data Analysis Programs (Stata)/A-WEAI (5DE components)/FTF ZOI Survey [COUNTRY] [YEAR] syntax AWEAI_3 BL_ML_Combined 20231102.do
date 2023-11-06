/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
********************** 5DE CALCULATIONS, A-WEAI INDICATORS *********************
******************************* [COUNTRY] [YEAR] *******************************
********************************************************************************
Description:

This syntax appends the baseline and midline data files generated with the 
A-WEAI analytic variables and then tabulates the estimates that will be included
in the midline indicator assessment report.

The template do files used to produce the data files used in this do file are:

	1. Data preparation: 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_1 prep.do
	   which results in: 
			- "FTF_ZOI_Survey [COUNTRY] [YEAR] aweai_prep.dta"
	   
	2. 5DE-related calculations: 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_2 5DEcalc.do
	   which results in: 
			- "FTF_ZOI_Survey [COUNTRY] [YEAR] aweai_individual_indices.dta"
			- "FTF_ZOI_Survey [COUNTRY] [YEAR] 5DE_FINAL.dta"

Each of the do and dta files specified above should exist separately for 
baseline and midline, where "BL"=baseline and "ML"=midline.

Syntax prepared by ICF March 2023

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 12.3, Part 3, Step 2 and Part 3 of the Guide to 
Feed the Future Midline Statistics.
*******************************************************************************/
*Specify local drive and folders in which inputs and outputs are stored.

//DIRECTORY PATH
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"
cd "$analytic"

//Input data:  $analytic\Results\FTF_ZOI_Survey [COUNTRY] [BL YEAR] aweai_prep.dta 
//             $analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_prep.dta 
//             $analytic\Results\FTF_ZOI_Survey [COUNTRY] [BL YEAR] aweai_individual_indices.dta
//             $analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_individual_indices.dta
//             $analytic\Results\FTF_ZOI_Survey [COUNTRY] [BL YEAR] 5DE_FINAL.dta"
//             $analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] 5DE_FINAL.dta"
//Log result:  $analtyic\Log\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_BL_ML_compare.log
//Output data: none
//Syntax:      $analytic\FTF ZOI Survey [COUNTRY] [ML YEAR] syntax AWEAI_BL_ML_compare.do 

capture log close
clear all
set more off

*Create a log file.
log using "$analytic\Log\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_BL_ML_compare.log", text replace

********************************************************************************
*Load the Midline Survey data file with the empowerment and average adequacy 
*variables and generate a survey variable=2 (for midline).
use "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_individual_indices.dta", clear
gen survey=2

*Append the Baseline Survey data file with the empowerment and average adequacy 
*variables and update the survey variable to have a value=1 for baseline records.
append using "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [BL YEAR] aweai_individual_indices.dta"
replace survey=1 if survey==.
tab survey

*Create unique cluster and sampling weight variables across the two surveys.
egen hhea2=group(survey hhea)
gen wgt_combined=wgt_fpdm if survey==2
replace wgt_combined=wgt_hh if survey==1

*Save the combined baseline/midline A-WEAI indicatr data file.
save "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_individual_indices_BL_ML.dta", replace

*Apply the sample design
svyset hhea2 [pw=wgt_combined], strata(strata) singleunit(scaled)

********************************************************************************
****** Section 6.2 tables
********************************************************************************
*Recreate the age category variable because the youth variable if needed.
/*gen	fdm_agecat=missing
replace fdm_agecat=1 if age>=18 & age<30
replace fdm_agecat=2 if age>=30 & age<98
la def 	fdm_agecat 1 "18-29 years" 0 "30+ years"
la val 	fdm_agecat fdm_agecat 
la var "Female PDM's age (18-29, 30+)"
*/

*****TABLE 6.2.1 (% empowered, average adequacy of disempowered)
*5DE - SEE NEXT SECTION

*% empowered
svy: tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if fdm_agecat==1 & miss_any==0): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if fdm_agecat==2 & miss_any==0): tab emp_80p survey, col perc format(%6.1f) obs

*Average adequacy score of disempowered womem
svy: mean ad_80p, over(survey)
svy: regress ad_80p survey
matrix list r(table)

svy, subpop(if fdm_agecat==1 & miss_any==0): mean ad_80p, over(survey)
svy, subpop(if fdm_agecat==1 & miss_any==0): regress ad_80p survey
matrix list r(table)

svy, subpop(if fdm_agecat==2 & miss_any==0): mean ad_80p, over(survey)
svy, subpop(if fdm_agecat==2 & miss_any==0):regress ad_80p survey
matrix list r(table)

*****TABLE 6.2.2 (% empowered, by household characteristics)
svy: tab emp_80p survey, col perc format(%6.1f) obs

*Wealth index
svy, subpop(if awiquint==5): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if awiquint==4): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if awiquint==3): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if awiquint==2): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if awiquint==1): tab emp_80p survey, col perc format(%6.1f) obs

*Shock exposure severity
svy, subpop(if shock_sev==1): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if shovk_sev==2): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if shock_sev==3): tab emp_80p survey, col perc format(%6.1f) obs
svy, subpop(if shock_sev==4): tab emp_80p survey, col perc format(%6.1f) obs


********************************************************************************
****** Section 6.3 tables
********************************************************************************
*Create a variable list for the six A-WEAI variables
global varlist_all feelinputdecagr jown_count credjanydec_any incdec_count groupmember_any npoor_z105

*****TABLE 6.3.1 (Women with all data for all 6 A-WEAI indicators, adequate)
sum $varlist_all if miss_any==0 
foreach var in $varlist_all {
	svy, subpop(if miss_any==0): tab `var' survey, col ci perc format(%6.1f) obs
	svy, subpop(if fdm_agecat==1 & miss_any==0): tab `var' survey, col ci perc format(%6.1f) obs
	svy, subpop(if fdm_agecat==2 & miss_any==0): tab `var' survey, col ci perc format(%6.1f) obs
}

*****TABLE 6.3.2 (Disempowered women, adequate)
sum $varlist_all if miss_any==0 & fdm_dj==1
foreach var in $varlist_all {
	svy, subpop(if dis_80p==1): tab `var' survey, col ci perc format(%6.1f) obs
	svy, subpop(if fdm_agecat==1 & dis_80p==1): tab `var' survey, col ci perc format(%6.1f) obs
	svy, subpop(if fdm_agecat==2 & dis_80p==1): tab `var' survey, col ci perc format(%6.1f) obs
}

*****TABLE 6.3.3 (All women, adequate)
sum $varlist_all
foreach var in $varlist_all {
    svy: tab `var' survey, col ci perc format(%6.1f) obs
	svy, subpop(if fdm_agecat==1): tab `var' survey, col ci perc format(%6.1f) obs
	svy, subpop(if fdm_agecat==2): tab `var' survey, col ci perc format(%6.1f) obs
}

********************************************************************************
**#**** Part 3, Step 2. Performing a test of difference for 5DE estimates ******
********************************************************************************
*Step 2.1. Load the data file with the 5DE results at midline and append the 
*          data file with the 5DE results at baseline 
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] 5DE_FINAL_ML", clear
append "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] 5DE_FINAL_BL"

*Step 2.2. Transform the data file from long to wide format so that there are 3 
*          records, each with baseline and midline 5DE data (i.e., the estimate, 
*          standard error, lower bound of the 95% CI, upper bound of the 95% CI, 
*          and DEFF). The first row is for all women, the second for women 18-29 
*          years of age, and the third for women 30 years of age or older.
drop Label
reshape wide EA_80p SE LCI UCI deff, i(cat) j(survey)

*Step 2.3. Label the variables in data file.
la var 	EA_80p1 	"5DE, baseline"
la var 	SE1			"5DE SE, baseline" 
la var 	LCI1 		"5DE lower CI bound, baseline"
la var 	UCI1 		"5DE upper CI bound, baseline"
la var 	deff1 		"5DE design effect, baseline"
la var 	EA_80p2 	"5DE, midline"
la var 	SE2 		"5DE SE, midline" 
la var 	LCI2 		"5DE lower CI bound, midline"
la var 	UCI2 		"5DE upper CI bound, midline"
la var 	deff2		"5DE design effect, midline"

*Step 2.4. Create a variable that is equal to the Z-score (Z), following the 
*          guidance in Section 3.2.3 of the Guide to Feed the Future Midline
*          Statistics, "Analyzing indicators of proportions or means if the 
*          data are not available."

gen Z=abs(EA_80p2-EA_80p1)/sqrt(SE2^2 + SE1^2)
la var Z "5DE ML/BL comparison Z-score"

*Step 2.5. Create a variable that is equal to the p-value (P) by subtracting the 
*          normalized absolute value of P from 1 and multiplying the result by 2.

gen P=2*(1-normal(abs(Z)))
la var P "5DE ML/BL comparison P-value"

*Save the data file with the Z-score and P-value results.
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] 5DE_FINAL_ML_BL_P", replace

********************************************************************************
****** Section 6.4 tables
********************************************************************************
*Load the Midline Survey data file with the A-WEAI indicators and generate a 
*survey variable=2 (for midline).
use "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_prep.dta", clear
gen survey=2

*Append the Baseline Survey data file with the A-WEAI indicators and set the 
*survey variable=1 (for baseline)
append using "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [BL YEAR] aweai_prep.dta"
replace survey=1 if survey==.
tab survey

*Create unique cluster and sampling weight variables across the two surveys.
egen hhea2=group(survey hhea)
gen wgt_combined=wgt_fpdm if survey==2
replace wgt_combined=wgt_hh if survey==1

*Save the combined baseline/midline A-WEAI indicatr data file.
save "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_prep_BL_ML.dta", replace

*Apply the sampling design 
svyset hhea2 [pw=wgt_combined], strata(strata) singleunit(scaled)

*Tabulate the variables included in Table T6.4.1 by survey and check the results.
tab partact_any survey
tab partact_agr_any survey
tab partact_1 survey
tab partact_2 survey
tab partact_3 survey
tab partact_4 survey
tab partact_5 survey
tab partact_6 survey

*Tabulate the weighted estimates for Table T6.4.1 by survey.
foreach x of varlist partact_any partact_agr_any partact_1-partact_6 {
  svy: tab `x' survey, col ci perc format(%6.1f) obs 
}

*Tabulate the variables included in Table T6.4.2 by survey and check the results.
tab inputdec_any survey
tab inputdec_agr_any survey
tab inputdec_1 survey
tab inputdec_2 survey
tab inputdec_3 survey
tab inputdec_4 survey
tab inputdec_5 survey
tab inputdec_6 survey

*Tabulate the weighted estimates for Table T6.4.2 by survey.
foreach x of varlist inputdec_any inputdec_agr_any inputdec_1-inputdec_5 {
  svy: tab `x' survey, col ci perc format(%6.1f) obs
}

*Tabulate the variables included in Table T6.4.3 by survey and check the results.
tab jown_count survey
tab selfjointown_01x survey
tab selfjointown_02x survey
tab selfjointown_03x survey
tab selfjointown_04x survey
tab selfjointown_05x survey
tab selfjointown_06x survey
tab selfjointown_07x survey
tab selfjointown_08x survey
tab selfjointown_09x survey
tab selfjointown_10x survey
tab selfjointown_11x survey
tab selfjointown_12x survey
tab selfjointown_13x survey
tab selfjointown_14x survey
tab selfjointown_15x survey

*Tabulate the weighted estimates for Table T6.4.3 by survey.
svy: tab jown_count survey, col ci perc format(%6.1f) obs 
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 {
  svy: tab selfjointown_`x'x survey, col ci perc format(%6.1f) obs 
}

*Tabulate the variables included in Table T6.4.4 by survey and check the results.
**Household received a loan (any, cash, in-kind)
tab hh_loan_any survey
tab hh_cash_any survey
tab hh_inkind_any survey
*Source of loan
tab creditaccess_1 survey
tab creditaccess_2 survey
tab creditaccess_3 survey
tab creditaccess_4 survey
tab creditaccess_5 survey
tab creditaccess_6 survey
*Contributed to a credit decision
tab creditdec_any survey
tab creditdecborrow_any survey
tab creditdecuse_any survey
*Contributed to a credit decision by source
tab creditselfjointanydec_1 survey 
tab creditselfjointanydec_2 survey
tab creditselfjointanydec_3 survey
tab creditselfjointanydec_4 survey
tab creditselfjointanydec_5 survey
tab creditselfjointanydec_6 survey
tab creditselfjointborrow_1 survey
tab creditselfjointborrow_2 survey
tab creditselfjointborrow_3 survey
tab creditselfjointborrow_4 survey
tab creditselfjointborrow_5 survey
tab creditselfjointborrow_6 survey
tab creditselfjointuse_1 survey
tab creditselfjointuse_2 survey
tab creditselfjointuse_3 survey
tab creditselfjointuse_4 survey
tab creditselfjointuse_5 survey
tab creditselfjointuse_6 survey

*Tabulate the weighted estimates for Table T6.4.4 by survey.
svy: tab hh_loan_any survey, col ci perc format(%6.1f) obs
svy: tab hh_cash_any survey, col ci perc format(%6.1f) obs
svy: tab hh_inkind_any survey, col ci perc format(%6.1f) obs

foreach x of varlist creditaccess_1-creditaccess_6 {
  svy: tab `x' survey, col ci perc format(%6.1f) obs
}

svy: tab creditdecborrow_any survey, col ci perc format(%6.1f) obs
svy: tab creditdecuse_any survey, col ci perc format(%6.1f) obs
svy: tab creditdec_any survey, col ci perc format(%6.1f) obs

foreach x of varlist creditselfjointanydec_? creditselfjointborrow_? creditselfjointuse_? {
  svy: tab `x' survey, col ci perc format(%6.1f) obs
}

*Tabulate the weighted estimates for Table T6.4.5 by survey.
tab incomedec_any survey
tab incomedec_agr_any survey
tab incomedec_1 survey
tab incomedec_2 survey
tab incomedec_3 survey
tab incomedec_4 survey
tab incomedec_5 survey
tab incomedec_6 survey
tab inputdec_7 survey
tab inputdec_8 survey

*Tabulate the weighted estimates for Table T6.4.5 by survey.
foreach x of varlist incomedec_any incomedec_agr_any incomedec_1-incomedec_6 inputdec_7 inputdec_8 {
  svy: tab `x' survey, col ci perc format(%6.1f) obs
}

*Tabulate the weighted estimates for Table T6.4.6 by survey.
tab groupmember_any survey
tab groupmember_01x survey
tab groupmember_02x survey
tab groupmember_03x survey
tab groupmember_04x survey
tab groupmember_05x survey
tab groupmember_06x survey
tab groupmember_07x survey
tab groupmember_08x survey
tab groupmember_09x survey
tab groupmember_10x survey
tab groupmember_11x survey

*Tabulate the weighted estimates for Table T6.4.6 by survey.
foreach x of varlist groupmember_any groupmember_01x-groupmember_11x {
  replace `x'=0 if `x'==.
  svy: tab `x' survey, col ci perc format(%6.1f) obs
}

*Tabulate the weighted estimates re: activity participation for Table T6.4.7 by survey.
tab work_any survey 
tab partook_A survey
tab partook_B survey
tab partook_C survey
tab partook_D survey
tab partook_E survey
tab partook_F survey
tab partook_GHIJ survey
tab partook_K survey
tab partook_L survey
tab partook_M survey
tab partook_N survey
tab partook_O survey
tab partook_P survey
tab partook_OP survey
tab partook_P survey
tab partook_QR survey
tab partook_S survey
tab partook_T survey
tab partook_U survey
tab partook_V survey
tab partook_W survey
tab partook_X survey

*Tabulate the weighted estimates re: activity participation for Table T6.4.7 by survey.
foreach x of varlist work_any partook_A-partook_F partook_GHIJ partook_K-partook_N partook_OP partook_Q-partook_X {
  svy: tab `x' survey, col ci perc format(%6.1f) obs
}
*Tabulate activity P separately because it is available only at midline.
svy: tab partook_P if survey==2, ci perc format(%6.1f) obs

*Tabulate the weighted estimates re: time per activity for Table T6.4.7 by survey.
mean work_hours, over(survey)
mean hours_A, over(survey)
mean hours_B, over(survey)
mean hours_C, over(survey)
mean hours_D, over(survey)
mean hours_E, over(survey)
mean hours_F, over(survey)
mean hours_GHIJ, over(survey)
mean hours_K, over(survey)
mean hours_L, over(survey)
mean hours_M, over(survey)
mean hours_N, over(survey)
mean hours_O, over(survey)
mean hours_P, over(survey)
mean hours_OP, over(survey)
mean hours_QR, over(survey)
mean hours_S, over(survey)
mean hours_T, over(survey)
mean hours_U, over(survey)
mean hours_V, over(survey)
mean hours_W, over(survey)
mean hours_X, over(survey)

*Tabulate the weighted mean time estimates for Table T6.4.7 by survey.
foreach x of varlist work_hours hours_A-hours_F hours_GHIJ hours_K-hours_N hours_OP hours_Q-hours_X {
  svy: mean `x', over (survey)
}
*Tabulate activity P separately because it is available only at midline.
svy: mean hours_P

save "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_prep_BL_ML.dta", replace

di "Date:$S_DATE $S_TIME"
log close
