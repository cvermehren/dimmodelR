
dm_refresh_one_fact <- function(dm, new_fact, fact_name, dm_path = NULL) {

  if(!is.null(dm) & !inherits(dm, "dm_model")) stop(
    "dm must be a `dm_model` object, i.e. an object returned by
    `dm_model` or `dm_refresh_one_fact`.\n"
    )

  has_fct_prefix <- startsWith(fact_name, "fct_")

  if(!has_fct_prefix) stop(
    "The name of fact tables (passed to `fact_name`) must start with 'fct_'.\n"
  )

  dimension_names <- names(dm$dimensions)

  dim_ls <- list()

  for (i in seq_along(dm$dimensions)) {

    old_dim <- dm$dimensions[[i]]

    # If dim is an Arrow dataset, collect into memory
    isarrow <- all(
      inherits(old_dim, "ArrowObject"),
      inherits(old_dim, "FileSystemDataset")
      )
    if(isarrow) old_dim <- dplyr::collect(old_dim)

    # If fact is an Arrow dataset, collect into memory
    is_fact_arrow <- all(
      inherits(new_fact, "ArrowObject"),
      inherits(new_fact, "FileSystemDataset")
    )
    if(is_fact_arrow) new_fact <- dplyr::collect(new_fact)

    # Check if old_dim is unique with only shared_cols
    no_match <- dm_check_dim_match(old_dim, new_fact)

    if (no_match) {
      message(dimension_names[i], " does not match new_fact; skipping the dimension...\n")
      next
    }

    # Refresh using the internal function
    refreshed_schema <- dm_dim_refresh(old_dim = old_dim, new_fact = new_fact)

    # Add refreshed dim to empty list
    if(isarrow) {
      path_tmp <- file.path(dm_path, "dimensions", dimension_names[i])
      arrow::write_dataset(refreshed_schema$dimension, path_tmp)
      dim_ls[[dimension_names[i]]] <- arrow::open_dataset(path_tmp)

    } else {

      dim_ls[[dimension_names[i]]] <- refreshed_schema$dimension

    }

    # Overwrite new_fact and use this in next iteration
    new_fact <- refreshed_schema$fact

  }

  # If model exists, add dim to model
  # Otherwise create model
  if(!is.null(dm)) {

    dm$fact <- NULL

    for(i in seq_along(dim_ls)) {
      name <- names(dim_ls)[i]
      dm$dimensions[[name]] <- dim_ls[[i]]
    }

  } else {

    dm <- structure(
      list(dimensions = dim_ls),
      class = "dm_model"
    )
  }

  dm$fact_tables[[fact_name]] <- new_fact

  return(dm)
}

#' Save mode as csv
#'
#' This is a description.
#'
#' @param dm A model object
#' @param new_fact_list A fact table
#' @param dm_path A fact table
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
dm_refresh <- function(dm, new_fact_list, dm_path = NULL, ...) {

  # Get names of fact tables
  fact_names <- names(new_fact_list)

  # Refresh each new fact table
  for (i in seq_along(new_fact_list)) {

    if(nrow(new_fact_list[[i]])==0) next

    dm <- dm_refresh_one_fact(
      dm,
      new_fact_list[[i]],
      fact_name = fact_names[i],
      dm_path = dm_path
    )

    if(!is.null(dm_path)) {
      # Save as parquet
      path_tmp <- file.path(dm_path, "facts", fact_names[i])
      arrow::write_dataset(dm$fact_tables[[fact_names[i]]], path_tmp, ...)

      # Open Arrow dataset and add it to model
      dm$fact_tables[[fact_names[i]]] <- arrow::open_dataset(path_tmp)
    }


  }

  return(dm)
}


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
