/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
******************** NON-FOOD CONSUMPTION IN THE PAST 1 MONTH ******************
******************************* [COUNTRY] [YEAR] *******************************
********************************************************************************
Description: This code is intended to calculate the per capita daily non-food 
consumption expenditure in the 1 month preceding the survey. This is the 3rd of 
8 preparatory syntax files to calculate the poverty indicators.

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
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] pov3_nfood_1m.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov3_nfood_1m.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax pov3_nfood_1m.do 
 
cap log close
cap log using  "$analytic\log\FTF ZOI Survey [Country] [Year] pov3_nfood_1m.log", replace
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
keep hhea hhnum c05 c06 hhsize_dj v830* v8700r v8100r

********************************************************************************
// STEP 0: DROP HOUSEHOLDS THAT DID NOT COMPLETE SUB-MODULES 8.2-8.7
********************************************************************************
drop if v8700r != 1
 
********************************************************************************
//STEP 1: PREPARE THE DATA
********************************************************************************
**1a. Flag households if none of the non-food items were consumed in the past  
**    one month. [v8302>=2 or v8302=.]

sum   v8302*
quiet for var v8302*: recode X 3/max=., gen(Xx)   
egen  v8302xmin=rowmin(v8302*x)
tab   v8302xmin,m  //HHs missing info on consumption expenditure on all items

sum v8302*x if v8302xmin==.  //HH missing answer on all items
sum v8302*x if v8302xmin==2  //HH answer is "no" to all items 

**1b. Drop flagged HHs from the working dataset. These households are added back 
**    into the dataset later in step 6.  Assuming it is legitimate 
**	  that these households did not make purchases on these items  
**    in the past month, their PCD non-food expenditures are set to 0 
**    later in  step 9.

drop  if v8302xmin==.  
drop  if v8302xmin==2  
count
drop v8302*x v8302xmin

**1c. Change the data format from household level to item level.
reshape long v8301_ v8302_ v8303_ , i(hhea hhnum c05 c06  hhsize_dj) j(j) string
des
rename *_ *
sum v830*

**1d. Drop the item if it is not consumed 
la var v8302 "HH purchased non-food item, past 1 month"
tab     v8302,m
sum  if v8302>=2
drop if v8302>=2

**1e. Create new variables to use in the analysis 
clonevar item=v8301          
la var   item "Non-food item, past 1 month" 
gen      totnfood_item=v8303 //total nonfood expenditure on [item]
la var   totnfood_item "Total expenditure on non-food item, past 1 month" 

**1f. Drop items related to health (item numbers 8228 to 8236 in core 
**    questionnaire) that do not contribute to household consumption but are
**	  asked to respondents.  The range should be adjusted to the 
**    country-specificquestionnaire. 

drop if inrange(item,8228,8236) 

**1g. Check the values for each item and set invalid values to missing.
**    Refuse=999999997, DK=999999998, Missing=999999999

bys     item: tab totnfood_item
replace totnfood_item = . if totnfood_item >= 999999997 

********************************************************************************
//STEP 2: CALCULATE PER CAPITA DAILY NONFOOD CONSUMPTION EXP ON EACH ITEM 
*         PURCHASED IN THE PAST 1 MONTH
********************************************************************************
gen    pcdnfood_item = (totnfood_item/hhsize_dj)/30 if totnfood_item!=.
sum    pcdnfood_item 
la var pcdnfood_item "PCD non-food consumption expenditure on item, past 1 month"

********************************************************************************
//STEP 3: IDENTIFY AND VERIFY POTENTIAL OUTLIERS OF pcdnfood_item AND SET 
*         CONFIRMED OUTLIERS TO MISSING 
********************************************************************************
*3a. Run the FLAG_OUTLIERS macro to identify potential pcdnfood_item outliers.

FLAG_OUTLIERS pcdnfood_item

tab out_pcdnfood_item 
tab pcdnfood_item if out_pcdnfood_item >0  

*3b. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "3a_pcdnfood_item_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_pcdnfood_item > 0 
gen Notes = ""
order hhea hhnum item pcdnfood_item m_pcdnfood_item sd_pcdnfood_item Notes out_pcdnfood_item, first
export excel "$analytic\Log\3a_pcdnfood_item_outliers.xlsx", replace first(variable)
restore

*3c. Set the out_pcdnfood_item value to be 0 if when reviewing potential outliers
*    in Step 3b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_pcdnfood_item values, as applicable.

*replace out_pcdnfood_item =0 if ... // Modify this IF statement to change 
*                                       extreme values to be non-outliers

