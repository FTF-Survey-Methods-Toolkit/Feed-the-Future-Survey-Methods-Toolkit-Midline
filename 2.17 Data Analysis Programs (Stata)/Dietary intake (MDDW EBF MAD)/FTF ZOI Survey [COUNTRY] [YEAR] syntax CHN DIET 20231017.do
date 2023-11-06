/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
******************** CHILDREN'S NUTRITION INDICATORS (CHN) *********************
****************************** [COUNTRY] [YEAR] ********************************
********************************************************************************
Description: This code is intended to produce Feed the Future's indicators 
related to children's dietary intake:

*1. Prevalence of exclusive breastfeeding of children under 6 months of age 
*2. Percent of children 6-23 months receiving a minimum acceptable diet (MAD) 

Syntax prepared by ICF, 2018
Syntax revised by ICF, October 2022, April 2023, September 2023

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Sections 15.2.1 and 15.2.2 in the Guide to Feed the 
Future Midline Statistics.
				
This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. Be sure to adjust it as needed to align with the 
country-customized questionnaire.
*******************************************************************************/
set   more off
*clear all
macro drop _all

*DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

*Input(s):     	 	 "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta"
*Data Outputs(s):	 "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.dta"
*Log Outputs(s):	 "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.log"
*Do file Name:    	 "$syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax chn diet.do"				

capture log close
cap la def YESNO 0 "No" 1"Yes"
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.log", replace	
********************************************************************************
*Step 0. Load the persons analytic do file and keep only records for children
*        under 24 months whose caregiver completed Module 5, Children's nutrition.
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear

keep if cage_months_int<24 & v500r==1

********************************************************************************
*INDICATOR 1: EXCLUSIVE BREASTFEEDING (0-5 MONTHS)
********************************************************************************

*Step 1: Create a binary variable that flags children 0-5 months of age who were 
*        breastfed during the day and night preceding the survey (chn_bf). This 
*        includes being breastfed by the mother or by another woman (v521); or 
*        receiving breastmilk in a spoon, cup, or bottle (v522); or being 
*        breastfed by another woman. 
gen 	chn_bf=.
replace chn_bf=0 if c0_5m==1
replace chn_bf=1 if (v521==1 | v522==1) & c0_5m==1
la val 	chn_bf YESNO
la var 	chn_bf "Child consumed breastmilk"
tab chn_bf 

*Step 2:  Create a binary variable that flags children 0-5 months of age who 
*         received any milk other than breastmilk (chn_othermilk). This includes 
*         formula (v527); milk, such as tinned, powdered, or fresh animal milk 
*         (v529); or yogurt, including yogurt drinks (v533) and other yogurt (v534a).
gen 	chn_othermilk=.
replace chn_othermilk=0 if c0_5m==1
replace chn_othermilk=1 if (v527==1 | v529==1 | v533==1 | v534a==1) & c0_5m==1
la val 	chn_othermilk YESNO
la var 	chn_othermilk "Child consumed other milk (non-breastmilk)"
tab chn_othermilk 

*Step 3: Create a binary variable that flags children 0-5 months of age who 
*        received plain water (chn_water).
gen 	chn_water=.
replace chn_water=0 if c0_5m==1
replace chn_water=1 if v526==1 & c0_5m==1
la val 	chn_water YESNO
la var 	chn_water "Child consumed plain water"
tab chn_water 

*Step 4: Create a binary variable that flags children 0-5 months of age who 
*        received non-milk liquid (chn_nonmilk). Non-milk liquids include juice or 
*        juice drinks (v531); sugary drinks such as soda pop, sports drinks, or 
*        malt drinks (v531a); clear broth (v532); thin porridge (v535); and other
*        water-based liquids, such as glucose water or sugar water (v536, v537).
gen 	chn_nonmilk=.
replace chn_nonmilk=0 if c0_5m==1
replace chn_nonmilk=1 if (v531==1 | v531a==1 | v532==1 | v535==1 | v536==1 | v537==1) & c0_5m==1
la val 	chn_nonmilk YESNO
la var 	chn_nonmilk "Child consumed non-milk liquid"
tab chn_nonmilk 

