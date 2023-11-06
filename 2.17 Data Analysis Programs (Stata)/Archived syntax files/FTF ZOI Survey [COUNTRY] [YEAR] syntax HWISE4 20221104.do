/*******************************************************************************
*************************** FEED THE FUTURE ZOI SURVEY *************************
******************************* HWISE-4 INDICATOR  *****************************
******************************** [COUNTRY, YEAR] *******************************
********************************************************************************

The Household Water Insecurity Experience Scale 4-item (HWISE-4) short form
 (aka Brief Water Insecurity Experiences (BWISE)) is comprised of 4 items: 
 
1. Worry: In the last 4 weeks, how frequently did you or anyone in your household 
   worry you would not have enough water for all of your household needs?
2. Plans: In the last 4 weeks,how frequently have you or anyone in your household
   had to change schedules or plans because of problems with your water situation? 
3. Drink: In the last 4 weeks, how frequently has there not been as much water to 
   drink as you would like for you or anyone in your household?
4. Hands: In the last 4 weeks, how frequently have you or anyone in your household
   had to go without washing hands after dirty activities?
 
Responses to items are as follows: 
	never (0 times), 
	rarely (1–2 times), 
	sometimes (3–10 times), 
	often (11–20 times), 
	always (more than 20 times).

Rarely is scored as 1, sometimes is scored as 2, and often/always is scored as 3. 

Responses are totaled for a summative score. A score of >= 4 indicates household 
water insecurity. 

Young, S. et al (2018). Validity of a Four-Item Household Water Insecurity Experiences Scale 
for Assessing Water Issue Related to Health and Well-Being. Am. J. Trop. Med. Hyg., 104(1), 2021, pp. 391–394	

Syntax prepared by ICF, January 2022 
*******************************************************************************/

set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\Midline FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] resilience.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] resilience.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax resilience.do 
//Key indicators(s):    
 
cap log close
cap log using  "$analytic\Log\Midline FTF ZOI Survey [COUNTRY] [YEAR] hwise4.log", replace

********************************************************************************

*Step 0. Load the household-level analytic data file
use  "$analytic\Midline ZOI household data analytic.dta", clear 

*Step 1a. Define the variables to use to construct the indicator
global $bwise v218a v218b v218c v218d
tab $bwise

*Step 1b. Ensure that all four variables of interest are not missing for any households
/*** All 4 should have values. ***/
egen  miss_h4 = rowmiss($bwise)

*Step 2. Add responses together for a summative score for HWISE-4.
*        Make sure all 4 items have a value for each household.
egen  bwise4 = rowtotal($bwise) if miss_h4==0

*Step 3. Create the indicator variable: Household Water Insecurity Experience
*  A score of  >= 4 indicates household water insecurity. 
gen     hwise4 = 1 if bwise4 >= 4
replace hwise4 = 0 if bwise4 < 4
la var  hwise4 "Brief Household Water Insecurity Experience Scale (HWISE-4)"
la def  hwise4 1 "Water insecure" 0 "Not insecure"
la val  hwise4 hwise4

tab hwise4

*Step 4. After applying the household weight (wgt_hh), calculate the percentage 
*		 of households who are facing water insecurity using the hwise4 analytic 
*	     variable. Repeat using the gendered household type and residence 
*	     (urban/rural) disaggregate. 
svyset hhea [pweight=wgt_hh], strata(strata) singleunit(scaled)

svy: tab hwise4
svy: mean hwise4, over(genhhtype_dj)
svy: mean hwise4, over(ahtype)

