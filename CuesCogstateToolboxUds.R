#!/usr/bin/env Rscript

## Script to summarize some of the data in the "LaptopToolboxDataset" spreadsheet

library(dplyr)
library(lubridate)
library(ggplot2)

df <- readr::read_csv("LaptopToolboxDataset_DATA_2018-03-07.csv", na = "", trim_ws = TRUE)

# Check data integrity
length(unique(df$subject_id))
length(unique(df$mrn))
length(unique(df$madc_id))

which(duplicated(df$subject_id) == duplicated(df$mrn) %in% FALSE) + 1
which(duplicated(df$subject_id) == duplicated(df$madc_id) %in% FALSE) + 1
which(duplicated(df$mrn) == duplicated(df$madc_id) %in% FALSE) + 1
which(duplicated(df$subject_id) == duplicated(df$dob) %in% FALSE) + 1

#####
### Check dates
##
grep(pattern = "dob", x = names(df))
grep(pattern = "date", x = names(df))
length(grep(pattern = "date", x = names(df)))

# Coerce df$dob to type Date
class(df$dob)
# lubridate::mdy(df$dob)
lubridate::mdy(df$dob)
df$dob <- as.character(lubridate::mdy(df$dob))

# Coerce any columns with "date"=>"character" in field name to type Date
# df %>% 
#   select(matches("date")) # this doesn't work because there's a non-date 'remdates' column;
#                           # use ends_with("dates") instead
missing_dates_1 <- df %>% 
  select(ends_with("date")) %>% 
  sapply(X = ., FUN = function(x) { sum(is.na(x)) })
missing_dates_2 <- df %>% 
  mutate_at(vars(ends_with("date")), mdy) %>% 
  select(ends_with("date")) %>% 
  sapply(X = ., FUN = function(x) { sum(is.na(x)) })
identical(missing_dates_1, missing_dates_2)
# blah <- df %>%
#   select(ends_with("date")) %>% 
#   mutate_all(mdy)
df <- df %>% 
  mutate_at(vars(ends_with("date")), function(x) { as.character(mdy(x)) })
# Histo plot of columns with dates
# ggplot(df, aes(x = dob)) + geom_histogram() # dob field has to be class Date (not character)
df_dates <- df %>% 
  select(subject_id, redcap_event_name, dob, ends_with("date"))
# lapply(X = df_dates[, -(1:2)], FUN = function(x) { # date fields have to be class Date (not character)
#     ggplot(df, aes(x = x)) + geom_histogram(bins = 20) + ggtitle(label = names(x))
#   })
# Range of columns with dates
lapply(X = df_dates[, -(1:2)], FUN = function(x) { range(x, na.rm = TRUE) })
df_dates_future <- df_dates %>% 
  filter_at(vars(ends_with("date")), any_vars(. > Sys.Date()))
lapply(X = df_dates_future[, -(1:2)], FUN = function(x) { sum(x > Sys.Date(), na.rm = TRUE) })
lapply(X = df_dates_future[, -(1:2)], FUN = function(x) { x > Sys.Date() })

# Shorten redcap_event_name values
df$redcap_event_name <- stringr::str_replace(string = df$redcap_event_name, pattern = "visit_", replacement = "v")
df$redcap_event_name <- stringr::str_replace(string = df$redcap_event_name, pattern = "_arm_1", replacement = "")

# Reshape to long
df_long <- df %>% 
  dplyr::select(subject_id, mrn, madc_id, dob, redcap_event_name, everything()) %>% 
  tidyr::gather(key = "var", value = "val", -subject_id, -redcap_event_name) 

# Reshape to wide
df_wide <- df_long %>% 
  tidyr::unite(col = "redcap_event_name.var", redcap_event_name, var, sep = ".") %>%
  tidyr::spread(key = redcap_event_name.var, value = val)

# Sample wide data set (for SPSS) with particular values: 
#   subject_id, age, uds_consensus_dx, education, cog_crys_*
df_wide_sample <- df_long %>% 
  dplyr::filter(var == "subject_id" | var == "age" | var == "uds_consensus_dx" | 
                  var == "cog_crys_comp_uss" | var == "cog_crys_comp_aass" | 
                  var == "cog_crys_comp_npaa" | var == "cog_crys_comp_fass") %>% 
  tidyr::unite(col = "redcap_event_name__var", redcap_event_name, var, sep = "__") %>% 
  tidyr::spread(key = redcap_event_name__var, value = val)

### Might be useful to partition the data by column types (numerical, date, character) and then cbind

#####
### Check columns with numeric values
##
# df_num
# df_num <- df %>% 
#   select_if(is.numeric) 
# df_num_range <- lapply(X = df_num, FUN = function(x) { range(x, na.rm = TRUE) })

####
### Check columns with character values
##
#
# df_char <- df %>% 
#   select_if(is.character)

# df_factor <- df %>% # no factor columns
#   select_if(is.factor)

# df_logic <- df %>% # no logical columns
#   select_if(is.logical)







