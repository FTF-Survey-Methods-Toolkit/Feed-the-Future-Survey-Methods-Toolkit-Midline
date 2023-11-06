################################################################################
#              FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS 
#                        FOOD INSECURITY - FIES INDICATOR
#                                 [COUNTRY] [YEAR] 
################################################################################
#Description: This code calculates the prevalence of moderate and severe food 
#according to the Food Insecurity Experiences Scale (FIES) and exports the 
#results to CSV and Stata files. The code follows Section 15.2 in the Guide to
#Feed the Future Statistics for Phase Two Midline Surveys.

#Syntax prepared by ICF, 2018
#Syntax revised by ICF, September 2023

#This syntax file was developed using the core Feed the Future phase 1 endline/
#phase 2 baseline ZOI Survey questionnaire and revised using the core Feed the 
#Future Midline Survey parallel survey questionnaire. It must be adapted for the 
#final country-specific questionnaire. The syntax was only be partially tested 
#using ZOI Survey data; therefore, double-check all results carefully and 
#troubleshoot to resolve any issues identified. 

############################# Step 1. ########################################
# Download R, install the required packages, set a working directory, 
# and read the data into R.

# Step 1a. Go to https://cran.r-project.org/ to download R. 
# After it is downloaded, R can be used directly in the console or through a 
# user-friendly compiler, RStudio, which needs to be downloaded separately. 

# Step 1b. Go to https://www.rstudio.com/products/rstudio/download/ to download 
# RStudio, which is an integrated development environment for R. It includes a 
# console, a syntax-highlighting editor that supports direct code execution, and
# tools for plotting, tracking history, debugging, and managing the workspace.

# Step 1c. Install and upload the required packages. 
install.packages("RM.weights") # for Rasch modeling
install.packages("survey") # for analysis of complex survey samples 
install.packages("haven") # to read data stored in Stata, SPSS, or other software
install.packages("tidyverse") # for data manipulation

library(RM.weights)
library(haven)
library(tidyverse)
library(survey)

# Step 1d. Specify the working directory in which the data are stored. 
# This will serve as the root directory. 
setwd("FIES\\FTF ZOI Survey [COUNTRY] [YEAR] NAME")


# Step 1e. Load in script to calculate the margin of error (MOE). 
# Read the source code of the moe function to calculate the confidence interval
# and design effect. Before running the code, ensure that the 
# "moe_nat_psu_strata_v2.R" file is located in the working directory, and call 
# the moe function into the code. 
source("moe_nat_psu_strata_v2.R")

# Step 1f. create a new function to compute population standard deviation
var.p <- function(x) var(x) * (length(x)-1) / length(x)
sd.p <- function(x) sqrt(var.p(x))

# Step 1g. Use the haven package to read in the ZOI Survey 
# household-level analytic data file with the Stata labels preserved.

ftfzoi_midline_import <- read_dta("FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta")

# if working with baseline together 
ftfzoi_baseline_import <- read_dta("FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta")


########## STEP 2. DATA PREPARATION #############################

# Step 2a. Create a data frame (ftfzoi_midline) in which the FIES survey 
# variables are renamed to the corresponding items that will be used in the 
# Rasch model using the rename function. 

ftfzoi_midline <-
  ftfzoi_midline_import %>%
  rename(
    "WORRIED" = "v301", 
    "HEALTHY" = "v302", 
    "FEWFOOD" = "v303", 
    "SKIPPED" = "v304", 
    "ATELESS" = "v305", 
    "RUNOUT"  = "v306", 
    "HUNGRY"  = "v307", 
    "WHLDAY"  = "v308")

# repeat step for baseline

ftfzoi_baseline <-
  ftfzoi_baseline_import %>%
  rename(
    "WORRIED" = "v301", 
    "HEALTHY" = "v302", 
    "FEWFOOD" = "v303", 
    "SKIPPED" = "v304", 
    "ATELESS" = "v305", 
    "RUNOUT"  = "v306", 
    "HUNGRY"  = "v307", 
    "WHLDAY"  = "v308")

# Step 2b. Recode all variables in the ftfzoi_midline data frame created in 
# Step 2a. Keep ‘YES’ responses coded as ‘1,’ and recode 
# ‘NO’ responses as ‘0.’ ‘REFUSED’ responses (‘7’) will be set to missing (NA) 
# and excluded from the analysis.

# recode FIES vars - NO response from 2 to 0
ml_hh_midline <- 
  ml_hh_midline %>% mutate_at(dplyr::vars(WORRIED:WHLDAY),
                               dplyr::funs(case_when(
                                 . == 1 ~ 1,
                                 . == 2 ~ 0)
                               ))
# BASELINE (optional)
ml_hh_baseline <- 
  ml_hh_baseline %>% mutate_at(dplyr::vars(WORRIED:WHLDAY),
                               dplyr::funs(case_when(
                                 . == 1 ~ 1,
                                 . == 2 ~ 0)
                               ))
# Step 2c. Store the complex survey design variables and disaggregate variables 
# that will be used later for analysis. Remember to edit the variable names, 
# values, and labels as needed.

