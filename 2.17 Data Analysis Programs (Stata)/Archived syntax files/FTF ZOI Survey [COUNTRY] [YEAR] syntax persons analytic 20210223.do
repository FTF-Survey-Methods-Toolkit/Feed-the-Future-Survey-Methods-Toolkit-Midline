/********************************************************************************
************************* FEED THE FUTURE ZOI SURVEY ***************************
**************************  PERSON ANALYTICAL FILE  ****************************
******************************* [COUNTRY, YEAR] ********************************
********************************************************************************
Description: This code is intended to create persons-level analytical variables 
and disaggregates required to calculate program indicators and for data analysis. 

The variables created are grouped in the following 4 broad categories:

1. Characteristics of household members 
2. Education level of household members 
3. Characteristics of primary caregivers of under 5 children 
4. Characteristics of primary decisionmakers (person-level information)
5. Characteristics of farmers (producers) of targeted VCCs

Author(s): Gheda Temsah @ ICF, Nizam Khan @ ICF, August 2018
Updated by: Kirsten Zalisk @ ICF, August 2019

This syntax file was developed using the core Feed the Future ZOI Survey phase one 
endline/phase two baseline core questionnaire. It must be adapted for the final  
country-specific questionnaire. The syntax could only be partially tested using 
ZOI Survey data; therefore, double-check all results carefully and troubleshoot 
to resolve any issues identified. 
*******************************************************************************/

clear all
set more off

//DIRECTORY PATH
*Analysis note: Adjust paths to map to the analyst's computer
global syntax	 "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Syntax" 
global source    "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Raw"      
global analytic  "C:\FTF ZOI Survey [COUNTRY] [YEAR]\Data\Analytic"

//Input data:   $source\FTF ZOI Survey [COUNTRY] [YEAR] persons data raw.dta 
//Log Outputs:	$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] persons analytic.log	
//Output data:	$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta
//Syntax: 	    $syntax\FTF ZOI Survey [COUNTRY] [YEAR] syntax persons analytic.do 

capture log close
log using "$analytic\Log\FTF ZOI Survey [COUNTRY] [YEAR] persons analytic.log", replace
********************************************************************************

*Load the individual-level data file that was created from the CSPro export
use "$source\FTF ZOI Survey [COUNTRY] [YEAR] persons raw.dta", clear
count

********************************************************************************
//STEP 1: HH MEMBER DEMOGRAPHICS
********************************************************************************
*1.1 Create analytic variable for de jure HH members
gen hhmem_dj=v105a==1
lab def YESNO 0 "No" 1 "Yes"
la val hhmem_dj YESNO
la var hhmem_dj "De jure (usual) HH member"

*1.2 Create analytic variable for de facto HH members
gen hhmem_df=v105b==1
la val hhmem_df YESNO
la var hhmem_df "De facto HH member (stayed in HH night prior to survey)"

tab1 hhmem_*

*1.3 Create sex analytic variable [1=male 2=female]
clonevar sex=v102
tab sex

*1.4 Create age in years analytic variable
tab v104,m
gen age=v104 if v104<=95
la var age "Age of HH member"
sum age

*1.5 Create age category variable (5 years)
recode age  (0/4=1    "0-4")   ///
		    (5/9=2    "5-9")   ///
		    (10/14=3  "10-14") ///
		    (15/19=4  "15-19") ///
            (20/24=5  "20-24") ///
            (25/29=6  "25-29") ///   
		    (30/34=7  "30-34") ///
            (35/39=8  "35-39") ///
            (40/44=9  "40-44") ///
            (45/49=10 "45-49") ///
            (50/54=11 "50-54") ///		   
            (55/59=12 "55-59") ///
            (60/95=13 "60+"), gen(agegrp)	
lab var agegrp "HH members' age (categorical)"
tab agegrp
	
