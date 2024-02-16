#' Generate code and a `ggplot` object according to the described plot.
#'
#' This function automatically generates code and a `ggplot` object according to the described plot.
#'
#' @param data The input data to plot, can be either the path to a file (must be .csv or .xlsx) or a data frame.
#' @param plot_columns The list of names of columns in your dataframe which are relevant to the plot.
#' @param plot_description The description of the plot you want.
#' @param num_code_attempts The maximum number of attempts to code your plot before failing - can take less if no errors are encountered in code generation. Default is 5.
#' @param code_model The name of the language model to use for coding individual plots, in the case of azure openai this is the deployment_id. Default 'gpt-4'.
#' @param save_messages Whether to save chat messages for the plotting code generation, useful for finetuning. Default is false.
#' @param save_dir The directory to save chat messages in.
#' @param save_name The name to save chat messages under. Default is "auto_plot".
#'
#' @return The code string that was run to generate the plot, the corresponding `ggplot` object, and the total tokens used.
#'
#' @examples
#' \dontrun{
#'    # Generating a box plot for Bilirubin levels by Status
#'    output_dir <- tempdir() # Define output directory for saving the plot
#'    plot_results <- sullyplot::auto_plot(
#'      system.file("examples/cirrhosis.csv", package="sullyplot"),
#'      c("Status", "Bilirubin"),
#'      "A box plot showing the distribution of Bilirubin levels for each Status category. The x-axis should be the Status category and the y-axis should be the Bilirubin levels. This plot will show if there are differences in Bilirubin levels across different Status categories.",
#'      num_code_attempts=5,
#'      code_model="gpt-4"
#'    )
#'    # Save the generated plot
#'    ggplot2::ggsave(file.path(output_dir, "cirrhosis_bilirubin_status_plot.png"), plot = plot_results$plot_obj, width = 10, height = 8, dpi = 300)
#'
#'    # Note: In actual use, replace tempdir() with a specific directory
#'    # and ensure the directory exists or is created before saving.
#' }
#'
#'
#' @export
auto_plot <- function(data, plot_columns, plot_description, num_code_attempts=5, code_model="gpt-4", save_messages=FALSE, save_dir="", save_name="auto_plot") {
  temperature <- 0
  input_df <- read_data(data)
  using_azure <- is_azure_openai_configured()

  # Filter only the input columns that were chosen for this plot
  filtered_input_df <- filter_df(input_df, plot_columns)
  filtered_summary <- summarise_df(filtered_input_df, remove_cols=FALSE)
  filtered_summary_df <- filtered_summary$df_stats
  input_df <- filtered_summary$clean_df

  code_gen_prompt <- sprintf(generate_code_prompt, plot_description, to_csv(filtered_summary_df))
  log(sprintf("Attempting to plot:\n%s", plot_description))
  chat_messages <- data.frame(role = "user",  content = code_gen_prompt)
  all_chat_messages <- chat_messages

  # Make an initial attempt at coding the plot
  if(using_azure) {
    response <- sullyplot_azure_continue_chat(chat_messages, system_message = system_prompt, deployment_id = code_model, max_tokens = 512, options = list(temperature = temperature))
  } else {
    response <- sullyplot_openai_continue_chat(chat_messages, system_message = system_prompt, model_name = code_model, max_tokens = 512, options = list(temperature = temperature))
  }

  code_string <- response$message
  log(sprintf("First code attempt:\n%s", code_string))
  total_usage_tokens <- response$usage_tokens
  all_chat_messages <- data.frame(role = c("user", "assistant"), content = c(code_gen_prompt, code_string))

  # Use a feedback loop to keep re-attempting to code the plot until either the plot is satisfactory or it runs out of attempts
  for (attempt_idx in 1:num_code_attempts) {
    if (save_messages) {
      save_chat_messages(all_chat_messages, sprintf("%s/%s_all.json", save_dir, save_name))
    }

    attempt_results <- make_plot_attempt(code_string, input_df)
    if (attempt_results$success) {
      if (save_messages) {
        save_chat_messages(data.frame(role = c("system", "user", "assistant"), content = c(system_prompt, code_gen_prompt, code_string)), sprintf("%s/%s.json", save_dir, save_name))
      }
      return (list(code_string = code_string, plot_obj = attempt_results$plot_obj, usage_tokens = total_usage_tokens))
    } else if (attempt_idx < num_code_attempts) {
      chat_messages <- data.frame(
        role = c("user", "user"),
        content = c(code_gen_prompt, attempt_results$new_prompt)
      )

      if (temperature < 0.5) {
        # Increase temperature after each incorrect attempt
        temperature <- temperature + 0.1
      }

      if (using_azure) {
        response <- sullyplot_azure_continue_chat(chat_messages, system_message = system_prompt, deployment_id = code_model, max_tokens = 512, options = list(temperature = temperature))
      } else {
        response <- sullyplot_openai_continue_chat(chat_messages, system_message = system_prompt, model_name = code_model, max_tokens = 512, options = list(temperature = temperature))
      }

      code_string <- response$message
      log(sprintf("Attempt %d code:\n%s", attempt_idx, code_string))
      total_usage_tokens <- mapply('+', total_usage_tokens, response$usage_tokens)
      all_chat_messages <- rbind(all_chat_messages, data.frame(role = c("user", "assistant"), content = c(attempt_results$new_prompt, code_string)))

    } else if (!is.null(attempt_results$plot_obj)) {
      # If we're out of attempts but have a non-null plot object then use the plot object
      return(list(code_string = code_string, plot_obj = attempt_results$plot_obj, usage_tokens = total_usage_tokens))
    } else {
      stop(sprintf("Ran out of attempts with the error:\n%s", attempt_results$error))
    }
  }
}