/*******************************************************************************
*************************** FEED THE FUTURE ZOI SURVEY *************************
******************* AGRICULTURE TECH INDICATORS: FISHPOND AUACULTURE *******************
********************************* [COUNTRY-YEAR] *******************************
********************************************************************************
Description: This code is intended to calculate improved FISHPOND AQUACULTURE 
management practices and technologies indicator. 
			 
Author(s): Nizam Khan and Kirsten Zalisk @ICF, August 2018
Revised by: Kirsten Zalisk @ ICF, July 2019

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
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_fishpond.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_fishpond.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_fishpond.do 

cap log close 
log using "$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_fishpond.log",replace		
********************************************************************************
/*STEP 1: Review the fishpond section of the agriculture module in the ZOI Survey 
questionnaire and identify questions that relate to improved management practices 
and technologies being promoted in the ZOI. Determine which response options 
would be considered targeted improved management practices and technologies, and 
also determine what sub-category or sub-categories the targeted improved management 
practices and technologies fall under. 

If Feed the Future is promoting a management practice or technology for multiple 
benefits, be sure that producers applying the management practice or technology 
are reported under each sub-category for which the technology is being promoted. 
Conversely, if Feed the Future is promoting a management practice or technology 
for a single benefit though it could be promoted for multiple benefits, be sure 
that producers applying the management practice or technology are reported under 
only the one sub-category for which the technology is being promoted.*/

//STEP 2: Prepare data 		

**2a. Load individual level data file
use "$analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta", clear

**2b. Review the variable already created and included in the persons-level data
**    file that flags fishpond farmers (vcc_fish) who completed the fish module. 
**    If not in the data file, createit. 
tab vcc_fish
*gen vcc_fish=1 if v78000d==1

**2c. Drop all farmers from the data who did not cultivate maize in the year 
*     preceding the survey and drop variables not required to generate maize
*     specific variables.
keep if vcc_fish==1 
keep hhea hhnum samp_stratum sex age vcc* m1_line v78* 

//Step 3. Create eight binary variables—one for each management practice or 
**        technology type sub-category and one for the “other” category to flag 
**        producers who applied targeted improved management practices and 
**        technology to raise fishponds (1=applied, 0=not applied). 
la def applied 0 "Did not apply" 1 "applied", modify

//3a: Pond preparation
gen imp_pondprep=0
replace imp_pondprep=1 if (v78014>0 & v78014!=.) or v78017==1
la val imp_pondprep applied
la var imp_pondprep "Improved pond preparation"
tab imp_pondprep

//3b: Improved fingerlings
gen     imp_fingerlings=0
replace imp_fingerlings=1 if (v78002a==3 | v78002a==4) | (v78009a==1 | ///
                              v78009b==1 | v78009c==1)
la val imp_pondprep applied
la var imp_fingerlings "Improved fish fingerlings"
tab imp_fingerlings

//3c: Improved fish feed and feeding practices
gen imp_fishfeed=0
replace imp_fishfeed=1 if v78004==1 | v78017==1
la val imp_fishfeed applied
la var imp_fishfeed "Improved fish feed & feeding practices"
tab imp_fishfeed

//3d: Fish health and disease control
gen imp_fishhealth=0
replace imp_fishhealth=(v78006==1 | ///
                       (v78010ba==1|v78010bb==1|v78010bc==1|v78010bd==1|v78010be==1) | ///
	                   (v78011ba==1|v78011bb==1|v78011bc==1|v78011bd==1)
la val imp_fishhealth applied
la var imp_fishhealth "Improved fish fish health & disease control"
tab imp_fishhealth
 
//3e: Improved pond culture	
gen imp_pondculture=0
replace imp_pondculture=1 if (v78012ab==1|v78012ac==1)| ///
                             (v78013ad==1|v78013ae==1)| ///
							 (v78014=>1)| ///
							 (v78016a==1|v78016b==1|v78016c==1|v78016d) | ///
							 (v78017==1)
la var imp_pondculture "Improved pond culture"	
la val imp_pondculture applied
tab imp_pondculture

//3f: Management of carrying capacity	
gen imp_fishcarry=0
replace imp_fishcarry=1 if (v78024==1)|(v78016a==1|v78016b==1|v78016c==1|v78016d==1) 
la val imp_fishcarry applied
la var imp_fishcarry "Improved fish mngmt of carrying capacity"	

//3g: fish sampling and harvesting	
gen imp_fishharvest=0
replace imp_fishharvest=1 if v78018a==2 | inlist(v78018b,1,2,3)
la val imp_fishcarry applied
la var imp_fishcarry "Improved fish sampling and harvesting"	
tab imp_fishharvest  

//STEP 4: Generate a count variable to capture total number of targeted improved 
//     management practice or technology types practiced to raise fishponds (totimp_fish).
sum imp_*
egen totimp_fish=rsum(imp_*)
la var totimp_fish "Total number of improved management practice and technology types applied"
tab totimp_fish

//STEP 5: Generate a binary variable to indicate if farmer applied any targeted 
//     improved management practices or technologies to raise fishponds (anyimp_fish).

gen anyimp_fish=0
replace anyimp_fish=1 if totimp_fish>0 & totimp_fish!=.
la var anyimp_fish "Applied any targeted improved management practice and technology types applied"
la val anyimp_fish applied
tab anyimp_fish

//STEP 6. Calculate sample-weighted percentage of maize farmers who applied at 
**        least one targeted improved management practice or technology to raise
**		  maize and divide by the total number of maize farmers who cultivated 
**        maize after applying the vcc1 farmer weight. Overall and by category
svyset hhea [pw=wgt_fish], strata(samp_stratum)
svy, subpop(hhmem_dj): prop anyimp_fish
svy, subpop(hhmem_dj): prop anyimp_fish, over(vcc_youth)
svy, subpop(hhmem_dj): prop anyimp_fish, over(sex)

for each var in varlist imp_* {
  svy, subpop(hhmem_dj): prop `var'
}
	 			
//STEP 7. Keep only the variables that are necessary to calculate the final 
**         overall indicator across all VCCs and save the data.
keep hhea hhnum m1_line imp_* totimp_fish anyimp_fish

save "$indicator\output\FTF ZOI Survey [COUNTRY] [YEAR] agtech_fishpond",replace

di "Date:$S_DATE $S_TIME"
log close