*1.6 Adults (18+ years old), by sex and age
gen adult=inrange(age,18,95) if age<.      //All adults
la val adult YESNO
la var adult "Adult: 18+ years"

gen adult_m=adult if sex==1                //Male adult
replace adult_m=0 if adult_m!=1
la val adult_m YESNO
la var adult_m "Male adult: 18+ years"

gen adult_f=adult if sex==2                //Female adult
replace adult_f=0 if adult_f!=1
la val adult_f YESNO
la var adult_f "Female adult: 18+ years"

tab1 adult*

*1.7 Youth (15-29 years old), by sex
gen age15_29y=inrange(age,15,29)           //All youth 
gen age15_29ym=inrange(age,15,29) & sex==1 //Male youth
gen age15_29yf=inrange(age,15,29) & sex==2 //Female youth
la val age15_29* YESNO
la var age15_29y "Youth:15-29 years"
la var age15_29ym "Male youth:15-29 years"
la var age15_29yf "Female youth:15-29 years"

tab1 age15_19y*

*1.8 Women of reproductive age (15-49 years old)
gen wra=inrange(age,15,49) & sex==2 
la val wra YESNO
la var wra "Woman of reproductive age: 15-49 years"
tab wra

*******Child demographic groups
*1.9 Children under 2 years old, by sex
gen cu2=inrange(age,0,1)            //All children under 2
gen cu2m=inrange(age,0,1) & sex==2  //Male children under 2
gen cu2f=inrange(age,0,1) & sex==1  //Female children under 2
la val cu2* YESNO
la var cu2 "Child under 2 years - HH roster"
la var cu2m "Male child under 2 years - HH roster"
la var cu2f "Female child under 2 years - HH roster"

tab1 cu2*

*1.10 Children under 5 years old, by sex
gen cu5=inrange(age,0,4)            //All children under 5 
gen cu5m=inrange(age,0,1) & sex==2  //Male children under 5
gen cu5f=inrange(age,0,1) & sex==1  //Female children under 5
la val cu5* YESNO
la var cu5 "Child under 5 years - HH roster"
la var cu5m "Male child under 5 years - HH roster"
la var cu5f "Female child under 5 years - HH roster"

tab1 cu5*

*1.11 Children 5 or older (5-17 years old), by sex
gen c5_17y=inrange(age,5,17)            //All children 5-17
gen c5_17ym=inrange(age,5,17) & sex==2  //Male children 5-17
gen c5_17yf=inrange(age,5,17) & sex==1  //Female children 5-17
la val c5_17y* YESNO
la var c5_17y "Child 5-17 years - HH roster"
la var c5_17ym "Male child 5-17 years - HH roster"
la var c5_17yf "Female child 5-17 years - HH roster"

tab1 c5_17y*

sum  adult* age15_29y* wra cu2* cu5* c5_17*

***Note that ages in months from the nutrition module are for only children whose
***caregiver consented to respond to the module, also some of the ages reported in 
***the HH roster may be estimated or incorrect. Therefore, the # of children as
***calculated using data in the nutrition module is less than that calculated using
***data in the HH roster.

*1.12 Children's age in days (cage_days) and in months (cage_months, cage_months_int)
tab1 v502* v504 v505 v506* v507 v508 v510 v511

*Generate a birth day variable using both recall and vaccination card/book information
***INSTRUCTION: Update the maximum birth year to be relevant to the ZOI Survey
tab v502d if v500f==1
gen bday=v502d if v502d<=31
replace bday=v506d if v505==1 & v506d<=31 & bday==.
replace bday=15 if v502d>=98 & v500f==1 & & (v502m<=12 | v506m<=12) & (v502y<2020 | v506y<2020) & bday==.
tab bday

*Generate a birth month variable using both recall and vaccination card/book information
gen bmon=v502m if v502m<=12
replace bmon=v506m if v505==1 & v506m<=12 & bmon==.
tab bmon

