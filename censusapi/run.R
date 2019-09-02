# pull age-by-sex (by state) for use in national/regional dashboards

library(readxl)
library(stringr)
source("censusapi/functions.R")

# you'll need to supply your own census key
Sys.setenv(CENSUS_KEY = Sys.getenv("CENSUS_API_KEY"))

# Pull Segment-level with API ---------------------------------------------

# TODO: troubleshoot errors

# I honestly don't know how to fix this, it seems really buggy
# unless there is server maintenance or something
# for now I'll probably just bite the bullet and download the FactFinder data
# for 2009 through 2017

# get sex-by-age by state
get_B01001 <- function(year) {
    get_census_df("acs/acs5", year, "B01001", "state:*") %>%
        separate(label, c("type", "scope", "sex", "age"), sep = "!!") %>%
        filter(!is.na(sex), !is.na(age), type == "Estimate") %>%
        select(state = geo, sex, age, pop = value) %>%
        mutate(pop = as.numeric(pop), year = vintage)
}
pop_seg <- sapply(2010:2017, get_B01001, simplify = FALSE) %>% bind_rows()

# Load state-level Estimates ----------------------------------------------

# https://www.census.gov/data/tables/time-series/demo/popest/2010s-state-total.html
# https://www2.census.gov/programs-surveys/popest/tables/2000-2010/intercensal/state/

get_pop <- function(filename = "censusapi/nst-est2018-01.xlsx",
                    col_names = c("state", "drop1", "drop2", 2010:2018)) {
    read_excel(filename, skip = 9, n_max = 51, col_names = col_names) %>%
        select(-contains("drop")) %>%
        gather(year, pop_state, -state) %>%
        mutate(state = str_replace(state, ".", ""), year = as.numeric(year))
}
pop <- bind_rows(
    get_pop("censusapi/nst-est2018-01.xlsx", c("state", "drop1", "drop2", 2010:2018)),
    get_pop("censusapi/st-est00int-01.xls", c("state", "drop1", 2000:2009, "drop2", "drop3"))
)

# check state-level totals
group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    left_join(pop, by = c("state", "year")) %>%
    mutate(pct_diff = (pop - pop_state) / pop * 100) %>%
    arrange(desc(abs(pct_diff)))

# Prepare for Nat/Reg Dashboards ------------------------------------------

# 1. convert ages to dashboard categories
# 2. extrapolate for missing years (2008, 2009, 2018)
