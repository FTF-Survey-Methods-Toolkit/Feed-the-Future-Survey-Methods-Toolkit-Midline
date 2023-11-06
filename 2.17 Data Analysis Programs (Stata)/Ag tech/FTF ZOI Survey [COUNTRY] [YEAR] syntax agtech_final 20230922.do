/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
************************ AGRICULTURE TECH INDICATORS: ALL **********************
******************************** [COUNTRY] [YEAR] ******************************
********************************************************************************
Description: This code is intended to calculate the OVERALL 
targeted improved management practices and technologies indicator.

Syntax prepared by ICF, August 2019
Revised by ICF, September 2023

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. It must be adapted for the final country-specific questionnaire. 
The syntax was not tested using ZOI Survey data; therefore, double-check all 
syntax and results carefully and troubleshoot to resolve any issues identified.  
*******************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:   $analytic\Results\FTF ZOI Survey [Country] [Year] agtech_maize.dta
//				$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_fishpond.dta
//				$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.dta
//				$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_sheep.dta
//				$analytic\FTF ZOI Survey [Country] [Year] persons analytic data.dta
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_all.do 

cap log close 
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.log",replace
********************************************************************************
/*Note: Review all targeted improved management practices or technologies across 
all targeted VCCs during the year preceding the ZOI Survey. This can include 
crops (see Maize in 13.2.1), aquaculture (see Fishpond in 13.2.2), and livestock 
(see Dairy Cow in 13.2.3 and Sheep in 13.2.4). Before moving to the first step, 
perform the calculations for each additional targeted VCC value chain included in 
the ZOI Survey following the guidance in Sections 13.2.1-13.2.5, adapting as 
needed to reflect different crop or livestock value chains and improved management 
practices and technologies promoted in the ZOI. Note that these are only examples 
and MUST be adapted for the country context.
*/

*STEP 1. Create a data file, agtech_all, that includes one entry for each crop 
*		producer with variables for all targeted improved management practices and 
*		technologies and management practice and technology type categories for 
*		each crop and across crops. 

*Step 1.1 Create a data file that includes the data for all crop VCCs included in 
*		the survey. If there is more than one crop VCC included in the ZOI Survey, 
*		append all crop improved management practice and technology data files 
*		(e.g., as created in Step 11 of Section 13.2.1). If there is only one crop 
*		VCC, skip this step. Maize and millet are used here as an example. 
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.dta", clear 
append using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_millet.dta"

