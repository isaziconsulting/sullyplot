#' Generate a dashboard of `ggplot` objects
#'
#' This function automatically generates a dashboard of `ggplot` objects from your input file.
#' It allows you to specify the number of plots and a custom description of your dashboard.
#'
#' @param data The input data to create a dashboard from, can be either the path to a file (must be .csv or .xlsx) or a data frame.
#' @param num_plots The number of plots in your dashboard. Default is 6.
#' @param custom_description An optional description to describe the custom dashboard you want.
#' @param dash_model The name of the language model to use for designing the dashboard. Default 'gpt-4'.
#' @param code_model The name of the language model to use for coding individual plots. Default 'gpt-4'.
#' @param temperature The temperature value for the language model designing the dashboard (does not affect code generation). Default is 0.1.
#' @param num_design_attempts The number of iterations to improve on the dashboard design. Default is 2.
#' @param num_code_attempts The maximum number of attempts to code your plot before failing - can take less if no errors are encountered in code generation. Default is 5.
#' @param max_cols The maximum number of columns the LLM can 'see'. If more columns are provided in the file they will be sorted and the columns with the least NA and most information will be selected. Default is 10.
#' @param filter_pk_cols Whether to filter out primary key columns, useful if you have a primary key like an id which you don't want plotted. Default is false.
#' @param save_messages Whether to save chat messages and responses for each dashboard generation step, useful for finetuning. Default is false.
#' @param save_dir The directory to save chat messages in.
#' @param save_name The name to save chat messages under (will be suffixed for each step). Default is "auto_dash".
#'
#' @return The list of `ggplot` objects representing the dashboard.
#'
#' @examples
#' \dontrun{
#' # Example usage of a custom dashboard with saving list of ggplots to a pdf
#' all_plots <- auto_dash("auto-dash/kaggle_data/train/iris.csv", num_design_attempts=1, save_messages=TRUE, save_dir="sullyplot_messages", save_name="iris_custom",
#' custom_description="Two box plots for lengths and widths (use two y axes per plot to show petal and sepal lengths/widths together), and 2 scatter plots of lengths vs widths. All should be grouped by variety.")
#' render_dash_pdf(all_plots, "my_dash.pdf")
#' }
#' 
#' @importFrom rlang .data
#' @export
auto_dash <- function(data, num_plots = 6, custom_description="", dash_model="gpt-4", code_model="gpt-4", temperature=0.1, num_design_attempts=2, num_code_attempts=5, max_cols=10, filter_pk_cols=FALSE, save_messages=TRUE, save_dir="sullyplot_messages", save_name="auto_dash") {
  input_df <- read_data(data)
  summary <- summarise_df(input_df, remove_cols = TRUE, max_cols = max_cols, filter_pk_cols=filter_pk_cols)
  input_df <- summary$clean_df
  design_params <- auto_dash_design(data=NULL, summary=summary, num_plots=num_plots, custom_description=custom_description, dash_model=dash_model, temperature=temperature, num_design_attempts=num_design_attempts,
                                max_cols=max_cols, filter_pk_cols=filter_pk_cols, save_messages=save_messages, save_dir=save_dir, save_name=save_name)
  plot_info_df <- design_params$plot_info_df
  log(sprintf("Dashboard design completed using %d prompt tokens and %d completion tokens", design_params$usage_tokens$prompt_tokens, design_params$usage_tokens$completion_tokens))
  
  # Start coding the dashboard
  all_plots <- lapply(seq_along(plot_info_df$input_columns), function(idx) {
    log(sprintf("\nGenerating plot %d using the columns: %s", idx, paste(plot_info_df$input_columns[[idx]], collapse = ", ")))
    tryCatch({
      auto_plot_results <- auto_plot(input_df, plot_info_df$input_columns[[idx]], plot_info_df$descriptions[[idx]], num_code_attempts, code_model, save_messages, save_dir, sprintf("%s_plot_%d", save_name, idx))
      log(sprintf("Plot %d completed using %d prompt tokens and %d completion tokens", idx, auto_plot_results$usage_tokens$prompt_tokens, auto_plot_results$usage_tokens$completion_tokens))
      return(auto_plot_results$plot_obj)
    }, error = function(e) {
      log(sprintf("Failed to generate plot %d: %s", idx, e$message))
      return(NULL)
    })
  })
  return(all_plots)
}