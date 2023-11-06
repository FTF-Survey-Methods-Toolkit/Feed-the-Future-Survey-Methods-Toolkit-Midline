/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
**************************** HOUSING EXPENDITURE  ******************************
****************************** [COUNTRY] [YEAR] ********************************
********************************************************************************
Description: This code is intended to calculate per capita daily rental 
equivalent of housing consumption expenditure. This is the 7th of 8 preparatory 
syntax files to calculate the poverty indicators.

Syntax prepared by ICF, 2018
Syntax revised by ICF, August 2020, October 2022, April 2023, September 2023

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
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] pov7_house.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov7_house.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax pov7_house.do 
 
cap log close
cap log using  "$analytic\log\FTF ZOI Survey [Country] [Year] pov7_house.log", replace

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
keep hhea hhnum c05 c06 hhsize_dj v860* v8700r v8100r

********************************************************************************
// STEP 0: DROP HOUSEHOLDS THAT DID NOT COMPLETE SUB-MODULES 8.2-8.7
********************************************************************************
drop if v8700r != 1

numlabel, add force
tab v8601,m

********************************************************************************
//STEP 1: PREPARE THE DATA 
******************************************************************************** 
for var v8602 v8604a v8605a: recode X  999999996/999999998=., gen(Xx)
for var v8608 v8609:         recode X  999999996/999999998=., gen(Xx)
recode v8603 996/max=.,gen(v8603x)
for var v8602x v8603x v8604ax v8605ax v8608x v8609x: tab1 X,m

tab v8601,m

********************************************************************************
//STEP 2: CALCULATE PER CAPITA DAILY RENT FOR HHOLDS LIVING IN RENTED HOME 
**			(V8601=5)
******************************************************************************** 
bys v8605b: tab v8605ax 

gen     pcdhouse1=.
replace pcdhouse1=v8605ax/hhsize_dj      if v8605b==1 & v8601==5  //per day rent
replace pcdhouse1=v8605ax/hhsize_dj/7    if v8605b==2 & v8601==5  //per week
replace pcdhouse1=v8605ax/hhsize_dj/30.4 if v8605b==3 & v8601==5  //per month
replace pcdhouse1=v8605ax/hhsize_dj/365  if v8605b==4 & v8601==5  //per year
la var pcdhouse1 "Per capita daily rent, rented home"
sum     pcdhouse1  //@patricia in gts also includes & v8605ax != ., which one is correct?

********************************************************************************
//STEP 3: CALCULATE PER CAPITA DAILY RENTAL EQUIVALENT FOR HOUSEHOLDs LIVING IN 
**         EMPLOYER PROVIDED OR FREE HOME (v8601=3,4) 
********************************************************************************
bys     v8604b: tab v8604ax

gen     pcdhouse2=.
replace pcdhouse2=v8604ax/hhsize_dj      if v8604b==1 & inlist(v8601,3,4) //per day rent
replace pcdhouse2=v8604ax/hhsize_dj/7    if v8604b==2 & inlist(v8601,3,4) //per week rent
replace pcdhouse2=v8604ax/hhsize_dj/30.4 if v8604b==3 & inlist(v8601,3,4) //per month rent
replace pcdhouse2=v8604ax/hhsize_dj/365  if v8604b==4 & inlist(v8601,3,4) //per year rent
la var pcdhouse2 "Per capita daily rental equivalent, provided/free home"
sum     pcdhouse2  

*****************************************************************************
** STEP 4: ADD pcdhouse1 (rented home) AND pcdhouse2 (PROVIDED/FREE HOUSE)
**         TO CREATE A NEW VARIABLE pcdhouse3
*****************************************************************************
** This step is to prepare the data for the hedonic regression and impute 
** rental value for owner-occupied housing and missing rental values.

sum  pcdhouse1 pcdhouse2

egen pcdhouse3=      rsum(pcdhouse1 pcdhouse2) 
egen pcdhouse3_miss= rmiss(pcdhouse1 pcdhouse2)
tab  pcdhouse3_miss  
replace pcdhouse3 =. if pcdhouse3_miss==2

la var pcdhouse3 "PCD housing consumption expenditure for rented & provided/free homes"

sum  pcdhouse1 pcdhouse2 pcdhouse3

********************************************************************************
// 5: IDENTIFY POTENTIAL OUTLIERS OF pcdhouse3 AND SET VERIFIED OUTLIERS TO MISSING 
********************************************************************************
*5a. Run the FLAG_OUTLIERS macro to identify potential pcdhouse3 outliers.

FLAG_OUTLIERS pcdhouse3

