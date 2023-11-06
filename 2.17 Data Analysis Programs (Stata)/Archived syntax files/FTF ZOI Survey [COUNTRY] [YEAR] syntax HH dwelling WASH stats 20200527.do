/*******************************************************************************
************************* FEED THE FUTURE ZOI SURVEY ***************************
**************************   SUMMARY  STATISTICS  ******************************
******************************* [COUNTRY, YEAR] ********************************
********************************************************************************
Description: This code is intended to calculate household and person level 
background indicators that are presented in the baseline and endline reports.

The statistics are grouped in the following areas:

A. Household demographics (de jure), expect educational attainment is de facto
B. Primary adult decisionmaker characteristics (de jure)
C. Individual educational attainment (de facto)
D. Dwelling characteristics
E. Household water, sanitation, and hygiene (WASH) indicators

Author(s): Gheda Temsah @ ICF 
		   Nizam Khan @ ICF
Date: 8/28/2018
Updated by: Kirsten Zalisk @ ICF
Update Date: 7/10/2019

This syntax file was developed using the core Feed the Future ZOI Survey phase one 
endline/phase two baseline core questionnaire. It must be adapted for the final  
country-specific questionnaire. The syntax could only be partially tested using 
ZOI Survey data; therefore, double-check all results carefully and troubleshoot 
to resolve any issues identified. 
*******************************************************************************/

clear all
set more off

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global source    "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Raw"      
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Do file Name:    	 "$syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax HH background tables.do"				
//Input(s):     	 "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta"
//					 "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta"
//Log Outputs(s):	 "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] HH background tables.log"

capture log close
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] HH background tables.log", replace

********************************************************************************
//HH demographics
********************************************************************************
/*Sample-weighted indicators:
	1.Mean household size, de jure
	2.Mean number of children under 2 years, de jure
	3.Mean number of children under 5 years, de jure
	4.Mean number of children 5 or older (5-17 years), de jure
	5.Mean number of youth (15-29 years), de jure
	6.Mean number of women of reproductive age (15-49 years), de jure
	7.Mean number of adult male household members, de jure
	8.Mean number of adult female household members, de jure
	9.Mean number of producers of any targeted commodity, de jure
	10.Percent of adults who are male (%), de jure
	11.Percent of adults who are female (%), de jure
	12.Household size (%), de jure
	13.Highest education level completed (%), de facto
*/

*1. Load the household analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear

*2. Weight by household weight
*5/27/2020: Updated the svyset command for consistency across do files
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_hh], strata(samp_stratum) 

*3. Tabulate the values for Table 3.1, total and by gendered HH type
//Indicator 1. Mean household size, de jure
svy: mean hhsize_dj
svy: mean hhsize_dj, over(genhhtype_dj)

//Indicator 2. Mean number of children under 2 years, de jure
svy: mean ncu2_dj
svy: mean ncu2_dj, over(genhhtype_dj)

//Indicator 3. Mean number of children under 5 years, de jure
svy: mean ncu5_dj
svy: mean ncu5_dj, over(genhhtype_dj)

//Indicator 4. Mean number of children 5 or older (5-17 years), de jure
svy: mean nc5_17y_dj
svy: mean nc5_17y_dj, over(genhhtype_dj)

//Indicator 5. Mean number of youth (15-29 years), de jure
svy: mean nyouth_dj
svy: mean nyouth_dj, over(genhhtype_dj)

//Indicator 6. Mean number of women of reproductive age (15-49 years), de jure
svy: mean nwra_dj
svy: mean nwra_dj, over(genhhtype_dj)

//Indicator 7. Mean number of adult male household members, de jure
svy: mean nadult_mdj
svy: mean nadult_mdj, over(genhhtype_dj)

//Indicator 8. Mean number of adult female household members, de jure
svy: mean nadult_fdj
svy: mean nadult_fdj, over(genhhtype_dj)

//Indicator 9. Mean number of producers of any targeted commodity, de jure
svy: mean nvcc_dj
svy: mean nvcc_dj, over(genhhtype_dj)

