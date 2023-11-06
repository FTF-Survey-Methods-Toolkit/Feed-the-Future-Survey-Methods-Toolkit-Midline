/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
*******************  WATER, SANITATION, HYGIENE INDICATORS *********************
****************************** [COUNTRY] [YEAR]*********************************
********************************************************************************
Description: In this do file, household and dwelling characteristic and water, 
sanitation, and hygenie variables are created. 

The file is divided into two sections:
1. Household and dwelling characteristic indicators (Guide to Midline Statistics Chapter 9)
2. Water, sanitation, and hygiene (Guide to Midline Statistics Chapter 8)

Syntax prepared by ICF, April 2023
Revised by ICF, September 2023

The numbering of the sections and variables in this syntax file align with 
Chapters 8 and 9 in Feed the Future Midline Statistics.

This syntax file was developed using the Feed the Future phase two ZOI Midline 
main survey core questionnaire. It must be adapted for the final country- 
customized questionnaire. 
*******************************************************************************/
clear all
set more off
set maxvar 30000

//DIRECTORY PATH
*Analysis note: Adjust paths to map to the analyst's computer
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global source    "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Raw"      
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:   $source\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta 
//Log Outputs:	$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] WASH dwelling.log	
//Output data:	$analytic\FTF ZOI Survey [COUNTRY] [YEAR] WASH dwelling.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax WASH dwelling.do 

*Start a log file
capture log close
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] WASH dwelling.log", replace

*Load the household analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear

*Set up the sampling design and household weight
svyset hhea [pw=wgt_hh], strata(strata) 

********************************************************************************
**#WATER, SANITATION, AND HYGIENE (Guide to Midline Statistics Chapter 8)
********************************************************************************

********************************************************************************
***** 8.1. Improved water source that is regularly available

*Step 1: Create a binary variable to flag HHs that reported use of an improved 
*        water source as their main source of drinking water (h2o_improved). 
tab v211 
gen 	h2o_improved=0
replace h2o_improved=1 if inlist(v211,11,12,13,14,21,31,41,51,61,71,91) 
la val 	h2o_improved YESNO 
la var 	h2o_improved "HH uses an improved drinking water source"
tab h2o_improved 

*Step 2: Create a binary variable to flag HHs that reported that their main 
*        source of drinking water was regularly available (h2o_regular)—that is, 
*        it was available year-round and was available every day during the 2 
*        weeks preceding the survey.
tab1 v214 v215
gen 	h2o_regular=.
replace h2o_regular=0 if v214!=. & v215!=.
replace h2o_regular=1 if v214==1 & v215==1 
la val 	h2o_regular YESNO
la var 	h2o_regular "HH uses a regularly available drinking water source"
tab h2o_regular 
 
*Step 3: Create a final binary variable that indicates whether the HHs' main 
*        source of drinking water was improved and regularly available (h2_imp_reg).
gen 	h2o_imp_reg=.
replace h2o_imp_reg=0 if h2o_improved!=. | h2o_regular!=. 
replace h2o_imp_reg=1 if h2o_improved==1 & h2o_regular==1 
la val 	h2o_imp_reg YESNO
la var 	h2o_imp_reg "HH uses a regularly available improved drinking water source"
tab h2o_imp_reg 

*Step 4: After ensuring the HH sampling weight is applied, calculate the %  
*        HHs that use a regularly available improved water source using 
*        h2o_imp_reg. Repeat using ahtype.
svy: tab h2_imp_reg, perc format(%6.1f)
svy: tab h2_imp_reg ahtype, col perc format(%6.1f)

********************************************************************************
***** 8.2 Percent distribution of HHs by the number of trips household members made to obtain drinking water during the past 7 days. (New in ZOI Midline Surveys)

*Step 1: Create a variable that captures the number of trips that HH members took
*        during the 7 days preceding the survey to collect drinking water.
tab1 v213a
tab  v213a v211 if v212==3,m

gen 	h2o_trips=.
replace h2o_trips=0 if v212<3 | v211==11 | v211==12
replace h2o_trips=v213a if v213a>=0 & v213a<97
tab 	h2o_trips
la var 	h2o_trips "Number of trips for drinking water, past 7 days (continuous)"

*Step 2: Create a variable that assigns HHs to categories according to the 
*        number of trips that HH members took to collect drinking water during 
*        the 7 days preceding the survey.
*INSTRUCTIONS: Adjust the categories used as needed, based on the data, so that 
*              HHs are reasonably spread across the categories.
recode h2o_trips (0=0 "No trips") ///
				 (1/4=1 "1-4 trips") ///
				 (5/9=2 "5-9 trips") ///
				 (10/96=3 "10+ trips"), gen(h2o_trips_cat)
