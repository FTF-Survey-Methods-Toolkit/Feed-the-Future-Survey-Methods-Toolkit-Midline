/*******************************************************************************
************************** FEED THE FUTURE ZOI SURVEY **************************
******************** CHILDREN'S NUTRITION INDICATORS (CHN) *********************
******************************* [COUNTRY, YEAR] ********************************
********************************************************************************
Description: This code is intended to produce children's health and nutrition
indicators. The following indicators are included:

*A. Prevalence of exclusive breastfeeding of children under 6 months of age - FTF indicator
*B. Prevalence of children 6-23 months with minimum dietary diversity (MDD)
*C. Prevalence of children 6-23 months with minimum meal frequency (MMF)
*D. Prevalence of children 6-23 months receiving a minimum acceptable diet (MAD) - FTF indicator

Updated from baseline syntax by ICF 2022 for P2-ZOI midline surveys
				
This syntax file was developed using the core Feed the Future P2-ZOI Midline Survey 
questionnaire. It must be adapted for the final country-specific questionnaire. 
The syntax could only be partially tested using ZOI Survey data; therefore, 
double-check all results carefully and troubleshoot to resolve any issues identified. 
*******************************************************************************/
set   more off
*clear all
macro drop _all

/*DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

*Input(s):     	 "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta"
*Data Outputs(s):	 "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.dta"
*Log Outputs(s):	 "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.log"
*Do file Name:    	 "$syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax chn diet.do"				

capture log close
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.log", replace	

use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear
*/

cap la def YESNO 0 "No" 1"Yes"

********************************************************************************
*** EXCLUSIVE BREASTFEEDING (0-5 MONTHS)
********************************************************************************

***Step 1: Create a variable for whehter child is breastfed
gen bf=.
replace bf=0 if c0_5m==1
replace bf=1 if (v521==1 | v522==1) & c0_5m==1
la var bf "Child consumed breastmilk"
la value bf YESNO

***Step 2:  Create a variable for whether child received any milk other than breastmilk
egen othermilk=anymatch(v527 v529 v533), v(1)
replace othermilk=. if c0_5m!=1 
tab othermilk,m
la var othermilk "Child consumed other milk (non-breastmilk)"
la value othermilk YESNO

***Step 3: Create a variable for whether child received plain water
gen water=0
replace water=1 if v526==1 & c0_5m==1
replace water=. if c0_5m!=1 
la var water "Child consumed plain water"
la value water YESNO

***Step 4: Create a variable for whether child received non-milk liquids
egen nonmilk = anymatch (v531 v532 v535 v536 v537), v(1)
replace nonmilk=. if c0_5m!=1 
la var nonmilk "Child consumed non-milk liquid"
la value nonmilk YESNO

***Step 5: Create a variable for whether child received any food
*SA: added v560, previously the range stopped at v559 although v560 was included in step 6
egen food=anymatch(v539-v560), v(1) 
replace food=. if c0_5m!=1
la var food "Child consumed any food (non-liquid)"
la value food YESNO

***Step 6. Create variable to flag children who are missing all data about feedings
*Step 6a. Check distributions of feeding variables and recode missing and DK's to "no"
foreach var of varlist v526 v527 v529 v531 v532 v533 v535 v536 v537 v539-v560 {
  *tab `var',m
  recode `var' 2=0 8 9=., gen(`var'x)  
  *treat DKs and missing as "no" ; assume not given
}
sum v526x v527x v529x v531x v532x v533x v535x v536x v537x v539x-v560x

*Step 6b. Create the chn_fmiss variable
egen chn_fmiss=rowmiss(v526x v527x v529x v531x v532x v533x v535x v536x v537x v539x-v560x) 
replace chn_fmiss=. if c6_23!=1
replace chn_fmiss=0 if chn_fmiss<32
replace chn_fmiss=1 if chn_fmiss==32
la var chn_fmiss "Child is missing all food data"
la value chn_fmiss YESNO
tab chn_fmiss if c0_5m==1,m

***Step 7: Create a variable for whether child is exclusively breastfeeding
gen     bf_exclusive=0  if c0_5m==1
replace bf_exclusive=1 if bf==1 & water==0 & othermilk==0 & nonmilk==0 & food==0 & c0_5m==1
replace bf_exclusive=. if chn_fmiss==1 
la var bf_exclusive "Child was exclusively breastfed"
la value bf_exclusive YESNO

