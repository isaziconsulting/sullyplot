# sullyplot

The `sullyplot` R Package provides a framework for automated plotting of graphs and dashboards using OpenAI's latest LLMs.

## Maintainer

Kelian Massa - Initial Developer ([@KelianM](https://github.com/KelianM))

## Disclaimer

This package interacts with OpenAI's APIs or Azure OpenAI depending on what you configure, to design and generate dashboards based on a series of prompts. **Please note that using these services incurs costs**, so be sure to review the pricing details on the OpenAI and Azure OpenAI websites and monitor your usage accordingly.

## Usage

You should first set the `OPENAI_API_KEY` environment variable on whichever environment you are using.
If you want to use the Azure OpenAI API, you will also need to set the `AZURE_RESOURCE_NAME` environment variable.

Then simply use the functions from `sullyplot` with `sullyplot::function_name()` to use AI models.

Can be installed using `devtools::install_github("isaziconsulting/sullyplot@main")`.

## Customizing the AI Model

While `sullyplot` is optimized for use with GPT-4, you have the flexibility to change the underlying model to any other model available through OpenAI or your Azure OpenAI deployment. To use a different model, simply adjust the `code_model` or `dash_model` parameter in the relevant functions.

Please note, however, that the package is intended and fine-tuned for optimal performance with GPT-4. Switching to a different model may degrade the quality or relevance of the generated plots and dashboards. We recommend sticking with GPT-4 for the best results, but feel free to experiment with other models as needed for your specific use case.

## Running Package Examples

### Running the Example Script Directly

To quickly run the example script included in the `sullyplot` package without making any changes to it, you can execute the following commands in your R console:

```r
# Locate and run the example script directly
example_script_path <- system.file("examples/example_usage.R", package = "sullyplot")
source(example_script_path)
```

This will run the example usage script that demonstrates how to use sullyplot functionalities, directly from your installed package.

### Copying and Modifying the Example Script

If you wish to modify the example script to experiment with it or try out different parameters, you can copy it to your current working directory (or another directory of your choice) and then make your changes. Here's how:

```r
# Locate the example script
example_script_path <- system.file("examples/example_usage.R", package = "sullyplot")

# Copy the script to your current working directory
new_script_path <- file.path(getwd(), "example_usage_modified.R")
file.copy(example_script_path, new_script_path)

# Now you can open `example_usage_modified.R` in your R IDE or text editor, make any changes, and run it using:
source(new_script_path)
```

## Functions

### Automatically design and plot a full dashboard

0. `auto_dash` - Generates a dashboard from the input file and returns the list of `ggplot` objects.
1. `auto_dash_design` - Generates a dataframe describing the design of a dashboard for the given file.

### Automatically plot individual graphs

2. `auto_plot` - Generates a `ggplot` object from an input file, list of necessary columns, and plot description.

### Render generated plots and dashboards
3. `render_dash_html` - Renders a list of `ggplot` objects as an interactive dashboard in html.
4. `render_plot_html` - Renders a `ggplot` object as an interactive html page.
5. `render_dash_pdf` - Renders a list of `ggplot` objects as a pdf file.

### Openai Chat Requests
6. `sullyplot_openai_continue_chat` - Makes a continue chat request with openai chat completion endpoint and tracks token usage.
7. `sullyplot_azure_continue_chat` - Makes a continue chat request with azure openai chat completion endpoint and tracks token usage.