/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
******************  AGRICULTURE PRACTICE INDICATORS: SHEEP *********************
******************************** [Country Year] ********************************
********************************************************************************
Description: This code is intended to calculate the SHEEP component of the 
targeted improved management practices and technologies indicator.

Syntax prepared by ICF, October 2021
Revised by ICF, September 2023

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
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_sheep.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_sheep.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_sheep.do 

cap log close 
log using "$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_sheep.log",replace	
********************************************************************************
/*STEP 1. Review the sheep section of the agriculture module in the country-customized 
ZOI Survey questionnaire and identify questions that relate to improved management 
practices and technologies being promoted in the ZOI. Determine which response 
options would be considered targeted improved management practices and technologies, 
and also determine under which livestock management sub-type or sub-types the 
targeted improved management practices and technologies are being promoted. 

If Feed the Future is promoting a management practice or technology for multiple 
benefits, be sure that producers applying the management practice or technology 
are reported under each type or sub-type for which the technology is 
being promoted. Conversely, if Feed the Future is promoting a management 
practice or technology for a single benefit though it could be promoted for 
multiple benefits, be sure that producers applying the management practice or 
technology are reported under only the one type or sub-type for which 
the practice or technology is being promoted.

For sheep, most targeted improved management practices and technologies will be 
included under one management practice and technology type - livestock management 
- but some may fall under other management practice and technology types 
(e.g., food safety or "other," which is meant to capture improved practices and 
technologies that do not fit under any of the other types). Please see the Feed 
the Future Indicator Handbook or the Feed the Future Guide to Midline Statistics 
for the list of all management practice and technology types, including examples.
*/

*STEP 2. Prepare the data 		

*Step 2.1. Load individual level data file
use 	"$analytic\FTF ZOI Survey [Country] [Year] persons data analytic", clear

*Step 2.2. Review the variable already created and included in the persons-level 
*		data file that flags sheep farmers who completed the livestock module  
*		(vcc_sheep)
tab 	vcc_sheep

*Step 2.3. Drop all farmers from the data who did not raise sheep in the year 
*		preceding the survey and drop variables not required to generate sheep
*		specific variables.
keep if vcc_sheep==1 
keep 	hhea hhnum m1_line strata sex age15_29y vcc_sheep wgt_sheep v752*

*Step 3. Create binary variables for each targeted improved practice or 
*		technology to flag producers who applied the practice or technology to 
*		raise sheep during the 12 months preceding the survey (yes=1, no=0).

*Step 3.1: Create a binary variable to flag sheep producers who bred sheep 
*		with artificial insemination (imp_sheep_artinsem).
gen 	imp_sheep_artinsem=0
replace imp_sheep_artinsem=1 if strpos(v75206, "D")>0
la val 	imp_sheep_artinsem YESNO
la var 	imp_sheep_artinsem "Used artificial insemination for breeding sheep"
tab 	imp_sheep_artinsem

*Step 3.2. Create a binary variable to sheep producers who selectively chose rams 
*		for breeding their sheep (imp_sheep_selectbreed).
gen 	imp_sheep_selectbreed=0
replace imp_sheep_selectbreed=1 if strpos(v75207, "C")>0 | strpos(v75207, "D")>0 | strpos(v75207, "E")>0
la val 	imp_sheep_selectbreed YESNO
la var 	imp_sheep_selectbreed "Selectively chose rams for breeding sheep"
tab 	imp_sheep_selectbreed

*Step 3.3. Create a binary variable to flag sheep producers who used trained health 
*       service providers for their sheep (imp_sheep_healthserv).
gen 	imp_sheep_healthserv=0
replace imp_sheep_healthserv=1 if v75225==1 
la val 	imp_sheep_healthserv YESNO
la var 	imp_sheep_healthserv "Obtained health services for sheep from trained provider"
tab 	imp_sheep_healthserv

