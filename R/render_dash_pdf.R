#' Renders an interactive dashboard in html from a list of `ggplot` objects
#'
#' This function renders an interactive dashboard in html given a list of `ggplot` objects, which
#' can be created using `auto_dash`, `auto_plot`, or created separately from this package.
#'
#' @param all_plots The list of `ggplot` objects to render as an interactive dashboard.
#' @param filename The filename to save the pdf file under (must be .pdf).
#'
#' @return The html code for the interactive dashboard.
#'
#' @examples
#' \donttest{
#' # Example usage converting plots from `auto_dash` to a pdf dashboard
#' output_dir <- tempdir() # Define output directory for saving the dashboard
#' all_plots <- sullyplot::auto_dash(system.file("examples/iris.csv", package = "sullyplot"))
#' sullyplot::render_dash_pdf(all_plots, filename=file.path(output_dir, "my_dash.pdf"))
#' }
#'
#' @importFrom gridExtra grid.arrange
#' @export
render_dash_pdf <- function(all_plots, filename) {
  if(!grepl("\\.pdf$", filename)) {
    stop(sprintf("Filename (%s) is not a .pdf file", filename))
  }
  pdf(filename, width = 20, height = 10 * length(all_plots) / 2)
  do.call(grid.arrange, c(all_plots, ncol = 2))
  dev.off()
}