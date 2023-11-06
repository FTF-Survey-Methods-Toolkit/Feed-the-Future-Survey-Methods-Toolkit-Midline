/*******************************************************************************
*************************** FEED THE FUTURE ZOI SURVEY *************************
*****************************        RESILENCE       ***************************
********************************* [COUNTRY-YEAR] *******************************
********************************************************************************
Description:  This code is intended to calculate four Feed the Future phase two 
resilience indicators:
    1a. Shock exposure index (SEI)
	1b. Ability to recover from shocks and stresses index (ARSSI)
	2. Index of social capital at the household level
	3. Percent of HHs that believe local government will respond effectively to 
	   future shocks and stresses
	4. Percent of HHs participating in group-based savings, micro-finance or lending programs

Author(s):  Nizam Khan @ICF, Kirsten Zalisk @ICF, June 2018
Revised by:  Tesfayi Gebreselassie & Mandy McCleary @ ICF, May 2022

Note: Questions referring to the effect of shock or stress on 
     the household's economic situation are dropped because of the high correlation 
	 with the effect of shock or stress on hh consumption.

This syntax file was developed using the core Feed the Future ZOI Survey phase one 
endline/phase two baseline core questionnaire. It must be adapted for the final  
country-specific questionnaire. The syntax could only be partially tested using 
ZOI Survey data; therefore, double-check all results carefully and troubleshoot 
to resolve any issues identified. 
********************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\Midline FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] resilience.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] resilience.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax resilience.do 
//Key indicators(s):    
 
cap log close
cap log using  "$analytic\Log\Midline FTF ZOI Survey [COUNTRY] [YEAR] resilience.log", replace

********************************************************************************

*Step 0. Load the household-level analytic data file

use  "$analytic\Midline ZOI household data analytic.dta", clear 

********************************************************************************
//Indicator 1. ABILITY TO RECOVER FROM SHOCKS AND STRESSES INDEX (ARSSI)
********************************************************************************

***Step 1. Calculate base ability-to-recover index (atr) [range 2-6]

*1a. Identify and check all the variables needed to construct the indicators 
*NOTE: Variables may differ across countries, depending on the number of shocks
*      included in the questionnaire.
tab1 v309-v360

*1b. Recode v359 and v360 so that higher values mean better ability to recover, and set any refused responses to missing
tab1    v359 v360
for var v359 v360: recode X 1=3 2=2 3=1 4/max=., gen(Xx)
sum     v359 v360 v359x v360x
tab1    v359x v360x

*1c. Sum the recoded responses to v359 and v360 into one variable 
*    (atr, Base Ability To Recover), and set ATR to missing if v359 and v360 are missing.
egen    atr=rowtotal(v359x v360x)
replace atr=. if v359x==. | v360x==. 
tab     atr,m 
la var atr "Ability to recover index"

*Step 2. Calculate shock exposure index (sei) [range 0-64]
*  Questions referring to the effect of shock or stress on the household's 
*  economic situation are dropped because of the high correlation 
*  with the effect of shock or stress on hh consumption.

*2a. Generate global macro for severity of shock on household's food consumption
*    and recode any values greater than 4 to missing, generating new analytic variables

*--Severity of shock on household's food consumption 
global hhcons v311 v314 v317 v320 v323 v326 v330 v333 v336 v339 v342 v345 v348 v351 v354 v357

sum $hhcons

for var $hhcons: recode X 5/max=., gen(Xx)

*2b. Generate analytic variables for each question asking if the household experienced 
*  a certain shock during the year prior to the survey in which all no responses 
*  are recoded from 2 to 0. 


*--Did household experience shock? 
global shock  v309 v312 v315 v318 v321 v324 v328 v331 v334 v337 v340 v343 v346 v349 v352 v355

sum $shock

for var $shock: recode X 2=0 3/max=., gen(Xx) 

*2c. For shocks that were only asked of HHs cultivating crops or that own livestock 
* recode any missing responses to be 0.
for var v328x v331x v334x v337x: recode X .=0 if v327==2
for var v340x v343x v346x: recode X .=0 if v340a==2

*2d. Generate analytic variables for perceived impact of each schock on
*    household consumption

	egen perceived_sev1= rowtotal(v311x)
	egen perceived_sev2= rowtotal(v314x)
	egen perceived_sev3= rowtotal(v317x)
	egen perceived_sev4= rowtotal(v320x)
	egen perceived_sev5= rowtotal(v323x)
	egen perceived_sev6= rowtotal(v326x)
	egen perceived_sev7= rowtotal(v330x)
	egen perceived_sev8= rowtotal(v333x)
	egen perceived_sev9= rowtotal(v336x)
	egen perceived_sev10=rowtotal(v339x)
	egen perceived_sev11=rowtotal(v342x)
	egen perceived_sev12=rowtotal(v345x)
	egen perceived_sev13=rowtotal(v348x)
	egen perceived_sev14=rowtotal(v351x)
	egen perceived_sev15=rowtotal(v354x)
	egen perceived_sev16=rowtotal(v357x)

sum  perceived_sev*


*2e. Then multiply incidence of experience of each shock 
*    by perceived severity of each shock and add all into one variable to create 
*    weighted shock exposure index (SEI).The SEI ranges from 0 to 64 (if all 
*    16 shocks/stressors were experienced by the HHs at the highest level of 
*    severity).

gen sei = (perceived_sev1*v309x) + ///
          (perceived_sev2*v312x) + ///
          (perceived_sev3*v315x) + ///
          (perceived_sev4*v318x) + ///
          (perceived_sev5*v321x) + ///
          (perceived_sev6*v324x) + ///
          (perceived_sev7*v328x) + ///
          (perceived_sev8*v331x) + ///
          (perceived_sev9*v334x) + ///
          (perceived_sev10*v337x) + ///
          (perceived_sev11*v340x) + ///
          (perceived_sev12*v343x) + ///
          (perceived_sev13*v346x) + ///
          (perceived_sev14*v349x) + ///
          (perceived_sev15*v352x) + ///
          (perceived_sev16*v355x) 
sum  sei

la var sei "Shock exposure index"

*2f. generate a new variable to note HHs with any missing or refused questions 
*   in the SEI so they can be excluded from the analysis, as needed.

gen         anymissing=0
	replace anymissing=1 if v309x==. | (v309x==1 & (v311x==.))
	replace anymissing=1 if v312x==. | (v312x==1 & (v314x==.))
	replace anymissing=1 if v315x==. | (v315x==1 & (v317x==.))
	replace anymissing=1 if v318x==. | (v318x==1 & (v320x==.))
	replace anymissing=1 if v321x==. | (v321x==1 & (v323x==.))
	replace anymissing=1 if v324x==. | (v324x==1 & (v326x==.))
	replace anymissing=1 if v328x==. | (v328x==1 & (v330x==.))
	replace anymissing=1 if v331x==. | (v331x==1 & (v333x==.))
	replace anymissing=1 if v334x==. | (v334x==1 & (v336x==.))
	replace anymissing=1 if v337x==. | (v337x==1 & (v339x==.))
	replace anymissing=1 if v340x==. | (v340x==1 & (v342x==.))
	replace anymissing=1 if v343x==. | (v343x==1 & (v345x==.))
	replace anymissing=1 if v346x==. | (v346x==1 & (v348x==.))
	replace anymissing=1 if v349x==. | (v349x==1 & (v351x==.))
	replace anymissing=1 if v352x==. | (v352x==1 & (v354x==.))
	replace anymissing=1 if v355x==. | (v355x==1 & (v357x==.))

*2g. Calculate the average SEI
egen mean_sei = mean(sei) if anymissing==0
la var mean_sei "Mean SEI for surveyed HHs"

tab mean_sei

*Step 3. Calculate shock exposure-corrected ability to recover from shocks and 
*        stresses index (ARSSI)

*3a. Run a linear regression of the base ATR index on the SEI 
reg atr sei
gen b_atr=_b[sei]  //coefficient b    
sum b_atr

*3b. Calculate the ARSSI for each household 
gen arssi = atr + b_atr * (mean_sei-sei)
sum arssi
la var arssi "Ability-to-recover from shocks and stresses index (ARSSI)"


*Step 4. Generaet shock exposure index (sei) categories for disaggregated analysis

* Partition the values of sei into 3 equal groups 
xtile   shock_sev=sei if sei >0 & sei!=., nq(3)
replace shock_sev=0 if sei==0
tab     shock_sev
la var  shock_sev "Severity of shock exposure"

* Recode to generate 4 categories including 'No shock experienced'
recode  shock_sev 0=1 1=2 2=3 3=4
la def sei_level 1 "Did not experience any shocks" 2 "Low" 3 "Moderate" 4 "High"
la val shock_sev sei_level
tab     shock_sev

* Step 5. Disaggregated analysis of ARSSI and severity of shock exposure(shock_sev)
* Note: Take into account any subpopulation using subpop()
*
svyset hhea [pw=hh_wgt], strata(strata)
svy: mean arssi
svy: mean arssi, over(genhtype_dj)

********************************************************************************
label define yesno 0 No 1 Yes 

*******************************************************************************
***
***  //Indicator 2: INDEX OF SOCIAL CAPITAL 
***
********************************************************************************
** This indicator is constructed from two sub-indices: 
** (1) bonding sc: the degree of bonding among households  
**      in their own community:v361a, v361b, v361e and v361f 
** (2) bridging sc: the degree of bridging between households in the area 
**       to households outside their own community: v361c, v361d, v361g, v361h
**--------------------------------------------------------------------------**
/*2a. Bonding social capital index (v361a v361e v361b v361fc)
**--------------------------------------------------------------------------**
*  A measure of whether the HH would be able to get help from or give help to people 
*  living INSIDE their community if they needed it. That is  
* (1) Household be able to lean on relatives/non-relatives living in your community: v361a, v361e
* (2) Same relatives/non-relatives living in your community are able to lean on you: v361b,v361f
*/

