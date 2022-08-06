#' Refresh a dimension
#'
#' This is a description.
#'
#' @param dm A model object
#' @param new_fact A fact table
#' @param fact_name The name of the fact table
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
dm_refresh_one_fact <- function(dm, new_fact, fact_name) {

  if(!is.null(dm) & !inherits(dm, "dm_model")) stop(
    "dm must be a `dm_model` object, i.e. an object returned by
    `dm_model_create` or `dm_refresh_one_fact`.\n"
  )


  has_fct_prefix <- startsWith(fact_name, "fct_")

  if(!has_fct_prefix) stop(
    "The name of fact tables (passed to `fact_name`) must start with 'fct_'.\n"
  )

  dimension_names <- names(dm$dimensions)

  dim_ls <- list()

  for (i in seq_along(dm$dimensions)) {

    old_dim <- dm$dimensions[[i]]

    # Check if old_dim is unique with only shared_cols
    no_match <- dm_check_dim_match(old_dim, new_fact)

    if (no_match) {

      message(dimension_names[i], " does not match new_fact; skipping the dimension...\n")

      next

      }

    # Refresh using the internal function
    refreshed_schema <- dm_dim_refresh(old_dim = dm$dimensions[[i]], new_fact = new_fact)

    # Add refreshed dim to empty list
    dim_ls[[dimension_names[i]]] <- refreshed_schema$dimension

    # Overwrite new_fact to use this in next iteration
    new_fact <- refreshed_schema$fact

  }

  if(!is.null(dm)) {

    dm$fact <- NULL

    for(i in seq_along(dim_ls)) {
      name <- names(dim_ls)[i]
      dm$dimensions[[name]] <- dim_ls[[i]]
    }

  } else {

    dm <- structure(
      list(dimensions = dim_ls),
      class = "dm_model"
      )
  }

  dm$fact_tables[[fact_name]] <- new_fact

  return(dm)
}


dm_refresh <- function(dm, new_fact_list) {

  fact_names <- names(new_fact_list)

  for (i in seq_along(new_fact_list)) {

    dm <- dm_refresh_one_fact(
      dm,
      new_fact_list[[i]],
      fact_name = fact_names[i])
  }

  return(dm)
}





# dm_refresh_model <- function(dimensions, dimension_names, new_fact) {
#
#   dim_ls <- list()
#
#   for (i in seq_along(dimensions)) {
#
#     refreshed_schema <- dm_dim_refresh(old_dim = dimensions[[i]], new_fact = new_fact)
#     dim_ls[[dimension_names[i]]] <- refreshed_schema$dimension
#     new_fact <- refreshed_schema$fact
#
#   }
#
#   res <- list(dimensions = dim_ls, fact = new_fact)
#   return(res)
# }
