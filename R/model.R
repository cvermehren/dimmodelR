# fact=new_fact
# dim=old_dim

# Internal function
dm_check_dim_match <- function(dim, fact) {

  shared_cols <- intersect(names(fact), names(dim))
  no_shared_cols <- length(shared_cols) == 0
  not_unique <- any(duplicated(dim, by = shared_cols))

  return(no_shared_cols | not_unique)
}


dm_model_create <- function(flat_table,
                            dimension_columns,
                            dm = NULL) {

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

  #i=1
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
    data.table::setcolorder(flat_table, c(key_name, setdiff(names(flat_table), key_name)))
    data.table::setDF(dim)

  }

  data.table::setDF(flat_table)

  if(!is.null(dm)) {

    for(i in seq_along(dim_list)) {
      name <- names(dim_list)[i]
      dm$dimensions[[name]] <- dim_list[[i]]
    }

    dm$fact <- flat_table

  } else {

    dm <- structure(
      list(
        dimensions = dim_list,
        fact = NULL
        ),
      class = "dm_dimension_model"
      )

    dm$fact <- flat_table

  }

  return(dm)

}
