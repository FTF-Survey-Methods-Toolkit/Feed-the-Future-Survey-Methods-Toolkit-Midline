/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
************************ POVERTY INDICATORS- FINAL DO FILE *********************
******************************** [COUNTRY] [YEAR] ******************************
********************************************************************************
Description: This is the final (8 of 8) syntax files to calculate the poverty 
indicators. This syntax is intended to calculate the following:
			   
Feed the Future phase two indicators:
  1. Percent of people living below US$ 1.90 poverty line based on 2011 PPP
  2. Depth of poverty of the poor based on US$ 1.90 poverty line
  3. People living on 100% to 125% of the $1.90 poverty line at 2011 PPP (near poor)

Feed the Future phase one indicators:
  4. Percent of people living below US$ 1.25 poverty line based on 2005 PPP 
     (also necessary for an appendix for the phase 2 baseline report)
  5. Depth of poverty based on US$ 1.25 poverty line
  6. Per capita daily consumption expenditure in USD in 2010 prices using 2005 PPP
  
Feed the Future phase two indicators:
  7. Percent of people living below US$ 2.15 poverty line based on 2017 PPP
  8. Depth of poverty of the poor based on US$ 2.15 poverty line
  9. People living on 100% to 125% of the $2.15 poverty line at 2017 PPP (near poor)
  
Throughout this do file:
- 20xx stands for survey year. Replace 'xx' with the survey year (ex. 18 or 19).
- ccc  stands for survey country. Replace 'ccc' with a 3-letter abbreviation for
       the country (ex. 'eth' for Ethiopia or 'uga' for Uganda).

Syntax prepared by ICF, 2018
Syntax revised by ICF, April 2020, September 2023

This syntax file was developed using the core Feed the Future phase 1 endline/
phase 2 baseline ZOI Survey questionnaire and revised using the core Feed the 
Future Midline Survey parallel survey questionnaire. It must be adapted for the 
final country-specific questionnaire. The syntax was only be partially tested 
using ZOI Survey data; therefore, double-check all results carefully and 
troubleshoot to resolve any issues identified. 
*******************************************************************************
 
NOTE: In this 8th syntax file, the results of the 7 previous poverty syntax 
files are combined to create a single household-level variable, the daily per 
capita (PCD) consumption expenditure, which is then used to derive the poverty 
indicators (see the Guide to Feed the Future Statistics, Chap. 9).  It is 
important to make sure that there are sufficient data to produce the aggregate 
variable, even if v8700r (Outcome of sub-modules 8.2-8.7) is coded as 'completed'
(coded 01). 

As a general rule, if at this point the PCD expenditure of a sub-module is 
missing or equal to 0 for a household, further investigation is advised and it 
may be preferable to drop the household from the poverty indicators analysis.  

There are 2 PCD expenditure variables that should not be missing or equal to 
zero: (1) if 'pcd_food' was missing for a household, it should 
have been replaced by the local median (in pov1.do) since every household must 
have consumed food in the past 7 days; and (2) if 'pcd_house' was missing for a 
household, it should have been estimated using the hedonic regression model 
(in pov7.do), as every household must have a dwelling. 

It may be legitimate for a household to have had no expenses on the other 
sub-modules (although some scrutiny should be applied).  If there are otherwise 
sufficient data for the household, the PCD expenditure for that sub-module 
should be left equal to 0.
*******************************************************************************/

set   more off
clear all
macro drop _all
set maxvar 10000

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//INPUT DATA:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//             $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov1_food_1w.dta  
//             $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov2_nfood_1w.dta
//             $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov3_nfood_1m.dta
//             $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov4_nfood_3m.dta
//             $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov5_nfood_1y.dta 
//             $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov6_asset.dta
//             $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov7_housing.dta            
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] pov8_final.log
//OUTPUT DATA: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov8_final.dta
//SYNTAX:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax pov8_final.do        

cap log close
cap log using  "$analytic\log\FTF ZOI Survey [Country] [Year] pov8_final.log", replace
********************************************************************************
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

******************************************************************************
* 	10.2.11 CALCULATING THE CONSUMPTION AGGREGATE
******************************************************************************

//STEP 1: CALCULATE TOTAL PER CAPITA DAILY (PCD) CONSUMPTION EXPENDITURE IN Local Currency Unit (LCU, 20xx)

**1a: Merge the poverty data files with the household-level analytic data file.

// Use household-level data and keep relevant variables including survey specific 
** cluster, district, and project level variables

