/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
************************** COMPARATIVE WEALTH INDEX ****************************
***************************** [COUNTRY] [YEAR] *********************************
********************************************************************************
Description: This code is intended to construct the Feed the Future COMPARATIVE 
WEALTH INDEX indicator using the following steps:
1.	Create the first three UBN variables using HH-level data. 
2.	Create the fourth UBN variable using individual-level data. 
3.	Calculate the UBN cutpoint values.
4.  Create variables for the UBN cutpoint values for the reference survey. 
5.	Reshape and save UBN cutpoint values data.
6.	Calculate asset cutpoint values.
7.	Create variables for the asset cutpoint values for the reference survey. 
8.	Reshape and save ASSET cutpoint values data.
9.	Append UBN and ASSET cutpoint values data.
10.	Regress calculated cutpoints on reference survey cutpoints.
11.	Drop redundant observations and variables and with HH data.
12.	Calculate comparative wealth index (CWI).
13.	Create a variable to flag HHs below the threshold for the poorest quintile of
    the CWI (i.e., the reference survey cutpoint for poorest quintile).
14.	Calculated the sample-weighted indicator
15.Create a variable that assigns all surveyed households to a CWI quintile (cwiquint).

Syntax prepared by ICF, August 2018
Revised by ICF, August 2019, September 2023

The numbering of the steps in this syntax file aligns with the numbering of the 
step-by-step guidance in Section 11.2 Part 2 in the Guide to Feed the Future 
Midline Statistics.

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. Be sure to adjust it as needed to align with the 
country-customized questionnaire.
*******************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input(s):    $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.dta
//Log Outputs: $analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex CWI.log
//Output data: $analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex CWI.dta
//Syntax: 	   $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax CWI.do 

capture log close
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex CWI.log", replace

********************************************************************************
*STEP 1: Calculate UBN variables and scores
*Step 1.1: Load AWI data created previously
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.dta",clear

*Step 1.2: Calculate UBN1: Inadequate dwelling construction-dirt floors or natural/rustic walls
tab1 v202 v203,m

gen     ubn1=0
replace ubn1=1 if inlist(v202,11,12,13,96) | inlist(v203,11,12,13,14,15,96)  
la var  ubn1 "Inadequate dwelling construction (floors/walls)"
la val  ubn1 YESNO
tab     ubn1

*Step 1.3: Calculate UBN2: Inadequate sanitation or drinking water source
*INSTRUCTION: Double-check that water sources below are considered inadequate in
*             the ZOI Survey country.
*2/6/2023: Added Flush to Somewhere else (14) to unimproved [Note: Flush to DK is improved according to JMP]
*          Removed Rainwater (51), Tanker truck (61), and Cart w/small tank (71) from unimproved
tab v208

gen     ubn2=0
replace ubn2=1 if inlist(v208,14,23,41,51,61,96) | v209==1 | inlist(v211,32,42,81,96)       
la val  ubn2 YESNO
la var  ubn2 "Inadequate sanitation (toilet/drinking water)"
tab     ubn2

*Step 1.4: Calculate UBN3: Household crowding - 4+ persons per room
tab1 hhsize_dj memsleep_dj memsleep 

gen     ubn3=0
replace ubn3=1 if memsleep>3 & memsleep!=.
la var  ubn3 "Household crowding: >3 de jure HH members/sleeping room"
la val  ubn3 YESNO
tab     ubn3
tab1 v204  hhsize

*Step 2: Create the fourth UBN variable that indicates high economic dependency 
*using person-level data. 

*Step 2.1: Save the current data in a temporary file and load the persons-level 
*          analytic data file to create the final UBN variable.
save "$analytic\Temp\temp_ubn_hh.dta", replace
use  "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta",clear

*Step 2.2: Create a variable to flag de jure working-age adults in the household (wadult_dj).
gen wadult_dj=inrange(age,15,64) if hhmem_dj==1
la var wadult_dj "Working-age adult (15-64), de jure HH member"
la val wadult_dj YESNO
tab wadult_dj

