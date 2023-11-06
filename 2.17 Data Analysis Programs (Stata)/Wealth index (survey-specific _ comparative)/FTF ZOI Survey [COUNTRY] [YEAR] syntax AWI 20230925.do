/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
***************************** ASSET-BASED WEALTH INDEX *************************
********************************* [COUNTRY] [YEAR] *****************************
********************************************************************************
Description: This code is intended to produce the asset-based household wealth 
index (AWI), which is used as a disaggregate in many Feed the Future report 
tables, and which is also used to calculate the comparative wealth index (CWI). 

The methodology for calculating the AWI is based on the DHS Wealth Index.

The basic steps include:

FIRST: Data prep
* Identify needed variables from person-level and household-level data files
* Explore frequencies, check for missing values, and look at variation in responses

SECOND: Variable and indicator construction
* Create binary variables from categorical variables; do not create indicators for empty categories
* Ensure binary variables are coded 0 (No) and 1 (Yes)
* Code "Don't Know/Refuse/Not applicable" as "No" (0)
* Set missing values to zero unless stated otherwise in the syntax
* Ensure all variables without variation are dropped
* Replace missing values of continuous variables with the mean (during PCA)
* Check frequencies of constructed indicators against the original data for any discrepancies
	
THIRD: Computation of wealth score
***For the factor analysis use the factor command with pcf option.
* Perform the factor analysis for all areas using common assets 
* Perform the factor analysis for urban areas.
* Perform the factor analysis for rural areas.
* Regress the urban and rural results on the common results to obtain an overall wealth score.
	
FOURTH: Creation of wealth quintiles
* Create a HH member weight (HH weight * Number of usual HH members)
* Divide the wealth score into quintiles using the HH member weight
* (Note that the population will be evenly distributed among the quintiles, but
* the number of HHs may not be.)

References: 
http://dhsprogram.com/pubs/pdf/CR6/CR6.pdf
http://pdf.usaid.gov/pdf_docs/Pnadn521.pdf
https://dhsprogram.com/programming/wealth%20index/Steps_to_constructing_the_new_DHS_Wealth_Index.pdf
https://www.dhsprogram.com/topics/wealth-index/Index.cfm

Syntax prepared by ICF, July 2019
Reviewed by ICF, September 2023

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 11.2 Part 1 in the Guide to Feed the Future 
Midline Statistics.

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. Be sure to adjust it as needed to align with the 
country-customized questionnaire.
*******************************************************************************/

set   more off
clear all
macro drop _all
set maxvar 30000

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"


//Do file Name:     $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax AWI.do
//Input(s):     	$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta
//					$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta
//Log Outputs(s):	$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.log
///Data Outputs(s): $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.dta

capture log close
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.log", replace

********************************************************************************
//Create all relevant variables  
********************************************************************************	
*STEP 1: Review data and create the variables needed to construct the AWI.

*Step 1.1: Load the household-level data file.
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear

*Step 1.2: Create a variable that indicates the number of de jure household 
*          members per sleeping room (memsleep) using memsleep_dj, which should
*          already exist in the HH data file.
*          NOTE: For the PCA, per DHS protocol, truncate (do not round) the 
*          variable to be a whole number.
sum memsleep_dj
tab memsleep_dj

gen memsleep=trunc(memsleep_dj)
l var memsleep "Number of HH members per sleeping room, truncated"

*Step 1.3: Create a variable that indicates if anyone in the HH owns agricultural 
*          land. Treat missing data as though they do not own land. 
*    Note: This variable is different than the land variable in the DHS wealth 
*          quintile because we are not using person-level data that indicates if 
*          individuals own land.
tab     v240a, m
gen     land=0
replace land=1 if v240a==1
la var land "Household owns agricultural land"
la val land YESNO
tab v240a land,m //verify

*Step 1.4: Create a variable that indicates the amount of agricultural land owned 
*          by the HH. HHs that own 95 or more hectares of land are all coded as
*          having 95 hectares. Set missing/DK to missing (will be replaced by 
*          median in the next step). Be sure to adjust the syntax if land area was 
*          collected without a decimal point or if multiple units were allowed 
*          (ex. hectares or square meters).
tab1    v240a v240b
gen     landarea=0 if land==0
replace landarea=v240b if v240b!=. & landarea==.
replace landarea=. if v240b>95 & v240b!=.

