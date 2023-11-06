/*******************************************************************************
************************ FEED THE FUTURE ZOI SURVEY ****************************
**************************** A-WEAI CALCULATIONS *******************************
****************************** [YEAR] [COUNTRY] ********************************
********************************************************************************

Description:

This syntax is used to create the 5 domains of empowerment (5DE) indicators used 
to calculate the Abbreviated Women's Empowerment in Agriculture Index (A-WEAI)  
for Feed the Future Phase Two Zone of Influence (P2-ZOI) Midline Surveys.

This file is an adaptation of the 2020 A-WEAI calc file prepared by Ana Vaz and 
Sabina Alkire at www.ophi.org.uk and found on the WEAI Resource Center website, 
hosted by IFPRI. 
https://weai.ifpri.info/files/2020/05/Dataprep-and-AWEAI-calculation-files.zip

More information about the A-WEAI calculation can be found here:
https://www.ifpri.org/sites/default/files/a-weai_instructional_guide_final.pdf

The file has been adapted by Feed the Future for use with the P2-ZOI Midline 
Survey data; however, the names of variables included in the IFPRI syntax files
are preserved. Explanatory notes are added to faciliate implementation of the syntax.

For P2-ZOI Midline Surveys, the A-WEAI cannot be calculated because data are 
collected only from primary adult female decision-makers. Data from primary adult
male decision-makers are collected only at baseline and endline. For P2-ZOI 
Midline Surveys, results related to the 5DE component of the A-WEAI are 
calculated.

Two files are needed to produce the 5DE results included in the P2-ZOI Midline
Survey reports:

	1. Data preparation (current file): 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_1 prep.do
	2. 5DE-related calculations: 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_2 5DEcalc.do

This data prep file includes syntax to calculate:

	A. variables needed for section 6.2 of the survey report:
	   the 5DE, the % of women who are empowered, and the average inadequacy score 
	B. variables needed for section 6.3 of the survey report:
	   the % of women who have data for all 5DE indicators who are adequate in each indicator,
	   the % of women who are disempowered who are adequate in each indicator,
	   the % of all women who are adequate in each indicator
	C. the 5DE standard error (SE), 95% confidence interval (CI), and design effect (DEFF)
	   required for Tables ES1 and/or A1.1 of the survey report

Updated from baseline syntax by ICF 2022 for P2-ZOI midline surveys

This syntax file was developed using the core Feed the Future P2-ZOI Midline 
Survey questionnaire. It must be adapted for the final country-specific 
questionnaire; therefore, double-check all results carefully and troubleshoot to 
resolve any issues identified. 
*******************************************************************************/
*Specify local drive and folders in which inputs and outputs are stored

//DATA DIRECTORY PATH
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"
cd "$analytic"

//Input data:  $analytic\Results\aweai_prep.dta 
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] aweai 5DEcalc.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] aweai 5DEcalc.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax AWEAI_2 5DEcalc.do 
********************************************************************************
capture log close
log using "$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] aweai 5DEcalc.log", replace 

*Open data file created using A-WEAI data prep do file
use "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] aweai_prep.dta", clear

********************************************************************************
************************** C1. Weighted inadequacy score ***********************
********************************************************************************
*All six 5DE indicators have been defined so that 1=adequate, 0=inadequate.
*Now we transform indicators so 1 identifies inadequate.

*C-1.1: Create a global variable (varlist_emp) with all six 5DE indicators.
global varlist_emp feelinputdecagr jown_count credjanydec_any incdec_count groupmember_any npoor_z105

