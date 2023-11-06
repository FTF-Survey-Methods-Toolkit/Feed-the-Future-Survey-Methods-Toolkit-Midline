/*******************************************************************************
*************************** FEED THE FUTURE ZOI SURVEY *************************
********************** HOUSEHOLD WEALTH INDEX - COMPARATIVE ********************
***************************** [COUNTRY, YEAR] **********************************
********************************************************************************
Description: This code is intended to construct the Feed the Future COMPARATIVE 
WEALTH INDEX indicator:
1.	Calculate UBN variables and scores 
2.	Calculate UBN cutpoint values
3.	Add baseline UBN cutpoint values
4.	Reshape and save UBN cutpoint values data
5.	Calculate asset cutpoint values
6.	Add baseline asset cutpoint values
7.	Reshape and save ASSET cutpoint values data
8.	Append UBN and ASSET cutpoint values data
9.	Regress compared cutpoints on baseline cutpoints
10.	Drop redundant observations and variables and with household data
11.	Calculate comparative wealth index (CWI)
12.	Flag HHs below the comparative threshold for the poorest quintile of the 
    asset-based CWI (i.e., the baseline survey cut point for poorest quintile)
13.	Save data

Author(s): 	Nizam Khan, @ICF 
			Kirsten Zalisk, @ICF
Date updated: Aug 21, 2018
Reviewed and updated by: Kirsten Zalisk @ICF
Review date: August 2019

This syntax file was developed using the core Feed the Future ZOI Survey phase one 
endline/phase two baseline core questionnaire. It must be adapted for the final  
country-specific questionnaire. The syntax could only be partially tested using 
ZOI Survey data; therefore, double-check all results carefully and troubleshoot 
to resolve any issues identified. 
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
**1a. Load AWI data created previously
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex AWI.dta",clear

**1b. Calculate UBN1: Inadequate dwelling construction - dirt floors or natural/rustic walls
tab1 v202 v203,m

gen     ubn1=0
*5/27/2020: Moved the second part of if statement onto same line because "///" was missing
replace ubn1=1 if inlist(v202,11,12,13,96) | inlist(v203,11,12,13,14,15,96)  
la var  ubn1 "Inadequate dwelling construction"
la val  ubn1 YESNO
tab     ubn1

**1c. Calculate UBN2: Inadequate sanitation or drinking water source
*INSTRUCTION: Double-check that water sources below are considered inadequate in
*             the ZOI Survey country.
tab v208

gen     ubn2=0
*5/27/2020: Put all syntax on one line, change v209=1 to double equal sign
replace ubn2=1 if inlist(v208,23,41,51,61,96) | v209==1 | inlist(v211,32,42,51,61,71,81,96)       
la val  ubn2 YESNO
la var  ubn2 "Inadequate sanitation (toilet facility or water source)"
tab     ubn2

**1d. Calculate UBN3: Household crowding - 4+ persons per room
tab1 hhsize_dj memsleep_dj memsleep 

*5/27/2020: Updated memsleep_dj variable to be the truncated version generated in 
*           the AWI do file (memsleep), per DHS protocol
gen     ubn3=0
replace ubn3=1 if memsleep>3 
la var  ubn3 "Household crowding: 4+ de jure HH members per sleeping room"
la val  ubn3 YESNO
tab     ubn3
tab1 v204  hhsize

*Step 2. Create the fourth UBN variable that indicates high economic dependency 
*using person-level data. 

**2a. Save the current data in a temporary file and load the persons-level 
*analytic data file to create the final UBN variable.
save "$analytic\Temp\temp_ubn_hh.dta", replace
use  "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta",clear

**2b. Create a variable to flag de jure working-age adults in the household (wadult).
gen wadult_dj=inrange(age,15,64) if hhmem_dj==1
la var wadult_dj "Working-age adult, de jure HH member"
la val wadult_dj YESNO
tab wadult_dj

**2c. Create a variable to flag working-age adults who did not complete primary education 
***INSTRUCTION: Ensure code takes into account the education levels and grades 
***in the country questionnaire.
gen wadult_noprim=0 if wadult_dj==1
replace wadult_noprim=1 if edu_prim==0 & wadult_dj==1
la var wadult_noprim "Working-age adult who didn't complete primary school, de jure HH member"
la val wadult_noprim YESNO
tab wadult_noprim

**2d. Create a variable to flag working-age adults who were attending school at 
*the time of the survey (wadult_att).
gen wadult_att=0 if wadult_dj==1
replace wadult_att=1 if v110==1 & wadult_dj==1
la var wadult_att "Working-age adult attending school at time of survey, de jure HH member"
la val wadult_att YESNO
tab wadult_att

**2e. Create household-level variables from the persons-level data.
collapse (sum) wadult_dj wadult_nopri wadult_att (max) edu_prim_pdm_dj, by(hhea hhnum)

la var wadult_dj       "Number of working-age adults in HH"
la var wadult_noprim   "Number of working-age adults in HH who didn't complete primary school"
la var wadult_att      "Number of working-age adults attending school at time of survey"
la var edu_prim_pdm_dj "De jure primary adult decisionmaker (male or female) completed primary school"

**2f. Create the fourth UBN variable (ubn4).
/*UBN=4 if (a) there is no working-age adult that have completed primary education 
among the household members; or (b) the only working-age adult in the household 
is still in school; or (c) there are no working-age adults in the household and 
a primary adult decisionmaker has not completed primary education.*/		
gen ubn4=0
replace ubn4=1 if wadult_dj>0 & wadult_dj!=. & wadult_dj==wadult_nopri
replace ubn4=1 if wadult_dj>0 & wadult_dj!=. & wadult_dj==wadult_att 
replace ubn4=1 if wadult_dj==0 & edu_prim_pdm_dj!=1
la var ubn4 "High economic dependency"
la val ubn4 YESNO
tab ubn4

