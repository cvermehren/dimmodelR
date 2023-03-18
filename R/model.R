#' Create a dimensional model
#'
#' This function creates a dimensional model from a data frame (i.e., the 'flat
#' table').
#'
#' A complete dimensional model consists of a set of dimension tables that
#' reference one or more fact tables. However, the dm_model function only
#' creates dimension tables, not fact tables. It is meant as the first step in
#' building a complete model. Fact tables are created and added to the model
#' later using the \code{\link{dm_refresh}} function.
#'
#' Moreover, the dm_model function builds dimension tables using only a sample
#' of the flat table. Even if you pass a very large flat table to the function,
#' it returns dimension tables with only a few rows. If you work with very large
#' flat tables that do not fit into memory, you can pass them to the function as
#' Arrow datasets pointing to a folder with Parquet files. If you specify the
#' dm_path argument, the dm_model function will save the returned model itself
#' as Parquet files organized in a sub-folder called 'dimensions'. This folder
#' can be loaded later as an Arrow dataset using the \code{\link{dm_load}}
#' function.
#'
#' The dm_model can include dimensions from multiple flat tables. This is done
#' by first initiating the model with a single flat table. This will return a
#' dm_model object ready for expansion. To expand the model, run the dm_model
#' function again using a new flat table and the returned dm_model object as
#' arguments. If some of the columns in the new flat table intersect with an
#' existing dimension in the model, and if you want this dimension to be updated
#' using these columns, simply specify them in the dimension_columns argument
#' using the same dimension name as the existing dimension.
#'
#' @param flat_table A data frame or an Arrow dataset from which the dimensional
#'   model should be created.
#' @param dimension_columns A named list with vectors of column names from
#'   `flat_table` each of which should form a dimension table.
#' @param dm A `dm_model` object, i.e. an object returned by `dm_model` or
#'   `dm_model_refresh`, used when adding more dimensions to the model by
#'   passing additional flat tables to the function.
#' @param dm_path The file path for saving the model. If used the model will be
#'   saved as parquet files and the the model returned will be a list of arrow
#'   datasets.
#'
#' @import data.table
#' @return A `dm_model` object containing a list of dimension tables with primary
#'   keys.
#' @seealso \code{\link{dm_refresh}}
#' @export
#'
#' @examples
#'
#' library(dimmodelR)
#'
#' data(campaign_metrics)
#'
#' # Define dimensions as a named list of column names from campaign_metrics
#' dimensions = list(dim_channel = c("source", "medium", "campaign"))
#'
#' # Initiate the model
#' dm <- dm_model(campaign_metrics, dimensions)
#'
#' # The `dm` object, the model, now holds one dimension, called `dim_channel`,
#' # consisting of the unique combination of the columns 'source', 'medium' and
#' # 'campaign' from the data frame `campaign_metrics`. A surrogate key column
#' # named `channel_key` has been added which will be used to create the fact
#' # table when the model is populated with data using dm_refresh.
dm_model <- function(flat_table,
                     dimension_columns,
                     dm = NULL,
                     dm_path = NULL) {

  # Test if flat table is an Arrow dataset
  isarrow <- all(
    inherits(flat_table, "ArrowObject"),
    inherits(flat_table, "FileSystemDataset")
  )

  if(!(is.data.frame(flat_table) | isarrow)) stop("flat_table must be a data.frame or an Arrow dataset!\n")

  if(!is.list(dimension_columns)) stop("dimension_columns must be a list object!\n")

  if(is.null(names(dimension_columns))) stop(
    "dimension_columns must be a named list, where each element is a vector of
    `flat_table` column-names that should form a unique dimension.\n"
    )

  has_dim_prefix <- all(startsWith(names(dimension_columns), "dim_"))

  if(!has_dim_prefix) stop(
    "All dimension names must start with 'dim_'.\n",
    "Dimension names are the names of the list passed to `dimension_columns`.\n"
    )

  has_key_suffix <- any(unlist(lapply(dimension_columns, endsWith, "_key")))

  if(has_key_suffix) stop(
    "Dimension column names (passed to `dimension_columns`) must not end with
    '_key'. This column suffix is reserved for the dimension's primary key
    column.\n"
  )

  if(!is.null(dm) & !inherits(dm, "dm_model")) stop(
    "dm must be a `dm_model` object, i.e. an object returned by
    `dm_model` or `dm_model_refresh`.\n"
  )

  #if(isarrow) flat_table <- dplyr::collect(utils::head(flat_table))

  if(isarrow) {
    frac <- 2000/nrow(flat_table)
    frac <- ifelse(frac >= 0, 0.5, frac)
    flat_table <-  flat_table |>
      arrow::map_batches(~ arrow::as_record_batch(dplyr::sample_frac(as.data.frame(.), frac))) |>
      dplyr::collect()
    }

  data.table::setDT(flat_table)

  # Take sample of flat_table
  flat_table <- flat_table[1:500]
  flat_cols <- names(flat_table)

  # Make all dimension columns character
  for (i in seq_along(dimension_columns)) {

    character_cols <- dimension_columns[[i]]

    if(!all(character_cols %in% flat_cols)) stop(
      "dimension_columns must be columns of `flat_table`!\n"
    )

    flat_table[, (character_cols) := lapply(.SD, as.character), .SDcols = character_cols]
  }

  # Format and save dim
  for(i in seq_along(dimension_columns)) {

    dim_name <- names(dimension_columns[i])
    dim_cols <- dimension_columns[i][[1]]

    key_name <- paste0(dim_name, "_key")
    key_name <- gsub("^dim_", "", key_name)

    dim <- unique(flat_table[, .SD, .SDcols = dim_cols])

    # Replace NAs with "n/a"
    dim[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]
    flat_table[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]

    # Insert surrogate key
    dim[, (key_name) := as.double(1:nrow(dim)) ]

    # Reorder columns
    setcolorder(dim, c(key_name, setdiff(names(dim), key_name)))

    stopifnot(min(dim[,get(key_name)]) == 1)
    stopifnot(max(dim[,get(key_name)]) == nrow(dim))
    stopifnot(length(unique(dim[,get(key_name)])) == nrow(dim))

    data.table::setDF(dim)

    # Write to parquet
    if(!is.null(dm_path)) {
      dm_path_tmp <- file.path(dm_path, "dimensions", dim_name)
      arrow::write_dataset(dim, dm_path_tmp)
      dim <- arrow::open_dataset(dm_path_tmp)
    }

    # Add dim to dim_list
    if(!exists("dim_list")) dim_list <- list()
    dim_list[[names(dimension_columns[i])]] <- dim

  }

  if(!is.null(dm)) {

    for(i in seq_along(dim_list)) {
      name <- names(dim_list)[i]
      dm$dimensions[[name]] <- dim_list[[i]]
    }

  } else {

    dm <- structure(list(dimensions = dim_list), class = "dm_model")

  }

  return(dm)

}


#' Load a dimensional model from Parquet files
#'
#' This is a description.
#'
#' @param dm_path Path to the dimensional model
#'
#' @return A `dm_model` object containing a list of dimension tables with primary
#'   keys pointing to the rows of `flat_table`.
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_model_load("/path/to/my/dim_model")
#'
#'
#' }
dm_load <- function(dm_path) {

  # Open dimension datasets
  dim_paths <- list.dirs(path = paste0(dm_path, "/dimensions"), recursive = FALSE)
  dim_names <- basename(dim_paths)

  dim_list <- list()

  for (i in seq_along(dim_paths)) {

    dim_list[[dim_names[i]]] <- arrow::open_dataset(dim_paths[i])
  }


  # Open facts datasets
  fact_paths <- list.dirs(path = paste0(dm_path, "/facts"), recursive = FALSE)
  fact_names <- basename(fact_paths)

  fact_list <- list()

  for (i in seq_along(fact_paths)) {

    fact_list[[fact_names[i]]] <- arrow::open_dataset(fact_paths[i])
  }

  # Create dm_model object
  dm <- structure(
    list(
      dimensions = dim_list,
      facts = fact_list
    ),
    class = "dm_model"
  )

  return(dm)

}