*C-1.2: Transform the 5DE indicators so that 1=inadequate, 0=adequate.
foreach var in $varlist_emp {
  rename `var' `var'_ndepr
  gen `var'=1 if `var'_ndepr==0
  replace `var'=0 if `var'_ndepr==1
  la val `var' YESNO
}

******The six 5DE indicators******
*Indicator 1-input into productive decision-making
*Indicator 2-asset ownershio
*Indicator 3-input into credit decision-making
*Indicator 4-input into income decision-making
*Indicator 5-group membership
*Indicator 6-workload

la var feelinputdecagr 	"Inadequate in decision-making (Indicator 1), all women"
la var jown_count 		"Inadequate in asset ownership (Indicator 2), all women"
la var credjanydec_any 	"Inadequate in credit decision-making (Indicator 3), all women" 
la var incdec_count 	"Inadequate in income decision-making (Indicator 4), all women"
la var groupmember_any 	"Inadequate in group membership (Indicator 5), all women"
la var npoor_z105 		"Inadequate in work hours (Indicator 6), all women"

*FOR MIDLINE REPORT TABLE 6.3.3
la var feelinputdecagr_ndepr "Adequate in decision-making (Indicator 1), all women"
la var jown_count_ndepr 	 "Adequate in asset ownership (Indicator 2), all women"
la var credjanydec_any_ndepr "Adequate in credit decision-making (Indicator 3), all women" 
la var incdec_count_ndepr 	 "Adequate in income decision-making (Indicator 4), all women"
la var groupmember_any_ndepr "Adequate in group membership (Indicator 5), all women"
la var npoor_z105_ndepr 	 "Adequate in work hours (Indicator 6), all women"

*C-1.3: Create a global variable (varlist_emp_ndepr) with all six 5DE indicators.
global varlist_emp_ndepr feelinputdecagr_ndepr jown_count_ndepr credjanydec_any_ndepr incdec_count_ndepr groupmember_any_ndepr npoor_z105_ndepr

tab1 $varlist_emp $varlist_emp_ndepr
sum  $varlist_emp $varlist_emp_ndepr

*C-1.4: Ensure at most 1 female record per household.
*       Return error & stop script if female record per household is not unique.
isid hhea hhnum  

*C-1.5: Create variables for 5DE indicator weights.
*       Weights sum to 1 (not to the number of indicators)

*C-1.5A: Assign weight of 1/5 for domain 1, 3, 4, and 5 indicators
foreach var in feelinputdecagr incdec_count groupmember_any npoor_z105 {
  gen w_`var'=1/5
}

*C-1.5B: Assign weights to domain 2 indicators: 2/15 for asset ownership 
*        indicator & 1/15 for credit access indicator.
gen w_jown_count=2/15
gen w_credjanydec_any=1/15

*C-1.6: Apply the weights to each 5DE indicator indicating inadequacy.
foreach var in $varlist_emp {
	gen wg0_`var'= `var'*w_`var'
}

*C-1.7: Create a global variable (wg0_varlist_emp) with the six weighted 5DE indicators indicating inadequacy.
global wg0_varlist_emp wg0_feelinputdecagr wg0_jown_count wg0_credjanydec_any wg0_incdec_count wg0_groupmember_any wg0_npoor_z105
sum $wg0_varlist_emp 

*C-1.8: Apply the weights to each 5DE indicator indicatoring adequacy.
foreach var in $varlist_emp {
	gen wg0_`var'_ndepr= `var'_ndepr*w_`var'
}

*C-1.9: Create a global variable (wg0_varlist_emp_ndepr) with the six weighted 5DE indicators indicating adequacy.
global wg0_varlist_emp_ndepr wg0_feelinputdecagr_ndepr wg0_jown_count_ndepr wg0_credjanydec_any_ndepr wg0_incdec_count_ndepr wg0_groupmember_any_ndepr wg0_npoor_z105_ndepr
sum $wg0_varlist_emp_ndepr 

*C-1.10: Compute the frequency of missing values for each 5DE indicator indicating inadequacy.
foreach var in $varlist_emp {
  gen `var'_miss=1 if `var'==.
  replace `var'_miss=0 if `var'!=.
}

tab1 *_miss
sum *_miss

*C-1.11: Define the weighted inadequacy count vector "ci". 
egen ci=rsum($wg0_varlist_emp) 
replace ci=round(ci,.0001) 
label variable ci "Weighted inadequacy count"
tab ci

*C-1.12: Define the weighted adequacy count vector "ca". 
*        NOTE: Not part of IFPRI code
egen ca=rsum($wg0_varlist_emp_ndepr) 
replace ca=round(ca,.0001) 
label variable ca "Weighted adequacy count"
tab ca

*C-1.13: Determine the number of 5DE indicators indicating inadequacy each 
*        respondent is missing (will be the same for adequacy).
egen n_missing=rowmiss($wg0_varlist_emp) 
label variable n_missing "Number of missing variables by individual"
tab n_missing

