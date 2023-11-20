make_plot_attempt <- function(code_string, file_df) {
  tryCatch({
    # First attempt to evaluate the code_string
    eval(parse(text = code_string))
    p <- plot_df(file_df)
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
      user_prompt <- sprintf(fix_low_quality_plot_prompt, code_string, low_quality$message)
      # A low quality plot can still be plotted if we run out of attempts, so return the plot object
      return(list(success = FALSE, plot_obj = p, new_prompt = user_prompt))
    } else {
      return(list(success = TRUE, plot_obj = p, new_prompt = ""))
    } 
  },
  error = function(e) {
    log(sprintf("Plot failed with the error: %s \n", e$message))
    user_prompt <- sprintf(fix_error_prompt, code_string, e$message)
    return(list(success = FALSE, plot_obj = NULL, new_prompt = user_prompt))
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