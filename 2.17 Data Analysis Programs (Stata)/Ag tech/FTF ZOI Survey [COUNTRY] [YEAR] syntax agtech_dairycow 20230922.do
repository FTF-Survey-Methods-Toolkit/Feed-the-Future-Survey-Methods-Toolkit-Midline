/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
*******************  AGRICULTURE TECH INDICATORS: DAIRY COW ********************
********************************* [COUNTRY-YEAR] *******************************
********************************************************************************
Description: This code is intended to calculate the DAIRY COW component of the 
targeted improved management practices and technologies indicator.

Syntax prepared by ICF, August 2019
Revised by ICF, September 2023

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
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_dairycow.do 

cap log close 
log using "$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.log",replace	
********************************************************************************
/*STEP 1. Review the dairy cow section of the agriculture module in the country-customized 
ZOI Survey questionnaire and identify questions that relate to improved management 
practices and technologies being promoted in the ZOI. Determine which response 
options would be considered targeted improved management practices and technologies, 
and also determine under which management practice and technology categories the 
targeted improved management practices and technologies are being promoted. 

If Feed the Future is promoting a practice or technology for multiple benefits, 
the dairy producers applying the technology should be reported under each category 
for which the practice or technology is being promoted. If the practice is being 
promoted for only one purpose, the dairy producer should be reported under only 
the relevant category. If Feed the Future is promoting a practice or technology 
for a single benefit even though it could be promoted for multiple benefits, be 
sure that producers applying the practice or technology are reported under only 
the one category for which the practice or technology is being promoted. 

For dairy cows, most targeted improved management practices and technologies will 
be included under one management practice and technology type category—livestock 
management, but some may fall under other management practice and technology type 
categories (e.g., food safety or "other," which is meant to capture improved 
practices and technologies that do not fit under any of the other categories). 
Please see the Feed the Future Indicator Handbook or the Feed the Future Guide to 
Midline Statistics for the list of all management practice and technology type 
categories, including examples.
*/

*STEP 2. Prepare the data 		

*Load individual level data file
use "$analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta", clear

*Review the variable already created and included in the persons-level 
*		data file that flags dairy cow farmers who completed the livestock module  
*		(vcc_dairy)
tab 	vcc_dairy

*Drop all farmers from the data who did not raise dairy cows in the year 
*		preceding the survey and drop variables not required to generate dairy
*		specific variables.
keep if vcc_dairy==1 
keep 	hhea hhnum m1_line strata sex age15_29y hhmem_dj wgt_dairy vcc_dairy v750*

*STEP 3. Create 16 binary variables—one for each targeted improved practice or
*		technology to flag producers who applied the practice or technology 
*		to raise dairy cows during the 12 months preceding the survey (yes=1, no=0).

*Step 3.1. Create a binary variable to flag dairy cow producers who bred dairy 
*		cows with artificial insemination (imp_dairy_artinsem)
gen 	imp_dairy_artinsem=0
replace imp_dairy_artinsem=1 if strpos(v75008, "B")>0
la val 	imp_dairy_artinsem YESNO
la var 	imp_dairy_artinsem "Used artificial insemination to breed dairy cows"
tab 	imp_dairy_artinsem

*Step 3.2. Create a binary variable to flag dairy cow producers who selectively
*		chose bulls for breeding—that is chose bull because he had good body 
*		size or composition, was the son of a high-producing cow, or was known 
*		to have good fertility (imp_dairy_selectbreed).
gen 	imp_dairy_selectbreed=0
replace imp_dairy_selectbreed=1 if (v75011==3 | v75011==4 | v75011==5)
la val 	imp_dairy_selectbreed YESNO
la var 	imp_dairy_selectbreed "Selectively chose bulls for breeding dairy cows"
tab 	imp_dairy_selectbreed

*Step 3.3. Create a binary variable to flag dairy cow producers who used 
*		trained health service providers for their dairy cows 
*		(imp_dairy_healthserv).
gen 	imp_dairy_healthserv=0
replace imp_dairy_healthserv=1 if (v75028==1)
la val 	imp_dairy_healthserv YESNO
la var 	imp_dairy_healthserv "Obtained health services for dairy cows from a trained provider"
tab 	imp_dairy_healthserv

*Step 3.4. Create a binary variable to flag dairy cow producers who gave dairy 
*		cows medicine (imp_dairy_medicine).
gen 	imp_dairy_medicine=0
replace imp_dairy_medicine=1 if (v75030==1)
la val 	imp_dairy_medicine YESNO
la var 	imp_dairy_medicine "Gave dairy cows medicine"
tab 	imp_dairy_medicine