# variables used for complex survey design - weights, household 
# size, cluster ID, HHID, strata
ftfzoi_midline$wt <- ftfzoi_midline$wgt_hh
ftfzoi_midline$hhsize_dj <- ftfzoi_midline$hhsize_dj
ftfzoi_midline$hhnum <- ftfzoi_midline$hhnum 
ftfzoi_midline$strata <- ftfzoi_midline$strata 

# Disaggregates – gendered HH type, residency, shock severity, wealth index
ftfzoi_midline$ahtype <- factor(ftfzoi_midline$ahtype, levels=c(1,2), 
                                labels=c("urban","rural"))

ftfzoi_midline$genhhtype_dj <- factor(ftfzoi_midline$genhhtype_dj, 
                                      levels=c(1,2,3,4), 
                                      labels=c("Male and Female adults",
                                               "Female adults only",
                                               "Male adults only", 
                                               "Children only"))

ftfzoi_midline$shock_sev <- factor(ftfzoi_midline$shock_sev, levels = c(1,2,3,4), 
                                   labels = c("None", "Low", "Medium", "High"))

ftfzoi_midline$awiquint <- factor(ftfzoi_midline$awiquint, levels = c(1,2,3,4,5), 
                                  labels = c("Poorest", "Second", "Middle", 
                                             "Fourth", "Wealthiest"))

# select variables 
ftfzoi_midline  <- ftfzoi_midline %>%
select(wt, mem, hhea  , hhnum, strata, ahtype, genhhtype_dj, shock_sev, 
       awiquint, WORRIED:WHLDAY)

# BASELINE (OPTIONAL)
# variables used for complex survey design - weights, household 
# size, cluster ID, HHID, strata
ftfzoi_baseline$wt <- ftfzoi_baseline$wgt_hh
ftfzoi_baseline$hhsize_dj <- ftfzoi_baseline$hhsize_dj
ftfzoi_baseline$hhnum <- ftfzoi_baseline$hhnum 
ftfzoi_baseline$strata <- ftfzoi_baseline$strata 

# Disaggregates – gendered HH type, residency, shock severity, wealth index
ftfzoi_baseline$ahtype <- factor(ftfzoi_baseline$ahtype, levels=c(1,2), 
                                 labels=c("urban","rural"))
ftfzoi_baseline$genhhtype_dj <- factor(ftfzoi_baseline$genhhtype_dj, 
                                      levels=c(1,2,3,4), 
                                      labels=c("Male and Female adults",
                                               "Female adults only",
                                               "Male adults only", 
                                               "Children only"))

ftfzoi_baseline$shock_sev <- factor(ftfzoi_baseline$shock_sev,
                                    levels = c(1,2,3,4), labels = c("None", 
                                                                    "Low", 
                                                                    "Medium", 
                                                                    "High"))

ftfzoi_baseline$awiquint <- factor(ftfzoi_baseline$awiquint, levels = c(1,2,3,4,5), 
                                   labels = c("Poorest", "Second", "Middle", 
                                              "Fourth", "Wealthiest"))

# select variables 
ftfzoi_baseline  <- ftfzoi_baseline %>%
  select(wt, mem, hhea  , hhnum, strata, ahtype, genhhtype_dj,
         shock_sev, awiquint, WORRIED:WHLDAY)


# Step 2d. Missing values


# remove HHs where all FIES items are missing
ftfzoi_midline <- ftfzoi_midline %>%
  filter_at(dplyr::vars(WORRIED:WHLDAY), 
            dplyr::all_vars(!is.na(.)))

# explore data with individual missing items
ftfzoi_midline %>%
  filter_at(dplyr::vars(WORRIED:WHLDAY), 
            dplyr::any_vars(is.na(.))) 

# impute for missing values on ATELESS
ftfzoi_midline <- ftfzoi_midline %>%
  dplyr::mutate(ATELESS = case_when(WORRIED == 0 & HEALTHY == 0 & FEWFOOD == 0 &
                                    SKIPPED == 0 & RUNOUT  == 0 & HUNGRY  == 0 & 
                                    WHLDAY  == 0 & is.na(ATELESS) ~ 0, 
                                    TRUE ~ as.numeric(ATELESS)))


# check percentages to guide imputation
ftfzoi_midline %>% 
  select(WORRIED:WHLDAY) %>%
  colMeans()

#Step 2e. Create data frame with only FIES items
FIES_midline <- ftfzoi_midline %>%
  select(WORRIED:WHLDAY)

FIES_baseline <- ftfzoi_baseline %>%
  select(WORRIED:WHLDAY)

######### 3. Rasch modeling ###############

# Step 3a. Run the Rasch model on the selected FIES items and households after 
# data preparation and handling missing data,   using the data frame created in 
# Step 2e (FIES_midline). Use the RM.w function of the RMweights package to run 
# the model. 
FIES_midline_rasch <- RM.w(FIES_midline, write.file = TRUE, 
                           country = "FTF ZOI SURVEY COUNTRY")
FIES_midline_RS = rowSums(FIES_midline)

