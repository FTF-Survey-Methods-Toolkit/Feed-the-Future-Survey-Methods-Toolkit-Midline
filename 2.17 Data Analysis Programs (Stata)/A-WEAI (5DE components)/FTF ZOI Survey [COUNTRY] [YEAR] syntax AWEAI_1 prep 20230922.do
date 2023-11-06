/*******************************************************************************
***************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ***************
********************** 5DE CALCULATIONS, A-WEAI INDICATORS *********************
****************************** [COUNTRY] [YEAR] ********************************
********************************************************************************

Description:

This syntax is used to create the 5 domains of empowerment (5DE) indicators used 
to calculate the Abbreviated Women's Empowerment in Agriculture Index (A-WEAI)  
for Feed the Future Phase Two Zone of Influence (P2-ZOI) Midline Surveys.

This file is an adaptation of the 2020 A-WEAI data prep file prepared by Ana Vaz
and Sabina Alkire at www.ophi.org.uk and found on the WEAI Resource Center 
website, hosted by IFPRI. 
https://weai.ifpri.info/files/2020/05/Dataprep-and-AWEAI-calculation-files.zip

More information about the A-WEAI calculation can be found here:
https://www.ifpri.org/sites/default/files/a-weai_instructional_guide_final.pdf

The file has been adapted by Feed the Future for use with the P2-ZOI Midline 
Survey data. All variables are named in accordance with the core P2-ZOI Midline 
Survey CS-Pro data collection program and codebook. Additional explanatory notes 
are added to faciliate implementation of the syntax.

For P2-ZOI Midline Surveys, the A-WEAI cannot be calculated because data are 
collected only from primary adult female decision-makers. Data from primary adult
male decision-makers are collected only at baseline and endline. For P2-ZOI 
Midline Surveys, results related to the 5DE component of the A-WEAI are 
calculated.

Two files are needed to produce the 5DE results at midline that are included in 
the P2-ZOI Midline Survey reports:

	1. Data preparation (current file): 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_1 prep.do
	2. 5DE-related calculations: 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_2 5DEcalc.do

A third file can be used to compare 5DE results between baseline and midline and 
generate the results that are reported in the results tables of Chapter 6 of the
midline indicator assessment report template:

	3. Midline/baseline comparative results:
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_3 ML_BL_compare.do
	   
This data prep file includes syntax to:

	A. Check for data quality 
	   (frequency distribution, missing cases, out-of-range values, skip patterns)
	B. Calculate the six A-WEAI indicators of achievement

This file can be used to create the A-WEAI indicators at baseline, but care must
be taken to update the variable names to align with the baseline data (e.g., if 
Variables have different names or value sets).

Syntax updated from baseline syntax by ICF, 2022/2023 

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 12.3, Part 1 of the Guide to Feed the Future 
Midline Statistics.

This syntax file was developed using the core Feed the Future P2-ZOI Midline 
Survey questionnaire. It must be adapted for the final country-specific 
questionnaire; therefore, double-check all results carefully and troubleshoot to 
resolve any issues identified. 
*******************************************************************************/
*Specify local drive and folders in which inputs and outputs are stored.

//DIRECTORY PATH
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"
cd "$analytic"

//Input data:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] aweai prep.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] aweai prep.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax AWEAI_1 prep.do 

capture log close
clear all
set more off

*Specify folder in which log files are stored.
log using "$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] aweai prep.log", text replace

set mem 100m 

*Step 1.1: Load, review and prepare the data.
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic", clear

*Keep records for only respondents who completed Module 6 and are de jure HH members 
drop if v6605!=1
drop if fdm_dj!=1

********************************************************************************
* Uses data from Module 6
* Variables are recoded to create 6 indicators of achievement in 5 domains of
*   empowerment for the 5DE score:
	*1. Decision-making over production (Production domain)
	*2. Access to resources (Resources domain)
	*3. Access to and decision-making over credit (Resources domain)
	*4. Control over income (Income domain)
	*5. Group participation (Leadership domain)
	*6. Workload (Time domain)
* Indicators are dichotomized and coded 0 (respondent is not have adequate 
* achievement in the indicator) or 1 (respondent has adequate achievement in the 
* indicator.)

********************************************************************************
*DOMAIN 1: PRODUCTION 
********************************************************************************
*This domain has one indicator:
	**Indicator 1.1 (A-WEAI indicator 1): Input in productive decisions

********************************************************************************
**# A-WEAI 1ndicator 1. Input in productive decisions **************************
********************************************************************************
*Adequate achievement if respondent has at least some decisionmaking power 
*i.e. if respondent: (1) decides alone (v6202=A); (2) reports input into some, 
*     most or all decisions (v6203=2 or 3); or (3) reports ability to make 
*     discisions, if desired, to a medium or high extent (v6204=3 or 4)
*Individuals who do not participate in an activity or who report not applicable 
*(v6202==X) or no decision made (v6203==93) are excluded.

*Only activities 1, 2, 3, and 6 are used to calculate the indicator for 
*this domain; however, all activities are checked and analytic variables are
*created for them because these variables are used in the domain 3 indicator 
*calculations.

*Step 1.1. Review and prepare the data. 

*Step 1.1A: Check frequency distribution and number of missing cases.
sum v6201* v6203* v6204*
tab1 v6201* v6202* v6203* v6204*

*Step 1.1B: Check skip patterns are correct - if the respondent did not participate 
*in the activity s/he should not have a response for v6202 v6203 v6204. 
*Note: activities 7 and 8 not included because v6201 doesn't exist for them.
foreach x in 1 2 3 4 5 6 {
  tab v6202_`x' v6201_`x',m
  tab v6203_`x' v6201_`x',m
  tab v6204_`x' v6201_`x',m
}

*Also check who usually makes the decisions for each activity (v6202a); if the 
*respondent is usually the sole decision-maker for an activity, they should not 
*have a response for v6203 and v6204.
foreach x in 1 2 3 4 5 6 7 8 {
  tab v6203_`x' v6204_`x' if v6202aa_`x'==1
  tab v6203_`x' v6204_`x' if v6202aa_`x'!=1
}

*Step 1.1C: Create new variables for v6201, v6203, and v6204 that set missing, not 
*applicable, and no decision made responses (i.e., 9, 93, and 99) to missing 
*(v6201_1x-v6201_6x, v6203_1x-v6203_6x, and v6204_1x-v6204_6x). 
for var v6201_* v6204_*: recode X (9=.), gen(Xx)
for var v6203_*: recode X (99 93=.), gen(Xx)

*Step 1.1D: Create analytic variables v6201_7x and v6201_8x. Set the variables equal 
*to 1 for all respondents who have data for the corresponding v6202 variable. 
*Variables v6201_7 and v6201_8 do not exist in the data file so the corresponding 
*analytic variables could not be generated as v6201_1x-v62016x were in the 
*previous step, but the variables created in this step are needed for a later step.
foreach x in 7 8 {
  replace v6201_`x'x=1 if v6202_`x'!="" 
}

