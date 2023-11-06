/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
*************** AGRICULTURE TECH INDICATORS: FISHPOND AQUACULTURE **************
******************************* [COUNTRY] [YEAR] *******************************
********************************************************************************
Description: This code is intended to calculate the FISHPOND AQUACULTURE 
component of the targeted improved management practices and technologies indicator.
			 
Syntax prepared by ICF, August 2018
Revised by ICF July 2019, August 2023

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. It must be adapted for the final country-specific questionnaire. 
The syntax was not tested using ZOI Survey data; therefore, double-check all 
syntax and results carefully and troubleshoot to resolve any issues identified. 
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
and technologies being promoted in the ZOI. Determine which response options would 
be considered targeted improved management practices and technologies, and also 
determine under which management practice and technology categories the targeted 
improved management practices and technologies are being promoted under – most 
will fall under improved aquaculture management. 

If Feed the Future is promoting a practice or technology for multiple benefits, 
the fishpond producers applying the technology should be reported under each 
category for which the practice or technology is being promoted. If the practice 
is being promoted for only one purpose, the fishpond producer should be reported 
under only the relevant category. If Feed the Future is promoting a practice or 
technology for a single benefit even though it could be promoted for multiple 
benefits, be sure that producers applying the practice or technology are reported 
under only the one category for which the practice or technology is being promoted. 

For fishpond aquaculture, most targeted improved management practices and 
technologies will be included under one management practice and technology 
category—aquaculture management, but some may fall under other management 
practice and technology categories (e.g., the "other" category, which is meant 
to capture improved practices and technologies that do not fit under any of the 
other category). Please see the Feed the Future Indicator Handbook or the Feed 
the Future Guide to Midline Statistics for the list of all management practice
 and technology types, including examples.
*/

*STEP 2. Prepare the data 		

*Load individual level data file
use "$analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta", clear

*Review the variables already created and included in the persons-level data 
*		file that flags fishpond farmers who completed the fish module (vcc_fish). 
*		(See Section 4.6.3 of the Guide to FTF Midline Statistics)     
tab 	vcc_fish

*Drop all producers from the data who did not cultivate fish in the year 
*		preceding the survey, and drop variables not required to generate 
*		fishponds specific variables.
keep if vcc_fish==1 
keep 	hhea hhnum m1_line strata sex age15_29y hhmem_dj wgt_fish vcc_fish v780* 

*STEP 3. Create binary variables for each targeted improved practice and 
*		technology practice to flag producers who applied the practice or 
*		technology to raise fish in ponds during the 12 months preceding the survey 
*		(yes =1; no =0). 

*Step 3.1. Create a binary variable to flag producers who drained their fishponds 
*		at least once (imp_fish_ponddrain).
gen 	imp_fish_ponddrain=0
replace imp_fish_ponddrain=1 if v78014>0 & v78014!=.
la val 	imp_fish_ponddrain YESNO
la var 	imp_fish_ponddrain "Drained fishponds 1+ times"
tab 	imp_fish_ponddrain

*Step 3.2. Create a binary variable to flag fishpond producers who added manure to 
*		their fishponds (imp_fish_pondmanure).
gen 	imp_fish_pondmanure=0
replace imp_fish_pondmanure=1 if v78017==1
la val 	imp_fish_pondmanure YESNO
la var 	imp_fish_pondmanure "Added manure to fishponds"
tab 	imp_fish_pondmanure

*Step 3.3. Create a binary variable to flag producers who obtained their fish 
*		from a registered/certified hatchery (imp_fish_certhatch).
gen 	imp_fish_certhatch=0
replace imp_fish_certhatch=1 if v78002c==1
la val 	imp_fish_certhatch YESNO
la var 	imp_fish_certhatch "Obtained fish from a registered/certified hatchery"
tab 	imp_fish_certhatch

*Step 3.4. Create a binary variable to flag producers who raised carp, tilapia, 
*		or catfish (imp_fish_species).
gen 	imp_fish_species=0
replace imp_fish_species=1 if strpos(v78009,"A")>0 | strpos(v78009,"B")>0 | ///
		strpos(v78009,"C")>0
la val 	imp_fish_species YESNO
la var 	imp_fish_species "Raised carp, tilapia, or catfish"
tab 	imp_fish_species

*Step 3.5. Create a binary variable to flag producers who fed their fish 
*		supplemental food to promote faster growth (imp_fish_fedsupp).
gen 	imp_fish_fedsupp=0
replace imp_fish_fedsupp=1 if v78004==1
la val 	imp_fish_fedsupp YESNO
la var 	imp_fish_fedsupp "Fed fish supplemental food"
tab 	imp_fish_fedsupp