*Step 2.3: Create a variable to flag working-age adults who did not complete 
*          primary education, but first create a variable that that capture 
*          whether HH members completed primary education. Be sure to adapt the 
*          syntax to appropriately account for primary education in the country.
***INSTRUCTION: Ensure syntax takes into account the education levels and grades 
***in the survey-customized questionnaire; [A], [X], [B], and [Y] are placeholders.
tab v111a v111b
gen edu_prim_dj=0 if v111a!=. & hhmem_dj==1
replace edu_prim_dj=1 if v111a>=[A] & v111a<=[X] & v111b>=[B] & v111b<=[Y] & hhmem_dj==1
tab edu_prim_dj
la val edu_prim_dj YESNO
la var edu_prim_dj "HH member completed primary education"

gen wadult_noprim_dj=0 if wadult_dj==1
replace wadult_noprim_dj=1 if edu_prim_dj==0 & wadult_dj==1
la var wadult_noprim_dj "Working-age adult didn't complete primary school, de jure HH member"
la val wadult_noprim_dj YESNO
tab wadult_noprim_dj

*Step 2.4: Create a variable to flag working-age adults who were attending school 
*          at the time of the survey (wadult_att_dj).
gen wadult_att_dj=0 if wadult_dj==1
replace wadult_att_dj=1 if v110==1 & wadult_dj==1
la var wadult_att_dj "Working-age adult attending school at time of survey, de jure HH member"
la val wadult_att_dj YESNO
tab wadult_att_dj

*Step 2.5: Create a variable to flag whether a primary adult decisionmaker in 
*          the HH completed primary school (edu_prim_pdm_dj).
gen edu_prim_pdm_dj=0
replace edu_prim_pdm_dj=1 if (edu_prim_dj==1 and fdm_dj==1) | (edu_prim_dj==1 and mdm_dj==1)
la val YESNO
la var "Primary adult decision-maker in HH completed primary school"

*Step 2.6: Create HH-level variables from the persons-level data.
collapse (sum) wadult_dj wadult_noprim_dj wadult_att_dj (max) edu_prim_pdm_dj, by(hhea hhnum)

la var wadult_dj       		"Number of working-age adults in HH"
la var wadult_noprim_dj   	"Number of working-age adults in HH who didn't complete primary school"
la var wadult_att_dj      	"Number of working-age adults attending school at time of survey"
la var edu_prim_pdm_dj 		"De jure primary adult decisionmaker (male or female) completed primary school"

*Step 2.7: Create the fourth UBN variable (ubn4).
*          UBN4=1 if (a) there is no working-age adult that have completed primary 
*          education among the HH members; or (b) the only working-age adults in 
*          the HH are still in school; or (c) there are no working-age adults in 
*          the HH and a primary adult decisionmaker has not completed primary education.
gen ubn4=0
replace ubn4=1 if wadult_dj>0 & wadult_dj!=. & wadult_dj==wadult_noprim_dj
replace ubn4=1 if wadult_dj>0 & wadult_dj!=. & wadult_dj==wadult_att_dj 
replace ubn4=1 if wadult_dj==0 & edu_prim_pdm_dj!=1
la var ubn4 "High economic dependency"
la val ubn4 YESNO
tab ubn4

keep hhea hhnum ubn4

*Step 2.8: Merge ubn4 into the temp_ubn_hh data file
merge 1:1 hhea hhnum using "$analytic\Temp\temp_ubn_hh.dta"
drop _merge

*Step 2.9: Calculate UBN score and save data 
egen ubn=rsum(ubn1 ubn2 ubn3 ubn4)
la var ubn "Unmet basic needs score (0-4)"
sum  ubn
save temp_ubn,replace

*Step 3: Calculate of UBN cutpoint values 

*Step 3.1:. Create a new dataset that includes 5 observations (0–4) and four 
*           variables (Frequency, Cumulative Frequency, Percentage, Cumulative 
*           Percentage)
contract ubn, freq(freq) cfreq(cumfreq) percent(percent) cpercent(cumpercent)
list, noobs

