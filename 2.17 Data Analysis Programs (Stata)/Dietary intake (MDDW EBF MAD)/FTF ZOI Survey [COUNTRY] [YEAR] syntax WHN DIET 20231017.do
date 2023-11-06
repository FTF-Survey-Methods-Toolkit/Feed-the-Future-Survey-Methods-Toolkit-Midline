/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
*************************** WOMEN'S NUTRITION (MDD-W) **************************
******************************** [COUNTRY] [YEAR] ******************************
********************************************************************************
Description: This code is intended to produce the following indicator: the
percentage of women of reproductive age (15-49 years) consuming a diet of 
minimum dietary diversity (MDD-W) 

Syntax prepared by ICF, 2018
Revised by ICF, October 2021, April 2023, September 2023

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 15.2.3 in the Guide to Feed the Future Midline 
Statistics.

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. Be sure to adjust it as needed to align with the 
country-customized questionnaire.
********************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input(s):     	 "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta"
//Data Outputs(s):	 "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] whn.dta"
//Log Outputs(s):	 "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] whn.log"
//Do file Name:    	 "$syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax whn.do"				

capture log close
cap la def YESNO 0 "No" 1"Yes"

log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] whn.log", replace	
********************************************************************************
*Step 0: Load the persons analytic do file and keep only records for woman of 
*        reproductive age (15-49 years of age) who complete Module 4, Women's
*        nutrition.
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear

keep if sex==2 & inrange(age,15,49)==1 & v400r==1

********************************************************************************
* Step 1: Identify the variables associated with the 10 food groups used to 
*         generate women's food score. Pay particular attention if the 
*         questionnaire was adapted to include local foods. Table 21 in the 
*         Guide to Feed the Futre Midline Statistics lists the food groups and 
*         their corresponding variables according to the core ZOI Midline Survey 
*         questionnaire.

*Step 2: Create 10 binary variables, 1 for each food group variable 
*        (whn_foodgrp1-whn_foodgrp10).

*Step 2.1: Create a variable to flag women who ate grains, white roots, or 
*          tubers, including plaintains (whn_foodgrp1).
gen     whn_foodgrp1=0	
replace whn_foodgrp1=1 if v409==1 | v411==1 | v411a==1	
la val 	whn_foodgrp1 YESNO
la var 	whn_foodgrp1 "Woman ate grains, white roots, or tubers"
tab whn_foodgrp1

*Step 2.2: Create a variable to flag women who ate pulses (whn_foodgrp2).
gen     whn_foodgrp2=0	
replace whn_foodgrp2=1 if v422==1									
la val 	whn_foodgrp2 YESNO
la var 	whn_foodgrp2 "Woman ate pulses"
tab whn_foodgrp2

*Step 2.3: Create a variable to flag women who ate nuts or seeds (whn_foodgrp3).							
gen     whn_foodgrp3=0		
replace whn_foodgrp3=1 if v423==1		
la val 	whn_foodgrp3 YESNO
la var 	whn_foodgrp3 "Woman ate nuts or seeds"
tab whn_foodgrp3

*Step 2.4: Create a variable to flag women who ate dairy products (whn_foodgrp4).
gen     whn_foodgrp4=0	
replace whn_foodgrp4=1 if v424==1
la val 	whn_foodgrp4 YESNO
la var 	whn_foodgrp4 "Woman ate dairy products"
tab whn_foodgrp4

*Step 2.5: Create a variable to flag women who ate meat, poultry, or fish 
*          (whn_foodgrp5); that is, organ meats, domesticated animals, organ 
*          meats wildlife, flesh meat wild animal, or fresh or dried fish.
gen     whn_foodgrp5=0
replace whn_foodgrp5=1 if v416==1 | v417==1 | v418==1 | v419==1 | v421==1 | v428==1
la val 	whn_foodgrp5 YESNO
la var 	whn_foodgrp5 "Woman ate meat, poultry, or fish"
tab whn_foodgrp5

*Step 2.6: Create a variable to flag women who ate eggs (whn_foodgrp6).
gen     whn_foodgrp6=0	
replace whn_foodgrp6=1 if v420==1
la val 	whn_foodgrp6 YESNO
la var 	whn_foodgrp6 "Woman ate eggs"
tab whn_foodgrp6

*Step 2.7: Create a variable to flag women who ate dark leafy green vegetables 
*          (whn_foodgrp7).
gen     whn_foodgrp7=0	
replace whn_foodgrp7=1 if v412==1
la val 	whn_foodgrp7 YESNO
la var 	whn_foodgrp7 "Woman ate dark green leafy vegetables"
tab whn_foodgrp7

*Step 2.8: Create a variable to flag women who ate vitamin A-rich fruits or 
*          vegetables other than dark leafy green vegetables (whn_foodgrp8).
gen     whn_foodgrp8=0		
replace whn_foodgrp8=1 if v410==1 | v414==1 | v429==1					
la val 	whn_foodgrp8 YESNO
la var 	whn_foodgrp8 "Woman ate other vitamin A-rich fruits/vegetables"
tab whn_foodgrp8

