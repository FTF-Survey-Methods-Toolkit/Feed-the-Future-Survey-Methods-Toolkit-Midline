/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
****************** FOOD CONSUMPTION IN THE PAST 7 DAYS *************************
**************************** [COUNTRY] [YEAR] **********************************
********************************************************************************
Description: This code calculates the per capita daily food consumption 
expenditure in the 7 days preceding the survey. This is 1 of 8 preparatory  
syntax files to calculate the poverty indicators.

- This syntax file was developed using the core Feed the Future ZOI Survey phase 
  one endline/phase two baseline core questionnaire. 
- It must be adapted for the final country-specific questionnaire, and all 
  results must be double-checked carefully. 
- Specifically, examine outliers one by one for plausibility before replacing 
  them with the median.  

Syntax prepared by ICF, 2018
Syntax revised by ICF, May 2020, September 2023

This syntax file was developed using the core Feed the Future phase 1 endline/
phase 2 baseline ZOI Survey questionnaire and revised using the core Feed the 
Future Midline Survey parallel survey questionnaire. It must be adapted for the 
final country-specific questionnaire. The syntax was only be partially tested 
using ZOI Survey data; therefore, double-check all results carefully and 
troubleshoot to resolve any issues identified. 
********************************************************************************
********************************************************************************

NOTE: Module 8 of the Feed the Future ZOI Survey questionnaire is composed
of 7 sub-modules. Together, they collect the data necessary to calculate 
the poverty indicators (see the Guide to Feed the Future Statistics, Chap. 9).
Although each sub-module is treated separately in individual syntax files,
(pov1 to pov7), results are combined at the end (in pov8) to create a 
single household-level variable, the daily per capita (PCD) consumption 
expenditure, which is then used to derive the poverty indicators.  
It is therefore important to make sure that there are sufficient data in 
each sub-module to produce the aggregate variable, even if v8100r and v8700r (outcome of the module) is coded as completed (coded 01). 

As a general rule, if any of the sub-modules contains a large number of missing 
or don't know responses (coded as ...996 or ...998 ), or if the respondent 
refused to respond or complete the module, further investigation is advised and 
it may be preferable to drop the household from the poverty indicators analysis.  

There are two exceptions: (1) if the food sub-module (v810*) is missing for a 
household that has acceptable data on the other sub-modules, then the PCD 
food consumption of these households is replaced by the local median in this 
syntax file, as every household must have consumed food in the past 7 days; and
(2) if the housing sub-module (v860*) is the missing sub-module for a household 
with otherwise acceptable data, then a rental equivalent should be estimated
using the hedonic regression approach described in pov7, as every household must 
have a dwelling. 

It may be legitimate for a household to record no expenses on a sub-module 
(although some scrutiny should be applied).  In this case the sub-module 
should be included in PCD expenditure with the value for these items equal to 0.
 
********************************************************************************/
set more off
clear all
macro drop _all
set maxvar 10000

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [Country] [Year]\Syntax" 
global analytic  "C:\FTF ZOI Survey [Country] [Year]\Analytic"

//Input data:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log result:  $analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] pov1_food.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov1_food.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax pov1_food_1w.do 
 
cap log close
cap log using  "$analytic\Log\FTF ZOI Survey [Country] [Year] pov1_food.log", replace

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

********************************************************************************
********************************************************************************
* Load the household-level data and keep variables needed for the analysis, 
* including variables from the food consumption sub-module of Module 8 (v810*), 
* the module 8 outcome variable (v8100r, v8700r), and project-specific variables such as:
* cluster (hhea), household number (hhnum), district and region (c05, c06), and
* household size based on usual household members (hhsize_dj). 
* INSTRUCTION: Adapt list of variables to be kept for country-specific ZOI Survey.

