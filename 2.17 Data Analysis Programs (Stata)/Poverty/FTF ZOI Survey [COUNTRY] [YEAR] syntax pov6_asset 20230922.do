/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
**************************** DURABLE GOODS/ASSETS ******************************
****************************** [COUNTRY] [YEAR] ********************************
********************************************************************************
Description: This code is intended to calculate per capita daily durable goods
consumption expenditure. This is the 6th of 8 preparatory syntax files to 
calculate the poverty indicators.

Syntax prepared by ICF, 2018
Syntax revised by ICF, April 2020, September 2023

This syntax file was developed using the core Feed the Future phase 1 endline/
phase 2 baseline ZOI Survey questionnaire and revised using the core Feed the 
Future Midline Survey parallel survey questionnaire. It must be adapted for the 
final country-specific questionnaire. The syntax was only be partially tested 
using ZOI Survey data; therefore, double-check all results carefully and 
troubleshoot to resolve any issues identified. 
** -------------------------------------------------------------------------- 
**  In particular, examine the outliers one by one for plausibility before 
**  replacing them with the median.  
*******************************************************************************/


set   more off
clear all
macro drop _all
set maxvar 10000

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [Country] [Year]\Syntax" 
global analytic  "C:\FTF ZOI Survey [Country] [Year]\Analytic"

//Input data:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] pov6_asset.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov6_asset.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax pov6_asset.do 
 
cap log close
cap log using  "$analytic\log\FTF ZOI Survey [Country] [Year] pov6_asset.log", replace

********************************************************************************
* DEFINE FLAG_OUTLIERS PROGRAM CALLED IN DO FILE
********************************************************************************
/* This set of commands is used to identify outlier values. The same
   program is used in all consumption expenditure do files (pov1 to pov8).

Outliers identification and verification procedures:

a. Select the local administrative unit within which boundary outliers will be 
   defined (e.g., cluster, district, etc.)
   
b. As a rule, a data point is defined as a potential outlier if it is more or 
   less than 3 standard deviations from its mean in the selected local 
   administrative unit. However, depending on the specific situations, data 
   analysts might need to consider a different cut-off point (such as 
   2 or 5 SD) and/or a different local administrative unit.
   
c. FLAG_OUTLIERS is a Stata macro syntax written for this study to flag outliers 
   for each item within the cluster using 3 SD as a cut-off point. However, 
   if a different cut-off point or local administrative units (such as district) 
   are needed to identify outliers, SD cut-off and relevant administrative units
   can easily be changed in the syntax if necessary. 
   
   The FLAG_OUTLIERS macro will create a new variable (e.g., out_unitprice_item) 
   to flag outliers and has 3 possible values:
      0 = not an outlier 
      1 = outlier: unitprice_item > (mean_unitprice_item + 3 sd_unitprice_item)  
      2 = outlier: unitprice_item < (mean_unitprice_item - 3 sd_unitprice_item) 

d. All flagged outlier data points should be examined for plausibility, as some 
   outliers may be legitimate values. We suggest outputting the flagged outliers 
   to an Excel file and examining each case individually. Upon review, some 
   outliers may need to be changed to non-outliers. Observations that are 
   confirmed to be outliers should be set to missing (they will be
   replaced in a later step). 
*/

