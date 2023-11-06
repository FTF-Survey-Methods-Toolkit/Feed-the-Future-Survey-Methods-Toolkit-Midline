/*******************************************************************************
************************* FEED THE FUTURE PHASE SURVEY *************************
**************************** A-WEAI CALCULATIONS *******************************
****************************** [YEAR] [COUNTRY] ********************************
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

Two files are needed to produce the 5DE results included in the P2-ZOI Midline
Survey reports:

	1. Data preparation (current file): 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_1 prep.do
	2. 5DE-related calculations: 
	   FTF P2-ZOI Midline Survey [COUNTRY] [YEAR] syntax AWEAI_2 5DEcalc.do

This data prep file includes syntax to:

	A. Check for data quality 
	   (frequency distribution, missing cases, out-of-range values, skip patterns)
	B. Calculate of the six 5DE indicators of achievement. 


Updated from baseline syntax by ICF 2022 for P2-ZOI midline surveys

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

*B-1.1: Load, review and prepare the data.
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic", clear

*Keep records for only respondents who completed Module 6
drop if v6605!=1

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
*** B1. DOMAIN 1: PRODUCTION 
********************************************************************************
*This domain has one indicator:
	**Indicator 1.1: Input in productive decisions

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

*B-1.1A: Check frequency distribution and number of missing cases.
sum v6201* v6203* v6204*
tab1 v6201* v6202* v6203* v6204*

*B-1.1B: Check skip patterns are correct - if the respondent did not participate 
*in the activity s/he should not have a response for v6202 v6203 v6204. 
*Note: activities 7 and 8 not included because v6201 doesn't exist for them.
foreach x in 1 2 3 4 5 6 {
  tab v6202_`x' v6201_`x',m
  tab v6203_`x' v6201_`x',m
  tab v6204_`x' v6201_`x',m
}

*B-1.1C: Create analytic variables with missing responses (i.e., 9 or 99) or not
		 applicable responses (i.e., 93) to missing (.).
for var v6201_* v6204_*: recode X (9=.), gen(Xx)
for var v6203_*: recode X (99 93=.), gen(Xx)

*B-1.1D: Set v6201 analytic variables for HH expenditures to 1 if there are 
*        data for v6202 and v6203 since Q.6201 is not asked for these items.
foreach x in 7 8 {
  replace v6201_`x'x=1 if v6202_`x'!="" | v6203_`x'!=.
}

*Check skip patterns are correct - if the respondent did not participate 
*in the activity s/he should not have a response for v6202 v6203 v6204. 
foreach x in 7 8 {
  tab v6202_`x' v6201_`x'x,m
  tab v6203_`x' v6201_`x'x,m
  tab v6204_`x' v6201_`x'x,m
}

*B-1.1E: Recode string vars with not applicable response (i.e., X) to missing.
foreach x in 1 2 3 4 5 6 7 8 {
  clonevar v6202_`x'x=v6202_`x'
  replace v6202_`x'x="" if v6202_`x'=="X" 
}

*B-1.2: Generate binary variables indicating participation in economic activities.
*--Variable=1 if respondent participated in activity.
*--Variable=0 if respondent did not participate in activity.
*--Variable=missing if v6201=missing for activity. 
foreach x in 1 2 3 4 5 6 7 8 {
  gen partact_`x'=(v6201_`x'x==1)
  replace partact_`x'=. if v6201_`x'x==.
  la val partact_`x' YESNO
} 	

la var partact_1 "Participated in food crop farming"
la var partact_2 "Participated in cash crop farming"
la var partact_3 "Participated in raising livestock"
la var partact_4 "Participated in non-farm economic activities"
la var partact_5 "Participated in wage and salary employment"
la var partact_6 "Participated in fishing or fishpond culture"
la var partact_7 "Participated in major HH expenditures"
la var partact_8 "Participated in minor HH expenditures"

tab1 partact_*
sum partact_*

*B-1.3. Generate a count variable=number of activities respondent partakes in (0-8).
*--Variable=missing if respondent is missing values for all 8 partact variables.
egen partact=rowtotal(partact_*), missing 
label var partact "Number of activities participated in"
tab partact

*B-1.4. Generate a count variable=number of ag activities respondent partakes in (0-4).
*--Variable=missing if respondent is missing values for all 4 partact variables.
egen partactagr=rowtotal(partact_1 partact_2 partact_3 partact_6), missing
label var partactagr "Number of ag. activities participated in"
tab partactagr

*B-1.5: Generate binary variables for each activity indicating if respondent has 
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

la var inputdec_1 "Has some input in decisions regarding food crop farming"
la var inputdec_2 "Has some input in decisions regarding cash crop farming"
la var inputdec_3 "Has some input in decisions regarding livestock raising"
la var inputdec_4 "Has some input in decisions regarding non-farm activity"
la var inputdec_5 "Has some input in decisions regarding wage & salary employment"
la var inputdec_6 "Has some input in decisions regarding fishing"
la var inputdec_7 "Has some input in decisions regarding major HH expenses"
la var inputdec_8 "Has some input in decisions regarding minor HH expenses"

tab1 inputdec_*
sum inputdec_*

*B-1.6: Generate binary variables for each activity indicating if respondent 
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

label var feelmakedec_1 "Has some input in decisions regarding food crop farming"
label var feelmakedec_2 "Has some input in decisions regarding cash crop farming"
label var feelmakedec_3 "Has some input in decisions regarding livestock raising"
label var feelmakedec_4 "Has some input in decisions regarding non-farm activity"
label var feelmakedec_5 "Has some input in decisions regarding wage & salary employment"
label var feelmakedec_6 "Has some input in decisions regarding fishing"
label var feelmakedec_7 "Has some input in decisions regarding major HH expenses"
label var feelmakedec_8 "Has some input in decisions regarding minor HH expenses"

tab1 feelmakedec_*
sum feelmakedec_*

*B-1.7: Create a count variable=number of agriculture economic activities for 
*       which respondents have input into at least some decisions, plus the 
*       number of agriculture economic activities for which respondents feel that 
*        they can make decisions to a medium or high extent if they wanted to. 
*--Variable=. if respondent is missing a value for all 8 component variables.
egen feelinputdecagr_sum=rowtotal(inputdec_1 inputdec_2 inputdec_3 inputdec_6 ///
					     feelmakedec_1 feelmakedec_2 feelmakedec_3 feelmakedec_6), missing 
label var feelinputdecagr_sum "No. of areas (of 8) respondent has decision-making inputs/power in"
tab feelinputdecagr_sum

*B-1.8. Generate input in decisions indicator indicating if participation in 
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
label var feelinputdecagr "Has decision-making inputs/power in at least 1 of 8 areas"

tab feelinputdecagr

********************************************************************************
******* B2/3. DOMAIN 2: ACCESS TO AND CONTROL OVER PRODUCTIVE RESOURCES ********
********************************************************************************
*This domain is comprised of 2 indicators:
	*Indicator 2.1: Ownership of assets
	*Indicator 2.2: Access to and decisions sover credit
	
********************************************************************************
*** B2. Ownership of assets 
********************************************************************************
*Adequate if individual owns AT LEAST two small assets (chicken, farming equipment 
*non-mechanized, and small consumer durables) OR one large asset (all the other). 

*B-2.1: Review and prepare data.

*B-2.1A: Check frequency distribution and number of missing cases
sum v6301* 
tab1 v6301* v6303*,m 

*B-2.1B: Create analytic variables with No responses (i.e., 2) recoded to 0 and 
*        missing responses (i.e., 9) recoded to missing (.). 
for var  v6301_*: recode X (2=0)(9=.), gen(Xx)

*B-2.2: Generate binary variables indicating if household owns each asset.
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
la var own_05 "HH owns agricultural fish pond or fishing equipment"
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

*B-2.3a: Generate a count variable=number of types of assets HHs own (0-15).
*--Variable=missing if respondent's HH is missing values for all 15 assets.
egen own_sum=rowtotal(own_01-own_15), missing
la var own_sum "No. of types of assets household owns"
tab own_sum

*B-2.3b: Generate a count variable=number of types of agricultural assets HHs own (0-8).
*--Variable=missing if respondent's HH is missing values for all 8 ag assets.
egen ownagr_sum=rowtotal(own_01-own_08), missing
la var ownagr_sum "No. of types of agricultural assets HH owns"
tab ownagr_sum

*B-2.4: Generate binary variables for each asset indicating if respondent owns 
*       the asset alone or jointly.
*--Variable=1 if respondent owns asset alone or jointly.
*--Variable=0 if HH owns asset but respondent does not own asset alone or jointly.
*--Variable=. if HH does not own asset, or HH owns asset but missing information 
*             on who owns the asset.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 {
  gen selfjointown_`x'=(strpos(v6303_`x',"A")>0) if own_`x'==1 
  replace selfjointown_`x'=. if v6303_`x'=="" & own_`x'==1 
  la val selfjointown_`x' YESNO
}

**Create labels for new vars
la var selfjointown_01 "Self/Jointly owns agricultural land"
la var selfjointown_02 "Self/Jointly owns large livestock"
la var selfjointown_03 "Self/Jointly owns small livestock"
la var selfjointown_04 "Self/Jointly owns chickens, turkeys, ducks"
la var selfjointown_05 "Self/Jointly owns fish pond or fishing equipment"
la var selfjointown_06 "Self/Jointly owns hand tools"
la var selfjointown_07 "Self/Jointly owns farm equipment (non-mechanized)"
la var selfjointown_08 "Self/Jointly owns farm equipment (mechanized)"
la var selfjointown_09 "Self/Jointly owns non-farm business equipment"
la var selfjointown_10 "Self/Jointly owns the house (or other structures)"
la var selfjointown_11 "Self/Jointly owns large consumer durables"
la var selfjointown_12 "Self/Jointly owns small consumer durables"
la var selfjointown_13 "Self/Jointly owns cell phone"
la var selfjointown_14 "Self/Jointly owns non-agricultural land"
la var selfjointown_15 "Self/Jointly owns means of transportation"

tab1 selfjointown_*
sum selfjointown_*

*B-2.5: Generate a count variable=number of assets respondent owns alone or jointly.
*--Variable=missing if asset ownership information is missing for all 15 assets.
egen selfjointownsum=rowtotal(selfjointown_*), missing
la var selfjointownsum "No. of assets the respondent owns alone or jointly"
tab selfjointownsum

*B-2.6: Generate ownership indicator indicating whether asset ownership is 
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
la var jown_count "Owns at least 1 large or 2 small assets alone or jointly"

tab1 selfjointownsum jown_count, m

********************************************************************************
*** B.3 Access to and decisions over credit ************************************
********************************************************************************
*Adequate if respondent made decisions alone or joinly regarding AT LEAST ONE 
*of six sources of credit 

*B-3.1: Review and prepare data.
*Check frequency distribution and missing/don't know cases
sum v6308* 
tab1 v6308* v6309* v6310*,m

*B-3.2: Create binary variables indicating whether HH borrowed from each source of credit.
*--Variable=1 if HH borrowed cash, in-kind, or both cash & in-kind from source.
*--Variable=0 if HH did not borrow from source.
*--Variable=. if HH is missing information for v6398 or if respondent doesn't 
*             know if HH borrowed from source.
foreach x in 1 2 3 4 5 6 {
  gen creditaccess_`x'=(v6308_`x'<4) 
  replace creditaccess_`x'=. if (v6308_`x'==. | v6308_`x'==8) 
}

*B-3.3: Create a count variable=number of credit sources the HH used.
*--Variable=missing if information is missing for all 5 credit sources.
egen creditaccess=rowtotal(creditaccess_*), missing
la var creditaccess "No. of credit sources that the HH used"
tab creditaccess

*B-3.4: Generate binary variables indicating if respondent participated in decisions:
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
  replace creditselfjointborrow_`x'=. if (v6309_`x'=="" | v6309_`x'=="X") & creditaccess_`x'==1
  la val creditselfjointborrow_`x' YESNO
  
  *Self or joint decide how to use
  gen creditselfjointuse_`x'=(strpos(v6310_`x',"A")>0) if creditaccess_`x'==1
  replace creditselfjointuse_`x'=. if (v6310_`x'=="" | v6310_`x'=="X") & creditaccess_`x'==1
  la val creditselfjointuse_`x' YESNO

  *Self or joint makes AT LEAST ONE decision regarding credit
  egen creditselfjointanydec_`x'=rowmax(creditselfjointborrow_`x' creditselfjointuse_`x')
  la val creditselfjointanydec_`x' YESNO
}

*Label new variables (borrow, use, any decision)
foreach x in borrow use {
  la var creditselfjoint`x'_1 "Jointly made decision about `x' credit from NGO"
  la var creditselfjoint`x'_2 "Jointly made decision about `x' credit from informal lender"
  la var creditselfjoint`x'_3 "Jointly made decision about `x' credit from formal lender"
  la var creditselfjoint`x'_4 "Jointly made decision about `x' credit from friends & relatives"
  la var creditselfjoint`x'_5 "Jointly made decision about `x' credit from group-based microfinace/VSLAs"
  la var creditselfjoint`x'_6 "Jointly made decision about `x' credit from informal saving/credit group"
}

la var creditselfjointanydec_1 "Jointly made 1+ decision about credit from NGO"
la var creditselfjointanydec_2 "Jointly made 1+ decision about credit from informal lender"
la var creditselfjointanydec_3 "Jointly made 1+ decision about credit from formal lender"
la var creditselfjointanydec_4 "Jointly made 1+ decision about credit from friends & relatives"
la var creditselfjointanydec_5 "Jointly made 1+ decision about credit from group-based microfinace VSLAs"
la var creditselfjointanydec_6 "Jointly made 1+ decision about credit from informal saving/credit group"

sum creditselfjoint*

*B-3.5: Generate indicator indicating if access to credit is adequate.
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
*** B4. DOMAIN 3: CONTROL OVER INCOME ******************************************
********************************************************************************
*This domain is comprised of 1 indicator:
	*Indictor 3: Control of use of income

***Control over use of income (Indicator 3)
/*combination of two sub-indicators: 
1) input into decisions about income from ag activities
2) autonomy in non-farm economic activities, salary/wage employment, major and 
   minor HH expenses individuals who do not participate in the activity and 
   report no decision made are excluded*/

