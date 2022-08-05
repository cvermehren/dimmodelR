library(testthat)
library(data.table)

testthat::test_that("dim model aggregates match source aggregates", {

  data(campaign_metrics)

  dim_cols = list(
    dim_channel = c("channel_grouping", "source", "medium", "campaign"),
    dim_market = c("view_name", "country")
  )

  dm <- dm_model_create(campaign_metrics, dim_cols)
  dm <- dm_model_refresh(dm, campaign_metrics)


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