***Step 5: Create a variable for whether children 0-5 months of age received any 
*          food (chn_food).
*SA: added v560, previously the range stopped at v559 although v560 was included in step 6
gen 	chn_food=.
replace chn_food=0 if c0_5m==1
replace chn_food=1 if (v539==1 | v540==1 | v541==1  | v541a==1 | v542==1 | v543==1 | ///
				          v544==1 | v545==1  | v546==1 | v547==1  | v548==1 | v549==1 | ///
				          v550==1 | v551==1  | v552==1 | v553==1  | v554==1 | v555==1 | ///
				          v556==1 | v557==1  | v558==1 | v559==1 | v560==1) & c0_5m==1
la val 	chn_food YESNO
la var 	chn_food "Child consumed any chn_food (non-liquid)"
tab chn_food

*Step 6: Create variable to flag children who are missing all data about food and 
*        drink, excluding breast milk.

*Step 6.1: Check distributions of feeding variables and recode missing and DK's to "no"
*          Treat DKs and missing as "no"; assume not given
foreach var of varlist v526 v527 v529 v531 v531a v532 v533 v534a v535 v536 v537 v539-v560 {
  recode `var' 2 8=0 9=., gen(`var'x) 
  la val `var'x YESNO
}
sum v526x v527x v529x v531x v531ax v532x v533x v534ax v535x v536x v537x v539x-v560x

*Step 6.2: Create a variable that counts the number of recoded food variables 
*          created in Step 6.1 that are missing for children 0-5 months (chn_num_ebf_miss). 
egen 	chn_num_ebf_miss=rowmiss(v526x v527x v529x v531x v531ax v532x v533x v534ax v535x v536x v537x v539x-v560x)
replace chn_num_ebf_miss=. if c0_5m!=1
la var 	chn_num_ebf_miss "Child 0-5 months, number of food/drink variables missing value"
tab 	chn_num_ebf_miss

*Step 6.3: Create a variable that flags whether a child 0-5 months is missing all food 
*          variables (chn_miss)—that is, if the value of chn_num_ebf_miss is less 
*          than the number of variables being summed (34 in the template syntax). 
gen 	chn_ebf_miss=.
replace chn_ebf_miss=0 if chn_num_ebf_miss<34 & c0_5m==1
replace chn_ebf_miss=1 if chn_num_ebf_miss==34 & c0_5m==1
la val	chn_ebf_miss YESNO
la var 	chn_ebf_miss "Child 0-5 months is missing all food and drink data"
tab chn_ebf_miss 

*Step 7: Create a binary variable that flags children 0-5 months of age who were 
*        exclusively breastfed (chn_ebf). 
gen     chn_ebf=.
replace chn_ebf=0 if c0_5m==1
replace chn_ebf=1 if chn_bf==1 & chn_water==0 & chn_othermilk==0 & chn_nonmilk==0 & chn_food==0 & c0_5m==1
replace chn_ebf=. if chn_ebf_miss==1 & c0_5m==1
la val 	chn_ebf YESNO
la var 	chn_ebf "Child 0-5 months was exclusively breastfed"
tab 	chn_ebf

*Step 8. Create a variable that captures the sub-population being examined for 
*        the breastfeeding indicator calculation—that is, children 0-5 months of 
*        age who are de facto HH members among all children 0-5 months of age 
*        surveyed (hhmem_c05m_df).
gen 	hhmem_c05m_df=.
replace hhmem_c05m_df=0 if c0_5m==1
replace hhmem_c05m_df=1 if c0_5m==1 & hhmem_df==1
la var 	hhmem_c05m_df "Child 0-5 months is a de facto HH member"
la val 	hhmem_c05m_df YESNO

*Step 9. Apply the children 0-5 month weight (wgt_c0_5m) and calculate the 
*        percentage of children 0-5 months of age who are de facto household 
*        members who were exclusively breastfed using chn_ebf. Repeat using the 
*        child's sex, wealth quintile, and shock exposure severity disaggregates.
svyset hhea [pw=wgt_c0_5m], strata(strata) 
svy, subpop(hhmem_c05m_df): tab chn_ebf, perc format(%6.1f)
svy, subpop(hhmem_c05m_df): tab chn_ebf sex, col perc format(%6.1f)
svy, subpop(hhmem_c05m_df): tab chn_ebf awiquint, col perc format(%6.1f)
svy, subpop(hhmem_c05m_df): tab chn_ebf shock_sev, col perc format(%6.1f)

********************************************************************************
*INDICATOR 2: MINIMUM ACCEPTABLE DIET (6-23 MONTHS)
********************************************************************************

*Step 1: Create a breastfeeding status variable that indicates whether children 
*        6-23 months of age breastfed during the day and night preceding the 
*        survey (bf_stat).
gen bf_stat=.
replace bf_stat=0 if c6_23m==1
replace bf_stat=1 if (v521==1 | v522==1) & c6_23m==1
lab val bf_stat YESNO
lab var bf_stat "Child is currently breastfeeding"
tab bf_stat

*Step 2: Identify the variables associated with the 8 food groups used to 
*        calculate children's dietary diversity score in the data file. Pay 
*        particular attention if the questionnaire was adapted to include local 
*        foods to ensure that they are assigned to the appropriate food group 
*        and that those variables are included in the analysis. Table 19 in the 
*        Guide to FTF Midline Statistics lists the food groups and their 
*        corresponding variables in the core ZOI Midline Survey questionnaire. 
*        Questionnaire customization may also have resulted in changes in the 
*        numbering of the questions in the questionnaire, so the variable 
*        numbering in Table 19 should also be reviewed for any needed adjustment.


*Step 3: Create the variables for the eight food groups (foodgrp1-foodgrp8).


*Step 3.1: Create a variable to flag children 6-23 months of age who ate grains, 
*          roots, or tubers (foodgrp1).
gen     chn_foodgrp1=0 if c6_23m==1
replace chn_foodgrp1=1 if (v535==1 | v539==1 | v541==1 | v541a==1) & c6_23m==1
la val  chn_foodgrp1 YESNO
la var 	chn_foodgrp1 "Child 6-23 months ate grains, roots, tubers"
tab chn_foodgrp1

*Step 3.2: Create a variable to flag children 6-23 months of age who ate pulses 
*          (peas, beans, and lentils), nuts, and seeds (chn_foodgrp2).
gen     chn_foodgrp2=0 if c6_23m==1
replace chn_foodgrp2=1 if (v552==1 | v553==1) & c6_23m==1		
la val  chn_foodgrp2 YESNO
la var 	chn_foodgrp2 "Child 6-23 months ate ate legumes, nuts"
tab chn_foodgrp2

*Step 3.3. Create a variable to flag children 6-23 months of age who ate 
*          dairy products (chn_foodgrp3).
gen     chn_foodgrp3=0 if c6_23m==1
replace chn_foodgrp3=1 if (v527==1 | v529==1 | v533==1 | v554==1 | v534a==1) & c6_23m==1
la val  chn_foodgrp3 YESNO
la var 	chn_foodgrp3 "Child 6-23 months ate dairy products"
tab chn_foodgrp3

*Step 3.4: Create a variable to flag children 6-23 months of age who ate flesh 
*          foods (chn_foodgrp4)
gen     chn_foodgrp4=0 if c6_23m==1
replace chn_foodgrp4=1 if (v546==1 | v547==1 | v548==1 | v549==1 | v551==1) & c6_23m==1	
la val  chn_foodgrp4 YESNO
la var 	chn_foodgrp4 "Child 6-23 months ate flesh foods"
tab chn_foodgrp4

*Step 3.5: Create a variable to flag children 6-23 months of age who ate eggs (chn_foodgrp5).
gen     chn_foodgrp5=0 if c6_23m==1
replace chn_foodgrp5=1 if (v550==1) & c6_23m==1
la val  chn_foodgrp5 YESNO
la var 	chn_foodgrp5 "Child 6-23 months ate eggs"
tab chn_foodgrp5

*Step 3.6: Create a variable to flag children 6-23 months of age who ate 
*          vitamin A-rich fruits or vegetables (chn_foodgrp6).
gen     chn_foodgrp6=0 if c6_23m==1
replace chn_foodgrp6=1 if (v540==1 | v542 ==1 | v544==1 | v559==1) & c6_23m==1
la val  chn_foodgrp6 YESNO
la var 	chn_foodgrp6 "Child 6-23 months ate vitamin A rich fruits and vegetables"
tab chn_foodgrp6

*Step 3.7: Create a variable to flag children 6-23 months of age who ate other 
*          (i.e., not vitamin A-rich) fruits or vegetables (chn_foodgrp7).
gen     chn_foodgrp7=0 if c6_23m==1
replace chn_foodgrp7=1 if (v543==1 | v545==1) & c6_23m==1
la val  chn_foodgrp7 YESNO
la var 	chn_foodgrp7 "Child 6-23 months ate other fruits and vegetables"
tab chn_foodgrp7

*Step 3.8: Create a variable to flag children 6-23 months of age who consumed 
*          breastmilk (chn_foodgrp8).
gen 	chn_foodgrp8=bf_stat 
la val  chn_foodgrp8 YESNO
la var  chn_foodgrp8 "Child 6-23 months consumed breastmilk"
tab chn_foodgrp8

*Step 4: Create a binary variable that flags children 6-23 months of age who are 
*        missing data for all food and drink variables, excluding breastmilk 
*        (chn_mad_miss). 

*Step 4.1: Create variables that recode `no' responses that have a value of `2' 
*          to be `0' and `don't know' (8) and missing (9) responses are set to 
*          blank (missing) if they do not already exist in the data file. 
foreach var of varlist v526 v527 v529 v531 v531a v532 v533 v534a v535 v536 v537 v539-v560 {
  recode `var' 2 8=0 9=., gen(`var'x) 
  la val `var'x YESNO
}
sum v526x v527x v529x v531x v531ax v532x v533x v534ax v535x v536x v537x v539x-v560x

*Step 4.2: Create a variable that counts the number of recoded food variables 
*          created in Step 4.1 that are missing for children 6-23 months (chn_num_mad_miss). 
egen 	chn_num_mad_miss=rowmiss(v526x v527x v529x v531x v531ax v532x v533x v534ax v535x v536x v537x v539x-v560x)
replace chn_num_mad_miss=. if c6_23m!=1
la var 	chn_num_mad_miss "Child 6-23 months, number of food/drink variables missing value"
tab 	chn_num_mad_miss

*Step 4.3: Create a variable that flags whether a child 6-23 months is missing all food 
*          variables (chn_mad_miss)—that is, if the value of chn_num_mad_miss is less 
*          than the number of variables being summed (34 in the template syntax). 
gen 	chn_mad_miss=.
replace chn_mad_miss=0 if chn_num_mad_miss<34 & c6_23m==1
replace chn_mad_miss=1 if chn_num_mad_miss==34 & c6_23m==1
la val	chn_mad_miss YESNO
la var 	chn_mad_miss "Child 6-23 months is missing all food and drink data"
tab chn_mad_miss 

*Step 5: Create a variable that sums the number of food groups that children 
*        6-23 months of age consumed (chn_foodsum).
egen 	chn_foodsum=rowtotal(chn_foodgrp*)
la var 	chn_foodsum "Child 6-23 months, number of food groups consumed"
tab chn_foodsum 

*Step 6: Create a variable that flags children 6-23 months of age who meet the 
*        minimum dietary diversity threshold (chn_mmd)—that is, they consumed at 
*        least five of the eight specified food groups. 
recode 	chn_foodsum (1/4=0) (5/8=1), gen(chn_mdd) 
replace chn_mdd=. if c6_23m!=1
la val	chn_mdd YESNO
la var 	chn_mdd "Child 6-23 months meets minimum dietary diversity (MDD) criteria"

*Step 7: Create a variable that flags children 6-23 months of age who achieve
*        minimum feeding frequency (chn_mff).
 
*Step 7.1: Create analytic variables that can be used to create chn_mff (v528x,
*          v530x, v534x, v534bx, and v563x). For v528, v530, v534, and v534b, 
*          recode "don't know" responses (98) and missing responses (99) to zero 
*          (0) under the assumption that children had no milk feeds. For v563, if 
*          v562 is "no" (2), "don't know" (8), or "missing" (9), or if v563 is 
*          "don't know" (98) or "missing" (99), recode v563 to zero (0) under
*          the assumption that children did not eat any solid, semi-solid, or 
*          soft foods.
*to check data
sum v528 v530 v534 v534b v563 
foreach var in v528 v530 v534 v534b v563 {
  recode `var' 98 99=0, gen(`var'x)		
}
replace v563x=0 if v562==2 | v562==8 | v562==9
sum v528x v530x v534x v534bx v563x
                 