*B-4.1: Review and prepare the data.

*B-4.1A: Check frequency distribution and number of missing cases.
sum v6205*
tab1 v6205*

*B-4.1B: Check skip patterns are correct - if the respondent did not participate 
*        in the activity s/he should not have a response for v6205. 
foreach x in 1 2 3 4 5 6 {
  tab v6205_`x' v6201_`x',m
}

*B-4.1C: Create analtyic variables with missing values (99) and decision not 
*        made values (93) recoded to missing (.).
for var v6205_*: recode X (99 93=.), gen(Xx) 

*B-4.2: Generate binary variables indicating if respondent had input into 
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
	
la var incomedec_1 "Has some input in decisions about income from food crop farming"
la var incomedec_2 "Has some input in decisions about income from cash crop farming"
la var incomedec_3 "Has some input in decisions about income from livestock raising"
la var incomedec_4 "Has some input in decisions about income from non-farm activity"
la var incomedec_5 "Has some input in decisions about income from wage & salary employment"
la var incomedec_6 "Has some input in decisions about income from fishing"

tab1 incomedec_*
sum incomedec_*

*B-4.3: Create a variable that counts the number of relevant activities for which 
*       respondents have input into decisions on the use of income or feel they 
*       can make decisions if they wanted. This includes all 6 income activities plus 
*       major and minor HH expenditures, wage/salary employment, and non-farm economic activities.
*--Variable=missing if values are missing for all 10 component variables.
egen incomedec_sum=rowtotal(incomedec_* feelmakedec_4 feelmakedec_5 feelmakedec_7 feelmakedec_8), missing
la var incomedec_sum "No. of areas (of 10) in which individual has income decision-making input/power"
tab incomedec_sum

