#' sullyplot: Package for automatically plotting R plots and dashboards using LLMs.
#' 
#' The `sullyplot` R Package provides a framework for automated plotting of graphs and dashboards using OpenAI's latest LLMs.
#' 
#' @section sullyplot functions:
#' 
#' ## Functions
#' 
#' ### Automatically plot a full dashboard
#' 
#' 0. `auto_dash_interactive` - Generates an interactive dashboard from the input file and returns the html.
#' 1. `auto_dash` - Generates a dashboard from the input file and returns the list of `ggplot` objects.
#' 2. `render_dashboard` - Renders a list of `ggplot` objects as an interactive dashboard in html.
#' 
#' ### Automatically plot individual graphs
#' 
#' 3. `auto_plot` - Generates a `ggplot` object from an input file, list of necessary columns, and plot description.
#' 4. `attempt_code` - Attempts to plot the input file given the plotting code and returns the resulting status and plot object.
#'
#' @md
#' @docType package
#' @name sullyplot
#' 

## usethis namespace: start
#' @useDynLib sullyplot, .registration = TRUE
#' @importFrom Rcpp sourceCpp
## usethis namespace: end
NULL
