#' Make a continue chat request with azure openai chat completion endpoint and track token usage.
#'
#' This function uses the azure openai api chat completions endpoint to continue a chat from a series of chat messages and optionally a system prompt, also returns usage statistics.
#' If azure openai is not configured, it will default to using the openai api using `sullyplot_openai_continue_chat`.
#'
#' @param chat_messages The input data frame of chat messages (see openai api docs for format).
#' @param system_message Optional system prompt which will be added to chat messages.
#' @param deployment_id The azure deployment id for the model you want to use. Default is 'gpt-4'.
#' @param api_version The azure openai api version. Default is '2023-05-15'.
#' @param max_tokens The maximum number of tokens in the response. Default is 150.
#' @param options Additional options such as temperature
#'
#' @return The response message as well as the amount of prompt and completion tokens used.
#'
#' @export
sullyplot_azure_continue_chat <- function(chat_messages, system_message = NULL, deployment_id = "gpt-4", api_version = "2023-05-15", max_tokens = 16384, options = list()) {
  openai_api_key <- Sys.getenv("OPENAI_API_KEY")
  if (openai_api_key == "") {
    stop("You need to set the OPENAI_API_KEY environment variable!")
  }

  if (!is_azure_openai_configured()) {
    log("AZURE_RESOURCE_NAME has not been set, defaulting to OpenAI API Chat Completion endpoint")
    # OpenAI API uses GPT-3.5-turbo instead of GPT-35-turbo
    model_name <- gsub("35", "3.5", deployment_id)
    return(sullyplot_openai_continue_chat(chat_messages, system_message, model_name, max_tokens, options))
  }
  azure_resource_name	 <- Sys.getenv("AZURE_RESOURCE_NAME")

  chat_messages <- apply(chat_messages, 1, as.list)

  # Initialize the list of messages with the system message, if provided
  messages <- list()
  if (!is.null(system_message)) {
    messages <- append(messages, list(list("role" = "system", "content" = system_message)))
  }

  # Append the chat messages to the list of messages
  messages <- append(messages, chat_messages)

  # Set default values for options and override with user-specified options
  default_options <- list(
    temperature = 0.5
  )
  if(is.null(options))options <- list()
  options <- utils::modifyList(default_options, options)


  # Remove temperature from options if not supported
  if (!(model_name %in% temperature_models)) {
    options$temperature <- NULL
  }
  
  # Create a JSON object with the messages and options
  json_data <- list(
    messages = messages,
    max_completion_tokens = max_tokens
  )
  json_data <- utils::modifyList(json_data, options) # Add options to the JSON object

  api_url = sprintf("https://%s.openai.azure.com/openai/deployments/%s/chat/completions?api-version=%s", azure_resource_name, deployment_id, api_version)

  # Call the API with exponential back-off
  response <- httr::RETRY(
    "POST",
    url = api_url,
    httr::add_headers(
      "Content-Type" = "application/json",
      "api-key" = openai_api_key
    ),
    body = json_data,
    encode = "json",
    times = 5, # Number of retries
    pause_cap = 64, # Maximum delay between retries in seconds (2^6 = 64 seconds)
    pause_base = 2, # Base of the exponential back-off
    pause_min = 1, # Minimum delay between retries in seconds
    pause_growth = 1, # Growth factor for the exponential back-off
    verbose = 1, # Verbosity level
    terminate_on = c(400, 401, 404)
  )

  parsed_response <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
  if ("error" %in% names(parsed_response)) {
    stop("Azure OpenAI Error: ", parsed_response$error$message, " (", parsed_response$error$type, ")")
  }

  if(parsed_response$choices$finish_reason != "stop"){
    stop(paste("AI Chat completion did not complete entirely - stop reason is ", parsed_response$choices$finish_reason))
  }

  # Extract the response message from the response
  response_message <- parsed_response$choices$message$content[[1]]

  # Also return tokens for collecting usage statistics
  prompt_tokens <- parsed_response$usage$prompt_tokens[[1]]
  completion_tokens <- parsed_response$usage$completion_tokens[[1]]
  usage_tokens <- list(prompt_tokens=prompt_tokens, completion_tokens=completion_tokens)

  return(list(message=response_message, usage_tokens=usage_tokens))
}

is_azure_openai_configured <- function() {
  azure_resource_name	 <- Sys.getenv("AZURE_RESOURCE_NAME")
  azure_configured <- (azure_resource_name != "")
  azure_configured
}
