dm_model_create <- function(flat_table, dimension_columns) {

  stopifnot(is.data.frame(flat_table))
  stopifnot(is.list(dimension_columns))

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

    dim <- data.table(unique(flat_table[, dim_cols, with = FALSE]))

    dim[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]
    flat_table[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]

    dim[, (key_name) := as.character(1:nrow(dim)) ]
    setcolorder(dim, c(key_name, setdiff(names(dim), key_name)))

    stopifnot(min(as.numeric(dim[[1]])) == 1)
    stopifnot(max(as.numeric(dim[[1]])) == nrow(dim))
    stopifnot(length(unique(dim[[1]])) == nrow(dim))

    if(!exists("dim_list")) dim_list <- list()
    dim_list[[names(dimension_columns[i])]] <- dim

    flat_table <- merge(flat_table, dim_list[[i]], all.x = T, all.y =  T, by = dim_cols)
    flat_table[, (dim_cols) := NULL]
  }

  res <- list(fact = flat_table, dimensions = dim_list)

  return(res)

}