tab1 v361a v361e v361b v361f
for var v361a v361e v361b v361f: gen Xx=1   if X==1 
for var v361a v361e v361b v361f: replace Xx=0   if X!=1 
* If No Consent and module is blank
for var v361a v361e v361b v361f: replace Xx=.   if v300d!=1

* To capture skips
replace v361bx = 0  if v361a==2
replace v361fx = 0  if v361e==2

sum v361?x

* Generate the Bonding Social Capital index taking into account reciprocal relationship
* By checking whether the HH be able to lean on relatives or non-relatives 
*   and same relatives or non-relatives are able to lean on the HH 
*   INSIDE of their community. 
* 
gen     scap_bond=0
replace scap_bond=1             if (v361ax==1 & v361bx==1) 
replace scap_bond=scap_bond+1 if (v361ex==1 & v361fx==1)
replace scap_bond=.             if v361ax==. | v361bx==. | v361ex==. | v361fx==.

tab scap_bond	
la var scap_bond "Bonding SC (0-2)"
*
** -------------------------------------------------------------------
/*2b. Bridging social capital (v361c v361g v361d v361h)
** -------------------------------------------------------------------
* This index is based on whether: 
* (1) Household be able to lean on relatives/non-relatives living OUTSIDE the community: v361c, v361g
* (2) Same relatives/non-relatives living OUTSIDE your community are able to lean on you: v361d,v361h
*/
* 
tab1 v361c v361g v361d v361h
*
for var v361c v361g v361d v361h: gen Xx=1   if X==1 
for var v361c v361g v361d v361h: replace Xx=0   if X!=1 
* If No Consent and module is blank
for var v361c v361g v361d v361h: replace Xx=.   if v300d!=1

