/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
********************** 5DE CALCULATIONS, A-WEAI INDICATORS *********************
****************************** [COUNTRY] [YEAR] ********************************
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

	1. Data preparation: 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_1 prep.do
	2. 5DE-related calculations (current file): 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_2 5DEcalc.do

A third file can be used to compare 5DE results between baseline and midline and 
generate the results that are reported in the results tables of Chapter 6 of the
midline indicator assessment report template:

	3. Midline/baseline comparative results:
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_3 ML_BL_compare.do

This 5DE calc file includes syntax to calculate:

	1. variables needed for section 6.2 of the survey report:
	   the 5DE, the % of women who are empowered, and the average inadequacy score 
	2. variables needed for section 6.3 of the survey report:
	   the % of women who have data for all 5DE indicators who are adequate in each indicator,
	   the % of women who are disempowered who are adequate in each indicator,
	   the % of all women who are adequate in each indicator
	3. the 5DE standard error (SE), 95% confidence interval (CI), and design effect (DEFF)
	   required for Tables ES1 and/or A1.1 of the survey report

This file should be run after the AWEAI_1 prep do file has been run.

Syntax updated from baseline syntax by ICF, 2022/2023 

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 12.3, Part 2 through Part 3, Step 1 of the 
Guide to Feed the Future Midline Statistics. 

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
**#***************** Part 2, Step 1. Weighted adequacy score *******************
********************************************************************************
*Step 1.1: Create a global variable (varlist_emp) with all six A-WEAI indicators indicating adequacy.
global varlist_all feelinputdecagr jown_count credjanydec_any incdec_count groupmember_any npoor_z105

******The six A-WEAI indicators******
*Indicator 1-input into productive decision-making
*Indicator 2-asset ownership
*Indicator 3-input into credit decision-making
*Indicator 4-input into income decision-making
*Indicator 5-group membership
*Indicator 6-workload

la var feelinputdecagr "Adequate in decision-making (Indicator 1), all women"
la var jown_count 	   "Adequate in asset ownership (Indicator 2), all women"
la var credjanydec_any "Adequate in credit decision-making (Indicator 3), all women" 
la var incdec_count    "Adequate in income decision-making (Indicator 4), all women"
la var groupmember_any "Adequate in group membership (Indicator 5), all women"
la var npoor_z105 	   "Adequate in work hours (Indicator 6), all women"

tab1 $varlist_all 
sum  $varlist_all 

*Step 1.2: Create variables for A-WEAI indicator weights.
*          Weights sum to 1 (not to the number of indicators)

*Step 1.2A: Assign weight of 1/5 for domain 1, 3, 4, and 5 indicators
foreach var in feelinputdecagr incdec_count groupmember_any npoor_z105 {
  gen w_`var'=1/5
}

*Step 1.2B: Assign weights to domain 2 indicators: 2/15 for asset ownership 
*           indicator & 1/15 for credit access indicator.
gen w_jown_count=2/15
gen w_credjanydec_any=1/15

*Step 1.3: Apply the weights to each A-WEAI indicator indicating adequacy.
foreach var in $varlist_all {
	gen wg0_`var'= `var'*w_`var'
}

*Step 1.4: Create a global variable (wg0_varlist_emp) with the six weighted A-WEAI indicators indicating adequacy.
global wg0_varlist_all wg0_feelinputdecagr wg0_jown_count wg0_credjanydec_any wg0_incdec_count wg0_groupmember_any wg0_npoor_z105
sum $wg0_varlist_all 

*Step 1.5: Compute the frequency of missing values for each A-WEAI indicator indicating adequacy.
foreach var in $varlist_all {
  gen `var'_miss=1 if `var'==.
  replace `var'_miss=0 if `var'!=.
}

tab1 *_miss
sum *_miss

*Step 1.6: Define the weighted adequacy count vector "ca". 
egen ca=rsum($wg0_varlist_all) 
replace ca=round(ca,.0001) 
la var ca "Weighted adequacy score"
tab ca

*Step 1.7: Determine the number of A-WEAI indicators indicating adequacy each 
*          respondent is missing.
egen n_missing=rowmiss($wg0_varlist_all) 
la var n_missing "Number of missing variables by individual"
tab n_missing

*Step 1.8: Create a variable indicating if respondent is missing any of the six 
*          A-WEAI indicators.
gen miss_any=(n_missing>0) 
la var miss_any "Individual has missing variables"
tab miss_any

*Step 1.9: Check sample for respondents missing values.
tab miss_any
*list miss_any $varlist_all if miss_any!=0

*Step 1.10: Save the data file.
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] aweai_depr_indicators.dta", replace

