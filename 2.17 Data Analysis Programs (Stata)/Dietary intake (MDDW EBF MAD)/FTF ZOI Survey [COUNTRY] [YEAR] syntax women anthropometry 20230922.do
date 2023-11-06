/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
********************* WOMEN'S ANTHROPOMETRY INDICATORS *************************
**************************** [COUNTRY] [YEAR] **********************************
********************************************************************************
Purpose: 			Code to compute anthropometry indicators for women
Data inputs: 		DHS IR dataset
Data outputs:		Women's anthropometry indicators

Syntax prepared by ICF, September 2023

Note: This syntax file is for use with the Demographic and Health Survey IR 
datasets. For ever-married sample surveys please use the PR dataset instead of 
the IR dataset. 

The following variables will be relevant in the PR dataset:
hv020: Ever-married sample
hv103: Slept last night
ha3: Woman's height in centimeters
ha40: Body Mass Index
hv005: Household sample weight

See details in the DHS Guide to Statistics: 
https://www.dhsprogram.com/data/Guide-to-DHS-Statistics/index.htm#t=Nutritional_Status.htm%23Percentage_of_women_bybc-2&rhtocid=_14_9_1
			
*******************************************************************************/

set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"
global anthro "FTF ZOI Survey [COUNTRY] [YEAR] NAME\Anthropometry"

//Input data:   $anthro\[CC]IR[VV]FL_FTF_ZOI.DTA
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] women antrhopometry.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] women anthropometry.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax women antrhopometry.do 

cap log close 
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] women anthropometry.log",replace

/*-------------------------------------------------------------------------------------------------
Variables used:
v000 - "country code and phase"
v001 - "cluster number"
v005 - "womens individual sample weight (6 decimals)"
v008 - "date of interview (cmc)"
v012 - "respondents current age (in years)"
v013 - "respondents age in 5 years group"
v190 - "wealth index"
v022 - "sample strata for sampling errors"
v023 - "stratification used in sample design"
v024 - "region"
v213 - "currently pregnant"
v437 - "weight of the respondent in kilograms"
v445 - "body mass index"
b3_01 - "date of birth (cmc)"
b19_01 - "current age of child in months"

Variables created in this file:
cage_youngest - "Age of youngest child"
agegrp_wra_7grp - "Woman's age category in years"
agegrp_wra_2grp - “Women 15-49 age category (15-19, 20-49 years)" 

Additional indicators:
whn_bmi	- "Mean BMI  - women"
whn_hw	- "Normal BMI - women"
whn_uw - "Underweight BMI - women"
whn_ow - "Overweight BMI  - women"
whn_obese - "Obese BMI  - women"
----------------------------------------------------------------------------------------------------*/

*****************************************************************
** 17.2.5. Prevalence of underweight women of reproductive age **
*****************************************************************
// This indicator estimates the percentage of non-pregnant women of reproductive age (15-49 years) who are underweight, according to their BMI, in the ZOI population. Women's BMI is calculated by dividing women's weight in kilograms by the square of their height in meters. The indicator is calculated using DHS survey data. 

* Step 1. Load the women's data file that was created in Section 17.2.1.
use "$anthro\[CC]IR[VV]FL_FTF_ZOI.DTA", clear

* Step 2. Create a variable that indicates the age of each woman's youngest child (cage_youngest). The variable will be used in the next step to exclude women who gave birth to a child during the 2 months preceding the survey. To create cage_youngest, use b19_01 (current age in months of the woman's youngest child) if it exists in the data file. If it does not exist, subtract the date of birth of the woman's youngest child (b3_01) from the date of the interview (v008). The variable cage_youngest will have a value of missing if a woman does not have any children.

gen  cage_youngest = v008 - b3_01
	
* to check if survey has b19, which should be used instead to compute age. 
scalar b19_included=1
capture confirm numeric variable b19_01, exact 
if _rc>0 {
	* b19 is not present
	scalar b19_included=0
	}
	if _rc==0 {
	* b19 is present; check for values
	summarize b19_01
	if r(sd)==0 | r(sd)==. {
	scalar b19_included=0
	}
	}

	if b19_included==1 {
	drop cage_youngest
	gen cage_youngest=b19_01
	}

label var cage_youngest "Age in months of woman's youngest child"

