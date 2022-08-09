#' Demo Data: Web Metrics
#'
#' These data resemble data that could be extracted from a web analytics tool
#' such as Google Analytics. They show how an online retailer's digital channels
#' are performing.
#'
#' To identify unique channels it is necessary to combine the columns `source`,
#' `medium` and `campaign`. Some channels are paid for by the retailer, others
#' are not. If not, the `campaign` column will show '(not set)'.
#'
#' Channel performance is measured by number of visits (sessions), number of
#' purchases (transactions) and total revenue. A common performance metric is
#' the conversion rate, which can be calculated as the number of purchases
#' divided by the number of sessions.
#'
#' Typically a retailer would also want to calculate the Return On Ad Spend
#' (ROAS) for each paid-for campaign. However, web metrics data do not normally
#' include information on spend (ad costs). As such, online retailers often try
#' to combine these data with data pulled from the advertising platforms there
#' are investing in: Facebook Ads, Google Ads, Bing Ads, etc. (available as demo
#' data in \link{campaign_metrics}).
#'
#' @seealso \link{campaign_metrics}, \link{email_metrics}
"web_metrics"

#' Demo Data: Campaign Metrics
#'
#' These data resemble data that could be extracted extracted and combined from
#' different advertising platforms: Facebook Ads, Google Ads, Bing Ads, etc.
#' Among other things, the data show the total amount of money invested in each
#' campaign (`ad_cost`).
#'
#' The campaign metrics data can be combined with \link{web_metrics} to get the
#' full picture of campaign performance. You can merge the data using the
#' columns `source`, `medium` and `campaign` as key. For the purposes of this
#' package, these three columns will be used to create a single dimension which
#' is shared by two fact tables.
#'
#' The most important performance metric is Return On Advertising Spend (ROAS)
#' calculated as `revenue` (from \link{web_metrics}) divided by `ad_cost`.
#' However, `impressions` and `clicks` are also worth considering.
#'
#' @seealso \link{web_metrics}, \link{email_metrics}
"campaign_metrics"

#' Demo Data: Email Metrics
#'
#' These data resemble data that could be extracted from a marketing automation
#' tool such as SalesForce Marketing Cloud or MailChimp. They show the
#' performance of each email in terms of the number of times it was sent, opened
#' and clicked.
#'
#' The email metrics data share only one column (the column named `email`) with
#' \link{web_metrics} and \link{campaign_metrics} (the column named `campaign`).
#' But this relation is (potentially) a many-to-many relation, which is why the
#' email data cannot share a dimension directly with the web and campaign
#' metrics data.
#'
#' @seealso \link{web_metrics}, \link{campaign_metrics}
"email_metrics"
