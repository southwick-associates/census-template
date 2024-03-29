# Template code for extracting data from US Census

Although [American Fact Finder](https://factfinder.census.gov/faces/nav/jsf/pages/index.xhtml) provides a GUI interface for finding data, it isn't very well-suited to production workflows. There is an available [Census API](https://www.census.gov/developers/) that can serve this purpose.

## Using R

Several packages have been written that provide R front-ends to the Census API (e.g., acs, tidycensus). The [censusapi](https://hrecht.github.io/censusapi/) package seems to provide the most flexible/complete interface (although a package like [tidycensus](https://walkerke.github.io/tidycensus/) is probably easier to use).

### censusapi

Includes an example of using package censusapi to pull ACS table B01001 (sex by age). Written using R 3.6.1.
