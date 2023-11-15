#' Generate a dashboard of `ggplot` objects
#'
#' This function automatically generates a dashboard of `ggplot` objects from your input file.
#' It allows you to specify the number of plots and a custom description of your dashboard.
#'
#' @param file_path The path to your input file. Must be .csv or .xlsx.
#' @param num_plots The number of plots in your dashboard. Default is 6.
#' @param custom_description An optional description to describe the custom dashboard you want.
#' @param dash_model The name of the language model to use for designing the dashboard. Default 'gpt-4'.
#' @param code_model The name of the language model to use for coding individual plots. Default 'gpt-4'.
#' @param temperature The temperature value for the language model designing the dashboard (does not affect code generation). Default is 0.1.
#' @param num_design_attempts The number of iterations to improve on the dashboard design. Default is 1.
#' @param num_code_attempts The maximum number of attempts to code your plot before failing - can take less if no errors are encountered in code generation. Default is 5.
#' @param max_cols The maximum number of columns the LLM can 'see'. If more columns are provided in the file they will be sorted and the columns with the least NA and most information will be selected. Default is 10.
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
auto_dash <- function(file_path, num_plots = 6, custom_description="", dash_model="gpt-4", code_model="gpt-4", temperature=0.1, num_design_attempts=1, num_code_attempts=5, max_cols=10, save_messages=FALSE, save_dir="", save_name="auto_dash") {
  file_df <- read_file(file_path)
  summary <- summarise_df(file_df, remove_cols = TRUE, max_cols = max_cols)
  file_df <- summary$clean_df
  summary_df <- summary$df_stats
  
  # Get GPT to design and describe the overall dashboard, use the custom description if available
  if(custom_description == "") {
    user_prompt <- sprintf(describe_dashboard_prompt, num_plots, to_csv(summary_df), mi_matrix(file_df), significant_categorical_relationships(file_df, summary_df), significant_categorical_numeric_relationships(file_df, summary_df))
  } else {
    user_prompt <- sprintf(describe_custom_dashboard_prompt, num_plots, custom_description, to_csv(summary_df))
  }
    # user_prompt <- sprintf(describe_dashboard_prompt, num_plots, to_csv(summary_df))
  log(user_prompt)
  chat_messages <- data.frame(role = "user", content = user_prompt)
  all_chat_messages <- chat_messages
  response_json <- continue_chat(chat_messages, system_message = system_prompt, model_name = dash_model, max_tokens = 768, options = list(temperature = temperature))
  all_chat_messages <- data.frame(role = c("user", "assistant"), content = c(user_prompt, response_json))
  
  log("Initial dashboard design")
  log(response_json)
  if (num_design_attempts > 0) {
    for(attempt_idx in 1:num_design_attempts) {
      log(sprintf("Improved dashboard design v%d", attempt_idx))
      improve_dashboard_message <- sprintf(improve_dashboard_prompt, num_plots, response_json)
      chat_messages_new <- rbind(chat_messages, data.frame(role = "user", content = improve_dashboard_message))
      response_json <- continue_chat(chat_messages_new, system_message = system_prompt, model_name = dash_model, max_tokens = 768, options = list(temperature = temperature))
      all_chat_messages <- rbind(all_chat_messages, data.frame(role = c("user", "assistant"), content = c(improve_dashboard_message, response_json)))
      log(response_json)
    }
  }
  plot_info <- jsonlite::fromJSON(response_json, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
  if(save_messages) {
    save_chat_messages(data.frame(role = c("system", "user", "assistant"), content = c(system_prompt, user_prompt, response_json)), sprintf("%s/%s_dash.json", save_dir, save_name))
    save_chat_messages(all_chat_messages, sprintf("%s/%s_dash_all.json", save_dir, save_name))
  }
  
  # Start coding the dashboard
  all_plots <- lapply(seq_along(plot_info$input_columns), function(idx) {
    log(sprintf("\nGenerating plot %d using the columns: %s", idx, paste(plot_info$input_columns[[idx]], collapse = ", ")))
    tryCatch({
      auto_plot_results <- auto_plot(file_df, plot_info$input_columns[[idx]], plot_info$descriptions[[idx]], num_code_attempts, code_model, save_messages, save_dir, sprintf("%s_plot_%d", save_name, idx))
      return(auto_plot_results$plot_obj)
    }, error = function(e) {
      log(sprintf("Failed to generate plot %d: ", idx, e$message))
      return(NULL)
    })
  })
  return(all_plots)
}