# functions to prepare census data

library(censusapi)
library(tidyr)
library(dplyr)

# return census data as a tidy data frame
# mostly a wrapper for getCensus(); uses the same argument names
get_census_df <- function(name, vintage, group, region, ...) {
    df <- getCensus(
        name, vintage, vars = c("NAME", paste0("group(", group, ")")), 
        region = region,
        ...
    )
    meta <- listCensusMetadata(name, vintage, group = group)
    
    df %>%
        select(geo = NAME, contains(group)) %>%
        select(contains("E")) %>% # keep only estimates
        gather(name, value, -geo) %>%
        left_join(select(meta, name, label), by = "name")
}

# pull age by sex for all states (for a given year)
get_B01001 <- function(vintage) {
    get_census_df("acs/acs5", vintage, "B01001", "state:*") %>%
        separate(label, c("type", "scope", "sex", "age"), sep = "!!") %>%
        filter(!is.na(sex), !is.na(age), type == "Estimate") %>%
        select(state = geo, sex, age, pop = value) %>%
        mutate(pop = as.numeric(pop), year = vintage)
}
