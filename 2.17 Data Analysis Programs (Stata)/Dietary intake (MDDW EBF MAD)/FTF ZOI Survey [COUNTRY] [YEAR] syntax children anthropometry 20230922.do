/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
******************** NON-FOOD CONSUMPTION IN THE PAST 3 MONTHS******************
******************************* [COUNTRY] [YEAR] *******************************
********************************************************************************
Purpose:	Code to compute anthropometry indicators for children under 5 years
Data inputs:  DHS PR dataset 
Data outputs: Children's anthropometry indicators

Syntax prepared by ICF, September 21, 2023
Revised by ICF, September 2023 

Note: This syntax file is for use with the Demographic and Health Survey PR 
datasets. 			
*******************************************************************************/

set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"
global anthro 	 "FTF ZOI Survey [COUNTRY] [YEAR] NAME\Anthropometry"

//Input data:   $anthro\[CC]PR[VV]FL_FTF_ZOI.DTA
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] children anthropometry.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] children anthropometry.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax children antrhopometry.do 

cap log close 
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] children anthropometry.log",replace

/*-----------------------------------------------------------------------------------------
Variables created in this file:
chn_stunted		"Stunted child under 5 years"
chn_wasted		"Wasted child under 5 years"
chn_hw          "Child under 5 years with healthy weight"

Additional indicators:
chn_sev_stunted "Severely stuned child under 5 years"
chn_sev_wasted "Severely wasted child under 5 years"
chn_haz "Mean height for age"
chn_ow "Overweight child under 5 years"
chn_whz "Mean weight for height"

Variables used:
hc70  -   "height/age standard deviation (new who)"
hc72  -   "weight/height standard deviation (new who)"
hc71  -    "weight/age standard deviation (new who)"
hv000 - "code and phase"
hv001 - "Cluster number"
hv002 - "Household number"
hv006 - "Month of interview"
hv007 - "Year of interview"
hv008 - "Date of interview (CMC)"
hv001 - "cluster number"
hv005 - "household sample weight (6 decimals)"
hv013 - "number of de facto members"
hv022 - "Sample strata for sampling errors"
hv023 - "Stratification used in sample design"
hv024 - "Region"
hv103 - "slept last night (de facto living child)"
hv106 - "Highest educational level attained"
hv270 - "wealth index"
hc1  -   "child age in months"
hc27 -  "sex of the child"

--------------------------------------------------------------------------------------------*/


*****************************************************************
** 17.2.2. Prevalence of stunted children under 5 years of age **
*****************************************************************
// This indicator estimates the percentage of children under 5 years of age (0-59 months) who are moderately to severely stunted. The indicator is calculated using DHS survey data.  

* Step 1. Load the household member data file that was created in Section 17.2.1.
use "$anthro\[CC]PR[VV]FL_FTF_ZOI.DTA", clear

* Step 2. Create a variable to indicate whether a child is stunted (chn_stunted). Children with a HAZ score less than -2 (i.e., hc70<-200) are categorized as stunted. Children with a HAZ score determined to be invalid (HAZ score <-6 or HAZ score >+6) or missing (hc70≥9996) are set to missing.

gen chn_stunted= 0      if hv103==1
replace chn_stunted=.   if hc70>=9996
replace chn_stunted=1  if hc70<-200 & hv103==1 
label val chn_stunted yesno
label var chn_stunted "Stunted child under 5 years"

* Step 3. Create a variable that categorizes children under 5 years of age into two age categories (0-23 months and 24-59 months) (agegrp_cu5_2grp). 
gen	agegrp_cu5_2grp=. 
replace agegrp_cu5_2grp=0 if hc1<24 
replace agegrp_cu5_2grp=1 if hc1≥24 & hc1<60 
label def 0 "0-23 months" 1 "24-59 months"
label var "Child under 5 age category (0-23, 24-59 months)" 

* Step 4. Create a variable that categorizes children under 5 years of age into 12-month age categories (agegrp_cu5_5grp).

gen agegrp_cu5_5grp=. 
replace agegrp_cu5_5grp=1 if hc1<12 
replace agegrp_cu5_5grp=2 if hc1≥12 & hc1<24 
replace agegrp_cu5_5grp=3 if hc1≥24 & hc1<36 
replace agegrp_cu5_5grp=4 if hc1≥36 & hc1<48 
replace agegrp_cu5_5grp=5 if hc1≥48 & hc1<60 
label def 1 "0-11 months"  2 "12-23 months"  3 "24-35 months"  4 "36-47 months" 5 "48-59 months"
label var "Child under 5 age category (12-month groups)"