//Indicator 12. Household size category (%), de jure
svy: tab hhsizegrp_dj
svy: tab hhsizegrp_dj genhhtype_dj, col

//Indicator 13. Highest education level completed (%), de facto
***UPDATE 9/11/2019: Changed genhhtype_dj to genhhtype_df.***
svy: tab edulevel_hh_df 
svy: tab edulevel_hh_df genhhtype_df, col

*4. Deterine unweighted n's for table
*Total
count
***UPDATE 9/17/2019: Added next 2 lines.***
tab genhhtype_dj
tab edulevel_hh_df 

*By gendered HH type
tab genhhtype_dj
***UPDATE 9/17/2019: Added next line.***
tab genhhtype_df

*5. Load the household analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear

*6. Weight by household weight
*5/27/2020: Updated the svyset command for consistency across do files
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_hh], strata(samp_stratum) 

*7. Tabulate the person-level values for Table 3.1.1, total and by gendered HH type

//Indicator 10. Percent of adults who are male (%), de jure
***UPDATE 9/17/2019: Updated this calculation.***
replace adult_m=.if age<18
svy, subpop(hhmem_dj): tab adult_m, col
svy, subpop(hhmem_dj): tab adult_m genhhtype_dj, col 

//Indicator 11. Percent of adults who are female (%), de jure
***UPDATE 9/17/2019: Updated this calculation.***
replace adult_f=. if age<18
svy, subpop(hhmem_dj): tab adult_f, col
svy, subpop(hhmem_dj): tab adult_f genhhtype_dj if hhmem_dj==1, col

********************************************************************************
//PADM characteristics
********************************************************************************
/*Sample-weighted indicators:
	1. PDM by sex and age group
	2. PDM by sex and marital status
	3. PDM by sex and educational attainment
	4. PDM by sex and participation in any economic activity
	5. PDM by sex and type of economic activity participates in
*/

*1. Load the household analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear

*2. Weight by PAMDM weight
*5/27/2020: Updated the svyset command for consistency across do files
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_mpdm], strata(samp_stratum) 

*3. Tabulate indicator values for PAMDM
*Age group 
svy: tab agegrp_mdm_dj if m6100d==1 
*Marital status
svy: tab marstat_mdm_dj if m6100d==1 & hhmem_dj==1
*Education
svy: tab edu_mdm_dj if m6100d==1 & hhmem_dj==1
*Economic activity participation
svy: tab mdm_actany if m6100d==1 & hhmem_dj==1
*Type of economic activity
svy: tab mdm_econ_farm if m6100d==1 & hhmem_dj==1
svy: tab mdm_econ_nonfarm if m6100d==1 & hhmem_dj==1
svy: tab mdm_econ_wage if m6100d==1 & hhmem_dj==1

*4. Determine PAMDM unweighted n
tab mdm_dj if m6100d==1 

*5. Weight by PAFDM weight
*5/27/2020: Updated the svyset command for consistency across do files
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_fpdm], strata(samp_stratum) 

*6. Tabulate indicator values for PAFDM
*Age group 
svy: tab agegrp_fdm_dj if v6100d==1
*Marital status
svy: tab marstat_fdm_dj if v6100d==1 & hhmem_dj==1
*Education
svy: tab edulevel_fdm if v6100d==1 & hhmem_dj==1
*Economic activity participation
svy: tab fdm_actany if v6100d==1 & hhmem_dj==1
*Type of economic activity
svy: tab fdm_econ_farm if v6100d==1 & hhmem_dj==1
svy: tab fdm_econ_nonfarm if v6100d==1 & hhmem_dj==1
svy: tab fdm_econ_wage if v6100d==1 & hhmem_dj==1

*7. Determine PAFDM unweighted n
tab fdm_dj if v6100d==1 