********************************************************************************
* STEP 1: PREPARE THE DATA 
********************************************************************************
*1a. Load the household-level analytic data file and keep only the variables for 
*    cluster number, household number, geographic administrative units, de jure 
*    household size, sub-module 8.1 variables (variables starting with `v810'), 
*    and the outcome variables for Module 8 (v8100r and v8700r). Drop households 
*    that did not complete sub-module 8.1.  
use  "$analytic\FTF ZOI Survey [Country] [Year] household data analytic.dta", clear 
keep hhea hhnum c05 c06 hhsize_dj v810* v8100r v8700r
drop if v8100r != 1

*1b. Flag households if none of the food items were consumed in the seven days 
*    preceding the survey (that is: v8102>=2 or v8102=. for all food items).

sum   v8102*
quiet for var v8102*: recode X 3/max=., gen(Xx) 
egen  v8102xmin=rowmin(v8102*x)
tab   v8102xmin,m  //HHs missing info on consumption expenditure on all items

sum v8102*x if v8102xmin==.  //HH answer is missing for all food items
sum v8102*x if v8102xmin==2  //HH answer is "no" to all food items 

*1c. Drop households flagged in Step 1b from the working dataset. These households 
*    are added back into the dataset later (Step 10). Assuming that every 
*    household must have consumed some food in the seven days preceding the 
*    survey, PCD consumption of these dropped households is replaced by the  
*    local median (Step 12).

drop if v8102xmin==. 
drop if v8102xmin==2 
count
drop v8102*x v8102xmin

*1d. Change the data format from household level to food item level. Original 
*    food consumption data are in flat format, meaning there is one record per 
*    household. For data management purposes, convert the data from flat format 
*    to rectangular format, meaning that for each household, there are multiple 
*    records - one for each food item. 

reshape long v8101_ v8102_ v8103a_ v8103b_ v8104a_ v8104b_ v8105_ v8106a_ v8106b_ ///
        v8106c_ v8107a_ v8107b_ v8107c_, i(hhea hhnum c05 c06 hhsize_dj) j(j) string
rename  *_ *
des
count

*1e. Drop records for food items that are not consumed.

tab     v8102,m
sum  if v8102>=2
drop if v8102>=2 

*1f. Label all of the variables.

la var v8101  "Name of food item" 
la var v8102  "Household consumed item, past week"

la var v8103a "Quantity HH consumed, past week" 
la var v8103b "Unit of quantity consumed, past week" 

la var v8104a "Quantity consumed from purchases, past week" 
la var v8104b "Unit of quantity purchased, past week" 
la var v8105  "Value of quantity purchased, past week"

la var v8106a "Quantity consumed from production, past week" 
la var v8106b "Unit of quantity produced, past week" 
la var v8106c "Value of quantity produced, past week"

la var v8107a "Quantity consumed from gifts or other sources, past week"
la var v8107b "Unit of quantity received, past week"
la var v8107c "Value of quantity received, past week"  

*1g. Create analytic variables for food quantities, units, and monetary values 
*    to use in the analysis. 

clonevar item=v8101 
clonevar cons_q=v8103a  //consumption quantity
clonevar cons_u=v8103b  //consumption unit

clonevar purc_q=v8104a  //purchase quantity
clonevar purc_u=v8104b  //purchase unit
clonevar purc_v=v8105   //purchase monetary value

clonevar prod_q=v8106a  //production quantity
clonevar prod_u=v8106b  //production unit
clonevar prod_v=v8106c  //production monetary value

clonevar gift_q=v8107a  //gift and other sources quantity
clonevar gift_u=v8107b  //gift and other sources unit
clonevar gift_v=v8107c  //gift and other sources monetary value

global quan cons_q purc_q prod_q gift_q
global unit cons_u purc_u prod_u gift_u
global val  purc_v prod_v gift_v

*1h. Check the quantity and monetary value variables for each food item and set
*    invalid values to missing. 
*    Refuse=9999997,999999997; DK=9999998,999999998; Missing=9999999, 999999999
*INSTRUCTION: Ensure the number of digits for each of the variables is 
*             appropriate given the final country-adapted questionnaire.
 
bys item: tab1 $quan $val,m
for var $quan: replace X=. if inlist(X, 9999997,   9999998,   9999999)           
for var $val:  replace X=. if inlist(X, 999999997, 999999998, 999999999) 

sum $quan $val //Ensure there are no invalid values. Outliers are checked in later steps.

*1i. Verify units reported for each food item are the same within one food item
*    record--that is, the same units are used for consumption and all of the 
*    sources that are reported for that food item in that record--up to 3 sources 
*    (i.e, purchase, production, and gifts/other sources).   

*1i.1.First, create a variable (prob_unit) to flag records in which the 
*     units reported are not the same for consumption and all sources reported.

gen     prob_unit=0
replace prob_unit=1 if (cons_u!=purc_u) & purc_u !=.
replace prob_unit=1 if (cons_u!=prod_u) & prod_u !=.
replace prob_unit=1 if (cons_u!=gift_u) & gift_u !=.

*1i.2.Second, review the records flagged in above (with prob_unit=1) and correct 
*     any issues, if possible. Corrections can only be made for issues with 
*     clear-cut resolutions. If the issue cannot be corrected, set the unit 
*     variable (i.e., cons_u, purc_u, prod_u, gift_u) that is causing the issue  
*     to missing. For example, if the quantity consumed unit is kilograms, the
*     purchased quantity unit is liters, and the item is something that is 
*     measured by weight, update the purchased units to be kilograms. As another
*     example, if the units for quantity consumed are liters and the units for 
*     quantity produced are milliliters, look at the quantities consumed and 
*     produced and decide which units make sense and update accordingly. 
*     If the solution is not obvious,  because of the purchased quantity 
*     reported, set the purchased quantity units to missing. 

tab prob_unit

list hhea hhnum item cons_* purc_* prod_* gift_* if prob_unit==1, sepby(item) noobs nola
*INSTRUCTIONS: Add syntax to update the quantity and unit values as needed per
*the review performed.

*1j. Drop the food item if values of all 7 variables measuring quantities and 
*    monetary values of the item are missing. 

for    var $quan $val: recode X 0=. //Recode zeros to missing 
egen   miss_data=rmiss($quan $val)
tab    miss_data	   
sum    $quan $val if miss_data==7  //If all 7 vars are missing then miss_data=7

drop if miss_data==7
drop    miss_data
count

*1k. Verify that for each food item record, the quantity consumed equals the sum 
*    of quantities from the 3 sources (i.e., v8103a = v8104a + v8106a + v8107a).
*    The sum will not equal the quantity consumed if, for example, there is 
*    repetition of quantities for multiple sources and the sum ends up to be
*    two or three times the quantity consumed.  In theory, because of the way 
*    the questions are formulated, it should be the same, but in practice, it
*    may differ. A household may report quantities obtained from various sources
*    that were not entirely consumed in the past 7 days, or there could be
*    data entry errors.  We treat an amount consumed greater than the sum
*    differently from an amount consumed less than the sum. 

*1k.1.Create a variable (sumfood1) equal to the sum of quantities from the 3 
*     sources and compare the new variable to the quantity consumed. 

egen double sumfood1=rowtotal(purc_q prod_q gift_q) 
compare sumfood1 cons_q

*1k.2.If the quantity consumed is greater than the sum of quantities from the 3 
*     sources, replace the quantity consumed with sumfood1. That is, if 
*     cons_q > (purc_q + prod_q + gift_q), then adjust cons_q to equal the sum. 
*     This is because the quantity consumed cannot be greater than the amounts
*     obtained from various sources.

replace cons_q= sumfood1 if cons_q>sumfood1 

*1k.3.Create a flag (flag_1) equal to 1 if the quantity and units consumed equal 
*     the quantity and units purchased, and set the quantity and units for 
*     produced and gifted/other sources to missing.
*     FLAG_1: IF CONSUMPTION QUANTITY=PURCHASED QUANTITY & 
*                CONSUMPTION UNIT=PURCHASED UNIT, THEN SET PRODUCED & GIFT VARIABLES=.

gen  flag_1=1 if cons_q==purc_q & cons_u==purc_u 
tab  flag_1
sort item
list hhea hhnum item cons_* purc_* prod_* gift_* if flag_1==1, sepby(item) noobs nola
for  var prod_? gift_?: replace X=. if flag_1==1

*1k.4.Create a flag (flag_2) equal to 1 if the quantity and units consumed equal 
*     the quantity and units produced, and set the quantity and units for 
*     purchased and gifted/other sources to missing.
*     FLAG_2: IF CONSUMPTION QUANTITY=PRODUCED QUANTITY & 
*                CONSUMPTION UNIT=PRODUCED UNIT, THEN SET PURCHASED & GIFT VARIABLES=.

gen  flag_2=1 if cons_q==prod_q & cons_u==prod_u
tab  flag_2
list hhea hhnum item cons_* purc_* prod_* gift_* if flag_2==1, sepby(item) noobs nola
for  var purc_? gift_?:replace X=. if flag_2==1

*1k.5.Create a flag (flag_3) equal to 1 if the quantity and units consumed equal 
*     the quantity and units gifted/from other sources, and set the quantity and  
*     units for purchased and produced to missing.
*     FLAG_3: IF CONSUMPTION QUANTITY=GIFT QUANTITY & 
*                CONSUMPTION UNIT=GIFT UNIT, THEN PURCHASED & PRODUCED VARIABLES=.

gen  flag_3=1 if cons_q==gift_q & cons_u==gift_u 
tab  flag_3
list hhea hhnum item cons_* purc_* prod_* gift_* if flag_3==1, sepby(item) noobs nola
for  var purc_? prod_?: replace X=. if flag_3==1

*1k.6.Create a variable (sumfood2) equal to the sum of the quantities from the 3
*     sources, and then create a second variable (flag_4) equal to 1 if sumfood2 
*     is not equal to the quantity consumed. 
*     FLAG_4=1: IF CONSUMPTION QUANTITY NOT EQUAL TO PURCHASED+PRODUCED+GIFTED QUANTITIES

egen double sumfood2=rowtotal(purc_q prod_q gift_q) 
compare sumfood2 cons_q
gen     flag_4=1 if sumfood2!=cons_q

*1k.7.Save the flagged records with relevant admin. unit identifiers to an Excel 
*    file: "flag4.xlsx."
*    Open the Excel file and carefully examine each record one by one to determine
*    what the issue may be (e.g., data entry errors in quantity or value variables), 
*    whether a correction can be made, and what should the correction be. 

preserve
keep if flag_4==1 
order hhea hhnum item sumfood2 cons_* purc_* prod_* gift_* 
export excel "$analytic\Log\flag4.xlsx", replace first(variable)
restore

*1k.8.Add syntax to update the records that can be corrected, per the examination 
*     performed in Step 1j.7.
*INSTRUCTIONS: Add syntax to make corrections to the food item variables.

********************************************************************************
* STEP 2:CONVERT UNITS TO THE SAME NUMERAIRE TO THE EXTENT POSSIBLE
*        TO CALCAULTE UNIT PRICE AND RECONCILE UNITS OF MEASURE.
*        IN ADDITION, CHECKING OUTLIERS REQUIRE ALL THE UNITS OF AN ITEM TO BE THE SAME.
********************************************************************************
*Identify the type (i.e., weight, volume, count units), name, and number of 
*units of measurement collected in the country-specific survey. The field team should
*have obtained or developed  a country-specific conversion table. Then customize 
*the syntax in this step to convert units to the same numeraire (i.e., standard 
*units). The units in the syntax below are from the sub-module 8.1 of the core
*ZOI Survey questionnaire: HOUSEHOLD CONSUMPTION EXPENDITURE - FOOD CONSUMPTION
*OVER PAST 7 DAYS. This requires that you:
*
* i)   List all measurement units reported for quantity consumed, purchased, 
*      produced, and gifted. 
* ii)  Check whether country-specific (or local) units have an equivalent in 
*      standard/metric units for conversion. Consult the unit conversion table
*      developed for the country-specific survey at the time of fieldwork.
* iii) Update the syntax in this step for the country-specific survey. For 
*      example, replace 'xxxxx' with the metric/standard units equivalent.

*2a. Create variables to keep unit, value, and quantity variables at this point
*    in the process (at the beginning of Step 2) as a backup/reference.
foreach var of varlist cons_u *_v *_q {
  clonevar orig_`var' = `var'
}	