use   "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta",clear
keep   hhea hhnum c05 c06 a05 a06 wgt_hh wgt_hhmem hhsize_dj genhhtype_dj

mmerge hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov1_food_1w.dta",   ukeep(pcd_food_1w) 
mmerge hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov2_nfood_1w.dta",  ukeep(pcd_nfood_1w) 
mmerge hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov3_nfood_1m.dta",  ukeep(pcd_nfood_1m) 
mmerge hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov4_nfood_3m.dta",  ukeep(pcd_nfood_3m) 
mmerge hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov5_nfood_1y.dta",  ukeep(pcd_nfood_1y)
mmerge hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov6_asset.dta",     ukeep(pcd_asset) 
mmerge hhea hhnum using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov7_housing.dta",   ukeep(pcd_house) 

drop if v8700r != 1

**1b: CALCULATE TOTAL PCD NON-FOOD CONSUMPTION IN local currency unit (LCU)
sum     pcd_nfood* 
egen    pcd_nfood=rsum(pcd_nfood_1w pcd_nfood_1m pcd_nfood_3m pcd_nfood_1y)
hist    pcd_nfood
sum     pcd_nfood	
lab var pcd_nfood "Per capita daily non-food consumption in local currency, 20xx"

**1c: CALCULATE TOTAL PCD CONSUMPTION IN LCU 
* Set the variable to missing if it is determined that there are insufficient 
* data overall for Module 8, as explained in the comment and general rule above,
* and drop the household from further analysis)

sum     pcd_food_1w pcd_nfood pcd_asset pcd_house
egen    Xpc_20xx_LCU=rowtotal(pcd_food_1w pcd_nfood pcd_asset pcd_house)

sum     Xpc_20xx_LCU
hist    Xpc_20xx_LCU 
la var  Xpc_20xx_LCU "Per capita daily consumption exp in local currency, 20xx"

//STEP 2: IDENTIFY AND VERIFY OUTLIERS OF Xpc_20xx_LCU AND SET CONFIRMED OUTLIERS TO MISSING

FLAG_OUTLIERS Xpc_20xx_LCU

tab out_Xpc_20xx_LCU  
sum Xpc_20xx_LCU if out_Xpc_20xx_LCU==0   
sum Xpc_20xx_LCU if out_Xpc_20xx_LCU>0

*Examine outliers one by one for plausibility before replacing them with the median.
*replace out_Xpc_20xx_LCU=0 if …   //Modify this IF statement to change identified 
*                                    extreme values to be non-outliers

replace Xpc_20xx_LCU=. if out_Xpc_20xx_LCU>=1 

//STEP 3: CALCULATE MEDIAN OF Xpc_20xx_LCU AND REPLACE OUTLIERS WITH MEDIAN 

CALC_MEDIAN Xpc_20xx_LCU

sum med_Xpc_20xx_LCU
count
histogram Xpc_20xx_LCU  //CHECK the distribution

replace  Xpc_20xx_LCU=med_Xpc_20xx_LCU if inlist(out_Xpc_20xx_LCU,1,2) & med_Xpc_20xx_LCU != . 

hist     Xpc_20xx_LCU  //check the distribution
tabstat  Xpc_20xx_LCU, stat(mean med)

********************************************************************************
********************************************************************************
*  CALCULATING INDICATORS AT THE $1.90 THRESHOLD
********************************************************************************
********************************************************************************

********************************************************************************
*  10.2.12 PREVALENCE OF POVERTY ($1.90 per day 2011 PPP) indicator
********************************************************************************
**The step-by-step procedures to calculate the prevalence of poverty, or the percentage of people living on less than $1.90 per day 2011 PPP. 

//STEP 1. GENERATE THE REQUIRED CPIs and PPPs for the $1.90 threshold (2011 PPP)

gen cpi20xx_ccc = xx.xx  //Survey country CPI of the year and month of the survey 
gen cpi2011_ccc = xx.xx  //Survey country CPI for year 2011 
gen ppp2011_ccc = xx.xx  //Survey country 2011 PPP conversion factor, private consumption

**NOTE: The 2011 PPP for private consumption is obtained from the World Bank 
**Databank.  It is also provided for target countries in the Guide to Feed 
**the Future Statistics in Table 6.
 
//STEP 2. Convert the USD $1.90 per day (2011 PPP) poverty line into local currency:

**    Multiply the $1.90 per day 2011 PPP poverty line by the 2011 PPP conversion 
**	  rate of the survey country. 