*B-4.4: Generate indicator indicating if control over income is adequate
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
la var incdec_count "Has some input/power in income decisions AND not only about minor HH expenditures"
tab incdec_count

********************************************************************************
*** B5. DOMAIN 4: LEADERSHIP IN THE COMMUNITY **********************************
********************************************************************************

*This domain is comprised of one indicator:
	*Indicator 4.1: Membership in economic of social group
	
********************************************************************************
*** Group membership ***********************************************************
********************************************************************************
*B-5.1: Review and prepare data.

*B-5.1A: Check frequency distribution and number of missing values
sum v6404* v6405*
tab1 v6404* v6405*,m

*B-5.1B: Check skip patterns.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 {
  tab v6404_`x' v6405_`x',m
}

*B-5.2: Create binary variables indicating whether the respondent belongs to 
*       each type of community group. 
*Variable=1 if group exists in community and respondent is a member.
*Variable=0 if group doesn't exist in community or respondent is not sure if it 
*           exists, or group exists but respondent is not a member.
*Variable=. if group exists but respondent refused to answer the question
*           about membership or information about respondent's membership is 
*           missing.
foreach x in 01 02 03 04 05 06 07 08 09 10 11 {
  gen groupmember_`x'=(v6405_`x'==1 & v6404_`x'==1)
  replace groupmember_`x'=. if ((v6405_`x'==. | v6405_`x'==7) & v6404_`x'==1) | (v6605!=1)
}
tab1 groupmember_* 

*B-5.3: Generate indicator indicating if group membership is adequate
*GROUP MEMBERSHIP: Adequate if individual is part of AT LEAST ONE group.
*--Variable=1 if respondent is a member of 1+ group.
*--Variable=0 if respondent is not a member of 1+ group, including cases in 
*             which there are no groups in the community or there is 1+ group
*             but the respondent refused to answer membership question.
*--Variable=. is not possible; must have a 0/1 value.
egen groupmember_any=rowmax(groupmember_*)
replace groupmember_any=0 if groupmember_any==.
replace groupmember_any=. if v6605!=1
la val groupmember_any YESNO
la var groupmember_any "Belongs to 1+ group"

tab groupmember_any

********************************************************************************
*** B6. DOMAIN 5: TIME USE *****************************************************
********************************************************************************

*This domain is comprised of one indicator:
	*Indicator 5.1: Worklaod

********************************************************************************
*** Workload *******************************************************************
********************************************************************************

** Create time poverty measure ***

*B-6.1: Review and prepare data. Create a variable equal to the number of 
*       15-minute time increment variables available for each respondent. There
*       should be 96 for all respondents. If there are more than or fewer than
*       96 increments, investigate and determine how to handle these cases.
*       Note that this step does not identify respondents who have missing 
*       values ("?"")--only thoses that are completely missing a response (""). 
*       "?" values are examined in the next step. This is just an initial 
*       screening step.
egen num_incr=rownonmiss(v6601p_*), strok
tab num_incr 

*B-6.2: Create a work variable that captures the number of 15-minute increments 
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
sum work

*B-6.2a: Create a variable to flag respondents missing all time increment data
*        and set the work variable to missing for these respondents.
*INSTRUCTIONS: If there are other cases in which a substantial number of values 
*              are missing (but not all), determine if they also need to be set
*              to missing. 
egen num_avail=rownonmiss(v6601p_*x), strok
tab num_avail
replace work=. if num_avail==0

*B-6.3: Convert total number of 15-minute increments spent working into hours.
gen work_hours=work/4

*B-6.4: Define the time poverty line to be 10.5 hours per day 
qui gen z105=10.5

*B-6.5: Create the indicator of adequate achievement in productive/domestic workload. 
*--Variable=1 if respondent spent <=10.5 hours working the day prior to survey.
*--Variable=0 if respondent spent >10.5 hours working the day prior to survey.
*--Variable=. if respondent is missing all time increment data/has a work_hours
*             variable missing a value.
gen npoor_z105=0 if work_hours>z105 & work_hours!=.
replace npoor_z105=1 if work_hours<=z105
la val npoor_z105 YESNO
la var npoor_z105 "Worked 10.5 hours or less day before survey"
tab npoor_z105

*B-6.6: Not atypical days should be included in the indicator calculation, BUT
*       this step can be added to compare the results for only typical days and
*       to those for both atypical and typical days. 
*replace npoor_z105=. if v6602!=2
	
*B-6.7: Review the 5DE variables created in this do file and save the data file.

sum feelinputdecagr jown_count credjanydec_any incdec_count groupmember_any npoor_z105
save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] aweai_prep.dta", replace

di "Date:$S_DATE $S_TIME"
log close