*Step 3.2: Create four percentile variables (ptile1, ptile2, ptile3, and ptile4) 
*          where HHs in ptile1 have 1+ unmet basic need; HHs in ptile2 have 2+ 
*          unmet basic needs; HHs in ptile3 have 3+ unmet basic needs; and HHs 
*          in ptile4 have all 4 unmet basic needs.
gen     ptile1=0
replace ptile1=(100-cumpercent) if ubn==0
la var  ptile1 "% of HHs with 1+ UBNs, constant"

gen     ptile2=0
replace ptile2=(100-cumpercent) if ubn==1
la var  ptile2 "% of HHs with 2+ UBNs, constant"

gen     ptile3=0
replace ptile3=(100-cumpercent) if ubn==2
la var  ptile3 "% of HHs with 3+ UBNs, constant"

gen     ptile4=0
replace ptile4=(100-cumpercent) if ubn==3
la var  ptile4 "% of HHs with 4 UBNs, constant"

*Step 3.3: Add all “ptile” and "freq" variables to “temp_ubn” data and save the file.
collapse (sum) ptile? freq
list, noobs

gen  null=1
save "$analytic\Temp\temp_cwi_ptile.dta", replace

*Step 3.4: Add the AWI variable (awi) from the wealthindex awi data file.
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex awi.dta",clear
merge m:1 null using "$analytic\Temp\temp_cwi_ptile.dta"
drop null _merge

sort awi

*Step 3.5: Create a variable to indicate cumulative HH sampling weight for all HHs. 
gen     sumwts=0
replace sumwts=sampwt if _n==1
replace sumwts=sumwts[_n-1]+sampwt if _n>1
la var sumwts "Cumulative HH sampling weight when HHs are sorted by awi score"

egen tot_wgt=total(hh_wgt)
la var tot_wgt "Sum of HH sampling weights, constant"

*Step 3.6: Create UBN cutpoint values for each HH.
gen cut4=awi if (ptile4/100) <= (sumwts/tot_wgt)
gen cut3=awi if (ptile3/100) <= (sumwts/tot_wgt)
gen cut2=awi if (ptile2/100) <= (sumwts/tot_wgt)
gen cut1=awi if (ptile1/100) <= (sumwts/tot_wgt)

*Step 3.7: Create UBN cutpoints by determining the minimum value of each of the 
*          four HH-level UBN cutpoint values.
egen compcut4=min(cut4)
egen compcut3=min(cut3)
egen compcut2=min(cut2)
egen compcut1=min(cut1)
sum  compcut*

*Step 3.8: Drop all observations except the 1st and drop all variables except compcut*. 
keep if _n==1
keep compcut* 

*Step 4: Create the four basecut variables for the reference survey UBN anchoring points. 

*NOTE: that the values of these variables were determined previously and are included in the template syntax file. They will be used in the CWI indicator calculation across all ZOI Surveys.)

gen 	basecut1=1.261171
gen 	basecut2=0.6508898
gen 	basecut3=(-0.6808249)
gen 	basecut4=(-1.330052)

*Step 5: Reshape and save UBN cutpoint value data
gen id=1
reshape long compcut basecut,i(id) j(num)  
gsort -num
list, noobs

la var basecut "UBN cutpoint values for the reference survey"
la var compcut "UBN cutpoint values for the ZOI survey"

save "$analytic\Temp\temp_UBNcutpoint.dta",replace

*Step 6: Calculate asset cutpoint values 

*Step 6.1: Load AWI data file, identify and define asset vars
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex awi.dta",clear

*Step 6.2: Create binary variables for the 4 asset items to be used as anchoring points 
des  v222c v222e v222f v223f
sum  v222c v222e v222f v223f
tab1 v222c v222e v222f v223f 

gen  tv=       v222c==1
gen  computer= v222e==1 
gen  fridge=   v222f==1
gen  car=      v223f==1
la var tv "HH has a tv"
la var fridge "HH has a refridgerator"
la var computer "HH has a computer"
la var car "HH has a car or truck"
sum  tv-car

*Step 6.3: Run logistic regression of each asset variable on awi using the HH 
*          sampling weights and calculate asset cutpoint values for each asset
svyset hhea [pw=wgt_hh], strata(strata)
svydescribe car fridge computer tv

