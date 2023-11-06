/*****************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS **************
********************** AGRICULTURE TECH INDICATORS: MAIZE ********************
***************************** [COUNTRY] [YEAR] *******************************
******************************************************************************
Description: This code is intended to calculate the MAIZE component of the 
targeted improved management practices and technologies indicator.

Syntax prepared by ICF, August 2019
Revised by ICF, September 2023

This syntax file is for use with the core Feed the Future ZOI Midline Survey 
questionnaire. It must be adapted for the final country-specific questionnaire.  
*******************************************************************************/
set   more off
clear all
macro drop _all

//DIRECTORY PATH
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:   $analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta
//Log Outputs:	$analtyic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.log	
//Output data:	$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax agtech_maize.do 

cap log close 
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.log",replace
********************************************************************************
/*STEP 1. Review the maize module (Module 7.1) in the country-customized ZOI 
Survey questionnaire and identify questions that relate to improved 
management practices and technologies being promoted in the ZOI. Determine 
which response options would be considered targeted improved management 
practices and technologies, and also determine what management practice or 
technology type or types the targeted improved management practices and 
technologies are promoted under. 

If Feed the Future is promoting a management practice or technology for 
multiple benefits, be sure that producers applying the management practice 
or technology are reported under each type for which the technology is being 
promoted. Conversely, if Feed the Future is promoting a management practice 
or technology for a single benefit though it could be promoted for multiple 
benefits, be sure that producers applying the management practice or 
technology are reported under only the one type for which the technology is 
being promoted.
*/

*STEP 2. Prepare the data 		

*Load individual level data file
use "$analytic\FTF ZOI Survey [Country] [Year] persons data analytic.dta", clear

*Review the variables already created and included in the 
*		persons-level data file that flags maize farmers (vcc_maize) who 
*		completed the maize module. 
*		(See Section 4.6.3 of the Guide to FTF Midline Statistics)     
tab 	vcc_maize

*Drop all farmers from the data who did not cultivate maize in the 
*		year preceding the survey and drop variables not required to 
*		generate maize specific variables.
keep if vcc_maize==1 
keep 	hhea hhnum m1_line strata sex age15_29y hhmem_dj wgt_maize vcc_maize v71* 

*STEP 3. Create binary variables for each targeted improved management 
*		practice and technology promoted in the surveyed area to flag 
*		farmers who used targeted improved management 
*		practices/technologies to cultivate maize (Yes=1, No=0). 

*Step 3.1. Create a binary variable to flag producers who used improved 
*		maize seeds (imp_maize_impseed). 
gen     imp_maize_impseed=0
replace imp_maize_impseed=1 if strpos(v7107,"B")>0 | strpos(v7107,"C")>0
la val  imp_maize_impseed YESNO
la var  imp_maize_impseed "Used improved or hybrid maize seeds"
tab		imp_maize_impseed

*Step 3.2. Create a binary variable to flag producers who planted their 
*		maize in rows (imp_maize_plantrow). 
gen     imp_maize_plantrow=0
replace imp_maize_plantrow=1 if v7109==1 | v7109==3
la val  imp_maize_plantrow YESNO
la var  imp_maize_plantrow "Planted maize in rows"
tab     imp_maize_plantrow

*Step 3.3. Create a binary variable to flag producers who used organic 
*		fertilizer to cultivate their maize (imp_maize_orgfert).
gen 	imp_maize_orgfert=0
replace imp_maize_orgfert=1 if strpos(v7111b,"A")>0 | strpos(v7111b,"C")>0 
la val 	imp_maize_orgfert YESNO
la var	imp_maize_orgfert "Used organic fertilizer on maize"
tab     imp_maize_orgfert

*Step 3.4. Create a binary variable to flag producers who used mulching to 
*		manage soil and water for their maize crop (imp_maize_mulchsoil).
gen 	imp_maize_mulchsoil=0
replace imp_maize_mulchsoil=1 if v7121_b==1 
la val 	imp_maize_mulchsoil YESNO
la var	imp_maize_mulchsoil "Used mulching for soil and water management for maize"
tab     imp_maize_mulchsoil