*     Adjust the resulting figure for cumulative price inflation since 2011 by 
**	  multiplying it by the ratio of the CPI of the year and month of the 
**	  survey to the 2011 CPI.

gen povline190_LCU = (1.90 * ppp2011_ccc) * (cpi20xx_ccc/cpi2011_ccc)
label var povline190_LCU "$1.90 poverty line in local currency at time of survey" 

//STEP 3. Create a variable that flags households that have a consumption aggregate 
** 	  below the $1.90 poverty line 2011 PPP converted to local currency.

gen     poor190=0
replace poor190=1 if (Xpc_20xx_LCU < povline190_LCU)

**NOTE there should not be any Xpc_20xx_LCU == . 

lab def POOR190 1 "HH members living below $1.90 Poverty Line (2011 PPP)" ///
                0 "HH members living on or above $1.90 Poverty Line (2011 PPP)"	
lab val poor190 POOR190															
lab var poor190 "HH members living below the $1.90 poverty line (2011 PPP)"
tab     poor190,m

//STEP 4. Create a de jure household member weight to calculate prevalence of poverty estimates. 

**4a. Create the de jure household member weight (wgt_hhmem) variable using the household weight variable (wgt_hh) and the number of de jure household members variable (hhsize_dj)

** NOTE: The syntax below is a sample of what can be done and is by no means 
** complete. Each country data analysis team may add syntax based on the needs 
** and requirements for the report. 

gen  wgt_hhmem=wgt_hh*hhsize_dj
svyset 	hhea [pw=wgt_hhmem], strata(strata)

**4b. Calculate the prevalence of poverty in the ZOI population using the poor190 variable. Repeat with desired dissagregates.

svy: tab poor190
svy: tab poor190 genhhtype_dj, col percent format(%6.1f)
svy: tab poor190 awiquint, col percent format(%6.1f)
svy: tab poor190 shock_sev, col percent format(%6.1f)

********************************************************************************
* 10.2.13 DEPTH OF POVERTY OF THE POOR ($1.90 PER DAY 2011 PPP) INDICATOR
********************************************************************************
//STEP 1. See Step 2 in Section 10.2.12 to ensure that the povline190_LCU variable is created.

//STEP 2. Create a variable measuring an individuals proportional shortfall from the poverty line.  
**2a. Subtract the per capita daily consumption expenditure in from the 
**     USD $1.90 poverty line converted to local currency. 
**2b. Divide by the USD $1.90 per day (2011 PPP) poverty threshold in local currency
**    to obtain the household's proportional shortfall from the poverty line. 
**2c. Multiply the result by 100 to obtain the depth of poverty expressed as 
**    a percentage of the poverty line.

gen     povdepth190 = ((povline190_LCU - Xpc_20xx_LCU) / povline190_LCU) * 100 

//STEP 3. Exclude households that have a per capita daily consumption equal to or greater than the $1.90 per day 2011 PPP poverty threshold converted to local currency. 

replace povdepth190 =. if (Xpc_20xx_LCU >= povline190_LCU) 

sum     povdepth190
la var  povdepth190 "Depth of poverty of the poor, $1.90 poverty line"

//STEP 4. Calculate the depth of poverty of the poor in the ZOI population as the mean of the povdepth190 variable. Repeat with desidred disaggregates.

svy: mean povdepth190
svy: mean povdepth190, over(genhhtype_dj)
svy: mean povdepth190, over(awiquint)
svy: mean povdepth190, over(shock_sev)

********************************************************************************
* 10.2.14 PERCENT OF PEOPLE WHO ARE "NEAR-POOR" ($1.90 PER DAY 2011 PPP INDICATOR)
********************************************************************************

//STEP 1. Create a variable that flags households that have a consumption aggregate that is equal to or greater than the $1.90 2011 PPP poverty line converted to local currency, but less than 125 percent of the $1.90 2011 PPP poverty line converted to local currency (povline190_LCU, which was created in Section 10.2.12, Step 2).

gen     nearpoor190=0
replace nearpoor190=1 if (Xpc_20xx_LCU >= povline190_LCU) & ///
       (Xpc_20xx_LCU < (povline190_LCU*1.25))

lab def NPOOR190 1 "HH members living on 100% to less than 125% of the $1.90 poverty line"  0 "HH members living below $1.90 poverty line or at or above 125% of $1.90 poverty line"	
lab val nearpoor190 NPOOR190															
lab var nearpoor190 "HH members living on 100% to less than 125% of the $1.90 poverty line (2011 PPP)"

