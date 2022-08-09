
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

It supports the following workflow:

1.  Split a data frame into a fact table and one or more dimensions
    (also known as a [star
    schema](https://en.wikipedia.org/wiki/Star_schema))
2.  Create multiple star schemas from data frames and add them to the
    same model
3.  Populate the model with data from a list of data frames and set up
    incremental refresh
4.  Serve the model as csv or parquet files for tools such as Power BI,
    Tableau or Qlik

## Installation

You can install the development version of dimmodelR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("cvermehren/dimmodelR")
```

## Create a star schema

Imagine we want to transform data extracted from a web analytics tool
such as Google Analytics into a star schema. We might have a dataset
which looks like this:

``` r
library(dimmodelR)

head(web_metrics)
#>         date view_name   country     source    medium     campaign sessions
#> 1 2021-11-25    view_1 country_1 source_735     email     email_65        2
#> 2 2021-04-08    view_1 country_1 source_950  referral    (not set)        1
#> 3 2021-05-23    view_1 country_1 source_549 medium_99 campaign_934       41
#> 4 2021-05-25    view_2 country_2 source_735     email    email_405        2
#> 5 2021-04-01    view_1 country_1   source_1    (none)    (not set)      450
#> 6 2021-08-27    view_1 country_1 source_427    social campaign_818        1
#>   transactions revenue
#> 1            0       0
#> 2            0       0
#> 3            0       0
#> 4            0       0
#> 5           28   19225
#> 6            0       0
```

The dataset contains three numeric variables which which can be
considered facts: `sessions`, `transactions` and `revenue`. The rest of
the columns provide context to these facts and can be considered
dimensions.

Let’s decide to categorize them into two dimensions which we call
`dim_channel` and `dim_market`:

``` r
dimensions <- list(
  dim_channel = c("source", "medium", "campaign"),
  dim_market = c("view_name", "country")
)
```

With this definition of dimensions, we can create a star schema using
the `dm_model` function:

``` r
dm <- dm_model(web_metrics, dimensions, return_facts = TRUE)

str(dm)
#> List of 2
#>  $ dimensions:List of 2
#>   ..$ dim_channel:'data.frame':  612 obs. of  4 variables:
#>   .. ..$ channel_key: num [1:612] 1 2 3 4 5 6 7 8 9 10 ...
#>   .. ..$ source     : chr [1:612] "source_735" "source_950" "source_549" "source_735" ...
#>   .. ..$ medium     : chr [1:612] "email" "referral" "medium_99" "email" ...
#>   .. ..$ campaign   : chr [1:612] "email_65" "(not set)" "campaign_934" "email_405" ...
#>   ..$ dim_market :'data.frame':  2 obs. of  3 variables:
#>   .. ..$ market_key: num [1:2] 1 2
#>   .. ..$ view_name : chr [1:2] "view_1" "view_2"
#>   .. ..$ country   : chr [1:2] "country_1" "country_2"
#>  $ fact      :'data.frame':  1500 obs. of  6 variables:
#>   ..$ market_key  : num [1:1500] 1 1 1 1 1 1 1 1 1 1 ...
#>   ..$ channel_key : num [1:1500] 5 5 5 5 5 5 502 431 431 374 ...
#>   ..$ date        : Date[1:1500], format: "2021-04-01" "2021-05-27" ...
#>   ..$ sessions    : num [1:1500] 450 557 863 647 455 559 1 1 1 1 ...
#>   ..$ transactions: num [1:1500] 28 23 72 61 11 10 0 0 0 0 ...
#>   ..$ revenue     : num [1:1500] 19225 11709 48431 44310 6450 ...
#>  - attr(*, "class")= chr "dm_model"
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
