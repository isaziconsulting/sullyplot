is_low_quality_plot <- function(plot_obj, data_point_threshold = 10,  min_bars_threshold = 2, max_bars_threshold = 1000, min_bins_threshold = 2, max_bins_threshold = 1000, axis_ticks_threshold = 30, legend_threshold = 20) {
  tryCatch({
    # Status is added to when there's errors that can be corrected together (e.g. too many ticks on x and y axis)
    low_quality_status <- list(status = FALSE, message = "")
    # Extract built data from the plot
    plot_build <- ggplot_build(plot_obj)
    plot_data <- plot_build$data[[1]]
    plot_layout <- plot_build$layout
    # Extract the scales from the plot build object
    scales <- plot_build$plot$scales$scales
    
    # Detect geoms used in the plot
    geoms_used <- sapply(plot_build$plot$layers, function(layer) class(layer$geom)[1])
    
    # Check num bars in bar charts
    if (any(geoms_used %in% c("GeomBar"))) {
      # Identify which data corresponds to the bar or histogram
      bar_data <- plot_build$data[[which(geoms_used %in% c("GeomBar"))]]
      
      # Check for the number of unique bins/bars
      num_bars <- length(unique(bar_data$x))
      if (num_bars < min_bars_threshold) {
        return(list(status = TRUE, message = sprintf("The bar chart has too few (%d) visible bars. Use box plots instead.", num_bars, min_bars_threshold)))
      }
      # Max bars only applies to bar charts (can have many histogram bins)
      else if (num_bars > max_bars_threshold) {
        return(list(status = TRUE, message = sprintf("The bar chart has too many (%d) visible bars. Either use a histogram with bins if the data is numeric, or otherwise select a subset of the %d most interesting categories.", num_bars, max_bars_threshold)))
      }
    }
    
    # Check num bins in histograms
    if (any(geoms_used %in% c("GeomHistogram"))) {
      # Identify which data corresponds to the bar or histogram
      hist_data <- plot_build$data[[which(geoms_used %in% c("GeomHistogram"))]]
      
      num_bins <- length(unique(hist_data$x))
      if (num_bins < min_bins_threshold) {
        return(list(status = TRUE, message = sprintf("The histogram has too few (%d) visible bins, decrease bin width to get at least %d bins.", num_bins, min_bins_threshold)))
      }
      else if (num_bins > max_bins_threshold) {
        return(list(status = TRUE, message = sprintf("The histogram has too many (%d) visible bins, increase bin width to get at most %d bins.", num_bins, max_bins_threshold)))
      }
    }
    
    # Check for too few data points, but skip for bar, box, or histogram plots
    if (!any(geoms_used %in% c("GeomBar", "GeomBoxplot", "GeomHistogram")) && nrow(unique(plot_data)) < data_point_threshold) {
      return(list(status = TRUE, message = "The plot has too few data points. Consider aggregating or using a different type of visualization."))
    }
    # Check for boxplots with minimal variation
    if ("GeomBoxplot" %in% geoms_used) {
      # Identify which data corresponds to the boxplot
      box_data <- plot_build$data[[which(geoms_used == "GeomBoxplot")]]
      if (all(box_data$ymax - box_data$ymin == 0)) {
        return(list(status = TRUE, message = "Box plots have no variation, indicating only one unique data point per category. Rather use a histogram with no categories to show the distribution."))
      }
    }
    
    # Check for potential text overlap due to too many axis ticks, for some reason always measures 1 extra
    num_x_ticks <- length(unique(plot_layout$panel_params[[1]]$x$breaks)) - 1
    num_y_ticks <- length(unique(plot_layout$panel_params[[1]]$y$breaks)) - 1
    if (!any(geoms_used %in% c("GeomBar", "GeomBoxplot", "GeomHistogram")) && num_x_ticks > axis_ticks_threshold) {
      low_quality_status$status = TRUE
      low_quality_status$message = paste(low_quality_status$message, sprintf("The plot has too many (%d) x-axis ticks which might cause text overlap.", num_x_ticks, axis_ticks_threshold - 5), collapse = "\n")
    }
    if (num_y_ticks > axis_ticks_threshold) {
      low_quality_status$status = TRUE
      low_quality_status$message = paste(low_quality_status$message, sprintf("The plot has too many (%d) y-axis ticks which might cause text overlap.", num_y_ticks, axis_ticks_threshold - 5), collapse = "\n")
    }
    
    # Check for overloaded legend
    # Iterate over the scales to check for legends with too many entries
    for(scale in scales) {
      # Check if the scale has a guide associated with it and it's not a continuous scale
      if(!is.null(scale$guide) && scale$is_discrete()) {
        # Check the number of breaks/values in the scale
        if(length(scale$get_breaks()) > legend_threshold) {
          low_quality_status$status = TRUE
          low_quality_status$message = paste(low_quality_status$message, sprintf("The plot has too many categories in the legend. If the column is numeric make the legend a continuous scale, otherwise if it is categorical select a subset of the %d most interesting categories.", legend_threshold), collapse = "\n")
          break
        }
      }
    }
    return(low_quality_status)
  }, error = function(e) {
    # log(sprintf("Low quality plot assessment failed: ", e$message))
    low_quality_status <- list(status = FALSE, message = "")
    return(low_quality_status)
  })
}