
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dimmodelR

<!-- badges: start -->
<!-- badges: end -->

Transforming source data to a [dimensional
model](https://en.wikipedia.org/wiki/Dimensional_modeling) is one of the
most difficult, time-consuming and error-prone tasks within data
engineering and business intelligence.

The `dimmodelR` package aims to make this task easy using R. It provides
a set of functions for automating the process of creating and refreshing
a central data model consisting of multiple fact tables and a set of
shared dimensions.

## Installation

You can install the development version of dimmodelR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("cvermehren/dimmodelR")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(dimmodelR)
1+2
#> [1] 3
## basic example code
```

## Features

-   Transform a data frame into a [star
    schema](https://en.wikipedia.org/wiki/Star_schema) with dimensions
    and fact tables related by [surrogate
    keys](https://en.wikipedia.org/wiki/Surrogate_key)
-   Extend a star schema with more transformations turning it into a
    central model also known as [fact
    constellation](https://en.wikipedia.org/wiki/Fact_constellation)
-   Easily refresh a central model incrementally as new source data
    become available
-   Save the model as csv or parquet files in a practical predefined
    folder structure

# dimmodelR

<!-- badges: start -->
<!-- badges: end -->

The goal of dimmodelR is to …

## Installation

You can install the development version of dimmodelR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("cvermehren/dimmodelR")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(dimmodelR)
## basic example code
```

What is special about using `README.Rmd` instead of just `README.md`?
You can include R chunks like so:

``` r
summary(cars)
#>      speed           dist       
#>  Min.   : 4.0   Min.   :  2.00  
#>  1st Qu.:12.0   1st Qu.: 26.00  
#>  Median :15.0   Median : 36.00  
#>  Mean   :15.4   Mean   : 42.98  
#>  3rd Qu.:19.0   3rd Qu.: 56.00  
#>  Max.   :25.0   Max.   :120.00
```

You’ll still need to render `README.Rmd` regularly, to keep `README.md`
up-to-date. `devtools::build_readme()` is handy for this. You could also
use GitHub Actions to re-render `README.Rmd` every time you push. An
example workflow can be found here:
<https://github.com/r-lib/actions/tree/v1/examples>.

You can also embed plots, for example:

<img src="man/figures/README-pressure-1.png" width="100%" />

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub and CRAN.