*C-1.14: Create a variable indicating if respondent is missing any of the six 
*        5DE indicators.
gen miss_any=(n_missing>0) 
label variable miss_any "Individual has missing variables"
tab miss_any

*C-1.15: Check sample for respondents missing values.
tab miss_any
list miss_any $varlist_emp if miss_any!=0

*C-1.16: Save the data file.
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] aweai_depr_indicators.dta", replace

********************************************************************************
***************** C2. Censored inadequacy and adequacy scores ******************
********************************************************************************
*KZ TEMP START
set seed 10000
gen wgt_pfdm=rnormal()
replace wgt_pfdm=abs(wgt_pfdm)	
clonevar strata=a03c
gen m1_line=1
*KZ TEMP END

*C-2.1: Create a total weight variable (total_w)—a constant that sums all women's 
*       sampling weights for respondents with complete 5DE indicator data.
egen total_w=total(wgt_pfdm) if miss_any==0
tab total_w

*C-2.2: Apply a threshold of 0.2 to be used for the censored head counts to 
*       identify those with inadequate empowerment higher than the threshold.
*       Woman has a weighted inadequacy score (ci)>0.2 on a scale of 0-1, and is 
*       therefore disempowered.
gen ch_20p=(ci>float(20/100))
replace ch_20p=. if miss_any==1 
label var ch_20p "Woman is disempowered, k=20%"
tab ch_20p

*C-2.3: Calculate the individual inadequacy of those who are disempowered.
gen a_20p=(ci) if ch_20p==1 
replace a_20p=. if miss_any==1
*label var a_20p "Individual average inadequacy, k=20%"
label var a_20p "Weighted inadequacy count (ci) for disempowered, k=20%"
tab a_20p

*C-2.4: Calculate the individual adequacy of those who are disempowered.
*        NOTE: Not part of IFPRI code
gen ad_20p=(ca) if ch_20p==1 
replace ad_20p=. if miss_any==1
*label var ad_20p "Individual average adequacy, k=20%"
label var ad_20p "Weighted adequacy count (ca) for disempowered, k=20%"
tab ad_20p

*C-2.5: Calculate the disempowerment index (DAI) 
egen DAI_20p= total(ci*ch_20p*wgt_pfdm/total_w) 
replace DAI_20p=. if miss_any==1
label var DAI_20p "Disempowerment Index, k=20%"
tab DAI_20p

*C-2.6: Calculate the empowerement index (EAI)
gen EAI_20p=1-DAI_20p 
label var EAI_20p "Empowerment Index, k=20%"
tab EAI_20p

sum ch_20p a_20p DAI_20p EAI_20p [aw=wgt_pfdm]

*C-2.7: Compute uncensored headcounts        
foreach var in $varlist_emp {
  gen `var'_raw=(`var')
  replace `var'_raw=. if miss_any==1
}

la var feelinputdecagr_raw "Inadequate in decision-making (Indicator 1), have all indicators"
la var jown_count_raw      "Inadequate in asset ownership (Indicator 2), have all indicators"
la var credjanydec_any_raw "Inadequate in credit decision-making (Indicator 3), have all indicators"
la var incdec_count_raw    "Inadequate in income decision-making (Indicator 4), have all indicators"
la var groupmember_any_raw "Inadequate in group membership (Indicator 5), have all indicators"
la var npoor_z105_raw      "Inadequate in work hours (Indicator 6), have all indicators"

sum *_raw
sum *_raw  [iw=wgt_pfdm]

*FOR MIDLINE REPORT TABLE 6.3.1
*C-2.8: Create indicators for the uncensored headcounts of individuals who 
*       are disempowered but achieved adequacy in the A-WEAI indicator.
*       NOTE: Not part of IFPRI code
foreach var in $varlist_emp_ndepr {
  gen `var'_nraw=(`var')
  replace `var'_nraw=. if miss_any==1
  la val `var'_nraw YESNO
}