*Step 1.2: Generate binary variables indicating participation in economic activities.
*--Variable=1 if respondent participated in activity.
*--Variable=0 if respondent did not participate in activity.
*--Variable=missing if v6201=missing for activity. 
foreach x in 1 2 3 4 5 6 7 8 {
  gen partact_`x'=(v6201_`x'x==1)
  replace partact_`x'=. if v6201_`x'x==.
  la val partact_`x' YESNO
} 	

la var partact_1 "Food crop farming: participated, past 12 months"
la var partact_2 "Cash crop farming: participated, past 12 months"
la var partact_3 "Raising livestock: participated, past 12 months"
la var partact_4 "Non-farm: participated, past 12 months"
la var partact_5 "Wage or salary: participated, past 12 months"
la var partact_6 "Fishing or fishpond: participated, past 12 months"
la var partact_7 "Major HH expenditures: participated, past 12 months"
la var partact_8 "Minor HH expenditures: participated, past 12 months"

tab1 partact_*
sum partact_*

*Step 1.3. Generate a count variable=number of activities respondent partakes in (0-8).
*--Variable=missing if respondent is missing values for all 8 partact variables.
egen partact=rowtotal(partact_*), missing 
label var partact "Number of productive activities participated in"
tab partact

*Step 1.4. Generate a count variable=number of ag activities respondent partakes in (0-4).
*--Variable=missing if respondent is missing values for all 4 partact variables.
egen partactagr=rowtotal(partact_1 partact_2 partact_3 partact_6), missing
label var partactagr "Number of productive ag activities participated in"
tab partactagr

*Step 1.5: Generate binary variables for each activity indicating if respondent has 
*       adequate participation in decisionmaking.
*--Variable=1 if respondent makes decisions alone or has input into some/most/all 
*             decisions for activity.
*--Variable=0 if respondent does not make decisions alone and does not have input 
*             into some/most/all decisions for activity.
*--Variable=. if respondent does not participate in activity, or participates 
*             in activity but no decisions were made or is missing input into 
*             decision-making information (v6202, v6203) for activity.
foreach x in 1 2 3 4 5 6 7 8 {
  gen inputdec_`x'=1 if (v6202aa_`x'==1 | v6203_`x'x==2 | v6203_`x'x==3) & partact_`x'==1
  replace inputdec_`x'=0 if v6202aa_`x'==2 & v6203_`x'x!=2 & v6203_`x'x!=3 & partact_`x'==1 
  replace inputdec_`x'=. if (v6202aa_`x'==. | (v6202aa_`x'==2 & v6203_`x'x==.)) & partact_`x'==1 
  replace inputdec_`x'=. if partact_`x'!=1 
  la val inputdec_`x' YESNO
}

la var inputdec_1 "Food crop farming: Has input into at least some decisions"
la var inputdec_2 "Cash crop farming: Has input into at least some decisions"
la var inputdec_3 "Livestock raising: Has input into at least some decisions"
la var inputdec_4 "Non-farm: Has input into at least some decisions"
la var inputdec_5 "Wage or salary: Has input into at least some decisions"
la var inputdec_6 "Fshing or fishpond: Has input into at least some decisions"
la var inputdec_7 "Major HH expenditures: Has input into at least some decisions"
la var inputdec_8 "Minor HH expenses: Has input into at least some decisions"

tab1 inputdec_*
sum inputdec_*

*Step 1.6: Generate binary variables for each activity indicating if respondent 
*       feels he/she has decisionmaking power
*--Variable=1 if respondent makes decisions alone or feels they can to a medium 
*             or high extent for activity.
*--Variable=0 if respondent does not make decisions alone and does not feel they 
*             can to a medium or high extent for activity.
*--Variable=. if respondent does not participate in activity, or participates in 
*             activity but is missing decision-making information (v6202, v6204) 
*             for activity.
foreach x in 1 2 3 4 5 6 7 8 {
  gen feelmakedec_`x'=1 if (v6202aa_`x'==1 | v6204_`x'x==3 | v6204_`x'x==4) & partact_`x'==1
  replace feelmakedec_`x'=0 if (v6202aa_`x'==2 & v6204_`x'x!=3 & v6204_`x'x!=4) & partact_`x'==1 
  replace feelmakedec_`x'=. if (v6202aa_`x'==. | (v6202aa_`x'==2 & v6204_`x'x==.)) & partact_`x'==1 
  replace feelmakedec_`x'=. if partact_`x'!=1 
  la val feelmakedec_`x' YESNO
}

label var feelmakedec_1 "Food crop farming: Feels can make descisions to at least medium extent"
label var feelmakedec_2 "Cash crop farming: Feels can make descisions to at least medium extent"
label var feelmakedec_3 "Livestock raising: Feels can make descisions to at least medium extent"
label var feelmakedec_4 "Non-farm activity: Feels can make descisions to at least medium extent"
label var feelmakedec_5 "Wage or salary: Feels can make descisions to at least medium extent"
label var feelmakedec_6 "Fishing or fishpond: Feels can make descisions to at least medium extent"
label var feelmakedec_7 "Major HH expenses: Feels can make descisions to at least medium extent"
label var feelmakedec_8 "Minor HH expenses: Feels can make descisions to at least medium extent"

tab1 feelmakedec_*
sum feelmakedec_*

*Step 1.7: Create a count variable=number of agriculture economic activities for 
*       which respondents have input into at least some decisions, plus the 
*       number of agriculture economic activities for which respondents feel that 
*        they can make decisions to a medium or high extent if they wanted to. 
*--Variable=. if respondent is missing a value for all 8 component variables.
egen feelinputdecagr_sum=rowtotal(inputdec_1 inputdec_2 inputdec_3 inputdec_6 ///
					     feelmakedec_1 feelmakedec_2 feelmakedec_3 feelmakedec_6), missing 
label var feelinputdecagr_sum "No. of areas makes decisions or feels can, ag activities (0-8)"
tab feelinputdecagr_sum

*Step 1.8. Generate input in decisions indicator indicating if participation in 
*       decisionmaking is adequate.
*INPUT IN PRODUCTIVE DECISIONS: Adequate if respondent scores a 1 or higher out of 8.
*--Variable=1 if respondent participates in 1+ activity and has input into some 
*             decisions for at least one area.
*--Variable=0 if respondent participates in 1+ activity but does not input into 
*             decisions for at least one area.
*--Variable=. if respondent does not have data on any of the 8 areas (i.e., 
*             either  does not participate in any of the activities or is 
*             missing decision-making information for all areas).
gen feelinputdecagr=(feelinputdecagr_sum>=1)
replace feelinputdecagr=. if feelinputdecagr_sum==.
label var feelinputdecagr "Adequate in decision-making, women active in ag (AWEAI indicator 1)"

tab feelinputdecagr

********************************************************************************
******* DOMAIN 2: ACCESS TO AND CONTROL OVER PRODUCTIVE RESOURCES ********
********************************************************************************
*This domain is comprised of 2 indicators:
	*Indicator 2.1 (A-WEAI indicator 2): Ownership of assets
	*Indicator 2.2 (A-WEAI indicator 3): Access to and decisions sover credit
	
********************************************************************************
**# A-WEAI Indicator 2. Ownership of assets ************************************
********************************************************************************
*Adequate if individual owns AT LEAST two small assets (chicken, farming equipment 
*non-mechanized, and small consumer durables) OR one large asset (all the other). 

*Step 2.1: Review and prepare data.

*Step 2.1A: Check frequency distribution and number of missing cases
sum v6301* 
tab1 v6301* v6303*,m 

*Step 2.1B: Check skip patterns are correct - if a household did not own an asset, 
*the respondent should not have a response for v6303.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 {
  tab v6303_`x' v6301_`x',m
}