*Step 3.5. Create a binary variable to flag producers who used terracing, 
*		soil bands, or trenches to cultivate their maize (imp_maize_terrace).
gen 	imp_maize_terrace=0
replace imp_maize_terrace=1 if v7121a==1 | v7121c==1
la val	imp_maize_terrace YESNO
la var	imp_maize_terrace "Used terracing, soil bands, or trenches on maize plots"
tab     imp_maize_terrace

*Step 3.6. Create a binary variable to flag maize producers who practices 
*		mulching to control weeds on their maize plots (imp_maize_mulchweed).
gen 	imp_maize_mulchweed=0
replace imp_maize_mulchweed=1 if strpos(v7119,"C")>0 
la val 	imp_maize_mulchweed YESNO
la var	imp_maize_mulchweed "Practiced mulching to control weeds on maize plots"
tab     imp_maize_mulchweed

*Step 3.7. Create a binary variable to flag producers who used chemical pest 
*		control, including herbicides, to cultivate their maize 
*		(imp_maize_pestchem).
gen 	imp_maize_pestchem=0
replace imp_maize_pestchem=1 if v7115==1 | strpos(v7119,"B")>0
la val 	imp_maize_pestchem YESNO
la var	imp_maize_pestchem "Used chemical pest control on maize"
tab     imp_maize_pestchem

*Step 3.8. Create a binary variable to flag producers who used drip 
*		irrigation on their maize plots (imp_maize_irrigdrip).
gen 	imp_maize_irrigdrip=0
replace imp_maize_irrigdrip=1 if strpos(v7123,"A")>0
la val 	imp_maize_irrigdrip YESNO
la var	imp_maize_irrigdrip "Used drip irrigation on maize plots"
tab     imp_maize_irrigdrip

*Step 3.9. Create a binary variable to flag producers who used pump 
*		irrigation on their maize plots (imp_maize_irrigpump).
gen 	imp_maize_irrigpump=0
replace imp_maize_irrigpump=1 if strpos(v7123,"D")>0
la val 	imp_maize_irrigpump YESNO
la var	imp_maize_irrigpump "Used pump irrigation on maize plots"
tab     imp_maize_irrigpump

*Step 3.10. Create a binary variable to flag producers who used zero tillage 
*		land preparation (imp_maize_zerotill).
gen 	imp_maize_zerotill=0
replace imp_maize_zerotill=1 if strpos(v7101,"B")>0
la val 	imp_maize_zerotill YESNO
la var	imp_maize_zerotill "Used zero tillage land preparation for maize plots"
tab     imp_maize_zerotill

*Step 3.11. Create a binary variable to flag producers who bought seeds from 
*		an agrodealer with either cash or a voucher (imp_maize_agdealerseed).
gen 	imp_maize_agdealerseed=0
replace imp_maize_agdealerseed=1 if v7106==4 | v7106==5
la val 	imp_maize_agdealerseed YESNO
la var	imp_maize_agdealerseed "Bought maize seeds from an ag dealer" 
tab     imp_maize_agdealerseed

*Step 3.12. Create a binary variable to flag producers who sold maize stalks 
*		or sold or traded maize husks (imp_maize_soldhusks).
gen 	imp_maize_soldhusks=0
replace imp_maize_soldhusks=1 if strpos(v7124a,"G")>0 | strpos(v7124c,"E")>0
la val 	imp_maize_soldhusks YESNO
la var	imp_maize_soldhusks "Sold maize stalks or sold/traded maize husks"
tab     imp_maize_soldhusks

*Step 3.13. Create a binary variable to flag producers who used solar or 
*		mechanized dryers to dry their maize (imp_maize_mechdry).
gen 	imp_maize_mechdry=0
replace imp_maize_mechdry=1 if strpos(v7126,"H")>0 | strpos(v7126,"I")>0
la val 	imp_maize_mechdry YESNO
la var	imp_maize_mechdry "Used solar or mechanized dryers for maize"
tab     imp_maize_mechdry

*Step 3.14. Create a binary variable to flag producers who used improved 
*		storage containers—hermetic bags (imp_maize_hermetic).
gen 	imp_maize_hermetic=0
replace imp_maize_hermetic=1 if strpos(v7129,"C")>0 
la val 	imp_maize_hermetic YESNO
la var	imp_maize_hermetic "Used hermetic bags for maize"
tab     imp_maize_hermetic

