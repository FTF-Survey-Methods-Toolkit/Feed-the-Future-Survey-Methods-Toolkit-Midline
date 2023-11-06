
************************ FEED THE FUTURE ZOI SURVEY ****************************
*********************  AGRICULTURE PRACTICE INDICATORS *************************
******************************** [Country Year] ********************************
/*******************************************************************************

Description: This code calculates the promoted improved practice indicator for 
             sheep.

Customized by: ICF for Midline Survey
Date         : October 2021

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

******************************************************************************/
cap log close 
log using "$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_sheep.log",replace	
********************************************************************************
/*Step 1. Review the sheep section of the agriculture module in the ZOI 
Survey questionnaire and identify questions that relate to improved management 
practices and technologies being promoted in the ZOI. Determine which response 
options would be considered targeted improved management practices and technologies, 
and also determine what livestock sub-category or sub-categories the targeted 
improved management practices and technologies fall under. */

use "$analytic\FTF ZOI Survey [Country] [Year] persons data analytic", clear


/**--------------------------------------------------------------------------**/
// Step 2: Identify variables and prepare data
keep if  vcc_sheep==1 
keep hhea hhnum m1_line strata sex age *vcc* v752*

/*----------------------------------------------------------------------------*/
// Step 3: Create binary variables for each of the management practice and technology 
**  types to flag farmers who applied targeted improved management practices or 
**  technologies to raise sheep.

*Step 3a. Used artificial insemination for breeding Sheep
gen     sheep_ai=0
replace sheep_ai=1 if (strpos(v75206,"D")>0)

lab var sheep_ai "Sheep: used artificial insemination for breeding Sheep"
label val sheep_ai yes_no
*tab  sheep_ai

*Step 3b. Household Sheep in a structure with a roof and sides (any type of floor) 
gen     sheep_inroof=0
replace sheep_inroof=1 if inrange(v75210,5,7)

lab var sheep_inroof "Sheep: Household Sheep in a structure with a roof and sides (any type of floor)"
label val sheep_inroof yes_no
*tab  sheep_inroof

*Step 3c. Piped drinking water to Sheep (or took Sheep to a community water point)
* Midline has only option 4 (Piped H2O)
gen     sheep_pipedwtr=0
replace sheep_pipedwtr=1 if inlist(v75211,4)

lab var sheep_pipedwtr "Sheep: Piped drinking water to sheep"
label val sheep_pipedwtr yes_no
*tab  sheep_pipedwtr

*Step 3d. Did anything to improve the quality of pasture
gen     sheep_pasture=0
replace sheep_pasture=1 if v75212b==1

lab var sheep_pasture "Sheep: did anything to improve the quality of pasture"
label val sheep_pasture yes_no
*tab  sheep_pasture

*Step 3e. Fed crop fodder to Sheep
* n ... Crop Fodder not in Midline
gen     sheep_fodder=0
replace sheep_fodder=1 if (strpos(v75214,"N")>0)

lab var sheep_fodder "Sheep: Fed crop fodder to sheep"
label val sheep_fodder yes_no
*tab  sheep_fodder

*Step 3f. Fed wheat bran to Sheep 
gen     sheep_bran=0 
replace sheep_bran=1 if (strpos(v75213,"B")>0 | strpos(v75217,"B")>0)

lab var sheep_bran "Sheep: Fed wheat bran to sheep"
label val sheep_bran yes_no
*tab  sheep_bran

*Step 3g. Fed minerals or vitamins 
gen     sheep_vit=0
replace sheep_vit=1 if v75222==1

lab var   sheep_vit "Sheep: Fed minerals or vitamins"
label val sheep_vit yes_no
*tab  sheep_vit

*Step 3h. Obtained health services from trained provider
gen     sheep_hlthserv=0
replace sheep_hlthserv=1 if v75225==1

lab var   sheep_hlthserv "Sheep: Obtained health services from trained provider"
label val sheep_hlthserv yes_no
*tab  sheep_hlthserv

*Step 3i. Vaccinated all Sheep
gen     sheep_vax=0
replace sheep_vax=1 if v75230==3

lab var   sheep_vax "Sheep: vaccinated all Sheep"
label val sheep_vax yes_no
*tab  sheep_vax

*Step 3j. Graze Sheep in enclosed/private land
gen     sheep_grazing=0
replace sheep_grazing=1 if v75212a==2

lab var   sheep_grazing "Sheep: Graze Sheep in enclosed/private land"
label val sheep_grazing yes_no
*tab  sheep_grazing

*Step 3k. Relied on the following information sources for sheep production: 
*    local agrovet dealer, private veterinary pharmacy, ag extension worker, radio, SMS, internet

gen     sheep_infoprod=0
replace sheep_infoprod=1 if inlist(v75257,3,4,5,7,8,9,10)

lab var   sheep_infoprod "Sheep: sheep production info source: local agrovet dealer, private vet. pharmacy, ag extension worker, radio, SMS, internet"
label val sheep_infoprod yes_no
*tab  sheep_infoprod

*Step 3l. Pasteurized Sheep’ milk 
gen     sheep_milk=0
replace sheep_milk=1 if (strpos(v75240,"B")>0)

lab var   sheep_milk "Sheep: Pasteurized Sheep milk "
label val sheep_milk yes_no
*tab  sheep_milk

// Step 4: Create a count variable to capture total number of targeted improved 
**      management practice or technology types to raise sheep (totimp_sheep).

* Total number of improved livestock practices for SHEEP */
global imp_sheep sheep_ai sheep_inroof sheep_pipedwtr sheep_pasture sheep_fodder sheep_bran sheep_vit sheep_hlthserv sheep_vax sheep_grazing sheep_infoprod sheep_milk

egen    imptot_sheep= rowtotal($imp_sheep)
lab var imptot_sheep "Total number of improved sheep/livestock practices applied"

// Step 5: Create a count variable to capture if farmer applied
*       any targeted improved management practices or technologies to raise sheep (anyimp_sheep).

** Any imporved livestock practice
egen anyimp_sheep = anymatch ($imp_sheep), v(1)
lab var anyimp_sheep "Any improved sheep/livestock practice applied"


// Step 6. After applying the dairy sheep farmer sampling weight, calculate the % of 
*         de jure dairy sheep farmers who applied 1+ targeted improved management 
*         practice or technology to raise sheep during the year preceding 
*         the survey using the anyimp_sheep analytic variable. Repeat using farmers’ 
*         age (<30, 30+) and sex as disaggregates.

svyset hhea [pw=wgt_sheep], strata(strata)
svy, subpop(hhmem_dj): prop anyimp_sheep
svy, subpop(hhmem_dj): prop anyimp_sheep, over(vcc_youth)
svy, subpop(hhmem_dj): prop anyimp_sheep, over(sex)

*
