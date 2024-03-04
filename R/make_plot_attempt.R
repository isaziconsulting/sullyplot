make_plot_attempt <- function(code_response, input_df) {
  tryCatch({
    # Extract the R code from the code block
    plotting_code <- extract_r_code_from_response(code_response)
    # Attempt to evaluate the code
    eval(parse(text = plotting_code))
    p <- plot_df(input_df)
    if (!inherits(p, "ggplot")) {
      if(class(p)[1] == "gtable" || class(p)[1] == "list") {
        stop("The returned object is of class '", class(p)[1], "', not 'ggplot', make sure to use `facet_wrap` for the separate y-axes rather than rendering a group of separate `ggplot` objects.")
      }
      stop("The returned object is of class '", class(p)[1], "', not 'ggplot'.")
    }
    # Try to render the plot object
    test_rendering(p)
    # Assess if plot is low quality
    low_quality <- is_low_quality_plot(p)
    if(low_quality$status) {
      log(sprintf("Plot was low quality: %s \n", low_quality$message))
      user_prompt <- sprintf(fix_low_quality_plot_prompt, code_response, low_quality$message)
      # A low quality plot can still be plotted if we run out of attempts, so return the plot object
      return(list(success = FALSE, plot_obj = p, new_prompt = user_prompt, error = low_quality$message))
    } else {
      log("Plot successful!")
      return(list(success = TRUE, plot_obj = p, new_prompt = NULL, error = NULL))
    } 
  },
  error = function(e) {
    # Construct a simplified error message as full traceback is too long to prompt with
    simplified_error <-   custom_error_handler(e)
    log(sprintf("Plot failed with the error: %s \n", simplified_error))
    user_prompt <- sprintf(fix_error_prompt, code_response, simplified_error)
    return(list(success = FALSE, plot_obj = NULL, new_prompt = user_prompt, error = simplified_error))
  })
}

# Tries to render a ggplot object
test_rendering <- function(plot_obj) {
  # Create a temporary pdf file for testing if we can render the plot
  test_file <- tempfile(fileext = "pdf")
  tryCatch({
    # First try render normally
    print(plot_obj)
  }, error = function(e) {
    # If that fails, try rendering with a file-based graphics device since it could be failing
    # due to the main graphics device being inaccessible (e.g. if this is run from a forked child process)
    pdf(test_file)
    print(plot_obj)
    dev.off()
  }, finally = {
    # Clean up temp file
    unlink(test_file)
  })
}

# custom_error_handler is a helper to return a simplified error message without the full traceback
custom_error_handler <- function(e) {
  # Extract the call from the error object
  error_call <- e$call
  
  # Get the function name
  func_name <- as.character(error_call[[1]])
  
  # Extract the error message
  error_message <- e$message
  
  # Get the arguments passed to the function
  args_passed <- sapply(error_call[-1], deparse)
  
  # Construct a simplified error message
  simplified_error <- paste("Error in function:", func_name, "\nArguments:", 
                            paste(names(args_passed), args_passed, sep = "=", collapse = ", "),
                            "\nMessage:", error_message)
  
  return(simplified_error)
}