*5/27/2020: Updated hhid to be hhea and hhnum
*keep hhid  ubn4 
keep hhea hhnum ubn4

**2g. Merge ubn4 into the temp_ubn_hh data file
merge 1:1 hhea hhnum using "$analytic\Temp\temp_ubn_hh.dta"
drop _merge

**2h. Calculate UBN score and save data 
egen ubn=rsum(ubn1 ubn2 ubn3 ubn4)
sum  ubn
save temp_ubn,replace

//Step 3: Calculate of UBN cutpoint values 
**3a. Create a new dataset that includes 5 observations (0–4) and four variables 
*(Frequency, Cumulative Frequency, Percentage, Cumulative Percentage)
gen a=1
contract ubn a, freq(freq) cfreq(cumfreq) percent(percent) cpercent(cumpercent)
list, noobs

**3b. Create four percentile variables (ptile1, ptile2, ptile3, and ptile4) where
*HHs in ptile1 have 1+ unmet basic need; HHs in ptile2 have 2+ unmet basic needs;
*HHs in ptile3 have 3+ unmet basic needs; and HHs in ptile4 have all 4 unmet basic needs
gen     ptile1=0
replace ptile1=(100-cumpercent) if ubn==0

gen     ptile2=0
replace ptile2=(100-cumpercent) if ubn==1

gen     ptile3=0
replace ptile3=(100-cumpercent) if ubn==2

gen     ptile4=0
replace ptile4=(100-cumpercent) if ubn==3

**3c. Add all “ptile” and "freq" variables to “temp_ubn” data and save the file.
collapse (sum) ptile? freq
list, noobs

gen  null=1
save "$analytic\Temp\temp_cwi_ptile.dta", replace

**3d. Add the AWI variable (awi) from the "Mali ZOI Survey 2019 wealthindex awi.dta” data file 
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex awi.dta",clear
*5/27/2020: Next line commented out because a null variables was created in the AWI do file.
*gen null=1
merge m:1 null using "$analytic\Temp\temp_cwi_ptile.dta"
drop null _merge