la def larea 95 "95+"
la val landarea larea
la var landarea "Amount of ag land HH owns (hectares)"
tab v240b landarea, m

*Step 1.5: Determine the median land area value by residence (urban/rural) and 
*          substitute the median value for any missing land area values.
sum landarea

sum landarea if ahtype==2, d
gen landarea_median_rural=r(p50)
tab landarea_median_rural
replace landarea=landarea_median_rural if landarea==. & ahtype==2

sum landarea if ahtype==1, d
gen landarea_median_urban=r(p50)
tab landarea_median_urban
replace landarea=landarea_median_urban if landarea==. & ahtype==1

*Step 1.6: Create a variable that indicates if the HH owns its dwelling. 
*          If a HH is missing this information, consider the HH to not own its
*          dwelling. Treat missing/DK as not owning a house. 
*    Note: This variable is different than the house variable in the DHS wealth 
*          quintile because we are not using person-level data that indicates if 
*          individuals own their house.
tab     v224b
gen     house=0
replace house=1 if v224b==1
la val  house YESNO
la var  house "HH owns dwelling"
tab     v8601 house,m //verify

*Step 1.7: Create a binary variable for each response category of the variable 
*          that indicates the HH's main source of drinking water.
tab v211,m
sum v211

foreach i of numlist 11/14 21 31/32 41/42 51 61 71 81 91 96 {
gen     water_`i'=0
replace water_`i'=1 if v211==`i'
la val  water_`i' YESNO
tab v211 water_`i',m //verify
}

lab var water_11 "Piped into dwelling"
lab var water_12 "Piped into yard/plot"
lab var water_13 "Piped to neighbor"
lab var water_14 "Piped to tap/standpipe"
lab var water_21 "Tubewell or borehole"
lab var water_31 "Protected well"
lab var water_32 "Unprotected well"
lab var water_41 "Protected spring"
lab var water_42 "Unprotected spring"
lab var water_51 "Rainwater"
lab var water_61 "Tanker truck"
lab var water_71 "Cart with small tank"
lab var water_81 "Surface water"
lab var water_91 "Bottled water"
lab var water_96 "Other water source"

*Step 1.8: Create two binary variables for each response category of the variable 
*          that indicates the HH's main sanitation facility. The exception is for 
*          the no toilet/bush response category. Open defecators are not asked Q209.
tab1 v208 v209,m
sum v208

foreach i of numlist 11/15 21/23 31 41 51 96 {
   foreach l of numlist 1 2 {
      gen toilet_`i'`l'=0
      replace toilet_`i'`l'=1 if v208==`i' & v209==`l'
	  la val toilet_`i'`l' YESNO
      tab v208 toilet_`i'`l' ,m //verify
      tab v209 toilet_`i'`l',m  //verify

   }
}
gen toilet_61=0
replace toilet_61=1 if v208==61 

lab var 	toilet_61 "No toilet, open bush"
lab var  	toilet_112 "Flush piped toilet, not shared"
lab var  	toilet_122 "Flush septic tank, not shared"
lab var  	toilet_132 "Flush pit latrine, not shared"
lab var  	toilet_142 "Flush elsewhere, not shared"
lab var 	toilet_152 "Flush DK where, not shared"
lab var 	toilet_212 "Ventilated pit, not shared"
lab var 	toilet_222 "Pit with slab, not shared"
lab var 	toilet_232 "Open pit, not shared"
lab var 	toilet_312 "Composting toilet, not shared"
lab var 	toilet_412 "Bucket toilet, not shared"
lab var 	toilet_512 "Hanging toilet, not shared"
lab var 	toilet_962 "Other toilet, not shared"
lab var 	toilet_111 "Flush piped toilet, shared"
lab var 	toilet_121 "Flush septic tank, shared"
lab var 	toilet_131 "Flush pit latrine, shared"
lab var 	toilet_141 "Flush elsewhere, shared"
lab var 	toilet_151 "Flush don't know where, shared"
lab var		toilet_211 "Ventilated pit, shared"
lab var 	toilet_221 "Pit with slab, shared"
lab var 	toilet_231 "Open pit, shared"
lab var 	toilet_311 "Composting toilet, shared"
lab var 	toilet_411 "Bucket toilet, shared"
lab var 	toilet_511 "Hanging toilet, shared"
lab var 	toilet_961 "Other toilet, shared"