*2b. Create a global macro (gl) for each weight unit included in the survey 
*    equal to the factor used to convert it to the numeraire for weights (gram).
*    INSTRUCTIONS: 
*    - Add syntax for any additional units used to report weight quantities.
*    - Remove any units that were not used in the survey.
*    - Replace 'xxxxx' with the metric/standard units equivalent.

gl     unit1           1000      //     1. KILOGRAMME (KG)
gl     unit18           1        //    18. GRAM (G)
gl     unit2           50000     //     2. 50 KG. BAG
gl     unit3           90000     //     3. 90 KG. BAG
gl     unit4           xxxxx     //     4. PAIL (SMALL)
gl     unit5           xxxxx     //     5. PAIL (LARGE)
gl     unit6           xxxxx     //     6. NO.10 PLATE
gl     unit7           xxxxx     //     7. NO.12 PLATE
gl     unit8           xxxxx     //     8. BUNCH
gl     unit10          xxxxx     //    10. HEAP
gl     unit11          xxxxx     //    11. BALE
gl     unit12          xxxxx     //    12. BASKET (DENGU) SHELLED
gl     unit13          xxxxx     //    13. BASKET, UNSHELLED
gl     unit14          xxxxx     //    14. OX-CART, UNSHELLED
gl     unit16          xxxxx     //    16. CUP
gl     unit17          xxxxx     //    17. TIN

