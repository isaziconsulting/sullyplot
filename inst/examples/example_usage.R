# Define the main function to auto-plot files from a specified directory
auto_plot_files <- function(directory = system.file("examples/example_data", package = "sullyplot"), save_messages = TRUE) {
  start_time <- Sys.time()

  # Ensure the output directory exists
  output_dir <- file.path(getwd(), "sullyplot_dashboards")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Message directory
  message_dir <- file.path(getwd(), "sullyplot_messages")
  if (save_messages && !dir.exists(message_dir)) {
    dir.create(message_dir, recursive = TRUE)
  }

  # List all CSV files in the directory
  files <- list.files(directory, pattern = "\\.csv$", full.names = TRUE)

  # Loop through the files and apply auto_plot
  for (file in files) {
    file_path <- file
    file_name <- tools::file_path_sans_ext(basename(file))
    cat(sprintf("\n************************* Auto_plotting file %s *************************\n", file_name))
  
    all_plots <- sullyplot::auto_dash(file_path, num_plots=4, num_design_attempts=1, num_code_attempts=5, save_messages=save_messages, save_dir=message_dir, save_name=file_name, code_model = "gpt-4", dash_model = "gpt-4")
    sullyplot::render_dash_pdf(all_plots, sprintf("%s/%s_dash.pdf", output_dir, file_name))
  }

  end_time <- Sys.time()
  execution_time <- end_time - start_time
  print(execution_time)
}

# Example function calls for auto plotting with custom dashboard or plot descriptions
auto_plot_custom_examples <- function() {
  example_data_dir <- system.file("examples/example_data", package = "sullyplot")
  output_dir <- file.path(getwd(), "sullyplot_dashboards")
  message_dir <- file.path(getwd(), "sullyplot_messages")

  # Ensure output and message directories exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  if (!dir.exists(message_dir)) {
    dir.create(message_dir, recursive = TRUE)
  }

  # Specific examples with custom dashboard descriptions
  files_to_plot <- c("cirrhosis.csv", "iris.csv")
  descriptions <- list(
    cirrhosis = "A dashboard of only bar plots",
    iris = "Two box plots for lengths and widths (use two y axes per plot to show petal and sepal lengths/widths together), and 2 scatter plots of lengths vs widths. All should be grouped by variety."
  )

  for (file_name in files_to_plot) {
    file_path <- file.path(example_data_dir, file_name)
    custom_description <- ifelse(file_name %in% names(descriptions), descriptions[[file_name]], "")

    cat(sprintf("\nGenerating custom dashboard for %s\n", file_name))

    # Generate the dashboard using the custom description
    all_plots <- sullyplot::auto_dash(file_path, num_design_attempts=1, save_messages=TRUE, save_dir=message_dir, save_name=tools::file_path_sans_ext(file_name), custom_description=custom_description)
    # Render the dashboard as both pdf and html
    sullyplot::render_dash_pdf(all_plots, file.path(output_dir, paste0(tools::file_path_sans_ext(file_name), "_dash_custom.pdf")))
    sullyplot::render_dash_html(all_plots, file.path(output_dir, paste0(tools::file_path_sans_ext(file_name), "_dash_custom.html")), display=TRUE)
  }

  # Example for a single plot
  file_path <- file.path(example_data_dir, "cirrhosis.csv")
  plot_results <- sullyplot::auto_plot(file_path, c("Status","Bilirubin"), "A box plot showing the distribution of Bilirubin levels for each Status category. The x-axis should be the Status category and the y-axis should be the Bilirubin levels. This plot will show if there are differences in Bilirubin levels across different Status categories.")
  ggplot2::ggsave(file.path(output_dir, "custom_plot.png"), plot = plot_results$plot_obj, width = 10, height = 8, dpi = 300)
}

# To run all examples
auto_plot_files() # Auto-plot dashboards for all files in example_data
auto_plot_custom_examples() # Run specific examples and a single plot example