foreach var of varlist tv fridge computer car {
  svy:logit `var' awi
  matrix list e(b)
  gen    compcut_`var'=-_b[_cons]/_b[awi]
}

sum compcut_*
rename compcut_tv       compcut1
rename compcut_fridge   compcut2
rename compcut_computer compcut3
rename compcut_car      compcut4

la var "Asset anchoring point: TV"
la var "Asset anchoring point: Refrigerator"
la var "Asset anchoring point: Computer"
la var "Asset anchoring point: Car/truck"

*Step 6.4: Keep relevant observation and vars
keep if _n==1
list compcut*
keep compcut*

*Step 7: Add asset cutpoint values of Baseline data (The values for these variables were calculated previously and included in the syntax file. They will be used in the CWI indicator calculation across all ZOI Surveys.) 
gen 	basecut1=0.1166113 	// [television]
gen 	basecut2=1.107843 	// [fridge]
gen 	basecut3=1.591285 	// [computer]
gen 	basecut4=2.05812 	// [car]

*Step 8. Reshape and save the asset cutpoint value data. 
gen id=1
reshape long compcut basecut,i(id) j(num2) string
gsort -num
list, noobs

save "$analytic\Temp\temp_ASSETcutpoint.dta",replace

*Step 9: Append UBNcutpoint and ASSETcutpoint data
append using "$analytic\Temp\temp_UBNcutpoint.dta"
list,  noobs

*Step 10: Regress compared cutpoints on basline cutpoints
reg basecut compcut
matrix list e(b)

gen coeff=_b[compcut]
gen const=_b[_cons]

*Step 11: Drop redundant obs and vars, save temp data and merge with master data
keep if _n==1
keep const coeff
gen null=1
save "$analytic\Temp\temp_regress_result.dta",replace

use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex awi.dta", clear
merge m:1 null using "$analytic\Temp\temp_regress_result.dta"
drop _merge

*Step 12: Calculate comparative wealth index
gen     cwi=0 
replace cwi=const+(coeff*awi)
replace cwi=. if awi==.
la var  cwi "Comparative Wealth Index (CWI) score"
sum     cwi

*Step 13: Using the value of the comparative threshold for the poorest 
*         quintile of the asset-based CWI, create a variable that flags HHs in 
*         the ZOI Survey sample that fall below it.
gen 	comp_poor=0 if cwi!=.
replace comp_poor=1 if cwi<-0.83574
la var  comp_poor “HH is in poorest CWI quintile”

*Step 14: Calculate the sample weighted-indicator. Repeat using the gendered household type and shock exposure severity disaggregate variables. 
svyset hhea [pw=wgt_hh], strata(strata)
svy: tab comp_poor
svy: tab comp_poor genhhtype_dj, col
svy: tab comp_poor shock_sev, col

*Step 15: Assign all surveyed households to a CWI quintile.
gen 	cwiquint=.
replace cwiquint=1 if cwi<-0.83574 & cwiquint==.
replace cwiquint=2 if cwi<-0.553915 & cwiquint==.
replace cwiquint=3 if cwi<-0.044190 & cwiquint==.
replace cwiquint=4 if cwi<0.864125 & cwiquint==.
replace cwiquint=5 if cwi>=0.864125 & cwi!=. & cwiquint==.
la var 	cwiquint "HH's CWI quintile"
tab 	cwiquint

*Step 16: Keep only the variables that will be added to the final post-analysis
*         data file and save the data 
keep hhea hhnum cwi* awi* comp_poor wgt_hh wgt_hhmember strata

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex CWI.dta", replace

erase "$analytic\Temp\temp_ubn_hh.dta""
erase "$analytic\Temp\temp_ubn.dta"
erase "$analytic\Temp\temp_cwi_ptile.dta"
erase "$analytic\Temp\temp_UBNcutpoint.dta"
erase "$analytic\Temp\temp_ASSETcutpoint.dta"
erase "$analytic\Temp\temp_regress_result.dta"

di "Date:$S_DATE $S_TIME"
log close