*Step 3.5. Create a binary variable to flag dairy cow producers who vaccinated 
*		some or all cattle (imp_dairy_vaccinated).
gen 	imp_dairy_vaccinated=0
replace imp_dairy_vaccinated=1 if (v75033==2 | v75033==3 )
la val 	imp_dairy_vaccinated YESNO
la var 	imp_dairy_vaccinated "Vaccinated some or all cattle"
tab 	imp_dairy_vaccinated

*Step 3.6. Create a binary variable to flag dairy cow producers who prevented
*		mastitis using udder wash, teat dip, somatic cell counts 
*		(imp_dairy_prevmast).
gen 	imp_dairy_prevmast=0
replace imp_dairy_prevmast=1 if strpos(v75034b, "A")>0 | strpos(v75034b, "B")>0 | ///
		strpos(v75034b, "C")>0
la val 	imp_dairy_prevmast YESNO
la var 	imp_dairy_prevmast "Prevented mastitis in dairy cows (udder wash, teat dip, somatic cell counts)"
tab 	imp_dairy_prevmast

*Step 3.7. Create a binary variable to flag dairy cow producers who used
*		housing with a roof for dairy cows (imp_dairy_roof).
gen 	imp_dairy_roof=0
replace imp_dairy_roof=1 if v75016==4 | v75016==5 | v75016==6 
la val 	imp_dairy_roof YESNO
la var 	imp_dairy_roof "Used housing with a roof for dairy cows"
tab 	imp_dairy_roof

*Step 3.8. Create a binary variable to flag dairy cow producers who fed dairy
*		cows crop by-products daily/weekly (imp_dairy_fedbyprod).
gen 	imp_dairy_fedbyprod=0
replace imp_dairy_fedbyprod=1 if v75021a==1 | v75021a==2
la val 	imp_dairy_fedbyprod YESNO
la var 	imp_dairy_fedbyprod "Fed dairy cows crop by-products daily or weekly"
tab 	imp_dairy_fedbyprod

*Step 3.9. Create a binary variable to flag dairy cow producers who fed dairy 
*		cows mixed concentrates daily/weekly (imp_dairy_fedconcentrate).
gen 	imp_dairy_fedconcentrate=0
replace imp_dairy_fedconcentrate=1 if v75024a==1 | v75024a==2
la val 	imp_dairy_fedconcentrate YESNO
la var 	imp_dairy_fedconcentrate "Fed dairy cows mixed concentrates daily or weekly"
tab 	imp_dairy_fedconcentrate

*Step 3.10. Create a binary variable to flag dairy cow producers who fed
*		dairy cows vitamins or minerals daily/weekly (imp_dairy_fedvitmin).
gen 	imp_dairy_fedvitmin=0
replace imp_dairy_fedvitmin=1 if (v75026a==1 | v75026a==2)
la val 	imp_dairy_fedvitmin YESNO
la var 	imp_dairy_fedvitmin "Fed dairy cows vitamins or minerals daily or weekly"
tab 	imp_dairy_fedvitmin

*Step 3.11. Create a binary variable to flag dairy cow producers who
*		collected dairy cows' manure and put in a designated covered area, 
*		pit or lagoon, tank, or biogas-producing digester (imp_dairy_collmanure).
gen 	imp_dairy_collmanure=0
replace imp_dairy_collmanure=1 if (v75027b==2 | v75027b==3 | v75027b==4 | v75027b==5)
la val 	imp_dairy_collmanure YESNO
la var 	imp_dairy_collmanure "Collected dairy cows' manure and put in a designated covered area"
tab 	imp_dairy_collmanure

*Step 3.12. Create a binary variable to flag dairy cow producers who fed 
*		dairy cows improved fodder crops—that is conserved rice straw; 
*		conserved maize stover; legume haulms or stovers; forage legumes; 
*		napier, guinea, or fresh cut grass; or tree fodder (imp_dairy_fedfodder).
gen 	imp_dairy_fedfodder=0
replace imp_dairy_fedfodder=1 if strpos(v75019, "B")>0 | strpos(v75019, "C")>0 | ///
		strpos(v75019, "D")>0 | strpos(v75019, "E")>0 | strpos(v75019, "F")>0 | ///
		strpos(v75019, "G")>0 | strpos(v75019, "H")>0 | strpos(v75019, "I")>0 |
la val 	imp_dairy_fedfodder YESNO
la var 	imp_dairy_fedfodder "Fed dairy cows improved fodder"
tab 	imp_dairy_fedfodder

*Step 3.13. Create a binary variable to flag dairy cow producers who 
*		pasteurized dairy cow's milk (imp_dairy_pasteurized).
gen 	imp_dairy_pasteurized=0
replace imp_dairy_pasteurized=1 if strpos(v75035a, "B")>0 
la val 	imp_dairy_pasteurized YESNO
la var 	imp_dairy_pasteurized "Pasteurized milk from dairy cows"
tab 	imp_dairy_pasteurized