*Step 3.4. Create a binary variable to flag sheep producers who vaccinated some or 
*		all of their sheep (imp_sheep_vaccinated).
gen 	imp_sheep_vaccinated=0
replace imp_sheep_vaccinated=1 if v75230==2 | v75230==3 
la val 	imp_sheep_vaccinated YESNO
la var 	imp_sheep_vaccinated "Vaccinated some or all sheep"
tab 	imp_sheep_vaccinated

*Step 3.5. Create a binary variable to flag sheep producers who used housing with a 
*		roof for their sheep (imp_sheep_roof).
gen 	imp_sheep_roof=0
replace imp_sheep_roof=1 if v75210==5 | v75210==6 | v75210==7 
la val 	imp_sheep_roof YESNO
la var 	imp_sheep_roof "Used housing with a roof for sheep"
tab 	imp_sheep_roof

*Step 3.6. Create a binary variable to flag sheep producers who fed sheep vitamins 
*		or minerals to their sheep (imp_sheep_fedvitmin).
gen 	imp_sheep_fedvitmin=0
replace imp_sheep_fedvitmin=1 if v75222==1 
la val 	imp_sheep_fedvitmin YESNO
la var 	imp_sheep_fedvitmin "Fed sheep vitamins or minerals in the past one year"
tab 	imp_sheep_fedvitmin

*Step 3.7. Create a binary variable to flag sheep producers who piped drinking 
*		water to sheep (imp_sheep_pipedwater).
gen 	imp_sheep_pipedwater=0
replace imp_sheep_pipedwater=1 if v75211==4 
la val 	imp_sheep_pipedwater YESNO
la var 	imp_sheep_pipedwater "Piped drinking water to sheep"
tab 	imp_sheep_pipedwater

*Step 3.8. Create a binary variable to sheep producers who improved the pasture 
*		quality where their sheep graze (imp_sheep_pasture).
gen 	imp_sheep_pasture=0
replace imp_sheep_pasture=1 if v75212b==1
la val 	imp_sheep_pasture YESNO
la var 	imp_sheep_pasture "Improved pasture quality for sheep grazing"
tab 	imp_sheep_pasture

*Step 3.9. Create a binary variable to sheep producers who fed sheep improved 
*		fodder crops or wheat bran forages (imp_sheep_fodder).
gen 	imp_sheep_fodder=0
replace imp_sheep_fodder=1 if v75215==1 | strpos(v75213, "B")>0 
la val 	imp_sheep_fodder YESNO
la var 	imp_sheep_fodder "Fed crop fodder or wheat bran forages to sheep"
tab 	imp_sheep_fodder

*Step 3.10. Create a binary variable to sheep producers who sold their sheep's milk 
*		(imp_sheep_soldmilk).
gen 	imp_sheep_soldmilk=0
replace imp_sheep_soldmilk=1 if v75238==1 
la val 	imp_sheep_soldmilk YESNO
la var 	imp_sheep_soldmilk "Sold sheep's milk"
tab 	imp_sheep_soldmilk

*Step 3.11. Create a binary variable to sheep producers who sold their sheep's 
*		manure (imp_sheep_soldmanure).
gen 	imp_sheep_soldmanure-0
replace imp_sheep_soldmanure=1 if v75224==05 | v75224==06 
la val 	imp_sheep_soldmanure YESNO
la var 	imp_sheep_soldmanure "Sold sheep's manure to friends or neighbors or at market"
tab 	imp_sheep_soldmanure

*Step 3.12. Create a binary variable to sheep producers who pasteurized their 
*		sheep's milk (imp_sheep_pasteurized).
gen 	imp_sheep_pasteurized=0
replace imp_sheep_pasteurized=1 if strpos(v75240, "B")>0
la val 	imp_sheep_pasteurized YESNO
la var 	imp_sheep_pasteurized "Pasteurized sheep's milk"
tab 	imp_sheep_pasteurized

