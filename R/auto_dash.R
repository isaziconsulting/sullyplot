#' Generate a dashboard of `ggplot` objects
#'
#' This function automatically generates a dashboard of `ggplot` objects from your input file.
#' It allows you to specify the number of plots and a custom description of your dashboard.
#'
#' @param file_path The path to your input file. Must be .csv or .xlsx.
#' @param num_plots The number of plots in your dashboard. Default is 4.
#' @param dash_model The name of the language model to use for designing the dashboard. Default 'gpt-4'.
#' @param code_model The name of the language model to use for coding individual plots. Default 'gpt-4'.
#' @param num_design_attempts The number of iterations to improve on the dashboard design. Default is 1.
#' @param num_code_attempts The maximum number of attempts to code your plot before failing - can take less if no errors are encountered in code generation. Default is 5.
#'
#' @return The list of `ggplot` objects representing the dashboard.
#'
#' @examples
#' \dontrun{
#' # Example usage with saving ggplots to a pdf
#' all_plots <- auto_dash("iris.csv")
#' pdf("my_dash.pdf", width = 20, height = 10 * length(all_plots) / 2)
#' do.call(grid.arrange, c(all_plots, ncol = 2))
#' dev.off()
#' }
#' 
#' @importFrom rlang .data
#' @export
auto_dash <- function(file_path, num_plots = 4, dash_model="gpt-4", code_model="gpt-4", num_design_attempts=1, num_code_attempts=5) {
  file_df <- read_file(file_path)
  summary <- summarise_df(file_df, remove_cols = TRUE, max_cols = max_cols)
  file_df <- summary$clean_df
  summary_df <- summary$df_stats
  
  # Get GPT to design and describe the overall dashboard
  user_prompt <- sprintf(describe_dashboard_prompt, num_plots, to_csv(summary_df), mi_matrix(file_df), significant_categorical_relationships(file_df, summary_df), significant_categorical_numeric_relationships(file_df, summary_df))
  # user_prompt <- sprintf(describe_dashboard_prompt, num_plots, to_csv(summary_df))
  log(user_prompt)
  chat_messages <- data.frame(role = "user", content = user_prompt)
  response_json <- continue_chat(chat_messages, system_message = system_prompt, model_name = dash_model, max_tokens = 768, options = list(temperature = 0))
  log("Initial dashboard design")
  log(response_json)
  for(attempt_idx in 1:num_design_attempts) {
    log(sprintf("Improved dashboard design v%d", attempt_idx))
    chat_messages_new <- rbind(chat_messages, data.frame(role = "user", content = sprintf(improve_dashboard_prompt, response_json)))
    response_json <- continue_chat(chat_messages_new, system_message = system_prompt, model_name = dash_model, max_tokens = 768, options = list(temperature = 0))
    log(response_json)
  }
  plot_info <- fromJSON(response_json, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
  
  # Start coding the dashboard
  all_plots <- lapply(seq_len(num_plots), function(idx) {
    auto_plot_results <- auto_plot(file_df, plot_info$input_columns[[idx]], plot_info$descriptions[[idx]], num_code_attempts, code_model)
    return(auto_plot_results$plot_obj)
  })
  return(all_plots)
}