tab out_pcdhouse3  
tab pcdhouse3 if out_pcdhouse3 >0  

*5b. Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "7a_pcdhouse3_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_pcdhouse3 > 0 & pcdhouse3 !=.
gen Notes = ""
order hhea hhnum pcdhouse1 pcdhouse2 pcdhouse3 m_pcdhouse3 sd_pcdhouse3 Notes out_pcdhouse3, first
export excel "$analytic\Log\7a_pcdhouse_outliers.xlsx", replace first(variable)
restore

*5c. Set the out_pcdhouse3 value to be 0 if when reviewing potential outliers
*    in Step 5b the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_pcdhouse3 values, as applicable.

* replace out_pcdhouse3=0 if ... // Modify this IF statement to change 
*                                   extreme values to be non-outliers

*5d. Set the value of pcdhouse3 to be missing for confirmed outliers.

replace pcdhouse3=. if out_pcdhouse3 > 0

********************************************************************************
// 6: CALCULATE LOCAL MEDIAN OF PCDHOUSE3 AND REPLACE CONFIRMED OUTLIERS WITH 
*     THE MEDIAN
********************************************************************************
CALC_MEDIAN pcdhouse3 

tab out_pcdhouse3
sum med_pcdhouse3

replace pcdhouse3 = med_pcdhouse3 if inlist(out_pcdhouse3,1,2) & med_pcdhouse3!=.
count if pcdhouse3 ==. 

sum     pcdhouse3
hist    pcdhouse3

** Assign missing if zero rent value in pcdhouse3 to avoid indeterminate value 
** for the hedonic regression (in log linear form)
replace pcdhouse3 = . if pcdhouse3 == 0

** Keep pcdhouse3 for Hedonic Regression
keep  hhea hhnum pcdhouse1 pcdhouse2 pcdhouse3 

********************************************************************************
//STEP 7: MERGE HOUSEHOLD DATA WITH DATA FROM STEP 4 FOR THE HEDONIC REGRESSION
** 		  MODEL.
********************************************************************************
** The model is used to impute rental value of owner-occupied housing 
** and missing rental values.  

**The model presented below is one of the possible specifications for the
**hedonic regression and the data analysis team may want to vary the specification 
**to better fit the data.  For instance, although the log-linear form is often 
**preferred, another functional form, such as a double-log, may be found to 
**perform better.  A common list of explanatory variables is used in this syntax,
**but other variables, including external ones, could be used to improve the 
**predictability of the model.


mmerge hhea hhnum using "$analytic\FTF ZOI Survey [Country] [Year] household data analytic.dta"

drop if v8700r !=1

** 7a. Generate a dependent variable for the log linear regression (log_house)
** 

sum  pcdhouse3   
gen  log_house=log(pcdhouse3)  
sum  log_house

**7b. Generate independent variables to include in the regression.
**    These variables are in the household data file.

gen dw_finishedroof= dw_roof==3
gen dw_finishedfloor=dw_floor==3
gen dw_finishedwall= dw_wall==3
gen access_electric=v222a==1

** 	roomsleep and h2o_improved already created in the HHold analytic file 
*	roomsleep         "Number of sleeping room"
*	h2_improved       "HH using an improved water source (1=yes, 0=no)"

**7c. Using global command, store the independent variables in memory ($ivar)  
**  to be used anytime during a Stata session by reference to its name  
**  and save the data to a temporary data file, temp_house.dta  

global ivar dw_finishedroof dw_finishedfloor dw_finishedwall access_electric ///
            roomsleep h2o_improved 
			
sum  $ivar

* Check for relevant district and region variable names

keep hhea hhnum c05 c06 hhsize_dj log_house pcdhouse* v860* $ivar

save "$analytic\temp\temp_house",replace

**7d. Run stepwise regression to find the best fit, with the objective of 
**  maximizing the R^2. Multi-collinearity is likely to be present, but 
**  since the purpose is to impute rent for hhs that own their house or where 
**  the rent is missing (predicting the dependent variable), the contribution 
**  or significance of individual variables should not be too much of a concern. 

use "$analytic\temp\temp_house",clear

reg log_house $ivar 

/* Generate Studentized Residuals (rstudent) to examine and identify outliers
 in the regression model
*/

predict rstudent, rstudent 

gen outlier=1 if (rstudent >=3 & rstudent <.) | rstudent <=3
sum rstudent  if outlier==1
tab outlier

** Rerun the log linear model again after removing outliers

reg log_house $ivar if outlier==. 
predict log_model

** 7e. Generate a variable for the predicted PCD housing value by taking the 
*    inverse of the log.