//STEP 2. Calculate the percentage of the ZOI population who are near poor using the nearpoor190 variable and the de jure household member weight. Repeat with desired dissagregates.

svy: tab nearpoor190
svy: tab nearpoor190 genhhtype_dj, col percent format(%6.1f)
svy: tab nearpoor190 awiquint, col percent format(%6.1f)
svy: tab nearpoor190 shock_sev, col percent format(%6.1f)


********************************************************************************
********************************************************************************
*  CALCULATING INDICATORS AT THE $1.25 THRESHOLD
********************************************************************************
********************************************************************************

********************************************************************************
* 10.2.15 PREVALENCE OF POVERTY ($1.25 PER DAY 2005 PPP) INDICATOR
********************************************************************************
**The step-by-step procedures to calculate the prevalence of poverty, or the percentage of people living on less than $1.25 per day 2005 PPP. The step-by-step procedures to calculate the prevalence of poverty, or the percentage of people living on less than $1.25 per day 2005 PPP.

//STEP 1. GENERATE THE REQUIRED CPIs and PPPs for the $1.25 threshold

gen cpi20xx_ccc = xx.xx  //Survey country CPI of the year and month of the survey 
gen cpi2005_ccc = xx.xx  //Survey country CPI for year 2005 
gen ppp2005_ccc = xx.xx  //Survey country 2005 PPP conversion factor, private consumption

** NOTE: This indicator is from Feed the Future phase one.  However, it is 
** required for an appendix table in the phase two Midline Report. The 2005 PPP 
** should be used to convert the poverty line into LCU.  The 2005 PPP for your 
** country is available in Table 10 of the Guide to Feed the Future Statistics.

//STEP 2. Convert the $1.25 2005 PPP poverty line into 2005 LCU by multiplying the $1.25 2005 PPP poverty line by the 2005 PPP conversion rate of the survey country. 

*Adjust the resulting figure for cumulative price inflation since 2005 by multiplying it by the ratio of the CPI of the year and month of the survey to the 2005 CPI

gen povline125_LCU = (1.25 * ppp2005_ccc) * (cpi20xx_ccc/cpi2005_ccc)
lab var "$1.25 poverty line in local currency at the time of the survey"

//STEP 3. Create a variable that flags households that have a consumption aggregate below the USD $1.25 poverty line at 2005 PPP expressed in local currency.

gen     poor125=0
replace poor125=1 if (Xpc_20xx_LCU < povline125_LCU) 

lab def poor125 0 "HH members living on or above the $1.25 poverty line (2005 PPP)" ///
                1 "HH members living below the $1.25 poverty line (2005 PPP"	
lab val poor125 POOR125															
lab var poor125 "HH members living below $1.25 poverty line (2005 PPP)"
tab     poor125,m

//STEP 4. Calculate the prevalence of poverty in the ZOI population using the poor125 variable. Repeat with desired dissagregates.

svy: tab poor125
svy: tab poor125 genhhtype_dj, col percent (format %6.1f)
svy: tab poor125 awiquint, col percent (format %6.1f)
svy: tab poor125 shock_sev, col percent (format %6.1f)

********************************************************************************
* 10.2.16 DEPTH OF POVERTY OF THE POOR ($1.25 PER DAY 2005 PPP) INDICATOR
********************************************************************************
** NOTE: You need to refer to Table 10 in the Guide to Feed the Future Statistics
** to obtain the 2005 PPP for private consumption for your country
** (the series is no longer available on the World Bank Databank website). 

//STEP 1. See Step 2 in Section 10.2.15 to ensure that the povline125_LCU variable is created.

//STEP 2. CALCULATE DEPTH OF POVERTY BASED ON THE $1.25 2005 PPP POVERTY LINE. 

** NOTE: This indicator is different from the baseline indicator DEPTH OF 
**		POVERTY OF THE POOOR AT THE $1.90 2011 PPP calculated above.
** 		For this indicator, all hhs are included in the calculation 
**		with non-poor hhs assigned a depth of poverty of 0. 

**2. Subtract the per capita expenditure in LCU from the $1.25 poverty line 
**		converted to LCU. 
**   Divide by the $1.25 poverty line converted to LCU to obtain the household
**		proportional shortfall from the poverty line.  
**   Multiply the result by 100 to obtain the depth of poverty expressed 
**     as a percentage of the poverty line.

