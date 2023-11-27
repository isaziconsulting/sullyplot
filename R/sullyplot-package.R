#' sullyplot: Package for automatically plotting R plots and dashboards using LLMs.
#' 
#' The `sullyplot` R Package provides a framework for automated plotting of graphs and dashboards using OpenAI's latest LLMs.
#' 
#' @section sullyplot functions:
#' 
#' ## Functions
#' 
#' ### Automatically design and plot a full dashboard
#' 
#' 0. `auto_dash` - Generates a dashboard from the input file and returns the list of `ggplot` objects.
#' 1. `auto_dash_design` - Generates a dataframe describing the design of a dashboard for the given file.
#' 
#' ### Automatically plot individual graphs
#' 
#' 2. `auto_plot` - Generates a `ggplot` object from an input file, list of necessary columns, and plot description.
#'
#' ### Render generated plots and dashboards
#' 3. `render_dash_html` - Renders a list of `ggplot` objects as an interactive dashboard in html.
#' 4. `render_plot_html` - Renders a `ggplot` object as an interactive html page.
#' 5. `render_dash_pdf` - Renders a list of `ggplot` objects as a pdf file.
#'
#' ### Openai Chat Requests
#' 6. `sullyplot_openai_continue_chat` - Makes a continue chat request with openai chat completion endpoint and tracks token usage.
#' 7. `sullyplot_azure_continue_chat` - Makes a continue chat request with azure openai chat completion endpoint and tracks token usage.
#'
#' @md
#' @docType package
#' @name sullyplot
#' 
NULL