* Step 5. After applying the household sampling weight, calculate the percentage of children under 5 years of age who are stunted (de facto household members only). Repeat using the child sex (hc27) and child age category disaggregates (agegrp_cu5_2grp and agegrp_cu5_5grp), as well as the wealth quintile disaggregate (hv270). Note that in DHS datasets, hv005 is the household sampling weight without any decimal places, hv001 is the cluster variable, hv022 is the strata variable, and hv103 is the de facto household member variable. 

gen wgt_hh=hv005/1000000 
svyset hv001 [pw=wgt_hh], strata(hv022) singleunit(scaled) 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_stunted  
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_stunted hc27, col 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_stunted agegrp_cu5_2grp, col 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_stunted agegrp_cu5_5grp, col 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_stunted hv270, col 

******************************************************************
** 17.2.3. Prevalence of wasted children under 5 years of age.  **
******************************************************************
// This indicator estimates the percentage of children under 5 years of age (0-59 months) who are moderately to severely wasted. The indicator is calculated using DHS survey data. 

* Step 1. Using the same data file used to calculate the stunting indicator in Section 17.2.2, create a variable to indicate whether a child is wasted (chn_wasted). Children with a WHZ score less than -2 (i.e., hc72<-200) are categorized as wasted. Children with a WHZ score determined to be invalid (WHZ score <-5 or HAZ score >+5) or missing (hc72≥9996) are set to missing.

gen chn_wasted= 0 if hv103==1
replace chn_wasted=. if hc72>=9996
replace chn_wasted=1 if hc72<-200 & hv103==1 
label val chn_wasted yesno
label var chn_wasted "Wasted child under 5 years"

* Step 2. After applying the household sampling weight, calculate the percentage of children under 5 years of age who are wasted (de facto household members only). Repeat using the child sex (hc27) and child age category disaggregates (agegrp_cu5_2grp and agegrp_cu5_5grp), as well as the wealth quintile disaggregate (hv270). Note that in DHS datasets, hv005 is the household sampling weight without any decimal places, hv001 is the cluster variable, hv022 is the strata variable, and hv103 is the de facto household member variable. 

gen wgt_hh=hv005/1000000 
svyset hv001 [pw=wgt_hh], strata(hv022) singleunit(scaled) 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_wasted  
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_wasted hc27, col 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_wasted agegrp_cu5_2grp, col 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_wasted agegrp_cu5_5grp, col 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_wasted hv270, col 

************************************************************************
** 17.2.4. Prevalence of healthy weight children under 5 years of age **
************************************************************************
// This indicator estimates the percentage of children under 5 years of age (0-59 months) who have a healthy weight in the ZOI population. The indicator is calculated using DHS survey data. 

* Step 1. Using the same data file used to calculate the stunting indicator in Section 17.2.2 and wasting indicator in Section 17.2.3, create a new variable to indicate whether a child is of healthy weight (chn_hw). Children with a WHZ score greater or equal to -2 and less than or equal to +2 (i.e., hc72≥-200 and hc72≤+200) are categorized as being of healthy weight. Children with a WHZ score determined to be invalid (WHZ score <-5 or WHZ score >+5) or missing (hc72≥9996) are set to missing.

gen chn_hw=0      if hv103==1
replace chn_hw=1 if hc72≥-200 & hc72≤+200 
replace chn_hw=. if hc72≥9996 
label val chn_hw yesno
label var "Healthy weight child under 5 years"

* Step 2. After applying the household sampling weight, calculate the percentage of children under 5 years of age who are a healthy weight (de facto household members only). Repeat using the child sex (hc27) and child age category disaggregates (agegrp_cu5_2grp and agegrp_cu5_5grp), as well as the wealth quintile disaggregate (hv270). Note that in DHS datasets, hv005 is the household sampling weight without any decimal places, hv001 is the cluster variable, hv022 is the strata variable, hv103 is the de facto household member variable, hc27 is the child sex variable, and hv270 is the wealth quintile variable