la var h2o_trips_cat "Number of trips for drinking water, past 7 days (categorical)"

*Step 3: After ensuring the HH sampling weight is applied, calculate the % of  
*        HHs that made 0, 1-4, 5-9, and 10+ trips to collect water. 
svy: tab h2o_trips_cat, perc ci format(%6.1f)
svy: tab h2o_trips_cat ahtype, col perc ci format(%6.1f)

********************************************************************************
***** 8.3. Correct water treatment technology

* Step 1. Create a binary variable to flag HHs using an effective water treatment practice or technology (h2o_corrtreat). 

gen h2o_corrtreat=.
replace h2o_corrtreat=0 if v217!=""
replace h2o_corrtreat= 1 if strpos(v217,"A")>0 | strpos(v217,"B")>0 |
							strpos(v217,"D")>0 | strpos(v217,"E")>0
la val h2_corrtreat YESNO 
la var h2o_corrtreat "HH uses correct water treatment practice/tech"
tab h2o_corrtreat

*Step 2. After ensuring the HH sampling weight is applied, calculate the % of HHs that correctly treat their drinking water using the h2o_corrtreat variable. Repeat using ahtype as a disaggregate.

svy: tab h2o_corrtreat format(%6.1f)
svy: tab h2o_corrtreat ahtype, col format(%6.1f)

********************************************************************************
***** 8.4 Soap and water at handwashing station (FEED THE FUTURE INDICATOR)

*Step 1: Create binary variable to flag HHs in which both soap and water are found at a handwashing station. Include households where a fixed or mobile place for handwashing was observed and households where no handwashing facility exists in the denominator—but exclude HHs that do not provide permission to see the handwashing facility or where it is not seen for some other reason.

tab1 v205 v206 v207
*INSTRUCTIONS: Adjust syntax if fixed and mobile handing washing stations are 
*              not distinguished in the questionnaire
gen handwash=0 if v205==1 | v205==2 |v205==3
replace handwash=1 if (v205==1 | v205==2) & v206==1 & v207==1
la var handwash "HH has a handwashing station with soap and water"
tab handwash

*Step 2: After ensuring the HH sampling weight is applied, calculate the % of HHs in which soap and water are found at the commonly used handwashing stations. Repeat using genhhttype_dj ahtype as disaggregates.

svy: tab handwash format(%6.1f)
svy: tab handwash genhhtype_dj, col format(%6.1f)
svy: tab handwash ahtype, col format(%6.1f)


********************************************************************************
***** *8.5 Improved sanitation facility - shared

*Step 1: Create a binary variable to flag HHs using an improved sanitation facility (san_improved). 
gen		san_improved=0
replace san_improved=1 if inlist(v208,11,12,13,15,21,22,31)
la val	san_improved YESNO 
la var	san_improved "HH's sanitation facility is improved"
tab san_improved 

*Step 2: Create a binary variable to flag HHs that share their sanitation facility with other HHs (san_shared).
gen		san_shared=.
replace san_shared=0 if v209==0
replace san_shared=1 if v209==1 
la val	san_shared YESNO 
la var 	san_shared "HH shares sanitation facility with other HHs"
tab san_shared 

*Step 3: Create a binary variable to flag HHs using an improved sanitation facility that is shared with other HHs (san_impshared).
gen		san_impshared=0
replace san_impshared=1 if san_improved==1 & (san_shared==1 | san_shared==.)
la val	san_impshared YESNO 
la var 	san_impshared "HH uses a shared improved sanitation facility"
tab san_impshared

*Step 4: After ensuring the HH sampling weight is applied, calculate the % of HHs that use an improved sanitation facility that is shared with other HHs using san_impshared. Repeat using genhhtype_dj and ahtype as disaggregates.
svy: tab san_impshared format(%6.1f)
svy: tab san_impshared ahtype, col format(%6.1f)

********************************************************************************
***** 8.6. Basic sanitation (Improved sanitation facility, not shared) (FEED THE FUTURE INDICATOR)

*Step 1: Create a binary variable to flag HHs using an improved sanitation facility that is not shared with other HHs (san_impshared).
gen 	san_impnotshared=0
replace san_impnotshared=1 if san_improved==1 & san_shared==0
la val	san_impnotshared YESNO 
la var 	san_impnotshared "HH uses an improved, unshared sanitation facility"
tab san_impnotshared

