/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
*****************************        RESILENCE       ***************************
******************************** [COUNTRY] [YEAR] ******************************
********************************************************************************
Description:  This code is intended to calculate four Feed the Future phase two 
resilience indicators:
    1. Ability to recover from shocks and stresses index (ARSSI)
	2. Index of social capital at the household level
	3. Percent of HHs that believe local government will respond effectively to 
	   future shocks and stresses
	4. Percent of HHs participating in group-based savings, micro-finance or 
	   lending programs

Syntax prepared by ICF, June 2018
Revised by ICF, September 2023

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 11.2 in the Guide to Feed the Future Midline 
Statistics.

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. Be sure to adjust it as needed to align with the 
country-customized questionnaire.
********************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:  $analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log result:  $analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] resilience.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] resilience.dta
//Syntax:      $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax resilience.do 
//Key indicators(s):    
 
cap log close
cap log using  "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] resilience.log", replace

********************************************************************************

*Step 0. Load the household-level analytic data file
use  "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear 

********************************************************************************
**#Indicator 1. ABILITY TO RECOVER FROM SHOCKS AND STRESSES INDEX (ARSSI)
********************************************************************************

*Step 1: Calculate base ability-to-recover index (atr) [range 2-6]

*Step 1.1: Identify and check all the variables needed to construct the indicators 
*NOTE:     Variables may differ across countries, depending on the number of shocks
*          included in the questionnaire.
tab1 v309-v360

*Step 1.2: Create two analytic variables: v359x and v360x, which recode the 
*          response options of variables v359 and v360 so that a higher value 
*          indicates a greater ability to recover from shocks, and set any 
*          indicates a refused responses to missing.
tab1    v359 v360
for var v359 v360: recode X 1=3 2=2 3=1 4/max=., gen(Xx)
sum     v359 v360 v359x v360x
tab1    v359x v360x
la def	recover 1 "Worse" 2 "Same" 3 "Better"
for var v359x v350x: la val X recover
la var v359x "HH's current recovery status"
la var v360x "HH's recovery status in 1 year"

*Step 1.3: Sum the recoded variables v359x and v360x into one variable (atr) 
*          that has a minimum value of 2 and a maximum value of 6, and set atr
*          to missing if v359x or v360x is missing.
egen    atr=rowtotal(v359x v360x)
replace atr=. if v359x==. | v360x==. 
tab     atr,m 
la var atr "Ability to recover index (2-6)"

*Step 2. Calculate shock exposure index (sei) [range 0-64]
*  Questions referring to the effect of shock or stress on the household's 
*  economic situation are dropped because of the high correlation 
*  with the effect of shock or stress on hh consumption.

*Step 2.1: Create global macro for severity of shock on HH's food consumption 
*          and then recode any values greater than 4 to missing, generating new 
*          analytic variables

*--Severity of shock on household's food consumption 
global hhcons v311 v314 v317 v320 v323 v326 v330 v333 v336 v339 v342 v345 v348 v351 v354 v357

sum $hhcons

for var $hhcons: recode X 5/max=., gen(Xx)
la def severity 1 "Not severe" 2 "Somewhat severe" 3 "Severe" 4 "Extremely severe"
for var $hhcons: la val Xx severity

*Step 2.2: Create analytic variables for each question asking if the HH experienced 
*          a certain shock during the year prior to the survey in which all no 
*          responses are recoded from 2 to 0. 

*--Did household experience shock? 
global shock v309 v312 v315 v318 v321 v324 v328 v331 v334 v337 v340 v343 v346 v349 v352 v355

sum $shock

for var $shock: recode X 2=0 3/max=., gen(Xx) 
for var $shock: la val Xx YESNO

*Step 2.3: For shocks that were only asked of HHs cultivating crops or that own  
*          livestock recode any missing responses to be 0.
for var v328x v331x v334x v337x: recode X .=0 if v327==2
for var v340x v343x v346x: recode X .=0 if v340a==2

*Step 2.4: Create analytic variables for the perceived impact of each shock on 
*          the HH's food consumption that set missing values to 0 so that they  
*          can be summed in Step 2.5 (perceived_sev1-perceived_sev16). 

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