*Step 3.6. Create a binary variable to flag fishpond producers who controlled 
*		disease or parasites with salt or formalin (imp_fish_diseasecontrol).
gen		imp_fish_diseasecontrol=0
replace imp_fish_diseasecontrol=1 if strpos(v78010b,"A")>0 | ///
		strpos(v78010b,"B")>0 |strpos(v78011b,"B")>0 | strpos(v78011b,"C")>0
la val 	imp_fish_diseasecontrol YESNO
la var 	imp_fish_diseasecontrol "Controlled disease or parasites with salt or formalin"
tab 	imp_fish_diseasecontrol
 
*Step 3.7. Create a binary variable to flag producers who monitored water 
*		quality in their fishponds (imp_fish_pondmonqual).
gen 	imp_fish_pondmonqual=0
replace imp_fish_pondmonqual=1 if v78012==1
la val 	imp_fish_pondmonqual YESNO
la var 	imp_fish_pondmonqual "Monitored pond water quality"
tab 	imp_fish_pondmonqual

*Step 3.8. Create a binary variable to flag producers who took steps to maintain 
*		good water quality in their fishponds (imp_fish_pondmainqual).
gen 	imp_fish_pondmainqual=0
replace imp_fish_pondmainqual=1 if v78013==1
la val 	imp_fish_pondmainqual YESNO
la var 	imp_fish_pondmainqual "Took steps to maintain good pond water quality"
tab 	imp_fish_pondmainqual

*Step 3.9. Create a binary variable to flag fishpond producers who improved their 
*		fish produced using sex or age separation (imp_fish_separate).
gen 	imp_fish_separate=0
replace imp_fish_separate=1 if v78016a==1 | v78016b==1
la val 	imp_fish_separate YESNO
la var 	imp_fish_separate "Improved fish produced using sex or age separation"
tab 	imp_fish_separate

*Step 3.10. Create a binary variable to flag producers who harvested their fish 
*		using partial harvests (imp_fish_partharv).
gen 	imp_fish_partharv=0
replace imp_fish_partharv=1 if v78018a==2 
la val 	imp_fish_partharv YESNO
la var 	imp_fish_partharv "Harvested fish using partial harvests"
tab 	imp_fish_partharv

*Step 3.11. Create a binary variable to flag fishpond producers who kept regular 
*		records on their fish  (imp_fish_records).
gen 	imp_fish_records=0
replace imp_fish_records=1 if v78024==1
la val 	imp_fish_records YESNO
la var 	imp_fish_records "Kept regular records on fish"
tab 	imp_fish_records

*Step 3.12. Create a binary variable to flag producers who used or sold fish 
*		guts, skin, or scales after harvest (imp_fish_useguts).
gen 	imp_fish_useguts=0
replace imp_fish_useguts=1 if strpos(v78023a,"A")>0 | strpos(v78023a,"B")>0 | ///
		strpos(v78023b,"A")>0 | strpos(v78023b,"B")>0 | strpos(v78023b,"C")>0
la val 	imp_fish_useguts YESNO
la var 	imp_fish_useguts "Used or sold fish guts, skin, or scales after harvest"
tab 	imp_fish_useguts

*Step 4. Create binary variables for each management practice and technology 
*		practice category to flag producers who applied any targeted improved 
*		practice or technology targeted by Feed the Future under the relevant 
*		category to cultivate fishponds (yes=1, no=0). Almost all improved 
*		aquaculture practices and technologies are categorized under a single 
*		management practice and technology category: aquaculture management

*Step 4.1: Create a binary variable to flag fishpond producers who applied a targeted 
*		improved management practice or technology related to aquaculture management 
*		(imp_fish_aquam).
gen 	imp_fish_aquam=0
replace imp_fish_aquam=1 if (imp_fish_ponddrain==1 | imp_fish_pondmanure==1 | ///
		imp_fish_certhatch==1 | imp_fish_species==1 | imp_fish_fedsupp==1 | ///
		imp_fish_diseasecontrol==1 | imp_fish_pondmonqual==1 | ///
		imp_fish_pondmainqual==1 | imp_fish_separate==1 | imp_fish_partharv==1)
la val 	imp_fish_aquam YES
la var 	imp_fish_aquam "Applied improved aquaculture management practices to raise fish"
tab 	imp_fish_aquam

*Step 4.2: Create a binary variable to flag fishpond producers who applied a targeted 
*		improved management practice or technology that is not captured under 
*		another management practice and technology type (imp_fish_other).
gen 	imp_fish_other=0
replace imp_fish_other=1 if imp_fish_records==1 | imp_fish_useguts==1
la val 	imp_fish_other YESNO
la var 	imp_fish_other "Applied other improved practices or technologies to raise fish"	
tab 	imp_fish_other  