*2c. Convert all weight units to grams (g), the standard unit for weight.

* The syntax below converts all weight units to a standard unit (grams). The 
* syntax is an example to be adapted based on the number of units collected in
* the country-specific survey. If the survey collected 100 units of measurements
* (excluding "Other"), regardless of the type of unit, then update the  
* 'forval f=1/23' below to be 'forval f = 1/100'. Then update the 'numlist' 
*  values to be the unit numbers for weight units, as defined in Step 2b. 

egen jj=group(j) //create a variable (jj) with a unique value for each food item 

forval f=1/23 {
  foreach u of numlist 1 2 3 4 5 6 7 8 10 11 12 13 14 16 17 {	
	foreach v in purc prod gift cons{
	  replace `v'_q = `v'_q*${unit`u'} if jj==`f' & cons_u==`u'	
	}
  }
}

*2d. Create a global macro for each volume unit included in the survey equal to 
*    the factor used to convert it to the numeraire for volumes (milliliters).
*    INSTRUCTION: Add syntax for any additional units used to report liquid 
*    quantities or volumes.
gl     unit15      1000         // 15. LITRE   
gl     unit19      1            //  19. MILLILITRE

*2e. Convert all volume units to milliliters (ml), the standard unit for 
*    liquid volume.

* The syntax below converts all volume units to a standard unit (milliliters). 
* The syntax is an example to be adapted based on the number of units collected in
* the country-specific survey. If the survey collected 100 units of measurements
* (excluding "Other"), regardless of the type of unit, then update the  
* 'forval f=1/23' below to be 'forval f = 1/100'. Then update the 'numlist' 
*  values to be the unit numbers for volume units, as defined in Step 2d. 