*Generate a birth year variable using both recall and vaccination card/book information
***INSTRUCTION: Update the maximum birth year to be relevant to the ZOI Survey
gen byear=v502y if v502y<9998
replace byear=v506y if v505==1 & v506y<=2020 & byear==.
tab byear

*Concatenate the birth day, month and year variables into a birthdate variable
gen bdate=mdy(bmon, bday, byear)
format bdate %td
tab bdate

*drop bday bmon byear

*Merge the final date of interview information from the HH-level data file 
merge m:1 hhea hhnum using "$source\Mali ZOI Survey 2019 household data raw.dta", keepusing(ahintd ahintm ahinty)
drop if _merge==2
drop _merge

*Concatenate the interview day, month and year variables into a date variable
gen intdate=mdy(ahintm, ahintd, ahinty)

*Generate an age in days variable
gen cage_days=intdate-bdate if bdate!=.
la var cage_days "Child age in days"
tab cage_days

*Generate an age in months variable
gen cage_months=cage_days/365.25*12
gen cage_months_int=int(cage_months)
la var cage_months "Child age in months, including decmial"
la var cage_months_int "Child age in months, excluding decimal"

*Compare the generated age in months variable to age in months variable collected in survey
count if v508!=cage_months_int & v508!=.
count if v508==cage_months_int & v508!=.
list v508 cage_months_int cage_months b* ahint* if v508!=cage_months_int
gen cage_months_int=v508 if cage_months_int==. & v508<60

*1.13 Children 0-5 months old
gen cu6m=inrange(cage_months_int,0,5)
la val cu6m YESNO
la var cu6m "Child: <6 months old - Nutrition module"

*1.14 Children 6-23 months old
gen c6_23m=inrange(cage_months_int,6,23)
la val c6_23m YESNO
la var c6_23m "Child: 6-23 months old - Nutrition module"

*1.15 Children 0-23 months old
gen c0_23m=inrange(cage_months_int,0,23)
la val c0_23m YESNO
la var c0_23m "Child: 0-23 months old - Nutrition module"

*1.16 Children 0-59 months old
gen c0_59m=inrange(cage_months_int,0,59)
la val c0_59m YESNO
la var c0_59m "Child: 0-59 months old - Nutrition module"

*1.17 Children 6-8 months old
gen c6_8m=inrange(cage_months_int,6,8)
la val c6_8m YESNO
la var c6_8m "Child: 6-8 months old - Nutrition module"

*1.18 Children 9-23 months old
gen c9_23m=inrange(cage_months_int,9,23)
la val c9_23m YESNO
la var c9_23m "Child: 9-23 months old - Nutrition module"

*1.19 Children 6-23 months in 6-month categories
recode cage_months_int  (6/11=1  "6-11")   ///
					    (12/17=2 "12-17")  ///
					    (18/23=3 "18-23"), gen(cage_6m) 
replace cage_6m=. if cage_months_int<6 | cage_months_int>=24
lab var cage_6m "Child age category 6-23 months (6m interval)"

*1.20 Children 0-59 months in 12-month categories
recode cage_months_int  (0/11=1  "0-11")   ///
					    (12/23=2 "12-23")  ///
					    (24/35=3 "24-35")  ///
						(36/47=4 "36-47")  ///
						(48/59=5 "48-59"), gen(cage_12m) 
replace cage_12m=. if cage_months_int>=60
lab var cage_12m "Child age category 0-59 months (12m interval)"

*1.21 Children 0-59 months in 2 categories: 0-23 months, 24-59 months
*5/27/2020: Updated the categories in next line; had been incorrect (0-11 & 48-59)
recode cage_months_int (0/23=1  "0-23")   ///
					   (24/59=2 "24-59"), gen(cnut_age)
replace cnut_age=. if cage_months_int>=60
lab var cnut_age "Child age category (0-23, 24-59 mo.)"					
						