*Step 2.5: Create a variable that flags HHs that have a missing or refused response 
*          to a question included in the calculation of the SEI variable (anymiss_sei).

gen         anymiss_sei=0
	replace anymiss_sei=1 if v309x==. | (v309x==1 & v311x==.)
	replace anymiss_sei=1 if v312x==. | (v312x==1 & v314x==.)
	replace anymiss_sei=1 if v315x==. | (v315x==1 & v317x==.)
	replace anymiss_sei=1 if v318x==. | (v318x==1 & v320x==.)
	replace anymiss_sei=1 if v321x==. | (v321x==1 & v323x==.)
	replace anymiss_sei=1 if v324x==. | (v324x==1 & v326x==.)
	replace anymiss_sei=1 if v328x==. | (v328x==1 & v330x==.)
	replace anymiss_sei=1 if v331x==. | (v331x==1 & v333x==.)
	replace anymiss_sei=1 if v334x==. | (v334x==1 & v336x==.)
	replace anymiss_sei=1 if v337x==. | (v337x==1 & v339x==.)
	replace anymiss_sei=1 if v340x==. | (v340x==1 & v342x==.)
	replace anymiss_sei=1 if v343x==. | (v343x==1 & v345x==.)
	replace anymiss_sei=1 if v346x==. | (v346x==1 & v348x==.)
	replace anymiss_sei=1 if v349x==. | (v349x==1 & v351x==.)
	replace anymiss_sei=1 if v352x==. | (v352x==1 & v354x==.)
	replace anymiss_sei=1 if v355x==. | (v355x==1 & v357x==.)
	
*Step 2.6: Multiply the analytic variables indicating whether a HH experienced a 
*          shock (those created in Steps 2.2 and 2.3) by the analytic variables 
*          indicating the perceived severity of each shock experienced (those 
*          created in Step 2.4) and sum into one variable to create the weighted 
*          SEI variable (sei). Then set sei to missing if anymissing, created in 
*          the previous step, is equal to 1. The sei can range from 0 (HH 
*          experienced no shocks) to 64 (HH experienced all 16 shocks/stresses 
*          at the highest level of severity). 

gen sei= (perceived_sev1*v309x) + (perceived_sev2*v312x) + ///
         (perceived_sev3*v315x) + (perceived_sev4*v318x) + ///
         (perceived_sev5*v321x) + (perceived_sev6*v324x) + ///
         (perceived_sev7*v328x) + (perceived_sev8*v331x) + ///
         (perceived_sev9*v334x) + (perceived_sev10*v337x) + ///
         (perceived_sev11*v340x) + (perceived_sev12*v343x) + ///
         (perceived_sev13*v346x) + (perceived_sev14*v349x) + ///
         (perceived_sev15*v352x) + (perceived_sev16*v355x) 
replace sei=. if anymiss_sei==1
la var sei "Shock exposure index"

*Step 2.7: Create a variable equal to the average SEI across households (mean_sei).
egen mean_sei = mean(sei) if anymiss_sei==0
la var mean_sei "Mean SEI for surveyed HHs"

tab mean_sei

*Step 3. Calculate shock exposure-corrected ability to recover from shocks and 
*        stresses index (ARSSI)

