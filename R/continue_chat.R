continue_chat <- function(chat_messages, system_message = NULL, model_name = "gpt-4", max_tokens = 150, options = list()) {
  openai_api_key <- Sys.getenv("OPENAI_API_KEY")
  if (openai_api_key == "") {
    stop("You need to set the OPENAI_API_KEY environment variable!")
  }
  
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
  
  # Create a JSON object with the messages and options
  json_data <- list(
    messages = messages,
    model = model_name,
    max_tokens = max_tokens
  )
  json_data <- utils::modifyList(json_data, options) # Add options to the JSON object
  
  # Call the API with exponential back-off
  response <- httr::RETRY(
    "POST",
    url = "https://api.openai.com/v1/chat/completions",
    httr::add_headers(
      "Content-Type" = "application/json",
      "Authorization" = paste0("Bearer ", openai_api_key)
    ),
    body = json_data,
    encode = "json",
    times = 5, # Number of retries
    pause_cap = 64, # Maximum delay between retries in seconds (2^6 = 64 seconds)
    pause_base = 2, # Base of the exponential back-off
    pause_min = 1, # Minimum delay between retries in seconds
    pause_growth = 1, # Growth factor for the exponential back-off
    verbose = 0, # Verbosity level
    terminate_on = c(400, 401, 404)
  )
  
  parsed_response <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
  if ("error" %in% names(parsed_response)) {
    stop("OpenAI Error: ", parsed_response$error$message, " (", parsed_response$error$type, ")")
  }
  
  if(parsed_response$choices$finish_reason != "stop"){
    warning(paste("AI Chat completion did not complete entirely - stop reason is ", parsed_response$choices$finish_reason))
  }
  
  # Extract the response message from the response
  response_message <- parsed_response$choices$message$content[[1]]
  
  # Also return tokens for collecting usage statistics
  prompt_tokens <- parsed_response$usage$prompt_tokens[[1]]
  completion_tokens <- parsed_response$usage$completion_tokens[[1]]
  usage_tokens <- list(prompt_tokens=prompt_tokens, completion_tokens=completion_tokens)
  
  return(list(message=response_message, usage_tokens=usage_tokens))
}