*Step 2.1C: Create analytic variables with No responses (i.e., 2) recoded to 0 and 
*        missing responses (i.e., 9) recoded to missing (.). 
for var  v6301_*: recode X (2=0)(9=.), gen(Xx)

*Step 2.2: Generate binary variables indicating if household owns each asset.
*--Variable=1 if HH owns asset.
*--Variable=0 if HH does not own asset.
*--Variable=. if HH is missing a value for v6301 for item.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 {
  gen own_`x'=v6301_`x'x==1 
  replace own_`x'=. if v6301_`x'x==. 
  la val own_`x' YESNO
}
	
la var own_01 "HH owns agricultural land"
la var own_02 "HH owns large livestock"
la var own_03 "HH owns small livestock"
la var own_04 "HH owns chickens, ducks, turkeys, pigeons"
la var own_05 "HH owns fishpond or fishing equipment"
la var own_06 "HH owns hand tools"
la var own_07 "HH owns farm equipment (non-mechanized)"
la var own_08 "HH owns farm equipment (mechanized)"
la var own_09 "HH owns nonfarm business equipment"
la var own_10 "HH owns house (or other structures)"
la var own_11 "HH owns large consumer durables (fridge, TV)"
la var own_12 "HH owns small consumer durables (radio, cookware)"
la var own_13 "HH owns cell phone"
la var own_14 "HH owns nonagricultural land"
la var own_15 "HH owns means of transportation"

sum own_*

*Step 2.3a: Generate a count variable=number of types of assets HHs own (0-15).
*--Variable=missing if respondent's HH is missing values for all 15 assets.
egen own_sum=rowtotal(own_01-own_15), missing
la var own_sum "No. of asset types household owns (0-15)"
tab own_sum

*Step 2.3b: Generate a count variable=number of types of agricultural assets HHs own (0-8).
*--Variable=missing if respondent's HH is missing values for all 8 ag assets.
egen ownagr_sum=rowtotal(own_01-own_08), missing
la var ownagr_sum "No. of agricultural asset types HH owns (0-8)"
tab ownagr_sum

*Step 2.4: Generate binary variables for each asset indicating if respondent owns 
*       the asset alone or jointly.
*--Variable=1 if respondent owns asset alone or jointly.
*--Variable=0 if HH owns asset but respondent does not own asset alone or jointly.
*--Variable=. if HH does not own asset, or HH owns asset but missing information 
*             on who owns the asset.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 {
  gen selfjointown_`x'=(strpos(v6303_`x',"A")>0) if own_`x'==1 
  replace selfjointown_`x'=. if own_`x'!=1 | ((v6303_`x'=="" | v6303_`x'=="?") & own_`x'==1)
  la val selfjointown_`x' YESNO
}

**Create labels for new vars
la var selfjointown_01 "Owns alone or jointly agricultural land"
la var selfjointown_02 "Owns alone or jointly large livestock"
la var selfjointown_03 "Owns alone or jointly small livestock"
la var selfjointown_04 "Owns alone or jointly chickens, turkeys, ducks"
la var selfjointown_05 "Owns alone or jointly fishpond or fishing equipment"
la var selfjointown_06 "Owns alone or jointly hand tools"
la var selfjointown_07 "Owns alone or jointly farm equipment (non-mechanized)"
la var selfjointown_08 "Owns alone or jointly farm equipment (mechanized)"
la var selfjointown_09 "Owns alone or jointly non-farm business equipment"
la var selfjointown_10 "Owns alone or jointly the house (or other structures)"
la var selfjointown_11 "Owns alone or jointly large consumer durables"
la var selfjointown_12 "Owns alone or jointly small consumer durables"
la var selfjointown_13 "Owns alone or jointly cell phone"
la var selfjointown_14 "Owns alone or jointly non-agricultural land"
la var selfjointown_15 "Owns alone or jointly means of transportation"

tab1 selfjointown_*
sum selfjointown_*

*Step 2.5: Generate a count variable=number of assets respondent owns alone or jointly.
*--Variable=missing if asset ownership information is missing for all 15 assets.
egen selfjointownsum=rowtotal(selfjointown_*), missing
la var selfjointownsum "No. of assets respondent owns alone or jointly (0-15)"
tab selfjointownsum

*Step 2.6: Generate ownership indicator indicating whether asset ownership is 
*       adequate--that is, whether the respondent owns alone or jointly 1+ large 
*       asset or 2+ small assets.
*--Variable=1 if respondent owns 1+ large asset or 2+ small assets alone or jointly.
*--Variable=0 if HH doesn't own any assets or respondent owns only 1 asset and 
*             that asset is a small asset.
*--Variable=. if data are missing for entire asset ownership sub-module, or HH
*             owns 1+ asset but information re: who owns the asset is missing
*             for all assets owned.
egen jown_count=rowmax(selfjointown_*)
replace jown_count=0 if jown_count==1 & selfjointownsum==1 & (selfjointown_04==1 | ///
                        selfjointown_06==1 | selfjointown_07==1 | selfjointown_12==1)
replace jown_count=0 if own_sum==0
la var jown_count "Owns 1+ large or 2+ small assets alone or jointly"

tab1 selfjointownsum jown_count, m

********************************************************************************
** # A-WEAI Indicator 3. Access to and decisions over credit *******************
********************************************************************************
*Adequate if respondent made decisions alone or joinly regarding AT LEAST ONE 
*of six sources of credit 

*Step 3.1: Review and prepare data.

*Step 3.1A:. Check frequency distribution and missing/don't know cases
sum v6308* 
tab1 v6308* v6309* v6310*,m

*Step 3.1B: Ensure that skip patterns are correct; if the respondent's household 
*did not borrow from the credit source, they should not have responses for v6309 and v6310. 
foreach x in 1 2 3 4 5 6 {
  tab v6308_`x' v6309_`x',m
  tab v6308_`x' v6310_`x',m
}