********************************************************************************
**#*****Part 2, Step 2. Empowerment and adequacy scores among disempowered *****
********************************************************************************
*Step 2.1: Create a binary variable that indicates whether the individual is 
*          empowered using a weighted adequacy score threshold of 0.8 (emp_80p). 
*          Women with a weighted adequacy score (ca, created in Step 1.6) equal 
*          to or higher than the threshold (i.e., ca≥0.8) are considered empowered. 
gen emp_80p=(ca>=float(80/100))
replace emp_80p=. if miss_any==1 
label var emp_80p "Woman is empowered, adequacy threshold>=0.8)"
tab emp_80p

*Step 2.2: Create a binary variable that indicates whether the individual is 
*          disempowered using a threshold of 0.8 (dis_80p). Women with weighted 
*          adequacy in the six A-WEAI indicators less than the threshold 
*          (i.e., ca<0.8) are considered disempowered. 
gen dis_80p=(ca<float(80/100))
replace dis_80p=. if miss_any==1 
label var dis_80p "Woman is disempowered, adequacy threshold>=0.8%"
tab dis_80p

*Step 2.3: Create a variable equal to the weighted adequacy score of those who 
*          are disempowered (ad_80p).
gen ad_80p=(ca) if dis_80p==1
label var ad_80p "Adequacy score (ca) for disempowered, adequacy threshold>=0.8"
tab ad_80p

********************************************************************************
**#********************* Part 2, Step 3. 5DE CALCULATION************************
********************************************************************************
*Step 3.1: Define the complex survey design
svyset hhea [pw=wgt_fpdm], strata(strata)

*Step 3.2: Create a variable equal to the mean sample-weighted ch_80p value, which 
*       is the percentage of women who are empowered.
svy: mean emp_80p
gen swp_emp_80p=e(b)[1,1]
la var swp_emp_80p "Sample-weighted percent empowered, adequacy threshold>=0.8"
tab swp_emp_80p

*Step 3.3: Create a variable equal to the mean sample-weighted ch_80p value, which 
*       is the percentage of women who are empowered.
*       (Note: ch_80p gets renamed H_80p after collapse)
svy: mean dis_80p
gen swp_dis_80p=e(b)[1,1]
la var swp_dis_80p "Sample-weighted percent disempowered, adequacy threshold<0.8"
tab swp_dis_80p

*Step 3.4: Create a variable equal to the average adequacy score among disempowered women
svy: mean ad_80p
gen swm_ad_80p=e(b)[1,1]
label var swm_ad_80p "Sample-weighted mean weighted adequacy count (ca) for disempowered, k=20%"
tab swm_ad_80p

*Step 3.5: Create a variable equal to the 5DE score 
/*5DE calculation: EA=He+(Hn*Aa)
	He=Percent of women who are empowered (swp_emp_80p)
	Hn=Percent of disempowered women (swp_dis_80p)
	Aa=Average percent of indicators in which disempowered women have adequate achievements (swm_ad_80p)
*/
gen EA_80p=swp_emp_80p+(swp_dis_80p*swm_ad_80p)
la var EA_80p "5DE (5 domains of empowerment), constant"
tab EA_80p

*Step 3.6: Save the individual-level data file before collapsing it.
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] aweai_individual_indices.dta", replace  

********************************************************************************
**#***** Part 3, Step 1. 5DE STANADARD ERROR CALCULATION (JACKKNIFE) ***********
********************************************************************************
*Step 1.1: Create a variable that indicates if the woman is <30 or 30+ years old
*          based on the age varible. 

gen		fdm_agecat=missing
replace fdm_agecat=1 if age>=18 & age<30 
replace fdm_agecat=2 if age>=30 & age<98 
la def 	fdm_agecat 1 "18-29 years" 2 "30+ years"
la val 	fdm_agecat fdm_agecat
la var	"Female PDM's age (18-29, 30+)"

*Step 1.2: Create a sequential cluster ID variable that starts from 1 
sort hhea
egen id = group(hhea)

*Step 1.3: Create total weight variables by strata and sex
bys strata: egen alloc=total(wgt_fpdm) if miss_any==0

*Step 1.4: Create total weight variables by strata, sex, and age
bys strata fdm_agecat: egen alloc_AGE=total(wgt_fpdm) if miss_any==0

*Step 1.5: Save the data to a temporary data file, AWEAI_DEPR.
save "$analytic\Results\AWEAI_DEPR", replace
cd "$analytic\"