forval f=1/23 {
  foreach u of numlist 15 19 {	
    foreach v in purc prod gift cons{
	  replace `v'_q = `v'_q*${unit`u'} if jj==`f' & cons_u==`u'	
	}
  }
}

*2f. Create a global macro for each count unit included in the survey equal to 
*    the factor used to convert it to the numeraire for counts (pieces).
*    INSTRUCTION: Add syntax for any additional units used to report piece/count quantities.
gl    unit9     2     //    96. PAIR    
gl    unit96    12    //   96. DOZEN (this is example; replace with appropriate unit)    

*2g. Convert count units to pieces, the standard unit for counts.

* The syntax below converts all count units to a standard unit (piece). 
* The syntax is an example to be adapted based on the number of units collected in
* the country-specific survey. If the survey collected 100 units of measurements
* (excluding "Other"), regardless of the type of unit, then update the  
* 'forval f=1/23' below to be 'forval f = 1/100'. Then update the 'numlist' 
*  values to be the unit numbers for count units, as defined in Step 2f. 

forval f=1/23 {
  foreach u of numlist 9 96 {	
	foreach v in purc prod gift cons{
	  replace `v'_q = `v'_q*${unit`u'} if jj==`f' & cons_u==`u'	
	}
  }
}		

sum   purc_v purc_q 
count if purc_v==. & purc_q==.

