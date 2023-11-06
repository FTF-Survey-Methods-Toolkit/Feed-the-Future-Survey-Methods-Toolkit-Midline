/*******************************************************************************
************************* FEED THE FUTURE ZOI MIDLINE SURVEY ***************************
***************************  HHOLD ANALYTICAL FILE  ****************************
********************************* [MALI, 2019] *********************************
********************************************************************************
Description: This code is intended to create household-level analytical variables 
and disaggregates that are required to calculate program indicators and for data 
analysis.

For Mali, the dwelling characteristic and WASH variables were moved to another
do file. 

Author(s): Gheda Temsah @ ICF 
		   Nizam Khan @ ICF
Date updated: 10/11/2021 by Shireen Assaf to fix handwashing code	

Customized for Mali by: Kirsten Zalisk @ ICF
Customized date: January 10, 2019
*******************************************************************************/

clear all
set more off
set maxvar 30000

//DIRECTORY PATH
global source   "C:\Users\21300\Documents\Atlanta\PADEMS\Midline Survey\Data\Raw"
global analytic "C:\Users\21300\Documents\Atlanta\PADEMS\Midline Survey\Data\Analytic"
global syntax   "C:\Users\21300\Documents\Atlanta\PADEMS\Midline Survey\Data\Syntax"

//Input data:  $source\Midline ZOI Survey household data raw.dta 
//			   $analytic\Midline ZOI Survey persons data analytic.dta
//Log Output:  $analytic\Log\FTF ZOI Survey Mali 2019 household data analytic.log	
//Output data: $analytic\FTF ZOI Survey Mali 2019 household data analytic.dta
//Syntax: 	   $syntax\FTF ZOI Survey Mali household_analytic.do 	

capture log close
log using "$analytic\Log\Midline ZOI Survey household data analytic.log", replace

********************************************************************************
//STEP 1: HOUSEHOLD DEMOGRAPHICS FROM THE PERSON-LEVEL DATA FILE
********************************************************************************
*First, load the persons-level data file to get individual-level data need to 
*calculate household-level variables.
use "$analytic\Midline ZOI Survey persons data analytic.dta", clear

*1.1. Create variables for the number of de jure HH members, by key group
***CUSTOMIZED VCCs FOR MALI
sort hhea hhnum
by hhea hhnum: egen nadult=total(adult) 
by hhea hhnum: egen nadult_f=total(adult_f)
by hhea hhnum: egen nadult_m=total(adult_m)
by hhea hhnum: egen nadult_dj=total(adult) if hhmem_dj==1
by hhea hhnum: egen nadult_fdj=total(adult_f) if hhmem_dj==1
by hhea hhnum: egen nadult_mdj=total(adult_m) if hhmem_dj==1
by hhea hhnum: egen nadult_df=total(adult) if hhmem_df==1
by hhea hhnum: egen nadult_fdf=total(adult_f) if hhmem_df==1
by hhea hhnum: egen nadult_mdf=total(adult_m) if hhmem_df==1
by hhea hhnum: egen nwra_dj=total(wra) if hhmem_dj==1
by hhea hhnum: egen nc5_17y_dj=total(c5_17y) if hhmem_dj==1
by hhea hhnum: egen nyouth_dj=total(age15_29y) if hhmem_dj==1
by hhea hhnum: egen ncu2_dj=total(cu2) if hhmem_dj==1
by hhea hhnum: egen ncu5_dj=total(cu5) if hhmem_dj==1
*by hhea hhnum: egen nvcc_dj=total(vcc) if hhmem_dj==1
*by hhea hhnum: egen nvcc_maize_dj=total(vcc_maize2) if hhmem_dj==1
*by hhea hhnum: egen nvcc_millet_dj=total(vcc_millet2) if hhmem_dj==1
*by hhea hhnum: egen nvcc_okra_dj=total(vcc_okra2) if hhmem_dj==1
*by hhea hhnum: egen nvcc_sheep_dj=total(vcc_sheep2) if hhmem_dj==1
by hhea hhnum: egen hhsize_dj=total(hhmem_dj)
by hhea hhnum: egen hhsize_df=total(hhmem_df)
gen temp=1 if age!=.
by hhea hhnum: egen hhsize=total(temp)
drop temp

*1.2. Create variables for the number of de facto & de jure HH members who completed primary school
by hhea hhnum: egen nedu_prim_df=total(edu_prim) if hhmem_df==1
by hhea hhnum: egen nedu_prim_dj=total(edu_prim) if hhmem_dj==1

