% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/render_plot_html.R
\name{render_plot_html}
\alias{render_plot_html}
\title{Renders an a `ggplot` object as an interactive html plot.}
\usage{
render_plot_html(plot, filename = NULL, display = FALSE)
}
\arguments{
\item{plot}{The `ggplot` object to render as an interactive html plot.}

\item{filename}{The filename to save the html file under (must be .html), no file is saved if null. Default is null.}

\item{display}{If true and a filename is specified opens up the dashboard html file in a separate browser page. Default is false.}
}
\value{
The html code for the interactive dashboard.
}
\description{
This function renders a `ggplot` object as an interactive plotly-based html plot
with the option to save and display it.
}
\examples{
\donttest{
  # Create an example plot with the mtcars dataset
  library(ggplot2)
  example_plot <- ggplot(mtcars, aes(x=wt, y=mpg)) +
    geom_point() +
    theme_minimal() +
    ggtitle("MPG vs. Weight")

  # Specify an output directory (adjust path as needed)
  output_dir <- tempdir() # Using tempdir() for example purposes

  # Render and optionally display the plot as HTML
  sullyplot::render_plot_html(example_plot, file.path(output_dir, "custom_plot.html"), display=TRUE)

  # Note: In actual use, replace tempdir() with a specific directory
  # and ensure the directory exists or is created before saving.
}

}