*Step 3.2: Create binary variables indicating whether HH borrowed from each source of credit.
*--Variable=1 if HH borrowed cash, in-kind, or both cash & in-kind from source.
*--Variable=0 if HH did not borrow from source.
*--Variable=. if HH is missing information for v6308 or if respondent doesn't 
*             know if HH borrowed from source.
foreach x in 1 2 3 4 5 6 {
  gen creditaccess_`x'=(v6308_`x'<4) 
  replace creditaccess_`x'=. if (v6308_`x'==. | v6308_`x'==8 | v6308_`x'==9) 
}

la var creditaccess_1 "HH borrowed from NGO"
la var creditaccess_2 "HH borrowed from informal lender"
la var creditaccess_3 "HH borrowed from formal lender"
la var creditaccess_4 "HH borrowed from friends & relatives"
la var creditaccess_5 "HH borrowed from group based microfinace/VSLAs"
la var creditaccess_6 "HH borrowed from informal savings/credit group"

*Step 3.3: Create a count variable=number of credit sources the HH used.
*--Variable=missing if information is missing for all 5 credit sources.
egen creditaccess=rowtotal(creditaccess_*), missing
la var creditaccess "No. of credit sources that the HH used (0-6)"
tab creditaccess

*Step 3.4: Generate binary variables indicating if respondent participated in decisions:
*       (1) to borrow, (2) how to use money or item borrowed, and (3) either 1 or 2.
*--Variable=1 if HH borrowed from the source and respondent was involved in the 
*             decision to borrow/how to use/either.
*--Variable=0 if HH borrowed from the source but respondent was not involved in 
*             the decision to borrow/how to use/either.
*--Variable=. if HH did not borrow from source, or HH borrowed from source but
*             decisionmaker information is missing, or no decisions were made.
foreach x in 1 2 3 4 5 6 {
  *Self or joint decide to borrow
  gen creditselfjointborrow_`x'=(strpos(v6309_`x',"A")>0) if creditaccess_`x'==1
  replace creditselfjointborrow_`x'=. if (v6309_`x'=="" | v6309_`x'=="X" | v6309_`x'=="?") & creditaccess_`x'==1
  la val creditselfjointborrow_`x' YESNO
  
  *Self or joint decide how to use
  gen creditselfjointuse_`x'=(strpos(v6310_`x',"A")>0) if creditaccess_`x'==1
  replace creditselfjointuse_`x'=. if (v6310_`x'=="" | v6310_`x'=="X" | v6310_`x'=="?") & creditaccess_`x'==1
  la val creditselfjointuse_`x' YESNO

  *Self or joint makes AT LEAST ONE decision regarding credit
  egen creditselfjointanydec_`x'=rowmax(creditselfjointborrow_`x' creditselfjointuse_`x')
  la val creditselfjointanydec_`x' YESNO
}

*Label new variables (borrow, use, any decision)
foreach x in borrow use {
  la var creditselfjoint`x'_1 "Participated in decision to `x' credit from NGO"
  la var creditselfjoint`x'_2 "Participated in decision to `x' credit from informal lender"
  la var creditselfjoint`x'_3 "Participated in decision to `x' credit from formal lender"
  la var creditselfjoint`x'_4 "Participated in decision to `x' credit from friends & relatives"
  la var creditselfjoint`x'_5 "Participated in decision to `x' credit from group-based microfinace/VSLAs"
  la var creditselfjoint`x'_6 "Participated in decision to `x' credit from informal saving/credit group"
}

la var creditselfjointanydec_1 "Participated in 1+ decision about credit from NGO"
la var creditselfjointanydec_2 "Participated in 1+ decision about credit from informal lender"
la var creditselfjointanydec_3 "Participated in 1+ decision about credit from formal lender"
la var creditselfjointanydec_4 "Participated in 1+ decision about credit from friends & relatives"
la var creditselfjointanydec_5 "Participated in 1+ decision about credit from group-based microfinace VSLAs"
la var creditselfjointanydec_6 "Participated in 1+ decision about credit from informal saving/credit group"

sum creditselfjoint*

*Step 3.5: Generate indicator indicating if access to credit is adequate.
*ACCESS TO CREDIT: Adequate if respondent has input to at least one decision about
*                  borrowing or use of borrowed money/item from one lending source.
*--Variable=1 if respondent was involved in any decision (borrow or use) for 1+ 
*             credit source.
*--Variable=0 if HH did not borrow from any source or if HH borrowed from 1+ 
*                source but respondent was not involved in any decisions.
*--Variable=. if data are missing for entire credit access sub-module, or HH
*             used 1+ credit source but either decision-making info for all 
*             sources is missing or no decisions were made for any source.
egen credjanydec_any=rowmax(creditselfjointanydec_*)
replace credjanydec_any=0 if creditaccess==0

la val credjanydec_any YESNO
la var credjanydec_any "Made 1+ decision regarding 1+ source of credit alone or jointly"
tab credjanydec_any

********************************************************************************
*** DOMAIN 3: CONTROL OVER INCOME ******************************************
********************************************************************************
*This domain is comprised of 1 indicator:
	*Indictor 3.1 (A-WEAI indicator 4): Control of use of income

********************************************************************************
**# A-WEAI Indicator 4. Control of use of income *******************************
********************************************************************************
***Control over use of income (Indicator 3)
/*combination of two sub-indicators: 
1) input into decisions about income from ag activities
2) autonomy in non-farm economic activities, salary/wage employment, major and 
   minor HH expenses individuals who do not participate in the activity and 
   report no decision made are excluded*/

*Step 4.1: Review and prepare the data.

*Step 4.1A: Check frequency distribution and number of missing cases.
sum v6205*
tab1 v6205*

*Step 4.1B: Check skip patterns are correct - if the respondent did not participate 
*        in the activity s/he should not have a response for v6205. 
foreach x in 1 2 3 4 5 6 {
  tab v6205_`x' v6201_`x',m
}

*Step 4.1C: Create analtyic variables with missing values (99) and decision not 
*        made values (93) recoded to missing (.).
for var v6205_*: recode X (99 93=.), gen(Xx) 