// LABEL VARIABLES
la var nadult         "Number of adults (18+) in HH"
la var nadult_f       "Number of female adults in HH"
la var nadult_m       "Number of male adults in HH"
la var nadult_dj      "Number of de jure adults (18+) in HH"
la var nadult_fdj     "Number of de jure female adults in HH"
la var nadult_mdj     "Number of de jure male adults in HH"
la var nadult_df      "Number of de facto adults (18+) in HH"
la var nadult_fdf     "Number of de facto female adults in HH"
la var nadult_mdf     "Number of de facto male adults in HH"
la var nwra_dj		  "Number of de jure women of reproductive age (15-49) in HH"
la var nyouth_dj      "Number of de jure youth (15-29 yo) in HH"
la var nc5_17y_dj     "Number of de jure children 5-17 yo in HH"
la var ncu2_dj        "Number of de jure children under 2 in HH"
la var ncu5_dj        "Number of de jure children under 5 in HH"
*la var nvcc_dj        "Number of de jure VCC producers in HH"
*la var nvcc_maize_dj  "Number of de jure maize producers in HH"
*la var nvcc_millet_dj "Number of de jure millet producers in HH"
*la var nvcc_okra_dj   "Number of de jure okra producers in HH"
*la var nvcc_sheep_dj  "Number of de jure sheep producers in HH"
la var edu_prim	      "At least one HH member completed primary school"
la var hhsize         "Number of HH members"	
la var hhsize_dj      "Number of de jure (usual) HH members"	
la var hhsize_df      "Number of de facto HH members (spent night prior to survey in HH)"
la var nedu_prim_df   "Number of de facto HH members who completed primary school"
la var nedu_prim_dj   "Number of de jure HH members who completed primary school"

tab1 n*

*1.3 Household size category, de jure members
tab hhsize_dj,m
recode hhsize_dj (1/5=1   "Small")  ///
                 (6/10=2  "Medium") ///
			     (11/max=3 "Large"), gen (hhsizegrp_dj)

la var hhsizegrp_dj  "Households by size category, de jure members"
tab hhsizegrp_dj

*1.4 Household size, de facto members 
tab    hhsize_df,m
recode hhsize_df (1/5=1   "Small")  ///
                 (6/10=2  "Medium") ///
			     (11/max=3 "Large"), gen (hhsizegrp_df)
replace hhsizegrp_df=. if hhsize_df==0
la var hhsizegrp_df  "Households by size category, de facto members"
tab hhsizegrp_df

*1.5 Highest level of education attained by any de facto household member
bysort hhea hhnum: egen edulevel_hh_df = max(edulevel) if hhmem_df==1

la var edulevel_hh_df "Highest level of educ attained by de facto HH members"
la val edulevel_hh_df edulevel
tab edulevel_hh_df

bysort hhea hhnum: egen edulevel_hh1_df = max(edulevel1) if hhmem_df==1
la var edulevel_hh1_df "Highest level of educ attained by de facto HH members (variation 1)"
la val edulevel_hh1_df edulevel1
tab edulevel_hh1_df

bysort hhea hhnum: egen edulevel_hh2_df = max(edulevel2) if hhmem_df==1
la var edulevel_hh2_df "Highest level of educ attained by de facto HH members (variation 2)"
la val edulevel_hh2_df edulevel2
tab edulevel_hh2_df

bysort hhea hhnum: egen edulevel_hh3_df = max(edulevel3) if hhmem_df==1
la var edulevel_hh3_df "Highest level of educ attained by de facto HH members (variation 3)"
la val edulevel_hh3_df edulevel3
tab edulevel_hh3_df

*1.6 Highest level of education attained by any de jure household member
bysort hhea hhnum: egen edulevel_hh_dj = max(edulevel) if hhmem_dj==1

la var edulevel_hh_dj "Highest level of educ attained by de jure HH members"
la val edulevel_hh_dj edulevel
tab edulevel_hh_dj

bysort hhea hhnum: egen edulevel_hh1_dj = max(edulevel1) if hhmem_dj==1
la var edulevel_hh1_dj "Highest level of educ attained by de jure HH members (variation 1)"
la val edulevel_hh1_dj edulevel1
tab edulevel_hh1_dj

bysort hhea hhnum: egen edulevel_hh2_dj = max(edulevel2) if hhmem_dj==1
la var edulevel_hh2_dj "Highest level of educ attained by de jure HH members (variation 2)"
la val edulevel_hh2_dj edulevel2
tab edulevel_hh2_dj

bysort hhea hhnum: egen edulevel_hh3_dj = max(edulevel3) if hhmem_dj==1
la var edulevel_hh3_dj "Highest level of educ attained by de jure HH members (variation 3)"
la val edulevel_hh3_dj edulevel3
tab edulevel_hh3_dj

bysort hhea hhnum: egen edulevel_hh3 = max(edulevel3) 
la val edulevel_hh3 edulevel3
la var edulevel_hh3 "Highest level of educ attained by all HH members (excl. dk, missing)"
tab edulevel_hh3

