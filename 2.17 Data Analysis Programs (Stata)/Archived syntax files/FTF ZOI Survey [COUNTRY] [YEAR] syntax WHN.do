/*******************************************************************************
*************************** FEED THE FUTURE ZOI MIDLINE SURVEY *************************
*********************** WOMEN HEALTH NUTRITION MODULE (WHN) ********************
***************************** [COUNTRY, YEAR] **********************************
********************************************************************************
Description: This code is intended to produce women's health and nutrition 
indicators. The following indicators are included:

Prevalence of women of reproductive age (15-49 years) consuming a diet of 
minimum dietary diversity (MDD-W) 

*Author(s): Ramu Bishwakarma and Gheda Temsah @ ICF Macro
*Last updated: October 14 2021 by Shireen Assaf to remove anthro measure and WDDS indicator

This syntax file was developed using the core Feed the Future ZOI Survey 
and adapted for the Midline survey. 
It must be adapted for the final country-specific questionnaire. 
The syntax could only be partially tested using ZOI Survey data; therefore, 
double-check all results carefully and troubleshoot to resolve any issues identified. 
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
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] whn.log", replace	
					

*******************************************************************************
/// WOMEN'S DIETARY DIVERSITY (ALL WOMEN 15-49 YEARS OLD)	 			 
*******************************************************************************
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear
keep if sex==2 & inrange(v402,15,49)==1


*******************************************************************************
* Phase two indicator: Percent of women of reproductive age consuming a diet
* of minimum diversity (looking at 10 food groups) (MDD-W) 
*******************************************************************************

** Step-1: Identify the variables 
** Step-2: Construct ten food group scores

gen     mddfgrp1= 0	//grains, roots, tuber, plantain
replace mddfgrp1= 1 if (v409==1 | v411==1 | v411a==1) 		

gen     mddfgrp2= 0	//beans and peas
replace mddfgrp2= 1 if (v422==1)										
																	
gen     mddfgrp3= 0	//nuts and seeds	
replace mddfgrp3= 1 if (v423==1)			

gen     mddfgrp4= 0	//dairy products (milk, yoghurt, cheese)	
replace mddfgrp4= 1 if (v424==1)

gen     mddfgrp5= 0	//organ meats, domesticated animals, organ meats wildlife, flesh meat wild animal, fresh or dried fish, grubs/snail/insects
replace mddfgrp5= 1 if (v416==1 | v417==1 | v418==1 | v419==1 | v421==1 | v428==1) 

gen     mddfgrp6= 0	//eggs
replace mddfgrp6= 1 if (v420==1)

gen     mddfgrp7= 0	//dark leafy vegetables
replace mddfgrp7= 1 if (v412==1)

gen     mddfgrp8= 0	//other vitamin A rich fruits and vegetables	
replace mddfgrp8= 1 if (v410==1 | v414==1 | v429==1)							

gen     mddfgrp9= 0	//other vegetables
replace mddfgrp9= 1 if (v413==1)

gen     mddfgrp10= 0	//other vegetables
replace mddfgrp10= 1 if (v415==1)

** Step 3a. Create variable that flags women missing all food data
** INSTRUCTIONS
gen whn_fmiss=.
replace whn_fmiss=1 if (v409/v429)==.
la var whn_fmiss "Woman is missing all food data"

**Step 3. Construct MDD food score
egen mdd_wfscore=rowtotal(mddfgrp*) 
replace mdd_wfscore=. if wra!=1 | whn_fmiss==1 
la var mdd_wfscore "Woman’s minimum dietary diversity food score"

** Step 4: Construct MDD_W 
gen     whn_mdd_w=. 		
replace whn_mdd_w=1 if (mdd_wfscore>=5 & mdd_wfscore<.) 
replace whn_mdd_w=0 if mdd_wfscore<5
lab var whn_mdd_w "Women of reproductive age who are consuming minimum (at least 5) dietary diversity"

**Step 5. Generate prevalence of women who achieve MDD using sample weights
svyset hhea [pw=wgt_w], strata(strata) // not needed if done for previous women indicators
svy, subpop(hhmem_df): tab whn_mdd_w
svy, subpop(hhmem_df): tab whn_mdd_w wra_cage
*svy, subpop(hhmem_df): prop whn_mdd_w 
*svy, subpop(hhmem_df): mean whn_mdd_w, over(wra_cage)

//Keep variables that will be added to the final post-analysis data file
//and save the data fie.
keep hhea hhnum whn*  
sort  hhea hhnum
save  "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] whn_nut.dta",replace

di "Date:$S_DATE $S_TIME"
log close