********************************************************************************
//EDUCATION: ATTENDING SCHOOL, TOTAL AND BY SEX
********************************************************************************
/* Indicators included in Table 3.2.1:
	Percent distribution of de facto HH members 5-24 yo currently attending school, by age catogory
	Percent distribution of de facto female HH members 5-24 yo currently attending school, by age category
	Percent distribution of de facto male HH members 5-24 yo currently attending school, by age category
	Ratio of de facto females to males 5-24 yo currently attending school, by age category
*/

*1. Load the household analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic", clear

*2. Weight by household weight
*5/27/2020: Updated the svyset command for consistency across do files
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_hh], strata(samp_stratum) 

*3. Calculate the sample-weighted indicators:

*Percent distribution of de facto HH members 5-24 yo currently attending school, by age catogory
gen edu_attend_df=.
replace edu_attend_df=0 if age>=5 and age<=24 and hhmem_df==1
replace edu_attend_df=1 if age>=5 and age<=24 and hhmem_df==1 and edu_attend==1
svy: tab agegrp edu_attend_df, obs row

*Percent distribution of de facto male HH members 5-24 yo currently attending school, by age catogory
gen edu_attend_mdf=.
replace edu_attend_mdf=0 if edu_attend_df!=. & sex==1
replace edu_attend_mdf=1 if edu_attend_df==1 & sex==1
svy: tab agegrp edu_attend_mdf, obs row

*Percent distribution of de facto female HH members 5-24 yo currently attending school, by age catogory
***UPDATE 9/17/2019: Modified next line.***
gen edu_attend_fdf=.
replace edu_attend_fdf=0 if edu_attend_df!=. & sex==2
replace edu_attend_fdf=1 if edu_attend_df==1 & sex==2
svy: tab agegrp edu_attend_fdf, obs row

*Ratio of de facto females to males 5-24 yo currently attending school, by age category
***UPDATE 9/17/2019: Updated this instruction.***
*INSTRUCTION: Divide the weighted percent of females attending school by the weighted
*percent of males attending school, for each age group to get the ratios.

********************************************************************************
//EDUCATION: COMPLETED PRIMARY EDUCATION, TOTAL AND BY SEX
********************************************************************************
/* Indicators:
	Percent distribution of de facto HH members 10+ yo who completed primary schooling, by age category
	Percent distribution of de facto female HH members 10+ yo who completed primary schooling, by age category
	Percent distribution of de facto male HH members 10+ yo who completed primary schooling, by age category
	Ratio of de facto females to males 10+ yo who completed primary schooling, by age category
*/

*Percent distribution of de facto HH members 10+ yo who completed primary schooling, by age category
gen edu_prim_df=.
replace edu_prim_df=0 if age>=10 & hhmem_df==1
replace edu_prim_df=1 if age>=10 & hhmem_df==1 & edu_prim==1
svy: tab agegrp edu_prim_df, obs row

*Percent distribution of de facto male HH members 10+ yo who completed primary schooling, by age category
gen edu_prim_mdf=.
replace edu_prim_mdf=0 if edu_prim_df!=. & sex==1
replace edu_prim_mdf=1 if edu_prim_df==1 & sex==1
svy: tab agegrp edu_prim_mdf, obs row

*Percent distribution of de facto female HH members 10+ yo who completed primary schooling, by age category
***UPDATE 9/17/2019: Added next line.***
gen edu_prim_fdf=.
replace edu_prim_fdf=0 if edu_prim_df!=. & sex==2
replace edu_prim_fdf=1 if edu_prim_df==1 & sex==2
svy: tab agegrp edu_prim_fdf, obs row

*Ratio of de facto females to males 10+ yo who completed primary schooling, by age category
***UPDATE 9/17/2019: Updated this instruction.***
*INSTRUCTION: Divide the weighted percent of females who completed primary education 
*by the weighted percent of males who completed primary education, for each age 
*group to get the ratios.