*Step 1.9: Create a binary variable for each response category of the variable 
*          that indicates the primary flooring material of the HH's dwelling. But 
*          instead of considering the response categories for natural flooring 
*          materials separately, group them into one variable.
tab v202,m
sum v202

foreach num of numlist 11/13 21/22 31/35 96 {
    gen floor_`num'=0
    replace floor_`num'=1 if v202 ==`num'
	la val floor_`num' YESNO
    tab v202 floor_`num' ,m //verify
}

lab var floor_11 "Floor - earth/sand"
lab var floor_12 "Floor - dung"
lab var floor_13 "Floor - palm leaves"
lab var floor_21 "Floor - wood planks"
lab var floor_22 "Floor - bamboo slats"
lab var floor_31 "Floor - vinyl or asphalt strips"
lab var floor_32 "Floor - wall-to-wall carpet"
lab var floor_33 "Floor - cement"
lab var floor_34 "Floor - parquet or polished wood"
lab var floor_35 "Floor - ceramic tiles"
lab var floor_96 "Floor - other"

*Step 1.10: Create a binary variable for each response category of the variable 
*           that indicates the primary roof material of the HH's dwelling. But 
*           instead of considering the response categories for natural roof 
*           materials separately, group them into one variable.
tab v201,m
sum v201

foreach num of numlist 11/14 21/22 31/36 96 {
   gen roof_`num'=0
   replace roof_`num'=1 if v201 ==`num'
   la val roof_`num' YESNO
   tab v201 roof_`num' ,m //verify
}

lab var roof_11 "Roof - no roof"
lab var roof_12 "Roof - thatch"
lab var roof_13 "Roof - sod"
lab var roof_14 "Roof - bamboo"
lab var roof_21 "Roof - wood planks"
lab var roof_22 "Roof - cardboard"
lab var roof_31 "Roof - metal"
lab var roof_32 "Roof - wood"
lab var roof_33 "Roof - calamine/cement fiber"
lab var roof_34 "Roof - ceramic tiles"
lab var roof_35 "Roof - cement"
lab var roof_36 "Roof - roofing shingles"
lab var roof_96 "Roof - other"

*Step 1.11: Create a binary variable for each response category of the variable 
*           that indicates the primary exterior wall material of theHH’s dwelling. 
*           But instead of considering the response categories for natural wall 
*           materials separately, group them into one variable.
tab v203,m
sum v203

foreach num of numlist 11/15 21/24 31/36 96 {
   gen wall_`num'=0
   replace wall_`num'=1 if v203 ==`num'
   la val wall_`num' YESNO
   tab v203 wall_`num' ,m //verify
}

lab var wall_11 "Wall - no walls"
lab var wall_12 "Wall - dirt"
lab var wall_13 "Wall - cane/palm/tree trunks"
lab var wall_14 "Wall - bamboo with mud"
lab var wall_15 "Wall - stone with mud"
lab var wall_21 "Wall - cardboard"
lab var wall_22 "Wall - reused wood"
lab var wall_23 "Wall - plywood"
lab var wall_24 "Wall - unbaked bricks"
lab var wall_31 "Wall - wood planks/shingles"
lab var wall_32 "Wall - unbaked bricks w plaster"
lab var wall_33 "Wall - bricks"
lab var wall_34 "Wall - cement blocks"
lab var wall_35 "Wall - cement"
lab var wall_36 "Wall - stone with lime/cement"
lab var wall_96 "Wall - other"

*Step 1.12: Create a binary variable for each response category of the variable  
*           that indicates the primary type of cooking fuel the HH uses.
tab v219,m
sum v219

foreach num of numlist 1/11 95 96 {
   gen cookfuel_`num'=0
   replace cookfuel_`num'=1 if v219 ==`num'
   la val cookfuel_`num' YESNO
   tab v219 cookfuel_`num' ,m //verify
}