sort awi

**3e. Create a variable to indicate cumulative HH sampling weight for all HHs. 
gen     sumwts=0
replace sumwts=sampwt if _n==1
replace sumwts=sumwts[_n-1]+sampwt if _n>1

**3f. Create UBN cutpoint values for each household.
*02/05/2020: Step updated to divide by the weighted total number of HHs rather than the unweighted
*number of households. (Note that if the weights were calculated such that the unweighted and 
*and weighted number of households is the same, this update will not affect the calculations.)
egen tot_wgt=total(hh_wgt)
gen cut4=awi if (ptile4/100) <= (sumwts/tot_wgt)
gen cut3=awi if (ptile3/100) <= (sumwts/tot_wgt)
gen cut2=awi if (ptile2/100) <= (sumwts/tot_wgt)
gen cut1=awi if (ptile1/100) <= (sumwts/tot_wgt)

*gen cut4=awi if (ptile4/100)<=(sumwts/freq)
*gen cut3=awi if (ptile3/100)<=(sumwts/freq)
*gen cut2=awi if (ptile2/100)<=(sumwts/freq)
*gen cut1=awi if (ptile1/100)<=(sumwts/freq)

**3g. Create UBN cutpoints by determining the minimum value of each of the 4 HH- 
*level UBN cutpoint values.
egen compcut4=min(cut4)
egen compcut3=min(cut3)
egen compcut2=min(cut2)
egen compcut1=min(cut1)
sum  compcut*

**3h. Drop all observations except the 1st and drop all variables except compcut*. 
keep if _n==1
keep compcut* 

//Step 4: Create the four basecut variables for the reference survey UBN anchoring points.
*02/05/2020: The update to Step 3f affects the UBN anchoring points obtained for the 
*reference survey, which have been updated here.
gen basecut1=1.284437
gen basecut2=0.6740997
gen basecut3=(-0.6691726)
gen basecut4=(-1.329942)

*gen basecut1=1.221723
*gen basecut2=0.5201281
*gen basecut3=(-0.8875138)
*gen basecut4=(-1.362395)

//Step 5: Reshape and save UBN cutpoint value data
gen id=1
reshape long compcut basecut,i(id) j(num)  
gsort -num
list, noobs

la var basecut "UBN cutpoint values-baseline survey"
la var compcut "UBN cutpoint values-ZOI Survey"

save "$analytic\Temp\temp_UBNcutpoint.dta",replace

//Step 6: Calculate asset cutpoint values 

**6a. Load AWI data file, identify and define asset vars
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex awi.dta",clear

**6b. Create binary variables for the 4 asset items to be used as anchoring points 
des  v222c v222e v222f v223f
sum  v222c v222e v222f v223f
tab1 v222c v222e v222f v223f 

gen  tv=       v222c==1
gen  computer= v222e==1 
gen  fridge=   v222f==1
gen  car=      v223f==1
sum  tv-car

**6c. Run logistic regression of each asset variable on awi using the sampling
**    weight and calculate asset cutpoint values for each asset
*5/27/2020: Updated svyset command for consistency across do files. 
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_hh], strata(samp_stratum)
svydescribe car fridge computer tv