la var feelinputdecagr_ndepr_nraw "Adequate in decision-making (Indicator 1), have all indicators"
la var jown_count_ndepr_nraw      "Adequate in asset ownership (Indicator 2), have all indicators"
la var credjanydec_any_ndepr_nraw "Adequate in credit decision-making (Indicator 3), have all indicators" 
la var incdec_count_ndepr_nraw    "Adequate in income decision-making (Indicator 4), have all indicators"
la var groupmember_any_ndepr_nraw "Adequate in group membership (Indicator 5), have all indicators"
la var npoor_z105_ndepr_nraw      "Adequate in work hours (Indicator 6), have all indicators"

sum *_nraw
sum *_nraw  [iw=wgt_pfdm]

global varlist_ndepr_nraw feelinputdecagr_ndepr_nraw jown_count_ndepr_nraw credjanydec_any_ndepr_nraw incdec_count_ndepr_nraw groupmember_any_ndepr_nraw npoor_z105_ndepr_nraw

********************************************************************************
************************* C3. Censored headcounts ******************************
********************************************************************************
/*
*C-3.1: Create indicators for the censored headcounts of individuals who are
*	    disempowered and also did not achieve adequacy in the A-WEAI indicator.
*	    Set the indicator value to missing if any of the 5DE indicators are
*       missing values for that respondent.
foreach var in $varlist_emp {
  gen `var'_CH_20p=(`var'==1 & ch_20p==1)
  replace `var'_CH_20p=. if miss_any==1
}

la var feelinputdecagr_CH_20p "Inadequate in decision-making (Indicator 1), censored HC"
la var jown_count_CH_20p      "Inadequate in asset ownership (Indicator 2), censored HC"
la var credjanydec_any_CH_20p "Inadequate in credit decision-making (Indicator 3), censored HC"
la var incdec_count_CH_20p    "Inadequate in income decision-making (Indicator 4), censored HC"
la var groupmember_any_CH_20p "Inadequate in group membership (Indicator 5), censored HC"
la var npoor_z105_CH_20p      "Inadequate in work hours (Indicator 6), censored HC"

sum *_CH_20p
sum *_CH_20p [iw=wgt_pfdm]

*C-3.2: Create indicators for the censored headcounts of individuals 
*	    who are disempowered but achieved adequacy in the A-WEAI indicator.
*	    Set the indicator value to missing if any of the 5DE indicators are
*       missing values for that respondent.
foreach var in $varlist_emp_ndepr {
  gen `var'_CH_20p=(`var'==1 & ch_20p==1)
  replace `var'_CH_20p=. if miss_any==1
}

la var feelinputdecagr_ndepr_CH_20p "Adequate in decision-making (Indicator 1), censored HC"
la var jown_count_ndepr_CH_20p      "Adequate in asset ownership (Indicator 2), censored HC"
la var credjanydec_any_ndepr_CH_20p "Adequate in credit decision-making (Indicator 3), censored HC"
la var incdec_count_ndepr_CH_20p    "Adequate in income decision-making (Indicator 4), censored HC"
la var groupmember_any_ndepr_CH_20p "Adequate in group membership (Indicator 5), censored HC"
la var npoor_z105_ndepr_CH_20p      "Adequate in work hours (Indicator 6), censored HC"

sum *_ndepr_CH_20p 
sum *_ndepr_CH_20p [iw=wgt_pfdm]

global varlist_ndepr_CH_20p feelinputdecagr_ndepr_CH_20p jown_count_ndepr_CH_20p credjanydec_any_ndepr_CH_20p incdec_count_ndepr_CH_20p groupmember_any_ndepr_CH_20p npoor_z105_ndepr_CH_20p
*/
********************************************************************************
*********************** C4. Disempowered headcounts ****************************
********************************************************************************
*C-4-1: Compute disempowered headcount variables for those indequate in each 5DE 
*       indicator (i.e., only among those who are disempowered)   
foreach var in $varlist_emp {
  gen `var'_dis=(`var')
  replace `var'_dis=. if ch_20p!=1
  la val `var' YESNO
}

la var feelinputdecagr_dis "Indequate in decision-making (Indicator 1), disempowered women"
la var jown_count_dis      "Adequate in asset ownership (Indicator 2), disempowered women"
la var credjanydec_any_dis "Adequate in credit decision-making (Indicator 3), disempowered women" 
la var incdec_count_dis    "Adequate in income decision-making (Indicator 4), disempowered women"
la var groupmember_any_dis "Adequate in group membership (Indicator 5), disempowered women"
la var npoor_z105_dis      "Adequate in work hours (Indicator 6), disempowered women"

