#' Generate a dashboard design.
#'
#' This function automatically generates a dataframe describing the design of a dashboard for the given file or file summary,
#' including the input columns necessary and descriptions for each plot in the dashboard.
#' Useful for modifying designs and generating them with auto_plot.
#'
#' @param data The input data to design the dashboard from, can be either the path to a file (must be .csv or .xlsx) or a data frame. Not used if a summary is provided.
#' @param summary Optional summary dataframe of the input file. Should be generated using `himunge::make_df_summary`.
#' @param num_plots The number of plots in your dashboard. Default is 6.
#' @param custom_description An optional description to describe the custom dashboard you want.
#' @param dash_model The name of the language model to use for designing the dashboard, in the case of azure openai this is the deployment_id. Default 'gpt-4'.
#' @param temperature The temperature value for the language model designing the dashboard (does not affect code generation). Default is 0.1.
#' @param num_design_attempts The number of iterations to improve on the dashboard design. Default is 2.
#' @param max_cols The maximum number of columns the LLM can 'see'. If more columns are provided in the file they will be sorted and the columns with the least NA and most information will be selected. Default is 10.
#' @param filter_pk_cols Whether to filter out primary key columns, useful if you have a primary key like an id which you don't want plotted. Default is false.
#' @param save_messages Whether to save chat messages and responses for each dashboard generation step, useful for finetuning. Default is false.
#' @param save_dir The directory to save chat messages in.
#' @param save_name The name to save chat messages under (will be suffixed for each step). Default is "auto_dash".
#'
#' @return A dataframe consisting of the columns input_columns - a list of lists of the input columns necessary for each plot; descriptions - a list of descriptions of each plot; and usage_tokens - the total number prompt and completion tokens used.
#'
#' @export
auto_dash_design <- function(data, summary = NULL, num_plots = 6, custom_description="", dash_model="gpt-4", temperature=0.1, num_design_attempts=2, max_cols=10, filter_pk_cols=FALSE, save_messages=TRUE, save_dir="sullyplot_messages", save_name="auto_dash") {
  if(is.null(summary)) {
    input_df <- read_data(data)
    summary <- summarise_df(input_df, remove_cols = TRUE, max_cols = max_cols, filter_pk_cols=filter_pk_cols)
  }
  input_df <- summary$clean_df
  summary_df <- summary$df_stats
  using_azure <- is_azure_openai_configured()
  
  # Get GPT to design and describe the overall dashboard, use the custom description if available
  if(custom_description == "") {
    user_prompt <- sprintf(describe_dashboard_prompt, num_plots, to_csv(summary_df), mi_matrix(input_df), significant_categorical_relationships(input_df, summary_df), significant_categorical_numeric_relationships(input_df, summary_df))
  } else {
    user_prompt <- sprintf(describe_custom_dashboard_prompt, num_plots, custom_description, to_csv(summary_df))
  }
  log(user_prompt)
  chat_messages <- data.frame(role = "user", content = user_prompt)
  all_chat_messages <- chat_messages
  
  if(using_azure) {
    response <- sullyplot_azure_continue_chat(chat_messages, system_message = system_prompt, deployment_id = dash_model, max_tokens = 1024, options = list(temperature = temperature))
  } else {
    response <- sullyplot_openai_continue_chat(chat_messages, system_message = system_prompt, model_name = dash_model, max_tokens = 1024, options = list(temperature = temperature))
  }
  
  plot_info_json <- response$message
  total_usage_tokens <- response$usage_tokens
  all_chat_messages <- data.frame(role = c("user", "assistant"), content = c(user_prompt, plot_info_json))
  log("Initial dashboard design")
  log(plot_info_json)
  
  if (num_design_attempts > 0) {
    for(attempt_idx in 1:num_design_attempts) {
      improve_dashboard_message <- sprintf(improve_dashboard_prompt, num_plots, plot_info_json)
      chat_messages_new <- rbind(chat_messages, data.frame(role = "user", content = improve_dashboard_message))
      
      if(using_azure) {
        response <- sullyplot_azure_continue_chat(chat_messages_new, system_message = system_prompt, deployment_id = dash_model, max_tokens = 1024, options = list(temperature = temperature))
      } else {
        response <- sullyplot_openai_continue_chat(chat_messages_new, system_message = system_prompt, model_name = dash_model, max_tokens = 1024, options = list(temperature = temperature))
      }
      
      plot_info_json <- response$message
      total_usage_tokens <- mapply('+', total_usage_tokens, response$usage_tokens)
      all_chat_messages <- rbind(all_chat_messages, data.frame(role = c("user", "assistant"), content = c(improve_dashboard_message, plot_info_json)))
      log(sprintf("Improved dashboard design v%d", attempt_idx))
      log(plot_info_json)
    }
  }
  plot_info_df <- jsonlite::fromJSON(plot_info_json, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
  if(save_messages) {
    save_chat_messages(data.frame(role = c("system", "user", "assistant"), content = c(system_prompt, user_prompt, plot_info_json)), sprintf("%s/%s_dash.json", save_dir, save_name))
    save_chat_messages(all_chat_messages, sprintf("%s/%s_dash_all.json", save_dir, save_name))
  }
  return(list(plot_info_df = plot_info_df, usage_tokens = total_usage_tokens))
}