* Step 3. Create a variable that indicates whether a woman 15-49 years of age is underweight according to their BMI (BMI<18.5kg/m2) (whn_uw). That is, use v445 (women's BMI without decimals) to identify women who are underweight. Women with a v455 value between 1200 and 1849 are underweight; women with a v455 value between 1850 and 6000 are not underweight. Women with a v455 value less than 1200 or greater than 6000 are excluded from the calculation. Be sure to exclude women who reported that they were pregnant at the time of interview (v213=1) or gave birth to a child during the 2 months preceding the survey (cage_youngest<2).

gen whn_uw= inrange(v445,1200,1849) if inrange(v445,1200,6000)
replace whn_uw=.   if (v213==1 | cage_youngest<2)
label va whn_uw yesno
label var whn_uw "Underweight woman, BMI<18.5kg/m2"

* Step 4 - Create a variable that categorizes women 15-49 years of age into two age categories (15-19 and 20-49 years of age) (agegrp_wra_2grp) using survey variable v012, women's age in years. 

generate 	agegrp_wra_2grp=.
replace 	agegrp_wra_2grp=1 if v012>=15 & v012<=19 
replace 	agegrp_wra_2grp=2 if v012>=20 & v012<=49 
label def   agegrp_wra_2grp 1 "15-19"  2 "20-49"
label var	agegrp_wra_2grp "Women 15-49 age category (15-19, 20-49 years)" 

* Step 5. Create a variable that categorizes women 15-49 years of age into 5-year age categories (agegrp_wra_7grp).
recode v012 15/19=1 20/24=2 25/29=3 30/34=4 35/39=5 40/44=6 45/49=7, generate (agegrp_wra_7grp)
la var  agegrp_wra_7grp  "Woman 15-49 age category (5-year groups)"
la def whn_agegrps  1 "15-19" 2 "20-24"  3 "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45-49"
la val agegrp_wra_7grp whn_agegrps

* Step 6. After applying the women's individual sampling weight, calculate the percentage of women 15 49 years of age who are underweight according to their BMI. Repeat using the women's age category disaggregates (agegrp_wra_2grp and agegrp_wra_7grp), as well as the wealth quintile disaggregate (v190). Note that in DHS women's data files, v005 is the women's individual sampling weight without any decimal places, v001 is the cluster variable, and v022 is the strata variable. Because the women's file contains records for only de facto household members, there is no need to specify de facto household members in the sub-population definition.

generate wgt_wra=v005/1000000 
svyset v001 [pw=wgt_wra], strata(v022) singleunit(scaled) 
svy, subpop(ftf_zoi): tab whn_uw 
svy, subpop(ftf_zoi): tab whn_uw agegrp_wra_2grp, col  
svy, subpop(ftf_zoi): tab whn_uw agegrp_wra_7grp, col 
svy, subpop(ftf_zoi): tab whn_uw v190, col 

// Step 7. Save the data file with the women's anthropometry variables created in this section. 

save “[CC]IR[VV]FL_FTF_ZOI_WHN.DTA” , clear


**********************************************************
** 17.2.7. Additional women's anthropometric indicators **
**********************************************************

// Mean BMI. Create a variable that can be used to calculate the mean BMI for women 15-49 years of age (whn_bmi).
gen bmi=v445/100
summarize bmi if inrange(bmi,12,60) & (v213!=1 & (v208==0 | age>=2)) [iw=wt]
gen whn_bmi=round(r(mean),0.1)
label var whn_bmi "Mean BMI, women 15-49 years"

// Normal weight. Create a variable that indicates whether a woman 15-49 years of age is of normal weight according to their BMI (BMI≥18.5kg/m2 and BMI<25.0kg/m2) (whn_hw). That is, use v445 (women's BMI without decimals) to identify women who are of normal weight. Women with a v455 value greater than or equal to 1850 and less than 2500 are of normal weight; women with a v455 value greater than or equal to 1200 and less than 1850 or between 2500 and 6000 are not of normal weight. Women with a v455 value less than 1200 or greater than 6000 are excluded from the calculation. Be sure to exclude women who reported that they were pregnant at the time of interview (v213=1) or gave birth to a child during the 2 months preceding the survey (cage_youngest<2).

gen whn_hw= inrange(v445,1850,2499)  if inrange(v445,1200,6000)
replace whn_hw=.   if (v213==1 | cage_youngest<2)
label val whn_hw yesno
label var whn_hw "Normal weight (BMI>=18.5kg/m2, BMI<25.0kg/m2)"

// Overweight. Create a variable that indicates whether a woman 15-49 years of age is overweight according to their BMI (BMI≥25.0kg/m2 and BMI<30.0kg/m2) (whn_ow). That is, use v445 (women's BMI without decimals) to identify women who are overweight. Women with a v455 value greater than or equal to 2500 and less than 3000 are overweight; women with a v455 value greater than or equal to 1200 and less than 2500 or between 3000 and 6000 are not overweight. Women with a v455 value less than 1200 or greater than 6000 are excluded from the calculation. Be sure to exclude women who reported that they were pregnant at the time of interview (v213=1) or gave birth to a child during the 2 months preceding the survey (cage_youngest<2).

gen whn_ow= inrange(v445,2500,2999) if inrange(v445,1200,6000)
replace whn_ow=. if (v213==1 | cage_youngest<2)
label val whn_ow yesno
label var whn_ow "Overweight (BMI>=25.0kg/m2, BMI<30.0kg/m2)"

// Obese. Create a variable that indicates whether a woman 15-49 years of age is obese according to their BMI (BMI≥30.0kg/m2) (whn_obese). That is, use v445 (women's BMI without decimals) to identify women who are obese. Women with a v455 value greater than or equal to 3000 and less than 6000 are obese; women with a v455 value greater than or equal to 1200 and less than 3000 are not obese. Women with a v455 value less than 1200 or greater than 6000 are excluded from the calculation. Be sure to exclude women who reported that they were pregnant at the time of interview (v213=1) or gave birth to a child during the 2 months preceding the survey (cage_youngest<2).

gen whn_obese= inrange(v445,3000,6000) if inrange(v445,1200,6000)
replace whn_obese=. if (v213==1 | cage_youngest <2)
label val whn_obese yesno
label var whn_obese "Obese (BMI>=30.0kg/m2)"

// BMI category. Create a categorical variable that captures the percent distribution women by their nutritional status according to their BMI category (bmi_cat). The variable includes four categories: underweight, healthy weight, overweight, and obese.

tabstat whn_uw whn_hw whn_ow whn_obese, stat(sum)
gen     bmi_cat=1 if whn_uw==1
replace bmi_cat=2 if whn_hw==1
replace bmi_cat=3 if whn_ow==1
replace bmi_cat=4 if whn_obese==1
tab     bmi_cat
label def 1 "Underweight" 2 "Healthy weight" 3 "Overweight" 4 "Obese"
label var bmi_cat "BMI Category"

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] women anthropometry.dta", replace

log close




 