*1.7 Create household level data
** After using the collapse command, there will be one record per HH
collapse (max) hhsize* n* edulevel_hh* *fdm *mdm *fdm_dj *mdm_dj *pdm*, by(hhea hhnum)
count

la val edulevel_hh_*  edulevel
la val edulevel_hh1* edulevel1
la val edulevel_hh2* edulevel2
la val edulevel_hh3* edulevel3

la val agegrp_?dm_dj agegrp_pdm_dj
la val hhsizegrp* hhsizegrp_dj
la val youth_*dm_dj edu_prim_*dm_dj ?dm ?dm_dj YESNO
la val edu_?dm_dj edulevel3

// LABEL VARIABLES
la var nadult         "Number of adults (18+) in HH"
la var nadult_f       "Number of female adults in HH"
la var nadult_m       "Number of male adults in HH"
la var nadult_dj      "Number of de jure adults (18+) in HH"
la var nadult_fdj     "Number of de jure female adults in HH"
la var nadult_mdj     "Number of de jure male adults in HH"
la var nadult_df      "Number of de facto adults (18+) in HH"
la var nadult_fdf     "Number of de facto female adults in HH"
la var nadult_mdf     "Number of de facto male adults in HH"
la var nwra_dj		  "Number of de jure women of reproductive age (15-49) in HH"
la var nyouth_dj      "Number of de jure youth (15-29 yo) in HH"
la var nc5_17y_dj     "Number of de jure children 5-17 yo in HH"
la var ncu2_dj        "Number of de jure children under 2 in HH"
la var ncu5_dj        "Number of de jure children under 5 in HH"
*la var nvcc_dj        "Number of de jure VCC producers in HH"
*la var nvcc_maize_dj  "Number of de jure maize producers in HH"
*la var nvcc_millet_dj "Number of de jure millet producers in HH"
*la var nvcc_okra_dj   "Number of de jure okra producers in HH"
*la var nvcc_sheep_dj  "Number of de jure sheep producers in HH"
la var nedu_prim_dj   "At least one de jure HH member completed primary school"
la var nedu_prim_df   "At least one de facto HH member completed primary school"
la var hhsize         "Number of HH members"	
la var hhsize_dj      "Number of de jure (usual) HH members"	
la var hhsize_df      "Number of de facto HH members (spent night prior to survey in HH)"
la var nedu_prim_df   "Number of de facto HH members who completed primary school"
la var nedu_prim_dj   "Number of de jure HH members who completed primary school"
la var hhsizegrp_dj   "Households by size category, de jure members"
la var hhsizegrp_df   "Households by size category, de facto members"
la var edulevel_hh_df  "Highest level of educ attained by de facto HH members"
la var edulevel_hh1_df "Highest level of educ attained by de facto HH members (variation 1)"
la var edulevel_hh2_df "Highest level of educ attained by de facto HH members (variation 2)"
la var edulevel_hh3_df "Highest level of educ attained by de facto HH members (variation 3)"
la var edulevel_hh_dj  "Highest level of educ attained by de jure HH members"
la var edulevel_hh1_dj "Highest level of educ attained by de jure HH members (variation 1)"
la var edulevel_hh2_dj "Highest level of educ attained by de jure HH members (variation 2)"
la var edulevel_hh3_dj "Highest level of educ attained by de jure HH members (variation 3)"
la var edulevel_hh3    "Highest level of educ attained by all HH members (excl. dk, missing)"
la var agegrp_fdm_dj   "De jure female PADM age, categorical"
la var agegrp_mdm_dj   "De jure male PADM age, categorical"
la var agegrp_pdm_dj   "De jure PADM age, categorical"
la var edu_fdm_dj      "De jure female PADM educ attained (edulevel3)"
la var edu_mdm_dj      "De jure male PADM educ attained (edulevel3)"
la var edu_pdm_dj      "De jure PADM educ attained (edulevel3)"
la var edu_prim_fdm_dj "De jure female PADM completed primary school"
la var edu_prim_mdm_dj "De jure male PADM completed primary school"
la var edu_prim_pdm_dj "De jure PADM completed primary school"
la var fdm 			   "Female primary adult decision-maker (PADM)"
la var fdm_dj 		   "De jure female PADM"
la var mdm 			   "Male primary adult decision-maker (PADM)" 
la var mdm_dj 		   "De jure male PADM" 
la var pdm_dj 		   "De jure PADM" 
la var pdm			   "Primary adult decision-maker (PADM)"
la var youth_fdm_dj	   "De jure female PADM 18-29 yo" 
la var youth_mdm_dj	   "De jure male PADM 18-29 yo"  
la var youth_pdm_dj    "De jure PADM 18-29 yo" 
*la var wgt_mpdm        "Male PADM weight (incl. 6 decimal places)"
*la var wgt_fpdm        "Female PADM weight (incl. 6 decimal places)"