* To capture skips
replace v361dx = 0  if v361c==2
replace v361hx = 0  if v361g==2

sum v361?x

*2b. * Generate the Bridging Social Capital index taking into account reciprocal relationship
* By checking whether the HH be able to lean on relatives or non-relatives 
*   and same relatives or non-relatives are able to lean on the HH 
*   OUTSIDE of their community. 
*
gen     scap_bridge=0
replace scap_bridge=1               if (v361cx==1 & v361dx==1) 
replace scap_bridge=scap_bridge+1 if (v361gx==1 & v361hx==1)
replace scap_bridge=.               if v361cx==. | v361dx==. | v361gx==. | v361hx==.
*
tab    scap_bridge
la var scap_bridge "Bridging SC (0-2)"

**--------------------------------------------------------------------------
/*2c. INDEX OF SOCIAL CAPITAL 
* This indicator is constructed from two sub-indices, (1) bonding sc and (2) bridging sc.
* The index of sc is the average of the sum of bonding and bridging SCs
**-------------------------------------------------------------------------
* 2c. Index of Social Capital
** Compute the average of the sum of bonding and bridging 
*/
gen    scap_index = (scap_bond+scap_bridge)/2 
la var scap_index "Index of social capital"
tab    scap_index

*******************************************************************************
* Rescale SC index to 100
*
gen     i_scap_index=(scap_index/2)*100
la var  i_scap_index "Social capital index (rescaled)"
tab     i_scap_index

