
dm_get_attribute_names <- function(dm) {
  c(dm$fact$measures, unlist(dm$dimension, use.names=FALSE))
}
