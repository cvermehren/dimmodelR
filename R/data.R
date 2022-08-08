#' Demo Data: Web Metrics
#'
#' A sample of data from a web analytics tool such as Google Analytics which is
#' typical of an online retailer. The data show how the retailer's digital
#' channels are performing.
#'
#' Unique channels are identified by combining the columns `source`, `medium`
#' and `campaign`. Some channels are paid for by the retailer, others are not.
#' In the latter case the `campaign` column will show '(not set)'.
#'
#' Performance is measured by the number of visits (sessions), the number of
#' purchases (transactions) and the total revenue a channel brings to the
#' website. A common performance metric is the conversion rate, which can be
#' calculated as the number of purchases divided by the number of sessions.
#'
#' Typically a retailer would also want to calculate the Return On Ad Spend
#' (ROAS) for each paid-for campaign. However, web metrics data do not include
#' information on spend (ad costs), which is why online retailers often try to
#' combine these data with data pulled from the advertising platforms there are
#' investing in: Facebook, Google Ads, Bing, etc. (available as demo data in
#' \link{campaign_metrics}).
#'
#' @seealso \link{campaign_metrics}, \link{email_metrics}
"web_metrics"

#' Demo Data: Campaign Metrics
#'
#' A sample of data extracted and combined from different advertising platforms:
#' Facebook, Google Ads, Bing, etc. Most importantly, the data show the total
#' amount invested in the campaigns (`ad_cost`).
#'
#' Campaign data can be combined with \link{web_metrics} to get the full picture
#' of campaign performance. The most important performance metric is Return On
#' Advertising Spend (ROAS) calculated as revenue (from \link{web_metrics})
#' divided by ad cost in this data.
#'
#'
#'
#' @seealso \link{web_metrics}, \link{email_metrics}
"campaign_metrics"

#' Demo Data: Email Metrics
#'
#' A fact table showing individual visitors and their transactions on an
#' e-commerce website.
#'
#' @seealso \link{web_metrics}, \link{campaign_metrics}
"email_metrics"
