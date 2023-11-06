/*******************************************************************************
*************************** FEED THE FUTURE ZOI SURVEY *************************
************************ AGRICULTURE TECH INDICATORS: MAIZE *********************
********************************* [COUNTRY-YEAR] *******************************
********************************************************************************
Description: This code is intended to calculate improved Agricultural technology
             indicator for MAIZE. 

Author(s): Nizam Khan and Kirsten Zalisk @ICF, September 2018
Revised by: Kirsten Zalisk @ ICF, August 2019

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

//Input data:   $analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_maize.do 

cap log close 
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.log",replace
********************************************************************************
/*STEP 1: Review the maize section of the agriculture module in the ZOI Survey 
questionnaire and identify questions that relate to improved management practices 
and technologies being promoted in the ZOI. Determine which response options 
would be considered targeted improved management practices and technologies, and 
also determine what category or categories the targeted improved management 
practices and technologies fall under. 

If Feed the Future is promoting a management practice or technology for multiple 
benefits, be sure that producers applying the management practice or technology 
are reported under each category for which the technology is being promoted. 
Conversely, if Feed the Future is promoting a management practice or technology 
for a single benefit though it could be promoted for multiple benefits, be sure 
that producers applying the management practice or technology are reported under 
only the one category for which the technology is being promoted.*/

//STEP 2: Prepare data 		

**2a. Load individual level data file
use "$analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta", clear

**2b. Review the variable already created and included in the persons-level data
**    file that flags maize farmers (vcc_maize) who completed the maize module. 
**    If not in the data file, createit. 
tab vcc_maize
*gen vcc_maize=1 if v7100d==1

**2c. Drop all farmers from the data who did not cultivate maize in the year 
*     preceding the survey and drop variables not required to generate maize
*     specific variables.
keep if vcc_maize==1 
keep hhea hhnum samp_stratum sex age *vcc* m1_line v71* 

//Step 3: Create 12 binary variables for each targeted improved management 
//practice and technology type that applies to crops to flag farmers who applied 
//targeted improved management practices or technologies to cultivate maize 
//(applied=1, not applied=0). 
*2/23/2021: Updated improved practices/technologies to match Guide to Statistics.
la def applied 0 "Did not apply" 1 "applied", modify

//STEP 3a: Crop genetics  
gen imp_genetics=(v7107b1==1|v7107c1==1) | inlist(v7107aa,2,3) 
la val imp_genetics applied
la var imp_genetics "Improved crop genetics" 

//STEP 3b: Cultural practices 
gen imp_culture=inlist(v7109,1,3) 
la val imp_culture applied
la var imp_culture"Improved cultural practices"
tab imp_culture

//STEP 3c: Natural resource or ecosystem management 
gen imp_ecosys=(v7111ba==1|v7111bc==1)| (v7119c==1) | (v7121a==1|v7121c==1 )  
la val imp_ecosys applied
la var imp_ecosys "Improved natural resources and ecosystem management" 
tab imp_ecosys

//STEP 3d: Pest and disease management	
gen imp_pest=(v7115==1) | (v7119b==1|v7119c==1)
la var imp_pest "Improved pest and disease management"
tab imp_pest

//STEP 3e: Soil-related fertility and conservation
gen imp_fert=(v7121a==1|v7121b==1|v7121c==1)
la val imp_fert applied
la var imp_fert "Improved soil related fertility and conservation" 
tab imp_fert

//STEP 3f: Irrigation
gen imp_irrig=(v7123c1==1|v7123d1==1)
la var imp_irrig "Improved irrigation"
tab imp_irrig

//STEP 3g: Agriculture water management (non-irrigation)
gen imp_water=(v7121a==1|v7121b==1|v7121c==1)
la val imp_water applied
la var imp_water "Improved agriculture water management" 
tab imp_water

//STEP 3h: Climate adaption (climiate mitigation not included as a category)
gen imp_adapt=(v7107b1==1|v7107c1==1)| (v7123c1==1 |v7123d1)
la val imp_adapt applied
la var imp_adapt "Improved climate adaption/management" 
tab imp_adapt

//STEP 3i: Marketing and distribution
gen imp_market=(v7106==4|v7106==5) | (v7124ag==1|v7124ce==1)
la var imp_market "Improved marketing and distribution"
tab imp_market

//STEP 3j: Post harvest handling and storage
gen imp_harvest=(v7126h==1|v7126i==1) | (v7129c==1) | (v7130e==1)
la val imp_harvest applied
la var imp_harvest "Improved post-harvest handling and storage" 
tab imp_harvest

//STEP 3k: Value added processing
gen imp_valadd=(v7127c==1)
la var imp_valadd "Improved value added processing"
tab imp_valadd

//STEP 3l: Other
gen imp_oth=(v7105c==1|v7105d==1) | inlist(v7124,2,3) 
la val imp_oth applied
la var imp_oth "Improved other improved management practices and technologies"
tab imp_oth

//STEP 4. Generate a count variable to capture total number of targeted improved management 
//practice or technology types practiced to cultivate maize (totimp_ maize).
gen totimp_maize = imp_genetics + imp_culture + imp_ecosys + imp_pest + imp_fert +   ///  
                   imp_irrig + imp_water + imp_adapt + imp_market + imp_harvest +   /// 
                   imp_valadd + imp_oth
la var totimp_maize "Total number of targeted improved management practice and technology types applied"
tab totimp_maize

//STEP 5. Generate a binary variable to indicate if farmer applied any targeted improved    
//management practices or technologies to cultivate  maize (anyimp_maize).
gen anyimp_maize=0
replace anyimp_maize=1 if totimp_ maize>0 & totimp_maize!=.
la val anyimp_maize applied
la var anyimp_maize "Applied any targeted improved management practice and technology types applied"						
tab anyimp_maize

//STEP 6. Calculate sample-weighted percentage of maize farmers who applied at 
**        least one targeted improved management practice or technology to raise
**		  maize and divide by the total number of maize farmers who cultivated 
**        maize after applying the vcc1 farmer weight. Overall and by category
svyset hhea [pw=wgt_maize], strata(samp_stratum)
svy, subpop(hhmem_dj): prop anyimp_maize
svy, subpop(hhmem_dj): prop anyimp_maize, over(vcc_youth)
svy, subpop(hhmem_dj): prop anyimp_maize, over(sex)

for each var in varlist imp_* {
  svy, subpop(hhmem_dj): prop `var'
}
	 			   
//STEP 7. Keep only the variables that are necessary to calculate the final 
**         overall indicator across all VCCs and save the data.
keep hhea hhnum m1_line imp_* totimp_maize anyimp_maize

save "$indicator\output\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize",replace

di "Date:$S_DATE $S_TIME"
log close
