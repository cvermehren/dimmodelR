
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

dimensions = list(dim_email = c("email"))

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
#>  - attr(*, "class")= chr "dm_model"
```

## Populate the model with data

We now have a dimensional model consisting of three dimensions, but no
facts. To populate the model with facts, we simply pass the model and
the original data frames to the function `dm_refresh`.

``` r
# Specify the data frames which the model was built from
facts <- list(
  fct_email = email_metrics, 
  fct_campaign = campaign_metrics,
  fct_web = web_metrics
)

# Populate the model with data
dm <- dm_refresh(dm, facts)
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> There were 17 new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> There were 282 new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...

str(dm)
#> List of 2
#>  $ dimensions :List of 3
#>   ..$ dim_channel:'data.frame':  612 obs. of  4 variables:
#>   .. ..$ channel_key: num [1:612] 1 2 3 4 5 6 7 8 9 10 ...
#>   .. ..$ source     : chr [1:612] "source_735" "source_950" "source_549" "source_735" ...
#>   .. ..$ medium     : chr [1:612] "email" "referral" "medium_99" "email" ...
#>   .. ..$ campaign   : chr [1:612] "email_65" "(not set)" "campaign_934" "email_405" ...
#>   ..$ dim_market :'data.frame':  2 obs. of  3 variables:
#>   .. ..$ market_key: num [1:2] 1 2
#>   .. ..$ view_name : chr [1:2] "view_1" "view_2"
#>   .. ..$ country   : chr [1:2] "country_1" "country_2"
#>   ..$ dim_email  :'data.frame':  46 obs. of  2 variables:
#>   .. ..$ email_key: num [1:46] 1 2 3 4 5 6 7 8 9 10 ...
#>   .. ..$ email    : chr [1:46] "email_241" "email_163" "email_30" "email_164" ...
#>  $ fact_tables:List of 3
#>   ..$ fct_email   :'data.frame': 376 obs. of  6 variables:
#>   .. ..$ email_key: num [1:376] 33 33 33 33 33 33 12 12 12 12 ...
#>   .. ..$ date     : num [1:376] 18861 18882 18872 18862 18875 ...
#>   .. ..$ sent     : int [1:376] 53 1 38 47 1 1 131 852 135 197 ...
#>   .. ..$ bounced  : int [1:376] 0 0 0 0 0 0 0 0 0 0 ...
#>   .. ..$ opened   : int [1:376] 20 1 16 31 4 1 79 156 48 90 ...
#>   .. ..$ clicked  : int [1:376] 14 0 11 19 1 1 6 18 9 16 ...
#>   ..$ fct_campaign:'data.frame': 449 obs. of  5 variables:
#>   .. ..$ channel_key: num [1:449] 10 10 10 10 10 10 10 10 10 47 ...
#>   .. ..$ date       : Date[1:449], format: "2021-05-28" "2021-06-11" ...
#>   .. ..$ impressions: num [1:449] 1123 634 1689 640 709 ...
#>   .. ..$ ad_clicks  : num [1:449] 712 396 1037 444 463 ...
#>   .. ..$ ad_cost    : num [1:449] 62.2 76.8 97.9 74.4 72.5 ...
#>   ..$ fct_web     :'data.frame': 1500 obs. of  6 variables:
#>   .. ..$ market_key  : num [1:1500] 1 1 1 1 1 1 1 1 1 1 ...
#>   .. ..$ channel_key : num [1:1500] 5 5 5 5 5 5 331 332 332 333 ...
#>   .. ..$ date        : Date[1:1500], format: "2021-04-01" "2021-05-27" ...
#>   .. ..$ sessions    : num [1:1500] 450 557 863 647 455 559 1 1 1 1 ...
#>   .. ..$ transactions: num [1:1500] 28 23 72 61 11 10 0 0 0 0 ...
#>   .. ..$ revenue     : num [1:1500] 19225 11709 48431 44310 6450 ...
#>  - attr(*, "class")= chr "dm_model"
```

The model now contains all the data from the three data frames (the
source data) organized as a dimensional model.

Notice how the refresh function has added not only three fact tables,
but also new rows to the dimensions. The reason is that the initial
model was based only on a sample of source data. When adding the entire
datasets using the refresh function, the dimensions are updated with
rows new to the model.

Notice also how the function handles shared dimension. Two of the fact
tables (`fct_campaign` and `fct_web`) share the `dim_channel` dimension.
In other words, the function inserts this dimension’s primary key
(`channel_key`) into both of these fact tables. It automatically
identifies how to do so by comparing source data and the existing
dimensions in the model.

To save the result as csv files:

``` r
dm_write_csv(dm, "my-folder")

list.files(path = "my-folder", recursive = TRUE)
#> [1] "dimensions/dim_channel.csv"   "dimensions/dim_email.csv"    
#> [3] "dimensions/dim_market.csv"    "fact_tables/fct_campaign.csv"
#> [5] "fact_tables/fct_email.csv"    "fact_tables/fct_web.csv"
```

The `dm_write_csv` function saves the result in two sub-directories
`dimensions` and `fact_tables`. It will always overwrite the files and,
therefore, is not meant for incremental refresh.

## Incremental refresh

To refresh your model incrementally, simply feed the model with the
newest source data followed by `dm_write_parquet`.

Let’s simulate how this would work.

``` r

dates <- seq.Date(min(web_metrics$date), max(web_metrics$date), "day")

# i=dates[3]
# 
# for (i in dates) {
# 
#   new_source_data <- web_metrics[web_metrics$date == i,]
# 
#   facts <- list(
#     fct_email = email_metrics,
#     fct_campaign = campaign_metrics,
#     fct_web = web_metrics
#     )
# 
#   dm <- dm_refresh(dm, facts)
# 
#   dm_write_parquet(dm, "my-incremental-model", partitioning = "date")
# }
# 
# 
# # dm_write_csv(dm, "my-folder")
# # 
# # list.files(path = "my-folder", recursive = TRUE)
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

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub and CRAN.