*Step 4.2: Generate binary variables indicating if respondent had input into 
*       decisions made on use of income from each activity.
*--Variable=1 if respondent participated in activity and decided alone or had 
*             input into some/most/all decisions re: income from activity.
*--Variable=0 if respondent participated in activity but did not decide alone and
*             did not have input into some/most/all decisions re: income from activity.
*--Variable=. if respondent did not participate in activity, or participated in 
*             activity but is missing information about decisions made re: income 
*             from activity.
foreach x in 1 2 3 4 5 6 { 
  gen incomedec_`x'=1 if (v6205_`x'x==2 | v6205_`x'x==3 | v6202aa_`x'==1) & partact_`x'==1
  replace incomedec_`x'=0 if v6205_`x'x!=2 & v6205_`x'x!=3 & v6202aa_`x'==2 & partact_`x'==1 
  replace incomedec_`x'=. if v6205_`x'x==. & v6202aa_`x'==2 & partact_`x'==1 
  replace incomedec_`x'=. if partact_`x'!=1 
  la val incomedec_`x' YESNO
}
	
la var incomedec_1 "Food crop farming: Has input into at least some decisions about income"
la var incomedec_2 "Cash crop farming: Has input into at least some decisions about income"
la var incomedec_3 "Livestock raising: Has input into at least some decisions about income"
la var incomedec_4 "Non-farm: Has input into at least some decisions about income"
la var incomedec_5 "Wage or salary: Has input into at least some decisions about income"
la var incomedec_6 "Fishing or fishpond: Has input into at least some decisions about income"

tab1 incomedec_*
sum incomedec_*

*Step 4.3: Create a variable that counts the number of relevant activities for which 
*       respondents have input into decisions on the use of income or feel they 
*       can make decisions if they wanted. This includes all 6 income activities plus 
*       major and minor HH expenditures, wage/salary employment, and non-farm economic activities.
*--Variable=missing if values are missing for all 10 component variables.
egen incomedec_sum=rowtotal(incomedec_* feelmakedec_4 feelmakedec_5 feelmakedec_7 feelmakedec_8), missing
la var incomedec_sum "No. of areas has income decision-making input/power (0-10)"
tab incomedec_sum

*Step 4.4: Generate indicator indicating if control over income is adequate
*ACCESS CONTROL OVER INCOME: adequate if respondent has input in income decisions 
*                            or feels she/he can make decisions regarding wage, 
*                            as long the only domain in which the individual feels 
*                            that he/she makes decisions IS NOT minor HH expenditures.
*--Variable=1 if respondent participates in at least some income decisions for 
*             at least 1 of 6 economic activities OR feels he/she can make 
*             decisions about 1 of 4 activities AND if meets criteria for only 
*             1 of 10, that 1 activity cannot be minor HH expenditures.
*--Veriable=0 if respondent does not participate in at least some income decisions
*             for any of the 6 economic activities and feels he/she cannot make 
*             decisions about any of the 4 activities OR feels they can make 
*             decisions about only 1 activity--minor HH expenditures.
*--Variable=. if respondent did not participate in any of the activities or if  
*             missing decision-making information for all 10 activities. 
gen incdec_count=(incomedec_sum>0)
replace incdec_count=0 if incdec_count==1 & incomedec_sum==1 & feelmakedec_8==1 
replace incdec_count=. if incomedec_sum==.
la val incdec_count YESNO
la var incdec_count "Has input/power in income decisions AND not only about minor HH expenditures"
tab incdec_count

********************************************************************************
*** DOMAIN 4: LEADERSHIP IN THE COMMUNITY **********************************
********************************************************************************
*This domain is comprised of one indicator:
	*Indicator 4.1 (A-WEAI Indicator 5): Membership in economic of social group
	
********************************************************************************
**# A-WEAI Indicator 5. Group membership ***************************************
********************************************************************************
*Step 5.1: Review and prepare data.

*Step 5.1A: Check frequency distribution and number of missing values
sum v6404* v6405*
tab1 v6404* v6405*,m

*Step 5.1B: Check skip patterns.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 {
  tab v6404_`x' v6405_`x',m
}

*Step 5.2: Create binary variables indicating whether the respondent belongs to 
*       each type of community group. 
*Variable=1 if group exists in community and respondent is an active member.
*Variable=0 if group doesn't exist in community or respondent is not sure if it 
*           exists, or group exists but respondent is not an active member.
*Variable=. if group exists but respondent refused to answer the question
*           about membership or information about respondent's membership is 
*           missing.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 {
  gen groupmember_`x'=(v6405_`x'==1 & v6404_`x'==1)
  replace groupmember_`x'=. if ((v6405_`x'==. | v6405_`x'==7 | v6405_`x'==9) & v6404_`x'==1) 
}
tab1 groupmember_* 
la var groupmember_01 "Ag/animal production group: Active member"
la var groupmember_02 "Water users' group: Active member"
la var groupmember_03 "Forest users' group: Active member"
la var groupmember_04 "Credit/microfinance group: Active member"
la var groupmember_05 "Mutual help/insurance group: Active member"
la var groupmember_06 "Trade/business group: Active member"
la var groupmember_07 "Civic group: Active member"
la var groupmember_08 "Local government group: Active member"
la var groupmember_09 "Religious group: Active member"
la var groupmember_10 "Other women's group: Active member"
la var groupmember_11 "Other group: Active member"

*Step 5.3: Generate indicator indicating if group membership is adequate
*GROUP MEMBERSHIP: Adequate if individual is part of AT LEAST ONE group.
*--Variable=1 if respondent is a member of 1+ group.
*--Variable=0 if respondent is not a member of 1+ group, including cases in 
*             which there are no groups in the community or there is 1+ group
*             but the respondent refused to answer membership question.
*--Variable=. is not possible; must have a 0/1 value unless missing data for 
*             the entire sub-module.
egen groupmember_any=rowmax(groupmember_*)
replace groupmember_any=0 if groupmember_any==.
replace groupmember_any=. if v6605!=1
la val groupmember_any YESNO
la var groupmember_any "Is active member of 1+ group in community"

tab groupmember_any

********************************************************************************
*** DOMAIN 5: TIME USE *****************************************************
********************************************************************************
*This domain is comprised of one indicator:
	*Indicator 5.1/A-WEAI indicator 6: Worklaod

********************************************************************************
**# A-WEAI Indicator 6. Workload ***********************************************
********************************************************************************

** Create time poverty measure ***

*Step 6.1: Review and prepare data. Create a variable equal to the number of 
*       15-minute time increment variables available for each respondent. There
*       should be 96 for all respondents. If there are more than or fewer than
*       96 increments, investigate and determine how to handle these cases.
*       Note that this step does not identify respondents who have missing 
*       values ("?"")--only thoses that are completely missing a response (""). 
*       "?" values are examined in the next step. This is just an initial 
*       screening step.
egen num_time_incr=rownonmiss(v6601p_*), strok
la var num_time_incr "Number of 15-min time increments with data"
tab num_incr 

*Step 6.2: Create a work variable that captures the number of 15-minute increments 
*       spent working. Evaluate only primary activities (secondary activities 
*       are not used for A-WEAI). Activities considered to be work are D-Q. All 
*       others are not considered to be work.
*       NOTE: THERE IS ONE ADDITIONAL RESPONSE OPTION IN THE MIDLINE QUESTIONNAIRE
*       THAT WAS NOT IN THE BASELINE QUESTIONNAIRE. (FETCHING WATER WAS SEPARATED
*       OUT FROM OTHER DOMESTIC WORK.) BE SURE TO FACTOR THIS INTO YOUR ANALYSIS.
gen work=0
foreach x in 15 30 45 60 {
  foreach i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 {
	clonevar v6601p_`x'_`i'x=v6601p_`x'_`i'
	replace v6601p_`x'_`i'x="" if v6601p_`x'_`i'=="?"
    foreach z in D E F G H I J K L M N O P Q R {
      replace work=work+1 if v6601p_`x'_`i'x=="`z'"
	}
  }
}
la var work	"Number of 15-min. increments worked, day preceding survey"
sum work

rep
*Step 6.3: Create variable similar to the one created in Step 6.1 to count the 
*          number of time increments with data (num_avail)—but this time for the 
*          v6601p_`x'_`i'x variables created in the previous step. Set  work to 
*          missing for respondents missing all time increment data. 
*INSTRUCTIONS: If there are women who have at least some time increment data 
*          but who do not have data for all 96 time increments, determine if 
*          work also should be set to missing for them. 

egen num_avail=rownonmiss(v6601p_*x), strok
tab num_avail
replace work=. if num_avail==0

*Step 6.4: Convert total number of 15-minute increments spent working into hours.
gen work_hours=work/4

*Step 6.5: Define the time poverty line to be 10.5 hours per day 
qui gen z105=10.5

*Step 6.6: Create the indicator of adequate achievement in productive/domestic workload. 
*--Variable=1 if respondent spent <=10.5 hours working the day prior to survey.
*--Variable=0 if respondent spent >10.5 hours working the day prior to survey.
*--Variable=. if respondent is missing all time increment data/has a work_hours
*             variable missing a value.
gen npoor_z105=0 if work_hours>z105 & work_hours!=.
replace npoor_z105=1 if work_hours<=z105
la val npoor_z105 YESNO
la var npoor_z105 "Worked 10.5 hours or less day before survey"
tab npoor_z105

*Step 6.X: Not atypical days should be included in the indicator calculation, BUT
*       this step can be added to compare the results for only typical days and
*       to those for both atypical and typical days. 
*replace npoor_z105=. if v6602!=2
	
*Step 6.7: Review the 5DE variables created in this do file and save the data file.

sum feelinputdecagr jown_count credjanydec_any incdec_count groupmember_any npoor_z105
save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] aweai_prep.dta", replace

