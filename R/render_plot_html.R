#' Renders an a `ggplot` object as an interactive html plot.
#'
#' This function renders a `ggplot` object as an interactive plotly-based html plot
#' with the option to save and display it.
#'
#' @param plot The `ggplot` object to render as an interactive html plot.
#' @param filename The filename to save the html file under (must be .html), no file is saved if null. Default is null.
#' @param display If true and a filename is specified opens up the dashboard html file in a separate browser page. Default is false.
#'
#' @return The html code for the interactive dashboard.
#'
#' @examples
#' \dontrun{
#'   # Create an example plot with the mtcars dataset
#'   library(ggplot2)
#'   example_plot <- ggplot(mtcars, aes(x=wt, y=mpg)) +
#'     geom_point() +
#'     theme_minimal() +
#'     ggtitle("MPG vs. Weight")
#'
#'   # Specify an output directory (adjust path as needed)
#'   output_dir <- tempdir() # Using tempdir() for example purposes
#'
#'   # Render and optionally display the plot as HTML
#'   sullyplot::render_plot_html(example_plot, file.path(output_dir, "custom_plot.html"), display=TRUE)
#'
#'   # Note: In actual use, replace tempdir() with a specific directory
#'   # and ensure the directory exists or is created before saving.
#' }
#'
#' @export
render_plot_html <- function(plot, filename=NULL, display=FALSE) {
  # Convert the ggplot to a plotly object and then to html
  p_ly <- plotly::ggplotly(plot)
  # Partial bundle for smaller file and faster rendering
  p_ly <- plotly::partial_bundle(p_ly)
  if(is.null(filename)) {
    # Create a temporary file to save the HTML content
    tmpfile <- tempfile(fileext = ".html")
    htmlwidgets::saveWidget(p_ly, file = tmpfile)
    html_content <- paste(readLines(tmpfile), collapse = "\n")
    unlink(tmpfile)
  } else {
    # Use the specified file to save the HTML content
    if(!grepl("\\.html$", filename)) {
      stop(sprintf("Filename (%s) is not a .html file", filename))
    }
    htmlwidgets::saveWidget(p_ly, file = filename)
    html_content <- paste(readLines(filename), collapse = "\n")
    if(display) {
      # Open the file in the default browser
      browseURL(filename)
    }
  }
  html_content
}