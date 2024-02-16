#' Renders an interactive dashboard in html from a list of `ggplot` objects
#'
#' This function renders an interactive dashboard in html given a list of `ggplot` objects, which
#' can be created using `auto_dash`, `auto_plot`, or created separately from this package.
#'
#' @param all_plots The list of `ggplot` objects to render as an interactive dashboard.
#' @param filename The filename to save the html file under (must be .html), no file is saved if null. Default is null.
#' @param display If true and a filename is specified opens up the dashboard html file in a separate browser page. Default is false
#'
#' @return The html code for the interactive dashboard.
#'
#' @examples
#' \donttest{
#'    # Example usage converting plots from `auto_dash` to a pdf dashboard
#'    output_dir <- tempdir() # Define output directory for saving the dashboard
#'    all_plots <- sullyplot::auto_dash(system.file("examples/example_data/iris.csv", package = "sullyplot"))
#'    sullyplot::render_dash_html(all_plots, filename=file.path(output_dir, "my_dash.html"), display=TRUE)
#'
#'    # Note: In actual use, replace tempdir() with a specific directory
#'    # and ensure the directory exists or is created before saving.
#' }
#'
#' @export
render_dash_html <- function(all_plots, filename=NULL, display=FALSE) {
  # Convert each ggplot to a plotly object and then to an iframe
  iframes <- lapply(all_plots, function(plot) {
    
    html_content <- render_plot_html(plot)
    
    # Create the iframe tag with the content of the temporary HTML file
    iframe <- htmltools::tags$iframe(
      srcdoc = html_content,
      width = "49%", height = "400px", frameborder = "0"
    )
    
    iframe
  })
  
  # Assemble the iframes into a flexbox div
  flex_div <- do.call(htmltools::tags$div, c(list(style = "display: flex; flex-wrap: wrap;"), iframes))
  
  # Wrap in a complete HTML document
  html_page <- htmltools::HTML(
    paste("<!DOCTYPE html><html><head><meta charset='utf-8'><title>Dashboard</title></head><body>",
          as.character(flex_div),
          "</body></html>")
  )
  
  if(!is.null(filename)) {
    if(!grepl("\\.html$", filename)) {
      stop(sprintf("Filename (%s) is not a .html file", filename))
    }
    # Write the HTML code to a file
    writeLines(html_page, filename)
    if(display) {
      # Open the file in the default browser
      browseURL(filename)
    }
  }
  
  # Return the complete HTML page
  html_page
}