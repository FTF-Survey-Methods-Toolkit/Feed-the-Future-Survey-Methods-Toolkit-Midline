/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
*************************  HOUSEHOLD ANALYTICAL FILE  **************************
****************************** [COUNTRY] [YEAR]*********************************
********************************************************************************
Description: In this do file, key household-level analytic variables used to 
calculate or disaggregate indicators are defined and their calculation described. 

The file is divided into three sections:
5.1. Household composition
5.2. Household level-disaggregates 
7.1. Household demographics

Syntax prepared by ICF, February 2023
Revised by ICF, September 2023

The numbering of the sections and variables in this syntax file align with 
Chapter 5 and 7 in Feed the Future Midline Statistics.

This syntax file was developed using the Feed the Future phase two ZOI Midline 
main survey core questionnaire. It must be adapted for the final country- 
customized questionnaire. 
*******************************************************************************/
clear all
set more off
set maxvar 30000

//DIRECTORY PATH
*Analysis note: Adjust paths to map to the analyst's computer
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global source    "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Raw"      
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:   $source\FTF ZOI Survey [COUNTRY] [YEAR] household data raw.dta 
//	 		    $analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta
//Log Outputs:	$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] household analytic.log	
//Output data:	$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax household analytic.do 

capture log close
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.log", replace
********************************************************************************
**#HOUSEHOLD COMPOSITION (Guide to Midline Statistics Section 5.1)
********************************************************************************
*Load the persons-level data file created using FTF ZOI Survey [COUNTRY] [YEAR] 
*syntax persons analytic.do 
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear

*5.1. Create variables for the number of de jure HH members, by key sub-population
sort hhea hhnum

*5.1.1.	Number of usual (de jure) HH members in HH
*       Create a variable that counts the number of de jure HH members in each 
*       HH (hhsize_dj) by summing the de jure HH member variable hhmem_dj.
by hhea hhnum: egen hhsize_dj=total(hhmem_dj)
lab var hhsize_dj "Number of de jure HH members"
tab hhsize_dj

*5.1.2.	Number of adults who are de jure HH members in HH, overall and by sex 
*       Create variables that count the total number of adults who are de jure 
*       HH members in each HH (nadult_dj, nadult_mdj, nadult_fdj) by summing the 
*       adult variables (adult, adult_m, adult_f) for de jure HH members (hhmem_dj). 
by hhea hhnum: egen nadult_dj=total(adult) if hhmem_dj==1
by hhea hhnum: egen nadult_mdj=total(adult_m) if hhmem_dj==1
by hhea hhnum: egen nadult_fdj=total(adult_f) if hhmem_dj==1

la var nadult_dj  "Number of adults in HH (de jure only)"
la var nadult_mdj "Number of male adults in HH (de jure only)"
la var nadult_fdj "Number of female adults in HH (de jure only)"

tab1 nadult*

*5.1.3.	Number of women of reproductive age (WRA) who are de jure HH members in HH
*       Create a variable that counts the number of WRA who are de jure HH members 
*       in each HH (nwra_dj) by summing the the WRA variable (wra) for de jure 
*       HH members (hhmem_dj).
by hhea hhnum: egen nwra_dj=total(wra) if hhmem_dj==1
la var nwra_dj "Number of WRA 15-49 years in HH (de jure only)"
tab nwra_dj

*5.1.4.	Number of children under 2 years of age who are de jure HH members in HH
*       Create a variable that counts the number of children under 2 years of age 
*       who are de jure HH members in each HH (ncu2_dj) by summing the the 
*       c0_23m variable for de jure HH members (hhmem_dj).
by hhea hhnum: egen ncu2_dj=total(c0_23m) if hhmem_dj==1
la var ncu2_dj "Number of children <2 years in HH (de jure only)"
tab ncu2_dj

*5.1.5.	Number of children under 5 years of age who are de jure HH members in HH
*       Create a variable that counts the number of children under 5 years of age 
*       who are de jure HH members in each HH (ncu5_dj) by summing the the 
*       c0_59m variable for de jure HH members (hhmem_dj).
by hhea hhnum: egen ncu5_dj=total(c0_59m) if hhmem_dj==1
la var ncu5_dj "Number of children <5 years in HH (de jure only)"
tab ncu5_dj

