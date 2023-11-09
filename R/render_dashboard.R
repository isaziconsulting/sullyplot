#' Renders an interactive dashboard from a list of `ggplot` objects
#'
#' This function renders an interactive dashboard given a list of `ggplot` objects, which
#' can be created using `auto_dash`, `auto_plot`, or created separately from this package.
#'
#' @param all_plots The list of `ggplot` objects to render as an interactive dashboard.
#' @param display If true opens up the dashboard in a separate browser page. Default is false.
#' 
#' @return The html code for the interactive dashboard.
#'
#' @examples
#' \dontrun{
#' # Example usage converting plots from `auto_dash` to an interactive dashboard
#' all_plots <- auto_dash("iris.csv")
#' html_code <- render_dashboard(all_plots, display=TRUE)
#' }
#' 
#' @export
render_dashboard <- function(all_plots, display=FALSE) {
  # Convert each ggplot to a plotly object and then to an iframe
  iframes <- lapply(all_plots, function(plot) {
    p_ly <- ggplotly(plot)
    # Create a temporary file to save the HTML content
    tmpfile <- tempfile(fileext = ".html")
    htmlwidgets::saveWidget(p_ly, file = tmpfile, selfcontained = TRUE)
    
    # Create the iframe tag with the content of the temporary HTML file
    iframe <- tags$iframe(
      srcdoc = paste(readLines(tmpfile), collapse = "\n"),
      width = "49%", height = "400px", frameborder = "0"
    )
    
    # Remove the temporary file
    unlink(tmpfile)
    iframe
  })
  
  # Assemble the iframes into a flexbox div
  flex_div <- do.call(tags$div, c(list(style = "display: flex; flex-wrap: wrap;"), iframes))
  
  # Wrap in a complete HTML document
  html_page <- HTML(
    paste("<!DOCTYPE html><html><head><meta charset='utf-8'><title>Dashboard</title></head><body>",
          as.character(flex_div),
          "</body></html>")
  )
  
  if(display) {
    # Write the HTML code to a file
    writeLines(html_page, "plot_dashboard.html")
    # Open the file in the default browser
    browseURL("plot_dashboard.html")
  }
  
  # Return the complete HTML page
  html_page
}