/***Step 8. Genreate prevalence of exclusive breastfeeding using sample weights 
gen hhmem_c05m_df=.
replace hhmem_c05m_df=0 if c0_5m==1
replace hhmem_c05m_df=1 if c0_5m==1 & hhmem_df==1
la var hhmem_c05m_df "Child 0-5 months is a de facto HH member"
la val hhmem_c05m_df YESNO

*The strata variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_c2], strata(strata) 
svy, subpop(hhmem_c05m_df): prop bf_exclusive 
svy, subpop(hhmem_c05m_df): prop bf_exclusive, over(sex)
*/
********************************************************************************
*SA added other indicators produced in the heading (MDD and MMF). 
***CHILDREN'S MINIMUM DIETARY DIVERSITY (MDD), MINIMUM MEAL FREQUENCY (MMF), and MINIMUM ACCEPTABLE DIET (MAD) ALL CHILDREN 6-23 MONTHS (183-729 days)   
********************************************************************************

*SA: removed three groups of BF status by age, not needed. Replaced it with bf_stat var that was previously Step 6.
*SA: adjusted bf_stat code 
*STEP 1 : Create breastfeeding status variable
gen bf_stat=(v521==1 | v522==1) 
replace bf_stat=. if v508<6 | v508>23
lab var bf_stat "Child is currently breastfeeding"
lab val bf_stat YESNO

*STEP 2: CREATE VARIABLES FOR THE 8 FOOD GROUPS 
*grains, roots/tuber, plantain
gen     foodgrp1=0	
replace foodgrp1=1 if (v535==1 | v539==1 | v541==1 | v541a==1) 
la var foodgrp1 "Child ate grains, roots, tubers"
la value foodgrp1 YESNO

*legume and nuts
gen     foodgrp2=0	
replace foodgrp2=1 if (v552==1 | v553==1)		
la var foodgrp2 "Child ate ate legumes, nuts"
la value foodgrp2 YESNO
			  
*formula, milk, yogurt, dairy product	
gen     foodgrp3=0	
* SA: added yogurt, non-drinks v534a
replace foodgrp3=1 if (v527==1 | v529==1 | v533==1 | v554==1 | v534a==1)
la var foodgrp3 "Child ate dairy products"
la value foodgrp3 YESNO

*flesh foods (organ meat, anymeat, organ meat from wildlife, flesh meat from wild animal, fresh or dried fish, grubs, snails or insects)
gen     foodgrp4=0
replace foodgrp4=1 if (v546==1 | v547==1 | v548==1 | v549==1 | v551==1 | v558==1)																				 
la var foodgrp4 "Child ate flesh foods"
la value foodgrp4 YESNO

*eggs
gen     foodgrp5=0	
replace foodgrp5=1 if (v550==1)
la var foodgrp5 "Child ate eggs"
la value foodgrp5 YESNO

*vitamin A rich fruits and vegetables-pumpkin/carrots/squash, seet potateos that are yellor or orange, drak green, ripe mangoes, red palm oil/red palm nuts
gen     foodgrp6=0	
replace foodgrp6=1 if (v540==1 | v542 ==1 | v544==1 | v559==1)
la var foodgrp6 "Child ate vitamin A rich fruits and vegetables"
la value foodgrp6 YESNO

*other fruits and vegetables
gen     foodgrp7=0	
replace foodgrp7=1 if (v543==1 | v545==1)
la var foodgrp7 "Child ate other fruits and vegetables"
la value foodgrp7 YESNO

*SA: add food group 8.
*breastmilk
gen foodgrp8= bf_stat 
la var foodgrp8 "Child consumed breastmilk"
la value foodgrp8 YESNO

*STEP 3: Create variables for MINIMUM DIETARY DIVERSITY (MDD) FOR BF AND NBF CHILDREN
* SA: adapted code to create mdd for all, BF and non-BF using breastfed variable v521
* SA: used new definition of 5 out of 8 food groups
**step 3a. create minimum dietary diversity variable among children 6-23 months
egen foodsum=rowtotal(foodgrp1-foodgrp8)
recode foodsum (1/4 =0) (5/8=1), gen(mdd_all) 
replace mdd_all=. if v508<6 | v508>23
la var mdd_all "Child ate foods from 5+ food groups, all children"
la value mdd_all YESNO