*Step 1.2. If there is more than one crop VCC included in the survey, aggregate 
*		the dataset so that there is only one record per crop producer – that is, 
*		if there are multiple records per crop producer, collapse the dataset 
*		and sum the values for each variable that begins with `imp', resulting 
*		in a dataset with one record per crop producer with the summed total of 
*		each improved management practice and technology that producer adopted 
*		across all crop VCCs. If there is only one crop VCC, skip this step.
collapse (sum) imp_*, by(hhea hhnum m1_line)
sum 	imp_*
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.dta",replace

*Step 1.3. Create a binary variable for each targeted management practice or 
*		technology that has "crop" in the variable name instead of the name of the 
*		crop (e.g. "maize") and captures whether the crop producer used the 
*		practice or technology for any of the crops for which it is targeted. 
*		The first variable created below in this step, imp_crop_impseed, applies to 
*		both maize and millet. The second variable created below in this step, 
*		imp_crop_maize_mulchweed, applies only to maize, but a variable is still 
*		created so that "crop" is consistently included in the name of all 
*		variables that will used for the overall indicator calculation. 
*		Be sure to expand the template syntax below as applicable to create a 
*		variable for each targeted improved management practice and technology. 
*		This should include the variables created in Step 3 of Section 13.2.1
gen 	imp_crop_impseed=0
replace imp_crop_impseed=1 if (imp_maize_impseed==1 | imp_millet_impseed==1)
la val 	imp_crop_impseed YESNO
la var	imp_crop_impseed "Used improved seeds (maize, millet)"
tab     imp_crop_impseed

gen 	imp_crop_mulchweed=imp_maize_mulchweed
la val 	imp_crop_mulchweed YESNO
la var 	imp_crop_mulchweed "Used mulching to control weeds (maize only)"
tab 	imp_crop_mulchweed

*Step 1.4. If there is only one crop VCC, skip to the next step. If there is more 
*		than one crop VCC, create a binary variable for each management practice 
*		and technology type category without the name of the crop in the variable 
*		name and save the data file. Be sure to expand the template syntax below to 
*		create a variable for each management practice and technology type category 
*		applicable to the crop value chains included in the survey. This should 
*		include the variables created in Step 4 of Section 13.2.1
gen 	imp_genetics=0
replace imp_genetics=1 if (imp_maize_genetics==1 | imp_millet_genetics==1)
la val 	imp_genetics YESNO
la var	imp_genetics "Used targeted improved crop genetics practices (maize, millet)"
tab     imp_genetics

gen 	imp_pest=imp_maize_pest
la val 	imp_pest YESNO
la var 	imp_pest "Used targeted improved pest management (maize only)"
tab 	imp_pest

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.dta",replace

*Step 1.5. If there is more than one crop VCC, skip this step. If there is only one 
*		crop VCC, clone the variable for each management practice and technology 
*		type category and save the data file. Be sure to expand the template syntax 
*		below to create a variable for each management practice and technology type 
*		category applicable to the crop value chains. This should include the 
*		variables created in Step 4 of Section 13.2.1.
clonevar imp_genetics=imp_maize_genetics
clonevar imp_pest=imp_maize_pest

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all.dta",replace

*STEP 2. Skip to Step 3 if fishponds are not a value chain included in the survey. 
*		If fishponds are a value chain, create the variables needed for the overall 
*		indicator calculation and then add an observation for each fishpond 
*		producer to the agtech_all data file created in Step 1.5. 

*Step 2.1. Load the fishpond data file created in Step 11 of Section 13.2.2 
*		and create a binary variable for each management practice and technology 
*		type category without `fish' in the variable name and save the data file. 
*		Be sure to expand the template syntax below to create a variable for each 
*		management practice and technology type category applicable to fishponds. 
*		Most targeted improved practices and technologies will be promoted under 
*		aquaculture management (imp_aquam), but some may be promoted under other 
*		management practice and technology type categories, such as "other" 
*		(imp_other). 
use "$analytic\Results\FTF ZOI Survey [Country] [Year] agtech_fishpond.dta", clear
clonevar imp_aquam=imp_fish_aquam
clonevar imp_other=imp_fish_other

save "$analytic\Results\FTF ZOI Survey [Country] [Year] fishpond_all.dta", replace

*Step 2.2. Append the fishpond data file to the agtech_all data file and save the 
*		data file. Skip this step if fishponds are not a VCC included in the survey.
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",clear
append using "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] fishpond_all"
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",replace

*STEP 3. Skip to Step 4 if there are no livestock value chains included in the 
*		survey. If there are one or more livestock value chains, create a data 
*		file, agtech_livestock_all, that includes one entry for each livestock 
*		producer with variables for all targeted improved management practices 
*		and technologies and management practice and technology type categories 
*		for each livestock and across livestock. Then add one observation for 
*		each livestock producer to the agtech_all data file created in Step 1.5 
*		(and modified in Step 2.2, if applicable).

*Step 3.1. If there is only one livestock VCC, skip to Step 3.3. Create a data 
*		file that includes the data for all livestock VCCs included in the survey. 
*		Append all livestock targeted improved management practice and technology 
*		data files (e.g., as created in Step 11 of Sections 13.2.3 and 13.3.3) if 
*		there is more than one livestock VCC. Dairy cows and sheep are used here 
*		as an example. 
use  "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_dairycow.dta", clear
append using "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_sheep.dta"

