/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
***************************** HWISE-4 INDICATOR  *******************************
****************************** [COUNTRY] [YEAR] ********************************
********************************************************************************
Description: The Household Water Insecurity Experience Scale 4-item (HWISE-4) 
short form (aka Brief Water Insecurity Experiences [B-WISE]) comprises 4 
questions: 
 
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

Never is scored as 0, rarely as 1, sometimes as 2, and often/always as 3. 

Responses are totaled for a summative score. A score >= 4 indicates household 
water insecurity. 

Reference: Young, S. et al (2018). Validity of a Four-Item Household Water 
Insecurity Experiences Scale for Assessing Water Issue Related to Health and 
Well-Being. Am. J. Trop. Med. Hyg., 104(1), 2021, pp. 391–394	

Syntax prepared by ICF, January 2022 
Syntax revised by ICF, March 2023, September 2023

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 7.8 in the Guide to Feed the Future Midline 
Statistics.

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. Be sure to adjust it as needed to align with the 
country-customized questionnaire.
*******************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] hwise4.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] hwise4.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax hwise4.do 
 
cap log close
cap log using  "$analytic\Log\Midline FTF ZOI Survey [COUNTRY] [YEAR] hwise4.log", replace

********************************************************************************
*Step 1.1: Load the household-level analytic data file
use  "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear 

*Step 1.2: Create a global variable to define the variables used to construct 
*          the indicator (bwise).
global bwise v218a v218b v218c v218d
tab1 $bwise

*Step 1.3: Ensure that the $bwise variables are not missing for any HHs by 
*          creating a variable to capture HHs with missing values (miss_h4).
egen  miss_h4 = rowmiss($bwise)
la val miss_h4 YESNO
la var miss_h4 "HH is missing 1+ variable for HWISE-4 calculation"

*Step 2. Create analytic variables that recode the $bwise variables 
*        with a value of 4 to be 3 (v218ax, v218bx, v218cx, v218dx).
for var $bwise: recode X 4=3, gen(Xx)
la def no_times 0 "Never (0 times)" 1 "Rarely (1-2 times)" ///
				2 "Sometimes (3-10 times)" 3 "Often/Always (11+ times)"
for var $bwise: la val Xx no_times

*Step 3. Create a variable that sums the 4 variables created in Step 2, 
*        excluding HHs with any missing data (bwise4).
egen  bwise4=rowtotal(v218ax v218bx v218cx v218dx) if miss_h4==0
la var bwise4 "HH's HWISE-4 score (0-12)"

*Step 4. Create the binary indicator variable (hwise4). A score >= 4 indicates 
*        HH water insecurity. 
gen     hwise4=1 if bwise4>=4 & bwise4!=.
replace hwise4=0 if bwise4<4
la var  hwise4 "Brief Household Water Insecurity Experience Scale (HWISE-4)"
la def  hwise4 1 "Water insecure" 0 "Not insecure"
la val  hwise4 hwise4
tab hwise4

*Step 5. After applying the household weight (wgt_hh), calculate the percentage 
*		 of households who are facing water insecurity using the hwise4 analytic 
*	     variable. Repeat using the gendered household type, residence 
*	     (urban/rural), wealth quintile, and shock experience severity
*        disaggregates. 
svyset hhea [pweight=wgt_hh], strata(strata)
svy: tab hwise4
svy: tab hwise4 genhhtype_dj, col perc format(%6.1f)
svy: tab hwise4 ahtype, col perc format(%6.1f)
svy: tab hwise4 awiquint, col perc format(%6.1f)
svy: tab hwise4 shock_sev, col perc format(%6.1f)

*STEP 6. Keep only the key intermediate and indicator variables and save the file
keep hhea hhnum m1_line wgt_hh strata miss_h4 bwise4 hwise4 

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] hwise4.dta",replace

di "Date:$S_DATE $S_TIME"
log close

