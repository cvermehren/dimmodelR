#' Refresh a dimension
#'
#' This is a description.
#'
#' @param dim_list a list of old dimensions (e.g. from dm_model_create())
#' @param new_fact A fact table
#' @param dm A model object
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
dm_model_refresh <- function(dim_list, new_fact, dm = NULL, fact_name = NULL) {

  has_fct_prefix <- startsWith(fact_name, "fct_")

  if(!has_fct_prefix) stop(
    "The name of fact tables (passed to `fact_name`) must start with 'fct_'.\n"
  )

  dimension_names <- names(dim_list)

  dim_ls <- list()

  for (i in seq_along(dim_list)) {

    old_dim <- dim_list[[i]]

    # Check if old_dim is unique with only shared_cols
    no_match <- dm_check_dim_match(old_dim, new_fact)

    #if (no_shared_cols | not_unique)

    if (no_match) {

      message(dimension_names[i], " does not match new_fact; skipping the dimension...\n")

      next

      }

    # Refresh using the internal function
    refreshed_schema <- dm_dim_refresh(old_dim = dim_list[[i]], new_fact = new_fact)

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

  if(is.null(fact_name)) {

    dm$fact <- new_fact

    } else {

      dm$fact_tables[[fact_name]] <- new_fact

      }

  # res <- list(dim_list = dim_ls, fact = new_fact)
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