*3d. Set the value of pcdnfood_item to be missing for confirmed outliers.

replace pcdnfood_item=. if out_pcdnfood_item>0

********************************************************************************
//STEP 4: CALCULATE LOCAL MEDIAN OF pcdnfood_item AND REPLACE OUTLIERS WITH MEDIAN 
********************************************************************************
*drop tot* impute
CALC_MEDIAN pcdnfood_item item

tab out_pcdnfood_item
sum med_pcdnfood_item

replace pcdnfood_item= med_pcdnfood_item if inlist(out_pcdnfood_item,1,2) & med_pcdnfood_item!=.

/*
sort hhea item
list hhea item pcdnfood_item out_pcdnfood* impute, sepby(hhea item) nola
*/
********************************************************************************
//STEP 5: SUM pcdnfood_item BY HHOLD TO CREATE HHOLD LEVEL DATA
********************************************************************************
//HH consumption in the past 1 month

egen pcdnfood_hh=sum(pcdnfood_item), by(hhea hhnum) 
bys  hhea hhnum: keep if _n==1

count
sum  pcdnfood_hh
hist pcdnfood_hh

********************************************************************************
//STEP 6: MERGE BACK THE HHOLDS DROPPED IN STEP 1 
********************************************************************************
** keep relevant variables including survey specific cluster, district, 
** and project level variables

mmerge hhea hhnum using "$analytic\Mali ZOI Survey 2019 household data analytic.dta", ///
       ukeep(hhea hhnum c05 c06 wgt_hh genhhtype hhsize_dj v8700r v8100r) 
count  if pcdnfood_hh==. 

drop if v8700r != 1

********************************************************************************
//STEP 7: IDENTIFY AND VERIFY POTENTIAL OUTLIERS OF pcdnfood_hh AND SET 
*         CONFIRMED OUTLIERS TO MISSING
********************************************************************************
*7a. Run the FLAG_OUTLIERS macro to identify potential pcdnfood_hh outliers.

FLAG_OUTLIERS pcdnfood_hh 

tab out_pcdnfood_hh  
tab pcdnfood_hh if out_pcdnfood_hh >0  

*7b. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "3b_pcdnfood_hh_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_pcdnfood_hh > 0 & out_pcdnfood_item!=.
gen Notes = ""
order hhea hhnum pcdnfood_hh m_pcdnfood_hh sd_pcdnfood_hh Notes out_pcdnfood_hh, first
export excel "$analytic\Log\3b_pcdnfood_hh_outliers.xlsx", replace first(variable)
restore

*7c. Set the out_pcdnfood_hh value to be 0 if when reviewing potential outliers
*    in Step 7b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_pcdnfood_hh values, as applicable.

*replace out_pcdnfood_hh=0 if ... // Modify this IF statement to change 
*                                    extreme values to be non-outliers

*7d. Set the value of pcdnfood_hh to be missing for confirmed outliers.

replace pcdnfood_hh=. if out_pcdnfood_hh>0

********************************************************************************
//STEP 8: CALCULATE LOCAL MEDIAN of pcdnfood_hh AND REPLACE CONFIRMED OUTLIERS 
*         WITH MEDIAN 
********************************************************************************
CALC_MEDIAN pcdnfood_hh 

tab out_pcdnfood_hh
sum med_pcdnfood_hh

replace pcdnfood_hh= med_pcdnfood_hh if inlist(out_pcdnfood_hh,1,2) & med_pcdnfood_hh!=.
count if pcdnfood_hh==.

********************************************************************************
//STEP 9: SET pcdnfood_hh TO 0 IF  MISSING. 
********************************************************************************
** A missing value means that the household either did not purchase any of these 
*  items in the past month or the household is missing consumption information.

replace pcdnfood_hh = 0 if pcdnfood_hh==.

sum     pcdnfood_hh
hist    pcdnfood_hh

********************************************************************************
//STEP 10: SAVE THE DATA FILE
********************************************************************************
rename pcdnfood_hh pcd_nfood_1m

la var pcd_nfood_1m "PCD nonfood consumption expenditure on item, past 1 month"

order hhea hhnum pcd_nfood_1m
keep  hhea hhnum pcd_nfood_1m
des
sort  hhea hhnum

la data "Per capita daily non-food consumption expenditure by HH, past 1 month"
save    "$analytic\results\FTF ZOI Survey [Country] [Year] pov3_nfood_1m.dta", replace 

di "Date:$S_DATE $S_TIME"
log     close