*Step 3.2. If there is more than one livestock VCC included in the survey, 
*		aggregate the dataset so that there is only one record per livestock 
*		producer – that is, if there are multiple records per livestock producer, 
*		collapse the dataset and sum the values for each variable that begins 
*		with `imp', resulting in a dataset with one record per livestock producer 
*		with the summed total of each improved management practice and technology 
*		that producer adopted across all livestock VCCs. If there is only one 
*		livestock VCC, skip this step. 
collapse (sum) imp_*, by(hhea hhnum m1_line)
sum 	imp_*
save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] livestock_all",replace

*Step 3.3. Create a binary variable for each targeted management practice or 
*		technology that has "ls" in the variable name instead of the name of the 
*		livestock (e.g., "sheep") and that captures whether the livestock 
*		producer used the practice or technology for any of the livestock for 
*		which it is targeted. 
*		The first variable created below in this step, imp_ls_artinsem, applies 
*		to both dairy cows and sheep. The second variable created below in this 
*		step, imp_ls_waste, applies only to dairy cows, but a variable is still 
*		created so that "ls" is consistently included in the name of all 
*		variables that will used for the overall indicator calculation.
*		Be sure to expand the template syntax below as applicable to create a 
*		variable for each targeted improved management practice and technology. 
*		This should include the variables created in Step 3 of 
*		Sections 13.2.3 and 13.2.4
gen 	imp_ls_artinsem=0
replace imp_ls_artinsem=1 if (imp_dairy_artinsem==1 | imp_sheep_artinsem==1)
la val 	imp_ls_artinsem YESNO
la var	imp_ls_artinsem "Used artificial insemination to breed (sheep, dairy cows)"
tab     imp_ls_artinsem

gen 	imp_lswaste=imp_dairy_lswaste
la val 	imp_lswaste YESNO
la var 	imp_lswaste "Used improved waste management (dairy cows only)"
tab 	imp_lswaste

save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] livestock_all",replace

*Step 3.4. Create a binary variable for each category without the name of the VCC in the variable name and save the data file. Be sure to expand the template syntax below to create a variable for each category applicable to the livestock value chains included in the survey. This should include the variables created in Step 4 of Sections 14.2.3 and 14.2.4. Most targeted practices will be targeted under livestock management (imp_livestm), but some may be targeted under other categories, such as imp_fsafety or imp_other. 

gen 	imp_livestm=0
replace imp_livestm=1 if (imp_dairy_livestm==1 | imp_sheep_livestm==1)
la val 	imp_livestm YESNO
la var	imp_livestm "Used improved livestock management practices (sheep, dairy cows)"
tab     imp_livestm

gen 	imp_fsafety=0
replace imp_fsafety=1 if (imp_dairy_fsafety==1 | imp_sheep_fsafety==1)
la val 	imp_fsafety YESNO
la var	imp_fsafety "Used improved food safety practices (sheep, dairy cows)"
tab     imp_fsafety

gen 	imp_other=0
replace imp_other=1 if (imp_dairy_other==1 | imp_sheep_other==1)
la val 	imp_other YESNO
la var	imp_other "Used other improved practice or technology (sheep, dairy cows)" 
tab     imp_other

save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] livestock_all",replace

*Step 3.5. If there is more than one livestock VCC included, skip this step. If there is only one livestock VCC included in the ZOI Survey, clone the variable for each category and save the date file. Be sure to expand the template syntax below to create a variable for each category applicable to livestock value chains. This should include the variables created in Step 4 of Sections 14.2.3 and 14.2.4. Most targeted practices and technologies will be targeted under livestock management (imp_livestm), but some may be targeted under other categories, such as imp_fsafety or imp_other. 
 
clonevar imp_livestm=imp_dairy_livestm
clonevar imp_fsafety=imp_dairy_fsafety
clonevar imp_other=imp_dairy_other

save "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] livestock_all",replace

*Step 3.6. Append the livestock data file to the crop data file. 
*		Save full VCC data file.
use "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",clear
append using "$analytic\Temp\FTF ZOI Survey [COUNTRY] [YEAR] livestock_all"
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",replace

*STEP 4. Aggregate the full VCC dataset so that there is only one record per 
*		producer – that is, collapse the dataset and sum the values for each 
*		variable that begins with `imp', resulting in a dataset with one record 
*		per producer with the summed total of each improved management practice 
*		and technology that producer adopted across all VCCs. The full VCC data 
*		file should now include variables for each targeted improved practice, 
*		each management practice and technology type for all crops, aquaculture, 
*		and all livestock included in the ZOI country survey. 
collapse (sum) imp_*, by(hhea hhnum m1_line)
sum 	imp_*
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",replace