gen     povdepth125=((povline125_LCU - Xpc_20xx_LCU) / povline125_LCU) * 100

//STEP 3. Exclude households if their per capita daily consumption expenditure exceeds the $1.25 per day threshold.
replace povdepth125=. if Xpc_20xx_LCU >= povline125_LCU

sum     povdepth125
la var  povdepth125 "Depth of poverty of the poor, $1.25 poverty line (2005 PPP)"

//STEP 4. Calculate the depth of poverty of the poor in the ZOI population as the mean of the povdepth125 variable. Repeat with desidred disaggregates.

svy: mean povdepth125
svy: mean povdepth125, over(genhhtype_dj)
svy: mean povdepth125, over(awiquint)
svy: mean povdepth125, over(shock_sev)

********************************************************************************
* 10.2.17 PERCENT OF PEOPLE WHO ARE "NEAR-POOR" ($1.25 PER DAY 2005 PPP) INDICATOR
********************************************************************************

//STEP 1. Create a variable that flags households that have a consumption aggregate 
**    that is equal to or greater than the $1.25 2005 PPP poverty line  
**    converted to local currency, but less than 125 percent of the $1.25 2005
**	  PPP poverty line converted to local currency (povline125_LCU, which was created in Section 10.2.15, Step 2).

gen     nearpoor125=0
replace nearpoor125=1 if (Xpc_20xx_LCU >= povline125_LCU) & ///
       (Xpc_20xx_LCU < (povline125_LCU*1.25))

lab def NPOOR125 1 "HH members living on 100% and up to less than 125% of $1.25 poverty line"  0 "HH living below $1.25 poverty line or at or above 125% of $1.25 poverty line"	
lab val nearpoor125 NPOOR125															
lab var nearpoor125 "HH members living on 100% to less than 125% of the $1.25 poverty line (2005 PPP)"

//STEP 2. Calculate the percentage of the ZOI population who are near poor using the nearpoor190 variable and the de jure household member weight. Repeat with desired dissagregates.

svy: tab nearpoor125
svy: tab nearpoor125 genhhtype_dj, col percent (format %6.1f)
svy: tab nearpoor125 awiquint, col percent (format %6.1f)
svy: tab nearpoor125 shock_sev, col percent (format %6.1f)


********************************************************************************
********************************************************************************
*  CALCULATING INDICATORS AT THE $2.15 THRESHOLD
********************************************************************************
********************************************************************************

********************************************************************************
* 10.2.18 PREVALENCE OF POVERTY ($2.15 PER DAY 2017 PPP) INDICATOR
********************************************************************************

**The step-by-step procedures to calculate the prevalence of poverty, or the percentage of people living on less than $2.15 per day 2015 PPP. The step-by-step procedures to calculate the prevalence of poverty, or the percentage of people living on less than $2.15 per day 2017 PPP


//STEP 1. GENERATE THE REQUIRED CPIs and PPPs for the $2.15 threshold

gen cpi20xx_ccc = xx.xx  //Survey country CPI of the year and month of the survey 
gen cpi2017_ccc = xx.xx  //Survey country CPI for year 2017 
gen ppp2017_ccc = xx.xx  //Survey country 2017 PPP conversion factor, private consumption

**NOTE: The 2017 PPP for private consumption is obtained from the World Bank 
**Databank.  It is also provided for target countries in the Guide to Feed 
**the Future Statistics in Table 10.

// STEP 2. Convert the $2.15 2017 PPP poverty line into 2017 LCU by multiplying the $2.15 2017 PPP poverty line by the 2017 PPP conversion rate of the survey country). Adjust the resulting figure for cumulative price inflation since 2017 by  multiplying it by the ratio of the CPI of the year and month of the survey to the 2017 CPI.

gen povline215_LCU = (2.15* ppp2017_ccc) * (cpi20xx_ccc/cpi2017_ccc)
lab var "$2.15 poverty line in local currency at the time of the survey"

//STEP 3. Create a variable that flags households that have a consumption aggregate below the USD $2.15 poverty line at 2017 PPP expressed in local currency.

gen     poor215=0
replace poor215=1 if (Xpc_20xx_LCU < povline215_LCU) 

lab def poor215 0 "HH members living on or above the $2.15 poverty line (2017 PPP)" ///
                1 "HH members living below the $2.15 poverty line (2017 PPP)"	
lab val poor215 POOR125															
lab var poor215 "HH members living below $2.15 poverty line (2017 PPP)"
tab     poor215,m