sum *_dis
sum *_dis  [iw=wgt_pfdm]

*C-4-2: Compute disempowered headcount variables for those dequate in each 5DE 
*       indicator. (i.e., only among those who are disempowered)   
foreach var in $varlist_emp_ndepr {
  gen `var'_dis=(`var')
  replace `var'_dis=. if ch_20p!=1
  la val `var'_dis YESNO
}

*FOR MIDLINE TABLE 6.3.2
la var feelinputdecagr_ndepr_dis "Adequate in decision-making (Indicator 1), disempowered women"
la var jown_count_ndepr_dis      "Adequate in asset ownership (Indicator 2), disempowered women"
la var credjanydec_any_ndepr_dis "Adequate in credit decision-making (Indicator 3), disempowered women" 
la var incdec_count_ndepr_dis    "Adequate in income decision-making (Indicator 4), disempowered women"
la var groupmember_any_ndepr_dis "Adequate in group membership (Indicator 5), disempowered women"
la var npoor_z105_ndepr_dis      "Adequate in work hours (Indicator 6), disempowered women"

sum *_dis
sum *_dis  [iw=wgt_pfdm]

global varlist_ndepr_dis feelinputdecagr_ndepr_dis jown_count_ndepr_dis  credjanydec_any_ndepr_dis incdec_count_ndepr_dis groupmember_any_ndepr_dis npoor_z105_ndepr_dis 

********************************************************************************
******************* C5. SAMPLE SIZE & POPULATION SHARE *************************
********************************************************************************
* We keep the information of the weighted population before reducing the sample 
* to only those cases with information in all the indicators considered.

*Determine sample size including all records (before) and including only 
*records that have complete 5DE indicator information (after).

*C-5.1: Create a variable equal to the sum of the weights of all women who
*       completed Module 6. 
egen total_b = total(wgt_pfdm) 
label var total_b "Total sample size before reduction"
tab total_b

*C-5.2: Create a variable equal to the weighted population share before 
*       reduction (that is, before women who do not have a value for all six
*       5DE variables are removed)
egen pop_shr_before = total(wgt_pfdm/total_b) 
label var pop_shr_before "Weighted population share before reduction"
tab pop_shr_before

*C-5.3: Create temp variable for counting observations
gen temp=1 

*C-5.4: Create a variable equal to the sample size before reduction (that is,  
*       equal to the number of women who completed Module 6 before women who do 
*       not have a value for all six 5DE variables are removed)
egen sample_r_before=total(temp) 
label var sample_r_before "Sample size before sample reduction"
tab sample_r_before

*C-5.5: Create a variable equal to the weighted population share after 
*       reduction (that is, for only women who have a value for all six
*       5DE variables)
egen pop_shr_after=total(wgt_pfdm/total_w) if miss_any==0 
label var pop_shr_after "Weighted population share after reduction"
tab pop_shr_after

*C-5.6: Create a variable equal to the sample size after reduction (that is,  
*       equal to the number of women who have a value for all six 5DE variables).
egen sample_r_after=total(temp) if miss_any==0
label var sample_r_after  "Sample size after reduction"
tab sample_r_after

*C-5.7: Create a variable equal to the relative size of the final sample after
*       reduction (that is, the proportion of women who completed Module 6 who
*       have data for all six 5DE indicators).
gen sample_lost_ratio=sample_r_after/sample_r_before
label var sample_lost_ratio  "Relative size of the final sample after reduction"
tab sample_lost_ratio

********************************************************************************
******************* C6. 5DE, EMPOWERMENT, AVERAGE ADEQUACY *********************
********************************************************************************
*C-6.1: Define the complex survey design
*INSTRUCTIONS: Adjust SVYSET command to account for complex survey design, 
*              including strata
svyset hhea [pw=wgt_pfdm]

*C-6.2: Create a variable equal to the mean sample-weighted ch_20p value, which 
*       is the percentage of women who are not empowered.
*       (Note: ch_20p gets renamed H_20p after collapse)
svy: mean ch_20p
gen mean_ch_20p=e(b)[1,1]
la var mean_ch_20p "Sample-weighted percent disempowered, k=20%"
tab mean_ch_20p