lab var cookfuel_1 "Cooking fuel - electricity"
lab var cookfuel_2 "Cooking fuel - liquid propane gas"
lab var cookfuel_3 "Cooking fuel - natural gas"
lab var cookfuel_4 "Cooking fuel - biogas"
lab var cookfuel_5 "Cooking fuel - kerosene"
lab var cookfuel_6 "Cooking fuel - coal"
lab var cookfuel_7 "Cooking fuel - charcoal"
lab var cookfuel_8 "Cooking fuel - wood"
lab var cookfuel_9 "Cooking fuel - straw/shrubs/grass"
lab var cookfuel_10 "Cooking fuel - agri crop residue"
lab var cookfuel_11 "Cooking fuel - animal dung"
lab var cookfuel_95 "Cooking fuel - food not cooked in house"
lab var cookfuel_96 "Cooking fuel - other"

*Step 1.13: Create a continuous variable for each farm animal equal to the number 
*           that the HH owns, setting missing values to 0 and leaving "don't know" 
*           responses as 98. Then create a set of categorical variables for each 
*           farm animal that indicates the number that the household owns. 
*           In most cases, these categories work, but it is important to review 
*           carefully to ensure that there are no categories with a small number 
*           of HHs (i.e., categories have at least 3-5 households in them). If 
*           there are not many HHs in certain categories, revise the variables to
*           better distribute the HHs among categories. 
tab1 v225 v226*,m

gen num_cow=0 if v225==2 | v226a==.
replace num_cow=v226a if v226a<=98
la var num_cow "Number of cows or bulls HH owns"

tab num_cow
gen cat_cow1_4=0
replace cat_cow1_4=1 if num_cow>=1 & num_cow<=4
la var cat_cow1_4 "HH owns 1-4 cows or bulls"
gen cat_cow5_9=0
replace cat_cow5_9=1 if num_cow>=5 & num_cow<=9
la var cat_cow5_9 "HH owns 5-9 cows or bulls"
gen cat_cow10=0
replace cat_cow10=1 if num_cow>=10 & num_cow<=98
la var cat_cow10 "HH owns 10+ cows or bulls"
tab1 cat_cow*

gen num_cattle=0 if v225==2 | v226b==.
replace num_cattle=v226b if v226b<=98
la var num_cattle "Number of other cattle HH owns"

tab num_cattle
gen cat_cattle1_4=0
replace cat_cattle1_4=1 if num_cattle>=1 & num_cattle<=4
la var cat_cattle1_4 "HH owns 1-4 other cattle"
gen cat_cattle5_9=0
replace cat_cattle5_9=1 if num_cattle>=5 & num_cattle<=9
la var cat_cattle5_9 "HH owns 5-9 other cattle"
gen cat_cattle10=0
replace cat_cattle10=1 if num_cattle>=10 & num_cattle<=98
la var cat_cattle10 "HH owns 10+ other cattle"
tab1 cat_cattle*

gen num_horse=0 if v225==2 | v226c==.
replace num_horse=v226c if v226c<=98
la var num_horse "Number of horses, donkeys, mules HH owns"

tab num_horse
gen cat_horse1_4=0
replace cat_horse1_4=1 if num_horse>=1 & num_horse<=4
la var cat_horse1_4 "HH owns 1-4 horses, donkeys, mules"
gen cat_horse5_9=0
replace cat_horse5_9=1 if num_horse>=5 & num_horse<=9
la var cat_horse5_9 "HH owns 5-9 horses, donkeys, mules"
gen cat_horse10=0
replace cat_horse10=1 if num_horse>=10 & num_horse<=98
la var cat_horse10 "HH owns 10+ horses, donkeys, mules"
tab1 cat_horse*

gen num_goat=0 if v225==2 | v226d==.
replace num_goat=v226d if v226d<=98
tab num_goat
la var num_goat "Number of goats owned by HH"

gen cat_goat1_4=0
replace cat_goat1_4=1 if num_goat>=1 & num_goat<=4
la var cat_goat1_4 "HH owns 1-4 goats"
gen cat_goat5_9=0
replace cat_goat5_9=1 if num_goat>=5 & num_goat<=9
la var cat_goat5_9 "HH owns 5-9 goats"
gen cat_goat10=0
replace cat_goat10=1 if num_goat>=10 & num_goat<=99
la var cat_goat10 "HH owns 10+ goats"
tab1 cat_goat*