generate wgt_hh = hv005/1000000 
svyset hv001 [pw=wgt_hh], strata(hv022) singleunit(scaled) 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_hw  
svy, subpop(if ftf_zoi==1 & hv103 ==1): tab chn_hw hc27, col 
svy, subpop(if ftf_zoi==1 & hv103 ==1): tab chn_hw agegrp_cu5_2grp, col 
svy, subpop(if ftf_zoi==1 & hv103==1): tab chn_hw agegrp_cu5_5grp, col 
svy, subpop(if ftf_zoi==1 & hv103 ==1): tab chn_hw hv270, col 

* Step 3. Save the data file with the children's antrhopometric variables created in sections 17.2.2-17.2.4

save “[CC]PR[VV]FL_FTF_ZOI_CHN.DTA” , clear

*************************************************************
** 17.2.6. Additional children's antrhopometric indicators **
*************************************************************
// This section describes how to create additional children's anthropometric indicators that are presented in midline indicator assessment reports. They can be added to the data file, [CC]PR[VV]FL_FTF_ZOI_CHN.DTA, created in Section 17.2.4, Step 4, that also has the other children's anthropometric indicator variables, and the sample-weighted estimates can be generated using the same approach taken for the key Feed the Future children's anthropometric indicators (e.g., see Section 17.2.2, Step 5).

// Severely stunted. Create a variable to indicate whether a child is severely stunted (chn_sev_stunted). Children with a HAZ score less than -3 (i.e., hc70<-300) are categorized as severely stunted. Children with a HAZ score determined to be invalid (HAZ score <-6 or HAZ score >+6) or missing (hc70≥9996) are set to missing.

gen chn_sev_stunted= 0      if hv103==1
replace chn_sev_stunted=.   if hc70>=9996
replace chn_sev_stunted=1  if hc70<-300 & hv103==1 
label val chn_sev_stunted yesno
label var chn_sev_stunted "Severely stunted child under 5 years"

// Mean HAZ. Create a variable that can be used to calculate the mean HAZ score for children under 5 years of age (chn_haz). Children with a HAZ score determined to be invalid (HAZ score <-6 or HAZ score >+6) or missing (hc70≥9996) are set to missing.

gen haz=hc70/100    if hc70<996
summarize haz         if hv103==1 [iw=wt]
gen chn_haz=round(r(mean),0.1)
label var chn_haz "Mean z-score for height-for-age for children under 5 years"

// Severely wasted. Create a variable to indicate whether a child is severely wasted (chn_sev_wasted). Children with a WHZ score less than -3 (i.e., hc72<-300) are categorized as severely wasted. Children with a WHZ score determined to be invalid (WHZ score <-5 or WHZ score >+5) or missing (hc72≥9996) are set to missing.

gen chn_sev_wasted= 0       if hv103==1
replace chn_sev_wasted=.    if hc72>=9996
replace chn_sev_wasted=1   if hc72<-300 & hv103==1 
label val chn_sev_wasted yesno
label var chn_sev_wasted "Severely wasted child under 5 years"

// Overweight for height. Create a variable to indicate whether a child is overweight for their height (chn_ow). Children with a WHZ score greater than +2 (i.e., hc72>+200) are categorized as overweight for their height. Children with a WHZ score determined to be invalid (WHZ score <-5 or WHZ score >+5) or missing (hc72≥9996) are set to missing.

gen chn_ow= 0      if hv103==1
replace chn_ow=.   if hc72>=9996
replace chn_ow=1  if hc72>200 & hc72<9996 & hv103==1 
label val chn_ow yesno
label var chn_ow "Overweight for height child under 5 years"

// Obese for height. Create a variable to indicate whether a child is obese for their height (chn_obese). Children with a WHZ score greater than +3 (i.e., hc72>+300) are categorized as obese for their height. Children with a WHZ score determined to be invalid (WHZ score <-5 or WHZ score >+5) or missing (hc72≥9996) are set to missing.

gen chn_obese= 0 if hv103==1
replace chn_obese=. if hc72>=9996
replace chn_obese=1 if hc72>300 & hc72<9996 & hv103==1 
label val chn_obese yesno
label var chn_obese "Obese for height child under 5 years"

//Mean whz. Create a variable that can be used to calculate the mean WHZ score for children under 5 years of age (chn_whz). Children with a WHZ score determined to be invalid (WHZ score <-5 or WHZ score >+5) or missing (hc72≥9996) are set to missing.

gen whz=hc72/100    if hc72<996
summarize whz         if hv103==1 [iw=wt]
gen chn_whz=round(r(mean),0.1)
label var chn_whz "Mean z-score for weight-for-height for children under 5 years"

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] children anthropometry.dta", replace

log close