*Step 3.14. Create a binary variable to flag dairy cow producers who sold 
*        dairy cows' milk (imp_dairy_soldmilk).
gen 	imp_dairy_soldmilk=0
replace imp_dairy_soldmilk=1 if (v75036==1)
la val 	imp_dairy_soldmilk YESNO
la var 	imp_dairy_soldmilk "Sold milk from dairy cows"
tab 	imp_dairy_soldmilk

*Step 3.15. Create a binary variable to flag dairy cow producers who sold dairy 
*		cows' manure to their friends or neighbors or at a market 
*		(imp_dairy_soldmanure).
gen 	imp_dairy_soldmanure=0
replace imp_dairy_soldmanure=1 if (v75027c==05 | v75027c==06)
la val 	imp_dairy_soldmanure YESNO
la var 	imp_dairy_soldmanure "Sold dairy cows' manure"
tab 	imp_dairy_soldmanure

*Step 3.16. Create a binary variable to flag dairy cow producers who kept 
*		written records on dairy cows (imp_dairy_records).
gen 	imp_dairy_records=0
replace imp_dairy_records=1 if (v75045==1)
la val 	imp_dairy_records YESNO
la var 	imp_dairy_records "Kept written records on dairy cows"
tab 	imp_dairy_records

*STEP 4. Create binary variables for each management practice and technology 
*		practice category to flag producers who applied any targeted improved 
*		practice or technology targeted by Feed the Future under the relevant 
*		category to raise dairy cows (yes=1, no=0). Almost all improved 
*		management practices and technologies for raising dairy cows are 
*		categorized under a single management practice and technology type 
*		category: livestock management

*Step 4.1. Create a binary variable to flag dairy cow producers who applied a targeted 
*		improved management practice or technology related to  livestock management  
*		(imp_dairy_livestm).
gen 	imp_dairy_livestm=0
replace imp_dairy_livestm=1 if (imp_dairy_artinsem==1 | imp_dairy_selectbreed==1 | ///
		imp_dairy_healthserv==1 | imp_dairy_medicine==1 | imp_dairy_vaccinated==1 | ///
		imp_dairy_prevmast==1 | imp_dairy_roof==1 | imp_dairy_fedbyprod==1 | ///
		imp_dairy_fedconcentrate==1 | imp_dairy_fedvitmin==1 | ///
		imp_dairy_collmanure==1 | imp_dairy_fedfodder==1)
la val 	imp_dairy_livestm YESNO 
la var 	imp_dairy_livestm "Applied improved livestock management"
tab 	imp_dairy_livestm

*Step 4.2. Create a binary variable to flag dairy cow producers who applied a  
*		targeted improved management practice or technology related to marketing and distribution (imp_dairy_markdist). 
gen 	imp_dairy_markdist=0
replace imp_dairy_markdist=1 if (imp_dairy_soldmilk==1 | imp_dairy_soldmanure==1)
la val 	imp_dairy_markdist YESNO 
la var 	imp_dairy_markdist "Applied improved marketing and distribution"
tab 	imp_dairy_markdist

*Step 4.3. Create a binary variable to flag dairy cow producers who applied a targeted 
*		improved management practice or technology related to value added processing (imp_dairy_valadd).
gen 	imp_dairy_valadd=0
replace imp_dairy_valadd=1 if (imp_dairy_pasteurized==1)
la val 	imp_dairy_valadd YESNO 
la var 	imp_dairy_valadd "Applied improved handling or housing"
tab 	imp_dairy_valadd

*Step 4.4. Create a binary variable to flag dairy cow producers who applied a targeted 
*		improved management practice or technology related to food safety 
*		(imp_dairy_fsafety).
gen 	imp_dairy_fsafety=0
replace imp_dairy_fsafety=1 if (imp_dairy_pasteurized==1)
la val 	imp_dairy_fsafety YESNO 
la var 	imp_dairy_fsafety "Applied improved food safety practices"
tab 	imp_dairy_fsafety

*Step 4.5. Create a binary variable to flag dairy cow producers who applied a 
*		targeted improved management practice or technology not captured in any 
*		other category (imp_dairy_other).
gen 	imp_dairy_other=0
replace imp_dairy_other=1 if (imp_dairy_records==1)
la val 	imp_dairy_other YESNO 
la var 	imp_dairy_other "Applied other improved practice or technology"
tab 	imp_dairy_other