*1.8 Sort and save the HH-level demographic variables created using the person data file
order hhea hhnum hhsize* n* edulevel_hh* 
keep  hhea hhnum hhsize* n* edulevel_hh* *mdm *fdm *dm_dj 
*nvcc*
sort  hhea hhnum
save "$analytic\Temp\Midline ZOI Survey HH demographics", replace

*1.9 Open the "raw" HH-level data file generated from the CSPro CAPI program export
*    and merge into it the HH demographic variables created from the person-level 
*    data file
clear all
set maxvar 30000
use "$source\Midline ZOI household data raw.dta", clear
merge 1:1 hhea hhnum using "$analytic\Temp\Midline ZOI Survey HH demographics.dta"
*(Check to make sure the results of the merge make sense and then drop the merge variable)
drop _merge

*1.10 Create a gendered household type variable
gen     genhhtype=0
replace genhhtype=1 if (nadult_f>0  & nadult_m>0)
replace genhhtype=2 if (nadult_f>0  & nadult_m==0)
replace genhhtype=3 if (nadult_f==0 & nadult_m>0)
replace genhhtype=4 if (nadult_f==0 & nadult_m==0)


la def genhh 1 "Male and Female adults" ///
             2 "Female adults only"     ///
             3 "Male adults only"       ///
			 4 "Children only", modify
la val genhhtype genhh
la var genhhtype "Gendered HH type, all HH members"
tab genhhtype

gen     genhhtype_dj=0
replace genhhtype_dj=1 if (nadult_fdj>0  & nadult_mdj>0) 
replace genhhtype_dj=2 if (nadult_fdj>0  & nadult_mdj==0) 
replace genhhtype_dj=3 if (nadult_fdj==0 & nadult_mdj>0) 
replace genhhtype_dj=4 if (nadult_fdj==0 & nadult_mdj==0)
replace genhhtype_dj=. if nadult_mdj==. & nadult_fdj==.
la val genhhtype_dj genhh
la var genhhtype_dj "Gendered HH type, de jure HH members"
tab genhhtype_dj

gen     genhhtype_df=0
replace genhhtype_df=1 if (nadult_fdf>0  & nadult_mdf>0) & nadult_mdf!=. & nadult_fdf!=.
replace genhhtype_df=2 if (nadult_fdf>0  & nadult_mdf==0) & nadult_mdf!=. & nadult_fdf!=.
replace genhhtype_df=3 if (nadult_fdf==0 & nadult_mdf>0) & nadult_mdf!=. & nadult_fdf!=.
replace genhhtype_df=4 if (nadult_fdf==0 & nadult_mdf==0) & nadult_mdf!=. & nadult_fdf!=.
replace genhhtype_df=. if nadult_mdf==. & nadult_fdf==.
la val genhhtype_df genhh
la var genhhtype_df "Gendered HH type, de facto HH members"
tab genhhtype_df

*1.11 Save the HH-level data file with the new variables included as the "analytic"
*     HH data file
save "$analytic\Midline ZOI Survey household data analytic.dta", replace
numlabel, add

********************************************************************************
//STEP 2: PRIMARY DECISIONMAKERS - VARIABLES IN HH DATA FILE
********************************************************************************
*2.1. Primary decision makers' marital status, by sex
gen     marstat_fdm_dj=1 if v6105==1 & fdm_dj==1 
replace marstat_fdm_dj=2 if v6105==2 & fdm_dj==1 
replace marstat_fdm_dj=3 if (v6105==3 & v6107==1) & fdm_dj==1
replace marstat_fdm_dj=4 if (v6105==3 & (v6107==2 | v6107==3)) & fdm_dj==1  
replace marstat_fdm_dj=5 if (v6105==3 & v6106==3) & fdm_dj==1 

/*
gen     marstat_mdm_dj=1 if m6105==1 & mdm_dj==1  
replace marstat_mdm_dj=2 if m6105==2 & mdm_dj==1 
replace marstat_mdm_dj=3 if (m6105==3 & m6107==1) & mdm_dj==1 
replace marstat_mdm_dj=4 if (m6105==3 & (m6107==2 | m6107==3)) & mdm_dj==1
replace marstat_mdm_dj=5 if (m6105==3 & m6106==3) & mdm_dj==1
*/
la def MARSTAT 1 "Married" 2 "Living together" 3 "Widowed" 4 "Divorced or separated" ///
			   5 "Never married or in a union", replace
la val marstat_fdm_dj MARSTAT
la var marstat_fdm_dj "De jure PAFDM marital status"
*la var marstat_mdm_dj "De jure PAMDM marital status"

tab1 marstat*