*STEP 5: Create a variable list (IMP_fish) that includes all applicable improved 
*		management practice and technology practices for fishponds. Adapt this 
*		step as needed to reflect different fishpond value chains and improved 
*		management practices and technologies promoted in the ZOI country context. 
global IMP_fish imp_fish_ponddrain imp_fish_pondmanure imp_fish_certhatch imp_fish_species imp_fish_fedsupp imp_fish_diseasecontrol imp_fish_pondmonqual imp_fish_pondmainqual imp_fish_seperate imp_fish_partharv imp_fish_records imp_fish_useguts

*STEP 6: Create a count variable to capture total number of targeted improved 
*		management practice or technology types practiced to raise fishponds 		
*		(imp_tot_fish).
egen 	imp_tot_fish = rowtotal ($IMP_fish)
la var 	imp_tot_fish "Number of targeted improved practices and technologies applied (fishponds)"
tab 	imp_tot_fish

*STEP 7. Create a categorical variable to categorize fishpond producers by the 
*		number of targeted improved practices or technologies they applied 
*		(imp_cat_fish) for Table 7.3.4. The categories used should be adapted based 
*		on the survey data; they do not have to be 0, 1-3, 4-6, 7-9, and 10 or more 
*		targeted improved practices or technologies.
gen 	imp_cat_fish=.
replace imp_cat_fish=0 if (imp_tot_fish==0)
replace imp_cat_fish=1 if (imp_tot_fish>=1 & imp_tot_fish<=3)
replace imp_cat_fish=2 if (imp_tot_fish>=4 & imp_tot_fish<=6)
replace imp_cat_fish=3 if (imp_tot_fish>=7 & imp_tot_fish<=9)
replace imp_cat_fish=4 if (imp_tot_fish>=10 & imp_tot_fish!=.)
la define cat_vcc 0 "None" 1 "1-3 practices" 2 "4-6 practices" 3 "7-9 practices" ///
		4 "10+ practices"
la val 	imp_cat_fish cat_vcc
la var 	imp_cat_fish "Number of targeted improved practices and technologies applied (fish, categorical)"
tab 	imp_cat_fish

*STEP 8: Create a binary variable to indicate if each fishpond producer applied any 
*		targeted improved management practices or technologies to raise fish in 
*		fishponds (imp_any_fish).
gen 	imp_any_fish=0
replace imp_any_fish=1 if imp_tot_fish>0 & imp_tot_fish!=.
la var 	imp_any_fish "Applied any targeted improved practice or technology (fishponds)"
la val 	imp_any_fish applied
tab 	imp_any_fish

*STEP 9. Calculate the percentage of fishpond producers who are de jure HH members 
*		who applied at least one targeted improved management practice or 
*		technology to raise fish in ponds during the 12 months preceding the survey 
*		using imp_any_fish. Repeat using producers' age (15-29, 30+ years) and sex 
*		as disaggregates. 
*		Also calculate the percentage of fishpond producers who are de jure HH 
*		members who applied each targeted improved management practice or technology, 
*		and the percentage of fishpond producers who are de jure HH members who 
*		applied each management practice and technology type andaquaculture management 
*		sub-type.
svyset 	hhea [pw=wgt_fish], strata(strata)
svy, 	subpop(hhmem_dj): tab imp_any_fish
svy, 	subpop(hhmem_dj): tab imp_any_fish age15_29y, col 
svy, 	subpop(hhmem_dj): tab imp_any_fish sex, col 

foreach var in varlist imp_fish_* {
		svy, subpop(hhmem_dj): tab `var'
}

*STEP 10. Calculate the percent distribution of fishpond producers who are de jure 
*		household members by the number of targeted improved management practices 
*		or technologies they applied to raise fish in ponds during the 12 months 
*		preceding the survey using imp_cat_fish. Repeat using producers' age (under 
*		30 years of age, 30 years of age or older) and sex as disaggregates. 
svy, subpop(hhmem_dj): tab imp_cat_fish
svy, subpop(hhmem_dj): tab imp_cat_fish age15_29y, col
svy, subpop(hhmem_dj): tab imp_cat_fish sex, col


*STEP 11. Keep only the variables that are necessary to calculate the final 
*		overall indicator across all VCCs and save the data.
keep 	hhea hhnum m1_line wgt_fish strata vcc_fish age15_29y sex imp_tot_fish ///
		imp_any_fish imp_fish_*
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_fishpond.dta",replace
