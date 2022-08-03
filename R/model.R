dm_model_create <- function(flat_table, dimension_columns) {

  stopifnot(is.data.frame(flat_table))
  stopifnot(is.list(dimension_columns))

  data.table::setDT(flat_table)

  flat_cols <- names(flat_table)

  # Make all dimension columns character
  for (i in seq_along(dimension_columns)) {

    character_cols <- dimension_columns[[i]]

    if(!all(character_cols %in% flat_cols)) stop("dimension_columns must be columns of flat_table")

    flat_table[, (character_cols) := lapply(.SD, as.character), .SDcols = character_cols]
  }

  #i=2
  for(i in seq_along(dimension_columns)) {

    dim_name <- names(dimension_columns[i])
    dim_cols <- dimension_columns[i][[1]]

    key_name <- paste0(dim_name, "_key")
    key_name <- gsub("^dim_", "", key_name)

    dim <- unique(flat_table[, dim_cols, with = FALSE])

    # Replace NAs with "n/a"
    dim[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]
    flat_table[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]

    # Insert surrogate key
    dim[, (key_name) := as.double(1:nrow(dim)) ]

    # Reorcer columns
    setcolorder(dim, c(key_name, setdiff(names(dim), key_name)))

    stopifnot(min(dim[[1]]) == 1)
    stopifnot(max(dim[[1]]) == nrow(dim))
    stopifnot(length(unique(dim[[1]])) == nrow(dim))

    # Add dim to dim_list
    if(!exists("dim_list")) dim_list <- list()
    dim_list[[names(dimension_columns[i])]] <- dim

    # Add key to fact via merge & remove dims
    flat_table <- merge(flat_table, dim_list[[i]], all.x = T, all.y =  T, by = dim_cols)
    flat_table[, (dim_cols) := NULL]

    # Reorder columns & set to df
    data.table::setcolorder(flat_table, c(key_name, setdiff(names(flat_table), key_name)))
    data.table::setDF(dim)

  }

  data.table::setDF(flat_table)

  res <- list(fact = flat_table, dimensions = dim_list)

  return(res)

}