*step 3b. Create variable for minimum dietary diversity for breastfed children
gen mdd_bf = mdd_all 
replace mdd_bf=. if bf_stat==0
la var mdd_bf "Child ate foods from 5+ food groups, breastfed"
la value mdd_bf YESNO

**step 3c. Create variable for minimum dietary diversity for non-breastfed children	
gen mdd_nbf = mdd_all
replace mdd_nbf=. if bf_stat==1
la var mdd_nbf "Child ate foods from 5+ food groups, non-breastfed"
la value mdd_nbf YESNO

*SA: deleted step 3c (all children who meet MDD crietria ). This is coded in step 3a.

***STEP 4: Create MINIMUM MEAL FREQUENCY variable

**Step 4a. Prepare variables - recode missing and DK responses to zero
*to check data
sum v528 v530 v534 v563 
foreach var in v528 v530 v534 v563 {
  recode `var' 98 99=0, gen(`var'x)		
}

*Take into account  filter (v562) for variable v563.
*if v562 is a no, DK or missing, then assume that child did not eat any solid, semi-solid or soft foods
*SA: uncommented the next line which was commented because v563 has no observations. However, the code should still be run in case a survey has observations in this variable. 
replace v563x=0 if v562==2 | v562==8 | v562==9
                 
**Step 4b. Create variable for total number of milk feeds
egen   mfreq_milk= rowtotal(v528x v530x v534x)
la var mfreq_milk "Number of milk feeds day and night before survey"

**Step 4c. Create variable for total number of feeds including milk and food
egen   mfreq_milkplus= rowtotal(v528x v530x v534x v563x)
la var mfreq_milkplus "Number of feeds (milk+food) day and night before survey"

**Step 4d. Create variables that categorize children 6-23 months of age by age and breastfeeding status. 
*SA: added bf by age groups here since it is used in minmfreq indicator
gen bf_grp1=(v521==1 | v522==1) & c6_8m==1 
la var bf_grp1 "Child 6-8 months, breastfeeds"

gen bf_grp2=(v521==1 | v522==1) & c9_23m==1
la var bf_grp2 "Child 9-23 months, breastfeeds"

gen bf_grp3=((v521==2 & v522==2) | (v520==2 & v522==2)) & c6_23m==1 
la var bf_grp3 "Child 6-23 months, does not breastfeed"


**Step 4e: Create MMF variable: children  receive minimum meal frequency based on age and BF status
gen     minmfreq=0 if c6_23m==1  
replace minmfreq=1 if bf_grp1==1 & v563x>=2 & v563x<.
replace minmfreq=1 if bf_grp2==1 & v563x>=3 & v563x<.
replace minmfreq=1 if bf_grp3==1 & mfreq_milk>=2 & mfreq_milkplus>=4
replace minmfreq=. if chn_fmiss==1
la var minmfreq "Child meets minimum meal frequency criteria"
la value minmfreq YESNO

***STEP 5: Create MINIMUM ACCEPTABLE DIET (MAD) INDICATOR
gen     chn_mad=0 if c6_23m==1 
replace chn_mad=1 if minmfreq==1 & mdd_bf==1   
replace chn_mad=1 if minmfreq==1 & mdd_nbf==1  
replace chn_mad=. if chn_fmiss==1
la var chn_mad "Child meets minimum acceptable diet criteria"
la value chn_mad YESNO

/*STEP 6: Create a subpopulation variable for de facto children 6-23 months old
*and update sample-weighted calculations to use it.
gen hhmem_c623m_df=.
replace hhmem_c623m_df=0 if c6_23m==1
replace hhmem_c623m_df=1 if c6_23m==1 & hhmem_df==1

***Step 7. generate prevalence of children who meet MAD criteria
*The strata variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_c2], strata(strata)
svy, subpop(hhmem_c623m_df): prop chn_mad 
svy, subpop(hhmem_c623m_df): prop chn_mad, over(sex) 

*Keep variables that will be added to the final post-analysis data file
*and save the data file.
*SA: updated to keep computed indicators. 
keep m1_line hh* wgt_c2 bf* chn* mdd* mf* min* food* strata 
sort  hhea hhnum
save  "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.dta",replace

di "Date:$S_DATE $S_TIME"
log  close
*/