*Step 7.2: Create a variable that counts the total number of feeds, including 
*          milk feeds plus soft, solid, or semi-solid food feeds that children 
*          6-23 months of age received (chn_mfreq_milkplus). 
egen   chn_mfreq_milkplus= rowtotal(v528x v530x v534x v563x)
la var chn_mfreq_milkplus "Child 6-23 months, number of feeds (milk+food)"
tab chn_mfreq_milkplus 

*Step 7.3: Create variables that categorize children 6-23 months of age by age 
*          and breastfeeding status. 

*Step 7.3.1: First create a variable that flags children 6-8 months of age 
*            (c6_8m) and then create a variable that flags breastfed children 
*            6-8 months of age (chn_bf_grp1).
gen		c6_8m=0
replace	c6_8m=1 if cage_months_int>=6 & cage_months_int<=8
*replace c6_8m=1 if v104a>=6 & v104a<=8 & c6_8m==0
la val	c6_8m YESNO
la var	c6_8m "Child is 6-8 months"


gen 	chn_bf_grp1=0
replace chn_bf_grp1=1 if bf_stat==1 & c6_8m==1 
la var 	chn_bf_grp1 "Child 6-8 months, breastfeeds"

*Step 7.3.2: First create a variable that flags children 9-23 months of age (c9_23m) 
*            and then create a variable that flags breastfed children 9-23 
*            months of age (chn_bf_grp2).
gen		c9_23m=0
replace	c9_23m=1 if cage_months_int>=9 & cage_months_int<=23
replace c9_23m=1 if ((v104a>=9 & v104a<=12) | v104==1) & c9_23m==0
la val	c9_23m YESNO
la var	c9_23m "Child is 9-23 months"