*5.1.6.	Number of children 5-17 years of age who are de jure HH members in HH
*       Create a variable that counts the number of children 5-17 years of age 
*       who are de jure HH members in each HH (nc5_17y_dj) by summing the the 
*       c5_17y variable for de jure HH members (hhmem_dj).
by hhea hhnum: egen nc5_17y_dj=total(c5_17y) if hhmem_dj==1
la var nc5_17y_dj "Number of children 5-17 years in HH (de jure only)"
tab nc5_17y_dj

*5.1.7.	Number of youth who are de jure household members in household
*       Create a variable that counts the number of youth 15-29 years of age 
*       who are de jure HH members in each HH (nage15_29y_dj) by summing the the 
*       age15_29m variable for de jure HH members (hhmem_dj).
by hhea hhnum: egen nage15_29y_dj=total(age15_29y) if hhmem_dj==1
la var nage15_29y_dj "Number of youth 15-29 years in HH (de jure only)"
tab nage15_29y_dj

*5.1.8.	Number of producers of targeted VCCs who are de jure HH members
*       Create variables that count the total number of targeted VCC producers 
*       who are de jure HH members in each HH (nvcc_dj, nvcc_maize_dj, 
*       nvcc_dairy_dj, nvcc_fish_dj) by summing the vcc variables (vcc, vcc_maize2,
*       vcc_dairy2, vcc_sheep2, vcc_fish2) for de jure HH members (hhmem_dj).   
*INSTRUCTIONS: Update the VCCs to be those included in the survey
by hhea hhnum: egen nvcc_dj=total(vcc) if hhmem_dj==1
by hhea hhnum: egen nvcc_maize_dj=total(vcc_maize2) if hhmem_dj==1
by hhea hhnum: egen nvcc_dairy_dj=total(vcc_dairy2) if hhmem_dj==1
by hhea hhnum: egen nvcc_sheep_dj=total(vcc_sheep2) if hhmem_dj==1
by hhea hhnum: egen nvcc_fish_dj=total(vcc_fish2) if hhmem_dj==1

la var nvcc_dj       "Number of producers of 1+ targeted VCC in HH (de jure only)"
la var nvcc_maize_dj "Number of maize producers in HH (de jure only)"
la var nvcc_dairy_dj "Number of dairy cow producers in HH (de jure only)"
la var nvcc_sheep_dj "Number of sheep producers in HH (de jure only)"
la var nvcc_fish_dj  "Number of fishpond producers in HH (de jure only)"

tab1 nvcc*

*5.1.9. These variables identify households that cultivated or raised specific targeted VCCs included in the ZOI Survey during the 12 months preceding the survey, according to information collected in the targeted VCC modules. The template syntax includes maize, dairy cows, sheep, and fishponds as the targeted VCCs. Be sure to adapt the syntax to reflect the VCCs included in the ZOI Survey being analyzed.

*5.1.9.1. Household member responsible for cultivating maize, past 12 months
gen	hh_maize=0 
replace hh_maize=1 if vcc_maize2>0 & vcc_maize2!=.
lab val hh_maize YESNO
la var "HH cultivated maize, past 12 months"
tab hh_maize

*5.1.9.2. Household member responsible for raising dairy cows, past 12 months
gen	hh_dairy=0 
replace hh_dairy=1 if vcc_dairy2>0 & vcc_dairy2!=.
lab val hh_dairy YESNO
la var "HH raised dairy cows, past 12 months"
tab hh_dairy

*5.1.9.3. Household member responsible for raising sheep, past 12 months
gen	hh_sheep=0 
replace hh_sheep=1 if vcc_sheep2>0 & vcc_sheep2!=.
lab val hh_sheep YESNO
la var "HH raised sheep, past 12 months"
tab hh_sheep

*5.1.9.4. Household member responsible for cultivating fishponds, past 12 months
gen	hh_fish=0 
replace hh_fish=1 if vcc_fish2>0 & vcc_fish2!=.
lab val hh_fish YESNO
la var "Fishpond producer, past 12 months"
tab hh_fish

*5.1.10. Household size category—de jure household members
*        Create a categorical variable for household size (hhsizegrp_dj) based on 
*        de jure HH members.
tab hhsize_dj,m
recode hhsize_dj (1/5=1    "1-5 de jure members")  ///
                 (6/10=2   "6-10 de jure members") ///
			     (11/max=3 "11+ de jure members"), gen (hhsizegrp_dj)