*Step 3.15. Create a binary variable to flag producers who used improved 
*		storage practices—stored in a warehouse (imp_maize_warehouse).
gen 	imp_maize_warehouse=0
replace imp_maize_warehouse=1 if v7130e==1
la val 	imp_maize_warehouse YESNO
la var	imp_maize_warehouse "Stored maize in a warehouse"
tab     imp_maize_warehouse

*Step 3.16. Create a binary variable to flag producers who shelled their 
*		maize by machine (imp_maize_mechshuck).
gen 	imp_maize_mechshuck=0
replace imp_maize_mechshuck=1 if strpos(v7127,"C")>0
la val 	imp_maize_mechshuck YESNO
la var	imp_maize_mechshuck "Shelled maize by machine"
tab     imp_maize_mechshuck

*Step 3.17. Create a binary variable to flag producers who prepared their 
*		maize plots using a motorized tiller or tractor (imp_maize_mechtill).
gen 	imp_maize_mechtill=0
replace imp_maize_mechtill=1 if strpos(v7105,"C")>0 | strpos(v7105,"D")>0
la val 	imp_maize_mechtill YESNO
la var	imp_maize_mechtill "Prepared maize plots with motorized tiller or tractor"
tab     imp_maize_mechtill

*Step 3.18. Create a binary variable to flag producers who used a machine to 
*		harvest their maize (imp_maize_mechharvest).
gen 	imp_maize_mechharvest=0
replace imp_maize_mechharvest=1 if v7124==2 | v7124==3
la val 	imp_maize_mechharvest YESNO
la var	imp_maize_mechharvest "Used a machine to harvest maize"
tab     imp_maize_mechharvest

*STEP 4. Create binary variables for each management practice and technology 
*		practice type to flag producers who applied any targeted improved 
*		practice or technology promoted by Feed the Future under the type to 
*		cultivate maize (yes=1, no=0). 

*Step 4.1. Create a binary variable to flag maize producers who applied a 
*		targeted improved practice or technology related to crop genetics 
*		(imp_maize_genetics). 
gen 	imp_maize_genetics=0
replace imp_maize_genetics=1 if imp_maize_impseed==1
la val 	imp_maize_genetics YESNO
la var 	imp_maize_genetics "Applied targeted improved crop genetics practices"
tab 	imp_maize_genetics

*Step 4.2. Create a binary variable to flag maize producers who applied a 
*		targeted improved practice or technology related to cultural 
*		practices (imp_maize_culture). 
gen 	imp_maize_culture=0
replace imp_maize_culture=1 if imp_maize_plantrow==1
la val 	imp_maize_culture YESNO
la var 	imp_maize_culture "Applied targeted improved cultural practices"
tab 	imp_maize_culture

*Step 4.3. Create a binary variable to flag maize producers who applied a 
*		targeted improved practice or technology related to natural resource 
*		or ecosystem management (imp_maize_ecosys).
gen 	imp_maize_ecosys=0
replace imp_maize_ecosys=1 if imp_maize_orgfert==1 | imp_maize_mulchsoil==1 | ///
		imp_maize_terrace==1 
la val 	imp_maize_ecosys YESNO
la var 	imp_maize_ecosys "Applied targeted improved natural resources and ecosystem management practices"
tab 	imp_maize_ecosys

*Step 4.4. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to improved pest and disease 
*		management (imp_maize_pest).
gen 	imp_maize_pest=0
replace imp_maize_pest=1 if imp_maize_mulchweed==1 | imp_maize_pestchem==1
la val 	imp_maize_pest YESNO
la var 	imp_maize_pest "Applied targeted improved pest and disease management practices"
tab 	imp_maize_pest 

*Step 4.5. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to soil-related fertility and 
*		conservation (imp_maize_fert).
gen 	imp_maize_fert=0
replace imp_maize_fert=1 if imp_maize_mulchsoil==1 | imp_maize_terrace==1 
la val 	imp_maize_fert YESNO
la var 	imp_maize_fert "Applied targeted improved soil related fertility and conservation practices"
tab 	imp_maize_fert 

