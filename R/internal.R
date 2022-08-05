# Internal function
dm_check_dim_match <- function(dim, fact) {

  shared_cols <- intersect(names(fact), names(dim))
  no_shared_cols <- length(shared_cols) == 0
  not_unique <- any(duplicated(dim, by = shared_cols))

  return(no_shared_cols | not_unique)
}


dm_dim_refresh <- function(old_dim, new_fact) {

  setDT(old_dim)
  setDT(new_fact)

  # Useful variables
  fact_rows <- nrow(new_fact) # nrows for testing purpose
  key_name <- names(old_dim)[names(old_dim) %like% "_key"]
  shared_cols <- intersect(names(old_dim), names(new_fact))

  # Check if old_dim is unique with only shared_cols
  no_match <- dm_check_dim_match(old_dim, new_fact)

  if (no_match) stop(
    key_name, ", cannot be inserted into new_fact.\n",
    "Please ensure new_fact shares enough columns with old_dim to form a relation with its primary key.\n"
  )

  # Reconstruct old_dim (remove post-calculated cols)
  old_cols <- append(key_name, shared_cols)
  old_dim <- old_dim[, .SD, .SDcols = old_cols]

  # Define new dim
  new_fact[, (shared_cols) := lapply(.SD, as.character), .SDcols = shared_cols]
  dim <- unique(new_fact[, .SD, .SDcols = shared_cols])

  # Replace NAs with n/a in new dim
  dim[, (shared_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = shared_cols]
  new_fact[, (shared_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = shared_cols]

  # Delete dim rows that are already in old dim (drop if key is NA)
  dim <- merge(dim, old_dim, all.x = TRUE, by = intersect(names(dim), names(old_dim)))
  dim <- dim[is.na(get(key_name)), ]

  # Reorder cols
  data.table::setcolorder(dim, c(key_name, setdiff(names(dim), key_name)))

  if (nrow(dim) > 0) {

    message("There were ", nrow(dim), " new entries of ", key_name,
            ". Adding ", key_name, " to new fact...\n")

    # Make sure key col is double
    dim[, (key_name) := as.double(get(key_name))]
    old_dim[, (key_name) := as.double(get(key_name))]

    # Set surrogate key for new dim
    old_key_max <- max(old_dim[, get(key_name)])
    dim[, (key_name) := old_key_max + as.double((1:nrow(dim)))]

    # Combine new and old dim
    dim <- rbindlist(list(old_dim, dim), use.names = T)

    stopifnot(min(dim[,get(key_name)]) == 1)
    stopifnot(max(dim[,get(key_name)]) == nrow(dim))
    stopifnot(length(dim[,get(key_name)]) == nrow(dim))
    stopifnot(length(dim[,get(key_name)]) == nrow(dim[, -c(key_name), with = FALSE]))
    stopifnot(nrow(unique(old_dim[, -c(key_name), with = FALSE])) == nrow(unique(old_dim)))
    stopifnot(nrow(unique(dim[, -c(key_name), with = FALSE])) == nrow(unique(dim)))

    # Merge to add surrogate key to fact table
    new_fact <- merge(new_fact, dim, all.x = T, by = intersect(names(new_fact), names(dim)))

  } else {

    dim <- old_dim

    message("No new entries of ", key_name, ". Adding ", key_name, " to new fact...\n")

    # Make sure key is double
    dim[, (key_name) := as.double(get(key_name))]

    # Merge to add surrogate key
    merge_by_cols <- intersect(names(new_fact), names(dim))
    new_fact <- merge(new_fact, dim, all.x = T, by = merge_by_cols)

  }

  # Leave only surrogate key in fact table
  new_fact[, (shared_cols) := NULL]
  setcolorder(new_fact, c(key_name, setdiff(names(new_fact), key_name)))

  #new_fact[, get(key_name)]
  stopifnot( nrow(new_fact[is.na(get(key_name))]) == 0 )
  stopifnot( fact_rows == nrow(new_fact) )
  stopifnot( new_fact[, max(get(key_name))] <= dim[, max(get(key_name))])

  data.table::setDF(dim)
  data.table::setDF(new_fact)

  res <- list(dimension = dim, fact = new_fact)
  return(res)
}