********************************************************************************
//TABLE 3.3.1 - DWELLING CHARACTERISTICS AND WASH INDICATORS
********************************************************************************
/*Indicators: 
	1. Percentage of households using solid fuels
	2. Percentage of households with access to electricity
	3. Mean number of de jure household members per sleeping room
	4. Percentage distribution of households by roof material of dwelling
	5. Percentage distribution of households by floor material of dwelling
	6. Percentage distribution of households by exterior walls of dwelling
*/

*1. Load the household analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", clear

*2. Weight by household weight
*5/27/2020: Updated the svyset command for consistency across do files
*The samp_stratum variable is a placeholder for the ZOI survey's strata variable
*and should be updated.
svyset hhea [pw=wgt_hh], strata(samp_stratum) 

*3. Calculate sample-weighted indicators for Table 3.3.1:
//Indicator 1.  Percentage of households using solid fuels
svy: tab dw_solid_fuel
svy: tab dw_solid_fuel ahtype, col
svy: tab dw_solid_fuel genhhtype_dj, col

//Indicator 2.  Percentage of households with access to electricity
svy: tab dw_elec
svy: tab dw_elec ahtype, col
svy: tab dw_elec genhhtype_dj, col

//Indicator 3. Mean number of de jure household members per sleeping room
svy: mean memsleep_dj
svy: mean memsleep_dj, over(ahtype)
svy: mean memsleep_dj, over(genhhtype_dj)

//Indicator 4. Percentage distribution of households by roof material of dwelling
svy: tab dw_roof
svy: tab dw_roof ahtype, col
svy: tab dw_roof genhhtype_dj, col

//Indicator 5. Percentage distribution of households by exterior walls of dwelling
svy: tab dw_walls
svy: tab dw_walls ahtype, col
svy: tab dw_walls genhhtype_dj, col

//Indicator 6. Percentage distribution of households by floor material of dwelling
svy: tab dw_floor
svy: tab dw_floor ahtype, col
svy: tab dw_floor genhhtype_dj, col

********************************************************************************
//TABLE 3.4.1 - WASH (WATER, SANITATION, AND HYGENIENE) INDICATORS
********************************************************************************
/*Sample-weighted indicators in Table 3.4.1:
	1.  Percentage of households using an improved water source
	2.  Percentage of households using a correct water treatment practice or technology
	3.  Percentage of households with soap and water at a handwashing station
	4.	Percentage of households using an improved sanitation facility, not shared
	5.  Percentage of households using an improved sanitation facility, shared
	6.  Percentage of households using an unimproved sanitation facility
	7.  Percentage of households practicing open defecation
*/

//Indicator 1.  Percentage of households using an improved water source
svy: tab h2_imp_reg
svy: tab h2_imp_reg ahtype, col
svy: tab h2_imp_reg genhhtype_dj, col

//Indicator 2.  Percentage of households using a correct water treatment practice or technology
svy: tab h2_corrtreat
svy: tab h2_corrtreat ahtype, col
svy: tab h2_corrtreat genhhtype_dj, col

//Indicator 3.  Percentage of households with soap and water at a handwashing station
svy: tab handwash
svy: tab handwash ahtype, col
svy: tab handwash genhhtype_dj, col

//Indicator 4.  Percentage of households using an improved sanitation facility, not shared
svy: tab san_impnotshared
svy: tab san_impnotshared ahtype, col
svy: tab san_impnotshared genhhtype_dj, col

//Indicator 5.  Percentage of households using an improved sanitation facility, shared
svy: tab san_impshared
svy: tab san_impshared ahtype, col
svy: tab san_impshared genhhtype_dj, col

//Indicator 6.  Percentage of households using an unimproved sanitation facility
svy: tab san_notimp
svy: tab san_notimp ahtype, col
svy: tab san_notimp genhhtype_dj, col

//Indicator 7.  Percentage of households practicing open defecation
svy: tab san_opendef
svy: tab san_opendef ahtype, col
svy: tab san_opendef genhhtype_dj, col

*2. Determine unweighted n's
*Total
count
*Urban/Rural
tab ahtype
*Gendered HH type
tab genhhtype_dj


//Close the log file
di "Date:$S_DATE $S_TIME"
log  close