*2h. Calculate the unit price of each food item (unitprice_item) using the 
*    following rules: 
*    - If (at least some of) the food item was purchased, 
*      unitprice_item = purchase price / purchase quantity.

*    - If the item was not purchased, but (at least some of) it was produced by the household,
*      unitprice_item = production value / production quantity.

*    - If the item was not purchased or produced, but it was  
*      obtained as a gift or from other sources, 
*      unitprice_item = gift value / gift quantity.

gen      unitprice_item = (purc_v/purc_q) if (purc_v>0 & purc_q>0)  		
replace  unitprice_item = (prod_v/prod_q) if (prod_v>0 & prod_q>0) & unitprice_item==.  
replace  unitprice_item = (gift_v/gift_q) if (gift_v>0 & gift_q>0) & unitprice_item==.  
sum      unitprice_item
count if unitprice_item==.  // ## items missing unit price

tab item, sum(unitprice_item)
count
la var unitprice_item "Per unit price of [item] consumed in the past week"

********************************************************************************
* STEP 3: IDENTIFY AND VERIFY POTENTIAL UNIT PRICE OUTLIERS OF EACH ITEM, 
*         AND SET CONFIRMED OUTLIERS TO MISSING
*******************************************************************************/
*3a. Run the FLAG_OUTLIERS macro to identify potential unit price outliers.

FLAG_OUTLIERS unitprice_item 

tab out_unitprice_item  
tab unitprice_item if out_unitprice_item > 0  

*3b. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "1a_food_unitprice_item_outliers.xlsx."
*    Open the Excel file and examine each outlier one by one for plausibility. 

preserve
keep if out_unitprice_item > 0 & prob_unit > 0
gen totalexp_using_reportedvalue = unitprice_item*cons_q
gen Notes = ""
order hhea hhnum item cons_u m_unitprice_item sd_unitprice_item ///
      unitprice_item Notes, first
rename orig_* original_*
export excel "$analytic\Log\1a_food_unitprice_item_outliers.xlsx", replace first(variable)
restore

*3c. Set the out_unitprice_item value to be 0 if when reviewing potential outliers
*    in Step 3b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_unit_price_item values, as applicable.

* replace out_unitprice_item=0 if ... // Modify this IF statement to change 
*                                        extreme values to be non-outliers

*3d. Set the value of unitprice_item to be missing for confirmed outliers.

replace unitprice_item=. if out_unitprice_item > 0  

drop m_* sd_*

********************************************************************************
//STEP 4: CALCULATE LOCAL MEDIAN OF unitprice_item BY ITEMS
********************************************************************************
*4a. Run the CALC_MEDIAN macro to calculate the local median for unitprice_item 
*    for each food item.

CALC_MEDIAN unitprice_item item
  
sum med_unitprice_item

********************************************************************************
* STEP 5: CALCULATE TOTAL HOUSEHOLD FOOD CONSUMPTION EXPENDITURE ON EACH FOOD  
*         ITEM IN THE PAST 1 WEEK
*         USE med_unitprice_item FROM STEP 4 TO IMPUTE MISSING UNIT PRICE VALUES
********************************************************************************
des $quan $val 
sum $quan $val 

*5a. Recode missing values to 0 [for data management]

for var $quan $val: recode X .=0
recode med_unitprice_item (.=0)

