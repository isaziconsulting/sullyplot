#' Generate code and a `ggplot` object according to the described plot.
#'
#' This function automatically generates code and a `ggplot` object according to the described plot.
#'
#' @param file_df A dataframe which you want plotted.
#' @param plot_columns The list of names of columns in your dataframe which are relevant to the plot.
#' @param plot_description The description of the plot you want.
#' @param num_code_attempts The maximum number of attempts to code your plot before failing - can take less if no errors are encountered in code generation. Default is 5.
#' @param code_model The name of the language model to use for coding individual plots. Default 'gpt-4'.
#' @param save_messages Whether to save chat messages for the plotting code generation, useful for finetuning. Default is false.
#' @param save_dir The directory to save chat messages in.
#' @param save_name The name to save chat messages under. Default is "auto_plot".
#'
#' @return The list of `ggplot` objects representing the dashboard.
#'
#' @examples
#' \dontrun{
#' # Example usage with saving ggplots to a pdf
#' my_plot <- auto_plot(iris_df, ["variety", "sepal.length"],
#'  "A box plot of sepal length for each variety to show the distribution of sepal length within each variety.")
#' print(my_plot)
#' }
#' @export
auto_plot <- function(file_df, plot_columns, plot_description, num_code_attempts=5, code_model="gpt-4", save_messages=FALSE, save_dir="", save_name="auto_plot") {
  # Filter only the input columns that were chosen for this plot
  filtered_file_df <- filter_df(file_df, plot_columns)
  filtered_summary <- summarise_df(filtered_file_df, remove_cols=FALSE)
  filtered_summary_df <- filtered_summary$df_stats
  
  code_gen_prompt <- sprintf(generate_code_prompt, plot_description, to_csv(filtered_summary_df))
  log("First code gen prompt:")
  log(code_gen_prompt)
  
  # Make an initial attempt at coding the plot
  chat_messages <- data.frame(role = "user",  content = code_gen_prompt)
  code_string <- continue_chat(chat_messages, system_message = system_prompt, model_name = code_model, max_tokens = 512, options = list(temperature = 0))
  
  # Use a feedback loop to keep re-attempting to code the plot until either the plot is satisfactory or it runs out of attempts
  for(attempt_idx in 1:num_code_attempts) {
    attempt_results <- make_plot_attempt(code_string, file_df)
    if (attempt_results$success) {
      log(sprintf("Final code: \n%s\n", code_string))
      if(save_messages) {
        save_chat_messages(data.frame(role = c("system", "user", "assistant"), content = c(system_prompt, code_gen_prompt, code_string)), sprintf("%s/%s.json", save_dir, save_name))
      }
      return(list(code_string = code_string, plot_obj = attempt_results$plot_obj))
    } else if (attempt_idx < num_code_attempts) {
      log("Trying again with new prompt:")
      log(attempt_results$new_prompt)
      chat_messages <- data.frame(
        role = c("user", "user"),
        content = c(code_gen_prompt, attempt_results$new_prompt)
      )
      code_string <- continue_chat(chat_messages, system_message = system_prompt, model_name = code_model, max_tokens = 512, options = list(temperature = 0))
    } else if (!is.null(attempt_results$plot_obj)) {
      # If we're out of attempts but have a non-null plot object then use the plot object
      return(list(code_string = code_string, plot_obj = attempt_results$plot_obj))
    } else {
      stop("Ran out of attempts")
    }
  }
}