*Step 3.13. Create a binary variable to flag sheep producers who kept written 
*		records on their sheep (imp_sheep_records).
gen 	imp_sheep_records=0
replace imp_sheep_records=1 if v75241==1
la val 	imp_sheep_records YESNO
la var 	imp_sheep_records "Kept written records on sheep"
tab 	imp_sheep_records

*STEP 4. Create binary variables for each management practice and technology 
*		practice category to flag producers who applied any targeted improved 
*		practice or technology targeted by Feed the Future under the relevant 
*		category to raise sheep (yes=1, no=0). Almost all improved management 
*		practices and technologies for raising sheep are categorized under a 
*		single practice and technology type: livestock management. 

*Step 4.1. Create a binary variable to indicate whether each sheep producer 
*		applied any targeted improved practices or technologies promoted 
*		under livestock management (imp_sheep_livestm). 
gen 	imp_sheep_livestm=0
replace imp_sheep_livestm=1 if imp_sheep_artinsem==1 | imp_sheep_selectbreed==1 | ///
		imp_sheep_healthserv==1 | imp_sheep_vaccinated==1 | imp_sheep_roof==1 | ///
		imp_sheep_fedvitmin==1 | imp_sheep_pipedwater==1 | imp_sheep_pasture==1 | ///
		imp_sheep_fodder==1 
la val 	imp_sheep_livestm YESNO 
la var 	imp_sheep_livestm "Used improved livestock management"
tab 	imp_sheep_livestm

*Step 4.2. Create a binary variable to flag sheep producers who applied a targeted 
*		improved management practice or technology related to marketing and 
*		distribution (imp_sheep_markdist).
gen 	imp_sheep_markdist=0
replace imp_sheep_markdist=1 if (imp_sheep_soldmilk==1 | imp_sheep_soldmanure==1)
la val 	imp_sheep_markdist YESNO 
la var 	imp_sheep_markdist "Used improved marketing and distribution"
tab 	imp_sheep_markdist

*Step 4.3. Create a binary variable to flag sheep producers who applied a 
*		targeted improved management practice or technology related to value 
*		added processing (imp_sheep_valadd).
gen 	imp_sheep_valadd=0
replace imp_sheep_valadd=1 if (imp_sheep_pasteurized==1)
la val 	imp_sheep_valadd YESNO 
la var 	imp_sheep_valadd "Used improved value-added processing"
tab 	imp_sheep_valadd

*Step 4.4. Create a binary variable to flag sheep producers who used a targeted 
*		improved management practice or technology related to food safety 
*		(imp_sheep_fsafety).
gen 	imp_sheep_fsafety=0
replace imp_sheep_fsafety=1 if imp_sheep_pasteurized==1
la val 	imp_sheep_fsafety YESNO
la var 	imp_sheep_fsafety "Used improved food safety practices"
tab 	imp_sheep_fsafety

*Step 4.5. Create a binary variable to flag sheep producers who used a targeted 
*		improved management practice or technology not captured in any other 
*		category (imp_sheep_other).
gen 	imp_sheep_other=0
replace imp_sheep_other=1 if imp_sheep_records==1
la val 	imp_sheep_other YESNO
la var 	imp_sheep_other "Used other improved practice or technology"
tab 	imp_sheep_other

*STEP 5. Create a variable list (IMP_sheep) that includes all applicable improved 
*		management practice and technology practices for sheep. Adapt this step as 
*		needed to reflect different livestock value chains and improved management 
*		practices and technologies promoted in the ZOI country context. 
global IMP_sheep imp_sheep_artinsem imp_sheep_selectbreed imp_sheep_healthserv imp_sheep_vaccinated imp_sheep_roof imp_sheep_fedvitmin imp_sheep_pipedwater imp_sheep_pasture imp_sheep_fodder imp_sheep_pasteurized imp_sheep_soldmilk imp_sheep_soldmanure imp_sheep_records

