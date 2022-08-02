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

  # Calculates new_fact rows for test purposes
  fact_rows <- nrow(new_fact)

  # Reconstruct old_dim (if dim has calculated cols)
  fact_cols <- names(new_fact)
  dim_cols <- names(old_dim)[!names(old_dim) %like% "_key"]
  dim_cols <- dim_cols[dim_cols %in% fact_cols]
  new_fact[, (dim_cols) := lapply(.SD, as.character), .SDcols = dim_cols]

  key_name <- names(old_dim)[names(old_dim) %like% "key"]

  old_cols <- append(key_name, dim_cols)
  old_dim <- old_dim[, old_cols, with = FALSE]

  # Define new dim
  dim <- unique(new_fact[, dim_cols, with = FALSE])

  dim[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]
  new_fact[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]

  # Delete dim rows that are already in old dim
  dim <- merge( dim, old_dim, all.x = TRUE, by = intersect(names(dim), names(old_dim)))

  setcolorder(dim, c(key_name, setdiff(names(dim), key_name)))

  dim <- dim[is.na(dim[[1]]), ]


  if (nrow(dim) > 0) {

    # Set surrogate key for new dim
    dim[, 1] <- as.numeric(dim[[1]])
    old_dim[, 1] <- as.numeric(old_dim[[1]])

    dim[, 1] <- max(old_dim[, 1]) + (1:nrow(dim))

    dim[, 1] <- as.character(dim[[1]])

    # Combine new and old dim
    old_dim[, 1] <- as.character(old_dim[[1]])

    dim <- rbindlist(list(old_dim, dim), use.names = T)

    stopifnot(min(as.numeric(dim[[1]])) == 1)
    stopifnot(max(as.numeric(dim[[1]])) == nrow(dim))
    stopifnot(length(unique(dim[[1]])) == nrow(dim))
    stopifnot(length(unique(dim[[1]])) == nrow(dim[, -c(key_name), with = FALSE]))
    stopifnot(nrow(unique(old_dim[, -c(key_name), with = FALSE])) == nrow(unique(old_dim)))
    stopifnot(nrow(unique(dim[, -c(key_name), with = FALSE])) == nrow(unique(dim)))

    # Merge to add surrogate key to fact table
    new_fact <- merge(new_fact, dim, all.x = T, by = intersect(names(new_fact), names(dim)))

    # names(new_fact)
    # names(dim)
    # intersect(names(new_fact), names(dim))

  } else {

    # This is only for testing later:
    # stopifnot( max(as.numeric(new_fact[[1]])) <= max(as.numeric(dim[[1]])) )
    dim <- old_dim
    dim[, 1] <- as.character(dim[[1]])

    new_fact <- merge(new_fact, old_dim, all.x = T, by = intersect(names(new_fact), names(old_dim)))

  }

  # Leave only surrogate key in fact table
  new_fact[, (dim_cols) := NULL]
  setcolorder(new_fact, c(key_name, setdiff(names(new_fact), key_name)))

  if(sum(is.na(new_fact[[1]])) > 0) {print(paste("No new entries for", key_name))}

  stopifnot( sum(is.na(new_fact[[1]])) == 0 )
  stopifnot( fact_rows == nrow(new_fact) )
  stopifnot( max(as.numeric(new_fact[[1]])) <= max(as.numeric(dim[[1]])) )

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


dm_refresh_model <- function(dimensions, dimension_names, new_fact) {

  # dimensions must be a list of old dimensions (e.g. from dm_schema())
  # dimension_names must be a vector of names(dimensions)

  dim_ls <- list()

  for (i in seq_along(dimensions)) {

    # Skip dims that are not in the fact table
    new_fact_cols <- names(new_fact)
    dim_cols <- names(dimensions[[i]])
    dim_is_not_in_fact <- length(intersect(new_fact_cols, dim_cols)) == 0
    if (dim_is_not_in_fact) { next }

    # Refresh using the internal function
    refreshed_schema <- dm_refresh_dim(old_dim = dimensions[[i]], new_fact = new_fact)

    # Add refreshed dim to empty list
    dim_ls[[dimension_names[i]]] <- refreshed_schema$dimension

    # Overwrite new_fact to use this in next iteration
    new_fact <- refreshed_schema$fact

  }

  res <- list(dimensions = dim_ls, fact = new_fact)
  return(res)
}
