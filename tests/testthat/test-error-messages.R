test_that("error when dim columns ends with '_key'", {

  flat_table <- as.data.frame( UCBAdmissions)
  names(flat_table)[1] <- "Admit_key"

  dimension_columns <- list(dim_department = c("admit_key", "Dept"), dim_gender = "Gender")

  expect_error(ubc_model <- dm_model_create(flat_table, dimension_columns))

  })


test_that("error dim names do not start with 'dim_'", {

  data("campaign_metrics")
  flat_table <-campaign_metrics

  dimension_columns = list(
    test = c("channel_grouping", "source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  expect_error(dm_model_create(flat_table, dimension_columns))


})



test_that("error when only one new_fact col match dm_model", {

  data(campaign_metrics)
  data(email_metrics)
  names(email_metrics)[1] <- "campaign"

  dim_cols = list(
    dim_channel = c("channel_grouping", "source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  dm_model <- dm_model_create(campaign_metrics, dim_cols)

  old_dim <- dm_model$dimensions$dim_channel
  new_fact <- email_metrics

  expect_error(dm_dim_refresh(old_dim, email_metrics) )


})


test_that("error when new_fact cols match dm model", {

  data(campaign_metrics)
  data(email_metrics)

  dim_cols = list(
    dim_channel = c("channel_grouping", "source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  dm_model <- dm_model_create(campaign_metrics, dim_cols)

  old_dim <- dm_model$dimensions$dim_channel
  new_fact <- email_metrics

  expect_error(dm_dim_refresh(old_dim, new_fact))

  })




