#' Create a dimensional model
#'
#' This is a description.
#'
#' @param flat_table The data frame from which the dimensional model should be
#'   created.
#' @param dimension_columns A named list with vectors of column names from
#'   `flat_table` each of which should form a dimension table.
#' @param dm A `dm_model` object, i.e. an object returned by `dm_model_create`
#'   or `dm_model_refresh`.
#' @param return_facts Should facts be returned?
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
#' dm_model_create(flat_table, dimension_columns)
#'
#'
#' }
dm_model_create <- function(flat_table,
                            dimension_columns,
                            dm = NULL,
                            return_facts = FALSE) {

  if(!is.data.frame(flat_table)) stop(
    "flat_table must be a data.frame!\n"
  )

  if(!is.list(dimension_columns)) stop(
    "dimension_columns must be a list object!\n"
  )

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
    `dm_model_create` or `dm_model_refresh`.\n"
    )

  data.table::setDT(flat_table)

  # Take sample of flat_table unless it should be returned
  if(!return_facts) flat_table <- flat_table[1:500]

  flat_cols <- names(flat_table)

  # Make all dimension columns character
  for (i in seq_along(dimension_columns)) {

    character_cols <- dimension_columns[[i]]

    if(!all(character_cols %in% flat_cols)) stop(
      "dimension_columns must be columns of `flat_table`!\n"
      )

    flat_table[, (character_cols) := lapply(.SD, as.character), .SDcols = character_cols]
  }

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

    # Add dim to dim_list
    if(!exists("dim_list")) dim_list <- list()
    dim_list[[names(dimension_columns[i])]] <- dim

    # Add key to fact via merge & remove dims
    flat_table <- merge(flat_table, dim_list[[i]], all.x = T, all.y =  T, by = dim_cols)
    flat_table[, (dim_cols) := NULL]

    # Reorder columns & set to df
    data.table::setcolorder(
      flat_table,
      c(key_name, setdiff(names(flat_table), key_name))
      )

    data.table::setDF(dim)

  }

  data.table::setDF(flat_table)

  if(!is.null(dm)) {

    for(i in seq_along(dim_list)) {
      name <- names(dim_list)[i]
      dm$dimensions[[name]] <- dim_list[[i]]
      }

  } else {

    dm <- structure(list(dimensions = dim_list), class = "dm_model")

    }

  if(return_facts) dm$fact <- flat_table

  return(dm)

}
