#' Quickly save a ggplot to a file
#'
#' @param plot A ggplot object
#' @param filename A character string of the file name
#' @param path A character string of the file path. By default, it is the working directory.
#' @inheritParams ggplot2::ggsave
#' @export
#'
#' @return NULL
#'
#' @examples
#' gg <- s_plot(mtcars, mpg, wt)
#' \dontrun{
#' s_ggsave(gg, "plot.png")
#' }
#'
#' # Alternatively, you can use the pipe operator
#' \dontrun{
#' mtcars %>%
#'   s_plot(mpg, wt) %>%
#'   s_ggsave("plot.png")
#' }
s_ggsave <- function(
    plot = ggplot2::last_plot(), filename,
    path = "wd", width = 7, height = 5,
    units = "in", dpi = 300, bg = "white") {
  if (length(path) > 1 && is.character(path)) {
    path <- path[1]
  }
  if (path == "wd") {
    path <- getwd()
  }

  if (!is.null(path)) {
    filename <- file.path(path, filename)
  } else {
    path <- dirname(filename)
  }

  ggplot2::ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    units = units,
    dpi = dpi,
    bg = bg
  )
}