*Step 7. Create additional variables needed for midline indicator assessment tables

*Step 7.1: Create a variable that indicates if a woman participated in at least one 
*          economic activity: food crop farming, cash crop farming, livestock 
*          raising, non-farm work, or wage/salaried employment (partact_any).
gen 	partact_any=0 if partact!=.
replace partact_any=1 if partact_1==1 | partact_2==1 | partact_3==1 | partact_4==1 | partact_5==1 | partact_6==1
la val  partact_any YESNO
la var 	partact_any "Participated in 1+ econ activity"
tab partact_any

*Step 7.2: Create a variable that indicates if a woman participated in at least  
*          one agriculture economic activity: food crop farming, cash crop 
*          farming, or livestock raising (partact_agr_any).
gen 	partact_agr_any=0 if partact_agr!=.
replace partact_agr_any=1 if partact_1==1 | partact_2==1 | partact_3==1 | partact_6==1
la val 	partact_agr_any YESNO 
la var 	partact_agr_any "Participated in 1+ ag econ activity"
tab partact_agr_any

*Step 7.3: Create a variable that indicates if a woman participated in decisions 
*          at least some of the time for at least one economic activity: food 
*          crop farming, cash crop farming, livestock raising, fishing or 
*          fishpond culture, non-farm work, or wage/salaried employment (inputdec_any).
gen 	inputdec_any=0 
replace inputdec_any=1 if inputdec_1==1 | inputdec_2==1 | inputdec_3==1 | inputdec_4==1 | inputdec_5==1 | inputdec_6==1
replace inputdec_any=. if inputdec_1==. & inputdec_2==. & inputdec_3==. & inputdec_4==. & inputdec_5==. & inputdec_6==.
la val  inputdec_any YESNO 
la var 	inputdec_any "Had input into 1+ econ activity"
tab inputdec_any

*Step 7.4: Create a variable that indicates if a woman participated in decisions 
*          at least some of the time for at least one agriculture economic 
*          activity: food crop farming, cash crop farming, livestock raising, or 
*          fishing or fishpond culture (inputdec_agr_any).
gen 	inputdec_agr_any=0 
replace inputdec_agr_any=1 if inputdec_1==1 | inputdec_2==1 | inputdec_3==1 | inputdec_6==1
replace inputdec_agr_any=. if inputdec_1==. & inputdec_2==. & inputdec_3==. & inputdec_6==.
la val 	inputdec_agr_any YESNO 
la var 	inputdec_agr_any "Had input into 1+ ag econ activity"
tab inputdec_agr_any

*Step 7.5: Create variables for each asset that replaces missing values for 
*          respondents whos HH does not own the asset with 0s so that all 
*          tabulated estimates have the same denominator (all respondents).
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 {
  gen selfjointown_`x'x=selfjointown_`x'
  replace selfjointown_`x'x=0 if own_`x'!=. & selfjointown_`x'==.
}

*Step 7.6: Create variables to capture whether a woman's HH borrowed cash,
*          in-kind, or either cash or in-kind from any source.

