# pull age-by-sex (by state) for use in national/regional dashboards

library(plyr)
library(ggplot2)
source("censusapi/functions.R")

# you'll need to specify a key - https://api.census.gov/data/key_signup.html
# alternatively, Dan can send you his key
Sys.setenv(CENSUS_KEY = Sys.getenv("CENSUS_API_KEY")) 

# Pull Census Data ---------------------------------------------

# get sex-by-age by state
pop_seg <- sapply(2010:2017, get_B01001, simplify = FALSE) %>% 
    bind_rows() %>%
    as_tibble()

# total pop by state
pop <- bind_rows(
    get_pop("censusapi/data/nst-est2018-01.xlsx", c("state", "drop1", "drop2", 2010:2018)),
    get_pop("censusapi/data/st-est00int-01.xls", c("state", "drop1", 2000:2009, "drop2", "drop3"))
)

# check state-level totals
discrepancy <- group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    left_join(pop, by = c("state", "year")) %>%
    mutate( pct_diff = (pop - pop_state) / pop * 100 )
arrange(discrepancy, desc(abs(pct_diff)))

# Prepare for Nat/Reg Dashboards ------------------------------------------

# only include 50 states (i.e., exclude Puerto Rico & DC)
pop_seg <- filter(pop_seg, state %in% state.name)

# adjust to match census totals
adjust <- discrepancy %>%
    mutate(ratio = pop_state / pop) %>%
    select(state, year, ratio)

pop_seg <- left_join(pop_seg, adjust, by = c("state", "year")) %>%
    mutate(pop = pop * ratio) %>%
    select(-ratio)

# extrapolate segments for years missing from B01001 table
pop_seg <- bind_rows(pop_seg, extrapolate_yr(pop_seg, pop, 2018, "forward"))
pop_seg <- bind_rows(extrapolate_yr(pop_seg, pop, 2009, "back"), pop_seg)
pop_seg <- bind_rows(extrapolate_yr(pop_seg, pop, 2008, "back"), pop_seg)

# convert sex/age to dashboard categories
pop_seg <- pop_seg %>% mutate(
    sex_acs = sex, age_acs = age,
    sex = ifelse(sex == "Male", 1L, 2L),
    age = plyr::mapvalues(age, age_map$acs_age, age_map$lic_age) %>% as.integer()
)
count(pop_seg, age, age_acs) %>% data.frame()
count(pop_seg, sex, sex_acs)

# collapse to 7 age categories
pop_seg <- group_by(pop_seg, state, year, sex, age) %>%
    summarise(pop = sum(pop))

# visualize
group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    ggplot(aes(state, pop, color = year)) +
    geom_point() + 
    coord_flip() +
    ggtitle("Total state populations by year")

# output to csv
write.csv(pop_seg, "censusapi/pop-out.csv", row.names = FALSE)