*1.22 Women's pregnancy status 
gen preg_stat=.
replace preg_stat=0 if wra==1 & (an405==2 | an405==8)
replace preg_stat=1 if wra==1 & an405==1
la val preg_stat YESNO
la var preg_stat "Woman is pregnant"

*1.23 Women of reproductive age's age by category 
gen age_wra=v402 if wra==1 & v402<98
replace age_wra=age if wra==1 & age_wra==.
recode age_wra  (15/19=1  "15-19") ///
				(20/24=2  "20-24") ///
				(25/29=3  "25-29") ///   
				(30/34=4  "30-34") ///
				(35/39=5  "35-39") ///
				(40/44=6  "40-44") ///
				(45/49=7  "45-49"), gen(agegrp_wra)	
lab var agegrp_wra "Women of reproductive age’s age (categorical)"
tab agegrp_wra

*1.24 Women of reproductive age's age by category (15-18, 19-49 yo)
gen age_wra=v402 if wra==1 & v402<98
replace age_wra=age if wra==1 & age_wra==.
recode age_wra  (15/18=1  "15-18") ///
				(19/49=2  "19-49"), gen(wra_cage)	
lab var wra_cage "Women of reproductive age’s age (categorical)"
tab wra_cage

tab1 cu6m c6_23m c0_23m c0_59m c6_8m c9_23m cage_12m cage_6m cnut_age preg_stat agegrp_wra wra_cage
sum  cu6m c6_23m c0_23m c0_59m c6_8m c9_23m cage_12m cage_6m cnut_age preg_stat agegrp_wra wra_cage

********************************************************************************
//STEP 2: HH MEMBER EDUCATION
********************************************************************************
***INSTRUCTION: Update values for all education variables to reflect final 
***country-specific questionnaire.

*2.1 Completed primary education - individuals 10 years and older
***The template code is written such that primary schooling includes 6 grades
tab1    v111a v111b,m
gen     edu_prim=.
replace edu_prim=0 if inrange(age,10,95)
replace edu_prim=1 if inrange(age,10,95) & (inlist(v111a,2,3) | (v111a==1 & v111b==6))
la val edu_prim YESNO
la var edu_prim "Individual (10+ yo) completed primary education" 
tab edu_prim

*2.2 Currently attending school education - individuals 5-24 years
***Assume missing are currently not attending
tab     v110
gen     edu_attend=. 
replace edu_attend=1 if inrange(age,5,24) & v110==1
replace edu_attend=0 if inrange(age,5,24) & v110!=1 
la val edu_attend YESNO 
la var edu_attend "Individual (5-24yo) is currently attending school"
tab edu_attend

*2.3 Educational attainment - individuals 5 years and older
*The template code is written such that primary schooling includes 6 grades,
*and secondary school includes 6 grades. 
***INSTRUCTION: Use the "Other" category to capture HH members whose highest 
***grade is "don't know" or whose highest level in primary school is "don't know". 
***Categorize HH members whose highest level in secondary school is "don't know"
***as having completed primary school. Remove "Other" category if not applicable.
gen edulevel=. 
replace edulevel=1 if v109==2 & inrange(age,5,95) 
replace edulevel=2 if (v111a==0 | (v111a==1 & (v111b<6 | v111b=98))) & inrange(age,5,95)  
replace edulevel=3 if ((v111a==1 & v111b==6) | (v111a==2 & (v111b<6 | v111b==98))) & inrange(age,5,95)  
replace edulevel=4 if ((v111a==2 & v111b==6) | (v111a==3 & v111b==0)) & inrange(age,5,95)  
replace edulevel=5 if v111a==3 & v111b>0 & inrange(age,5,95)
replace edulevel=6 if v111a==8 & inrange(age,5,95) 

lab def edulevel 1 "No education" ///
				 2 "Less than primary" ///
				 3 "Completed primary" ///
				 4 "Completed secondary" ///
				 5 "Higher" ///
				 6 "Other"
