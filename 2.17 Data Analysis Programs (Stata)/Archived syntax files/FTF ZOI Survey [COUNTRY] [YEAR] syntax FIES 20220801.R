### Feed the Future ZOI Surveys ####
### Food Insecurity Experience Scale-Core ###

# Clear the R environment
rm(list = ls(all = TRUE))

# INSTALL PACKAGES --------------------------------------------------------------------------------------------------
#install.packages("RM.weights")
#install.packages("survey")
#install.packages("foreign")
#install.packages("dplyr")
library(RM.weights)
library(survey)
library(foreign)
library(dplyr)

# DATASET PREPARATION AND CORRESPONDING WEIGHTS ---------------------------------------------------------------------
# Set working directory
setwd ("FIES\\FTF ZOI Survey [COUNTRY] [YEAR] NAME")

# Function for calculating sampling errors
source("moe_nat_psu_strata_v2.R")

# Read the data file 
ftf_household <- read.dta("FTF ZOI Survey [COUNTRY] [YEAR] household data analytic.dta", convert.factors = FALSE)

# List the Feed the Future variables
FIESvars <- c("WORRIED", "HEALTHY", "FEWFOOD", "SKIPPED", "ATELESS", "RUNOUT", "HUNGRY", "WHLDAY")
ftfvars  <- c("v301", "v302", "v303", "v304", "v305", "v306", "v307", "v308")

# Create data frame of just the FIES variables and rename the variables to FIES standard names
xx <- ftf_household[ftfvars]
names(xx) <- FIESvars

# Recode all variables - 1 to 1, 2 to 0, and everything else to missing
xx <- xx %>% mutate_all(
  function(x) case_when(
    x == 1 ~ 1,
    x == 2 ~ 0
  )
)
# Define weight variable
wt <- ftf_household$wgt_hh2 / 1000000
# number of household members - de jure
mem <- ftf_household$hhsize_dj

### CREATING DATA FRAME OF ANALYTIC VARIABLES -------------------------------------------------------------
# storing for use later with background characteristics
fies <- xx
fies$wt <- wt
fies$mem <- mem
fies$fcluster <- ftf_household$hhea
fies$hhnum <- ftf_household$hhnum
fies$strata <- ftf_household$strata
# add background variables as factors, with levels and labels
fies$region <- factor(ftf_household$region, levels=c(1,2,3), labels=c("region1","region2","region3"))
fies$urbanrural <- factor(ftf_household$urban_rural, levels=c(1,2), labels=c("urban","rural"))
fies$genhhtype_dj <- factor(ftf_household$genhhtype_dj, levels=c(1,2,3,4), labels=c("Male and Female adults","Female adults only","Male adults only", "Children only"))

### FIES PSYCHOMETRIC ANALYSIS ---------------------------------------------------------------------------------------
# Fit weighted Rasch at national level
rr <- RM.w(xx, wt, write.file = TRUE, country = "FTF ZOI SURVEY COUNTRY")

# Weighted number of population for each raw score 
rs = rowSums(xx)

# Equating to global reference standard, using default assumptions, and weighting by population. 
# These assumptions should be checked before continuing 
ee <- equating.fun(rr, wt.spec=wt*mem, write.file=TRUE)
# display prevalence
ee$prevs*100

### Calculate confidence intervals
# First extract the probabilities for each score for moderate and severe for each case
prob.rs=ee$probs.rs
prob.modsev=prob.rs[rs+1,1]
prob.sev=prob.rs[rs+1,2]
prob.mod=prob.rs[rs+1,1]-prob.rs[rs+1,2]

# Calculate margin of errors taking into account the complex sampling design
L.modsev <- moe(prob=prob.modsev, rs=rs, wt=wt*mem, psu=fies$fcluster, strata=fies$strata, conf.level = 0.95)
L.sev <- moe(prob=prob.sev, rs=rs, wt=wt*mem, psu=fies$fcluster, strata=fies$strata, conf.level = 0.95)
L.mod <- moe(prob=prob.mod, rs=rs, wt=wt*mem, psu=fies$fcluster, strata=fies$strata, conf.level = 0.95)

moes <- c("FI_mod+"=L.modsev$moe, "FI_sev"=L.sev$moe, "FI_mod"=L.mod$moe)
moes*100

# Design Effect
deffs <- c("FI_mod+"=L.modsev$deff_s, "FI_sev"=L.sev$deff_s, "FI_mod"=L.mod$deff_s)

# Number of cases
nwt <- sum((wt*mem)[!is.na(rs)])

# Number of cases
nt <- sum((mem)[!is.na(rs)])