la var hhsizegrp_dj  "Household size, categorical (de jure only)"
tab hhsizegrp_dj

*Sum the number of each HH composition variable created by HH to create HH-level data
*After using the collapse command, there will be one record per HH
collapse (max) hhsize_dj hhsizegrp_dj n* *fdm* *mdm* *pdm* hh_*, by(hhea hhnum)
count

// LABEL VALUES
la val agegrp_fdm_dj agegrp_pdm_dj
la val hhsizegrp_dj hhsizegrp_dj
la val youth_fdm_dj YESNO

// LABEL VARIABLES
la var hhsize_dj     	"Number of de jure HH members"
la var nadult_dj     	"Number of adults in HH (de jure only)"
la var nadult_mdj    	"Number of male adults in HH (de jure only)"
la var nadult_fdj    	"Number of female adults in HH (de jure only)"
la var nwra_dj       	"Number of WRA 15-49 years in HH (de jure only)"
la var ncu2_dj       	"Number of children <2 years in HH (de jure only)"
la var ncu5_dj       	"Number of children <5 years in HH (de jure only)"
la var nc5_17y_dj    	"Number of children 5-17 years in HH (de jure only)"
la var nage15_29y_dj    "Number of youth 15-29 years in HH (de jure only)"
la var nvcc_dj       	"Number of producers of 1+ targeted VCC in HH (de jure only)"
la var nvcc_maize_dj 	"Number of maize producers in HH (de jure only)"
la var nvcc_dairy_dj 	"Number of dairy cow producers in HH (de jure only)"
la var nvcc_sheep_dj 	"Number of sheep producers in HH (de jure only)"
la var nvcc_fish_dj  	"Number of fishpond producers in HH (de jure only)"
la var 					"HH cultivated maize, past 12 months"
la var 					"HH raised dairy cows, past 12 months"
la var					"HH raised sheep, past 12 months"
la var 					"Fishpond producer, past 12 months"
la var hhsizegrp_dj  	"Household size, categorical (de jure only)"
la var mdm 			 	"Primary adult male decision-maker (Male PADM)"
la var fdm 			 	"Primary adult female decision-maker (Female PADM)"
la var pdm 			 	"Primary adult decision-maker (PADM)"
la var mdm_dj 		 	"Male PADM, de jure HH member"
la var fdm_dj 		 	"Female PADM, de jure HH member"
la var agegrp_fdm_dj 	"Age category of female PADM, de jure HH member"
la var youth_fdm_dj  	"Female PADM is 18-29 years (youth), de jure HH member"
la var marstat_fdm_dj 	"Female PADM marital status, de jure HH member"
la var fdm_econ_miss  	"Number of activities female PADM is missing, de jure HH member"
la var fdm_econ_farm    "Female PADM partook in farm work, de jure HH member"
la var fdm_econ_nonfarm "Female PADM partook in non-farm work, de jure HH member"


*1.8 Sort and save the HH-level demographic variables created using the person data file
order hhea hhnum hhsize* n*  
keep  hhea hhnum hhsize* n* *mdm *fdm *dm_dj *nvcc*
sort  hhea hhnum
save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] HH demographics", replace

*1.9 Open the "raw" HH-level data file generated from the CSPro CAPI program export
*    and merge into it the HH demographic variables created from the person-level 
*    data file
clear all
set maxvar 30000
use "$source\FTF ZOI Survey [COUNTRY] [YEAR] household data raw.dta", clear
merge 1:1 hhea hhnum using "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] HH demographics.dta"
*(Check to make sure the results of the merge make sense and then drop the merge variable)
drop _merge

********************************************************************************
**#FINALIZE AND SAVE DATE FILE
********************************************************************************
*Step 1: Keep only HHs that completed the survey
drop if ahresult!=1

*Step 2: Add the shock exposure severity and wealth quintile 
*        disaggregate variables created in other syntax files into the HH file.
merge 1:1 hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.dta", keepusing(awiquint awi)
drop _merge
merge 1:1 hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] resilience.dta", keepusing(shock_sev)
drop _merge

*Step 3: Save household analytic data file
save "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", replace

*Step 4: Add HH-level analytic variables to the person analytic data file and save
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear
merge m:1 hhea hhnum using "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", keepus(ahtype strata genhhtype_dj awiquint shock_sev)