//STEP 4. Calculate the prevalence of poverty in the ZOI population using the poor215 variable. Repeat with desired dissagregates.

svy: tab poor215
svy: tab poor215 genhhtype_dj, col percent (format %6.1f)
svy: tab poor215 awiquint, col percent (format %6.1f)
svy: tab poor215 shock_sev, col percent (format %6.1f)

********************************************************************************
*  10.2.19 DEPTH OF POVERTY OF THE POOR ($2.15 PER DAY 2017 PPP) INDICATOR
********************************************************************************
** NOTE: You need to refer to Table 10 in the Guide to Feed the Future Statistics
** to obtain the 2017 PPP for private consumption for your country

//STEP 1. See Step 2 in Section 10.2.18 to ensure that the povline215_LCU variable is created

//STEP 2. CALCULATE DEPTH OF POVERTY BASED ON THE $2.15 2017 PPP POVERTY LINE. 

**2. Subtract the per capita expenditure in LCU from the $2.15 poverty line 
**		converted to LCU. 
**   Divide by the $2.15 poverty line converted to LCU to obtain the household
**		proportional shortfall from the poverty line.  
**   Multiply the result by 100 to obtain the depth of poverty expressed 
**     as a percentage of the poverty line.

gen     povdepth215=((povline215_LCU - Xpc_20xx_LCU) / povline215_LCU) * 100

//STEP 3. Exclude households if their per capita daily consumption expenditure exceeds the $2.15 per day threshold.
replace povdepth215=. if Xpc_20xx_LCU >= povline215_LCU

sum     povdepth215
la var  povdepth215 "Depth of poverty of the poor, $2.15 poverty line (2017 PPP)"

//STEP 4. Calculate the depth of poverty of the poor in the ZOI population as the mean of the povdepth215 variable. Repeat with desidred disaggregates.

svy: mean povdepth215
svy: mean povdepth215, over(genhhtype_dj)
svy: mean povdepth215, over(awiquint)
svy: mean povdepth215, over(shock_sev)

********************************************************************************
* 10.2.20 PERCENT OF PEOPLE WHO ARE "NEAR-POOR" ($2.15 PER DAY 2017 PPP) INDICATOR
********************************************************************************

//STEP 1. Create a variable that flags households that have a consumption aggregate that is equal to or greater than the $2.15 2017 PPP poverty line converted to local currency, but less than 125 percent of the $2.15 2017 PPP poverty line converted to local currency (povline215_LCU, which was created in Section 10.2.18, Step 2).

gen     nearpoor215=0
replace nearpoor215=1 if (Xpc_20xx_LCU >= povline215_LCU) & ///
       (Xpc_20xx_LCU < (povline215_LCU*1.25))

lab def NPOOR215 1 "HH members living on 100% and up to less than 125% of $2.15 poverty line"  0 "HH living below $2.15 poverty line or at or above 125% of $2.15 poverty line"	
lab val nearpoor215 NPOOR215															
lab var nearpoor215 "HH members living on 100% to less than 125% of the $2.15 poverty line (2017 PPP)"

//STEP 2. Calculate the percentage of the ZOI population who are near poor using the nearpoor215 variable and the de jure household member weight. Repeat with desired dissagregates.

svy: tab nearpoor215
svy: tab nearpoor215 genhhtype_dj, col percent (format %6.1f)
svy: tab nearpoor215 awiquint, col percent (format %6.1f)
svy: tab nearpoor215 shock_sev, col percent (format %6.1f)

********************************************************************************
//STEP I. SAVE THE DATA FILE
********************************************************************************
keep  region dist hhea hhnum c05 c06 hh_wgt hhsize_dj genhhtype_dj ///
      pcd_* Xpc_20xx_LCU Xpc_2010_USD* poor* nearpoor* povdepth* povline190_LCU  ///
	  povline125_LCU share_* 
	 
order region dist hhea hhnum c05 c06 hh_wgt hhsize_dj genhhtype_dj ///
      pcd_* Xpc_20xx_LCU Xpc_2010_USD* poor* nearpoor* povdepth* povline190_LCU  ///
	  povline125_LCU share_* 

sort  hhea hhnum
numlabel, add force

label data "Poverty Indicators"
save  "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] pov8_final.dta", replace 

disp "DateTime: $S_DATE $S_TIME"

log  close
**-----------------------------------------------------------------------------

cap log close
cap log using  "$analytic\log\FTF ZOI Survey [Country] [Year] pov8_indicators.log", replace

log close