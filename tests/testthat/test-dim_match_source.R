testthat::test_that("dim model aggregates match source aggregates", {

  data(campaign_metrics)

  dim_cols = list(
    dim_channel = c("channel_grouping", "source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  dm <- dm_model_create(campaign_metrics, dim_cols)
  dm <- suppressMessages(dm_model_refresh(dm, campaign_metrics))


  cm <- as.data.table(dm$fact)
  cm <- cm[, .(sessions = sum(sessions)), by = channel_key]
  dim_cm <- as.data.table(dm$dimensions$dim_channel)

  setkey(cm, channel_key)
  setkey(dim_cm, channel_key)

  res1 <- dim_cm[cm]
  res1[, channel_key := NULL]
  setkeyv(res1, names(res1))

  res2 <- campaign_metrics[, .(sessions = sum(sessions)), by = .(channel_grouping, source, medium, campaign)]
  setkeyv(res2, names(res2))

  expect_identical(res1, res2)
})


testthat::test_that("dim model aggregates match source aggregates", {

  data(campaign_metrics)
  data(email_metrics)

  dim_cols = list(
    dim_channel = c("channel_grouping", "source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  dm_model <- dm_model_create(campaign_metrics, dim_cols)

  dim_cols = list(dim_email = "email")

  dm_model <- dm_model_create(email_metrics, dim_cols, dm_model)

  new_fact_list <- list(
    fct_email =email_metrics,
    fct_campaign = campaign_metrics
  )

  fact_names <- names(new_fact_list)

  for (i in seq_along(new_fact_list)) {

    dm_model <- suppressMessages(
      dm_model_refresh(dm_model, new_fact_list[[i]], fact_name = fact_names[i])
      )

  }

  expect_equal(length(dm_model), 2)
  expect_equal(length(dm_model$fact_tables), 2)
  expect_equal(length(dm_model$dimensions), 3)

  expect_equal(nrow(dm_model$fact_tables$fct_email), 1500)
  expect_equal(nrow(dm_model$fact_tables$fct_campaign), 1500)

})