cap prog drop FLAG_OUTLIERS
prog def FLAG_OUTLIERS
  sum  `1'
  egen m_`1' = mean(`1'), by(hhea `2')
  egen sd_`1'=   sd(`1'), by(hhea `2')
  
  gen     out_`1'=0 if `1'<.
  replace out_`1'=1 if `1'< (m_`1'-(3*sd_`1')) & `1'<.
  replace out_`1'=2 if `1'> (m_`1'+(3*sd_`1')) & `1'<.
  tab     out_`1'  
*Next line is commented out because the mean and std. dev. variables are needed
*when exporting flagged outliers to Excel for review.
*  drop    m_`1' sd_`1'
end

********************************************************************************
* DEFINE MEDIAN_CALC PROGRAM CALLED IN DO FILE
********************************************************************************
/* This set of commands is used to calculate the median value that is then used
   to replace confirmed outliers and missing values. The same program is used 
   in all consumption expenditure do files (pov1 to pov8).

Median calculation rules:

a. First select the administrative units to be used to calculate medians at local
   levels: lowest (e.g., cluster), second lowest (e.g., district), third lowest 
   (e.g., region), etc.
   
b. If total # of valid observations of an item at the lowest administrative unit
   level (e.g., cluster) is greater or equal to 5, calculate median at that 
   administrative unit level.
   
c. If total # of valid observations of an item is less than 5 at the lowest 
   administrative level but greater or equal to 5 at next lowest administrative
   level (e.g.,district), calculate the median at that second lowest  
   administrative level.
   
c. If total # of valid observations of an item is less than 5 at the second
   lowest administrative level but greater or equal to 5 at next lowest 
   administrative level (e.g., region), calculate the median at that third lowest  
   administrative level.
   
d. If total # of valid observations of an item at the third lowest 
   administrative level is less than 5, but greater or equal to 5 at the sample
   level (whole study area), calculate the median at the sample level.
   
e. If total # of observations of an item in the sample is less than 5, don't 
   calculate any median. In that case, all observations should be reviewed 
   together to determine whether to include the item in the calculation, and 
   if so, what values are plausible. If the value is not plausible, it 
   should be set to missing.

CALC_MEDIAN is a Stata macro syntax written for this study to calculate median 
values for each item at local level using the rules mentioned above. In this 
syntax, cluster and district are used as the first lowest and second lowest 
administrative units, respectively. However, selection of relevant local 
administrative units are country and project specific, and therefore, the syntax 
needs to be adapted to reflect the specific administrative breakdown.
*/

cap prog drop CALC_MEDIAN
prog def CALC_MEDIAN

**SET IMPUTATION RULES
  gen  xflag=1 if `1' <.
  tab  xflag
  egen tothhea=sum(xflag), by(hhea `2')	 //# of non-missing cases at cluster level 
  egen totdist=sum(xflag), by(c05  `2') //# of non-missing cases at district level   
  egen totdreg=sum(xflag), by(c06  `2') //# of non-missing cases at region level    
  egen totproj=sum(xflag), by(`2')       //# of non-missing cases at project level
  
  gen     impute=1 if             tothhea>=5 & tothhea<. //>=5 cases per cluster
  replace impute=2 if impute==. & totdist>=5 & totdist<. //>=5 cases per distrist
  replace impute=3 if impute==. & totreg>=5 & totreg<. //>=5 cases per project
  replace impute=4 if impute==. & totproj>=5 & totproj<. //>=5 cases per project
  replace impute=5 if impute==. & totproj<5              //<5  cases per project
  tab     impute
  drop    xflag 
 
**CALCULATE LOCAL MEDIAN VALUES
  egen median_`1'1=median(`1'), by(hhea `2')  //cluster level
  egen median_`1'2=median(`1'), by(c05 `2')   //district level
  egen median_`1'2=median(`1'), by(c06 `2')   //region level
  egen median_`1'3=median(`1'), by(`2')		  //project level
   
  gen     med_`1'= median_`1'1 if impute==1 // >=5 non-missing cases at cluster level
  replace med_`1'= median_`1'2 if impute==2 // <5  non-missing cases at cluster level but >=5 at district level
  replace med_`1'= median_`1'2 if impute==3 // <5  non-missing cases at cluster level but >=5 at region level
  replace med_`1'= median_`1'3 if impute==4 // <5  non-missing cases at district level but >=5 at project level
*The next line is commented out because items with fewer than 5 cases at
*the highest (i.e., project) level should not be automatically imputed but 
*but rather these cases shoule be examined individually.
*  replace med_`1'= median_`1'3 if impute==5 // <5 non-missing cases at project level
  sum     med_`1'
  drop    median_`1'* 
  drop    tot* impute
end

// Use household-level data and keep relevant variables including survey specific 
** cluster, district, and project level variables
use  "$analytic\FTF ZOI Survey [Country] [Year] household data analytic.dta", clear 
keep hhea hhnum c05 c06 hhsize_dj v870* v8100r v8700r

********************************************************************************
// STEP 0: DROP HOUSEHOLDS THAT DID NOT COMPLETE SUB-MODULES 8.2-8.7
********************************************************************************
drop if v8700r != 1 

********************************************************************************
//STEP 1: PREPARE DATA SET
********************************************************************************
**1a. Flag households if none of the durable assets were owned by the household 
**    [v8702>=2]

sum   v8702*
quiet for var v8702*: recode X 3/max=., gen(Xx)   
egen  v8702xmin=rowmin(v8702*x)
tab   v8702xmin,m             //HH missing info on consumption expenditure on all items

sum v8702*x if v8702xmin==.  //HH missing answer to all items
sum v8702*x if v8702xmin==2  //HH answer is "no" to all items

/*
Note: If a household has all zero or missing for this sub-module, further 
investigation is advised.  If there are too many missing observations, it may
be preferable to drop the household from the poverty indicators analysis.
If the respondent answered that the household has no asset, the analyst should 
check for plausibility.  If it appears to be plausible, consumption expenditures
for this sub-module should be set equal to zero. 
*/

**1b. Drop flagged HHs from the working dataset. 
drop  if v8702xmin==.  
drop  if v8702xmin==2  
count
drop v8702*x v8702xmin

**1c. Change the data format from household level to item level.
reshape long v8701_ v8702_ v8703_ v8704_ v8705_ v8706_ , i(hhea hhnum c05 c06 hhsize_dj) j(j) string
des
rename *_ *
sum v870*
numlabel,add force
tab v8701,m
tab v8702,m

** 1d. Drop item if it is not owned
count
sum v87* if v8702==1
sum v87* if v8702==2
sum v87* if v8702==.
drop     if v8702>1

**1e. Create new item (item), current value (currvalue), purchased value (purcvalue) 
**   and durable good age (assetage) variables. 
**   Check for outliers and examine if the values are plausible
**-----------------------------------------------------------------------
clonevar item      = v8701 
clonevar currvalue = v8705 
clonevar purcvalue = v8706   

clonevar assetage  = v8704
replace  assetage = 1 if (v8703!=0 & v8706 > 0 & v8704==0) //Set asset age to 1 year if asset was purchased <1 year prior to survey @patricia, gts says if v8704<= 0. which one is right?

**1f. Check current values, purchase values, and asset age values, and set invalid values to missing
replace assetage=.  if assetage>=997
replace currvalue=. if currvalue >= 999999997
replace purcvalue=. if purcvalue >= 999999997

bys item: tab assetage
bys item: tab currvalue
bys item: tab purcvalue

********************************************************************************
//STEP 2: IDENTIFY AND VERIFY POTENTIAL OUTLIERS OF currvalue, purcvalue, AND assetage AND SET CONFIRMED OUTLIERS TO MISSING 
********************************************************************************
*2a. Run the FLAG_OUTLIERS macro to identify potential purcvalue outliers.

FLAG_OUTLIERS purcvalue 

tab out_purcvalue 
tab purcvalue if out_purcvalue >0  

*2b. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "6a_purcvalue_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_purcvalue > 0 & purcvalue !=.
gen Notes = ""
order hhea hhnum item purcvalue m_purcvalue sd_purcvalue Notes out_purcvalue, first
export excel "$analytic\Log\6a_purcvalue_outliers.xlsx", replace first(variable)
restore

*2c. Set the out_purcvalue value to be 0 if when reviewing potential outliers
*    in Step 2b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_purcvalue values, as applicable.

*replace out_purcvalue =0 if ... // Modify this IF statement to change 
*                                   extreme values to be non-outliers

*2d. Set the value of purcvalue to be missing for confirmed outliers.

replace purcvalue =. if out_purcvalue >0

*2e. Run the FLAG_OUTLIERS macro to identify potential currvalue outliers.

FLAG_OUTLIERS currvalue 

tab out_currvalue 
tab currvalue if out_currvalue >0  

*2f. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "6b_currvalue_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_currvalue > 0 & currvalue !=.
gen Notes = ""
order hhea hhnum item currvalue m_currvalue sd_currvalue Notes out_currvalue, first
export excel "$analytic\Log\6b_currvalue_outliers.xlsx", replace first(variable)
restore

*2g. Set the out_currvalue value to be 0 if when reviewing potential outliers
*    in Step 2f the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_currvalue values, as applicable.

*replace out_currvalue =0 if … //Modify this IF statement to change identified 
*                                extreme values to be non-outliers

*2h. Set the value of currvalue to be missing for confirmed outliers.

replace currvalue =. if out_currvalue >0

*2i. Run the FLAG_OUTLIERS macro to identify potential assetage outliers.

FLAG_OUTLIERS assetage 

tab out_assetage
tab asset_age if out_assetage >0  

*2j. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "6c_assetage_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_assetage > 0 & assetage !=.
gen Notes = ""
order hhea hhnum item assetage m_assetage sd_assetage Notes out_assetage, first
export excel "$analytic\Log\6c_assetage_outliers.xlsx", replace first(variable)
restore

*2k. Set the out_assetage value to be 0 if when reviewing potential outliers
*    in Step 2j the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_assetage values, as applicable.

*replace out_assetage =0 if … //Modify this IF statement to change identified 
*                                extreme values to be non-outliers

*2h. Set the value of assetage to be missing for confirmed outliers.

replace assetage =. if out_assetage >0

********************************************************************************
//STEP 3: CALCULATE MEDIAN VALUES OF purcvalue item AND REPLACE CONFIRMED 
*         OUTLIERS WITH MEDIAN
********************************************************************************
**3a. Original asset value
CALC_MEDIAN purcvalue item

sum     med_purcvalue
sum     purcvalue
replace purcvalue=med_purcvalue if inlist(out_purcvalue,1,2) & med_purcvalue!=.

**3b. Current asset value
*drop tot* impute
CALC_MEDIAN currvalue item

sum   med_currvalue
sum   currvalue
replace currvalue=med_currvalue if inlist(out_currvalue,1,2) & med_currvalue!=.

********************************************************************************
//STEP 4: CALCULATE ASSET DEPRECIATION RATE 
**				= 1-((currvalue/purcvalue)^(1/assetage))
** 		  This is a geometric depreciation model
********************************************************************************
*NOTE: Although it is possible for a good to increase in value (e.g., painting, 
*antique, baseball card), it would be categorized as an investment good and not
*as a consumption good.  This is unlikely to occur from our list of 
*household assets and if current value exceeds purchase value in the survey 
*data, it is likely due to an error during data collection (respondent or 
*data entry). Flag instances in which the current value of an asset is greater 
*than the purchase value and set to missing.  It will be replaced by the median 
*in Step 6).
 
*******************************************************************************/
gen     dep = .
replace dep = 1-(((currvalue)/purcvalue)^(1/assetage)) if (assetage !=0)	 
replace dep = . if currvalue > purcvalue
 
lab var dep "Depreciation rate of each item owned (average)" 
hist    dep

********************************************************************************
//STEP 5: IDENTIFY AND VERIFY POTENTIAL OUTLIERS OF dep AND SET VERIFIED 
*         OUTLIERS TO MISSING
********************************************************************************
*5a. Run the FLAG_OUTLIERS macro to identify potential dep outliers.

FLAG_OUTLIERS dep item  

tab out_dep 
tab dep if out_dep >0  

*5b. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "6c_dep_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_dep > 0 & dep !=.
gen Notes = ""
order hhea hhnum item dep currvalue purcvalue assetage m_dep sd_dep Notes out_dep, first
export excel "$analytic\Log\6c_dep_outliers.xlsx", replace first(variable)
restore

*5c. Set the out_dep value to be 0 if when reviewing potential outliers
*    in Step 5b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_dep values, as applicable.

*replace out_dep =0 if ... // Modify this IF statement to change 
*                             extreme values to be non-outliers

*5d. Set the value of dep to be missing for confirmed outliers.

replace dep =. if out_dep >0

********************************************************************************
//STEP 6: CALCULATE LOCAL MEDIAN VALUES OF DEP AND REPLACE OUTLIERS AND MISSING
**        VALUES WITH MEDIAN
********************************************************************************
*drop tot* impute

CALC_MEDIAN dep item

tab out_dep
sum med_dep

count    if med_dep==.
tabulate item, sum(med_dep)

replace dep = med_dep if out_dep > 0 & med_dep!=. 
replace dep = med_dep if dep ==. 

********************************************************************************
//STEP 7: CALCULATE ANNUAL RENTAL PRICE OF THE DURABLE GOODS (totrent_item1) 
********************************************************************************
*INSTRUCTION: Replace the avgintrate value with the average interest rate for the 
*country, which can be determined here: http://databank.worldbank.org/data/home.aspx, 
*under the World Development Indicators database and Real Interest Rates series.

*totrent_item1 = current value * (average real interest rate + depreciation rate)

gen    avgintrate=0
la var avgintrate "Average interest rate, [Country] over [X] years"
gen    totrent_item1=currvalue*(avgintrate + dep)   

********************************************************************************
//STEP 8: CALCULATE ANNUAL RENTAL EQUIVALENT OF THE DURABLE GOODS (totrent_item2)
********************************************************************************
gen  totrent_item2=(totrent_item1*v8703)
tab item, sum(totrent_item2)

********************************************************************************
//STEP 9: CALCULATE PCD RENTAL EQUIVALENT OF DURABLE GOODS (pcdrent_item) 
********************************************************************************
gen pcdrent_item=(totrent_item2/hhsize_dj)/365  
tab item, sum(pcdrent_item)

********************************************************************************
//STEP 10: IDENTIFY AND VERIFY POTENTIAL OUTLIERS OF pcdrent_item AND SET 
*          CONFIRMED OUTLIERS TO MISSING
** Note: pcdrent_item cannot be negative
********************************************************************************
*10a. Run the FLAG_OUTLIERS macro to identify potential pcdrent_item outliers.

FLAG_OUTLIERS pcdrent_item item  

sum pcdrent_item 
tab pcdrent_item if out_pcdrent_item < 0  

*10b.Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "6d_currvalue_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_pcdrent_item > 0 & pcdrent_item !=.
gen Notes = ""
order hhea hhnum item pcdrent_item totrent_item2 totrent_item1 currvalue avgintrate dep /// 
      m_pcdrent_item sd_pcdrent_item Notes out_pcdrent_item, first
export excel "$analytic\Log\6d_pcdrent_outliers.xlsx", replace first(variable)
restore

*10c.Set the out_pcdrent_item value to be 0 if when reviewing potential outliers
*    in Step 10b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_pcdrent_item values, as applicable.

*replace out_pcdrent_item =0 if ... // Modify this IF statement to change 
*                                      extreme values to be non-outliers

*10d.Set the value of pcdrent_item to be missing for confirmed outliers.

replace pcdrent_item =. if out_pcdrent_item >0

********************************************************************************
//STEP 11: CALCULATE LOCAL MEDIAN OF pcdrent_item AND REPLACE CONFIRMED OUTLIERS 
*          WITH MEDIAN
********************************************************************************
*drop tot* impute
CALC_MEDIAN pcdrent_item item

tab out_dep
sum med_dep

replace pcdrent_item=med_pcdrent_item if inlist(out_pcdrent_item,1,2) & med_pcdrent_item!=.
sum     pcdrent_item

********************************************************************************
//STEP 12: SUM pcdrent_item BY HHOLD AND CREATE HHOLD LEVEL DATA
********************************************************************************
egen pcdrent_hh=sum(pcdrent_item), by(hhea hhnum)
bys  hhea hhnum: keep if _n==1
la   var pcdrent_hh "Per capita daily household asset rental equivalent"

********************************************************************************
//STEP 13: MERGE BACK THE HHOLDS DROPPED IN STEP 1 AND SET THEIR pcdrent_hh to 0
******************************************************************************** 
** keep relevant HH variables (including survey specific cluster, district, and 
** project level variables)

mmerge hhea hhnum using "$analytic\FTF ZOI Survey [Country] [Year] household data analytic.dta", ///
       ukeep(hhea hhnum c05 c06 hhsize_dj v8100r v8700r)
	   
drop if v8700r != 1

replace  pcdrent_hh=0 if _merge==2

sum      pcdrent_hh
hist     pcdrent_hh 

********************************************************************************
//STEP 14: SAVE THE DATA FILE
********************************************************************************
rename pcdrent_hh pcd_asset

keep  hhea hhnum pcd_asset 
order hhea hhnum pcd_asset 
des
sort  hhea hhnum

la data "Per capita daily rental equivalent of durable goods consumed by HH"
save "$analytic\results\FTF ZOI Survey [Country] [Year] pov6_asset.dta",replace

disp "DateTime: $S_DATE $S_TIME"
log  close

