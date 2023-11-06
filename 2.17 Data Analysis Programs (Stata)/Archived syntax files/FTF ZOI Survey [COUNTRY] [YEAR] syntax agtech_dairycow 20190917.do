/*******************************************************************************
*************************** FEED THE FUTURE ZOI SURVEY *************************
*******************  AGRICULTURE TECH INDICATORS: LIVESTOCK ********************
********************************* [COUNTRY-YEAR] *******************************
********************************************************************************
Description: This code is intended to calculate the improved dairy cow management
             practices and technologies indicator. 

Author(s): Nizam Khan and Kirsten Zalisk @ICF, August 10, 2018
Revised by: Kirsten Zalisk @ ICF, August 2019

This syntax file was developed using the core Feed the Future ZOI Survey phase one 
endline/phase two baseline core questionnaire. It must be adapted for the final  
country-specific questionnaire. The syntax was not tested using ZOI Survey data; 
therefore, double-check all results carefully and troubleshoot to resolve any 
issues identified. 
*******************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:   $analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_dairycow.do 

cap log close 
log using "$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.log",replace	
********************************************************************************
/*Step 1. Review the dairy cow section of the agriculture module in the ZOI 
Survey questionnaire and identify questions that relate to improved management 
practices and technologies being promoted in the ZOI. Determine which response 
options would be considered targeted improved management practices and technologies, 
and also determine what livestock sub-category or sub-categories the targeted 
improved management practices and technologies fall under. */
use "$analytic\FTF ZOI Survey [Country] [Year] persons data analytic", clear

//STEP 2: Identify variables and prepare data
keep if vcc_dairy==1 
keep hhea hhnum m1_line samp_stratum sex age *vcc* v750*
la def applied 0 "Did not apply" 1 "Applied"

//Step 3: Create binary variables for each of the management practice and technology 
**  types to flag farmers who applied targeted improved management practices or 
**  technologies to raise dairy cows (applied=1, not applied=2).

//STEP 3a: Improved breeds
gen imp_lsbreeds=v75008b==1 | inlist(v75011,3,4,5) 
tab imp_lsbreeds, m
la val imp_lsbreeds applied
la var imp_lsbreeds "Improved breeds"
tab imp_lsbreeds

//STEP 3b: Improved health services and products such as vaccines
gen imp_lshealth=(v75028==1) | (v75033==3) | v75030==1 | /// 
				 (v75034ba==1|v75034bb==1|v75034bc==1)
la val imp_lsheath applied
la var imp_lsheath "Improved health sevices/products"
tab imp_lshealth

//STEP 3c: Improved livestock handling practices and housing  
gen imp_lshousing=inlist(v75016,4,5,6)
la val imp_lshousing applied
la var imp_lshousing "Improved handling practices and housing"
tab imp_lshousing

//STEP 3d: Improved feeding practices	
gen imp_lsfeed=inlist(v75021a,1,2) | inlist(v75024a,1,2) | inlist(v75026a,1,2)
la val imp_lsfeed applied
la var imp_lsfeed "Improved feeding practices"
tab imp_lsfeed

//STEP 3e: Improved grazing practices (none included in core questionnaire)
*gen imp_lsgrazing=.
*la val imp_lsgrazing applied
*la var imp_lsgrazing "Improved grazing practices"
*tab imp_lsgrazing

//STEP 3f: Improved waste management practices
gen imp_lswaste=inlist(v75027b,2,3,4,5)
la val imp_lswaste applied
la val imp_lswaste "Improved waste management practices"
tab imp_lswaste

//STEP 3g:Improved fodder crop	
gen imp_lsfodder=v75019b==1 | v75019c==1 | v75019d==1 | v75019e==1 | ///
				 v75019f==1 | v75019g==1 | v75019h==1 | v75019i==1
*INSTRUCTIONS: Also manually check through the responses entered for X and 
*include any that should be considered promoted, improved fodder crop.
la val imp_lsfodder applied
la var imp_lsfodder "Improved fodder crop"
tab imp_lsfodder

//STEP 3h: Improved cultivation and dual purpose crops (none included in core questionnaire)
*gen imp_lsdualcrop=.
*la val imp_lsdualcrop applied
*la var imp_lsdualcrop "Improved cultivation and dual purpose crops"
*tab imp_lsdualcrop

//STEP 3i: Other improved practices or technologies
gen imp_dc_other=v75045==1 
la val imp_dc_other applied
la var imp_dc_other "Other improved dairy cow practice or technology"
tab imp_dc_other

//STEP 4: Create a count variable to capture total number of targeted improved 
//   management practice or technology types to raise dairy cows (totimp_cow).
sum  imp_*
egen totimp_cow=rsum(imp_*)
tab  totimp_cow

//STEP 5: Create a binary variable to indicate if the dairy cow producer applied
*         any targeted improved management practices or technologies 
gen anyimp_cow=totimp_cow>0
la val anyimp_cow applied
la var "Applied any targeted improved management practice or technology (Dairy cows)"
tab anyimp_cow

//STEP 6. After applying the dairy cow farmer sampling weight, calculate the % of 
*         de jure dairy cow farmers who applied 1+ targeted improved management 
*         practice or technology to raise dairy cows during the year preceding 
*         the survey using the anyimp_cow analytic variable. Repeat using farmers’ 
*         age (<30, 30+) and sex as disaggregates.
svyset hhea [pw=wgt_cow], strata(samp_stratum)
svy, subpop(hhmem_dj): prop anyimp_cow
svy, subpop(hhmem_dj): prop anyimp_cow, over(vcc_youth)
svy, subpop(hhmem_dj): prop anyimp_cow, over(sex)

//STEP 7. Keep only the variables that are necessary to calculate the final overall 
*         indicator across all VCCs and save the data.
Keep hhea hhnum m1_line totimp_cow anyimp_cow imp*
Save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow"

di "Date:$S_DATE $S_TIME"
log close