# BASELINE (Skip if not working with BL)
FIES_baseline_rasch <- RM.w(FIES_baseline, write.file = TRUE, 
                           country = "FTF ZOI SURVEY COUNTRY")
FIES_baseline_RS = rowSums(FIES_baseline)

# step 3b. Check diagnostic statistics (Only outlined for Midline. If working with
# baseline, repeat same steps on baseline data)

round(FIES_midline_rasch$infit) # to see infit scores for each item/question

round(FIES_midline_rasch$infit.person) # to see individual infit scores

round(FIES_midline_rasch$outfit, digits = 2)   # to see outfit scores for each item/question

round(FIES_midline_rasch$outfit.person, digits = 2) # to see individual outfit scores

round(FIES_midline_rasch$reliab.fl, digits = 2) # reliability stat 

round(sd.p(FIES_midline_rasch$b), digits = 2) # calculate pop. Standard deviation of item scores.

plot(prcomp(FIES_midline_rasch$mat.res)$sd^2) # view PCA residuals


#### USE THIS CODE AS GUIDANCE IN CASE AN ITEM OR HH NEEDS TO BE REMOVED.
#### BE SURE TO RERUN RASCH MODEL AFTER REMOVING EITHER AN ITEM OR HH.
##### # item (column) removal – WORRIED
##### FIES_midline <- FIES_midline[, -1]
##### FIES_midline_rasch <- RM.w(as.matrix(FIES_midline), write.file = TRUE, country = "FTF ZOI SURVEY COUNTRY")

##### # row (household) removal – HH ar row number 30 
##### FIES_midline <- FIES_midline[-30, ]
##### FIES_midline_rasch <- RM.w(as.matrix(FIES_midline), write.file = TRUE, country = "FTF ZOI SURVEY COUNTRY")




#### Step 4. Use equating processes to adjust the midline data to baseline ####
# so that they are on the same local scale 

# NOTE: This is only an option if you have access to both datasets or Rasch outputs
# If you do not have this for the baseline, then skip Step 4.

# Step 4a. Create a graph to compare baseline and midline item severity scores divided by the item standard deviation.
{
  x  <- FIES_baseline_rasch$b/sd.p(FIES_baseline_rasch$b)
  y_bl <- FIES_baseline_rasch$b/sd.p(FIES_baseline_rasch$b)
  y_ml  <- FIES_midline_rasch$b/sd.p(FIES_midline_rasch$b)
  plot(x,y_bl, col = 1, ylim = c(-2.5,2),ylab="Severity",xlab="Severity")
  points(x, y_ml, col = 2)
  text(x+0.04,x-0.55,colnames(FIES),cex=0.6,pos=2,srt=90)
  abline(0,1,lty = 2)
  legend("topleft",c("baseline","midline"),pch = 1, col = c(1,2), cex = 0.75)
  title(main = "Comparing scales across surveys")
}

abs(round(FIES_baseline_rasch$b/sd.p(FIES_baseline_rasch$b) - FIES_midline_rasch$b/sd.p(FIES_midline_rasch$b), 2))


# Step 4b. Create vectors with common items to be used to calculate the mean and standard deviation of the common item severity scores for both baseline and midline. 
# identify items in common – one where scores are similar
not_common  <-  c("WHLDAY","RUNOUT")
common  <- setdiff(colnames(FIES_midline),not_common)
# mean of common item scores 
m.bl <- mean(res_bl$b[common]) 
m.ml  <- mean(res_ml$b[common])
# sd of common item scores
s.bl  <- sd.p(res_bl$b[common])
s.ml  <- sd.p(res_ml$b[common])

# adjust midline scale to the baseline metric
# assign Midline rasch object to Adjusted Midline rasch object
FIES_midline_rasch_adj  <- FIES_midline_rasch
# adjusted mean of item severity scores
FIES_midline_rasch_adj$b  <- (FIES_midline_rasch$b - m.ml)/s.ml*s.bl + m.bl
# adjusted mean of raw score severity scores
FIES_midline_rasch_adj$a  <- (FIES_midline_rasch$a - m.ml)/s.ml*s.bl + m.bl
# adjusted standard deviation of raw scores
FIES_midline_rasch_adj$se.a  <- FIES_midline_rasch_adj$se.a/s.ml*s.bl

# Step 4c. Create a matrix with the weighted   distributions of baseline and midline raw scores to use for the prevalence calculations.
RS_table  <- t(cbind(
  "Baseline" = aggregate(ftfzoi_baseline$wt, list(FIES_baseline_RS), FUN=sum, na.rm=TRUE)$x /sum(ftfzoi_baseline$wt [!is.na(FIES_baseline_RS)]),
  "Midline" = aggregate(ftfzoi_midline$wt, list(FIES_midline_RS), FUN=sum, na.rm=TRUE)$x /sum(ftfzoi_midline$wt [!is.na(FIES_midline_RS)])
))


######## Step 5. Map the global scale onto the local baseline scale ###########
# This is to obtain thresholds for moderate and severe food insecurity
# ensuring that measurement is consistent across datasets. 

