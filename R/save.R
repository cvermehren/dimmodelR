#' Refresh a dimension
#'
#' This is a description.
#'
#' @param dm A model object
#' @param path A fact table
#' @param partitioning A fact table2
#'
#' @import data.table
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_save(old_dim, new_fact)
#'
#'
#' }
dm_write_parquet <- function(dm, path, partitioning = NULL) {

  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("Please install package arrow to use this function.")
  }

  # if(!overwrite & dir.exists(path)) stop(
  #   "The directory '", path, "' already exists. Please set overwrite to"
  #   )

  # Save dimensions (no partitioning)
  dim_names <- names(dm$dimensions)

  for (i in seq_along(dm$dimensions)) {
    dimpath <- file.path(path, "dimensions")
    dir.create(dimpath, recursive = TRUE, showWarnings = FALSE)
    filename <- file.path(dimpath, paste0(dim_names[i], ".parquet"))
    arrow::write_parquet(dm$dimensions[[i]], filename)
  }

  # Save fact tables with partitioning option
  fct_names <- names(dm$fact_tables)

  for (i in seq_along(dm$fact_tables)) {

    fctpath <- file.path(path, "fact_tables")

    if(is.null(partitioning)) {
      dir.create(fctpath, recursive = TRUE, showWarnings = FALSE)
      filename <- file.path(fctpath, paste0(fct_names[i], ".parquet"))
      arrow::write_parquet(dm$fact_tables[[i]], filename)

    } else {

      fctpath <- file.path(fctpath, fct_names[i])
      dir.create(fctpath, recursive = TRUE, showWarnings = FALSE)
      arrow::write_dataset(
        dm$fact_tables[[i]],
        fctpath,
        partitioning = partitioning
      )
    }
  }

}



#' Save mode as csv
#'
#' This is a description.
#'
#' @param dm A model object
#' @param path A fact table
#' @param ... Arguments passed to data.table::fwrite
#'
#' @import data.table
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_save(old_dim, new_fact)
#'
#'
#' }
dm_write_csv <- function(dm, path, ...) {

  # Save dimensions (no partitioning)
  dim_names <- names(dm$dimensions)

  for (i in seq_along(dm$dimensions)) {
    dimpath <- file.path(path, "dimensions")
    dir.create(dimpath, recursive = TRUE, showWarnings = FALSE)
    filename <- file.path(dimpath, paste0(dim_names[i], ".csv"))
    data.table::fwrite(dm$dimensions[[i]], filename, ...)

  }

  # Save fact tables with partitioning option
  fct_names <- names(dm$fact_tables)

  for (i in seq_along(dm$fact_tables)) {

    fctpath <- file.path(path, "fact_tables")

    dir.create(fctpath, recursive = TRUE, showWarnings = FALSE)
    filename <- file.path(fctpath, paste0(fct_names[i], ".csv"))

    data.table::fwrite(dm$fact_tables[[i]], filename, ...)

  }

}