*Step 4.6. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to irrigation (imp_maize_irrig).
gen 	imp_maize_irrig=0
replace imp_maize_irrig=1 if imp_maize_irrigdrip==1 | imp_maize_irrigpump==1 
la val 	imp_maize_irrig YESNO
la var 	imp_maize_irrig "Applied targeted improved irrigation practices"
tab 	imp_maize_irrig

*Step 4.7. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to water management 
*		(non-irrigation) (imp_maize_water).
gen 	imp_maize_water=0
replace imp_maize_water=1 if imp_maize_mulchsoil==1 | imp_maize_terrace==1
la val 	imp_maize_water YESNO
la var 	imp_maize_water "Applied targeted improved water management (non-irrigation) practices" 
tab 	imp_maize_water 

*Step 4.8. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to climate mitigation 
*		(imp_maize_cmitigate).
gen 	imp_maize_cmitigate=0
replace imp_maize_cmitigate=1 if imp_maize_irrigdrip==1 | imp_maize_zerotill==1 
la val 	imp_maize_cmitigate YESNO
la var 	imp_maize_cmitigate "Applied targeted improved climate mitigation practices"
tab		imp_maize_cmitigate 

*Step 4.9. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to climate adaption 
*		(imp_maize_cadapt).
gen 	imp_maize_cadapt=0
replace imp_maize_cadapt=1 if imp_maize_impseed==1 | imp_maize_irrigpump==1 
la val 	imp_maize_cadapt YESNO
la var 	imp_maize_cadapt "Applied targeted improved climate adaption practices"
tab 	imp_maize_cadapt

*Step 4.10. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to marketing and distribution 
*		(imp_maize_markdist).
gen 	imp_maize_markdist=0
replace imp_maize_markdist=1 if imp_maize_agdealerseed==1 | imp_maize_soldhusks==1
la val 	imp_maize_markdist YESNO
la var 	imp_maize_markdist "Applied targeted improved marketing and distribution practices"
tab 	imp_maize_markdist 

*Step 4.11. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to post-harvest handling and 
*		storage (imp_maize_pharvest).
gen 	imp_maize_pharvest=0
replace imp_maize_pharvest=1 if imp_maize_mechdry==1 | imp_maize_hermetic==1 | ///
		imp_maize_warehouse==1
la val 	imp_maize_pharvest YESNO
la var 	imp_maize_pharvest "Applied targeted improved post-harvest handling and storage practices"
tab 	imp_maize_pharvest 

*Step 4.12. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to value-added processing 
*		(imp_maize_valadd).
gen 	imp_maize_valadd=0
replace imp_maize_valadd=1 if imp_maize_mechshuck==1
la val 	imp_maize_valadd YESNO
la var 	imp_maize_valadd "Applied targeted improved value-added processing practices"
tab 	imp_maize_valadd 

*Step 4.13. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to food safety (imp_maize_fsafety).
gen 	imp_maize_fsafety=0
replace imp_maize_fsafety=1 if imp_maize_hermetic==1 
la val 	imp_maize_fsafety YESNO
la var 	imp_maize_fsafety "Applied targeted improved food safety practices"
tab 	imp_maize_fsafety 

*Step 4.14. Create a binary variable to flag maize producers who applied a targeted 
*		improved practice or technology related to other management practices or 
*		technologies (imp_maize_other).
gen 	imp_maize_other=0
replace imp_maize_other=1 if imp_maize_mechtill==1 | imp_maize_mechharvest==1 
la val 	imp_maize_other YESNO
la var 	imp_maize_other "Applied other targeted improved management practices"
tab 	imp_maize_other 

*STEP 5. Create a variable list (IMP_maize) that includes all applicable improved 
*		management practice and technology practices for maize. Adapt this step as 
*		needed to reflect different crop value chains and improved management 
*		practices and technologies promoted in the ZOI country context. 
global IMP_maize imp_maize_impseed imp_maize_plantrow imp_maize_orgfert imp_maize_mulchsoil imp_maize_terrace imp_maize_mulchweed imp_maize_pestchem imp_maize_irrigdrip imp_maize_irrigpump imp_maize_zerotill imp_maize_agdealerseed imp_maize_soldhusk imp_maize_mechdry imp_maize_hermetic imp_maize_warehouse imp_maize_mechshuck imp_maize_mechtill imp_maize_mechharvest