# Step 5a. Define the local (baseline) and the global scales
# NOTE: We use the baseline as the anchor for our analysis given the adjustment 
# of the Midline to the Baseline. If not working with a baseline, then use the 
# Midline as the Local Scale.
loc_st <- FIES_baseline_rasch$b
glob_st  <- c("WORRIED"= -1.2230564, "HEALTHY"= -0.847121, "FEWFOODS"= -1.1056616,
              "SKIPPED" = 0.3509848, "ATELESS" = -0.3117999, 
              "RUNOUT" = 0.5065051, "HUNGRY" = 0.7546138, "WHLDAY" = 1.8755353)

# Step 5b. Obtain the absolute value of the difference of the standardized 
# versions of the local and global scales. 

# standardized version of both scales – item severity score divided by the population SD
abs(round(loc_st/sd.p(loc_st) - glob_st/sd.p(glob_st), 2))

# Step 5c. Calculate the mean and standard deviation of the common item severity
# scores for both the global and local scales. 

# produce mean and sd for each scale among common items used in equating
# NOTE: In this example, we use columns 2,3,4,6,7,8.
# Adapt as needed
glob_st.m <- mean(glob_st[c(2:4, 6:8)])
glob_st.s <- sd.p(glob_st[c(2:4, 6:8)])
m.bl  <- mean(loc_st   [c(2:3, 6:8)]) 
s.bl  <- sd.p(loc_st[c(2:3, 6:8)])


# Step 5d. Adjust the global scale to fit the local scale. 
# Note: The thresholds are defined as items 5 and 8 of the adjusted scale based on 
# the FAO’s thresholds for moderate and severe food insecurity.

# mapping the thresholds from the global scale onto the local (baseline) scale
glob_st_adj  <- (glob_st - glob_st.m)/(glob_st.s * s.bl  + m.bl)
newthres  <- glob_st_adj[c(5,8)]


#### Step 6. Calculate the prevalence of mod + sev, mod, sev food insecurity ####

# Step 6a. Assign a probability to each household that it is beyond the moderate
# food insecurity threshold and then calculate the prevalence of moderate and 
# severe food insecurity using matrix multiplication of each household’s score 
# probabilities against the frequency of raw scores in the sample: 
  
# moderate+severe FI
# midline
glo_probs_ml_mod_sev <- 1-pnorm(newthres[1], mean = FIES_midline_rasch_adj$a, sd = FIES_midline_rasch_adj$se.a)

glo_prev_ml_adj_mod_sev <- glo_probs_ml_mod_sev %*% FIES_midline_RS[2,]

#baseline (if needed)
glo_probs_bl_mod_sev <- 1-pnorm(newthres[1], mean = FIES_baseline_rasch$a, sd = FIES_baseline_rasch$se.a)
glo_prev_bl_mod_sev <- glo_probs_bl_mod_sev %*% FIES_baseline_RS[1,]

# Step 6b. Follow a similar process to calculate the prevalence of severe food insecurity.

# severe FI
# midline 
glo_probs_ml_sev <- 1-pnorm(newthres[2], mean = FIES_midline_rasch_adj$a, sd = FIES_midline_rasch_adj$se.a)

glo_prev_ml_adj_sev <- glo_probs_ml_sev %*% FIES_midline_RS[2,]

#baseline (if needed)
glo_probs_bl_sev <- 1-pnorm(newthres[2], mean = FIES_baseline_rasch$a, sd = FIES_baseline_rasch$se.a)

glo_prev_bl_sev  <- glo_probs_bl_sev %*% FIES_baseline_RS[1,]
# Step 6c. Calculate the prevalence of moderate food insecurity by obtaining the 
# difference between the moderate and severe food insecurity prevalence and 
# severe food insecurity prevalence. 

# create moderate only  <- mod+sev – sev
# prevalence
glo_prev_bl_mod <- glo_prev_bl_mod_sev - glo_prev_bl_sev   
glo_prev_ml_adj_mod <- glo_prev_ml_adj_mod_sev - glo_prev_ml_adj_sev

# probability of moderate food insecurity at each raw score
glo_probs_bl_mod <- glo_probs_bl_mod_sev - glo_probs_bl_sev
glo_probs_ml_mod <- glo_probs_ml_mod_sev - glo_probs_ml_sev 

# Step 6d. Add the prevalence results to a common object and assign probabilities
# to each household in the original data frame read in Step 1G.
# put into common object
glo_prev_bl <- c(glo_prev_bl_mod_sev, glo_prev_bl_mod, glo_prev_bl_sev)
glo_prev_ml <- c(glo_prev_ml_adj_mod_sev, glo_prev_ml_adj_mod, glo_prev_ml_adj_sev)

#Attaching probabilities to each case/HH
ftfzoi_baseline$prob_mod_sev  <- NULL
ftfzoi_midline$prob_mod_sev  <- NULL

ftfzoi_baseline$prob_mod  <- NULL
ftfzoi_midline$prob_mod  <- NULL

ftfzoi_baseline$prob_sev  <- NULL
ftfzoi_midline$prob_sev  <- NULL