*C-6.3: Create a variable equal to the percent of women achieving empowerment
gen empowered=1-ch_20p
tab empowered 
svy: mean empowered
gen perc_emp=e(b)[1,1]
la var empowered "Woman is empowered, k=20%"
la var perc_emp "Sample-weighted percent empowered, k=20%"
tab perc_emp

*C-6.4: Create a variable equal to the average inadequacy score
*       (Note: a_20p gets renamed A_20p after collapse)
svy: mean a_20p
gen mean_a_20p=e(b)[1,1]
label var mean_a_20p "Sample-weighted mean weighted inadequacy count (ci) for disempowered, k=20%"
tab mean_a_20p

*C-6.5: Create a variable equal to the average adequacy score
gen avg_adequacy=1-a_20p
svy: mean avg_adequacy
gen mean_avg_adequacy=e(b)[1,1]
la var avg_adequacy "Weighted adequacy count for disempowered, k=20%"
la var mean_avg_adequacy "Sample-weighted mean weighted average adequacy score for disempowered, k=20%"


*C-6.6: Create a variable equal to the 5DE score 
gen M0_20p=mean_ch_20p*mean_a_20p
gen EA_20p=1-M0_20p
tab EA_20p
la var M0_20p "Disempowerment Index, k=20%"
la var EA_20p "Empowerment Index (5DE score), k=20%"

/*CHECK 5DE calculation: EA=1-M0=He+(Hn*Aa)
	He=Percent of women who are empowered (perc_emp)
	Hn=Percent of disempowered women (mean_ch_20p)
	Aa=Average percent of indicators in which disempowered women have adequate achievements (mean_avg_adequacy)
*/
gen FiveDE=perc_emp+(mean_ch_20p*mean_avg_adequacy)
la var FiveDE "EA_20p check"
tab1 EA_20p FiveDE
drop FiveDE

sum ch_20p a_20p *_CH_20p *_raw w_* EAI_20p *_miss miss_any DAI_20p pop_shr* sample_r_* sample_lost_ratio mean_ch_20p empowered perc_emp mean_a_20p avg_adequacy mean_avg_adequacy M0_20p EA_20p [aw=wgt_pfdm] 

svy: mean ch_20p a_20p *_CH_20p *_raw w_* EAI_20p *_miss miss_any DAI_20p pop_shr* sample_r_* sample_lost_ratio mean_ch_20p empowered perc_emp mean_a_20p avg_adequacy mean_avg_adequacy M0_20p EA_20p

*C-6.7 Save the individual-level data file before collapsing it.
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] aweai_individual_indices.dta", replace  

********************************************************************************
*************** D. 5DE STANADARD ERROR CALCULATION - JACKKNIFE *****************
********************************************************************************
*D-1. Create a variable that indicates if the woman is <30 or 30+ years old
*     (if not already created). If the primary decision-maker's age is missing in 
*     Module 6, use the person's age in the household roster.
gen age_cat=.
replace age_cat=1 if v6102<30
replace age_cat=2 if v6102>=30 & v6102<98
*INSTRUCTIONS: Update next line of syntax so that household roster age variable is merged into data file 
merge m:1 hhea hhnum m1_line using "$analytic\FTF ZOI Midline Survey Data 29JULY2021 Persons Raw.dta", keepusing(v104)
drop if _merge==2
drop _merge
replace age_cat=1 if v104<30 & age_cat==.
replace age_cat=2 if v104>=30 & v104<98 & age_cat==.
la def agecat 1 "<30yo" 2 "30+ yo"
la val age_cat agecat
tab age_cat, m

*D-2. Create a sequential cluster ID variable that starts from 1 
sort hhea
egen id = group(hhea)

*D-3. Create total weight variables by strata and sex
bys strata: egen alloc=total(wgt_pfdm)

*D-4. Create total weight variables by strata, sex, and age
bys strata age_cat: egen alloc_AGE=total(wgt_pfdm)

*D-5. Save the data to a temporary data file, AWEAI_DEPR.
save "$analytic\Temp\AWEAI_DEPR", replace