lab val edulevel edulevel
la var edulevel "Level of education attained by HH member"
tab edulevel

********************************************************************************
//STEP 3: PRIMARY ADULT DECISIONMAKERS - PERSON-LEVEL VARIABLES
********************************************************************************
*3.1 Primary adult decisionmakers, by sex
*If using the CSPro CAPI data collection program available before [DATE], and the
*program was not adapted, you must using the following syntax:
/*gen mdm=1 if v101a==1 & m1_line==1  //Primary adult male decisionmaker 
  gen fdm=1 if (v101b==1 & vtype==1 & m1_line==2) | ///
			 (v101b==1 & vtype==3 & m1_line==1) //Primary adult female decisionmaker 
  gen pdm=1 if mdm==1 | fdm==1  //Primary adult decisionmaker */

tab1 m1_line v101a v101b,m
gen pdm=.
replace pdm=1 if m1_line==1 | m1_line==2 //Primary adult decisionmaker 
gen mdm=pdm==1 & sex==1                  //Primary adult male decisionmaker 
gen fdm=pdm==1 & sex==2                  //Primary adult female decisionmaker 
la def YES 1 "YES"
la val pdm mdm fdm YES
la var pdm "Primary adult decisionmaker"
la var mdm "Primary adult male decisionmaker"
la var fdm "Primary adult female decisionmaker"

tab1 pdm mdm fdm

*3.2 Create variables for de jure PDMs
gen mdm_dj=0 if mdm==1
replace mdm_dj=1 if mdm==1 & hhmem_dj==1

gen fdm_dj=0 if fdm==1
replace fdm_dj=1 if fdm==1 & hhmem_dj==1

gen pdm_dj=0 if pdm==1
replace pdm_dj=1 if pdm==1 & hhmem_dj==1

la val pdm_dj fdm_dj mdm_dj YESNO
la var pdm_dj "PDM, de jure HH member"
la var fdm_dj "Female PDM, de jure HH member"
la var mdm_dj "Male PDM, de jure HH member"

tab1 ?dm_dj

*3.3 De jure primary adult decisionmakers educational attainment
gen edu_pdm_dj=edulevel if pdm_dj==1 
gen edu_mdm_dj=edulevel if mdm_dj==1  //MALE
gen edu_fdm_dj=edulevel if fdm_dj==1  //FEMALE

la val edu_?dm_dj edulevel
la var edu_pdm_dj "Education of de jure PDM"
la var edu_fdm_dj "Education of de jure female PDM"
la var edu_mdm_dj "Education of de jure male PDM"

tab1 edu_?dm_dj

*3.4 De jure primary adult decisionmakers completed primary school
gen edu_prim_pdm_dj=edu_prim if pdm_dj==1
gen edu_prim_mdm_dj=edu_prim if mdm_dj==1  //MALE
gen edu_prim_fdm_dj=edu_prim if fdm_dj==1  //FEMALE

la val edu_prim_?dm_dj YESNO
la var edu_prim_pdm_dj "PDM completed primary school"
la var edu_prim_fdm_dj "Female PDM completed primary school"
la var edu_prim_mdm_dj "Male PDM completed primary school"

tab1 edu_prim_?dm_dj

*3.5 De jure primary adult decisionmakers by age category
recode age (18/24=1  "18-24") ///
           (25/29=2  "25-29") ///   
	       (30/34=3  "30-34") ///
           (35/39=4  "35-39") ///
           (40/44=5  "40-44") ///
           (45/49=6  "45-49") ///
           (50/54=7  "50-54") ///		   
           (55/59=8  "55-59") ///
           (60/95=9  "60+") if pdm_dj==1, gen(agegrp_pdm_dj)
gen agegrp_fdm_dj=agegrp_pdm_dj if fdm_dj==1
gen agegrp_mdm_dj=agegrp_pdm_dj if mdm_dj==1

la val agegrp_fdm_dj agegrp_mdm_dj agegrp_pdm_dj

