#' Demo data: Campaign Metrics
#'
#' A look-up dimension related to Fact Visitors through the hour_key column.
#'
#' @format A data frame with 24 rows and 2 columns:
#' \describe{
#'   \item{date}{Primary key (unique identifier of hour).}
#'   \item{view_name}{Hour as a name (character type).}
#'   \item{country}{Hour as a name (character type).}
#'   \item{channel_grouping}{Hour as a name (character type).}
#'   \item{source}{Hour as a name (character type).}
#'   \item{medium}{Hour as a name (character type).}
#'   \item{campaign}{Hour as a name (character type).}
#'   \item{impressions}{Hour as a name (character type).}
#'   \item{ad_clicks}{Hour as a name (character type).}
#'   \item{ad_cost}{Hour as a name (character type).}
#'   \item{sessions}{Hour as a name (character type).}
#'   \item{transactions}{Hour as a name (character type).}
#'   \item{revenue}{Hour as a name (character type).}
#'   }
#'
#' @source Anonymized data from google analytics.
"campaign_metrics"

#' Demo data: Email Send Data
#'
#' A fact table showing individual visitors and their transactions on an
#' e-commerce website.
#'
#' @format A data frame with 10,033 rows and 5 columns:
#' \describe{
#'   \item{email}{Unique identifier of the visitor.}
#'   \item{date}{Unique identifier of the transactions.}
#'   \item{sent}{The value of the transaction in USD.}
#'   \item{bounced}{The time of visit in minutes since 1970-01-01.}
#'   \item{opened}{Foreign key referring to dim_hour.}
#'   \item{clicked}{Foreign key referring to dim_hour.}
#'   }
#'
#' @source Anonymized data from google analytics.
"email_metrics"