*2.2. Number of activities each PDM participated in, by sex (0-6 activities)
tab1 v6201_1-v6201_5  //FDM economic activity variables
*tab1 m6201_01-m6201_06  //MDM economic activity variables
*for var v6201_01-v6201_06 m6201_01-m6201_06: recode X 2 3=0 7 9=., gen(Xx) //Recode activities 
for var v6201_1-v6201_5: recode X 2 3=0 7 9=., gen(Xx) //Recode activities 

egen fdm_actmiss=rmiss(v6201_1x-v6201_5x) 
replace fdm_actmiss=. if v6100d!=1
tab  fdm_actmiss
la var fdm_actmiss "Number of activities missing info for FDM"

/*
egen mdm_actmiss=rmiss(m6201_01x-m6201_06x) 
replace mdm_actmiss=. if m6100d!=1
tab  mdm_actmiss
la var mdm_actmiss "Number of activities missing info for MDM"
*/

egen fdm_acttot=rsum(v6201_1x-v6201_5x) if fdm_actmiss<5 // # of activities FDM participated in
*egen mdm_acttot=rsum(m6201_01x-m6201_06x) if mdm_actmiss<6 // # of activities MDM participated in

*la var mdm_acttot "Number of male PDM's econ activities"
la var fdm_acttot "Number of female PDM's econ activities"

tab1 ?dm_acttot

*2.3. PDM participation in 1+ economic activity, by sex
gen  fdm_actany=inrange(fdm_acttot,1,5) if fdm_acttot!=. & fdm_dj==1 //Female
*gen  mdm_actany=inrange(mdm_acttot,1,6) if mdm_acttot!=. & mdm_dj==1 //Male

*la var mdm_actany "Male PDM participated in 1+ econ activity"
la var fdm_actany "Female PDM participated in 1+ econ activity"

tab1 ?dm_actany

*2.4. Type of activities PDMs participated in
*FDM farm work
gen fdm_econ_farm=0 if v6100d==1
replace fdm_econ_farm=1 if (v6201_1==1 | v6201_2==1 | v6201_3==1 | v6201_4==1)
replace fdm_econ_farm=. if fdm_actmiss==6

*FDM non-farm work
gen fdm_econ_nonfarm=0 if v6100d==1
replace fdm_econ_nonfarm=1 if v6201_5==1
replace fdm_econ_nonfarm=. if fdm_actmiss==6

/*
*FDM wage/salary
gen fdm_econ_wage=0 if v6100d==1
replace fdm_econ_wage=1 if v6201_6==1
replace fdm_econ_wage=. if fdm_actmiss==6


*MDM farm work
gen mdm_econ_farm=0 if m6100d==1
replace mdm_econ_farm=1 if (m6201_01==1 | m6201_02==1 | m6201_03==1 | m6201_04==1)
replace mdm_econ_farm=. if mdm_actmiss==6

*MDM non-farm work
gen mdm_econ_nonfarm=0 if m6100d==1
replace mdm_econ_nonfarm=1 if m6201_05==1
replace mdm_econ_nonfarm=. if mdm_actmiss==6

*MDM wage/salary
gen mdm_econ_wage=0 if m6100d==1
replace mdm_econ_wage=1 if m6201_06==1
replace mdm_econ_wage=. if mdm_actmiss==6
*/

lab val ?dm_econ* YESNO
la var fdm_econ_farm "FDM farm work"
la var fdm_econ_nonfarm "FDM non-farm work"
*la var fdm_econ_wage "FDM wage/salary work"

/*
la var mdm_econ_farm "MDM farm work"
la var mdm_econ_nonfarm "MDM non-farm work"
la var mdm_econ_wage "MDM wage/salary work"
*/

tab1 *_econ_*
drop v6201_1x-v6201_5x
*drop v6201_01x-v6201_06x
*drop m6201_01x-m6201_06x

********************************************************************************
//STEP 3: CREATE HH-LEVEL DISAGGREGATES/VARIABLES
********************************************************************************
*3.1 Create variable for amount of agricultural land owned
tab1 v240*
gen agland_ownc=.
replace agland_ownc=1 if v240a==2
replace agland_ownc=2 if v240b<5
replace agland_ownc=3 if v240b>=5 & v240b<10
replace agland_ownc=4 if v240b>=10 & v240b<=95
la var agland_ownc "Hectares of ag land HH owns, category"
la def aglandc 1 "0 ha" 2 "<5 ha" 3 "5 to <10 ha" 4 "10+ ha"
la val agland_ownc aglandc
tab agland_ownc

*3.2 Create variable for amount of agricultural land HH owns or has rights over
tab1 v240*
gen agland_own=.
replace agland_own=0 if v240a==2
replace agland_own=v240b if v240b<95.0 & agland_own==.
la var agland_own "Ag land HH owns (hectares)"