*STEP 5. Set the denominator for each targeted improved management practice and 
*		technology variable and category variable to the total number of VCC 
*		farmers (n) who completed the survey. That is, for each practice and 
*		category, set all missing answers to 0 (no). Adapt this step as needed to 
*		reflect the crop, livestock, or fishpond value chains and improved  
*		management practices and technologies promoted in the ZOI country context. 
foreach v of var imp_crop_* imp_ls_* imp_fish_* imp_genetics imp_culture imp_ecosys imp_pest imp_fert imp_irrig imp_water imp_cmitigate imp_cadapt imp_markdist imp_pharvest imp_valadd imp_fsafety imp_other imp_fish_aquam imp_livestm {
		replace `v'=0 if `v'==.
		tab `v'
}

*STEP 6. Create a variable list (IMP_PRACTICE) that includes all targeted improved 
*		management practice and technology variables. Adapt this step as needed to 
*		reflect the crop, livestock, or fishpond value chains and improved management 
*		practices and technologies promoted in the ZOI country context. 
global IMP_PRACTICE imp_crop_impseed imp_crop_plantrow imp_crop_orgfert imp_crop_mulchsoil imp_crop_terrace imp_crop_mulchweed imp_crop_pestchem imp_crop_irrigdrip imp_crop_irrigpump imp_crop_zerotill imp_crop_agdealerseed imp_crop_soldhusks imp_crop_mechdry imp_crop_hermetic imp_crop_warehouse imp_crop_mechshuck imp_crop_mechtill imp_crop_mechharvest imp_ls_artinsem imp_dairy_selectbreed imp_ls_healthserv imp_dairy_medicine imp_ls_vaccinated imp_ls_prevmast imp_ls_roof imp_ls_fedbyprod imp_ls_fedconcentrate imp_ls_fedvitmin imp_ls_pipedwater imp_ls_pasture imp_ls_collmanure imp_ls_fodder imp_ls_pasteurized imp_ls_soldmilk imp_ls_soldmanure imp_ls_records imp_fish_ponddrain imp_fish_pondmanure imp_fish_certhatch imp_fish_species imp_fish_fedsupp imp_fish_diseasecontrol imp_fish_pondmonqual imp_fish_pondmainqual imp_fish_separate imp_fish_partharv imp_fish_records imp_fish_useguts

*STEP 7. Create a count variable to capture the total number of of targeted 
*		improved management practices or technologies used (imp_tot_vcc).
egen 	imp_tot_vcc = rowtotal($IMP_PRACTICE)
lab var imp_tot_vcc "Number of targeted improved practices and technologies used (total)"
tab 	imp_tot_vcc

*STEP 8. Create a categorical variable to categorize producers by the number of 
*		targeted improved practices or technologies they used (imp_cat_vcc) for 
*		Table 7.1.4. The categories used can be adapted based on the survey data; 
*		they do not have to be 0, 1-3, 4-6, 7-9, and 10 or more practices or 
*		technologies.
gen 	imp_cat_vcc=.
replace imp_cat_vcc=0 if (imp_tot_vcc==0)
replace imp_cat_vcc=1 if (imp_tot_vcc>=1 & imp_tot_vcc<=3)
replace imp_cat_vcc=2 if (imp_tot_vcc>=4 & imp_tot_vcc<=6)
replace imp_cat_vcc=3 if (imp_tot_vcc>=7 & imp_tot_vcc<=9)
replace imp_cat_vcc=4 if (imp_tot_vcc>=10 & imp_tot_vcc!=.)
la define cat_vcc 0 "None" 1 "1-3 practices" 2 "4-6 practices" 3 "7-9 practices" ///
		4 "10+ practices"
la val 	imp_cat_vcc cat_vcc
la var 	imp_cat_vcc "Number of targeted improved practices and technologies used (total, categorical)"
tab 	imp_cat_vcc

*STEP 9. Create a binary variable to indicate if the producers used any targeted 
*		improved practices or technologies (imp_any_vcc).
gen 	imp_any_vcc=0
replace imp_any_vcc=1 if (imp_tot_vcc>0 & imp_tot_vcc!=.)
lab var imp_any_vcc "Used any targeted improved management practice and technology (total)"
tab 	imp_any_vcc

*STEP 10. Create a variable list (IMP_TYPE) that includes all applicable management 
*	      practice and technology type variables. Adapt this step as needed to 
*		  reflect the crop, livestock, or fishpond value chains and improved 
*		  management practices and technologies promoted in the ZOI country context. 
global IMP_TYPE imp_genetics imp_culture imp_ecosys imp_pest imp_fert imp_irrig imp_water imp_cmitigate imp_cadapt imp_markdist imp_pharvest imp_valadd imp_fsafety imp_other imp_fish_aquam imp_livestm 

*STEP 11. If not already in the data file, add the de jure household member status, 
*	  	  age, sex, producer weight, and sample stratum variables and as well as 
*		  all variables that include `vcc' in the name from the individual-level 
*		  analytic data file needed to calculate the overall indicator and its 
*		  disaggregates and save the data file.
mmerge 	hhea hhnum m1_line using "$analytic\FTF ZOI Survey [Country] [Year] persons analytic data", ukeep(hhea hhnum m1_line hhmem_dj sex age15_29 wgt_vcc strata *vcc*) 
tab 	_merge
drop 	_merge
tab1 	sex age15_29 vcc_*
save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_all",replace
 
*STEP 12. Apply the producer sampling weight to adjust for the survey design, and 
*		calculate the indicator for producers who are de jure household members 
*		using the imp_any_vcc analytic variable. Repeat the calculation using the 
*		sex, age (under 30 years of age, 30 years of age or older), and improved 
*		management practices and technology type disaggregates. Note that the 
*		commodity disaggregate was already calculated in the individual VCC syntax files. 
svyset 	hhea [pw=wgt_vcc], strata(strata) 
svy, 	subpop(hhmem_dj): tab imp_any_vcc 
svy, 	subpop(hhmem_dj): tab imp_any_vcc sex, col 
svy, 	subpop(hhmem_dj): tab imp_any_vcc age15_29, col 
	   	   
foreach x of varlist $IMP_TYPE $IMP_PRACTICE{
		svy, subpop(hhmem_dj): tab `x', col 
}  	   

*Step 13. Calculate the percentage distribution of value chain commodity 
*		producers who are de jure household members by the number of targeted 
*		improved management practices or technologies they used during the 12 
*		months preceding the survey using imp_cat_vcc. Repeat using producers' 
*		age (under 30 years of age, 30 years of age or older) and sex as 
*		disaggregates.
svy, subpop(hhmem_dj): tab imp_cat_vcc
svy, subpop(hhmem_dj): tab imp_cat_vcc age15_29y, col 
svy, subpop(hhmem_dj): tab imp_cat_vcc sex, col