la var agegrp_pdm_dj "De jure PDM by age category"
la var agegrp_fdm_dj "De jure FDM by age category"
la var agegrp_mdm_dj "De jure MDM by age category"

tab1 agegrp_?dm_dj

*3.6 Create variable for de jure youth/non-youth primary decisionmakers
gen youth_pdm_dj=.
replace youth_pdm_dj=0 if pdm_dj==1
replace youth_pdm_dj=1 if pdm_dj==1 & age<30
gen youth_fdm_dj=youth_pdm_dj if fdm_dj==1   //FEMALE
gen youth_mdm_dj=youth_pdm_dj if mdm_dj==1   //MALE

la val youth_?dm_dj YESNO
la var youth_pdm_dj "De jure PDM < 30 yo"
la var youth_fdm_dj "De jure female PDM <30 yo"
la var youth_mdm_dj "De jure female PDM <30 yo"

tab1 youth_?dm_dj

********************************************************************************
//STEP 4: PRIMARY CAREGIVER OF CHILD UNDER AGE 5
********************************************************************************
*4.1 Create a variable specifies primary caregivers of children under 5 in the 
*    persons file.

*4.1a Save the persons analytic data file with the analytic variables already created
save "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta",replace

*4.1b Create a variable that indicates the child included in the children’s 
*nutrition module has a primary caregiver and is 0-59 months old.
gen caregiver=.
replace caregiver=1 if v500e!=. & v508<60
la val caregiver YES
la var caregiver "Primary caregiver of a child under 5 years old"

*4.1c Keep only records for children ages 0-59 months old who have a primary 
*caregiver with a household roster line number in the children’s nutrition module.
keep if caregiver==1 
keep hhea hhnum v500e caregiver

*4.1d Sort the data by cluster, household number, and caregiver line number, 
*and keep only the first record for each unique caregiver (that is eliminate 
*multiple records for caregivers who have more than one child 0-59 months).
sort hhea hhnum m1_line
by hhea hhnum m1_line: keep if _n==1
rename v500e m1_line

*4.1e Save the dataset as temp_analytic.
save "$analytic\Temp\temp_caregiver", replace

*4.1f Merge the temp_analytic data file with the individual-level data file 
*using m1_line as a key variable and keeping the caregiver variable.
use "$analytic\Temp\ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear
merge 1:1 hhea hhnum m1_line using temp_analytic, keepusing(caregiver)
drop _merge

*4.2. Create a variable that indicates the highest level of educational 
*attainment of primary caregivers
gen edu_cg=.
replace edu_cg=edulevel if caregiver==1 
la val edu_cg edulevel
lab var edu_cg "Educational attainement of primary caregivers of children 0-59 months"

*4.3 Create a variable that indicates the sex of primary caregivers
gen sex_cg=.
replace sex_cg=sex if caregiver==1
la def sex 1 "Male" 2 "Female"
la val sex_cg sex
la var sex_cg "Sex of caregivers of children 0-59 months"

*4.4 Create a variable that indicates the age of primary caregivers
recode age (0/17 =1  "<18")   ///
           (18/24=2  "18-24") ///
           (25/29=3  "25-29") ///   
		   (30/34=4  "30-34") ///
           (35/39=5  "35-39") ///
           (40/44=6  "40-44") ///
           (45/49=7  "45-49") ///
           (50/54=8  "50-54") ///		   
           (55/59=9  "55-59") ///
           (60/95=10 "60+"), gen(agegrp_cg)	
la var agegrp_cg "Cargeiver of children <5yo (categorical)"

tab1 *_cg

********************************************************************************
//STEP 5: FARMERS
********************************************************************************
*This step requires customization to align with the country questionnaire. The
*targeted VCCs will vary by country. The template code was set up for a survey
*that included maize, millet, okra, and sheep (3 crop VCCs and 1 livestock VCC).

