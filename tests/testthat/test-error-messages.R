test_that("error when dim columns ends with '_key'", {

  flat_table <- as.data.frame( UCBAdmissions)
  names(flat_table)[1] <- "Admit_key"

  dimension_columns <- list(dim_department = c("admit_key", "Dept"), dim_gender = "Gender")

  expect_error(ubc_model <- dm_model(flat_table, dimension_columns))

  })


test_that("error when dim names do not start with 'dim_'", {

  data("web_metrics")
  flat_table <-web_metrics

  dimension_columns = list(
    test = c("source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  expect_error(dm_model(flat_table, dimension_columns))


})



test_that("error when only one new_fact col matches dm_model", {

  data(web_metrics)
  data(email_metrics)
  names(email_metrics)[1] <- "campaign"

  dim_cols = list(
    dim_channel = c("source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  dm_model <- dm_model(web_metrics, dim_cols)

  old_dim <- dm_model$dimensions$dim_channel
  new_fact <- email_metrics

  expect_error(dm_dim_refresh(old_dim, email_metrics) )


})


test_that("error when no new_fact cols match dm model", {

  data(web_metrics)
  data(email_metrics)

  dim_cols = list(
    dim_channel = c("source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  dm_model <- dm_model(web_metrics, dim_cols)

  old_dim <- dm_model$dimensions$dim_channel
  new_fact <- email_metrics

  expect_error(dm_dim_refresh(old_dim, new_fact))

  })




