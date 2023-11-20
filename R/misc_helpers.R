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
    logger::log_info(sprintf("%s\n", message))
  }
}