#' Create a dimensional model
#'
#' This function creates a dimensional model from a data frame (referred to as
#' 'flat table').
#'
#' A complete dimensional model consists of a set of dimension tables that
#' reference one or more fact tables. However, \code{\link{dm_model}} only
#' creates dimension tables, not fact tables. It is meant as the first step in
#' building a complete model. Fact tables are created and added to the model
#' later using \code{\link{dm_refresh}}.
#'
#' Moreover, \code{\link{dm_model}} builds dimension tables using only a sample
#' of the flat table. Even if you pass a very large flat table to the function,
#' it returns dimension tables with only a few rows. If you work with big data
#' that do not fit into memory, you can pass them to the function as Arrow
#' datasets pointing to a folder with Parquet files. If you specify the
#' \code{dm_path} argument, \code{\link{dm_model}} will save the returned model
#' itself as Parquet files organized in a sub-folder called 'dimensions'. This
#' folder can be loaded later as an Arrow dataset using \code{\link{dm_load}}.
#'
#' \code{\link{dm_model}} can include dimensions from multiple flat tables. This
#' is done by first initiating the model with a single flat table. This will
#' return a \code{dm_model} object ready for expansion. To expand the model, run
#' \code{dm_model} again using a new flat table and the returned \code{dm_model}
#' object as arguments. If some of the columns in the new flat table intersect
#' with an existing dimension in the model, and if you want this dimension to be
#' updated using these columns, simply specify them in the
#' \code{dimension_columns} argument using the same dimension name as the
#' existing dimension.
#'
#' @param flat_table A data frame or an Arrow dataset from which the dimensional
#'   model should be created.
#' @param dimension_columns A named list with vectors of column names from
#'   `flat_table` each of which should form a dimension table.
#' @param dm A `dm_model` object, i.e. an object returned by `dm_model` or
#'   `dm_model_refresh`, used when adding more dimensions to the model by
#'   passing additional flat tables to the function.
#' @param dm_path string path referencing a directory to write the dimensional
#'   model to (directory will be created if it does not exist). If used the model
#'   will be saved as parquet files and the the model returned will be a list of
#'   arrow datasets.
#'
#' @import data.table
#' @return A \code{dm_model} object containing a list of dimension tables (data
#'   frames) with primary keys. If \code{dm_path} is used the returned object
#'   will be a list with Arrow datasets (useful when working with big data).
#' @seealso \code{\link{dm_refresh}}
#' @export
#'
#' @examples
#'
#' library(dimmodelR)
#'
#' # Load demo data
#' data(campaign_metrics)
#' data(campaign_metrics)
#'
#' # Define dimensions as a named list of column names from campaign_metrics
#' dimensions = list(dim_channel = c("source", "medium", "campaign"))
#'
#' # Initiate the model
#' dm <- dm_model(campaign_metrics, dimensions)
#'
#' # Add dimensions from web_metrics
#' dimensions = list(
#'   dim_channel = c("source", "medium", "campaign"),
#'   dim_market = c("view_name", "country")
#'   )
#'
#' # Expand the model using the model itself (`dm`) as an argument
#' dm <- dm_model(web_metrics, dimensions, dm)
#'
#' \dontrun{
#'
#' # When working with big data, use the arrow package
#'
#' library(arrow)
#'
#' # Let's imagine campaign_metrics is too big to fit into memory
#' flattable <- tempfile()
#' arrow::write_dataset( campaign_metrics, flattable)
#'
#' # Set the path of the dimensional model you are going to create
#' model_path <- file.path(getwd(), "my-model")
#'
#' # Open campaign_metrics as an Arrow dataset
#' # (imagining it is too big for memory)
#' cam <- arrow::open_dataset(flattable)
#'
#' # Define dimension columns
#' dimension_columns <- list(dim_channel = c("source", "medium", "campaign"))
#'
#' # Initiate the mode without loading into memory (using the dm_path argument)
#' dm <- dm_model(
#'   flat_table = cam,
#'   dimension_columns = dimension_columns,
#'   dm = NULL,
#'   dm_path = model_path
#'   )
#'
#' # Let's add dimensions from web_metrics
#' # Again we imagine it is big
#' flattable <- tempfile()
#' arrow::write_dataset(web_metrics, flattable)
#'
#' web <- arrow::open_dataset(flattable)
#'
#' dimension_columns = list(
#'   dim_channel = c("source", "medium", "campaign"),
#'   dim_market = c("view_name", "country")
#'   )
#'
#' dm <- dm_model(
#'   flat_table = web,
#'   dimension_columns = dimension_columns,
#'   dm = dm,
#'   dm_path = dm_path = model_path
#'   )
#'
#' # Check the result
#' list.files(model_path, recursive = TRUE)
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
#' This function makes it easy to load a dimensional model previously built
#' with \code{\link{dm_model}} and saved as Parquet files. The model is loaded
#' as Arrow datasets.
#'
#' Saving your model as Parquet files is practical if you are working with
#' big data. When it is time to update your model with new rows from
#' \code{flat_table}, use \code{\link{dm_load}} before passing it to
#' \code{\link{dm_refresh}}.
#'
#' @param dm_path string path referencing the directory to which you have saved
#'   your model using \code{\link{dm_model}} or \code{\link{dm_refresh}}.
#'
#' @return A \code{dm_model} object containing a list of dimension tables with primary
#'   keys pointing to the rows of \code{flat_table}.
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' # Let's first build a model and save it as Parquet files
#'
#' # Create temp files to write files to
#' web_path <- tempfile()
#'
#' # Write as Parquet to temp files
#' web_fs <- arrow::write_dataset( web_metrics, web_path)
#'
#' # Open the files as Arrow datasets
#' web_ds <- arrow::open_dataset(web_path)
#'
#' # Define dimension columns
#' dimension_columns <- list(
#'   dim_channel = c("source", "medium", "campaign"),
#'   dim_market = c("view_name", "country")
#'   )
#'
#' # Set the path of the directory you want to write the dimensional model to
#' model_path <- file.path(tempfile(), "my-model")
#'
#' # Initiate the mode without loading into memory (using the dm_path argument)
#' dm <- dm_model(
#'   flat_table = web_ds,
#'   dimension_columns = dimension_columns,
#'   dm_path = model_path
#'   )
#'
#' # Populate with data
#' dm <- dm_refresh(
#'   dm = dm,
#'   new_fact_list = list(fct_web = web_ds),
#'   dm_path = model_path
#'   )
#'
#' # Check the files
#' list.files(model_path, recursive = TRUE)
#'
#' # Load the model when it's time to add new rows to dimension and fact tables
#' mymodel <- dm_load(model_path)
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
