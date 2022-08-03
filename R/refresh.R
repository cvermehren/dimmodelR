#' Refresh a dimension
#'
#' This is a description.
#'
#' @param old_dim A dimension
#' @param new_fact A fact table
#'
#' @import data.table
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_refresh(old_dim, new_fact)
#'
#'
#' }
dm_refresh_dim <- function(old_dim, new_fact) {

  setDT(old_dim)
  setDT(new_fact)

  # Useful variables
  fact_rows <- nrow(new_fact) # nrows for testing purpose
  key_name <- names(old_dim)[names(old_dim) %like% "_key"]
  shared_cols <- intersect(names(old_dim), names(new_fact))

  # Check if old_dim is unique with only shared_cols
  old_dim_shared <- unique(old_dim[, shared_cols, with = FALSE])
  is_unique <- nrow(old_dim_shared) == nrow(old_dim)

  if(!is_unique) stop(
    "The dimension key, ", key_name, ", cannot be inserted into new_fact.\n",
    "  Please ensure new_fact shares enough columns with old_dim to form a unique key."
    )

  # Reconstruct old_dim (remove post-calculated cols)
  old_cols <- append(key_name, shared_cols)
  old_dim <- old_dim[, old_cols, with = FALSE]

  # Define new dim
  new_fact[, (shared_cols) := lapply(.SD, as.character), .SDcols = shared_cols]
  dim <- unique(new_fact[, shared_cols, with = FALSE])

  # Replace NAs with n/a in new dim
  dim[, (shared_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = shared_cols]
  new_fact[, (shared_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = shared_cols]

  # Delete dim rows that are already in old dim (drop if key is NA)
  dim <- merge(dim, old_dim, all.x = TRUE, by = intersect(names(dim), names(old_dim)))
  dim <- dim[is.na(get(key_name)), ]

  # Reorder cols
  data.table::setcolorder(dim, c(key_name, setdiff(names(dim), key_name)))

  if (nrow(dim) > 0) {

    message("There were ", nrow(dim), " new entries of ", key_name, ".\n",
            "Adding ", key_name, " to new fact...\n")

    # Make sure key col is double
    dim[, (key_name) := as.double(get(key_name))]
    old_dim[, (key_name) := as.double(get(key_name))]

    # Set surrogate key for new dim
    old_key_max <- max(old_dim[, get(key_name)])
    dim[, (key_name) := old_key_max + as.double((1:nrow(dim)))]

    # Combine new and old dim
    dim <- rbindlist(list(old_dim, dim), use.names = T)

    stopifnot(min(as.numeric(dim[[1]])) == 1)
    stopifnot(max(as.numeric(dim[[1]])) == nrow(dim))
    stopifnot(length(unique(dim[[1]])) == nrow(dim))
    stopifnot(length(unique(dim[[1]])) == nrow(dim[, -c(key_name), with = FALSE]))
    stopifnot(nrow(unique(old_dim[, -c(key_name), with = FALSE])) == nrow(unique(old_dim)))
    stopifnot(nrow(unique(dim[, -c(key_name), with = FALSE])) == nrow(unique(dim)))

    # Merge to add surrogate key to fact table
    new_fact <- merge(new_fact, dim, all.x = T, by = intersect(names(new_fact), names(dim)))

  } else {

    dim <- old_dim

    message("No new entries of ", key_name, ".\n", "Adding ", key_name, " to new fact...\n")

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


# dm_refresh_model <- function(dimensions, dimension_names, new_fact) {
#
#   dim_ls <- list()
#
#   for (i in seq_along(dimensions)) {
#
#     refreshed_schema <- dm_refresh_dim(old_dim = dimensions[[i]], new_fact = new_fact)
#     dim_ls[[dimension_names[i]]] <- refreshed_schema$dimension
#     new_fact <- refreshed_schema$fact
#
#   }
#
#   res <- list(dimensions = dim_ls, fact = new_fact)
#   return(res)
# }


dm_refresh_model <- function(dim_list, new_fact) {

  # dim_list must be a list of old dimensions (e.g. from dm_model_create())
  # dimension_names must be a vector of names(dim_list)

  dimension_names <- names(dim_list)

  dim_ls <- list()

  #i=1

  for (i in seq_along(dim_list)) {

    # Skip dims that are not in the fact table
    new_fact_cols <- names(new_fact)
    dim_cols <- names(dim_list[[i]])
    dim_is_not_in_fact <- length(intersect(new_fact_cols, dim_cols)) == 0

    if (dim_is_not_in_fact) { next }

    # Refresh using the internal function
    refreshed_schema <- dm_refresh_dim(old_dim = dim_list[[i]], new_fact = new_fact)

    # Add refreshed dim to empty list
    dim_ls[[dimension_names[i]]] <- refreshed_schema$dimension

    # Overwrite new_fact to use this in next iteration
    new_fact <- refreshed_schema$fact

  }

  res <- list(dim_list = dim_ls, fact = new_fact)
  return(res)
}