*5b. If the unit price for the food item is not missing, set the total household 
*    food consumption expenditure equal to the item's unit price multiplied by 
*    the quantity consumed.

gen     totfood_item=.
replace totfood_item=cons_q * unitprice_item if unitprice_item!=.

*5c. If the food item was purchased from a vendor (food items 8167-8186) and 
*    purc_q is missing & purc_v > 0, set the total household food consumption
*    expenditure equal to the monetary value of the food item.
*INSTRUCTIONS: Be sure to check the questionnaire to confirm food item codes
*for foods from vendors and update inrange syntax as needed.

replace totfood_item = purc_v if purc_q==. & purc_v > 0 & inrange(v8101, 8167, 8186)

*5d. If the unit price for the food item is missing, set the total household
*    food consumption expenditure equal to the quantity consumed multiplied by
*    the median unit price for the food item.

replace totfood_item = cons_q * (med_unitprice_item) if totfood_item==. 

********************************************************************************
* STEP 6: CALCULATE PCD FOOD CONSUMPTION OF EACH FOOD ITEM IN THE PAST 1 WEEK
********************************************************************************  
*Create a variable (pcdfood_item) to capture the daily per capita food consumption
*of each food item during the seven days preceding the survey in local currency
*by dividing the variable created in Step 5 by the number of usual members in 
*the household (hhsize_dj) and the number of days in the week.

gen pcdfood_item=(totfood_item/hhsize_dj/7)
tabulate item, sum(pcdfood_item)
lab var pcdfood_item "Per capita daily consumption of food item in LOCAL currency"

********************************************************************************
* STEP 7: IDENTIFY AND VERIFY POTENTIAL pcdfood_item OUTLIERS, AND SET CONFIRMED 
*         OUTLIERS TO MISSING 
********************************************************************************
*7a. Run the FLAG_OUTLIERS macro to identify potential pcdfood_item outliers.

FLAG_OUTLIERS pcdfood_item

tab out_pcdfood_item 
tab pcdfood_item if out_pcdfood_item > 0  

*7b. Save the flagged outliers with relevant admin. unit identifiers to an Excel  
*    file: "1b_food_unitprice_item_outliers.xlsx" for review.
*    Open the Excel file and examine each outlier one by one for plausibility 
*    before replacing them with the median.
 
preserve
keep if out_pcdfood_item > 0 & prob_unit > 0
gen Notes = ""
order hhea hhnum item cons_u m_pcdfood_item sd_pcdfood_item pcdfood_item Notes, first
export excel "$analytic\Log\1b_food_pcdfood_item_outliers.xlsx", replace first(variable)
restore

*7c. Set the out_pcdfood_item value to be 0 if when reviewing potential outliers
*    in Step 7b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_pcdfood_item values, as applicable.

* replace out_pcdfood_item=0 if ... // Modify this IF statement to change 
*                                      extreme values to be non-outliers

*7d. Set the value of pcdfood_item to be missing for confirmed outliers.

replace pcdfood_item=. if out_pcdfood_item > 0   

drop m_* sd_*

********************************************************************************
* STEP 8: CALCULATE LOCAL MEDIAN pcdfood_item VALUES FOR EACH ITEM AND
*   	  REPLACE VERIFIED OUTLIERS WITH THE MEDIAN 
********************************************************************************
*8a. Run the CALC_MEDIAN macro to calculate the local median for pcdfood_item 
*    for each food item.
CALC_MEDIAN pcdfood_item item   

tab out_pcdfood_item
sum med_pcdfood_item

*8b. Replace outliers confirmed in Step 7b and missing values with the local median.
replace pcdfood_item=med_pcdfood_item if inlist(out_pcdfood_item,1,2) & med_pcdfood_item!=.
replace pcdfood_item=med_pcdfood_item if pcdfood_item==.

********************************************************************************
* STEP 9: SUM pcdfood_item BY HOUSEHOLD AND CREATE HOUSEHOLD LEVEL VARIABLE
********************************************************************************
*Create a variable (pcdfood_hh) that captures the total daily per capita food 
*consumption expenditure for the household in the week preceding the survey.