*Step 7.6.1: Create variables for each credit sourse setting the cash variables 
*            to 1 if the woman's HH borrowed only cash or cash+in-kind 
*            (hh_cash_1-hh_cash_6) and setting the in-kind variables to 1 the 
*            woman's HH borrowed only in-kind or cash+in-kind (hh_in_kind_1-
*            hh_inkind_6). Set all variables to missing if the response is don't
*            know or missing (9 or .) 
*            
foreach x of numlist 1/6 {
  gen hh_cash_`x'=0
  replace hh_cash_`x'=1 if v6308_`x'==1 | v6308_`x'==3
  replace hh_cash_`x'=. if v6308_`x'>4
  la val hh_cash_`x' YESNO
  
  gen hh_inkind_`x'=0
  replace hh_inkind_`x'=1 if v6308_`x'==2 | v6308_`x'==3
  replace hh_inkind_`x'=. if v6308_`x'>4
  la val hh_inkind_`x' YESNO
}

la var hh_cash_1 "HH borrowed cash from NGO"
la var hh_cash_2 "HH borrowed cash from informal lender"
la var hh_cash_3 "HH borrowed cash from formal lender"
la var hh_cash_4 "HH borrowed cash from friends & relatives"
la var hh_cash_5 "HH borrowed cash from group based microfinace/VSLAs"
la var hh_cash_6 "HH borrowed cash from informal savings/credit group"
  
la var hh_inkind_1 "HH borrowed in-kind from NGO"
la var hh_inkind_2 "HH borrowed in-kind from informal lender"
la var hh_inkind_3 "HH borrowed in-kind from formal lender"
la var hh_inkind_4 "HH borrowed in-kind from friends & relatives"
la var hh_inkind_5 "HH borrowed in-kind from group based microfinace/VSLAs"
la var hh_inkind_6 "HH borrowed in-kind from informal savings/credit group"

*Step 7.6.2: Create variables indicating if a woman's household borrowed cash 
*            (hh_cash_any), in-kind (hh_inkind_any), or either cash or in-kind 
*            (hh_loan_any) from any lending source.
gen 	hh_cash_any=0
replace hh_cash_any=1 if hh_cash_1==1 | hh_cash_2==1 | hh_cash_3==1 | hh_cash_4==1 | hh_cash_5==1 | hh_cash_6==1 
replace hh_cash_any=. if hh_cash_1==. & hh_cash_2==. & hh_cash_3==. & hh_cash_4==. & hh_cash_5==. & hh_cash_6==. 
la val 	hh_cash_any YESNO
la var 	hh_cash_any "HH took a cash loan"
tab hh_cash_any

gen 	hh_inkind_any=0
replace hh_inkind_any=1 if hh_inkind_1==1 | hh_inkind_2==1 | hh_inkind_3==1 | hh_inkind_4==1 | hh_inkind_5==1 | hh_inkind_6==1 
replace hh_inkind_any=. if hh_inkind_1==. & hh_inkind_2==. & hh_inkind_3==. & hh_inkind_4==. & hh_inkind_5==. & hh_inkind_6==. 
la val 	hh_inkind_any YESNO
la var 	hh_inkind_any "HH took an in-kind loan"
tab hh_inkind_any

gen 	hh_loan_any=0
replace hh_loan_any=1 if creditaccess_1==1 | creditaccess_2==1 | creditaccess_3==1 | creditaccess_4==1 | creditaccess_5==1 | creditaccess_6==1 
replace hh_loan_any=. if creditaccess_1==. & creditaccess_2==. & creditaccess_3==. & creditaccess_4==. & creditaccess_5==. & creditaccess_6==. 
la val 	hh_loan_any YESNO
la var 	hh_loan_any "HH took a cash or in-kind loan"
tab hh_loan_any

*Step 7.6.3: Create variables indicating if a woman participated in decisions 
*            related to borrowing from any credit source (creditdecborrow_any),
*            using the credit from any credit source (creditdecuse_any), 
*            or or either borrowing from or using the credit from any lending 
*            source (creditdec_any).
egen 	creditdecborrow_any=rowtotal(creditselfjointborrow_*), missing
replace creditdecborrow_any=1 if creditdecborrow_any>0 & creditdecborrow_any!=.
replace creditdecborrow_any=. if hh_loan_any==0
la val 	creditdecborrow_any YESNO
la var 	creditdecborrow_any "Woman participated in decision to borrow, any source"
tab creditdecborrow_any 

egen 	creditdecuse_any=rowtotal(creditselfjointuse_*), missing
replace creditdecuse_any=1 if creditdecuse_any>0 & creditdecuse_any!=.
replace creditdecuse_any=. if hh_loan_any==0
la val 	creditdecuse_any YESNO
la var 	creditdecuse_any "Woman participated in decision to use credit, any source"
tab creditdecuse_any 

gen 	creditdec_any=0 if hh_loan_any==1
replace creditdec_any=1 if creditdecuse_any==1 | creditdecborrow_any==1
la val 	creditdecuse_any YESNO
la var 	creditdecuse_any "Woman participated in decision to borrow or use credit, any source"
tab creditdec_any

*Step 7.7: Create a variable that indicates if a woman participated in at least
*          some decisions related to using income or HH expenditures: food crop
*          farming, cash crop farming, livestock raising, fishing or fishpond 
*          culture, non-farm work, work or salaried employment, minor HH 
*          expenditures, and major HH expenditures (incomdec_any). Note that the 
*          variables for making decisions about HH expenditures are inputdec_`x' 
*          rather than incomedec_`x'. 
*          (incomdec_any).
gen 	incomedec_any=0 if incomedec!=.
replace incomedec_any=1 if incomedec_1==1 | incomedec_2==1 | incomedec_3==1 | ///
						   incomedec_4==1 | incomedec_5==1 | incomedec_6==1 | ///
						   inputdec_7==1  | inputdec_8==1
la val 	incomedec_any YESNO 
la var 	incomedec_any "Had input into income decisions on 1+ activity, incl. HH expenditures"
tab incomedec_any

*Step 7.8: Create a variable that indicates if a woman participated in at least
*          some decisions related to using income from agriculture activities: 
*          food crop farming, cash crop farming, livestock raising, and fishing 
*          or fishpond culture(incomdec_agr_any).
gen 	incomedec_agr_any=0 if incomedec!=.
replace incomedec_agr_any=1 if incomedec_1==1 | incomedec_2==1 | incomedec_3==1 | incomedec_6==1
la val 	incomedec_agr_any YESNO
la var 	incomedec_agr_any "Had input into income decisions on 1+ ag activity, incl. HH expenditures"
tab incomedec_agr_any

*Step 7.9: Create a variable for each group that replaces missing values for HHs 
*          that do not have that type of group in their community with `0' so 
*          that all estimates have the same denominator (i.e., all HHs ) 
*          (groupmember_01x-groupmember_11x).
foreach x of varlist groupmember_01-groupmember_11 {
  gen `x'x=`x'
  replace `x'x=0 if `x'==. and groupmember_any!=.
}

*Step 7.10: Create a variable that indicates if a woman did any work during the
*           day preceding the survey (work_any).
work_any
gen work_any=0 if work_hours!=.
replace work_any=1 if work_hours>0 & work_hours!=.
la val work_any YESNO 
la var work_any "Performed any work activities"

*Step 7.11: Create variables that count the number of 15-minute time increments spent performing each activity (time_A-time_X).
foreach z in A B C D E F G H I J K L M N O P Q R S T U V W X {
  gen time_`z'=0
}

foreach x in 15 30 45 60 {
  foreach i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 {
    foreach z in A B C D E F G H I J K L M N O P Q R S T U V W X {
	  replace time_`z'=time_`z'+1 if v6601p_`x'_`i'="`z'"
	}
  }
}

la var time_A 	"Sleeping/resting (# 15-min periods)"
la var time_B 	"Eating/drinking (# 15-min periods)"
la var time_C 	"Personal care (# 15-min periods)"
la var time_D 	"School/homework (# 15-min periods)"
la var time_E 	"Work as employed (# 15-min periods)"
la var time_F 	"Own business work (# 15-min periods)"
la var time_G 	"Food crop farming (# 15-min periods)"
la var time_H 	"Cash crop farming (# 15-min periods)"
la var time_I 	"Livestock raising (# 15-min periods)"
la var time_J 	"Fishing/fishpond culture (# 15-min periods)"
la var time_K 	"Commuting (work/school) (# 15-min periods)"
la var time_L 	"Shopping/getting services (# 15-min periods)"
la var time_M 	"Weaving/sewing/textile care (# 15-min periods)"
la var time_N 	"Cooking (# 15-min periods)"
la var time_O 	"Domestic work (# 15-min periods)"
la var time_P 	"Fetching water (# 15-min periods)"
la var time_Q 	"Caring for children (# 15-min periods)"
la var time_R 	"Caring for sick/elderly adults (# 15-min periods)"
la var time_S 	"Traveling, not for work/school (# 15-min periods)"
la var time_T 	"Watching TV/listing to radio/reading (# 15-min periods)"
la var time_U 	"Exercise (# 15-min periods)"
la var time_V 	"Social activities/hobbies (# 15-min periods)"
la var time_W 	"Religious activities (# 15-min periods)"
la var time_X 	"Other (# 15-min periods)"

*Step 7.12. Create variables combines the number of 15-minute time increments 
*           spent performing domestic work excluding fetching water and the time 
*           spent fetching water as a stand-alone activity to enable comparison 
*           to baseline when the two activities were combined (time_OP). 
gen time_OP=0
replace time_OP=time_O+time_P
la var time_OP "Domestic work, incl. fetching water (# 15-min periods)"