gen 	chn_bf_grp2=0
replace chn_bf_grp2=1 if bf_stat==1 & c9_23m==1
la var 	chn_bf_grp2 "Child 9-23 months, breastfeeds"

*Step 7.3.3: Create a variable that flags non-breastfed children 6-23 months of 
*            age (chn_bf_grp3). 
gen 	chn_bf_grp3=0
replace chn_bf_grp3=1 if bf_stat==0 & c6_23m==1 
la var 	chn_bf_grp3 "Child 6-23 months, does not breastfeed"

tab1 chn_bf_grp*

*Step 7.4: Create a binary variable that flags children 6-23 months of age who 
*          received the minimum meal frequency based on their age and 
*          breastfeeding status (chn_mmf).
*KZ: Updated 6/25 to remove mmfF for non-breastfed children 
gen     chn_mmf=0 if c6_23m==1  
replace chn_mmf=1 if chn_bf_grp1==1 & v563x>=2 & v563x!=.
replace chn_mmf=1 if chn_bf_grp2==1 & v563x>=3 & v563x!=.
replace chn_mmf=1 if chn_bf_grp3==1 & chn_mfreq_milkplus>=4 & chn_mfreq_milkplus!=. & ///
								      v563x>=1 & v563x!=.
replace chn_mmf=. if chn_mad_miss==1
la val 	chn_mmf YESNO
la var 	chn_mmf "Child 6-23 months meets minimum meal frequency (mmf) criteria"
tab chn_mmf

