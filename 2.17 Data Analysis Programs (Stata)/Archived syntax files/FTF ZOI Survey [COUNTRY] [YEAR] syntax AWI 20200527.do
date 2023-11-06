/*******************************************************************************
************************* FEED THE FUTURE ZOI SURVEY ***************************
**************************       WEALTH INDEX       ****************************
******************************* [COUNTRY, YEAR] ********************************
********************************************************************************
Description: This code is intended to produce the asset-based household wealth 
index...or absolute wealth index (AWI), which is used as a disaggregate in many
Feed the Future report tables, and which is also used to calculate the 
comparative wealth index (CWI). 

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

Author(s): Gheda Temsah, ICF
Reviewed and updated by: Kirsten Zalisk @ ICF
Review date: July 11, 2019

This syntax file was developed using the core Feed the Future ZOI Survey phase one 
endline/phase two baseline core questionnaire. It must be adapted for the final  
country-specific questionnaire. The syntax could only be partially tested using 
ZOI Survey data; therefore, double-check all results carefully and troubleshoot 
to resolve any issues identified. 
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
**Read person level data
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear

*STEP 1: Review data and create the variables needed to construct the AWI.

*Step 1a: Create a variable that indicates the number of de jure household 
*         members per sleeping room 
/*See household analytic do file - variable already created (memsleep_dj)*/
sum memsleep_dj
tab memsleep_dj

*For the PCA, per DHS protocol, truncate (do not round) the variable to be a whole number.
gen memsleep=trunc(memsleep_dj)

*Step 1b: Create a variable that indicates if anyone in the household owns 
*agricultural land. Treat missing data as though they do not own land.
*Note: this variable is different than the land variable in the DHS wealth quintile
*because we are not using person-level data that indicates if individuals own land.
tab     v240a, m
gen     land=0
replace land=1 if v240a==1
tab v240a land,m //verify

*Step 1c: Create a variable that indicates the amount of agricultural land owned 
*by the household. Households that own 95 or more hectares of land are all coded 
*as having 95 hectares. Set missing/DK to missing (will be replaced by mean in a
*later step). Be sure to adjust the syntax if land area was collected without a
*decimal point or if multiple units were allowed (ex. hectares or square meters).
tab1    v240a v240b
gen     landarea=0 if land==0
replace landarea=v240b if v240b!=. & landarea==.
replace landarea=. if v240b>95 & v240b!=.

la def larea 95 "95+"
la val landarea larea
la var landarea "Amount of ag land HH owns (hectares)"
tab v240b landarea, m

*Step 1d: Create a variable that indicates if the household owns its dwelling. 
*If a household is missing this information, consider the household to not own 
*its dwelling. Treat missing/DK as not owning a house.
*Note: this variable is different than the house variable in the DHS wealth quintile
*because we are not using person-level data that indicates if individuals own their house.
tab     v8601
gen     house=0
replace house=1 if v8601==1
la val  house YESNO
la var  house "Household owns dwelling"
tab     v8601 house,m //verify

*Stedp 1e: Create a binary variable for each response category of the variable 
*that indicates the household’s main source of drinking water 
tab v211,m
sum v211

