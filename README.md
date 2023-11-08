# sullyplot

The `sullyplot` R Package provides a framework for automated plotting of graphs and dashboards using OpenAI's latest LLMs.

## Usage

You should first set the `OPENAI_API_KEY` environment variable on whichever environment you are using.

Then simply use the functions from `sullyplot` with `sullyplot::function_name()` to use AI models.

## Functions

### Automatically plot a full dashboard

0. `auto_dash_interactive` - Generates an interactive dashboard from the input file and returns the html.
1. `auto_dash` - Generates a dashboard from the input file and returns the list of `ggplot` objects.
2. `make_interactive` - Converts a list of `ggplot` objects into an interactive dashboard in html.

### Automatically plot individual graphs

3. `auto_plot` - Generates a `ggplot` object from an input file, list of necessary columns, and plot description.
4. `auto_plot_code` - Same as `auto_plot` but only returns the plotting code.
5. `attempt_code` - Attempts to plot the input file given the plotting code and returns the resulting status and plot object.