*Step 1.6: Create sample weighted variables for the ch_80p and a_80p mean and DEFF: 
*          (0) all women, (1) <30yo, and (2) 30+ yo if the woman is not missing any
*          5DE indicators.
set more off
foreach var of varlist emp_80p dis_80p ad_80p {
	svy: mean `var' if miss_any==0 
	estat effects
	mat a=e(b)
    mat d=e(deff)
	gen mean_0_`var'=a[1,1]
	gen deff_0_`var'=d[1,1]
	
	svy: mean `var' if miss_any==0, over(fdm_agecat) 
	estat effects
	mat a=e(b)
    mat d=e(deff)
	gen mean_1_`var'=a[1,1]
	gen mean_2_`var'=a[1,2]
	gen deff_1_`var'=d[1,1]
	gen deff_2_`var'=d[1,2]
}

*Step 1.7: Collapse the data to get the mean ch_80p and a_80p and DEFF values for 
*          each of the three groups.
collapse (mean) *emp_80p *dis_80p *ad_80p /*ia_80p*/

*Step 1.8: Generate the 5DE score (EA_80p) for each group by multiplying the mean 
*          ch_80p and the mean a_80p.
gen EA_80p0=mean_0_emp_80p+(mean_0_dis_80p*mean_0_ad_80p)
gen EA_80p1=mean_1_emp_80p+(mean_1_dis_80p*mean_1_ad_80p)
gen EA_80p2=mean_2_emp_80p+(mean_2_dis_80p*mean_2_ad_80p)

*Step 1.9: Generate the DEFF for each group by averaging the ch_80p and a_80p DEFFs.
gen deff0=(deff_0_emp_80p + deff_0_ad_80p)/2
gen deff1=(deff_1_emp_80p + deff_1_ad_80p)/2
gen deff2=(deff_2_emp_80p + deff_2_ad_80p)/2

*Step 1.10: Keep only the EA_80p and deff variables.
keep EA_80p* deff*

*Step 1.11: Create a variable equal to one (ID) and reshape the data from wide to long. 
gen ID = 1
reshape long EA_80p deff, i(ID) j(fdm_agecat)
drop ID

*Step 1.12: Initialize a counter equal to 0.
gen replicate=0

*Step 1.13: Save the data to a tempory data file, 5DE_JK.
save Results\5DE_JK, replace

*Step 1.14: Create a scalar equal to the number of sample clusters (hhea) in the analysis
       *INSTRUCTIONS: ADJUST P2 TO BE EQUAL TO # OF CLUSTERS INCLUDED IN ANALYSIS*
scalar PS2=[XX]

*Step 1.15: Perform the jackknife computation for the 5DE using the following loop.
*           For each cluster included in the analysis, a 5DE score (EA_80p) is 
*           generated for all women, women 18-29 years old, and women 30 years of 
*           ageor older using a jacknife approach, which involves dropping the 
* .         casesfrom one cluster at a time, adjusting the weights, calculating 
*           the 5DEscores, and and appending the 5DE scores to a data file that 
*           will later be used to get mean 5DE scores (overall and by age group).
set more off
local i=1
  while `i'<=PS2 {

	use Results\AWEAI_DEPR, replace 
	drop if id==`i'

	bys strata: egen allocj=total(wgt_fpdm) if miss_any==0
	bys strata fdm_agecat: egen allocj_AGE=total(wgt_fpdm) if miss_any==0

	gen wtadj=wgt_fpdm*(alloc/allocj) 
	gen wtadj_AGE=wgt_fpdm*(alloc_AGE/allocj_AGE) 

	save Results\AWEAI_AGE_`i', replace

	collapse emp_80p dis_80p ad_80p [aw=wtadj]
	gen fdm_agecat=0
	save Results\AWEAI_OVERALL_`i', replace

	use Results\AWEAI_AGE_`i', clear
	collapse emp_80p dis_80p ad_80p [aw=wtadj_AGE],by(fdm_agecat)
	append using Results\AWEAI_OVERALL_`i', force 

	gen EA_80p=emp_80p+(dis_80p*ad_80p)

	keep fdm_agecat EA_80p

	gen replicate=`i'

	append using Results\5DE_JK, force 
	save Results\5DE_JK, replace
	 
	erase Results\AWEAI_AGE_`i'.dta
	erase Results\AWEAI_OVERALL_`i'.dta
	 
	local i=`i'+1	
}

*Step 1.16: Erase the temporary AWEAI_DEPR data file.
erase Results\AWEAI_DEPR.dta

*Step 1.17: Reshape the data from long to wide. 
reshape wide EA_80p deff, i(replicate) j(fdm_agecat)

*Step 1.18: Save the data to a temporary file, 5DE_JK.
save Results\5DE_JK, replace

*Step 1.19: Create a global variable for the three EA_80p variables created in the 
*          Jackknife loop for each cluster.
global varlist_0 EA_80p0 EA_80p1 EA_80p2