*D-6. Create sample weighted variables for the ch_20p and a_20p mean and DEFF: 
*     (0) overall, (1) <30yo, and (2) 30+ yo if the woman is not missing any
*     5DE indicators.
set more off
foreach var of varlist ch_20p a_20p {
	svy: mean `var' if miss_any==0 
	estat effects
	mat a=e(b)
    mat d=e(deff)
	gen mean_0_`var'=a[1,1]
	gen deff_0_`var'=d[1,1]
	
	svy: mean `var' if miss_any==0, over(age_cat) 
	estat effects
	mat a=e(b)
    mat d=e(deff)
	gen mean_1_`var'=a[1,1]
	gen mean_2_`var'=a[1,2]
	gen deff_1_`var'=d[1,1]
	gen deff_2_`var'=d[1,2]
}

*D-7. Collapse the data to get the mean ch_20p and a_20p and DEFF values for 
*   each of the three groups.
collapse (mean) *_ch_20p *_a_20p

*D-8. Generate the 5DE score (EA_20p) for each group by multiplying the mean 
*      ch_20p and the mean a_20p.
gen EA_20p0=1-(mean_0_ch_20p*mean_0_a_20p)
gen EA_20p1=1-(mean_1_ch_20p*mean_1_a_20p)
gen EA_20p2=1-(mean_2_ch_20p*mean_2_a_20p)

*D-11. Generate the DEFF for each group by averaging the ch_20p and a_20p DEFFs.
gen deff0=(deff_0_ch_20p + deff_0_a_20p)/2
gen deff1=(deff_1_ch_20p + deff_1_a_20p)/2
gen deff2=(deff_2_ch_20p + deff_2_a_20p)/2

*D-12. Create a dummy variable equal to one and reshape the data from wide to long. 
gen ID = 1
reshape long EA_20p deff, i(ID) j(age_cat)

*D-13. Keep only the EA_20p, deff, and age_cat variables.
keep EA_20p deff age_cat

*D-14. Initialize a counter equal to 0.
gen replicate=0

*D-15. Save the data to a tempory data file, 5DE_JK.
save Temp\5DE_JK, replace

*D-16. Create a scalar equal to the number of sample clusters (hhea) in the analysis
       *INSTRUCTIONS: ADJUST P2 TO BE EQUAL TO # OF CLUSTERS INCLUDED IN ANALYSIS*
scalar PS2=8 

*D-17. Perform the jackknife computation for the 5DE using the following loop.
*      For each cluster included in the analysis, a 5DE score (EA_20p) is 
*      generated for all women, women 18-29 years old, and women 30 years of age
*      or older using a jacknife approach, which involves dropping the cases
* .    from one cluster at a time, adjusting the weights, calculating the 5DE
*      scores, and and appending the 5DE scores to a data file that will later
*      be used to get mean 5DE scores (overall and by age group).
set more off
local i=1
        while `i'<=PS2 {

use Temp\AWEAI_DEPR, replace 
drop if id==`i'

bys strata: egen allocj=total(wgt_pfdm)
bys strata age_cat: egen allocj_AGE=total(wgt_pfdm)

gen wtadj=wgt_pfdm*(alloc/allocj)
gen wtadj_AGE=wgt_pfdm*(alloc_AGE/allocj_AGE)

save Temp\AWEAI_DEPR_`i', replace

*replacing weight by weightadj
collapse ch_20p a_20p [aw=wtadj]
gen age_cat=0
save Temp\NATIONAL_`i', replace

use Temp\AWEAI_DEPR_`i', clear
collapse ch_20p a_20p [aw=wtadj_AGE],by(age_cat)
append using Temp\NATIONAL_`i', force 

gen EA_20p=1-(ch_20p*a_20p)

keep age_cat EA_20p

gen replicate=`i'

append using Temp\5DE_JK, force 
save Temp\5DE_JK, replace
 
erase Temp\AWEAI_DEPR_`i'.dta
erase Temp\NATIONAL_`i'.dta
 
local i=`i'+1	
}

*D-18. Erase the temporary AWEAI_DEPR data file.
erase Temp\AWEAI_DEPR.dta

*D-19. Reshape the data from long to wide. 
reshape wide EA_20p deff, i(replicate) j(age_cat)