gen num_sheep=0 if v225==2 | v226e==.
replace num_sheep=v226e if v226e<=98
la var num_sheep "Number of sheep HH owns"

tab num_sheep
gen cat_sheep1_4=0
replace cat_sheep1_4=1 if num_sheep>=1 & num_sheep<=4
la var cat_sheep1_4 "HH owns 1-4 sheep"
gen cat_sheep5_9=0
replace cat_sheep5_9=1 if num_sheep>=5 & num_sheep<=9
la var cat_sheep5_9 "HH owns 5-9 sheep"
gen cat_sheep10=0
replace cat_sheep10=1 if num_sheep>=10 & num_sheep<=98
la var cat_sheep10 "HH owns 10+ sheep"
tab1 cat_sheep*

gen num_poultry=0 if v225==2 | v226f==.
replace num_poultry=v226f if v226f<=98
la var num_poultry "Number of poultry HH owns"

tab num_poultry
gen cat_poultry1_9=0
replace cat_poultry1_9=1 if num_poultry>=1 & num_poultry<=9
la var cat_poultry1_9 "HH owns 1-9 poultry"
gen cat_poultry10_29=0
replace cat_poultry10_29=1 if num_poultry>=10 & num_poultry<=29
la var cat_poultry10_29 "HH owns 10-29 poultry"
gen cat_poultry30=0
replace cat_poultry30=1 if num_poultry>=30 & num_poultry<=98
la var cat_poultry10 "HH owns 30+ poultry"
tab1 cat_poultry*
 
gen num_fish=0 if v225==2 | v226g==.
replace num_fish=v226g if v226g<=9998
la var num_fish "Number of fish HH owns"

tab num_fish
gen cat_fish1_9=0
replace cat_fish1_49=1 if num_fish>=1 & num_fish<=49
la var cat_fish1_49 "HH owns 1-49 fish"
gen cat_fish50_99=0
replace cat_fish50_99=1 if num_fish>=50 & num_fish<=99
la var cat_fish50_99 "HH owns 50-99 fish"
gen cat_fish100=0
replace cat_fish100=1 if num_fish>=100 & num_fish<=9998
la var cat_fish100 "HH owns 100+ fish"
tab1 cat_fish*

tab1 cat_*

*Step 1.14: Recode the binary variable for each asset included in the survey so 
*           that no, don’t know, and missing responses/values have a value of 0. 
tab1 v222? v223?,m

foreach var of varlist v222? v223? {
  recode `var' (2 9 .=0), gen(`var'x)
}

*Step 1.15: Create a binary variable that indicates if any HH member has a bank
*           account so that no, don’t know, and missing values have a value of 0. 
tab    v224,m
recode v224 (2 9 .=0), gen(bankacct)
la val bankacct YESNO
la var bankacct "HH member has a bank account"
tab bankacct

*STEP 2: Create a binary variable that indicates if the household had a maid or servant.

*Step 2.1: Save the current version of the HH-level analytic data file as 
*          a temporary data file, and load the persons-level analyatic data file.
save "$analytic\Temp\temp_awi.dta", replace
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear

*Step 2.2: Create a variable indicates if any HH members in the roster are maids or servants.
egen domestic=anymatch(v103), values(14)

*Step 2.3: Create a file that has 1 record per HH indicating if there is a maid
*          or servant in that HH and save the file as a temporary data file. 
collapse (max) domestic, by(hhea hhnum)
la val domestic YESNO
la var domestic "HH has a maid or servant"
save "$analytic\Temp\temp_domestic.dta", replace

*Step 2.4: Load the temporary HH-level analytic data file created in step 2.1,
*          and add the domestic variable from the temporary data file created in 
*          Step 2.3.
use "$analytic\Temp\temp_awi.dta", clear
merge 1:1 hhea hhnum using "$analytic\Temp\temp_domestic.dta", keepus(domestic)
drop _merge

*STEP 3: Determine which variables created in Steps 1 and 2 do not have any 
*        variation so that they can be excluded from the PCA. To do this, run 
*        frequencies on all the created indicator variables and flag any 
*        variables that should no variation or little variation. 

