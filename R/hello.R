#' Hello world
#'
#' @param dt data frame
#'
#' @import data.table
#' @return A print
#' @export
#'
#' @examples hello(iris)
hello <- function(dt) {
  data.table::setDT(dt)


  return(dt)
}