foreach i of numlist 11/14 21 31/32 41/42 51 61 71 81 91 96 {
gen     water_`i'=0
replace water_`i'=1 if v211==`i'
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

*Step 1f: Create two binary variables for each response category of the variable 
*that indicates the household’s main sanitation facility. The exception is for 
*the no toilet/bush response category. Open defecators are not asked Q209.
tab1 v208 v209,m
sum v208

foreach i of numlist 11/15 21/23 31 41 51 96 {
   foreach l of numlist 1 2 {
      gen toilet_`i'`l'=0
      replace toilet_`i'`l'=1 if v208==`i' & v209==`l'
      tab v208 toilet_`i'`l' ,m //verify
      tab v209 toilet_`i'`l',m  //verify
   }
}
gen toilet_61=0
replace toilet_61=1 if v208==61 

lab var toilet_111 "Flush piped toilet, shared"
lab var toilet_112 "Flush piped toilet, not shared"
lab var toilet_121 "Flush septic tank, shared"
lab var toilet_122 "Flush septic tank, not shared"
lab var toilet_131 "Flush pit latrine, shared"
lab var toilet_132 "Flush pit latrine, not shared"
lab var toilet_141 "Flush elsewhere, shared"
lab var toilet_142 "Flush elsewhere, not shared"
lab var toilet_151 "Flush DK where, shared"
lab var toilet_152 "Flush DK where, not shared"
lab var toilet_211 "Ventilated pit, shared"
lab var toilet_212 "Ventilated pit, not shared"
lab var toilet_221 "Pit with slab, shared"
lab var toilet_222 "Pit with slab,not shared"
lab var toilet_231 "Open pit, shared"
lab var toilet_232 "Open pit, not shared"
lab var toilet_311 "Composting toilet, shared"
lab var toilet_312 "Composting toilet, not shared"
lab var toilet_411 "Bucket toilet, shared"
lab var toilet_412 "Bucket toilet,not shared"
lab var toilet_511 "Hanging toilet, shared"
lab var toilet_512 "Hanging toilet, not shared"
lab var toilet_961 "Other toilet, shared"
lab var toilet_962 "Other toilet, not shared"
lab var toilet_61  "No toilet, open bush"

*Step 1g: Create a binary variable for each response category of the variable 
*that indicates the primary flooring material of the household’s dwelling. But 
*instead of considering the response categories for natural flooring materials 
*separately, group them into one variable 
tab v202,m
sum v202

foreach num of numlist 11/13 21/22 31/35 96 {
    gen floor_`num'=0
    replace floor_`num'=1 if v202 ==`num'
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

*Step 1h: Create a binary variable for each response category of the variable that 
*indicates the primary roof material of the household’s dwelling. But instead of 
*considering the response categories for natural roof materials separately, group 
*them into one variable 
tab v201,m
sum v201

foreach num of numlist 11/14 21/22 31/36 96 {
   gen roof_`num'=0
   replace roof_`num'=1 if v201 ==`num'
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

*Step 1i: Create a binary variable for each response category of the variable that 
*indicates the primary exterior wall material of the household’s dwelling. But 
*instead of considering the response categories for natural wall materials 
*separately, group them into one variable 
tab v203,m
sum v203

foreach num of numlist 11/15 21/24 31/36 96 {
   gen wall_`num'=0
   replace wall_`num'=1 if v203 ==`num'
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
lab var wall_32 "Wall - unbaked bricks"
lab var wall_33 "Wall - bricks"
lab var wall_34 "Wall - cement blocks"
lab var wall_35 "Wall - cement"
lab var wall_36 "Wall - stone with lime/cement"
lab var wall_96 "Wall - other"

*Step 1j. Create a binary variable for each response category of the variable  
*that indicates the primary type of cooking fuel the household uses 
tab v219,m
sum v219

foreach num of numlist 1/11 95 96 {
   gen cookfuel_`num'=0
   replace cookfuel_`num'=1 if v219 ==`num'
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

*Step 1k: Create a categorical variable for each farm animal that indicates 
*the number that the household owns. 
tab1 v225 v226*,m

gen num_cow=0 if v225==2 | v226a==.
replace num_cow=v226a if v226a<=98
tab num_cow
gen cat_cow1_4=0
replace cat_cow1_4=1 if num_cow>=1 & num_cow<=4
la var cat_cow1_4 "Household owns 1-4 cows"
gen cat_cow5_9=0
replace cat_cow5_9=1 if num_cow>=5 & num_cow<=9
la var cat_cow5_9 "Household owns 5-9 cows"
gen cat_cow10=0
replace cat_cow10=1 if num_cow>=10 & num_cow<=99
la var cat_cow10 "Household owns 10+ cows"
tab1 cat_cow*

gen num_cattle=0 if v225==2 | v226b==.
replace num_cattle=v226b if v226b<=99
tab num_cattle
gen cat_cattle1_4=0
replace cat_cattle1_4=1 if num_cattle>=1 & num_cattle<=4
la var cat_cattle1_4 "Household owns 1-4 cattle"
gen cat_cattle5_9=0
replace cat_cattle5_9=1 if num_cattle>=5 & num_cattle<=9
la var cat_cattle5_9 "Household owns 5-9 cattle"
gen cat_cattle10=0
replace cat_cattle10=1 if num_cattle>=10 & num_cattle<=99
la var cat_cattle10 "Household owns 10+ cattle"
tab1 cat_cattle*

gen num_horse=0 if v225==2 | v226c==.
replace num_horse=v226c if v226c<=99
tab num_horse
gen cat_horse1_4=0
replace cat_horse1_4=1 if num_horse>=1 & num_horse<=4
la var cat_horse1_4 "Household owns 1-4 horses"
gen cat_horse5_9=0
replace cat_horse5_9=1 if num_horse>=5 & num_horse<=9
la var cat_horse5_9 "Household owns 5-9 horses"
gen cat_horse10=0
replace cat_horse10=1 if num_horse>=10 & num_horse<=99
la var cat_horse10 "Household owns 10+ horses"
tab1 cat_horse*

gen num_goat=0 if v225==2 | v226d==.
replace num_goat=v226d if v226d<=99
tab num_goat
gen cat_goat1_4=0
replace cat_goat1_4=1 if num_goat>=1 & num_goat<=4
la var cat_goat1_4 "Household owns 1-4 goats"
gen cat_goat5_9=0
replace cat_goat5_9=1 if num_goat>=5 & num_goat<=9
la var cat_goat5_9 "Household owns 5-9 goats"
gen cat_goat10=0
replace cat_goat10=1 if num_goat>=10 & num_goat<=99
la var cat_goat10 "Household owns 10+ goats"
tab1 cat_goat*

gen num_sheep=0 if v225==2 | v226e==.
replace num_sheep=v226e if v226e<=99
tab num_sheep
gen cat_sheep1_4=0
replace cat_sheep1_4=1 if num_sheep>=1 & num_sheep<=4
la var cat_sheep1_4 "Household owns 1-4 sheep"
gen cat_sheep5_9=0
replace cat_sheep5_9=1 if num_sheep>=5 & num_sheep<=9
la var cat_sheep5_9 "Household owns 5-9 sheep"
gen cat_sheep10=0
replace cat_sheep10=1 if num_sheep>=10 & num_sheep<=99
la var cat_sheep10 "Household owns 10+ sheep"
tab1 cat_sheep*

gen num_poultry=0 if v225==2 | v226f==.
replace num_poultry=v226f if v226f<=99
tab num_poultry
gen cat_poultry1_9=0
replace cat_poultry1_9=1 if num_poultry>=1 & num_poultry<=9
la var cat_poultry1_9 "Household owns 1-9 poultry"
gen cat_poultry10_29=0
replace cat_poultry10_29=1 if num_poultry>=10 & num_poultry<=29
la var cat_poultry10_29 "Household owns 10-29 poultry"
gen cat_poultry30=0
replace cat_poultry30=1 if num_poultry>=30 & num_poultry<=99
la var cat_poultry10 "Household owns 30+ poultry"
tab1 cat_poultry*
 
gen num_fish=0 if v225==2 | v226g==.
replace num_fish=v226g if v226g<=99
tab num_fish
gen cat_fish1_9=0
replace cat_fish1_9=1 if num_fish>=1 & num_fish<=9
la var cat_fish1_9 "Household owns 1-9 fish"
gen cat_fish10_29=0
replace cat_fish10_29=1 if num_fish>=10 & num_fish<=29
la var cat_fish10_29 "Household owns 10-29 fish"
gen cat_fish30=0
replace cat_fish30=1 if num_fish>=30 & num_fish<=99
la var cat_fish30 "Household owns 30+ fish"
tab1 cat_fish*

tab1 cat_*

*Step 1l: Recode the binary variable for each asset included in the survey so that 
* no, don’t know, and missing responses/values have a value of 0. 
tab1 v222? v223?,m

foreach var of varlist v222? v223? {
  recode `var' (2 8 9 99 95 98 .=0), gen(`var'x)
}

*Step 1m: Create a binary variable that indicates if any household member has a 
*bank account so that no, don’t know, and missing responses/values have a value of 0. 
tab    v224,m
recode v224 (2 8 9 .=0), gen(bankacct)
la val bankacct YESNO
la var bankacct "Household member has a bank account"
tab bankacct

*Step 2: Create a binary variable that indicates if the household had a maid or servant.

*Step 2a: Save the current version of the household-level analytic data file as 
*a temporary data file, and load the persons-level analyatic data file.
save "$analytic\Temp\temp_awi.dta", replace
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear

*Step 2b: Generate a variable indicates if any HH members in the roster are maids or servants.
egen domestic=anymatch(v103), values(14)

*Step 2c: Generate a file that has 1 record per household indicating if there is 
*a maid or servant in that HH and save the file as a temporary data file. 
collapse (max) domestic, by(hhea hhnum)
save "$analytic\Temp\temp_domestic.dta", replace

*Step 2d: Load the temporary household-level analytic data file created in step 2a,
*and add the domestic variable from the temporary data file created in step 2d 
*to the file loaded in step 2c.
use "$analytic\Temp\temp_awi.dta", clear
merge 1:1 hhea hhnum using "$analytic\Temp\temp_domestic.dta", keepus(domestic)
drop _merge

*STEP 3: Determine the mean values for all land area variable to be included 
*in the AWI and substitute the mean values for any continuous variables with 
*missing values.
sum landarea

egen landarea_mean_rural= mean(landarea) if ahtype==2
tab landarea_mean_rural
replace landarea=landarea_mean_rural if landarea==. & ahtype==2

egen landarea_mean_urban= mean(landarea) if ahtype==1
tab landarea_mean_urban
replace landarea=landarea_mean_urban if landarea==. & ahtype==1

*5/27/2020: Commented out next two lines - global variable not defined yet
*sum $vars
*tab1 $vars, m

*STEP 4: Determine which variables created in Step 1 do not have any variation
*so that they can be excluded from the PCA. To do this, run frequencies 
*on all the created indicator variables and flag any variables that should no 
*variation or little variation. 

global vars domestic land landarea house water_* toilet_* floor_* roof_* wall_* ///
            cookfuel_* cat_* v222ax-v222fx v223ax-v223gx bankacct memsleep
sum $vars
tab1 $vars, m

foreach var of varlist $vars {
  sum `var'
  tab `var', m
}

*STEP 5:Create a new global vars variable to include only variables that have  
*variation that will be included in the PCA, if necessary.
*INSTRUCTION: ADJUST VARIABLE LIST FOR SURVEY COUNTRY AND REMOVE VARIABLES THAT 
*			  DO NOT HAVE VARIATION.
global vars2 domestic memsleep land landarea house bankacct cat_cow* ///
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

*STEP 6: Create a global variable that includes all common variables thought to  
*have the same relationship with theunderlying economic status dimension in both   
*urban andrural areas and selectout those that do not apply to one or another area   
*or are thought to indicate different levels of wealth. The selection of which 
*variables to be included in the common factor analysis is based on one’s 
*understanding and experience. (Removed landarea and animals below.)
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

*STEP 7: Run the factor analysis for the common variables and save the component scores
*as the variable com.
factor $varsc, pcf factors(1)
predict com, norot

*STEP 8: Create a global variable that includes all variables thought to be important 
*in urban areas. Note that rural-type indicators may  also be relevant in urban areas 
*but with a different relationship to wealth. The selection of which variables to be 
*included in the urban factor analysis is again based on one’s understanding and 
*experience. If an indicator variable has no standard deviation, it should be omitted 
*from the analysis. 
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

*STEP 9: Run the factor analysis for the urban variables and save the component scores
*as the variable urb.
factor $varsu if ahtype==1,  factors(1)
predict urb if ahtype==1, norot

*STEP 10: Create a global variable that includes all variables thought to be important 
*in rural areas. Note that urban-type indicators may  also be relevant in rural areas 
*but with a different relationship to wealth. The selection of which variables to be 
*included in the rural factor analysis is again based on one’s understanding and 
*experience. If an indicator variable has no standard deviation, it should be omitted 
*from the rural analysis
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

*STEP 11: Run the factor analysis for the urban variables and save the component scores
*as the variable rur.
factor $varsr if ahtype==2, pcf factors(1) 
predict rur if ahtype==2, norot

*STEP 12: Run a regression with the common factor score (COM) as the dependent 
*variable and the urban area factor score (URB) as the independent variable.
*Save the constant term and the coefficient. 
regress com urb if ahtype==1
gen urb_const=_b[_cons]
gen urb_coeff=_b[urb]

*STEP 13: Run a regression with the common factor score (COM) as the dependent 
*variable and the rural area factor score (RUR) as the independent variable.
*Save the constant term and the coefficient. 		 
regress com rur if ahtype==2
gen rur_const=_b[_cons]
gen rur_coeff=_b[rur]

*STEP 14: Create a variable for the combined score, COMBSCOR, equal to 0. Then 
*calculate the combined score using the appropriate urban or rural factor scores, 
*constant and coefficient obtained in steps 8-13.
gen combscor=0
replace combscor=urb_const+(urb_coeff*urb) if ahtype==1
replace combscor=rur_const+(rur_coeff*rur) if ahtype==2
sum combscor
rename combscor awi

*STEP 15: Generate household member weight variable if not already created
*update the household weight variable based on variable name in the dataset
***If the household weight is stored without decimals, add a step to adjust it.
gen hhmemwgt=wgt_hh*hhsize_dj

*STEP 16: Generate wealth quintiles
xtile awiquint=awi [pweight=hhmemwgt], nq(5)

sum awiquint* 
tab1 awiquint*

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

*STEP 17: Create a null variable to use for merging in the CWI and save the AWI data file
gen null=1
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.dta", replace

//Close the log file
di "Date:$S_DATE $S_TIME"
log close