*STEP 6. Create a count variable to capture the total number of targeted improved 
*		practices or technologies each maize producer applied to cultivate maize 
*		(imp_tot_maize). That is, create a variable that sums all the variables in 
*		the (IMP_maize) variable list created in Step 5.
egen 	imp_tot_maize = rowtotal ($IMP_maize)
la var 	imp_tot_maize "Number of targeted improved practices and technologies applied (maize)"
tab 	imp_tot_maize

*Step 7. Create a categorical variable to categorize maize producers by the number 
*		of targeted improved practices or technologies they applied (imp_cat_maize) 
*		for Table 7.2.4. The categories used should be adapted based on the survey 
*		data; they do not have to be 0, 1-3, 4-6, 7-9, and 10 or more targeted 
*		improved practices or technologies.
gen 	imp_cat_maize=.
replace imp_cat_maize=0 if (imp_tot_maize==0)
replace imp_cat_maize=1 if (imp_tot_maize>=1 & imp_tot_maize<=3)
replace imp_cat_maize=2 if (imp_tot_maize>=4 & imp_tot_maize<=6)
replace imp_cat_maize=3 if (imp_tot_maize>=7 & imp_tot_maize<=9)
replace imp_cat_maize=4 if (imp_tot_maize>=10 & imp_tot_maize!=.)
la define cat_vcc 0 "None" 1 "1-3 practices" 2 "4-6 practices" 3 "7-9 practices" ///
		4 "10+ practices"
la val 	imp_cat_maize cat_vcc
la var 	imp_cat_maize "Number of targeted improved practices and technologies applied (maize, categorical)"
tab 	imp_cat_maize

*STEP 8. Create a binary variable to indicate if each farmer applied any targeted 
*		improved management practices or technologies to cultivate maize 
*		(imp_any_maize).
gen 	imp_any_maize=0
replace imp_any_maize=1 if imp_tot_maize>0 & imp_tot_maize!=.
la val 	imp_any_maize YESNO
la var 	imp_any_maize "Applied any targeted improved management practice and technology (maize)"						
tab 	imp_any_maize

*STEP 9. After applying the maize producer sampling weight, calculate the 
*		percentage of maize producers who are de jure household members who applied 
*		at least one targeted improved management practice or technology to 
*		cultivate maize during the 12 months preceding the survey using 
*		imp_any_maize. Repeat using producers' age (under 30 years of age, 30 years 
*		of age or older) and sex as disaggregates. 
*		Also calculate the percentage of maize producers who are de jure household 
*		members who applied each targeted improved management practice or 
*		technology (i.e., for all variables created in Step 3) and the percentage 
*		of maize producers who are de jure household members who applied targeted 
*		improved practices or technologies by management practice and technology 
*		type category (i.e., for all variables created in Step 4). 

svyset 	hhea [pw=wgt_maize], strata(strata)
svy, 	subpop(hhmem_dj): tab imp_any_maize
svy, 	subpop(hhmem_dj): tab imp_any_maize age15_29y, col  
svy, 	subpop(hhmem_dj): tab imp_any_maize sex, col  

foreach var in varlist imp_maize_* {
		svy, subpop(hhmem_dj): tab `var' 
}

*STEP 10. Also calculate the percentage distribution of maize producers who are de 
*		jure household members by the number of targeted improved management 
*		practices or technologies they used to cultivate maize during the 12 months 
*		preceding the survey using imp_cat_maize. Repeat using producers' age 
*		(under 30 years of age, 30 years of age or older) and sex as disaggregates. 

svy, subpop(hhmem_dj): tab imp_cat_maize
svy, subpop(hhmem_dj): tab imp_cat_maize age15_29y, col
svy, subpop(hhmem_dj): tab imp_cat_maize sex, col
	 			   
*STEP 11. Keep only the variables that are necessary to calculate the final 
*		overall indicator across all VCCs and save the data.
keep 	hhea hhnum m1_line strata sex age15_29y hhmem_dj wgt_maize vcc_maize ///
		imp_tot_maize imp_any_maize 

save "$analytic\Results\FTF ZOI Survey [COUNTRY] [YEAR] agtech_maize.dta",replace

di "Date:$S_DATE $S_TIME"
log close
