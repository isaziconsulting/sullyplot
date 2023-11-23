#' Renders an a `ggplot` object as an interactive html plot.
#'
#' This function renders a `ggplot` object as an interactive plotly-based html plot.
#'
#' @param plot The `ggplot` object to render as an interactive html plot.
#' @param filename The filename to save the html file under (must be .html), no file is saved if null. Default is null.
#' @param display If true and a filename is specified opens up the dashboard html file in a separate browser page. Default is false.
#' 
#' @return The html code for the interactive dashboard.
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