*Step 2: After ensuring the HH sampling weight is applied, calculate the % of HHs that use an improved sanitation facility that is not shared with other HHs using the san_impnotshared variable. Repeat using genhhtype_dj and ahtype as disaggregates. 
svy: tab san_impnotshared format(%6.1f)
svy: tab san_impnotshared genhhtype_dj, col format(%6.1f)
svy: tab san_impnotshared ahtype, col format(%6.1f)

********************************************************************************
***** 8.7. Unimproved sanitation facility

*Step 1: Create binary variable to flag HHs using an unimproved sanitation facility (san_notimp)
gen 	san_notimp=inlist(v208,14,23,41,51,61,96,.) 
la val	san_notimp YESNO 
la var san_notimp "HH uses an unimproved sanitation facility"
tab san_notimp

*Step 2: After ensuring the HH sampling weight is applied, calculate the % of HHs that use an unimproved sanitation facility using san_notimp. Repeat using ahtype as a disaggregate.
svy: tab san_notimp format(%6.1f)
svy: tab san_notimp ahtype, col format(%6.1f)


********************************************************************************
***** 8.8. Open defecation

*Step 1: Create binary variable to flag HH practicing open defecation (san_opendef).
gen 	san_opendef=0
replace	san_opendef=1 if v208==61
la val 	san_opendef YESNO 
la var 	san_opendef "HH practices open defecation"
tab san_opendef

*Step 2: After ensuring the HH sampling weight is applied, calculate the % of HHs that report having no sanitation facility or using the bush or field for defecation using san_opendef. Repeat using ahtypeas a disaggregate.
svy: tab san_opendef format(%6.1f)
svy: tab san_opendef ahtype, col format(%6.1f)


********************************************************************************
****** 8.9. Mean number of HH members who regularly defecate in the open 

*NOTE: Included "Other" toilet as having a toilet facility. Customize for survey as needed.

*Step 1: Create a variable to capture the number of HH members who defecate in the open regularly (hhmem_open_def).
tab v210a
gen hhmem_open_def=v210a if v210a<97
la var hhmem_open_def "Number of HH members who defecate in open regularly"

*Step 2: After ensuring the HH sampling weight is applied, calculate the mean number of HH members who regularly decefate in the open overall and by residence.
svy: mean hhmem_open_def cformat(%6.1f)
svy: mean hhmem_open_def, over(ahtype) cformat(%6.1f)

********************************************************************************
***** 8.10 Brief Household Water Insecurity Experiences (HWISE-4) Scale
*Please run Brief Household Water Insecurity Experiences (HWISE-4) Scale do file to calculate the HWISE-4 results. The following code runs the do file automatically, but first be sure to customize the template HWISE do file for your survey before running the the code.

*cd "$syntax\"
*do FTF ZOI Survey [COUNTRY] [YEAR] syntax HWISE4.do

********************************************************************************
**#DWELLING AND HOUSEHOLD CHARACTERISTICS (Guide to Midline Statistics Chapter 9)
********************************************************************************
/*Indicators: 
	1. Percentage of households using solid fuels
	2. Percentage of households with access to electricity
	3. Mean number of de jure household members per sleeping room
	4. Percentage distribution of households by roof material of dwelling
	5. Percentage distribution of households by floor material of dwelling
	6. Percentage distribution of households by exterior walls of dwelling
*/

*********************************************************************************
****** 9.1. Percent of households using solid fuels for cooking

*Step 1: Create a binary variable that flags households using solid fuels for cooking (dw_solidfuel). 
tab    v219,m
gen dw_solidfuel=.
replace dw_solidfuel=1 if v219>=6 & v219<=11
replace dw_solidfuel=0 if v219<6
la val dw_solidfuel YESNO
la var dw_solidfuel "HH uses solid fuel cooking fuel"
tab v219 dw_solidfuel, m //verify

*Step 2. After ensuring the HH sampling weight is applied, calculate the % of HHs that use solid fuels for cooking using dw_solidfuel. Repeat using the ahtypeas a disaggregate.
svy: tab dw_solid_fuel format(%6.1f)
svy: tab dw_solid_fuel ahtype, col format(%6.1f)

**********************************************************************************
****** 9.2. Number of de jure HH members per sleeping room

*Step 1: Create a variable that indicates the number of rooms in each HH's dwelling that are used for sleeping (nroom). If the number of sleeping rooms in the HH-level data file is missing or equal to 0, set the number of sleeping rooms to be 1, assuming that every HH has at least 1 room in which to sleep. 
tab v204,m  