for (rs in 0:8) {
  ftfzoi_baseline$prob_mod[ftfzoi_baseline$RS == rs] = glo_probs_bl_mod[rs+1]
  ftfzoi_midline$prob_mod[ftfzoi_midline$RS == rs] =   glo_probs_ml_mod[rs+1]
  ftfzoi_baseline$prob_mod_sev[ftfzoi_baseline$RS == rs] = glo_probs_bl_mod_sev[rs+1]
  ftfzoi_midline$prob_mod_sev[ftfzoi_midline$RS == rs] =   glo_probs_ml_mod_sev[rs+1]
  ftfzoi_baseline$prob_sev[ftfzoi_baseline$RS == rs] = glo_probs_bl_sev[rs+1]
  ftfzoi_midline$prob_sev[ftfzoi_midline$RS == rs] =   glo_probs_ml_sev[rs+1]
}

# review output  
table(ftfzoi_midline$prob_mod, RS, useNA = "ifany")
table(ftfzoi_midline$prob_mod_sev, RS, useNA = "ifany")
table(ftfzoi_midline$prob_sev, RS, useNA = "ifany")

### Step 7. Create binary variable (optional) ####
# Now that each household has a probability assigned for each level of 
# severity, an optional step is to assign binary variables to the different food
# insecurity levels. This can be helpful when trying to use food insecurity as a
# disaggregate in the analysis of other variables. To do this, use an ifelse 
# statement that assigns 1 if the unit is .5 or over and 0 if the unit is below.

ftfzoi_midline$fi_mod_sev_bin <-   ifelse(ftfzoi_midline$prob_mod_sev <= .5, 1, 0)
ftfzoi_midline$fi_mod_bin <- ifelse(ftfzoi_midline$prob_mod <= .5, 1, 0)
ftfzoi_midline$fi_sev_bin <- ifelse(ftfzoi_midline$prob_sev <= .5, 1, 0)
ftfzoi_baseline$fi_mod_sev_bin <- ifelse(ftfzoi_baseline$prob_mod_sev <= .5, 1, 0)
ftfzoi_baseline$fi_mod_bin <- ifelse(ftfzoi_baseline$prob_mod <= .5, 1, 0)
ftfzoi_baseline$fi_sev_bin <- ifelse(ftfzoi_baseline$prob_sev <= .5, 1, 0)



# Step 8. Calculate the baseline and midline margins of error (MoE) and sig. test
# The MoE is used to detect statistically significant changes in the food 
# insecurity estimates over time.

# NOTE: confidence level can be adjusted as needed. PSU and Strata are optional
# NOTE: only displaying mod+sev food insecurity prevalence rate. mod fi and sev fi
# can be seen below
modsev_ml_moe_95 <- moe(ftfzoi_midline$prob_mod_sev,ftfzoi_midline$RS,
                        ftfzoi_midline$wt * 10^6, conf.level = .95, 
                        psu = ftfzoi_midline$psu, 
                        strata = ftfzoi_midline$strata)$moe * 100

# BASELINE 
modsev_bl_moe_95 <- moe(ftfzoi_baseline$prob_mod_sev,ftfzoi_baseline$RS,
                        ftfzoi_baseline$wt * 10^6, conf.level = .95, 
                        psu = ftfzoi_baseline$psu, 
                        strata = ftfzoi_baseline$strata)$moe * 100

# OPTIONAL: test of significance between time periods for mod+sev FI

fies_diff <- glo_prev_bl[1] - glo_prev_ml[1] # calculate difference
ifelse(fies_diff > modsev_ml_moe_95, TRUE, FALSE) # output will indicate whether statement is TRUE or FALSE

# other fi prevelance rate levels
mod_moe_bl_95 <- moe(ftfzoi_baseline$prob_mod,ftfzoi_baseline$RS,ftfzoi_baseline$wt * 10^6, 
                     conf.level = .95,
                     psu = ftfzoi_baseline$psu, strata = ftfzoi_baseline$strata)$moe * 100
sev_moe_bl_95 <- moe(ftfzoi_baseline$prob_sev,ftfzoi_baseline$RS,ftfzoi_baseline$wt * 10^6, 
                     conf.level = .95,
                     psu = ftfzoi_baseline$psu, strata = ftfzoi_baseline$strata)$moe * 100

moe_bl_95 <- c(modsev_moe_bl_95, mod_moe_bl_95, sev_moe_bl_95) # put MoE for BL 
# into common object

# Midline
mod_moe_ml_95 <- moe(ftfzoi_midline$prob_mod,ftfzoi_midline$RS,
                     ftfzoi_midline$wt * 10^6, conf.level = .95,
                     psu = ftfzoi_midline$psu, strata = ftfzoi_midline$strata)$moe * 100
sev_moe_ml_95 <- moe(ftfzoi_midline$prob_sev,ftfzoi_midline$RS,
                     ftfzoi_midline$wt * 10^6, conf.level = .95,
                     psu = ftfzoi_midline$psu, strata = ftfzoi_midline$strata)$moe * 100
moe_ml_95 <- c(modsev_moe_ml_95, mod_moe_ml_95, sev_moe_ml_95)