*foreach var of varlist tv phone computer car {
*2/7/2020: Updated next line to replace phone with fridge
foreach var of varlist tv fridge computer car {
*foreach var of varlist tv phone computer car {
    svy:logit `var' awi
    matrix list e(b)
    gen    compcut_`var'=-_b[_cons]/_b[awi]
	}
sum compcut_*
rename compcut_tv       compcut1
*2/7/2020: Updated next 2 lines to switch the assignments of computer and fridge
rename compcut_fridge   compcut2
rename compcut_computer compcut3
*rename compcut_computer compcut2
*rename compcut_fridge   compcut3
rename compcut_car      compcut4

**6d. Keep relevant observation and vars
keep if _n==1
list compcut*
keep compcut*

//Step 7: Add asset cutpoint values of Baseline data
gen basecut1=0.1166113
gen basecut2=1.107843
gen basecut3=1.591285
gen basecut4=6.366876

//Step 8. Reshape and save the asset cutpoint value data. 
gen id=1
*5/27/2020: removed underscore from compcut and basecut
reshape long compcut basecut,i(id) j(num2) string
gsort -num
list, noobs

save "$analytic\Temp\temp_ASSETcutpoint.dta",replace

//Step 9: Append UBNcutpoint and ASSETcutpoint data
append using "$analytic\Temp\temp_UBNcutpoint.dta"
list,  noobs

//Step 10: Regress compared cutpoints on basline cutpoints
*02/05/2020: The reference survey variables should be the dependent variables, 
*and the current survey variables should be the independent variables; this had
*been reversed
reg basecut compcut
*reg compcut basecut
matrix list e(b)

gen coeff=_b[compcut]
*gen coeff=_b[basecut]
gen const=_b[_cons]

//Step 11: Drop redundant obs and vars, save temp data and merge with master data
keep if _n==1
keep const coeff
gen null=1
save "$analytic\Temp\temp_regress_result.dta",replace

use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex awi.dta", clear
merge m:1 null using "$analytic\Temp\temp_regress_result.dta"
drop _merge

//Step 12: Calculate comparative wealth index
*5/27/2020: Added a 2nd replace statement so that a CWI score is only generated for HHs with an AWI score.
gen     cwi=0 
replace cwi=const+(coeff*awi)
replace cwi=. if awi==.
sum     cwi
la var  cwi "Comparative Wealth Index (CWI)"

//Step 13: Using the value of the comparative threshold for the poorest 
* quintile of the asset-based CWI, create a variable that flags HHs in the ZOI 
* Survey sample that fall below it.
*5/27/2020: Added if statement to include only HHs with a valid cwi score, and 
*          updated windex_cwi variable in replace statement to be cwi, and updated 
*          cutoff to be based on HH-weights rather than HH member weights
gen comp_poor=0 if cwi!=.
replace comp_poor=1 if cwi<-0.86276845
la var comp_poor “HH below the comparative threshold for the poorest quintile of the asset-based CWI”

//Step 14: Calculate the sample weighted-indicator
*5/27/2020: Updated svyset command for consistency across do files. 
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_hh], strata(samp_stratum)
svy: tab comp_poor
svy: tab awiquint

//Step 15: Assign all surveyed households to a CWI quintile.
*5/27/2020:Updated cutoffs to be based on HH-weights rather than HH member weights
gen cwiquint=.
replace cwiquint=1 if cwi<-0.86276845 & cwiquint==.
replace cwiquint=2 if cwi<0.00108905 & cwiquint==.
replace cwiquint=3 if cwi<0.80370025 & cwiquint==.
replace cwiquint=4 if cwi<1.2871975 & cwiquint==.
*5/27/2020: Added "& cwi!=." to if statement
replace cwiquint=5 if cwi>=1.2871975 & cwi!=. & cwiquint==.
tab cwiquint

//Step 16: Keep only the variables that will be added to the final post-analysis
* data file and save the data 
keep hhea hhnum cwi* awi* comp_poor

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] wealthindex CWI.dta", replace

erase "$analytic\Temp\temp_ubn_hh.dta""
erase "$analytic\Temp\temp_ubn.dta"
erase "$analytic\Temp\temp_cwi_ptile.dta"
erase "$analytic\Temp\temp_UBNcutpoint.dta"
erase "$analytic\Temp\temp_ASSETcutpoint.dta"
erase "$analytic\Temp\temp_regress_result.dta"

//Close the log file
di "Date:$S_DATE $S_TIME"
log close