*Step 2.9: Create a variable to flag women who ate other vegetables—that is, 
*          those not rich in vitamin A (whn_foodgrp9).
gen     whn_foodgrp9=0	
replace whn_foodgrp9=1 if v413==1
la val 	whn_foodgrp9 YESNO
la var 	whn_foodgrp9 "Woman ate other vegetables"
tab whn_foodgrp9

*Step 2.10: Create a variable to flag women who ate other fruits—that is, those 
*           not rich in vitamin A (whn_foodgrp10).
gen     whn_foodgrp10=0	
replace whn_foodgrp10=1 if v415==1
la val 	whn_foodgrp10 YESNO
la var 	whn_foodgrp10 "Woman ate other fruits"
tab whn_foodgrp10

*Step 3: Create a variable that flags women who are missing data for all food 
*        variables (whn_fmiss). 

*Step 3.1: Create variables that recode responses that have a value of `no' (2) 
*          or `don't know' (8) to be `0' and missing (9) responses to be 
*          missing (.) if they do not already exist in the data file.   
foreach var of varlist v409 v410 v411 v411a v412 v413 v414 v415 v416 v417 v418 v419 v420 v421 v422 v423 v424 v429 {
  recode `var' 2 8=0 9=., gen(`var'x)
  lab val `var'x YESNO 
}
  
*Step 3.2: Create a variable that counts the number of recoded food variables 
*          created in Step 3.1 that are missing (whn_num_fmiss). 
egen whn_num_fmiss=rowmiss(v409x v410x v411x v411ax v412x v413x v414x v415x v416x v417x v418x v419x v420x v421x v422x v423x v424x v429x)
label var whn_num_fmiss	"Number of woman's food variables missing values"  
tab whn_num_fmiss

*Step 3.3: Create a variable that flags whether a woman is missing all food 
*          variables (whn_fmiss)—that is, if the value of whn_num_fmiss is less 
*          than the total number of variables being summed 
*          (i.e., 18 in the template analysis). 
gen 	whn_fmiss=0 if whn_num_fmiss<18 
replace whn_fmiss=1 if whn_num_fmiss==18 
la val 	whn_fmiss YESNO 
la var 	whn_fmiss "Woman is missing all food data"
tab whn_fmiss 

*Step 4: Calculate each woman's minimum dietary diversity food score by
*        summing the number of food groups consumed (whn_fscore).
egen whn_fscore=rowtotal(whn_foodgrp*) 
replace whn_fscore=. if whn_fmiss==1 
la var whn_fscore "Woman’s minimum dietary diversity food score"
tab whn_fscore 

*Step 5: Create a binary variable that flags a woman who achieved a minimum 
*        dietary diversity (whn_mddw)
gen     whn_mddw=. 		
replace whn_mddw=0 if whn_fscore<5
replace whn_mddw=1 if whn_fscore>=5 & whn_fscore!=.
la val 	whn_mddw YESNO
la var 	whn_mddw "Woman achieved minimum dietary diversity (MDD-W)"
tab whn_mddw

*Step 6: Create a variable that captures the sub-population being examined for 
*        the indicator calculation—that is, women of reproductive age who are 
*        de facto HH members among all women of reproductive age surveyed 
*        (hhmem_wra_df).
gen 	hhmem_wra_df=.
replace hhmem_wra_df=0 if wra==1
replace hhmem_wra_df=1 if wra==1 & hhmem_df==1
la val 	hhmem_wra_df YESNO
la var  hhmem_wra_df "Woman 15-49 years is a de facto HH member"
tab hhmem_wra_df

*Step 7: Apply the women of reproductive age weight (wgt_w) and calculate the 
*        percentage of women of reproductive age who are de facto HH members who 
*        achieved the minimum diet diversity score using whn_mddw. Repeat using 
*        the two age category disaggregates (15-19/20-49 and 5-year age groups),
*        as well as the gendered household type, wealth quintile, and shock
*        exposure severity disaggregates. 
svyset hhea [pweight=wgt_w], strata(strata)
svy, subpop(hhmem_wra_df): tab whn_mddw_w 
svy, subpop(hhmem_wra_df): tab whn_mddw_w wra_cage, col perc format(%6.1f)
svy, subpop(hhmem_wra_df): tab whn_mddw wra_agegrp, col perc format(%6.1f)
svy, subpop(hhmem_wra_df): tab whn_mddw genhhtype_dj, col perc format(%6.1f)
svy, subpop(hhmem_wra_df): tab whn_mddw awiquint, col perc format(%6.1f)
svy, subpop(hhmem_wra_df): tab whn_mddw shock_sev, col perc format(%6.1f)

*Keep variables that will be added to the final post-analysis data file
*and save the data fie.
keep hhea hhnum m1_line wgt_w strata whn* hhmem_wra_df wra
save  "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] whn_nut.dta",replace

di "Date:$S_DATE $S_TIME"
log close