tab1 v241*
gen agland_use=.
replace agland_use=0 if v241a==2
replace agland_use=v241b if v241b<95.0 & agland_use==.
la var agland_use "Ag land HH has rights to use (hectares)"

egen agland_tot=rsum(agland_own agland_use)
replace agland_tot=. if agland_own==. & agland_use==.
replace agland_tot=. if agland_own==. & agland_use==0
replace agland_tot=. if agland_own==0 & agland_use==.
la var agland_tot "Ag land available to HH (own+use), hectares"

gen farmsize=.
replace farmsize=0 if agland_tot>=0 & agland_tot<=5
replace farmsize=1 if agland_tot>5 & agland_tot!=.
la def farmsize 0 "Smallholder" 1 "Non-smallholder"
la val farmsize farmsize
la var farmsize "Farm size"
tab farmsize

*3.3 Create variables for livestock owned (fish and other not included)
tab1 v225 v226*

gen own_cow=.
replace own_cow=0 if v225==2 | v226a==0 | v226a==.
replace own_cow=1 if v226a>0 & v226a<=98
la val own_cow OWNS
la var own_cow "HH owns at least 1 cow or bull"

gen own_cattle=.
replace own_cattle=0 if v225==2 | v226b==0 | v226b==.
replace own_cattle=1 if v226b>0 & v226b<=98
la val own_cattle OWNS
la var own_cattle "HH owns at least 1 other cattle"

gen own_anycattle=0
replace own_anycattle=1 if (v226a>0 & v226a<=98) | (v226b>0 & v226b<=98)
la val own_anycattle OWNS
la var own_anycattle "HH owns at least 1 cow, bull, or other cattle"

gen own_horse=.
replace own_horse=0 if v225==2 | v226c==0 | v226c==.
replace own_horse=1 if v226c>0 & v226c<=98
la val own_horse OWNS
la var own_horse "HH owns at least 1 horse, donkey or mule"

gen own_goat=.
replace own_goat=0 if v225==2 | v226d==0 | v226d==.
replace own_goat=1 if v226d>0 & v226d<=98
la val own_goat OWNS
la var own_goat "HH owns at least 1 goat"

gen own_sheep=.
replace own_sheep=0 if v225==2 | v226e==0 | v226e==.
replace own_sheep=1 if v226e>0 & v226e<=98
la val own_sheep OWNS
la var own_sheep "HH owns at least 1 sheep"

gen own_goatsheep=0
replace own_goatsheep=1 if (v226e>0 & v226e<=98) | (v226d>0 & v226d<=98)
la val own_goatsheep OWNS
la var own_goatsheep "HH owns at least 1 goat or sheep"

gen own_poultry=.
replace own_poultry=0 if v225==2 | v226f==0 | v226f==.
replace own_poultry=1 if v226f>0 & v226f<=98
la val own_poultry OWNS
la var own_poultry "HH owns at least 1 chicken or other poultry"

gen own_none=.
replace own_none=0 if v225!=. 
replace own_none=1 if v225==2
replace own_none=1 if own_cow==0 & own_cattle==0 & own_horse==0 & own_goat==0 & ///
					  own_sheep==0 & own_poultry==0 & own_none==0
la val own_none YESNO
la var own_none "HH does not own any farm animals"

tab1 own*
/*
*3.4 Create variables for crop VCCs cultivated by de jure HH members 
gen vcchh_maize=0
replace vcchh_maize=1 if nvcc_maize_dj>0 
la var vcchh_maize "De jure HH member(s) cultivated maize"

gen vcchh_millet=0
replace vcchh_millet=1 if nvcc_millet_dj>0 
la var vcchh_millet "De jure HH member(s) cultivated millet"

gen vcchh_okra=0
replace vcchh_okra=1 if nvcc_okra_dj>0 
la var vcchh_okra "De jure HH member(s) cultivated okra"

gen vcchh_sheep=0
replace vcchh_sheep=1 if nvcc_sheep_dj>0 
la var vcchh_sheep "De jure HH member(s) raised sheep"

gen vcchh_crop_none=0
replace vcchh_crop_none=1 if vcchh_maize==0 & vcchh_millet==0 & vcchh_okra==0 
la var vcchh_crop_none "De jure HH member(s) did not cultivate any crop VCCs"

la val vcchh_* YESNO
tab1 vcchh*
*/

/*
*3.5 Shock experience index disaggregate
*The shock experience index disaggregate is created in the resilience do file.

*3.6 Wealth quintile disaggregate
*The wealth index disaggregate is created in the wealth index AWI do file.

*3.7 Poverty status disaggregate
*The poverty status disaggregate is created in the final (#8) poverty do file.

*3.8 Food insecurity disaggregate
*The food insecurity disaggregate is created using R to calculate the FIES indicator.

*/

