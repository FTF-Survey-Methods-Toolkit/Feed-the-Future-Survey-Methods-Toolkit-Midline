/*******************************************************************************
*************************** FEED THE FUTURE ZOI SURVEY *************************
************************ AGRICULTURE TECH INDICATORS: ALL *********************
********************************* [COUNTRY-YEAR] *******************************
********************************************************************************
Description: This code is intended to calculate OVERALL improved Agricultural 
             technology indicator. This is 10 of 10 preparatory syntax files to 
             calculate final Agriculturual technology indicator

Author(s): Nizam Khan and Kirsten Zalisk @ICF, August 2018
Revised by: Kirsten Zalisk @ ICF, July 2019

This syntax file was developed using the core Feed the Future ZOI Survey phase one 
endline/phase two baseline core questionnaire. It must be adapted for the final  
country-specific questionnaire. The syntax could only be partially tested using 
ZOI Survey data; therefore, double-check all results carefully and troubleshoot 
to resolve any issues identified. 
*******************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:   $analytic\Results\FTF ZOI Survey [Country] [Year] agtech_maize.dta
//				$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_fishpond.dta
//				$analytic\FTF ZOI Survey [Country] [Year] persons analytic data.dta
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_all.do 

cap log close 
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.log",replace
********************************************************************************
*INSTRUCTIONS: Update the do file to reflect the VCCs included in the survey, and
*that were already analyzed by VCC in other agtech do files. 

*Step 1. Append all crop agtech data files if there is more than one crop VCC 
*        included in the survey and save the data file. If there is only one crop 
*        VCC, skip this step. Maize and millet are used here as an example.
use          "$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_maize", clear  
append using "$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_millet"

*Step 2. Create one record per farmer if there is more than one crop VCC 
*        included in the survey. If there is only one crop VCC, skip this step.
collapse (sum) imp_*, by(hhea hhnum m1_line)
sum imp_*
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",replace

*Step 3. Append all livestock agtech data files if there is more than one livestock 
*        VCC included in the survey. If there is only one livestock VCC, skip 
*        this step. Livestock include goats, sheep, and dairy cows. There are no
*        livestock VCCs in the example, so this step is commented out.
*use  "$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_goats", clear  
*append using "$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_dairy"

*Step 4. Create one record per farmer if there is more than one livestock VCC 
*        included in the survey. If there is only one livestock VCC, skip this step. 
*        There are no livestock VCCs in the example, so this step is commented out.
*collapse (sum) imp_*, by(hhea hhnum m1_line)
*sum imp_*
*save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] livestock_all",replace

*Step 5. Merge the livestock data with the crop data, keeping only the overall 
*        improved practices/technology for livestock. There are no
*        livestock VCCs in the example, so this step is commented out.
*use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",clear
*mmerge using "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] livestock_all", ukeep(imp_any_lstock)
*save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",replace

*Step 6. Merge the fishpond data with the crop data, keeping only the overall 
*        improved practices/technology for fishponds. Skip this step if fishponds
*        are not a VCC included in the survey.
mmerge using "$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_fishpond.dta", ukeep(imp_any_fish)
tab _merge
drop _merge

sum imp_*

*Step 7. Create a new variable for each improved practice and technology category 
*        to indicate if the farmer used any improved practices/technologies in 
*        that category.
*2/23/2021: Added X after recode - had been missing
for var imp_*: recode X 1/max=1, gen(X_any)
sum imp_*_any

*Step 8. Create a global variable that includes all category variables
*        INSTRUCTION: Add imp_any_lstock if applicable. Remove imp_any fish if 
*        not applicable.
global IMP imp_genetics imp_culture imp_ecosys imp_pest imp_fert imp_irrig imp_water ///
           imp_adapt imp_market imp_harvest imp_valadd imp_pest imp_oth imp_any_fish
		   
*Step 9. Create a variable to count the total number of categories farmers used
*        improved practices/technologies from.
egen   imptech_tot=rowtotal($IMP)
tab    imptech_tot                             
la var imptech_tot "Total number of improved technology categories practiced"

*Step 10. Create a variable to indicate whether farmers used any improved practices/technologies.
gen    imptech_any=imptech_tot>=1
la var imptech_any "Used any improved practice/technology"

*Step 11. Add variables from individual-leveld data file needed to calculate the 
*         overall ag tech indicator and its disaggregates and save the data file.
mmerge hhea hhnum m1_line using "$analytic\FTF ZOI Survey [Country] [Year] persons analytic data", ///
                          ukeep(hhea hhnum age sex *vcc* wgt_vcc* samp_stratum) 
tab _merge
drop _merge

tab1 sex age vcc_youth vcc_*

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",replace
 
*Step 12. Apply the farmer sampling weight to adjust for the survey design, and
*         calculate the indicator in total and by its disaggregates for de jure
*         HH members. Note that the commodity disaggregate was already calculated
*         in the individual VCC do files.
svyset hhea [pw=wgt_f], strata(samp_stratum) 

//IN TOTAL
svy, subpop(hhmem_dj): prop imptech_any 

//BY SEX: Proportion practiced improved management practice and technology
svy, subpop(hhmem_dj): prop imptech_any, over(sex)		   

//BY AGE GROUP: Proportion practiced improved management practice and technology    
svy, subpop(hhmem_dj): prop imptech_any, over(vcc_youth)		   

//BY TECHNOLOGY TYPE: Proportion practiced improved management practice and technology 		   
foreach x of varlist $IMP {
  svy, subpop(hhmem_dj): prop `x' 
}  

di "Date:$S_DATE $S_TIME"
log close		   
 
		   
		   
