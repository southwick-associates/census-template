# pull age-by-sex (by state) for use in national/regional dashboards

library(ggplot2)
source("censusapi/functions.R")

# you'll need to specify a key - https://api.census.gov/data/key_signup.html
# alternatively, Dan can send you his key
Sys.setenv(CENSUS_KEY = Sys.getenv("CENSUS_API_KEY")) 

# get sex-by-age for each state
pop_seg <- sapply(2010:2017, get_B01001, simplify = FALSE) %>% 
    bind_rows() %>%
    as_tibble()

# visualize
group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    ggplot(aes(state, pop, color = year)) +
    geom_point() + 
    coord_flip() +
    ggtitle("Total state populations by year")

# output to csv
write.csv(pop_seg, "censusapi/pop-out.csv", row.names = FALSE)