*Step 7.13. Create variables combines the number of 15-minute time increments 
*           spent on all agriculture work activities (i.e., food crop farming, 
*           cash crop farming, livestock raising, and fishing or fishpond 
*           aquaculture) to align with how the estimates are included in the 
*           results tables (time_GHIJ). 
gen time_GHIJ=0
replace	time_GHIJ=time_G+time_H+time_I+time_J
la var time_GHIJ "Farming/licestock/fish work (# 15-min periods)"

*Step 7.14. Create variables combines the number of 15-minute time increments 
*           spent on caring for children and caring for the elderly or sick to 
*           align with how the estimates are included in the results tables 
*           (time_QR). 
gen time_QR=0
replace	time_QR=time_Q+time_R
la var time_QR "Caring for children/elderly/sick (# 15-min periods)"

*Step 7.15: Create variables that indicate if a woman partook in each activity
*           (partook_A-partook_X). Note: Fetching water, activity P, was 
*           separated from domestic work in the core Midline Survey questionnaire.
*           If planning to compare with baseline, be sure to ensure that you name 
*           the baseline variables to enable comparison; partook_P will have a 
*           value for midline only.
foreach z in A B C D E F G H I J K L M N O P Q R S T U V W X {
  gen partook_`z'=0
  replace partook_`z'=1 if time_`z'>0
  la val partook_`z' YESNO 
}

la var partook_A "Sleeping/resting, previous day"
la var partook_B "Eating/drinking, previous day"
la var partook_C "Personal care, previous day"
la var partook_D "School/homework, previous day"
la var partook_E "Work as employed, previous day"
la var partook_F "Own business work, previous day"
la var partook_G "Food crop farming, previous day"
la var partook_H "Cash crop farming, previous day"
la var partook_I "Livestock raising, previous day"
la var partook_J "Fishing/fishpond culture, previous day"
la var partook_K "Commuting (work/school), previous day"
la var partook_L "Shopping/getting services, previous day"
la var partook_M "Weaving/sewing/textile care, previous day"
la var partook_N "Cooking, previous day"
la var partook_O "Domestic work excl. fetching water, previous day"
la var partook_P "Fetching water, previous day"
la var partook_Q "Caring for children, previous day"
la var partook_R "Caring for sick/elderly adults, previous day"
la var partook_S "Traveling (not for work/school), previous day"
la var partook_T "Watching TV/listing to radio/reading, previous day"
la var partook_U "Exercise, previous day"
la var partook_V "Social activities/hobbies, previous day"
la var partook_W "Religious activities, previous day"
la var partook_X "Other, previous day"

*Step 7.16: Create a variable that combines domestic work excluding fetching 
*           water and fetching water as a stand-alone activity to enable 
*           comparison to baseline when the two activities were combined 
*           (partook_OP).
gen partook_OP=0
replace partook_OP=1 if time_O>0 | time_P>0
la val partook_OP YESNO 
la var partook_OP "Domestic work incl. fetching water, previous day"

*Step 7.17: Create a variable that combines all agriculture work activities to
*           align with how the estimates are included in the results tables
*           (partook_GHIJ).
gen partook_GHIJ=0 if work_any!=.
replace partook_GHIJ=1 if partook_G==1 | partook_H==1 | partook_I==1 | partook_J==1
la val partook_GHIJ YESNO 
la var partook_GHIJ "Farming/livestock/fish work, previous day"
tab partook_GHIJ survey

*Step 7.18: Create a variable that combines caring for children and caring  
*           for elderly/sick to align with how the estimates are included in the 
*           results tables (partook_QR).
gen partook_QR=0 if work_any!=.
replace partook_QR=1 if partook_Q==1 | partook_R==1
la val partook_QR YESNO 
la var partook_QR "Caring for children/elderly/sick, previous day"
tab partook_QR survey

*Step 7.19: Create variables that the amount of time in hours) that a woman 
*           partook in each activity (hours_A-hours_X), including women who did 
*           not partake in an activity as 0. Note: Fetching water, activity P, was 
*           separated from domestic work in the core Midline Survey questionnaire.
*           If planning to compare with baseline, be sure to ensure that you name 
*           the baseline variables to enable comparison; hours_P will have a 
*           value for midline only.
foreach z in A B C D E F G H I J K L M N O P Q R S T U V W X {
  gen hours_`z'=0
  replace hours_`z'=time_`z'*15/60
}
la var hours_A "Sleeping/resting, time spent (hours)"
la var hours_B "Eating/drinking, time spent (hours)"
la var hours_C "Personal care, time spent (hours)"
la var hours_D "School/homework, time spent (hours)"
la var hours_E "Work as employed, time spent (hours)"
la var hours_F "Own business work, time spent (hours)"
la var hours_G "Food crop farming, time spent (hours)"
la var hours_H "Cash crop farming, time spent (hours)"
la var hours_I "Livestock raising, time spent (hours)"
la var hours_J "Fishing/fishpond culture, time spent (hours)"
la var hours_K "Commuting (work/school), time spent (hours)"
la var hours_L "Shopping/getting services, time spent (hours)"
la var hours_M "Weaving/sewing/textile care, time spent (hours)"
la var hours_N "Cooking, time spent (hours)"
la var hours_O "Domestic work, time spent (hours)"
la var hours_P "Fetching water, time spent (hours)"
la var hours_Q "Caring for children, time spent (hours)"
la var hours_R "Caring for sick/elderly adults, time spent (hours)"
la var hours_S "Traveling (not for work/school), time spent (hours)"
la var hours_T "Watching TV/listing to radio/reading, time spent (hours)"
la var hours_U "Exercise, time spent (hours)"
la var hours_V "Social activities/hobbies, time spent (hours)"
la var hours_W "Religious activities, time spent (hours)"
la var hours_X "Other, time spent (hours)"

*Step 7.20: Create a variable that combines the time spent on domestic work 
*           excluding fetching water and the time spent fetching water as a 
*           stand-alone activity to enable comparison to baseline when the two 
*           activities were combined (hours_OP).
gen hours_OP=0
replace hours_OP=hours_O+hours_P 
la val hours_OP YESNO 
la var hours_OP "Domestic work incl. fetching water, previous day"

*Step 7.21: Create a variable that combines the time spent on all agriculture 
*           work activities to align with how the estimates are included in the 
*           results tables (hours_GHIJ).
gen hours_GHIJ=0 if work_any!=.
replace hours_GHIJ=hours_G+hours_H+hours_I+hours_J
lab var hours_GHIJ "Farming/livestock/fish work, time spent (hours)"
sum hours_GHIJ

*Step 7.22: Create a variable that combines the time spent on caring for children 
*           and caring  for elderly/sick to align with how the estimates are 
*           included in the results tables (hours_QR).
gen hours_QR=0 if work_any!=.
replace hours_QR=hours_Q+hours_R
lab var hours_QR "Caring for children/elderly/sick, time spent (hours)"
sum hours_QR

di "Date:$S_DATE $S_TIME"
log close

