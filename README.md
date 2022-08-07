
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dimmodelR

<!-- badges: start -->
<!-- badges: end -->

Transforming source data to a [dimensional
model](https://en.wikipedia.org/wiki/Dimensional_modeling) is one of the
most difficult, time-consuming and error-prone tasks within data
engineering and business intelligence.

`dimmodelR` aims to make this task easy. It provides a set of R
functions which automate the process of creating and refreshing a
central star-schema model consisting of multiple fact tables and shared
dimension tables.

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