*STEP 5. Create a variable list (IMP_dairy) that includes all applicable improved 
*		management practice and technology practices for dairy cows. Adapt this 
*		step as needed to reflect different livestock value chains and improved 
*		management practices and technologies promoted in the ZOI country context.
global IMP_dairy imp_dairy_artinsem imp_dairy_selectbreed imp_dairy_healthserv imp_dairy_medicine imp_dairy_vaccinated imp_dairy_prevmast imp_dairy_roof imp_dairy_fedbyprod imp_dairy_fedconcentrate imp_dairy_fedvitmin imp_dairy_collmanure imp_dairy_fedfodder imp_dairy_pasteurized imp_dairy_soldmilk imp_dairy_soldmanure imp_dairy_records

*STEP 6. Create a count variable to capture the total number of targeted improved 
*		management practices or technologies each dairy cow producer used to raise 
*		dairy cows (imp_tot_dairy). That is, create a variable that sums all the 
*		variables created in Step 3.
egen 	imp_tot_dairy = rowtotal ($IMP_dairy)
la var 	imp_tot_dairy "Number of target improved practices and technologies applied (dairy cows)"
tab  	imp_tot_dairy

*STEP 7. Create a categorical variable to categorize dairy cow producers by the 
*		number of targeted improved practices or technologies they used 
*		(imp_cat_dairy) for Table 7.4.4. The categories used should be adapted 
*		based on the survey data; they do not have to be 0, 1-3, 4-6, 7-9, and 10 
*		or more targeted improved practices or technologies.
gen 	imp_cat_dairy=.
replace imp_cat_dairy=0 if (imp_tot_dairy==0)
replace imp_cat_dairy=1 if (imp_tot_dairy>=1 & imp_tot_dairy<=3)
replace imp_cat_dairy=2 if (imp_tot_dairy>=4 & imp_tot_dairy<=6)
replace imp_cat_dairy=3 if (imp_tot_dairy>=7 & imp_tot_dairy<=9)
replace imp_cat_dairy=4 if (imp_tot_dairy>=10 & imp_tot_dairy!=.)
la define cat_vcc 0 "None" 1 "1-3 practices" 2 "4-6 practices" 3 "7-9 practices" ///
		4 "10+ practices"
la val 	imp_cat_dairy cat_vcc
la var 	imp_cat_dairy "Number of targeted improved practices and technologies applied (dairy, categorical)"
tab 	imp_cat_dairy

*STEP 8. Create a binary variable to indicate whether each dairy cow producer 
*		applied any targeted improved management practices or technologies to raise 
*		dairy cows (imp_any_dairy).
gen 	imp_any_dairy=0
replace imp_any_dairy=1 if (imp_tot_dairy>0 & imp_tot_dairy!=.)
la val 	imp_any_dairy YESNO
la var 	imp_any_dairy "Applied any targeted management practice or technology (dairy cows)"
tab 	imp_any_dairy

*STEP 9. After applying the dairy cow producer sampling weight, calculate the 
*		percentage of de jure dairy cow producers who applied at least one targeted 
*		improved management practice or technology to raise dairy cows during the 
*		year preceding the survey using imp_any_dairy. Repeat using producers' age 
*		(under 30 years of age, 30 years of age or older) and sex as disaggregates. 
*		Also calculate the percentage of dairy cow producers who are de jure 
*		household members who used each targeted improved management practice or 
*		technology, and the percentage of dairy cow producers who are de jure 
*		household members who used each management practice and technology type and 
*		livestock management sub-type.
svyset 	hhea [pw=wgt_dairy], strata(strata)
svy, 	subpop(hhmem_dj): tab imp_any_dairy
svy, 	subpop(hhmem_dj): tab imp_any_dairy age15_29y, col 
svy, 	subpop(hhmem_dj): tab imp_any_dairy sex, col 

foreach var of varlist imp_dairy_* {
		svy, subpop(hhmem_dj): tab `var'
} 

*STEP 10. Calculate the percentage distribution of dairy cow producers who are de 
*		jure household members by the number of targeted improved management 
*		practices or technologies they used to cultivate dairy cows during the 12 
*		months preceding the survey using imp_cat_dairy. Repeat using producers' 
*		age (under 30 years of age, 30 years of age or older) and sex as 
*		disaggregates. 
svy, subpop(hhmem_dj): tab imp_cat_dairy
svy, subpop(hhmem_dj): tab imp_cat_dairy age15_29y, col
svy, subpop(hhmem_dj): tab imp_cat_dairy sex, col
	
*STEP 11. Keep only the variables that are necessary to calculate the final 
*		overall indicator across all VCCs and save the data.
keep 	hhea hhnum m1_line strata sex age15_29y hhmem_dj wgt_dairy vcc_dairy ///
		imp_tot_dairy imp_any_dairy imp_dairy_*
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.dta"

di "Date:$S_DATE $S_TIME"
log close