global vars domestic land landarea house water_* toilet_* floor_* roof_* wall_* ///
            cookfuel_* cat_* v222ax-v222fx v223ax-v223gx bankacct memsleep
sum $vars
tab1 $vars, m

foreach var of varlist $vars {
  sum `var'
  tab `var', m
}

*STEP 4: Create a new global vars variable to include only variables that have  
*        variation that will be included in the PCA, if necessary (vars2).
*INSTRUCTION: ADJUST VARIABLE LIST FOR SURVEY COUNTRY AND REMOVE VARIABLES THAT 
*			  DO NOT HAVE VARIATION.
global vars2 domestic memsleep land landarea house bankacct cat_cow* ///
			 cat_cattle* cat_horse* cat_goat* cat_sheep* cat_poultry* cat_fish*  ///
			 water_11 water_12 water_13 water_14 water_21 water_31 water_32 ///
			 water_41 water_42 water_51 water_61 water_71 water_91 water_81 water_96 ///
			 toilet_111 toilet_112 toilet_121 toilet_122 toilet_131 toilet_132 ///
			 toilet_141 toilet_142 toilet_151 toilet_152 toilet_211 toilet_212 ///
			 toilet_221 toilet_222 toilet_231 toilet_232 toilet_311 toilet_312 ///
			 toilet_411 toilet_412 toilet_511 toilet_512 toilet_961 toilet_962 ///
			 toilet_61 floor_11 floor_12 floor_13 floor_21 floor_22 floor_31 ///
			 floor_32 floor_33 floor_34 floor_35 floor_96 roof_11 roof_12 roof_13 ///
			 roof_14 roof_21 roof_22 roof_31 roof_32 roof_33 roof_34 roof_35 ///
			 roof_96 wall_11 wall_12 wall_13 wall_14 wall_15 wall_21 wall_22 wall_23 ///
			 wall_24 wall_31 wall_32 wall_33 wall_34 wall_35 wall_36 wall_96 ///
			 cookfuel_1 cookfuel_2 cookfuel_3 cookfuel_4 cookfuel_5 cookfuel_6 ///
			 cookfuel_7 cookfuel_8 cookfuel_9 cookfuel_10 cookfuel_11 ///
			 cookfuel_95 cookfuel_96 v222ax v222bx v222cx v222dx v222ex v222fx /// 
			 v223ax v223bx v223cx v223dx v223ex v223fx v223gx

*STEP 5: Create a global variable that includes all common variables thought to  
*        have the same relationship with theunderlying economic status dimension 
*        in both urban and rural areas and select out those that do not apply to 
*        one or another area or are thought to indicate different levels of 
*        wealth. The selection of which variables to be included in the common 
*	     factor analysis is based on one's understanding and experience. (Removed 
*	     landarea and animals below.) 
*INSTRUCTION: ADJUST VARIABLE LIST FOR SURVEY COUNTRY AND REMOVE VARIABLES THAT 
*			  DO NOT HAVE VARIATION.
global varsc domestic memsleep land house bankacct ///
			 water_11 water_12 water_13 water_14 water_21 water_31 water_32 ///
			 water_41 water_42 water_51 water_61 water_71 water_91 water_96 ///
			 toilet_111 toilet_112 toilet_121 toilet_122 toilet_131 toilet_132 ///
			 toilet_141 toilet_142 toilet_151 toilet_152 toilet_211 toilet_212 ///
			 toilet_221 toilet_222 toilet_231 toilet_232 toilet_311 toilet_312 ///
			 toilet_411 toilet_412 toilet_511 toilet_512 toilet_961 toilet_962 ///
			 toilet_61 floor_11 floor_12 floor_13 floor_21 floor_22 floor_31 ///
			 floor_32 floor_33 floor_34 floor_35 floor_96 roof_11 roof_12 roof_13 ///
			 roof_14 roof_21 roof_22 roof_31 roof_32 roof_33 roof_34 roof_35 ///
			 roof_96 wall_11 wall_12 wall_13 wall_14 wall_15 wall_21 wall_22 wall_23 ///
			 wall_24 wall_31 wall_32 wall_33 wall_34 wall_35 wall_36 wall_96 ///
			 cookfuel_1 cookfuel_2 cookfuel_3 cookfuel_4 cookfuel_5 cookfuel_6 ///
			 cookfuel_7 cookfuel_8 cookfuel_9 cookfuel_10 cookfuel_11 ///
			 cookfuel_95 cookfuel_96 v222ax v222bx v222cx v222dx v222ex v222fx /// 
			 v223ax v223bx v223cx v223dx v223ex v223fx v223gx	 