*Step 3.1: Run a linear regression of the base ATR index on the SEI to obtain 
*          `b' (b_atr), the SEI coefficient.
reg atr sei
gen b_atr=_b[sei]  //coefficient b    
sum b_atr

*Step 3.2: Calculate the ARSSI for each HH (arssi).
gen arssi = atr + b_atr * (mean_sei-sei)
sum arssi
la var arssi "Ability-to-recover from shocks and stresses index (ARSSI)"

*Step 4: Create a variable that assigns HHs that reported not experiencing 
*        shocks into their own category and then divide the remaining HHs by 
*        their SEI values so that they comprise three roughly equal groups 
*        (terciles): low, moderate, and high shock exposure severity (shock_sev). 
*        Reassign the categories so that they have values 1-4. This variable is
*        used as a disaggregate for many indicators across the survey report.
xtile   shock_sev=sei if sei >0 & sei!=., nq(3)
replace shock_sev=0 if sei==0
tab     shock_sev
la var  shock_sev "Shock exposure severity"

recode  shock_sev 0=1 1=2 2=3 3=4
la def sei_level 1 "Did not experience any shock" 2 "Low" 3 "Moderate" 4 "High"
la val shock_sev shock_level
tab     shock_sev

* Step 5: After applying the household sampling weight, calculate the mean ARSSI 
*         using the arssi variable. Repeat using the gendered household type
*         and wealth quintile disaggregates. 
svyset hhea [pw=hh_wgt], strata(strata)
svy: mean arssi
svy: mean arssi, over(genhtype_dj)
svy: mean arssi, over(awiquint)

********************************************************************************
**#Indicator 2: INDEX OF SOCIAL CAPITAL 
********************************************************************************
** This indicator is constructed from two sub-indices: 
** (1) bonding social capital: the degree of bonding among households  
**      in their own community:v361a, v361b, v361e and v361f 
** (2) bridging social capital: the degree of bridging between households in the area 
**       to households outside their own community: v361c, v361d, v361g, v361h

*Step 1: Create the required intermediate analytic variables (v361ax, v361bx, 
*        v361cx, v361dx, v361ex, v361fx, v361gx, v361hx) in which "no" responses 
*        are recoded from 2 to 0. Also set variables v361bx, v361dx, v361fx, and 
*        v361hx to 0 if the variable is missing a value because the question was 
*        skipped because the answer to the question preceding it was no.
tab1 v361a v361e v361b v361f
for var v361a v361e v361b v361f: gen Xx=1   if X==1 
for var v361a v361e v361b v361f: replace Xx=0   if X!=1 

* If No Consent and module is blank
for var v361a v361e v361b v361f: replace Xx=.   if v300r!=1

tab1 v361c v361g v361d v361h
for var v361c v361g v361d v361h: gen Xx=1   if X==1 
for var v361c v361g v361d v361h: replace Xx=0   if X!=1 

* If No Consent and module is blank
for var v361c v361g v361d v361h: replace Xx=.   if v300r!=1

* To capture skips 
replace v361dx = 0  if v361c==2
replace v361hx = 0  if v361g==2
replace v361bx = 0  if v361a==2
replace v361fx = 0  if v361e==2

sum v361?x

** -------------------------------------------------------------------------- **
*        Bonding social capital (v361a v361b v361e v361f)
** -------------------------------------------------------------------------- **
*Step 2: Calculate bonding social capital (scap_bond).
*        Bonding social capital is a measure of whether the HH would be able to 
*        get help from or give help to people living INSIDE their community if 
*        they needed it. That is:  
*        (1) HH can lean on relatives/non-relatives living in their community (v361a, v361e)
*        (2) Same relatives/non-relatives living in their community are able to lean on them (v361b,v361f)

*Generate the bonding social capital index taking into account reciprocal 
*relationships by checking whether the HH can lean on relatives and non-relatives 
*INSIDE of their community and same relatives and non-relatives are able to lean 
*on the HH. 

gen     scap_bond=0
replace scap_bond=1           if v361ax==1 & v361bx==1 
replace scap_bond=scap_bond+1 if v361ex==1 & v361fx==1
replace scap_bond=.           if v361ax==. | v361bx==. | v361ex==. | v361fx==.
la var scap_bond "Bonding social capital (0-2)"
tab scap_bond	

** -------------------------------------------------------------------------- **
*        Bridging social capital (v361c v361d v361g v361h)
** -------------------------------------------------------------------------- **
*Step 3: Calculate bridging social capital (scap_bridge).
*        Bridging social capital is a measure of whether the HH would be able to 
*        get help from or give help to people living OUTSIDE OF their community 
*        if they needed it. That is:  
*        (1) HH can lean on relatives/non-relatives living outside their community (v361c, v361g)
*        (2) Same relatives/non-relatives living outside their community are able to lean on them (v361d,v361f)

*Generate the bridging social capital index taking into account reciprocal 
*relationships by checking whether the HH can lean on relatives and non-relatives 
*IOUTSIDE of their community and same relatives and non-relatives are able to lean 
*on the HH. 

gen     scap_bridge=0
replace scap_bridge=1             if v361cx==1 & v361dx==1
replace scap_bridge=scap_bridge+1 if v361gx==1 & v361hx==1
replace scap_bridge=.             if v361cx==. | v361dx==. | v361gx==. | v361hx==.

tab    scap_bridge
la var scap_bridge "Bridging social capital (0-2)"

** -------------------------------------------------------------------------- **
*       Index of social capital at the HH level (scap_bond, scap_bridge)
** -------------------------------------------------------------------------- **
*Step 4: Calculate index of social capital (scap_index) by averaging the bonding 
*        and bridging social capital.
gen	   	   scap_index = .
replace    scap_index = (scap_bond+scap_bridge)/2 
la var 	   scap_index "Index of social capital (0-2)"
tab        scap_index

** -------------------------------------------------------------------------- **
*Step 5: Rescale the index and the two sub-indices to be out of 100 
*        (i_scap_index, i_scap_bond, i_scap_bridge).

gen     i_scap_index=(scap_index/2)*100
la var  i_scap_index "Social capital index (rescaled 0-100)"
tab     i_scap_index

gen     i_scap_bond=(scap_bond/2)*100
la var  i_scap_bond "Bonding social capital (rescaled 0-100)"
tab     i_scap_bond

gen     i_scap_bridge=(scap_bridge/2)*100
la var  i_scap_bridge "Bridging social capital (rescaled 0-100)"
tab     i_scap_bridge

* Step 6: Calculate the sample-weighted mean index of social capital. 
*         Repeat using the gendered household type, wealth quintile, 
*         and shock exposure severity disaggregates.
svyset hhea [pweight=wgt_hh], strata(strata) 
svy: mean i_scap_index 	
svy: mean i_scap_index, over(genhhtype_dj)
svy: mean i_scap_index, over(awiquint)
svy: mean i_scap_index, over(shock_sev)

*Step 7: Repeat Step 6 for the rescaled bonding and bridging social capital sub-indices.
svy: mean i_scap_bond	
svy: mean i_scap_bond, over(genhhtype_dj)
svy: mean i_scap_bond, over(awiquint)
svy: mean i_scap_bond, over(shock_sev)

svy: mean i_scap_bridge
svy: mean i_scap_bridge, over(genhhtype_dj)
svy: mean i_scap_bridge, over(awiquint)
svy: mean i_scap_bridge, over(shock_sev)

*******************************************************************************
********************************************************************************
**#Indicator 3. HOUSEHOLDS THAT BELIEVE LOCAL GOVERNMENT WILL RESPOND EFFECTIVELY 
*        		TO FUTURE SHOCKS AND STRESSES
********************************************************************************
**The indicator measures households' in a specific geographic area's belief the
**local government will help the community cope with difficult times in the 
**future. 

**Step 1: Create the indicator variable (locgov_resp), dropping any HHs for
*         which a response is missing or with a "No, support not needed" response.
tab v362
recode v362 2=0 3/max=., gen(locgov_resp)
la val locgov_resp yesno
la var locgov_resp "HH believes local govt will help the community cope with future difficult times and shocks or stresses."
tab locgov_resp,m

tab locgov_resp

*Step 2: After applying the HH sampling weight, calculate the percentage 
*        of HHs that believe local government will respond effectively to future 
*        shocks and stresses using locgov_resp. Repeat using the gendered 
*        household type, wealth quintile, and shock severity exposure
*        disaggregates. 
svy: tab locgov_resp	
svy: tab locgov_resp genhhtype_dj, col perc format(%6.1f)
svy: tab locgov_resp awiquint, col perc format(%6.1f)
svy: tab locgov_resp shock_sev, col perc format(%6.1f)

********************************************************************************
**#Indicator 4. ACCESS TO MICROFINANCE
**              Percent of HHs participating in group-based savings, 
**              micro-finance or lending programs
********************************************************************************
**
** Two ways to calculate ACCESS to MICROFINANCE are presented depending on 
**   the ZOI survey focus and time - Baseline or Midline
**
** -------------------------------------------------------------------------- **
*Approach 1: Using data from only primary female adult decision-makers collected in Module 6 (for comparative analyses)

*Create a binary variable that indicates whether primary female adult decision-makers (PAFDMs) who completed Module 6 reported that at least one person from their HH participated in a group-based savings, micro-finance, or lending program in the 12 months preceding the survey (access_finance1). The variable indicates whether anyone in the HH took a loan from a group-based micro-finance or lending program (v6308_5) or from an informal credit or savings group (v6308_6) or whether the PAFDM in the HH is an active member of a savings, credit, or micro-finance group (v6405_05).
gen     access_finance1=.
*Include participants who completed Module 6
replace access_finance1=0 if v600r==1
*Set variable to 1 (yes) if PAFDM reports someone in their HH borrowed cash or in-kind from group-based microfinance 
replace access_finance1=1 if v6308_5<=3  
*Set variable to 1 (yes) if PAFDM reports someone in their HH borrowed cash or in-kind from informal credit/savings groups
replace access_finance1=1 if v6308_6<=3 
*Set variable to 1 (yes) if the PAFDM is an active member of a credit/microfinance group
replace access_finance1=1 if v6405_05==1 

la var access_finance1 "PAFDM responded that HH participated in group-based savings, microfinance, or lending"
la val access_finance1 YESNO
tab access_finance1

*Step 2. Apply the household sampling weight and calculate the percentage of households that participated in a group-based savings, micro-finance, or lending program in the 12 months preceding the survey using access_finance1. Repeat using the gendered household type, wealth index, and shock exposure severity disaggregates.
svyset hhea [pweight=wgt_hh], strata(strata)
svy: tab access_finance1	
svy: tab access_finance1 genhhtype_dj, col
svy: tab access_finance1 awiquint, col
svy: tab access_finance1 shock_sev, col


**--------------------------------------------------------------------------- **
*Approach 2: Using data collected in Module 3, which is available only in surveys with fieldwork in or after 2022 (for descriptive analyses at one point in time)

*Step 1. Create a binary variable that indicates whether respondents to Module 3 reported that at least one person from their household participated in a group-based savings, micro-finance, or lending program in the 12 months preceding the survey (access_finance2). The variable indicates whether anyone in the household took a loan from a group-based micro-finance or lending program (v364) or from an informal credit or savings group (v365) or whether a primary adult decision-maker in the household is an active member of a savings, credit, or micro-finance group (v366, v367).
gen     access_finance2=.
*Include participants who completed Module 3
replace access_finance2=0 if v300r==1
*Set variable to 1 (yes) if someone in the HH borrowed cash or in-kind from group-based microfinance 
replace access_finance2=1 if v364 <=3  
*Set variable to 1 (yes) if someone in the HH borrowed cash or in-kind from informal credit/savings groups
replace access_finance3=1 if v365 <=3    
*Set variable to 1 (yes) if anyone in HH is an active member of a credit/microfinance group
replace access_finance3=1 if v367==1 & v366==1

la var access_finance3 "HH participated in group-based savings, microfinance, or lending"
la val access_finance3 yesno
tab access_finance3

*Step 2. After applying the household sampling weight, calculate the percentage of households that participated in a group-based savings, micro-finance, or lending program in the 12 months preceding the survey using access_finance2. Repeat using the gendered household type, wealth quintile, and shock exposure severity disaggregates.
svyset hhea [pweight=wgt_hh], strata(strata)
svy: tab access_finance2	
svy: tab access_finance2 genhhtype_dj, col
svy: tab access_finance2 awiquint, col
svy: tab access_finance2 shock_sev, col


keep hhea hhnum wgt_hh strata atr perceived_sev* sei anymiss_sei arssi b_atr shock_sev access_finance* locgov_resp *scap*

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] resilience.dta", replace 

di "Date:$S_DATE $S_TIME"
log close

