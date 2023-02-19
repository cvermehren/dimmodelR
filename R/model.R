#' Create a dimensional model
#'
#' This is a description.
#'
#' @param flat_table The data frame from which the dimensional model should be
#'   created.
#' @param dimension_columns A named list with vectors of column names from
#'   `flat_table` each of which should form a dimension table.
#' @param dm A `dm_model` object, i.e. an object returned by `dm_model`
#'   or `dm_model_refresh`.
#' @param dm_path The file path for saving the model. If used the model will be
#'   saved as parquet files and the the model returned will be a list of arrow
#'   datasets.
#'
#' @import data.table
#' @return A `dm_model` object containing a list of dimension tables with primary
#'   keys pointing to the rows of `flat_table`.
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_model(flat_table, dimension_columns)
#'
#'
#' }
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

  if(isarrow) flat_table <- dplyr::collect(utils::head(flat_table))

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
dm_model_load <- function(dm_path) {

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