### ESTIMATES FOR BACKGROUND CHARACTERISTICS
# Function for calculating prevalences for background characteristics assuming the same model as for the full sample
FIES_char <- function (df.char, fies. = fies, rr. = rr, ee. = ee)
{
  list.x <- list()
  # loop through each category of the background variable
  for ( i in levels(df.char) ) { 
    
    print(i) 
    # selection for this individual category
    select <- !is.na(df.char) & df.char==i

    # questionnaire data
    xx <- fies[select,1:8]
    # weight variable
    wt <- fies$wt[select]
    # de jure population
    mem <- fies$mem[select]
    
    list.x[[i]]$rr <- RM.w(xx, wt, write.file = TRUE, country = paste("FTF ZOI SURVEY COUNTRY",i))
    
    # Prevalence of food insecurity
    list.x[[i]]$prev <- prob.assign(sthres = ee$adj.thres, 
                                    flex=list(a=rr$a,se.a=rr$se.a,XX=xx,wt=(wt*mem)))$sprob
    list.x[[i]]$prev*100
  
    # extract the raw scores and the probabilities for each score for moderate and severe food insecurity for each case
    rs = rowSums(xx)
    prob.modsev=prob.rs[rs+1,1]
    prob.sev=prob.rs[rs+1,2]
    prob.mod = prob.rs[rs+1,1] - prob.rs[rs+1,2]
    
    # margin of error taking into account the complex sampling design
    L.modsev <- moe(prob=prob.modsev, rs=rs, wt=wt*mem, psu=fies$fcluster[select], strata=fies$strata[select], conf.level = 0.95)
    L.sev <- moe(prob=prob.sev, rs=rs, wt=wt*mem, psu=fies$fcluster[select], strata=fies$strata[select], conf.level = 0.95)
    L.mod <- moe(prob=prob.mod, rs=rs, wt=wt*mem, psu=fies$fcluster[select], strata=fies$strata[select], conf.level = 0.95)
    
    list.x[[i]]$moes <- c("FI_mod+"=L.modsev$moe, "FI_sev"=L.sev$moe, "FI_mod"=L.mod$moe)
    list.x[[i]]$moes*100 
    
    # Design Effect
    list.x[[i]]$deffs <- c("DF_mod+"=L.modsev$deff_s, "DF_sev"=L.sev$deff_s, "DF_mod"=L.mod$deff_s)
    
     # Number of cases
    list.x[[i]]$nwt <- sum((wt*mem)[!is.na(rs)])
    
    # Number of cases unweighted
    list.x[[i]]$nt <- sum((mem)[!is.na(rs)])
    
  }
  
  return(list.x)
}

# Run for background characteristics
list.reg <- FIES_char(fies$region)
list.res <- FIES_char(fies$urbanrural)
list.ghh <- FIES_char(fies$genhhtype_dj)

### OUTPUTTING OF RESULTS ---------------------------------------------
# Function to create a data frame of results for each characteristic
FIES_df <- function( df.char, list.x ) { 
  df.x <- data.frame()
  for ( i in levels(df.char) ) { 
    df.x <- rbind(df.x,cbind(
      "Little or no" = 100*(1-list.x[[i]]$prev[1]), 
      "Moderate" = 100*(list.x[[i]]$prev[1]-list.x[[i]]$prev[2]), 
      "Severe" = 100*(list.x[[i]]$prev[2]), 
      "Moderate or severe" = 100*(list.x[[i]]$prev[1]), 
      "Number" = sum(list.x[[i]]$nwt),
      "Unweighted Number" = sum(list.x[[i]]$nt),
      "CI Severe low"  = 100*(list.x[[i]]$prev[2]-list.x[[i]]$moes[2]),
      "CI Severe high" = 100*(list.x[[i]]$prev[2]+list.x[[i]]$moes[2]),
      "CI Moderate+ low"  = 100*(list.x[[i]]$prev[1]-list.x[[i]]$moes[1]), 
      "CI Moderate+ high" = 100*(list.x[[i]]$prev[1]+list.x[[i]]$moes[1]),
      "CI Moderate low"  = 100*((list.x[[i]]$prev[1]-list.x[[i]]$prev[2])-list.x[[i]]$moes[3]), 
      "CI Moderate high" = 100*((list.x[[i]]$prev[1]-list.x[[i]]$prev[2])+list.x[[i]]$moes[3]),
      "DEFF Severe"  = (list.x[[i]]$deffs[2]),
      "DEFF Moderate+"  = (list.x[[i]]$deffs[1]),
      "DEFF Moderate"  = (list.x[[i]]$deffs[3])
    ))
  }
  row.names(df.x) <- levels(df.char)
  return(df.x)
}

# Create final data frame of results
df <- data.frame()
df <- rbind(df,FIES_df(fies$region, list.reg))
df <- rbind(df,FIES_df(fies$urbanrural, list.res))
df <- rbind(df,FIES_df(fies$genhhtype_dj, list.ghh))
# Add total to the bottom of the data frame
df.t <- data.frame()
prev <- ee$prevs
df.t <- cbind(
  "Little or no" = 100*(1-prev[1]), 
  "Moderate" = 100*(prev[1]-prev[2]), 
  "Severe" = 100*(prev[2]), 
  "Moderate or severe" =100*(prev[1]), 
  "Number" = sum(nwt),
  "Unweighted Number" = sum(nt),
  "CI Severe low"  = 100*(prev[2]-moes[2]),
  "CI Severe high" = 100*(prev[2]+moes[2]),
  "CI Moderate+ low"  = 100*(prev[1]-moes[1]), 
  "CI Moderate+ high" = 100*(prev[1]+moes[1]),
  "CI Moderate low"  = 100*((prev[1]-prev[2])-moes[3]), 
  "CI Moderate high" = 100*((prev[1]-prev[2])+moes[3]),
  "DEFF Severe" =(deffs[2]),
  "DEFF Moderate+" =(deffs[1]),
  "DEFF Moderate" =(deffs[3])
)
row.names(df.t) <- c("Total")
df <- rbind(df,df.t)

# Write the results to a CSV file
write.csv(df, file="FTF ZOI SURVEY COUNTRY FIES table.csv")