*Step 7.5: Create a variable that counts the total number of milk feeds 
*          non-breastfed children 6-23 months of age received (chn_nbf_milk). 
egen 	chn_nonbf_milk=rowtotal(v528x v530x v534x v534bx) if chn_bf_grp3==1
la val  chn_nonbf_milk "Non-breastfed child 6-23 months, number of milk feeds"

*Step 7.6: Create a variable (chn_mmff) that flags non-breastfed children 6-23 
*          months of age who received minimum milk feeding frequency—that is, 
*		   they received at least two milk feeds. 
gen     chn_mmff=0 if chn_bf_grp3==1
replace chn_mmff=1 if chn_nonbf_milk>=2 & chn_nonbf_milk!=. & chn_bf_grp3==1
replace chn_mmff=. if chn_mad_miss==1
la val  chn_mmff YESNO
la var  chn_mmff "Non-breastfed child 6-23 months meets minimum milk feeding frequency (MMFF)"

*Step 8: Create a binary variable (chn_mad) that flags children 6-23 months of 
*        age who received a minimum acceptable diet—that is, they achieved both 
*        minimum dietary diversity and minimum meal frequency given their age 
*        and breastfeeding status.
gen     chn_mad=0 if c6_23m==1 
replace chn_mad=1 if chn_mdd==1 & chn_mmf==1 & (chn_bf_grp1==1 | chn_bf_grp2==1)  
replace chn_mad=1 if chn_mdd==1 & chn_mmf==1 & chn_mmff==1 & chn_bf_grp3==1
replace chn_mad=. if chn_mad_miss==1
la value chn_mad YESNO
la var chn_mad "Child 6-23 months meets minimum acceptable diet (MAD) criteria"
tab chn_mad 