##### Step 9. Store all results ###### 
# includes the baseline and midline weighted and unweighted number of observations, 
# the estimates for moderate and severe food insecurity, moderate food insecurity, 
# and severe food insecurity, and the MoE and 95% confidence interval 
# for each estimate) in a data frame, AGG_df.

## Calculate aggregate prevalence levels and put in df  

# create empty DF
AGG_df <- matrix(NA, nrow = 2, ncol = 17)
# add column and rownames
colnames(AGG_df) = c("Moderate+Severe_Food_Insecurity", "Moderate_Food_Insecurity", "Severe_Food_Insecurity",
                      "N","WN", 
                      "MSFI_MoE", "MFI_MoE","SFI_MoE",
                      "MSFI_CI_Low", "MFI_CI_Low", "SFI_CI_Low",
                      "MSFI_CI_High", "MFI_CI_High", "SFI_CI_High",
                      "MSFI_Sig", "MFI_Sig", "SFI_Sig")
rownames(AGG_df) = c("Baseline","Midline")
# add in values
AGG_df[1, c(1,2, 3)] <- glo_prev_bl * 100
AGG_df[1, c(4)] <- nrow(FIES_baseline_rasch$XX)
AGG_df[1, c(5)] <- round(sum(ftfzoi_baseline$wt * 10^6), 2)
AGG_df[1, c(6, 7, 8)] <- moe_bl_95
AGG_df[1, c(9, 10, 11)] <- (glo_prev_bl * 100) - moe_bl_95 
AGG_df[1, c(12, 13, 14)] <- (glo_prev_bl * 100) + moe_bl_95
AGG_df[1, c(15, 16, 17)] <- c(NA, NA, NA)

AGG_df[2, c(1,2, 3)] <- glo_prev_ml * 100
AGG_df[2, c(4)] <- nrow(res_ml$XX)
AGG_df[2, c(5)] <- round(sum(FIES_midline_rasch$wt * 10^6), 2)
AGG_df[2, c(6, 7, 8)] <- moe_ml_95
AGG_df[2, c(9, 10, 11)] <- (glo_prev_ml * 100) - moe_ml_95 
AGG_df[2, c(12, 13, 14)] <- (glo_prev_ml * 100) + moe_ml_95
AGG_df[2, c(15, 16, 17)] <- ifelse(((glo_prev_ml * 100) - (glo_prev_bl * 100)) > moe_ml_95, "T", "F")

# Convert matrix to dataframe and convert row ID to column.
AGG_df <- AGG_df %>%
  as.data.frame() %>%
  rownames_to_column("Survey_Round")
# view results
head(AGG_df)

# Step 10. Calculate midline estimates for disaggregates. 

# Step 10a. Define the disaggregates to be included in this analysis. 
# Computing prevalence and MoEs by groups
# survey round
# urban rural
group1 = ftfzoi_midline$urbanrural

group2 = ftfzoi_midline$genhhtype_dj
group2 <- factor(group4, levels = c(1,2,3,4), labels = c("De jure male and female adults","De jure female, no male", "De jure male, no female", "De jure children only")) 

group3 <- ftfzoi_midline$shock_sev[!is.na(ftfzoi_midline$shock_sev)]
group3 <- factor(group5, levels = c(1,2,3,4), labels = c("None", "Low", "Medium", "High"))

group4 <- ftfzoi_midline$awiquint[!is.na(ftfzoi_midline$awiquint)]
group4 <- factor(group6, levels = c(1,2,3,4,5), labels = c("Poorest", "Second", "Middle", "Fourth", "Wealthiest"))


# Step 10b. Add the disaggregate variables to the group_list and groups objects 
# so that they are included in the loop function.
group_list <- list(group1, group2, group3, group4)

groups <- c(unique(as.character(group1)), unique(as.character(group2)),
            unique(as.character(group3)), unique(as.character(group4)))


# Step 10c. Use loop function to calculate disaggregate estimates. 
# Create an empty data frame (mod_sev_fi_ml) and use a loop function 
# to calculate prevalence, unweighted and weighted number of observations, and 
# the MoE for each disaggregate at midline and store the results in the data frame. 

# create empty data frame for results
mod_sev_fi_ml <- data.frame()
# loop function
for (i in 1:length(group_list)) {
  for (dis in unique(groups)) {
    if(!(dis %in% group_list[[i]])) next # skip if disaggregate not in group
    disag = dis # store disaggregate name
    fltr = which(group_list[[i]] == dis) #define rows/HHs to calc. values
    prob_mods = ftfzoi_midline$prob_mod_sev[fltr] # define probabilities
    wt = ftfzoi_midline$wt[fltr]*10^6 # define weights
    rs = ftfzoi_midline$RS[fltr] # define raw scores
    psu = ftfzoi_midline$psu[fltr]  # define primary sampling units for MOE
    strata = ftfzoi_midline$strata[fltr] # define strata for MOE
    # results
    output_1 = disag
    output_2 = length(fltr) 
    output_3 = sum(wt) 
    output_4 = wtd.mean(prob_mods,wt) * 100
    output_5 = moe(prob_mods,rs,wt,psu=psu,strata=strata, conf.level = .95)$moe * 100
    tot_output = c(output_1, output_2, output_3, round(output_4, 1), round(output_5, 1)) # assign results to vector
    mod_sev_fi_ml <- rbind(mod_sev_fi_ml, tot_output) # assign vector to data frame row
  }
  colnames(mod_sev_fi_ml) = c("Disaggregat","Midline_", "Midline_W","Midline_MSF","Midline_Mo")  # assign column names
}