*D-20. Save the data to a temporary file, 5DE_JK.
save Temp\5DE_JK, replace

*D-21. Create a global variable for the three EA_20p variables created in the 
*      Jackknife loop for each cluster.
global varlist_0 EA_20p0 EA_20p1 EA_20p2

*D-22. Create variables needed to calculated the standard errors of the three 
*      EA_20p variables
foreach var of varlist $varlist_0 {
  gen A_`var' = (PS2*`var'[1] - (PS2-1)*`var')
  gen B_`var' = (A_`var' - `var'[1])^2
}  

*D-23. Drop the first row in the data file that has the DEFFs.
drop if replicate==0

*D-24. Collapse the data for each cluster to generate mean values an rename the 
*      variables.
collapse (sum) JKSE_EA_20p0=B_EA_20p0 /// 
               JKSE_EA_20p1=B_EA_20p1 ///
			   JKSE_EA_20p2=B_EA_20p2 

*D-21. Create a global variable for the three variables created in Step D-24.
global varlist_1 JKSE_EA_20p0 JKSE_EA_20p1 JKSE_EA_20p2

*D-22. Calculate the standard eror for the three EA_20p variables
foreach var of varlist $varlist_1 {
  gen SE_`var' = sqrt(`var'/(PS2*(PS2-1)))
  drop `var'
}

*D-23. Create an ID variable equal to 1 and save the data file containing the 
*      standard errors.
gen ID=1
save Temp\5DE_SE, replace

*D-24. Load the 5DE data file saved in Step D-20 and keep only the row with the DEFFs.
use Temp\5DE_JK, replace
drop if replicate!=0

*D-25. Create an ID equal to 1 and merge the data file with the 5DE standard 
*      error data file.
gen ID=1
merge 1:1 ID using Temp\5DE_SE
drop _merge replicate

*D-26. Rename the standard error variables.
rename SE_JKSE_EA_20p0 SE0
rename SE_JKSE_EA_20p1 SE1		
rename SE_JKSE_EA_20p2 SE2

*D-27. Tranform the data file from wide to long.
reshape long EA_20p SE deff, i(ID)
drop ID _j 

*D-28. Create row labels.
input str11 Label
"All women"  
"Young women"    
"Old women"  

*D-29. Create variables equal to the upper and lower bounds of the 95% confidence
*      intervals for the 5DE.
gen LCI = EA_20p - (1.96*SE)
gen UCI = EA_20p + (1.96*SE)

*D-30. Save the data to a temporary data file, 5DE_FINAL
order Label EA_20p SE LCI UCI, first
save Temp\5DE_FINAL, replace

*D-31. Export the 5DE results (5DE SE, LCI, and UCI) to Excel.
export excel using "$analytic\Results\5DE CI.xlsx", firstrow(variables) replace

di "Date:$S_DATE $S_TIME"
log close

end 

********************************************************************************
********************************** TABLES **************************************
********************************************************************************
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] aweai_individual_indices.dta", clear

gen age_young=0
replace age_young=1 if age_cat==1
la var age_young "Woman is 18-29 years old"
la val age_young YESNO

gen age_old=0
replace age_old=1 if age_cat==2
la var age_old "Woman is 30+ years old"
la val age_old YESNO

*Women with all 6 indicators, adequate (TABLE 6.3.1)
sum $varlist_ndepr_nraw 
foreach var in $varlist_ndepr_nraw {
	svy: tab `var', over(survey)
	svy, subpop(age_young): tab `var', over(survey)
	svy, subpop(age_old): tab `var', over(survey)
}

*Disempowered women, adequate (TABLE 6.3.2)
sum $varlist_ndepr_dis 
foreach var in $varlist_ndepr_dis {
	svy: tab `var', over(survey)
	svy, subpop(age_young): tab `var', over(survey)
	svy, subpop(age_old): tab `var', over(survey)
}

*All women, adequate (TABLE 6.3.3)
sum $varlist_emp_ndepr
foreach var in $varlist_emp_ndepr {
	svy: tab `var', over(survey)
	svy, subpop(age_young): tab `var', over(survey)
	svy, subpop(age_old): tab `var', over(survey)
}