*Step 9: Create a variable that captures the sub-population being examined for 
*        the minimum acceptable diet indicator calculation—that is, children 
*        6-23 months of age who are de facto HH members among all children 6-23 
*        months of age surveyed (hhmem_c623m_df).
gen 	hhmem_c623m_df=.
replace hhmem_c623m_df=0 if c6_23m==1
replace hhmem_c623m_df=1 if c6_23m==1 & hhmem_df==1
la val 	hhmem_c623m_df YESNO
la var  hhmem_c623m_df "Child 6-23 months is a de facto HH member"
tab hhmem_c623m_df

*Step 10: After applying the children 6-23 months weight (wgt_c6_23m), calculate 
*         the percentage of children 6-23 months of age who are de facto HH 
*         members who received a minimum acceptable diet using chn_mad. Repeat 
*         using the child's sex, child's age, gendered household type, wealth 
*         index, and shock exposure severity disaggregates. 
svyset hhea [pw=wgt_c6_23m], strata(strata)
svy, subpop(hhmem_c623m_df): tab chn_mad 
svy, subpop(hhmem_c623m_df): tab chn_mad sex, col perc format(%6.1f)
svy, subpop(hhmem_c623m_df): tab chn_mad chn_age, col perc format(%6.1f)
svy, subpop(hhmem_c623m_df): tab chn_mad genhhtype_dj, col perc format(%6.1f)
svy, subpop(hhmem_c623m_df): tab chn_mad awiquint, col perc format(%6.1f)
svy, subpop(hhmem_c623m_df): tab chn_mad shock_sev, col perc format(%6.1f)

*Keep variables that will be added to the final post-analysis data file
*and save the data file.
*SA: updated to keep computed indicators. 
keep hhea hhnum m1_line wgt_c0_5m wgt_c6_23m strata bf* chn* hhmem_c05m_df hhmem_c623m_df c6_23m c0_5m
sort  hhea hhnum
save  "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] chn diet.dta",replace

di "Date:$S_DATE $S_TIME"
log  close