# view results
head(mod_sev_fi_ml)

# Step 10d. If also analyzing baseline data, customize the code in Steps 10a-c to run with the baseline data.
# create empty data frame for results
mod_sev_fi_bl <- data.frame()
# loop function
for (i in 1:length(group_list)) {
  for (dis in unique(groups)) {
    if(!(dis %in% group_list[[i]])) next # skip if disaggregate not in group
    disag = dis # store disaggregate name
    fltr = which(group_list[[i]] == dis) #define rows/HHs to calc. values
    prob_mods = ftfzoi_midline$prob_mod_sev[fltr] # define probabilities
    wt = ftfzoi_midline$wt[fltr]*10^6 # define weights
    rs = ftfzoi_midline$RS[fltr] # define raw scores
    psu = ftfzoi_midline$psu[fltr]  # define primary sampling units for MOE
    strata = ftfzoi_midline$strata[fltr] # define strata for MOE
    # results
    output_1 = disag
    output_2 = length(fltr) 
    output_3 = sum(wt) 
    output_4 = wtd.mean(prob_mods,wt) * 100
    output_5 = moe(prob_mods,rs,wt,psu=psu,strata=strata, conf.level = .95)$moe * 100
    tot_output = c(output_1, output_2, output_3, round(output_4, 1), round(output_5, 1)) # assign results to vector
    mod_sev_fi_ml <- rbind(mod_sev_fi_ml, tot_output) # assign vector to data frame row
  }
  colnames(mod_sev_fi_bl) = c("Disaggregat","Midline_", "Midline_W","Midline_MSF","Midline_Mo")  # assign column names
}


# create variable identifying survey 
mod_sev_fi_ml$Survey <- "Midline"
mod_sev_fi_bl$Survey <- "Baseline"
# join into combined disaggregate data frame
mod_sev_fi_combined <- left_join(mod_sev_fi_bl, mod_sev_fi_ml, by = c("Disaggregate", "Survey"))


# Step 10e. calculate difference- midline–- baseline 
mod_sev_fi_combined$diff <- mod_sev_fi_combined$Midline - mod_sev_fi_combined$Baseline_MSFI
# significance test
mod_sev_fi_combined$sig_test <- ifelse(mod_sev_fi_combined$Diff > mod_sev_fi_combined$Midline_MoE, T, F)

                                 
########### Step 11 & 12 Export the  results ###########
# csv file
# define working directory to save results in a separate folder
setwd("FIES\\FTF ZOI Survey [COUNTRY] [YEAR] NAME\\Result")

write_csv(as.data.frame(AGG_df),"prevalence_food_insecurity_aggregate.cs")
write_csv(as.data.frame(mod_sev_fi),"prevalence_mod_sev_food_insecurity_disaggregates.cs")

# stata dta file

# # binary variable of moderate/severe food insecurity 
# 
# # more variables can be labelled as above. here is a list on suggested use of labels
var_label(AGG_df$Survey_Round) <- "Survey Round: Baseline/Midline"
var_label(AGG_df$Moderate+Severe_Food_Insecurity) <- "Estimate of Moderate & Severe Food Insecurity Rate"
var_label(AGG_df$Moderate_Food_Insecurity) <- "Estimate of Moderate Food Insecurity Rate"
var_label(AGG_df$Severe_Food_Insecurity) <- "Estimate of Severe Food Insecurity Rate"
var_label(AGG_df$N) <- "Unweighted N"
var_label(AGG_df$WN) <- "Weighted N"
var_label(AGG_df$MSFI_MoE) <- "Margin of Error - Moderate & Severe Food Insecurity"              
var_label(AGG_df$MFI_MoE) <- "Margin of Error - Moderate Food Insecurity"
var_label(AGG_df$SFI_MoE) <- "Margin of Error – Severe Food Insecurity"
var_label(AGG_df$MSFI_CI_Low) <- "Lower Confidence Interval – Moderate & Severe Food Insecurity"
var_label(AGG_df$MFI_CI_Low) <- "Lower Confidence Interval – Moderate Food Insecurity"
var_label(AGG_df$SFI_CI_Low) <- "Lower Confidence Interval – Severe Food Insecurity"
var_label(AGG_df$MSFI_CI_High) <- "Upper Confidence Interval – Moderate & Severe Food Insecurity"
var_label(AGG_df$MFI_CI_High) <- "Upper Confidence Interval – Moderate Food Insecurity"
var_label(AGG_df$SFI_CI_High) <- "Upper Confidence Interval – Severe Food Insecurity"
var_label(AGG_df$MSFI_Sig) <- "Significance Test – Moderate & Severe Food Insecurity: TRUE/FALSE"
var_label(AGG_df$MFI_Sig) <- "Significance Test – Moderate Food Insecurity: TRUE/FALSE"
var_label(AGG_df$SFI_Sig) <- "Significance Test – Severe Food Insecurity: TRUE/FALSE"

