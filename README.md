
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dimmodelR

<!-- badges: start -->
<!-- badges: end -->

Business-intelligence tools such as Power BI, Tableau and Qlik work best
when data are organized as a [dimensional
model](https://en.wikipedia.org/wiki/Dimensional_modeling). A common
task within business intelligence is therefore to transform source data
according to this model’s underlying design principle known as [star
schema](https://en.wikipedia.org/wiki/Star_schema).

The `dimmodelR` package makes this easy using R. It provides a set of
functions for automating the process of creating and refreshing a
central data model consisting of multiple [fact
tables](https://en.wikipedia.org/wiki/Fact_table) and a set of shared
[dimensions](https://en.wikipedia.org/wiki/Dimension_(data_warehouse)#Dimension_table).

## Installation

You can install the development version of dimmodelR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("cvermehren/dimmodelR")
```

## Workflow

The following workflow is supported:

1.  Define a star-schema model from one or more data frames
2.  Populate the model with data and set up incremental refresh
3.  Save the model as csv or parquet files and serve them to a BI tool

## Define a star-schema model

A star-schema model can be based on multiple data frames, but needs to
be built gradually. We will start with the included demo dataset
`campaign_metrics`:

``` r
library(dimmodelR)

data(campaign_metrics)

str(campaign_metrics)
#> 'data.frame':    449 obs. of  7 variables:
#>  $ date       : Date, format: "2021-09-04" "2021-05-28" ...
#>  $ source     : chr  "source_481" "source_481" "source_481" "source_481" ...
#>  $ medium     : chr  "cpc" "cpc" "cpc" "cpc" ...
#>  $ campaign   : chr  "campaign_185" "campaign_1" "campaign_184" "campaign_158" ...
#>  $ impressions: num  4 1123 41 91 24 ...
#>  $ ad_clicks  : num  1 712 3 5 1 118 1 4 1 142 ...
#>  $ ad_cost    : num  0.581 62.16 4.076 9.308 0.58 ...
```

Typically fact tables are formed by numerical columns, while dimensions
are formed by character columns.

To define a star-schema model we only need to specify the dimensions.
Fact tables will be added later when we populate the model with data.

``` r
# Define dimensions
dimensions = list(dim_channel = c("source", "medium", "campaign"))

# Initiate the model
dm <- dm_model(campaign_metrics, dimensions)

str(dm)
#> List of 1
#>  $ dimensions:List of 1
#>   ..$ dim_channel:'data.frame':  79 obs. of  4 variables:
#>   .. ..$ channel_key: num [1:79] 1 2 3 4 5 6 7 8 9 10 ...
#>   .. ..$ source     : chr [1:79] "source_481" "source_481" "source_481" "source_481" ...
#>   .. ..$ medium     : chr [1:79] "cpc" "cpc" "cpc" "cpc" ...
#>   .. ..$ campaign   : chr [1:79] "campaign_185" "campaign_1" "campaign_184" "campaign_158" ...
#>  - attr(*, "class")= chr "dm_model"
```

The function `dm_model` has extracted one dimension, `dim_channel`, from
the data frame and added a [surrogate
key](https://en.wikipedia.org/wiki/Surrogate_key) column named
`channel_key`.

The surrogate key will function as the [primary
key](https://en.wikipedia.org/wiki/Primary_key) of `dim_channel` which
will reference a [foreign
key](https://en.wikipedia.org/wiki/Foreign_key) in the fact table when
we populate the model with data.

Before we do so, let’s extend the model with a few more dimensions.

``` r
data("web_metrics")

str(web_metrics)
#> 'data.frame':    1500 obs. of  9 variables:
#>  $ date        : Date, format: "2021-11-25" "2021-04-08" ...
#>  $ view_name   : chr  "view_1" "view_1" "view_1" "view_2" ...
#>  $ country     : chr  "country_1" "country_1" "country_1" "country_2" ...
#>  $ source      : chr  "source_735" "source_950" "source_549" "source_735" ...
#>  $ medium      : chr  "email" "referral" "medium_99" "email" ...
#>  $ campaign    : chr  "email_65" "(not set)" "campaign_934" "email_405" ...
#>  $ sessions    : num  2 1 41 2 450 1 2 1 8 614 ...
#>  $ transactions: num  0 0 0 0 28 0 0 0 0 8 ...
#>  $ revenue     : num  0 0 0 0 19225 ...
```

The `web_metrics` dataset introduces two new dimension columns:
`view_name` and `country`. These can be added to the model as long as we
remember to use the model itself (`dm`) as an argument in the function.

``` r
dimensions = list(
  dim_channel = c("source", "medium", "campaign"),
  dim_market = c("view_name", "country")
)

# Extend the model using the model itself `dm` as an argument
dm <- dm_model(web_metrics, dimensions, dm)

str(dm)
#> List of 1
#>  $ dimensions:List of 2
#>   ..$ dim_channel:'data.frame':  313 obs. of  4 variables:
#>   .. ..$ channel_key: num [1:313] 1 2 3 4 5 6 7 8 9 10 ...
#>   .. ..$ source     : chr [1:313] "source_735" "source_950" "source_549" "source_735" ...
#>   .. ..$ medium     : chr [1:313] "email" "referral" "medium_99" "email" ...
#>   .. ..$ campaign   : chr [1:313] "email_65" "(not set)" "campaign_934" "email_405" ...
#>   ..$ dim_market :'data.frame':  2 obs. of  3 variables:
#>   .. ..$ market_key: num [1:2] 1 2
#>   .. ..$ view_name : chr [1:2] "view_1" "view_2"
#>   .. ..$ country   : chr [1:2] "country_1" "country_2"
#>  - attr(*, "class")= chr "dm_model"
```

The model now consist of two dimensions. Let’s add one more using the
final demo dataset.

``` r
data("email_metrics")

dimensions = list(
  dim_email = c("email")
  )
dm <- dm_model(email_metrics, dimensions, dm)

str(dm)
#> List of 1
#>  $ dimensions:List of 3
#>   ..$ dim_channel:'data.frame':  313 obs. of  4 variables:
#>   .. ..$ channel_key: num [1:313] 1 2 3 4 5 6 7 8 9 10 ...
#>   .. ..$ source     : chr [1:313] "source_735" "source_950" "source_549" "source_735" ...
#>   .. ..$ medium     : chr [1:313] "email" "referral" "medium_99" "email" ...
#>   .. ..$ campaign   : chr [1:313] "email_65" "(not set)" "campaign_934" "email_405" ...
#>   ..$ dim_market :'data.frame':  2 obs. of  3 variables:
#>   .. ..$ market_key: num [1:2] 1 2
#>   .. ..$ view_name : chr [1:2] "view_1" "view_2"
#>   .. ..$ country   : chr [1:2] "country_1" "country_2"
#>   ..$ dim_email  :'data.frame':  46 obs. of  2 variables:
#>   .. ..$ email_key: num [1:46] 1 2 3 4 5 6 7 8 9 10 ...
#>   .. ..$ email    : chr [1:46] "email_241" "email_163" "email_30" "email_164" ...
#>   .. ..- attr(*, "jobReference")=List of 3
#>   .. .. ..$ projectId: chr "gar-creds-185213"
#>   .. .. ..$ jobId    : chr "job_UZXfDJVHRH15-f4JwQ9BIKcObN19"
#>   .. .. ..$ location : chr "EU"
#>   .. ..- attr(*, "pageToken")= chr "BFTSDQS6QIAQAAASA4EAAEEAQCAAKGQGBDUAOEHIA4QLBLQV"
#>  - attr(*, "class")= chr "dm_model"
```

## Populate the model with data

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

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub and CRAN.