gen model= exp(log_model) 
sum model 

********************************************************************************
//STEP 8: GENERATE A SINGLE PCD USE VALUE OF HOUSING (pcdhouse), USING THE
**        REGRESSION MODEL FOR PREDICTING A RENT EQUIVALENT FOR OWNER-OCCUPIED
**        HOUSING AND MISSING OBSERVATIONS
********************************************************************************

** Because all households need to have a dwelling of some sort, 
** missing values - whether because there are insufficient information in
** the sub-module or the respondent did not answer or did not know - should
** be replaced by the hedonic model predicted value. 

gen     pcdhouse=pcdhouse3
replace pcdhouse=model  if pcdhouse==. & inlist(v8601,., 1,2, 8) /// 
        | (pcdhouse1 == . & v8601 == 5) | (pcdhouse2 == . & inlist(v8601, 3, 4))

la var  pcdhouse "Per capita daily use value of housing, plus predicted"

sum     pcdhouse
hist    pcdhouse

********************************************************************************
//STEP 9: CALCULATE PER CAPITA EXPENDITURE ON REPAIRS AND MAINTENANCE
*         TO THE HOUSE 
********************************************************************************
**Reported expenditures on repairs and maintenance should be examined
**carefully to ensure they are realistic considering the PCD value of the
**dwelling and other household expenditures and do not unduly inflate 
**PCD on housing. 

*9a. Create a variable to capture expenditures on dwelling repairs and maintenance.

gen     repair= v8609 if v8609 < 999999996
sum     repair

*9b. Create a variable for PCD expenditures on repairs.

gen   pcdhouse4=(repair/hhsize_dj/30.4)

label var pcdhouse4 "PCD expenditure house repairs and maintenace"

********************************************************************************
//STEP 10: Identify and verify potention pcdhouse4 outliers
********************************************************************************

*Run the FLAG_OUTLIERS macro to identify potential pcdhouse4 outliers.

FLAG_OUTLIERS pcdhouse4

*    Save the flagged outliers with relevant admin. unit identifiers to an Excel 
*    file: "7b_pcdhouse4_outliers.xlsx"
*    Open the Excel file and examine each outlier one by one for plausibility.

preserve
keep if out_pcdhouse4 > 0 & out_pcdhouse4!= .
gen Notes = ""
order hhea hhnum repair pcdhouse4 hhsize_dj m_pcdhouse4 sd_pcdhouse4 Notes out_pcdhouse4, first
export excel "$analytic\Log\7b_pcdhouse_outliers.xlsx", replace first(variable)
restore

*    Set the out_pcdhouse4 value to be 0 if when reviewing potential outliers
*    in Step 9d the value was determined not to be an outlier.
*INSTRUCTIONS: Add syntax to update out_pcdhouse4 values, as applicable.

* replace out_pcdhouse4=0 if ... // Modify this IF statement to change 
*                                   extreme values to be non-outliers

*    Set the value of pcdhouse4 to be missing for confirmed outliers.

replace pcdhouse4=. if out_pcdhouse4 > 0 

********************************************************************************
//STEP 11: Calculate pcdhouse4 median and replace confirmed outliers with this median.
********************************************************************************

CALC_MEDIAN pcdhouse4

replace pcdhouse4=med_pcdhouse4 if out_pcdhouse4>0 & med_pcdhouse4!=. 

********************************************************************************
//STEP 12: CALCULATE PER CAPITA EXPENDITURE ON HOUSING.
**    Add together PCD use-value of housing 'pcdhouse' from Step 6 and 
**    PCD expenditure on repairs/maintenance 'pcdhouse4'
********************************************************************************

egen pcd_house = rsum(pcdhouse pcdhouse4)

**There should not be any missing observations at this point.  If there
**are, a rental equivalent needs to be estimated using the hedonic regression, 
**as described above.


egen    pcd_house_miss= rmiss(pcdhouse pcdhouse4)
tab     pcd_house_miss  
replace pcd_house =. if pcd_house_miss==2

la var  pcd_house "Per capita daily consumption expenditure on housing"

sum  pcd_house
hist pcd_house

********************************************************************************
//STEP 13: SAVE THE DATA FILE
********************************************************************************
keep  hhea hhnum pcd_house 
order hhea hhnum pcd_house 
des
sort  hhea hhnum

la data "Per capita daily rental equivalent of housing consumed by HH"
save "$analytic\results\FTF ZOI Survey [Country] [Year] pov7_house.dta",replace

disp "DateTime: $S_DATE $S_TIME"
log close

