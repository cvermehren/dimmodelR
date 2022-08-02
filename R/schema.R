#' Empty model
#'
#' This is a description.
#'
#' @import data.table
#' @return A data frame
#' @export
#'
#' @examples
#'
#' dm_empty_model()

dm_empty_model <- function() {
  schema <- list(fact = NULL, dimension = NULL)
  structure(
    schema,
    class = "dimensional_model"
  )
}


#' Define dimension
#'
#' This is a description.
#'
#' @param dm A dim model object
#' @param name The name of the dimension
#' @param attributes The columns of the dimension
#'
#' @import data.table
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_define_dim(dm, name = "My_name")
#'
#'
#' }
dm_define_dim <- function(dm, name = NULL, attributes = NULL) {

  stopifnot(!is.null(name))
  stopifnot(!(name %in% names(dm$dimension)))
  stopifnot(length(attributes) > 0)
  stopifnot(length(attributes) == length(unique(attributes)))
  attributes_defined <- dm_get_attribute_names(dm)
  for (attribute in attributes) {
    stopifnot(!(attribute %in% attributes_defined))
  }

  if (is.null(dm$dimension)) {

    dm$dimension <- list(name = attributes)
    names(dm$dimension) <- name

  } else {

    dim_names <- names(dm$dimension)
    dm$dimension <- c(dm$dimension, list(name = attributes))
    names(dm$dimension) <- c(dim_names, name)

  }

  return(dm)
}

#' Define fact
#'
#' This is a description.
#'
#' @param dm A dim model object
#' @param name The name of the dimension
#' @param measures The columns of the dimension
#'
#' @import data.table
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_define_fact(dm, name = "My_name")
#'
#'
#' }
dm_define_fact <- function(dm, name = NULL, measures = NULL) {

  stopifnot(!is.null(name))
  stopifnot(length(c(measures)) == length(unique(c(measures))))

  attributes_defined <- dm_get_attribute_names(dm)

  for (measure in c(measures)) {stopifnot(!(measure %in% attributes_defined))}

  dm$fact <- list(name = name, measures = measures)

  return(dm)
}

#' Create schema
#'
#' This is a description.
#'
#' @param dm A dim model object
#' @param fact The name of the dimension
#'
#' @import data.table
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' dm_schema(dm, name = "My_name")
#'
#'
#' }
dm_schema <- function(dm, fact) {

  dimensions <- dm$dimension
  fact_name <- dm$fact$name
  dim_list <- list()

  setDT(fact)

  #i <- 1

  for (i in seq_along(dm$dimension)) {
    character_cols <- dm$dimension[[i]]
    fact[, (character_cols) := lapply(.SD, as.character), .SDcols = character_cols]
  }

  for(i in seq_along(dimensions)) {

    dim_name <- names(dimensions[i])
    dim_cols <- dimensions[i][[1]]
    key_name <- paste0(dim_name, "_key")

    dim <- data.table(unique(fact[, dim_cols, with = FALSE]))

    dim[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]
    fact[, (dim_cols) := replace(.SD, is.na(.SD), "n/a"), .SDcols = dim_cols]

    dim[, (key_name) := as.character(1:nrow(dim)) ]
    setcolorder(dim, c(key_name, setdiff(names(dim), key_name)))

    stopifnot(min(as.numeric(dim[[1]])) == 1)
    stopifnot(max(as.numeric(dim[[1]])) == nrow(dim))
    stopifnot(length(unique(dim[[1]])) == nrow(dim))

    dim_list[[names(dimensions[i])]] <- dim

    fact <- merge(fact, dim_list[[i]], all.x = T, all.y =  T, by = dim_cols)
    fact[, (dim_cols) := NULL]
  }

  res <- list(fact = fact, fact_name = fact_name, dimensions = dim_list)

  return(res)
}