*******************************************************************************
********************************************************************************
// Indicator 3. HOUSEHOLDS THAT BELIEVE LOCAL GOVERNMENT WILL RESPOND EFFECTIVELY 
//        		TO FUTURE SHOCKS AND STRESSES
********************************************************************************
**The indicator measures households' in a specific geographic area's belief the
**local government will help the community cope with difficult times in the 
**future. 
*10/05/2021: Amended instructions and variable label to reflect question text in Midline Codebook and Questionnaire.

**Step 1. Identify and check the variable needed to construct the indicator
tab v362

**Step 2. Calculate the indicator dropping any households that refused to 
**	      answer the question or for which a response is missing.
recode v362 2=0 3/max=., gen(locgov_resp)
la val locgov_resp yesno
tab locgov_resp,m
la var locgov_resp "HH believes local govt will help the community cope with future difficult times and shocks or stresses."

tab locgov_resp

********************************************************************************
*******************************************************************************

**//Indicator 4. ACCESS TO MICROFINANCE
**               Percent of HHs participating in group-based savings, 
***              micro-finance or lending programs
********************************************************************************
**
** Three ways to calculate ACCESS to MICROFINANCE are presented depending on 
**   the ZOI survey focus and time - Baseline or Midline
**
** -------------------------------------------------------------------------- **
** Option 1. Include all HHs that had a PADM respond to the A-WEAI module 
*   (the female module, the male module, or both). The baseline syntax, includes 
*   relevant variables from the male module (m6*) – Baseline only
*   That is, both Female and Male PDMs as denominator. Use Module 6 vars.
*
* Flag primary adult decision makers who said at least one person from 
*their household participated in group-based savings, micro-finance or lending 
*program in the previous 12 months.

gen     access_finance1=.
*Include participants who completed the module
replace access_finance1=0 if v6100d==1 | m6100d==1
*Group-based microfinance (cash/inkind)
replace access_finance1=1 if v6308_5<=3 | m6308_5<=3  
*Informal credit/savings groups (cash/inkind)
replace access_finance1=1 if v6308_6<=3 | m6308_6<=3  
*Active member of a credit/microfinance group
replace access_finance1=1 if v6405_05==1 | m6405_05==1 

la var access_finance1 "Option 1- HH had access to group-based savings, microfinance or lending"
la val access_finance1 YESNO
tab access_finance1
*
**--------------------------------------------------------------------------- **
* Option 2. Direct comparability – Baseline & Midline 
** Only Female PDMs used
*
gen     access_finance2=.
*Include participants who completed the module
replace access_finance2=0 if v6100d==1
*Group-based microfinance (cash/inkind)
replace access_finance2=1 if v6308_5<=3   
*Informal credit/savings groups (cash/inkind)
replace access_finance2=1 if v6308_6<=3   
*Active member of a credit/microfinance group
replace access_finance2=1 if v6405_05==1 
*
la var access_finance2 "Option 2- HH had access to group-based savings, microfinance or lending "
la val access_finance2 yesno
tab access_finance2
*
**----------------------------------------------------------------------
*Option 3. Using questions added to Module 3 for Midline survey 
*      (Module 3, v364 to v367) – Midline only
* 
gen access_finance3=.
replace access_finance3=0 if v300d==1 
* Taken any loans or borrowed cash/in-kind from a group-based micro-finance or lending program
replace access_finance3=1 if v364 <=3  
* Taken any loans or borrowed cash/in-kind from an informal credit or savings group
replace access_finance3=1 if v365 <=3    
*Active member credit or microfinance group, such as a 
*  Savings and Credit Cooperative Organization (SACCO)
replace access_finance3=1 if v367==1 & v366==1

la var access_finance3 "Option 3- HH had access to group-based savings, microfinance or lending"
la val access_finance3 yesno
tab access_finance3



save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] resilience.dta", replace 

di "Date:$S_DATE $S_TIME"
log close