*Step 5: If age is missing for any HH roster entries (i.e., the HH roster entry 
*        is a placeholder for a primary adult decision-maker who does not exist
*        in the HH, set the variables merged into the data file to missing.)
foreach x of varlist ahtype strata genhhtype_dj awiquint shock_sev {
  replace `x'=. if age==.
}
drop _merge
save "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", replace

********************************************************************************
**#HH-LEVEL DISAGGREGATES (Guide to Midline Statistics Section 5.2)
********************************************************************************
*5.2.1. Gendered household type, de jure household members 
*       Create a categorical variable that identifies each HH by the sex of de
*       jure adult HH members living in the HH, or as a HH without de jure adult 
*       HH members (genhhtype_dj).
gen     genhhtype_dj=0
replace genhhtype_dj=1 if (nadult_fdj>0  & nadult_mdj>0) 
replace genhhtype_dj=2 if (nadult_fdj>0  & nadult_mdj==0) 
replace genhhtype_dj=3 if (nadult_fdj==0 & nadult_mdj>0) 
replace genhhtype_dj=4 if (nadult_fdj==0 & nadult_mdj==0)
replace genhhtype_dj=. if nadult_mdj==. & nadult_fdj==. ///
la def genhh 1 "Male and Female adults" 				///
             2 "Female adults only, no male adults"     ///
             3 "Male adults only, no female adults"     ///
			 4 "Children only, no adults", modify
la val genhhtype_dj genhh
la var genhhtype_dj "Gendered HH type, de jure HH members"
tab genhhtype_dj

*5.2.2. Wealth quintile disaggregate
*       The wealth index disaggregate is created in the wealth index AWI do file.

*5.2.3. Shock exposure severity disaggregate
*       The shock exposure severity disaggregate is created in the core resilience 
*	    do file. 

*Save the HH-level data file with the new variables included as the "analytic"
*HH data file
save "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", replace

********************************************************************************
**#Household demographics 
********************************************************************************
*(Guide to Feed the Future Midline Statistics Section 7.1)
/*Sample-weighted indicators:
	7.1.1. Mean household size, de jure
	7.1.2. Mean number of children under 2 years, de jure
	7.1,3. Mean number of children under 5 years, de jure
	7.1.4. Mean number of children 5 or older (5-17 years), de jure
	7.1.5. Mean number of youth (15-29 years), de jure
	7.1.6. Mean number of women of reproductive age (15-49 years), de jure
	7.1.7. Mean number of adult male household members, de jure
	7.1.8. Mean number of adult female household members, de jure
	7.1.9. Mean number of producers of any targeted commodity, de jure
	7.1.10.Household size (%), de jure
*/

*Step 1: Load the household analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear

*Step 2: Apply the household weight
svyset hhea [pw=wgt_hh], strata(strata) 

*Step 3: Tabulate the HH demographic variables.
*NOTE:   The numbering in Step 3 aligns with the Section numbering in the Guide 
*        to Feed the Future Midline Statistics.

*7.1.1: Mean household size, de jure
svy: mean hhsize_dj

*7.1.2: Mean number of children under 2 years, de jure
svy: mean ncu2_dj

*7.1.3: Mean number of children under 5 years, de jure
svy: mean ncu5_dj

*7.1.4: Mean number of children 5 or older (5-17 years), de jure
svy: mean nc5_17y_dj

*7.1.5: Mean number of youth (15-29 years), de jure
svy: mean nage15_29y_dj

*7.1.6: Mean number of women of reproductive age (15-49 years), de jure
svy: mean nwra_dj

*7.1.7: Mean number of adult male household members, de jure
svy: mean nadult_mdj

*7.1.8: Mean number of adult female household members, de jure
svy: mean nadult_fdj

*7.1.9: Mean number of producers of any targeted commodity, de jure
*INSTRUCTIONS: Update VCCs to reflect those included in the survey.
svy: mean nvcc_dj
svy: mean nvcc_maize_dj
svy: mean nvcc_dairy_dj
svy: mean nvcc_sheep_dj
svy: mean nvcc_fish_dj

*7.1.10: Household size category (%), de jure
svy: tab hhsizegrp_dj

*Step 4: Delete the demographics file and close the log file
di "Date:$S_DATE $S_TIME"
erase "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] HH demographics.dta"
log  close