********************************************************************************
//STEP 4 - DWELLING CHARACTERISTICS 
********************************************************************************
*4.1. Number of de jure household members per sleeping room
tab v204,m   //v204= # of sleeping room in the hhold. Check invalid and implausible values
gen roomsleep=v204 if v204<96  //96=other, 97=refusals, 98=DK, 99=missing
*Set the number of rooms to be 1 if value missing, assuming all HHs have at least one room
replace roomsleep=1 if v204==.
la var roomsleep "Number of rooms for sleeping in HH"

gen memsleep_dj= (hhsize_dj/roomsleep)  
la var memsleep_dj "Number of de jure HH members per sleeping room"
sum memsleep_dj

***CUSTOMIZED DWELLING VARIABLE CATEOGORIES FOR MALI QRE
*4.2. Household roof material 
tab v201,m
recode v201 (11/13=1 "Natural")     ///
            (21/24=2 "Rudimentary") ///
			(31/36=3 "Finished")    ///
			(96=4    "Other")       ///
			(97/max=.), gen (dw_roof)
la var dw_roof "Roof material of dwelling"
tab v201 dw_roof, m //verify

*4.3. Household floor material
tab v202,m
recode v202 (11/12=1 "Natural")     ///
            (21/22=2 "Rudimentary") ///
			(31/35=3 "Finished")   ///
			(96=4    "Other")      ///
			(97/max=.), gen (dw_floor)
la var dw_floor "Floor material of dwelling"
tab v202 dw_floor, m //verify

*4.4. Household exterior walls material
tab    v203,m
recode v203 (11/13=1 "Natural")     ///
            (21/26=2 "Rudimentary") ///
			(31/36=3 "Finished")    ///
			(96=4    "Other")       ///
			(97/max=.), gen (dw_wall)
la var dw_wall "Exterior wall material of dwelling"
tab v203 dw_wall, m //verify

*4.5. Solid cooking fuels
tab    v219,m
recode v219 (95=0 "No food cooked in HH") /// 
            (1/5=1 "Non solid fuel")      /// 
            (7/11=2 "Solid fuel")         ///
			(96=3 "Other")                ///
			(97/max=.), gen (dw_fuel)
gen dw_solidfuel=0 if dw_fuel!=.
replace dw_solidfuel=1 if dw_fuel==2
la var dw_solidfuel "HH uses solid fuels to cook"
tab v219 dw_solidfuel, m //verify

*4.6. Electricity
tab v222a,m
gen dw_elec=.
replace dw_elec=0 if v222a==2
replace dw_elec=1 if v222a==1 
la var dw_elec "HH has electricity"
tab dw_elec

********************************************************************************
//STEP 5: WASH
********************************************************************************

*5.1. Improved water source that is regularly available.
***INSTRUCTION: Check to determine if water from a tanker truck (61), cart with 
***small tank (71), and bottled water (91) are considered improved sources in the 
***survey country. Adjust the syntax accordingly.

*5.1a. Improved source
*CUSTOMIZED FOR MALI: 61 (Tanker truck) & 91 (Bottled water) are improved, 
*                     51 (Cart with small tank is not)
tab v211 
gen h2o_improved=inlist(v211, 11, 12 ,13, 14, 21, 31, 41, 51, 61, 91) 
la var h2o_improved "HH uses an improved drinking water source"

*5.1b. Regularly available source, that is, it is available year-round, and
*      was available everyday during the 2 weeks preceding the survey
tab1 v214 v215
gen h2o_regular=.
replace h2o_regular=0 if v214!=. & v215!=.
replace h2o_regular=1 if v214==1 & v215==1
la var h2o_regular "HH uses a regularly available drinking water source"
 
*5.1c. Improved source that is regularly available
gen h2o_imp_reg=.
replace h2o_imp_reg=0 if h2o_improved!=. | h2o_regular!=.
replace h2o_imp_reg=1 if h2o_improved==1 & h2o_regular==1 
 
la var h2o_imp_reg "HH uses a regularly available improved water source"
tab1 h2o_*

