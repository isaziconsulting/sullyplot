read_data <- function(data) {
  # Try read as a file path if data is a string otherwise if it's a df use it directly
  if (is.character(data) && length(data) == 1) {
    return(read_file(data))
  } else if (is.data.frame(data)) {
    return(data)
  } else {
    stop(sprintf("Format %s is not supported", class(data)[1]))
  }
}

get_file_fmt <- function(filename) {
  extension <- tools::file_ext(filename)
  if (extension == "") {
    stop("No file extension found.")
  } else if (extension == "xls") {
    return("xlsx") # xls files can be handled the same as xlsx files
  } else if (extension == "tsv" || extension == "txt") {
    return("delim") # treat .txt and .tsv as delim (tab separated)
  } else {
    return(extension)
  }
}

read_file <- function(file_path) {
  file_fmt <- get_file_fmt(file_path)
  read_func <- switch(file_fmt,
                      xlsx = function(file) readxl::read_excel(file, sheet = 1),
                      csv = function(file) read.csv(file, header = TRUE, stringsAsFactors = FALSE, row.names = NULL),
                      delim = function(file) read.delim(file, quote = "", header = TRUE, stringsAsFactors = FALSE, row.names = NULL),
                      stop("file_fmt %s not yet supported" %>% sprintf(file_fmt))
  )
  df <- read_func(file_path)
  return(df)
}

filter_df <- function(df, keep_cols) {
  df <- df[, keep_cols, drop = FALSE]
  df <- na.omit(df)
  return(df)
}

to_csv <- function(df) {
  # Create a text connection
  csv_output <- textConnection("csv_string", "w", local = TRUE)
  
  # Write data frame to the text connection
  write.csv(df, csv_output, row.names = FALSE)
  
  # Close the connection
  close(csv_output)
  return(paste(csv_string, collapse = "\n"))
}

save_chat_messages <- function(df, file_path) {
  # Extract the directory path from the file_path
  directory <- dirname(file_path)
  
  # Check if the directory is just the current directory
  if (directory == "") {
    directory <- "."
  }
  
  # Check if the directory exists, if not, create it
  if (!dir.exists(directory)) {
    dir.create(directory, recursive = TRUE)
  }
  json_data <- jsonlite::toJSON(list(messages = df), auto_unbox = TRUE, pretty = TRUE)
  write(json_data, file = file_path)
}

log <- function(message) {
  if (is.list(message) || is.data.frame(message)) {
    logger::log_info(paste(capture.output(print(message)), collapse = "\n"))
  } else {
    logger::log_info(logger::skip_formatter(message))
  }
}

# extract_r_code is a helper to extract just the r code from the LLM response,
# it expects the code in an R code block (```r your code ```).
extract_r_code_from_response <- function(input_string) {
  # Use a regex to find and extract the code block(s)
  pattern <- "```r([\\s\\S]*?)```"
  code_string <- stringr::str_extract(input_string, pattern)
  # If the R code block is not found, stop with an error message
  if (is.na(code_string)) {
    stop("R code block not found in the response, please format your response as a fenced R code block (```r your code here ```).")
  }
  # Extract the first match and remove the R code block markers
  code_string <- sub("```r", "", code_string)
  code_string <- sub("```", "", code_string)
  # Check the code string is not empty
  if (trimws(code_string) == "") {
    stop("R code block does not contain any code.")
  }
  
  return(trimws(code_string))
}

# extract_json_from_response is a helper to extract just the JSON from the LLM response,
# it expects the code in a JSON code block (```json your code ```).
extract_json_from_response <- function(input_string) {
  # Use a regex to find and extract the code block(s)
  pattern <- "```json([\\s\\S]*?)```"
  json_string <- stringr::str_extract(input_string, pattern)
  # If the R code block is not found, stop with an error message
  if (is.na(json_string)) {
    stop("JSON code block not found in the response, please format your response as a fenced JSON code block (```json your JSON here ```).")
  }
  # Extract the first match and remove the R code block markers
  json_string <- sub("```json", "", json_string)
  json_string <- sub("```", "", json_string)
  # Check the code string is not empty
  if (trimws(json_string) == "") {
    stop("JSON code block does not contain any text")
  }
  
  return(trimws(json_string))
}