sum $varsc

*STEP 6: Run the factor analysis for the common variables and save the component 
*        scores as the variable com.
factor $varsc, pcf factors(1)
predict com, norot

*STEP 7: Create a global variable that includes all variables thought to be 
*        important in urban areas. Note that rural-type indicators may  also be 
*        relevant in urban areas but with a different relationship to wealth. 
*        The selection of which variables to be included in the urban factor 
*        analysis is again based on one's understanding and experience. If an 
*        indicator variable has no standard deviation, it should be omitted 
*        from the analysis. 
*INSTRUCTION: ADJUST VARIABLE LIST FOR SURVEY COUNTRY AND REMOVE VARIABLES THAT 
*			  DO NOT HAVE VARIATION.
sum $vars2 if ahtype==1
global varsu domestic memsleep land landarea house bankacct cat_cow* ///
			 cat_cattle* cat_horse* cat_goat* cat_sheep* cat_poultry* cat_fish*  ///
			 water_11 water_12 water_13 water_14 water_21 water_31 water_32 ///
			 water_41 water_42 water_51 water_61 water_71 water_91 water_96 ///
			 toilet_111 toilet_112 toilet_121 toilet_122 toilet_131 toilet_132 ///
			 toilet_141 toilet_142 toilet_151 toilet_152 toilet_211 toilet_212 ///
			 toilet_221 toilet_222 toilet_231 toilet_232 toilet_311 toilet_312 ///
			 toilet_411 toilet_412 toilet_511 toilet_512 toilet_961 toilet_962 ///
			 toilet_61 floor_11 floor_12 floor_13 floor_21 floor_22 floor_31 ///
			 floor_32 floor_33 floor_34 floor_35 floor_96 roof_11 roof_12 roof_13 ///
			 roof_14 roof_21 roof_22 roof_31 roof_32 roof_33 roof_34 roof_35 ///
			 roof_96 wall_11 wall_12 wall_13 wall_14 wall_15 wall_21 wall_22 wall_23 ///
			 wall_24 wall_31 wall_32 wall_33 wall_34 wall_35 wall_36 wall_96 ///
			 cookfuel_1 cookfuel_2 cookfuel_3 cookfuel_4 cookfuel_5 cookfuel_6 ///
			 cookfuel_7 cookfuel_8 cookfuel_9 cookfuel_10 cookfuel_11 ///
			 cookfuel_95 cookfuel_96 v222ax v222bx v222cx v222dx v222ex v222fx /// 
			 v223ax v223bx v223cx v223dx v223ex v223fx v223gx	 
sum $varsu if ahtype==1

*STEP 8: Run the factor analysis for the urban variables and save the component 
*        scores as the variable urb.
factor $varsu if ahtype==1, pcf factors(1)
predict urb if ahtype==1, norot

