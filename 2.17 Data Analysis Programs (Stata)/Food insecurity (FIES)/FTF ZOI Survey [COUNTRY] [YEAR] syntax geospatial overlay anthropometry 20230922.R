################################################################################
#              FEED THE FUTURE PHASE-TWO ZOI MIDLINE ANALYSIS 
#                        FOOD INSECURITY - FIES INDICATOR
#                                 [COUNTRY] [YEAR] 
################################################################################
#Description: This code procedures to perform the geospatial overlay to identify 
#the DHS clusters in the ZOI to include in the analysis. The code follows Section 
#17.2.1 in the Guide to Feed the Future Statistics for Phase Two Midline Surveys.

#Syntax revised by ICF, September 2023

#This syntax file was developed using the core using the core Feed the 
#Future Midline Survey parallel survey questionnaire. It must be adapted for the 
#final country-specific questionnaire. The syntax was only be partially tested 
#using ZOI Survey data; therefore, double-check all results carefully and 
#troubleshoot to resolve any issues identified. 

################################################################################
#Step 1.

install.packages("sf")
install.packages("haven")
install.package("tidyverse")

library(tidyverse)
library(sf)
library(haven)

# clear environment
rm(list = ls())

#Step 2. Read data 

setwd("[DIRECTORY PATH]")
[COUNTRY]_dhs_female_[YEAR] <- read_dta(paste0(getwd(), "/[CC]IR[VV]FL.DTA"))

[COUNTRY]_dhs_pr_[YEAR] <- read_dta(paste0(getwd(), "/[CC]PR[VV]FL.DTA"))

[COUNTRY]_dhs_geospatial_[YEAR] <- read_sf(paste0(getwd(), "/[CC]GE[VV]FL/[CC]GE[VV]FL.shp"))

[COUNTRY]_adm2_shp <- read_sf("[COUNTRY]_ adm2_1m_gov_[DATE].shp")

#Step 3. 

#Convert to character variable
[COUNTRY]_adm2_shp <- 
  [COUNTRY]_adm2_shp %>%
  mutate(ADM2 = as.character(ADM2))

# create binary variable FTF_ZOI to identify admin units inside and outside the ZOI
[COUNTRY]_adm2_shp <- 
  [COUNTRY]_adm2_shp %>%
  mutate(FTF_ZOI = case_when(
    ADM2=="[Admin Unit 1]"~1, ADM2=="[Admin Unit 2]" ~1, 
    ADM2=="[Admin Unit 3]"~1, ADM2=="[Admin Unit 4]" ~1, 
    ADM2=="[Admin Unit 5]"~1, ADM2=="[Admin Unit 6]" ~1,
    ADM2=="[Admin Unit 7]"~1, ADM2=="[Admin Unit 8]" ~1, 
    ADM2=="[Admin Unit 9]"~1, ADM2=="[Admin Unit 10]"~1,
    TRUE ~ 0))

# check results
[COUNTRY]_adm3_shp %>%
  select(ADM2, ADM1, FTF_ZOI) %>%
  st_drop_geometry() %>%
  filter(FTF_ZOI == 1) %>%
  arrange(ADM1, ADM2) %>%
  as.data.frame()

sum([COUNTRY]_adm2_shp$FTF_ZOI)

#Step 4.

# do join in temporary shp/sf
temp <- st_join(st_as_sf([COUNTRY]_dhs_geospatial_[YEAR]), [COUNTRY]_adm2_shp, join = st_intersects)

# view column names
names([COUNTRY]_dhs_geospatial_[YEAR])
# check results - see frequency table on FTF ZOI variable
table(temp$FTF_ZOI)

# name new shapefile/sf object original name
[COUNTRY]_dhs_geospatial_[YEAR] <- temp

# delete temporary shp/sf
rm(temp)

# drop administrative units levels below Admin 1 to protect PII
[COUNTRY]_dhs_geospatial_[YEAR] <- [COUNTRY]_dhs_geospatial_[YEAR] %>%
  select(-contains(“ADM2”))

#Step 5

# join geospatial dhs cluster info onto female dhs df 
# check names
names([COUNTRY]_dhs_female_[YEAR])

# check to make sure all clusters have match
[COUNTRY]_dhs_female_[YEAR] %>%
  anti_join([COUNTRY]_dhs_geospatial_[YEAR] %>% st_drop_geometry(), by = c("v001" = "DHSCLUST"))

# returns zero - all of it joins - now use left_join
[COUNTRY]_dhs_female_[YEAR] <- 
  [COUNTRY]_dhs_female_[YEAR] %>%
  left_join([COUNTRY]_dhs_geospatial_[YEAR], by = c("v001" = "DHSCLUST"))

# join geospatial data onto persons df
# check to make sure all clusters have match
[COUNTRY]_dhs_pr_[YEAR] %>%
  anti_join([COUNTRY]_dhs_geospatial_[YEAR], by = c("hv001" = "DHSCLUST"))

# all clusters matched - now merge
[COUNTRY]_dhs_pr_[YEAR] <- 
  [COUNTRY]_dhs_pr_[YEAR] %>%
  left_join([COUNTRY]_dhs_geospatial_[YEAR], by = c("hv001" = "DHSCLUST"))

#Step 6

# remove geometry to make STATA compatible
[COUNTRY]_dhs_female_[YEAR] <- [COUNTRY]_dhs_female_[YEAR] %>%
  st_drop_geometry() %>%
  as_tibble()

[COUNTRY]_dhs_pr_[YEAR] <- [COUNTRY]_dhs_pr_[YEAR] %>%
  st_drop_geometry() %>%
  as_tibble()

haven::write_dta([COUNTRY]_dhs_female_[YEAR], 
                 path = paste0( getwd(), "/[CC]IR[VV]FL_FTF_ZOI.DTA"))
haven::write_dta([COUNTRY]_dhs_pr_[YEAR], 
                 path = paste0( getwd(), "/[CC]PR[VV]FL_FTF_ZOI.DTA"))

                  
         
