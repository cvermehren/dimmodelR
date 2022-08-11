
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dimmodelR

<!-- badges: start -->
<!-- badges: end -->

Business-intelligence tools such as Power BI, Tableau and Qlik work best
when they consume data organized as a [dimensional
model](https://en.wikipedia.org/wiki/Dimensional_modeling). A common
task before using these tools is therefore to transform data according
to this model’s design principles. This is also know as [star
schema](https://en.wikipedia.org/wiki/Star_schema) design.

The `dimmodelR` package aims to make this easy using R. It provides a
set of functions for automating the creation and refreshment of a
central data model consisting of multiple [fact
tables](https://en.wikipedia.org/wiki/Fact_table) referencing a set of
shared
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

1.  Define a star schema from one or more data frames
2.  Populate the schema with data and set up incremental refresh
3.  Save the model as csv or parquet files and serve them to a BI tool

## Define a star schema

A star schema can be created from multiple data frames, but needs to be
built gradually. We will start with the included demo dataset
`campaign_metrics`:

``` r
library(dimmodelR)

data(campaign_metrics)

str(campaign_metrics)
#> 'data.frame':    449 obs. of  9 variables:
#>  $ date       : Date, format: "2021-09-04" "2021-05-28" ...
#>  $ source     : chr  "source_481" "source_481" "source_481" "source_481" ...
#>  $ medium     : chr  "cpc" "cpc" "cpc" "cpc" ...
#>  $ campaign   : chr  "campaign_185" "campaign_1" "campaign_184" "campaign_158" ...
#>  $ impressions: num  4 1123 41 91 24 ...
#>  $ ad_clicks  : num  1 712 3 5 1 118 1 4 1 142 ...
#>  $ ad_cost    : num  0.581 62.16 4.076 9.308 0.58 ...
#>  $ year       : chr  "2021" "2021" "2021" "2021" ...
#>  $ month      : chr  "09" "05" "04" "08" ...
```

Typically fact tables are formed by numerical columns, while dimension
columns are character type.

To define a star schema we only need to specify the dimensions. Fact
tables are added later when populating the model with data.

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

The function `dm_model()` has extracted one dimension, `dim_channel`,
from the data frame and added a [surrogate
key](https://en.wikipedia.org/wiki/Surrogate_key) column named
`channel_key`.

The surrogate key will function as the [primary
key](https://en.wikipedia.org/wiki/Primary_key) of `dim_channel` and
will be inserted into the fact table as a [foreign
key](https://en.wikipedia.org/wiki/Foreign_key) when we populate the
model with data.

Before we do so, let’s extend the model with a few more dimensions using
the `web_metrics` and `email_metrics` datasets.

``` r
data("web_metrics")

# Inspect the dataset
str(web_metrics)
#> 'data.frame':    1500 obs. of  11 variables:
#>  $ date        : Date, format: "2021-11-25" "2021-04-08" ...
#>  $ view_name   : chr  "view_1" "view_1" "view_1" "view_2" ...
#>  $ country     : chr  "country_1" "country_1" "country_1" "country_2" ...
#>  $ source      : chr  "source_735" "source_950" "source_549" "source_735" ...
#>  $ medium      : chr  "email" "referral" "medium_99" "email" ...
#>  $ campaign    : chr  "email_65" "(not set)" "campaign_934" "email_405" ...
#>  $ sessions    : num  2 1 41 2 450 1 2 1 8 614 ...
#>  $ transactions: num  0 0 0 0 28 0 0 0 0 8 ...
#>  $ revenue     : num  0 0 0 0 19225 ...
#>  $ year        : chr  "2021" "2021" "2021" "2021" ...
#>  $ month       : chr  "11" "04" "05" "05" ...
```

The `web_metrics` dataset introduces two new dimension columns:
`view_name` and `country`. These can be added to the model as long as we
remember to use the model itself (`dm`) as an argument in the function.

``` r
dimensions = list(
  dim_channel = c("source", "medium", "campaign"),
  dim_market = c("view_name", "country")
)

# Extend the model using the model itself (`dm`) as an argument
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
facts. To populate the model with facts, you only need to pass the model
and a named list of source data to `dm_refresh()`. The function will
automatically match the source data with dimensions in the model and
extract fact tables accordingly.

``` r
# Make a named list of source data from which fact tables should be extracted
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
#>   ..$ fct_email   :'data.frame': 376 obs. of  8 variables:
#>   .. ..$ email_key: num [1:376] 33 33 33 33 33 33 12 12 12 12 ...
#>   .. ..$ date     : Date[1:376], format: "2021-08-22" "2021-09-12" ...
#>   .. ..$ sent     : int [1:376] 53 1 38 47 1 1 131 852 135 197 ...
#>   .. ..$ bounced  : int [1:376] 0 0 0 0 0 0 0 0 0 0 ...
#>   .. ..$ opened   : int [1:376] 20 1 16 31 4 1 79 156 48 90 ...
#>   .. ..$ clicked  : int [1:376] 14 0 11 19 1 1 6 18 9 16 ...
#>   .. ..$ year     : chr [1:376] "2021" "2021" "2021" "2021" ...
#>   .. ..$ month    : chr [1:376] "08" "09" "09" "08" ...
#>   ..$ fct_campaign:'data.frame': 449 obs. of  7 variables:
#>   .. ..$ channel_key: num [1:449] 10 10 10 10 10 10 10 10 10 47 ...
#>   .. ..$ date       : Date[1:449], format: "2021-05-28" "2021-06-11" ...
#>   .. ..$ impressions: num [1:449] 1123 634 1689 640 709 ...
#>   .. ..$ ad_clicks  : num [1:449] 712 396 1037 444 463 ...
#>   .. ..$ ad_cost    : num [1:449] 62.2 76.8 97.9 74.4 72.5 ...
#>   .. ..$ year       : chr [1:449] "2021" "2021" "2021" "2021" ...
#>   .. ..$ month      : chr [1:449] "05" "06" "06" "08" ...
#>   ..$ fct_web     :'data.frame': 1500 obs. of  8 variables:
#>   .. ..$ market_key  : num [1:1500] 1 1 1 1 1 1 1 1 1 1 ...
#>   .. ..$ channel_key : num [1:1500] 5 5 5 5 5 5 331 332 332 333 ...
#>   .. ..$ date        : Date[1:1500], format: "2021-04-01" "2021-05-27" ...
#>   .. ..$ sessions    : num [1:1500] 450 557 863 647 455 559 1 1 1 1 ...
#>   .. ..$ transactions: num [1:1500] 28 23 72 61 11 10 0 0 0 0 ...
#>   .. ..$ revenue     : num [1:1500] 19225 11709 48431 44310 6450 ...
#>   .. ..$ year        : chr [1:1500] "2021" "2021" "2021" "2021" ...
#>   .. ..$ month       : chr [1:1500] "04" "05" "05" "12" ...
#>  - attr(*, "class")= chr "dm_model"
```

The model now contains all data from the three data frames (source data)
organized as a dimensional model.

The refresh function has added not only three fact tables, but also new
rows to the dimensions. The initial model is based only on a sample of
source data. When adding the entire datasets using the refresh function,
the dimensions are updated with rows that are new to the model.

The function also handles shared dimension. Two of the fact tables
(`fct_campaign` and `fct_web`) share the `dim_channel` dimension. In
other words, the function inserts this dimension’s primary key
(`channel_key`) into both of these fact tables. It automatically
identifies how to do so by comparing source data and existing dimensions
in the model.

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

# Load demo data
data("web_metrics")
data("campaign_metrics")
data("email_metrics")

# # Ad partitioning columns
# web_metrics$month <- lubridate::month(web_metrics$date)
# campaign_metrics$month <- lubridate::month(campaign_metrics$date)
# email_metrics$month <- lubridate::month(email_metrics$date)
# 
# # Create campaig_metrics model
# dimensions <- list(dim_channel = c("source", "medium", "campaign"))
# dm <- dm_model(campaign_metrics, dimensions)
# 
# # Extend model with web_metrics
# dimensions <- list(
#   dim_channel = c("source", "medium", "campaign"), 
#   dim_market = c("view_name", "country"))
# dm <- dm_model(web_metrics, dimensions, dm)
# 
# # Extend model with email_metrics
# dimensions <- list(dim_channel = c("email"))
# dm <- dm_model(email_metrics, dimensions, dm)

# Make looping-list for incremental refresh
months <- sort(unique(web_metrics$month))

# Simulate incremental refresh
for (i in months) {
  new_campaign_metrics <- campaign_metrics[which(campaign_metrics$month == i),]
  new_web_metrics <- web_metrics[which(web_metrics$month == i),]
  new_email_metrics <- email_metrics[which(email_metrics$month == i),]
  
  facts <- list(
    fct_campaign = new_campaign_metrics,
    fct_web = new_web_metrics,
    fct_email = new_email_metrics
    )
  
  dm <- dm_refresh(dm, facts)
  
  dm_write_parquet(dm,path = "my-incremental-model", partitioning = c("year", "month"))
}
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> dim_channel does not match new_fact; skipping the dimension...
#> dim_market does not match new_fact; skipping the dimension...
#> No new entries of email_key. Adding email_key to new fact...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> dim_market does not match new_fact; skipping the dimension...
#> dim_email does not match new_fact; skipping the dimension...
#> No new entries of channel_key. Adding channel_key to new fact...
#> No new entries of market_key. Adding market_key to new fact...
#> dim_email does not match new_fact; skipping the dimension...

# Viewing the created files for fct_campaign
list.files(
  path = "my-incremental-model/fact_tables/fct_campaign", 
  recursive = TRUE
  )
#>  [1] "year=2021/month=01/part-0.parquet" "year=2021/month=02/part-0.parquet"
#>  [3] "year=2021/month=03/part-0.parquet" "year=2021/month=04/part-0.parquet"
#>  [5] "year=2021/month=05/part-0.parquet" "year=2021/month=06/part-0.parquet"
#>  [7] "year=2021/month=07/part-0.parquet" "year=2021/month=08/part-0.parquet"
#>  [9] "year=2021/month=09/part-0.parquet" "year=2021/month=10/part-0.parquet"
#> [11] "year=2021/month=11/part-0.parquet" "year=2021/month=12/part-0.parquet"
```
