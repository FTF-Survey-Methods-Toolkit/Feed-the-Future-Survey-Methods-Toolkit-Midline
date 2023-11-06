/*******************************************************************************
**************** FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS ****************
**************************  PERSON ANALYTICAL FILE  ****************************
****************************** [COUNTRY] [YEAR] ********************************
********************************************************************************
Description: In this do file, key individual-level analytic variables used to 
calculate or disaggregate indicators are defined and their calculation described. 

The file is divided into seven sections:

4.1. Household member status (de jure/de facto) and sex variables
4.2. Children under 5 years age-in-month variables
4.3. Household member age-in-year variables
4.4. Women of reproductive age variables 
4.5. Primary adult decisionmakers variables 
4.6. Producers (farmers) of targeted VCC variables 
4.7. Primary adult female decision-maker characteristics

The numbering of the sections and variables aligns with the Chapter 4 and 7 in the
Guide to Feed the Future Midline Statistics.

Syntax prepared by ICF, February 2023
Revised by ICF, September 2023

This syntax file was developed using the core Feed the Future phase two ZOI 
Midline main survey questionnaire. It must be adapted for the final country- 
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
**#1. HOUSEHOLD MEMBER STATUS (DE JURE/DE FACTO) AND SEX VARIABLES
********************************************************************************
*4.1.1. De jure HH member
*       Create a binary de jure household member analytic variable (hhmem_dj).  
tab v105a,m
gen hhmem_dj=0
replace hhmem_dj=1 if v105a==1
cap lab def YESNO 0 "No" 1 "Yes"
la val hhmem_dj YESNO
la var hhmem_dj "De jure (usual) HH member"
tab hhmem_dj

*4.1.2. De facto household member
*       Create a binary de facto household member analytic variable (hhmem_df).
tab v105b,m
gen hhmem_df=0
replace hhmem_df=1 if v105b==1
la val hhmem_df YESNO
la var hhmem_df "De facto HH member (stayed in HH night prior to survey)"
tab hhmem_df

*4.1.3. Sex 
*       Create binary sex analytic variable (sex) [1=male 2=female].
tab v102,m
gen sex=.
replace sex=1 if v102==1
replace sex=2 if v102==2
lab def SEX 1 "Male" 2 "Female"
lab val sex SEX
lab var sex "Sex of HH member"
tab sex

********************************************************************************
**#2. CHILDREN UNDER 5 YEARS AGE-IN-MONTH VARIABLES
********************************************************************************
*4.2.1. Age in days, children under 5 years
*       Create a variable that captures the age in days of children under 5 years 
*       (cage_days). If Module 5 was not completed for a child, they will not 
*       have a value for this variable.
*****Note that ages in days from the nutrition module are available only for 
*****children whose caregiver consented to respond to the module. The calculated
*****age in days may not match the HH roster age. 
tab1 v502* v504 v505 v506* v507 v508 v510 v511

*4.2.1.1-3. Generate a birth day variable using both caregiver's self report 
*           and the child's vaccination card/book information (bday). If day of 
*           birth is missing but month and year of birth are available, impute 
*           '15' as the day of birth.
***INSTRUCTION: Update the maximum birth year [YYYY] to be relevant to the ZOI Survey
tab v502d if v565==1,m
gen bday=.
replace bday=v502d if v502d<=31
replace bday=v506d if v505==1 & v506d<=31 & bday==.
replace bday=15 if v502d>=98 & v500c==1 & v506d >=98 & (v502m<=12 | v506m<=12) & (v502y<[YYYY] | v506y<[YYYY]) & bday==.
lab var	bday "Child's day of birth, derived"
tab bday

*4.2.1.4. Create a birth month variable (bmon) using the month reported by the 
*         caregiver in the nutrition module if the month is valid—that is, 12 or 
*         less. If the month reported by the caregiver is not valid or is missing, 
*         set the birth month to be the birth month on the child's vaccination 
*         card if the month on the card is valid.
gen bmon=.
replace bmon=v502m if v502m<=12
replace bmon=v506m if v505==1 & v506m<=12 & bmon==.
lab var	bmon "Child's day of birth, derived"
tab bmon

*4.2.1.5. Create a birth year variable (byear) using the year reported by the 
*         caregiver in the nutrition module if the year is valid—that is, less than 
*         or equal to the year of the survey data collection. If the year reported 
*         by the caregiver is not valid or is missing, set the birth year to be the 
*         birth year on the child's vaccination card if the year on the card is valid. 
***INSTRUCTION: Update the maximum birth year [YYYY] to be relevant to the ZOI Survey
gen byear=.
replace byear=v502y if v502y<=[YYYY]
replace byear=v506y if v505==1 & v506y<=[YYYY] & byear==.
lab var byear "Child's year of birth, derived"
tab byear

*4.2.1.6. Combine the birth day, month, and year variables into a variable 
*         formatted as a date that can be used in date arithmetic (bdate).
gen bdate=mdy(bmon, bday, byear)
format bdate %td
lab var	bdate "Child's date of birth, derived"
tab bdate

*drop bday bmon byear

*4.2.1.7. Merge the final date of interview information from the HH-level data file 
merge m:1 hhea hhnum using "$source\FTF ZOI Survey [COUNTRY] [YEAR] household data raw.dta", keepusing(ahintd ahintm ahinty)
drop if _merge==2
drop _merge

*4.2.1.8. Combine the final interview day, month, and year variables into a variable 
*         formatted as a date that can be used in date arithmetic (intdate).
gen intdate=mdy(ahintm, ahintd, ahinty)
format bdate %td
lab var	bdate "Date of interview"
tab intdate

*4.2.1.9. Create an age in days variable by subtracting the birthdate variable from 
*         the date of interview variable (cage_days).
gen cage_days=intdate-bdate if bdate!=.
la var cage_days "Child's age in days"
tab cage_days

*4.2.2. Age in months, children under 5 years
*       Create two variables that capture the age in days of children under 5 years 
*       (cage_months and cage_months_int).
*4.2.2.1. Create a variable that holds the age in months (cage_months) of children 
*         whose primary caregiver consented to respond to the children's nutrition 
*         module by dividing the child's age in days by the number of days in a 
*         year (365.25) and multiplying by 12 months. 
gen cage_months=cage_days/365.25*12
la var cage_months "Child's age in months, including decmial"
sum cage_months

*4.2.2.2. Create an integer version of the child's age in months variable 
*         (cage_months_int) using the variable created in the previous step. If 
*         the child does not have a value for cage_months and completed Module 5, 
*         use the child's caregiver-reported age (v508). If child did not 
*         complete Module 5 but is less than 1 year of age in the HH roster, use 
*         the child's age in months (v104a). 
gen cage_months_int=int(cage_months)
replace cage_months_int=v508 if cage_months_int==. & v508<60
replace cage_months_int=v104a if cage_months_int==. & v104a!=.
la var cage_months_int "Child's age in months, excluding decimal"

*4.2.3. Children 0-5 months old, overall and by sex
*       Create variables indicating children 0-5 months using the derived 
*       age-in-months variable (cage_months_int) variable.
gen c0_5m=0
replace c0_5m=1 if inrange(cage_months_int,0,5)
la val c0_5m YESNO
la var c0_5m "Child is 0-5 months"

gen c0_5mm=0
replace c0_5mm=1 if c0_5m==1 & sex==1
lab val	c0_5mm YESNO
lab var	c0_5mm "Male child 0-5 months"

gen c0_5mf=0
replace c0_5mf=1 if c0_5m==1 & sex==2
lab val	c0_5mf YESNO
lab var	c0_5mf "Female child 0-5 months"

tab1 c0_5m*

*4.2.4. Children 6-23 months old, overall and by sex
*       Create variables indicating children 6-23 months using the derived 
*       age-in-months variable (cage_months_int) and, if cage_months_int 
*       is missing, age-in-years from the HH roster (v104).
gen c6_23m=0
replace c6_23m=1 if inrange(cage_months_int,6,23)
replace c6_23m=1 if v104==1 & c6_23m==0
la val c6_23m YESNO
la var c6_23m "Child: 6-23 months old - Nutrition module"

gen c6_23mm=0
replace c6_23mm=1 if c6_23m==1 & sex==1
lab val	c6_23mm YESNO
lab var	c6_23mm "Male child 6-23 months"

gen c6_23mf=0
replace c6_23mf=1 if c6_23m==1 & sex==2
lab val	c6_23mf YESNO
lab var	c6_23mf "Female child 6-23 months"

tab1 c6_23* 

*4.2.5. Children 0-23 months old, overall and by sex
*       Create variables indicating children 0-23 months using the derived 
*       age-in-months variable (cage_months_int) variable and, if cage_months_int 
*       is missing, the age-in-years variable in the household roster (v104).
gen c0_23m=0
replace c0_23m=1 if inrange(cage_months_int,0,23)
replace c0_23m=1 if v104==1 & c0_23m==0
la val c0_23m YESNO
la var c0_23m "Child 0-23 months"

gen c0_23mm=0
replace c0_23mm=1 if c0_23m==1 & sex==1
lab val	c0_23mm YESNO
lab var	c0_23mm "Male child 0-23 months"

gen c0_23mf=0
replace c0_23mf=1 if c0_23m==1 & sex==2
lab val	c0_23mf YESNO
lab var	c0_23mf "Female child 0-23 months"

tab1 c0_23* 

*4.2.6. Children 0-59 months old, overall and by sex
*       Create variables indicating children 0-59 months using the derived 
*       age-in-months variable (cage_months_int) variable and, if cage_months_int 
*       is missing, the age-in-years variable in the household roster (v104).
gen c0_59m=0
replace c0_59m=1 if inrange(cage_months_int,0,59)
replace c0_59m=1 if v104>=1 & v104<=4 & c0_59m==0
la val c0_59m YESNO
la var c0_59m "Child 0-59 months"

gen c0_59mm=0
replace c0_59mm=1 if c0_59m==1 & sex==1
lab val	c0_59mm YESNO
lab var	c0_59mm "Male child 0-59 months"

gen c0_59mf=0
replace c0_59mf=1 if c0_59m==1 & sex==2
lab val	c0_59mf YESNO
lab var	c0_59mf "Female child 0-59 months"

tab1 c0_59* 

*4.2.7. Children 6-23 months in 6-month categories
*       Create a variable that identifies the age of all children 6-23 months of 
*       age in the children's nutrition module by 6-month age categories (cage_mad).
*       Children who do not have a value for cage_months_int, will not have a value  
*       for this variable.
recode cage_months_int  (6/11=1  "6-11")   ///
					    (12/17=2 "12-17")  ///
					    (18/23=3 "18-23"), gen(cage_mad) 
replace cage_mad=. if cage_months_int<6 | cage_months_int>=24 | v500r!=1
lab var cage_mad "Child's age category (6-11,12-17,18-23 months)"
tab cage_mad

*4.2.8. Children 0-59 months in 2 categories: 0-23 months and 24-59 months
*       Create a variable that categorizes all children 0-59 months of age in 
*       the children's nutrition module into two age categories: 0-23 months 
*       of age and 24-59 months of age (cage_pp).
*       Children who do not have a value for cage_months_int, will use their 
*       age in the household roster.
recode cage_months_int (0/23=1  "0-23")   ///
					   (24/59=2 "24-59"), gen(cage_pp)
replace cage_pp=1 if v104<2 & cage_pp==. & v500r==1
replace cage_pp=2 if v104>=2 & v104<5 & cage_pp=. & v500r==1
replace cage_pp=. if cage_months_int>=60 | v500r!=1
lab var cage_pp "Child age category (0-23,24-59 months)"		
tab cage_pp 

********************************************************************************
**#4.3 HOUSEHOLD MEMBER AGE-IN-YEAR VARIABLES
********************************************************************************
*4.3.1. Age in years
*       Create a continuous age-in-years analytic variable (age) using data from
*       the HH roster and well as self-report age in Modules 4 and 6 and 
*       caregiver reported birthdate/age information in Module 5.
tab v104,m
tab v402 if v400r==1,m
tab v6102 if v600r==1,m
tab1 cage_months_int if v500r==1,m 

gen 	age=v104
replace age=v402 if v402!=.
replace	age=v6102 if v6102!=.
replace	age=trunc(cage_months_int/12) if cage_months_int!=.
la var 	age "Age of HH member (years), HH roster"
sum age

*Explore whether there are any cases in which an individual responded to both 
*Module 4 and Module 6, and their self-reported ages in the two modules (v402 
*and v6102) do not agree. If their age in the household roster matches either 
*v402 or v6102, keep the age that matches their age in the household roster.

count if v402!=v6102 & v402==. & v6102!=.
list v104 v402 v6102 if v402!=v6102 & v402!=. & v6102!=.

replace age=v402 if v402!=v6102 & v402!=. & v6102!=. & v104==v402
replace age=v6102 if v402!=v6102 & v402!=. & v6102!=. & v104==v6102


*4.3.2. Adult, overall and by sex
*       Create binary variables that identify all adults in the household roster
*       overall (adult) and by sex (adult_m & adult_f).
gen adult=0
replace adult=1 if inrange(age,18,95) 
la val adult YESNO
la var adult "Adult (18+ years), HH roster"

gen adult_m=0
replace adult_m=1 if adult==1 & sex==1
la val adult_m YESNO
la var adult_m "Male adult (18+ years), HH roster"

gen adult_f=0
replace adult_f=1 if adult==1 & sex==2
la val adult_f YESNO
la var adult_f "Female adult (18+ years), HH roster"

tab1 adult*

*4.3.3. Youth, overall and by sex
*       Create binary variables that identify all youth (15-29 years) in the 
*       household roster overall (age15_29y) and by sex (age15_29ym & age15_29yf).
gen age15_29y=0
replace age15_29y=1 if inrange(age,15,29)
la val age15_29y YESNO
la var age15_29y "Youth (15-29 years), HH roster"

gen age15_29ym=0
replace age15_29ym=1 if age15_29y==1 & sex==1 
la val age15_29ym YESNO
la var age15_29ym "Male youth (15-29 years), HH roster"

gen age15_29yf=0
replace age15_29yf=1 if age15_29y==1 & sex==2 
la val age15_29yf YESNO
la var age15_29yf "Female youth (15-29 years), HH roster"

tab1 age15_29y*

*4.3.4. Children 5-17 years old, overall and by sex
*        Create variables indicating children 5-17 years using age from the household 
*        roster (age).
gen c5_17y=0
replace c5_17y=1 if inrange(age,5,17)
lab val c5_17y YESNO
la var c5_17y "Child 5-17 years, HH roster"

gen c5_17ym=0
replace c5_17ym=1 if c5_17y==1 & sex==1
lab val c5_17ym YESNO
la var c5_17ym "Male child 5-17 years, HH roster"

gen c5_17yf=0
replace c5_17yf=1 if c5_17y==1 & sex==2
lab val c5_17yf YESNO
la var c5_17yf "Female child 5-17 years, HH roster"

tab1 c5_17y*

********************************************************************************
**#4.4 WOMEN OF REPRODUCTIVE AGE VARIABLES
********************************************************************************
*4.4.1. Women of reproductive age
*       Create a binary variable that identifies all women of reproductive age 
*       based on the sex and age variables.
gen wra=0
replace wra=1 if inrange(age,15,49) & sex==2 
la val wra YESNO
la var wra "Woman of reproductive age (15-49 years)"
tab wra

*4.4.2. Women of reproductive age's age, 5-year categories
* 	 	Create a categorical variable that indicates the age of women of 
*       reproductive age by 5-year age category (wra_agegrp) using the age 
*       and sex variables.
recode age  (15/19=1  "15-19") ///
			(20/24=2  "20-24") ///
			(25/29=3  "25-29") ///   
			(30/34=4  "30-34") ///
			(35/39=5  "35-39") ///
			(40/44=6  "40-44") ///
			(45/49=7  "45-49") if wra==1, gen(agegrp_wra)	
replace agegrp_wra=. if v400r!=1
lab var agegrp_wra "Woman of reproductive age's age (5-year categories)"
tab agegrp_wra

*4.4.3. Women of reproductive age's age, by category (15-19, 20-49 years)
*       Create a categorical variable that categorizes women of reproductive age 
*       into two age categories: 15-19 years of age and 20-49 years of age 
*       (wra_cage) using the age and sex variables.
recode age  (15/19=1  "15-19") ///
			(20/49=2  "20-49") if wra==1, gen(wra_cage)	
replace wra_cage=. if v400r!=1
lab def WRA_CAGE 1 "15-19 years" 2 "20-49 years"
lab val wra_cage WRA_CAGE
lab var wra_cage "Woman of reproductive age's age (15-19, 20-49 years)"
tab wra_cage

********************************************************************************
**#4.5 PRIMARY ADULT DECISION-MAKER VARIABLES 
********************************************************************************
*4.5.1 Primary adult decision-makers, overall and by sex
*      Create variables that indicate the primary adult decision-makers in 
*      the household (mdm, fdm, pdm). 
tab1 m1_line v101a v101b,m

gen mdm=0
replace mdm=1 if m1_line==1
lab val mdm YESNO 
lab var mdm "Primary adult male decision-maker (Male PADM)"

gen fdm=0
replace fdm=1 if m1_line==2
lab val fdm YESNO 
lab var fdm "Primary adult female decision-maker (Female PADM)"

gen pdm=0
replace pdm=1 if mdm==1 | fdm==1
lab val pdm YESNO 
lab var pdm "Primary adult decision-maker (PADM)"

tab1 mdm fdm pdm 

*4.5.2. Primary adult male & female decision-makers who are de jure HH members
*       Create variables that indicate whether the primary adult decision-makers 
*       are de jure HH members (mdm_dj, fdm_dj). 
gen mdm_dj=0 if mdm==1
replace mdm_dj=1 if mdm==1 & hhmem_dj==1
lab val mdm_dj YESNO
la var mdm_dj "Male PADM, de jure HH member"

gen fdm_dj=0 if fdm==1
replace fdm_dj=1 if fdm==1 & hhmem_dj==1
lab val mdm_dj YESNO
la var fdm_dj "Female PADM, de jure HH member"

tab1 mdm_dj fdm_dj

*4.5.3. Age category, primary adult female decision-makers (de jure only)
*       Create a continuous variable that indicates the age of primary adult 
*       female decision-makers who are de jure household members according to 
*       the age variable. 
recode age (18/24=1  "18-24") ///
		   (25/29=2  "25-29") ///   
		   (30/34=3  "30-34") ///
		   (35/39=4  "35-39") ///
		   (40/44=5  "40-44") ///
		   (45/49=6  "45-49") ///
		   (50/54=7  "50-54") ///		   
		   (55/59=8  "55-59") ///
		   (60/95=9  "60+") if fdm_dj==1 & v600r==1, gen(agegrp_fdm_dj)
la var agegrp_fdm_dj "Age category of female PADM, de jure HH member"
tab agegrp_fdm_dj

*4.5.4. Youth, primary adult female decision-makers (de jure only)
*       Create a variable that indicates whether primary adult female decision-makers 
*       who are de jure HH members are youth (18-29 years of age) (youth_fdm_dj).
*       If a woman's self-reported age is missing in the women's empowerment in 
*       agriculture module, this variable is missing a value. 
gen youth_fdm_dj=0 if fdm_dj==1
replace youth_fdm_dj=1 if fdm_dj==1 & age>=18 & age<30 
replace youth_fdm_dj=. if v600r!=1
la val youth_fdm_dj YESNO
la var youth_fdm_dj "Female PADM is 18-29 years (youth), de jure HH member"
tab youth_fdm_dj

*4.5.5. Marital status, primary adult female decision-maker (de jure only)
*       If a woman's marital status information is missing in Module 6, this 
*       variable is missing a value. 
gen     marstat_fdm_dj=1 if v6105==1 & fdm_dj==1 
replace marstat_fdm_dj=2 if v6105==2 & fdm_dj==1 
replace marstat_fdm_dj=3 if v6105==3 & v6107==1 & fdm_dj==1
replace marstat_fdm_dj=4 if v6105==3 & (v6107==2 | v6107==3) & fdm_dj==1  
replace marstat_fdm_dj=5 if v6105==3 & v6106==3 & fdm_dj==1 

la def MARSTAT 1 "Married" 2 "Living together" 3 "Widowed" 4 "Divorced or separated" ///
			   5 "Never married or in a union", replace
la val marstat_fdm_dj MARSTAT
la var marstat_fdm_dj "Female PADM marital status, de jure HH member"
tab marstat_fdm_dj

*4.5.6. Primary adult female decision-makers who participate in agricultural 
*       production, non-farm work, and wage or salary work (de jure only)
*       If a woman's economic participation information is missing in Module 6,  
*       these variables are missing values.
tab1 v6201_1-v6201_6  

*4.5.6.1. Create temporary new variables for the Module 6 economic activity 
*         participation variables that reocode No's (2) to 0 and Inconsistent's 
*         (7) or Missing's (9) to Missing (.) (v6201_1x-v6201_6x).
for var v6201_1-v6201_6: recode X 2=0 7 9=., gen(Xx) 
for var v6201_1x-v6201_6x: lab val X YESNO

*4.5.6.2. Create a variable that counts the number variables created in the
*         previous step that are missing a value (0-6) and set the variable
*         to missing if Module 6 was not completed or if the primary adult female
*         decision-maker is not a usual HH member (fdm_econ_miss).
egen fdm_econ_miss=rmiss(v6201_1x-v6201_6x) 
replace fdm_econ_miss=. if v600r!=1 | fdm_dj!=1
la var fdm_econ_miss "Number of activities female PADM is missing, de jure HH member"
tab  fdm_econ_miss

*4.5.6.3. Create a variable to flag whether the primary adult female decision-maker
*         participated in agricultural production (i.e., food crop farming, cash 
*         crop farming, livestock raising, or fishpond culture/fishing) (fdm_econ_farm)
gen fdm_econ_farm=0 if v600r==1 
replace fdm_econ_farm=1 if (v6201_1==1 | v6201_2==1 | v6201_3==1 | v6201_4==1)
replace fdm_econ_farm=. if fdm_econ_miss==6 | fdm_dj!=1
lab val fdm_econ_farm YESNO
lab var fdm_econ_farm "Female PADM partook in farm work, de jure HH member"

*4.5.6.4. Create a variable to flag whether the primary adult female decision-maker
*         participated in non-farm work (fdm_econ_nonfarm)
gen fdm_econ_nonfarm=0 if v600r==1
replace fdm_econ_nonfarm=1 if v6201_5==1
replace fdm_econ_nonfarm=. if fdm_econ_miss==6 | fdm_dj!=1 
lab val fdm_econ_nonfarm YESNO
lab var fdm_econ_nonfarm "Female PADM partook in non-farm work, de jure HH member"

*4.5.6.5. Create a variable to flag whether the primary adult female decision-maker
*         participated in wage or salary work (fdm_econ_wage)
gen fdm_econ_wage=0 if v600r==1
replace fdm_econ_wage=1 if v6201_6==1
replace fdm_econ_wage=. if fdm_econ_miss==6 | fdm_dj!=1  
lab val fdm_econ_wage YESNO
lab var fdm_econ_wage "Female PADM partook in wage/salary work, de jure HH member"

*4.5.6.6. Create a variable to flag whether the primary adult female decision-maker
*         participated in any economic work (fdm_econ_any)
gen fdm_econ_any=0 if v600r==1
replace fdm_econ_any=1 if fdm_econ_farm==1 | fdm_econ_nonfarm==1 | fdm_econ_wage==1
replace fdm_econ_any=. if fdm_econ_miss==6 | fdm_dj!=1 
lab val fdm_econ_any YESNO
lab var fdm_econ_any "Female PADM partook in any economic work, de jure HH member"

tab1 fdm_econ_*
drop v6201_1x v6201_2x v6201_3x v6201_4x v6201_5x v6201_6x fdm_econ_miss

********************************************************************************
**#PRODUCERS (FARMERS) VARIABLES
********************************************************************************
*This step requires customization to align with the country questionnaire. The
*targeted VCCs will vary by country. The template code was set up for a survey
*that included maize, dairy cows, sheep, and fish.

***INSTRUCTIONS: Update code to reflect VCCs included in the survey.
tab vfarmer
tab farmstat

*4.6.1 Targeted VCC producer, any VCC
*4.6.1.1. Examine the consent and outcome variables for each VCC module to determine 
*         who was eligible to be interviewed and completed the modules.
tab v7100d 	v7100r  //Maize (Module 7.1)
tab v75000d v75000r //Dairy (Module 7.50)
tab v75200d v75200r //Sheep (Module 7.52)
tab v78000d v78000r //Fishpond (Module 7.80)

*4.6.1.2. Create a variable to indicate if HH member was responsible for producing
*         any VCC during the 12 months preceding the survey.
gen vcc=0
replace vcc=1 if v7100r!=. | v75000r!=. | v75200r!=. | v78000r!=.
lab val vcc YESNO
lab var vcc "Producer of 1+ targeted VCC, past 12 months"

*4.6.2. Targeted VCC producer, specific VCCs
*       Create variables to indicate if HH member was responsible for producing 
*       specific VCCs during the 12 months preceding the survey, regardless of 
*       whether they completed the VCC module
*4.6.2.1. Cultivated maize (vcc_maize2)
gen vcc_maize2=0
replace vcc_maize2=1 if v7100r!=.
lab val vcc_maize2 YESNO
lab var vcc_maize2 "Maize producer, past 12 months"
tab vcc_maize2 

*4.6.2.2. Raised dairy cows (vcc_dairy2)
gen vcc_dairy2=0
replace vcc_dairy2=1 if v75000r!=.
lab val vcc_dairy2 YESNO
lab var vcc_dairy2 "Dairy cow producer, past 12 months"
tab vcc_dairy2 

*4.6.2.3. Rasied sheep (vcc_sheep2).
gen vcc_sheep2=0
replace vcc_sheep2=1 if v75200r!=.
lab val vcc_sheep2 YESNO
lab var vcc_sheep2 "Sheep producer, past 12 months"
tab vcc_sheep2

*4.6.2.4. Cultivated fishponds (vcc_fish2).
gen vcc_fish2=0
replace vcc_fish2=1 if v78000r!=.
lab val vcc_fish2 YESNO
lab var vcc_fish2 "Fishpond producer, past 12 months"
tab vcc_fish2 

*4.6.3. Targeted VCC producer who completed relevant agriculture module
*       Create variables to indicated if HH member was responsible for producing 
*       specific VCCs and completed the VCC module
*4.6.3.1. Cultivated maize, completed maize module (vcc_maize)
gen vcc_maize=0
replace vcc_maize=1 if v7100r==1
lab val vcc_maize YESNO
lab var vcc_maize "Maize producer, completed maize module"
tab vcc_maize

*4.6.3.2. Raised dairy cows, completed dairy cow module (vcc_dairy2)
gen vcc_dairy=0
replace vcc_dairy=1 if v75000r==1
lab val vcc_dairy YESNO
lab var vcc_dairy "Dairy cow producer, completed dairy cow module"
tab vcc_dairy

*4.6.3.3. Raised sheep, completed sheep module (vcc_sheep2)
gen vcc_sheep=0
replace vcc_sheep=1 if v75200r==1
lab val vcc_sheep YESNO
lab var vcc_sheep "Sheep producer, completed sheep module"
tab vcc_sheep 

*4.6.3.4. Cultivated fishponds, completed fishpond module (vcc_fish2)
gen vcc_fish=0
replace vcc_fish=1 if v78000r==1
lab val vcc_fish YESNO
lab var vcc_fish "Fishpond producer, completed fishpond module"
tab vcc_fish 

*********************************************************************************
**#LABEL AND SAVE DATA
********************************************************************************

sort  hhea hhnum m1_line

la data "Persons analytic data - [COUNTRY] [YEAR]"
save "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta",replace

********************************************************************************
**#Primary adult female decision-maker characteristics
********************************************************************************
*(Guide to Feed the Future Midline Statistics Section 7.2)
/*Sample-weighted indicators:
	7.2.1. % distribution of PAFDMs by age group 
	7.2.2. % distribution of PAFDMs by their current marital status
	7.2.3. % of PAFDMs who participate in economic activities
	7.2.4. % of PAFDMs who participate in: 
	             - farm work
				 - non-farm work
				 - wage or salaried employment
*/

*Step 1: Load the persons analytic data file
use "$analytic\FTF ZOI Survey [COUNTRY] [YEAR] persons data analytic.dta", clear

*Step 2. Apply the survey design and PAFDM's sampling weight
svyset hhea [pw=wgt_fpdm], strata(strata) 

*Step 3: Tabulate indicator values for PAFDMs
*7.2.1: % distribution of PAFDMs by age group 
svy: tab agegrp_fdm_dj 

*7.2.2. % distribution of PAFDMs by their current marital status
svy: tab marstat_fdm_dj 

*7.2.3. % of PAFDMs who participate in economic activities
svy: tab fdm_econ_any 

*7.2.4. % of PAFDMs who participate in farm work, non-farm work, and wage or salaried employment
svy: tab fdm_econ_farm 
svy: tab fdm_econ_nonfarm 
svy: tab fdm_econ_wage 

di "Date:$S_DATE $S_TIME"
log  close