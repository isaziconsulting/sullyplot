render_dashboard <- function(all_plots, directory = file.path(getwd(), "dashboard")) {
  # Ensure the directory exists
  if (!dir.exists(directory)) {
    dir.create(directory, recursive = TRUE)
  }
  
  # Convert each ggplot to a standalone HTML ggplotly object
  html_files <- sapply(seq_along(all_plots), function(i) {
    p_ly <- ggplotly(all_plots[[i]])
    html_file <- file.path(directory, paste0("plot_", i, ".html"))
    saveWidget(widget = p_ly, selfcontained = TRUE, file = html_file)
    return(html_file)
  }, USE.NAMES = FALSE)
  
  # Construct the HTML dashboard with iframes for each plot
  iframes <- paste0(
    '<iframe src="', 
    basename(html_files), 
    '" style="width: 49%; height: 400px; border: none;"></iframe>', 
    collapse = ""
  )
  
  dashboard_html <- paste0(
    '<html><body>',
    '<div style="display: flex; flex-wrap: wrap;">', 
    iframes,
    '</div>',
    '</body></html>'
  )
  
  # Save the combined dashboard HTML
  dashboard_file <- file.path(directory, "dashboard.html")
  writeLines(dashboard_html, dashboard_file)
  
  cat("Dashboard created at:", dashboard_file, "\n")
  invisible(dashboard_file)
}