*Step 1.20: Create variables needed to calculated the standard errors of the three 
*           EA_80p variables
foreach var of varlist $varlist_0 {
  gen A_`var' = (PS2*`var'[1] - (PS2-1)*`var')
  gen B_`var' = (A_`var' - `var'[1])^2
}  

*Step 1.21: Drop the first row in the data file that has the DEFFs.
drop if replicate==0

*Step 1.22: Collapse the data for each cluster to generate mean values an rename the 
*           variables.
collapse (sum) JKSE_EA_80p0=B_EA_80p0 /// 
               JKSE_EA_80p1=B_EA_80p1 ///
			   JKSE_EA_80p2=B_EA_80p2 

*Step 1.23: Create a global variable for the three variables created in Step D-24.
global varlist_1 JKSE_EA_80p0 JKSE_EA_80p1 JKSE_EA_80p2

*Step 1.24: Calculate the standard eror for the three EA_80p variables
foreach var of varlist $varlist_1 {
  gen SE_`var' = sqrt(`var'/(PS2*(PS2-1)))
  drop `var'
}

*Step 1.25: Create an ID variable equal to 1 and save the data file containing the 
*      standard errors.
gen ID=1
save Results\5DE_SE, replace

*Step 1.26: Load the 5DE data file saved in Step D-20 and keep only the row with the DEFFs.
use Results\5DE_JK, replace
drop if replicate!=0

*Step 1.27: Create an ID equal to 1 and merge the data file with the 5DE standard 
*           error data file.
gen ID=1
merge 1:1 ID using Results\5DE_SE
drop _merge replicate

*Step 1.28: Rename the standard error variables.
rename SE_JKSE_EA_80p0 SE0
rename SE_JKSE_EA_80p1 SE1		
rename SE_JKSE_EA_80p2 SE2

*Step 1.29: Tranform the data file from wide to long.
reshape long EA_80p SE deff, i(ID)
drop ID _j 

*Step 1.30: Create row labels.
input str11 Label
"All women"  
"Young women"    
"Old women"  

*Step 1.31: Create variables equal to the upper and lower bounds of the 95% confidence
*      intervals for the 5DE.
gen LCI = EA_80p - (1.96*SE)
gen UCI = EA_80p + (1.96*SE)

*Step 1.32: Save the data to a temporary data file, 5DE_FINAL
order Label EA_80p SE LCI UCI, first
gen survey=1
gen cat=0
replace cat=1 if Label=="All women"
replace cat=2 if Label=="Women 18-29y"
replace cat=3 if Label=="Women 30+y"
la def cat 1 "All women" 2 "Women 18-29 years" 3 "Women 30+ years"
la val cat cat
lab var cat "Women's age category (A-WEAI)"
save Results\5DE_FINAL_BL, replace

*Step 1.33: Export the 5DE results (5DE SE, LCI, and UCI) to Excel.
export excel using "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [YEAR] 5DE CI.xlsx", firstrow(variables) replace

end 

********************************************************************************
**#***** Part 4. Calculating adequate achievement in each A-WEAI indicator *****
********************************************************************************
*Load the data file with the empowerment and average adequacy variables 
use "$analytic\Results\FTF_ZOI_Survey [COUNTRY] [ML YEAR] aweai_individual_indices.dta", clear

*Confirm that this is variable has two categories as created in Part 3, Step 1:
*1=women 18-29 years, 2=women 30+ years. If not in your data file, create it.
tab fdm_agecat 

*Create a variable list for the six A-WEAI variables
global varlist_all feelinputdecagr jown_count credjanydec_any incdec_count groupmember_any npoor_z105

*****TABLE 6.3.1 (Women with all data for all 6 A-WEAI indicators, adequate)
sum $varlist_all if miss_any==0 
foreach var in $varlist_all {
	svy, subpop(if miss_any==0): tab `var', col ci perc format(%6.1f) obs
	svy, subpop(if miss_any==0): tab `var' fdm_agecat, col ci perc format(%6.1f) obs
}

*****TABLE 6.3.2 (Disempowered women, adequate)
sum $varlist_all if dis_20p==1
foreach var in $varlist_all {
	svy, subpop(if dis_20p==1): tab `var', col ci perc format(%6.1f) obs
	svy, subpop(if dis_20p==1): tab `var' fdm_agecat, col ci perc format(%6.1f) obs
}

*****TABLE 6.3.3 (All women, adequate)
sum $varlist_all
foreach var in $varlist_all {
    svy: tab `var' survey, col ci perc format(%6.1f) obs
	svy: tab `var' fdm_agecat, col ci perc format(%6.1f) obs
}
di "Date:$S_DATE $S_TIME"
log close