write_dta(AGG_df,"FTF ZOI Survey [COUNTRY] [YEAR] NAME Food Insecurity Aggregate Results.dta")

# For writing out the HH dataset used for analysis, the following list of suggested
# variable names is provided: 


# label variables and values
var_label(ftfzoi_midline$prob_mod_sev) <- "Probability of HH being moderate or severe food insecure"
var_label(ftfzoi_midline$fi_mod_sev_bin) <- "Binary variable for moderate & severe food insecurity"

val_label(ftfzoi_midline$fi_mod_sev_bin, 1) <- "Yes"
val_label(ftfzoi_midline$fi_mod_sev_bin, 0) <- "No" # set yes/no labels for the 

### Core variables:
var_label(ftfzoi_midline$survey) <- "Survey round"
var_label(ftfzoi_midline$hhnum) <- "Household ID number"          
var_label(ftfzoi_midline$psu) <- "Primary sampling unit"           
var_label(ftfzoi_midline$wt) <- "HH sampling weight"
var_label(ftfzoi_midline$hhsize_dj   ) <- "Number of members in household"
var_label(ftfzoi_midline$strata) <- "Stratum"
var_label(ftfzoi_midline$fcluster) <- "Cluster ID number"  

### FIES items:
var_label(ftfzoi_midline$WORRIED) <- "Past 12 months: ever worried not enough food"
var_label(ftfzoi_midline$HEALTHY) <- "Past 12 months: ever unable to eat healthy foods"
var_label(ftfzoi_midline$FEWFOOD) <- "Past 12 months: ever limited variety of food"
var_label(ftfzoi_midline$SKIPPED) <- "Past 12 months: ever skipped a meal"
var_label(ftfzoi_midline$ATELESS) <- "Past 12 months: ever ate less than should"
var_label(ftfzoi_midline$RUNOUT) <- "Past 12 months: ever did’'t have food"
var_label(ftfzoi_midline$HUNGRY) <- "Past 12 months: ever hungry but did not eat"
var_label(ftfzoi_midline$WHLDAY) <- "Past 12 months: ever did’'t eat for a whole day"
var_label(ftfzoi_midline$RS) <- "Raw score: sum of 'yes' responses to FIES Items"
var_label(ftfzoi_midline$prob_mod) <- "Probability of being moderately food secure"
var_label(ftfzoi_midline$prob_mod_sev) <- "Probability of HH being moderately or severely food insecure"    
var_label(ftfzoi_midline$prob_sev) <- "Probability of HH being severely food insecure"  
var_label(ftfzoi_midline$fi_mod_sev_bin) <- "Moderately or severely food insecure - disaggregate"
var_label(ftfzoi_midline$fi_mod_bin) <- "Moderately food insecure - disaggregate"
var_label(ftfzoi_midline$fi_sev_bin) <- "Severely food insecure - disaggregate"
# 

# Key disaggregates (if included)
var_label(mod_sev_fi$ahtype) <– “Residency type (urban/rural)” 
var_label(mod_sev_fi$genhhtype_dj) <– “Gender household type – de jure household members” 
var_label(mod_sev_fi$awiquint) <– “Wealth quintile disaggregate”  
var_label(mod_sev_fi$shock_sev) <– “Shock severity exposure disaggregate” 

write_dta(ftfzoi_midline,"FTF ZOI Survey [COUNTRY] [YEAR] FIES.dta")


### disaggregate results
var_label(mod_sev_fi$Disaggregate) <- "Name of disaggregate"
var_label(mod_sev_fi$FI_Baseline) <- "Moderate and Severe Food Insecurity Rate, Baseline"
var_label(mod_sev_fi$CI_Baseline) <- "Confidence Interval: Moderate and Severe Food Insecurity Rate, Baseline"
var_label(mod_sev_fi$N_Baseline) <- "Unweighted N, Baseline"
var_label(mod_sev_fi$FI_Midline) <-  "Moderate and Severe Food Insecurity Rate, Midline"
var_label(mod_sev_fi$CI_Midline) <-  "Confidence Interval: Moderate and Severe Food Insecurity Rate, Midline"
var_label(mod_sev_fi$N_Midline) <-  "Unweighted N, Midline"
var_label(mod_sev_fi$Diff) <- "Difference between Midline and Baseline in Moderate and Severe Food Insecurity Rate"
var_label(mod_sev_fi$Sig) <- "Significance Test from Midline to Baseline – Moderate and Severe Food Insecurity Rate"
var_label(mod_sev_fi$MoE_Baseline) <- "Margin of Error– -  Moderate and Severe Food Insecurity Rate, Baseline"
var_label(mod_sev_fi$MoE_Midline) <- "Margin of Error– -  Moderate and Severe Food Insecurity Rate, Midline"


write_dta(mod_sev_fi_combined,"FTF ZOI Survey [COUNTRY] [YEAR] NAME Moderate & Severe Food Insecurity Disaggregate Results.dta")