gen roomsleep=v204 if v204<96  //96=other, 97=refusals, 98=DK, 99=missing
replace roomsleep=1 if v204==. | v204==0
la var roomsleep "Number of rooms for sleeping in HH"

*Step 2: Create a variable that indicates the number of de jure HH members per sleeping room (memsleep_dj).
gen memsleep_dj= (hhsize_dj/roomsleep)  
la var memsleep_dj "Number of de jure HH members per sleeping room"
sum memsleep_dj

*Step 3: After ensuring the HH sampling weight is applied, calculate the mean value of the memsleep_dj variable. Repeat using ahtypeas a disaggregate. 
svy: mean memsleep_dj cformat(%6.1f)
svy: mean memsleep_dj, over(ahtype) cformat(%6.1f)

**********************************************************************************
****** 9.3. Percent distribution of HHs by dwelling roof materials

*Step 1: Create a variable that categorizes each HH's main dwelling roof material as natural, rudimentary, finished, or other (dw_roof). The types of roof materials vary by country, so be sure to adapt the template syntax as needed to include all response options in the HH data file.
tab v201,m
recode v201 (11/13=1 "Natural")     /// 
            (14/22=2 "Rudimentary") ///
			(31/36=3 "Finished")    ///
			(96=4    "Other")       ///
			(97/max=.), gen (dw_roof)
la var dw_roof "Roof material of HH's dwelling"
tab v201 dw_roof, m //verify

*Step 2: After ensuring the HH sampling weight is applied, calculate the % of HHs that have roofs made of natural, rudimentary, and finished materials on their dwellings using the dw_roof variable. Repeat using ahtypeas a disaggregate. 
svy: tab dw_roof format(%6.1f)
svy: tab dw_roof ahtype, col format(%6.1f)

***********************************************************************************
****** 9.4. Percent distribution of HHs by dwelling exterior wall materials 

*Step 1: Create a variable that categorizes each HH's main wall material as natural, rudimentary, finished, or other (dw_wall). The types of wall materials vary by country, so be sure to adapt the template syntax as needed to capture all response options in the HH data file.
tab v203,m
recode v203 (11/13=1 "Natural")     ///
            (14/24=2 "Rudimentary") ///
			(31/36=3 "Finished")    ///
			(96=4    "Other")       ///
			(97/max=.), gen (dw_wall)
la var dw_wall "Wall material of HH's dwelling"
tab v203 dw_wall, m //verify

*Step 2: After ensuring the HH sampling weight is applied, calculate the % of HHs that have walls made of natural, rudimentary, and finished materials on their dwellings using the dw_wall variable. Repeat using ahtype as a disaggregate. 
svy: tab dw_walls format(%6.1f)
svy: tab dw_walls ahtype, col format(%6.1f)

************************************************************************************
****** 9.5. Percent distribution of HHs by dwelling floor materials 

*Step 1: Create a variable that categories each HH's main floor material as natural, rudimentary, finished, or other (dw_floor). The types of floor materials vary by country, so be sure to adapt the template syntax as needed to capture all response options in the HH data file.
tab    v202,m
recode v202 (11/13=1 "Natural")     ///
            (21/22=2 "Rudimentary") ///
			(31/35=3 "Finished")    ///
			(96=4    "Other")       ///
			(97/max=.), gen (dw_floor)
la var dw_floor "Floor material of HH's dwelling"
tab v202 dw_floor, m //verify

*Step 2: After ensuring the HH sampling weight is applied, calculate the % of HHs that have floors made of natural, rudimentary, and finished materials in their dwellings using the dw_floor variable. Repeat using ahtype as a disaggregate. 
svy: tab dw_floor format(%6.1f)
svy: tab dw_floor ahtype, col format(%6.1f)

************************************************************************************
****** 9.6. Percent of HHs that have electricity

*Step 1: Create a binary variable that flags HHs that have electricity (dw_elec). 
tab v222a,m
gen dw_elec=.
replace dw_elec=0 if v222a==2
replace dw_elec=1 if v222a==1 
la val dw_elec YESNO
la var dw_elec "HH has electricity"
tab dw_elec

*Step 2: Calculate the percentage of households that have electricity using the dw_elec variable. Repeat using ahtype as a disaggregate. 
svy: tab dw_elec format(%6.1f)
svy: tab dw_elec ahtype, col format(%6.1f)

*#FINALIZE AND SAVE DATE FILE
save "$analytic\Midline ZOI Survey household data WASH Dwelling.dta", replace
di "Date:$S_DATE $S_TIME"
log  close