*5.2. Correct water treatment technology
/*
A. BOIL	
B. ADD BLEACH/CHLORINE	
C. STRAIN THROUGH A CLOTH	
D. USE WATER FILTER (CERAMIC/SAND/COMPOSITE/ETC)
E. SOLAR DISINFECTION	
F. LET IT STAND AND SETTLE	
*/
tab v217,m
gen v217a=strpos(v217,"A")>0 // 
la var v217a "Boil"
gen v217b=strpos(v217,"B")>0 //
la var v217b "ADD BLEACH/CHLORINE"
gen v217c=strpos(v217,"C")>0 //
la var v217c "STRAIN THROUGH A CLOTH"
gen v217d=strpos(v217,"D")>0 //
la var v217d "USE WATER FILTER (CERAMIC/SAND/COMPOSITE/ETC)"
gen v217e=strpos(v217,"E")>0 //
la var v217e "SOLAR DISINFECTION"
gen v217f=strpos(v217,"F")>0  //
la var v217f "LET IT STAND AND SETTLE"
*
gen h2o_corrtreat=(v217a==1 | v217b==1 | v217d==1 | v217e==1)
la var h2o_corrtreat "HH uses correct water treatment practice/tech"
tab h2o_corrtreat
*
*5.3. Soap and water at handwashing station
*****FEED THE FUTURE HANDWASHING INDICATOR*****
tab1 v205 v206 v207
*20/5/2022: fixed denominator to only include households that were observed (changed v205!=. to v205==1 or 2)
gen handwash=0 if v205==1 | v205==2
replace handwash=1 if v205==1 & v206==1 & v207==1
la var handwash "HH has soap and water at handwashing station"
tab handwash

*5.4. Improved sanitation facility - shared
tab1 v208 v209,m
tab v208 v209
gen san_impshared=inlist(v208,11,12,13,21,22,31) & v209==1
la var san_impshared "HH uses improved sanitation facility, shared"
tab san_impshared

*5.5. Improved sanitation facility - not shared
*****FEED THE FUTURE BASIC SANITATION INDICATOR*****
gen san_impnotshared=inlist(v208,11,12,13,21,22,31) & v209==2
la var san_impnotshared "HH uses improved sanitation facility, not shared"
tab san_impnotshared

*5.6. Unimproved sanitation facility
gen san_notimp=inlist(v208,14,15,23,41,51,61,96) 
la var san_notimp "HH uses unimproved sanitation facility"
tab san_notimp

*5.7. Open defecation
gen san_opendef=v208==61
la var san_opendef "HH practices open defecation"
tab san_opendef

tab1 san_*

********************************************************************************
// STEP 6. FINALIZE AND SAVE DATE FILE
********************************************************************************
*6.1 Label binary Yes/No values
*lab def YESNO 0 No 1 Yes
for var dw_solidfuel h2o_* san_* handwash fdm_actany mdm_actany own_* dw_elec : label value X YESNO

*6.2 Keep only HHs that completed the survey
drop if ahresult!=1

*6.3 Create cercle, region, and residence analytic variables
*clonevar cercle=a03c
*clonevar region=a03d
*clonevar urban_rural=ahtype

****Add shock severity, poverty, and wealth quintile disaggregates into file
merge 1:1 hhea hhnum using "$analytic\Results\Midline ZOI Survey wealthindex AWI.dta", keepusing(awiquint awi)
drop _merge
merge 1:1 hhea hhnum using "$analytic\Results\Midline ZOI Survey resilience.dta", keepusing(shock_sev)
drop _merge
merge 1:1 hhea hhnum using "C:\Users\26167\OneDrive - ICF\Mali ZOI Survey\Data\Analytic\Midline ZOI Survey PoorATUSD1.90 July20.2020.dta"
drop _merge

*Create a categorical poverty status variable that specifies HHs as poor, near-poor, or neither
numlabel, add
tab1 poor190 nearpoor190
gen pov_stat=.
replace pov_stat=1 if poor190==1
replace pov_stat=2 if nearpoor190==1
replace pov_stat=3 if poor190==0 & nearpoor190==0
tab pov_stat
la def pov_stat 1 "Living <$1.90 pov line" 2 "Living 100% to <125% $1.90 pov line" 3 "Living >=125% $1.90 pov line", modify
la val pov_stat pov_stat
lab var pov_stat "Poverty status, categorical ($1.90 USD)"
tab pov_stat

*6.4 Save household analytic data file
save "$analytic\Midline ZOI Survey household data analytic.dta", replace

*6.5 Add gendered HH type variable to person analytic data file and save
use "$analytic\Midline ZOI Survey persons data analytic.dta", clear
merge m:1 hhea hhnum using "$analytic\Midline ZOI Survey household data analytic.dta", keepus(ahtype a03c genhhtype* agland_ownc own_* vcchh_* pov_stat poor190 nearpoor190 awiquint shock_sev)
foreach x of varlist a03c genhhtype* agland_ownc own_* vcchh_* pov_stat poor190 nearpoor190 awiquint shock_sev {
  replace `x'=. if age==.
}
drop _merge
save "$analytic\Midline ZOI Survey persons data analytic.dta", replace

*6.6 Delete the demographics file and close the log file
di "Date:$S_DATE $S_TIME"
erase "$analytic\Temp\Midline ZOI Survey HH demographics RS.dta"
log  close