***INSTRUCTIONS: Update code to reflect VCCs included in the survey.

*5.1. Count the number of farmers who cultivated a crop VCC or raised a livestock
*     VCC in the previous year
count if vfarmer>0 & vfarmer!=.
count if vanimal>0 & vanimal!=.

*5.2. Examine the informed consent variables in each VCC submodule to determine who
* was eligible to be interviewed
*Template code was developed using maize, millet, okra, and sheep as the VCCs.
tab v7100d   //Maize
tab v71000d  //Millet
tab v71100d  //Okra
tab v75200d  //Sheep

*5.3. Create a variable to indicate if HH member was responsible for producing
*     any VCC, regardless of whether the VCC module was completed.
gen vcc=1 if v7100d!=. | v71000d!=. | v71100d!=. | v75200d!=.
*gen vcc=1 if v7100d==1 | v71000d==1 | v71100d==1 | v75200d==1
lab val vcc YESNO
lab var vcc "Farmer of 1+ targeted VCC"

*5.4. Create variables to indicate if HH member was responsible for producing 
* specific VCCs and completed the VCC module
gen vcc_maize=1 if v7100d==1
lab vcc_maize YES
lab var vcc_maize "Maize farmer, completed maize module"

gen vcc_millet=1 if v71000d==1
lab vcc_millet YES
lab var vcc_millet "Millet producer, completed millet module"

gen vcc_okra=1 if v71100d==1
lab vcc_okra YES
lab var vcc_okra "Okra producer, completed okra module"

gen vcc_sheep=1 if v75200d==1
lab vcc_sheep YES
lab var vcc_sheep "Sheep producer, completed sheep module"

for var vcc_*: recode X .=0 if vcc==1

tab1 vcc_*

*5.5. Create variables to indicated if HH members was responsible for producing 
* specific VCCs, regardless of whether they completed the VCC module
gen vcc_maize2=1 if v7100d!=.
lab vcc_maize2 YES
lab var vcc_maize "Maize farmer"

gen vcc_millet2=1 if v71000d!=.
lab vcc_millet2 YES
lab var vcc_millet "Millet farmer"

gen vcc_okra2=1 if v71100d!=.
lab vcc_okra2 YES
lab var vcc_okra "Okra farmer"

gen vcc_sheep2=1 if v75200d!=.
lab vcc_sheep2 YES
lab var vcc_sheep "Sheep farmer"

for var vcc_*2: recode X .=0 if vcc==1

tab1 vcc_*2

*5.6. Create a varibale to indicate the number of VCCs each HH member was responsible for producing
egen tot_vcc=rsum(vcc_maize2 vcc_millet2 vcc_okra2 vcc_sheep2)
replace tot_vcc=. if tot_vcc==0
la var tot_vcc "Total number of VCCs per farmer"
tab tot_vcc

*5.7. Create a variable for the education level of each VCC producer
gen edu_vcc=.
replace edu_vcc=edulevel if vcc==1
la val edu_vcc edulevel
la var edu_vcc "Educational attainement of VCC producers"
tab edu_vcc

*5.8. Create variables for the age and age category of each VCC producer
gen agegrp_vcc=agegrp if vcc==1
la val agegrp_vcc agegrp
la var agegrp_vcc "Age group VCC producers"
tab agegrp_vcc

*5.9. Create variable for youth/non-youth of each VCC producer
gen youth_vcc=.
replace youth_vcc=0 if vcc==1
replace youth_vcc=1 if vcc==1 & age<30
la youth_vcc YESNO
la var youth_vcc "VCC producer is less than 30 years old"

tab1 *_vcc

*********************************************************************************
//STEP 6: LABEL AND SAVE DATA
********************************************************************************

order hhea hhnum  
sort  hhea hhnum m1_line

la data "Persons analytic data - [COUNTRY]"
save "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta",replace

di "Date:$S_DATE $S_TIME"
log  close