egen pcdfood_hh=sum(pcdfood_item), by(hhea hhnum) 
bys  hhea hhnum: keep if _n==1
count
sum  pcdfood_hh
hist pcdfood_hh

lab var pcdfood_hh "Per capita daily food consumption expenditure, past 1 week"

********************************************************************************
* STEP 10: MERGE HOUSEHOLDS MISSING DATA BACK INTO THE WORKING DATA FILE
********************************************************************************
*This includes households missing all non-food consumption expenditure data 
*and households that reported no expenditures on any food items in the seven 
*days preceding the survey. Keep relevant variables including survey-specific 
*cluster, district, and project level variables.
********************************************************************************
*10a. Using the household analytic data file, add households that were dropped in 
*     Step 1b back into the working data file.
*INSTRUCTIONS: Adapt merge command to keep variables applicable to the ZOI Survey.

mmerge hhea hhnum using "$analytic\FTF ZOI Survey [Country] [Year] household data analytic.dta", ///
       ukeep(hhea hhnum wgt_hh genhhtype_dj hhsize_dj c05 c06 v8100r v8700r)

*10b. Drop households that did not complete the food consumption expenditure module.

drop if v8100r!=1 

count if pcdfood_hh==. 

********************************************************************************
* STEP 11: IDENTIFY AND VERIFY POTENTIAL pcdfood_hh OUTLIERS, AND SET CONFIRMED 
*          OUTLIERS TO MISSING
********************************************************************************
*11a. Run the FLAG_OUTLIERS macro to identify potential pcdfood_hh outliers.

drop item
gen item=1
FLAG_OUTLIERS pcdfood_hh   

tab out_pcdfood_hh  
tab pcdfood_hh if out_pcdfood_hh>0  

*11b. Save the outliers with relevant admin. unit identifiers to an Excel file: 
*     "1c_pcdfood_hh_outliers.xlsx" for review.
*     Open the Excel file and examine each outlier one by one for plausibility 
*     before replacing them with the median.
 
preserve
keep if out_pcdfood_hh > 0 
gen Notes = ""
order hhea hhnum pcdfood_hh m_pcdfood_hh sd_pcdfood_hh Notes, first
export excel "$analytic\Log\1c_pcdfood_hh_outliers.xlsx", replace first(variable)
restore

*11c. Set the pcdfood_hh value to be 0 if when reviewing potential outliers
*     in Step 11b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_pcdfood_hh values, as applicable.

* replace out_pcdfood_hh=0 if ... // Modify this IF statement to change 
*                                    extreme values to be non-outliers

*11d. Set the value of pcdfood_hh to be missing for confirmed outliers.

replace pcdfood_hh=. if out_pcdfood_hh > 0

********************************************************************************
* STEP 12: CALCULATE LOCAL MEDIANS of pcdfood_hh AND REPLACE OUTLIERS AND
*          MISSING VALUES WITH LOCAL MEDIANS
********************************************************************************
*12a. Run the CALC_MEDIAN macro to calculate the local median for pcdfood_hh 
*     for each food item.

CALC_MEDIAN pcdfood_hh     

tab out_pcdfood_hh
sum med_pcdfood_hh

*12b. Replace outliers confirmed in Step 11b and missing values with the local median.

replace pcdfood_hh=med_pcdfood_hh if inlist(out_pcdfood_hh,1,2) & med_pcdfood_hh!=.
replace pcdfood_hh=med_pcdfood_hh if pcdfood_hh==. 

hist    pcdfood_hh
sum     pcdfood_hh

********************************************************************************
* STEP 13: SAVE THE DATA FILE
********************************************************************************
rename pcdfood_hh pcd_food_1w
order  hhea hhnum pcd_food_1w
keep   hhea hhnum pcd_food_1w
des
sort   hhea hhnum

la data "Per capita daily food consumption expenditures by HOUSEHOLD in the last 1 week"
save    "$analytic\Results\FTF ZOI Survey [Country] [Year] pov1_food.dta", replace

di "Date:$S_DATE $S_TIME"
log close