*STEP 6. Create a count variable to capture the total number of targeted improved 
*		management practices or technologies each producer used to raise sheep 
*		(imp_tot_sheep). That is, create a variable that sums all the variables in 
*		the (IMP_sheep) variable list created in Step 6.
egen 	imp_tot_sheep = rowtotal ($IMP_sheep)
la var 	imp_tot_sheep "Number of target improved practices and technologies applied (sheep)"
tab  	imp_tot_sheep

*STEP 7. Create a categorical variable to categorize sheep producers by the number 
*		of targeted improved practices or technologies they used (imp_cat_sheep) 
*		for Table 7.4.4 adapted for sheep. The categories used should be adapted 
*		based on the survey data; they do not have to be 0, 1-3, 4-6, 7-9, and 10 
*		or more targeted improved practices or technologies.
gen 	imp_cat_sheep=.
replace imp_cat_sheep=0 if (imp_tot_sheep==0)
replace imp_cat_sheep=1 if (imp_tot_sheep>=1 & imp_tot_sheep<=3)
replace imp_cat_sheep=2 if (imp_tot_sheep>=4 & imp_tot_sheep<=6)
replace imp_cat_sheep=3 if (imp_tot_sheep>=7 & imp_tot_sheep<=9)
replace imp_cat_sheep=4 if (imp_tot_sheep>=10 & imp_tot_sheep!=.)
la define cat_vcc 0 "None" 1 "1-3 practices" 2 "4-6 practices" 3 "7-9 practices" ///
		4 "10+ practices"
la val 	imp_cat_sheep cat_vcc
la var 	imp_cat_sheep "Number of targeted improved practices and technologies used (sheep, categorical)"
tab 	imp_cat_sheep

*STEP 8. Create a binary variable to indicate whether each sheep producer applied 
*		any targeted improved management practices or technologies to raise sheep *	
*		(imp_any_sheep).
gen 	imp_any_sheep=0
replace imp_any_sheep=1 if (imp_tot_sheep>0 & imp_tot_sheep!=.)
la val 	imp_any_sheep YESNO
la var 	imp_any_sheep "Used any targeted management practice or technology (sheep)"
tab 	imp_any_sheep

*STEP 9. After applying the sheep producer sampling weight, calculate the 
*		percentage of sheep producers who are de jure household members who applied 
*		at least one targeted improved management practice or technology to raise 
*		sheep during the year preceding the survey using imp_any_sheep. Repeat 
*		using producers' age (under 30 years of age, 30 years of age or older) and 
*		sex as disaggregates. 
*		Also calculate the percentage of maize producers who are de jure household 
*		members who used each targeted improved management practice or technology, 
*		and the percentage of maize producers who are de jure household members who 
*		used each management practice and technology type and livestock management 
*		sub-type. 
svyset 	hhea [pw=wgt_sheep], strata(strata)
svy, 	subpop(hhmem_dj): tab imp_any_sheep
svy, 	subpop(hhmem_dj): tab imp_any_sheep age15_29y, col
svy, 	subpop(hhmem_dj): tab imp_any_sheep sex, col

foreach var of varlist imp_sheep_* {
		svy, subpop(hhmem_dj): tab `var'
} 

*STEP 10. Calculate the percentage distribution of sheep producers who are de jure 
*		household members by the number of targeted improved management practices 
*		or technologies they used to cultivate sheep during the 12 months preceding 
*		the survey using imp_cat_sheep. Repeat using producers' age (under 30 years 
*		of age, 30 years of age or older) and sex as disaggregates. 
svy, subpop(hhmem_dj): tab imp_cat_sheep
svy, subpop(hhmem_dj): tab imp_cat_sheep age15_29y, col
svy, subpop(hhmem_dj): tab imp_cat_sheep sex, col

*STEP 11. Keep only the variables that are necessary to calculate the final overall 
*		indicator across all VCCs and save the data.
keep 	hhea hhnum m1_line strata sex age15_29y  hhmem_dj wgt_sheep vcc_sheep ///
		imp_tot_sheep imp_any_sheep imp_sheep_*
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_sheep.dta", replace

di "Date:$S_DATE $S_TIME"
log close