*STEP 9: Create a global variable that includes all variables thought to be 
*        important in rural areas. Note that urban-type indicators may  also be 
*        relevant in rural areas but with a different relationship to wealth. 
*        The selection of which variables to be included in the rural factor 
*        analysis is again based on one’s understanding and experience. If an 
*        indicator variable has no standard deviation, it should be omitted 
*        from the rural analysis
*INSTRUCTION: ADJUST VARIABLE LIST FOR SURVEY COUNTRY AND REMOVE VARIABLES THAT 
*			  DO NOT HAVE VARIATION.
sum $vars2 if ahtype==2
global varsr domestic memsleep land landarea house bankacct cat_cow* ///
			 cat_cattle* cat_horse* cat_goat* cat_sheep* cat_poultry* cat_fish* ///
			 water_11 water_12 water_13 water_14 water_21 water_31 water_32 ///
			 water_41 water_42 water_51 water_61 water_71 water_91 water_96 ///
			 toilet_111 toilet_112 toilet_121 toilet_122 toilet_131 toilet_132 ///
			 toilet_141 toilet_142 toilet_151 toilet_152 toilet_211 toilet_212 ///
			 toilet_221 toilet_222 toilet_231 toilet_232 toilet_311 toilet_312 ///
			 toilet_411 toilet_412 toilet_511 toilet_512 toilet_961 toilet_962 ///
			 toilet_61 floor_11 floor_12 floor_13 floor_21 floor_22 floor_31 ///
			 floor_32 floor_33 floor_34 floor_35 floor_96 roof_11 roof_12 roof_13 ///
			 roof_14 roof_21 roof_22 roof_31 roof_32 roof_33 roof_34 roof_35 ///
			 roof_96 wall_11 wall_12 wall_13 wall_14 wall_15 wall_21 wall_22 wall_23 ///
			 wall_24 wall_31 wall_32 wall_33 wall_34 wall_35 wall_36 wall_96 ///
			 cookfuel_1 cookfuel_2 cookfuel_3 cookfuel_4 cookfuel_5 cookfuel_6 ///
			 cookfuel_7 cookfuel_8 cookfuel_9 cookfuel_10 cookfuel_11 ///
			 cookfuel_95 cookfuel_96 v222ax v222bx v222cx v222dx v222ex v222fx /// 
			 v223ax v223bx v223cx v223dx v223ex v223fx v223gx	 
sum $varsr if ahtype==2

*STEP 10: Run the factor analysis for the urban variables and save the component 
*         scores as the variable rur.
factor $varsr if ahtype==2, pcf factors(1) 
predict rur if ahtype==2, norot

*STEP 11: Run a regression with the common factor score (com) as the dependent 
*         variable and the urban area factor score (urb) as the independent 
*         variable. Save the constant term and the coefficient. 
regress com urb if ahtype==1
gen urb_const=_b[_cons]
gen urb_coeff=_b[urb]

*STEP 12: Run a regression with the common factor score (com) as the dependent 
*         variable and the rural area factor score (rur) as the independent 
*         variable. Save the constant term and the coefficient. 		 
regress com rur if ahtype==2
gen rur_const=_b[_cons]
gen rur_coeff=_b[rur]

*STEP 13: Create a variable for the combined score, awi, equal to 0. Then 
*         calculate the combined score using the appropriate urban or rural 
*         factor scores, constant and coefficient obtained in steps 8-13.
gen awi=0
replace awi=urb_const+(urb_coeff*urb) if ahtype==1
replace awi=rur_const+(rur_coeff*rur) if ahtype==2
sum awi
la var awi "HH's asset-based wealth index score'"

*STEP 14: Create a variable for the HH member weight (hhmemwgt), if not already
*         created, by multiplying the number of de jure HH members (hhsize_dj) 
*         by the HH weight (wgt_hh).
gen hhmemwgt=wgt_hh*hhsize_dj

*STEP 15: Create wealth quintiles (awiquint) using the wealth index scores (awi) 
*         and applying the HH member weight. Note that in most cases, the 
*         cumulative distribution will not be smooth at the quintile cutpoints 
*         (e.g., 20 percent, 40 percent, 60 percent) because a single AWI score 
*         may increase the cumulative percentage by several percentage points. 
xtile awiquint=awi [pweight=hhmemwgt], nq(5)

sum awiquint* 
tab1 awiquint*
la var awiquint "HH's asset-based wealth index quintile"
la def wquint 5 "Highest (wealthiest)" 4 "Fourth" 3 "Middle" 2 "Second" 1 "Lowest (poorest)", modify
la val awiquint wquint

*Check the variables against each indicator to verify relationship is in 
*the expected direction

* Binary indicators
foreach var of varlist $vars2 {
  tab `var' awiquint, row nof m
}

* Continous indicators
foreach var of varlist landarea memsleep {
    bysort awiquint: sum `var'
}

* Histogram
hist awiquint, normal

*STEP 16: Create a null variable to use for merging in the CWI and save the AWI data file
gen null=1
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.dta", replace

di "Date:$S_DATE $S_TIME"
log close

