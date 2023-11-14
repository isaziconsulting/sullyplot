# sullyplot

The `sullyplot` R Package provides a framework for automated plotting of graphs and dashboards using OpenAI's latest LLMs.

## Usage

You should first set the `OPENAI_API_KEY` environment variable on whichever environment you are using.

Then simply use the functions from `sullyplot` with `sullyplot::function_name()` to use AI models.

Can be installed using `devtools::install_gitlab("isazi/hudson-packages/sullyplot@main")`.

## Functions

### Automatically plot a full dashboard

0. `auto_dash` - Generates a dashboard from the input file and returns the list of `ggplot` objects.
1. `auto_dash_df` - Generates a dashboard from an input data frame and returns the list of `ggplot` objects.
2. `render_dash_html` - Renders a list of `ggplot` objects as an interactive dashboard in html.
3. `render_dash_pdf` - Renders a list of `ggplot` objects as a pdf file.

### Automatically plot individual graphs

4. `auto_plot` - Generates and runs the code to create a `ggplot` object from an input file, list of necessary columns, and plot description.