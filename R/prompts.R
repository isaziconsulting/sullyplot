system_prompt <- "You are a data science assistant running an automated data science dashboard.
  Your job is to analyse data and produce R code that generates plots to capture the most relevant relationships or trends in the data.
  You must pay specific attention to prompts that tell you how to format your answers.
  Never include any of your own additional formatting or explanations in your answers.
  
  *** DASHBOARD RULES ***
  Make sure all plots can be plotted as `ggplot` objects.
  Quantitatives must be numerics/integers and have n_distinct > 20 in the summary.
  Categoricals must have the type 'Categorical' in the summary.
  Any variables referenced in plot descriptions must also be in the provided summary and list of input columns - never reference a varaible that does not refer to a specific column.
  Here are the available plot types & rules:
    scatter plots - must have only quantitatives on the x and y axes, and an optional 3rd categorical or quantitative column for colour (if you use a quantitative for colour, specify to use a continuous colour scale).
    line plot - must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column for colour.
    box plots - must have a categorical on the x-axis, a quantitative on the y axis, and an optional 3rd categorical or quantitative column for separate y-axes or grouped box plots.
    histogram - must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column for stacked bars, multiple axes, or colour.
    bar chart - must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column for stacked bars or multiple axes.
"

describe_dashboard_prompt <- "Design a data analysis dashboard consisting of %d plots using the data I give you. 

Explore the dataset with a variety of data analysis plots. Choose plots that give a broad and diverse view of the dataset, highlighting different aspects and relationships.

Ensure the plots each show different relationships by varying them as much as possible using different plot types and different columns, e.g. do not just use scatter plots or repeatedly show the same column on an axis.

As a guideline, include no more than 2 of the same plot type.

*** DASHBOARD RULES ***
  Make sure all plots can be plotted as `ggplot` objects.
  Quantitatives must be numerics/integers and have n_distinct > 20 in the summary.
  Categoricals must have the type 'Categorical' in the summary.
  Any variables referenced in plot descriptions must also be in the provided summary and list of input columns - never reference a varaible that does not refer to a specific column.
  Here are the available plot types & rules:
    scatter plots - must have only quantitatives on the x and y axes, and an optional 3rd categorical or quantitative column for colour (if you use a quantitative for colour, specify to use a continuous colour scale).
    line plot - must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column for colour.
    box plots - must have a categorical on the x-axis, a quantitative on the y axis, and an optional 3rd categorical or quantitative column for separate y-axes or grouped box plots.
    histogram - must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column for stacked bars, multiple axes, or colour.
    bar chart - must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column for stacked bars or multiple axes.

*** OUTPUT RULES ***
Your answer must only be a JSON string with the following keys:
- \"input_columns\": A list of lists of input columns from the summary needed for each plot.
- \"descriptions\": A list of plot descriptions explaining each plot, how it must show the relevant relationship, and how each column should be used in the plot.

Here is a summary of the columns in my input dataframe:
%s

Mutual information matrix of numeric columns:
%s

Significant categorical relationships and Chi-squared values:
%s

Significant categorical-to-numeric relationships and ANOVA values:
%s

** Only output the JSON string; omit any surrounding formatting such as single or double inverted commas or backticks, or stating json ```.**"

describe_custom_dashboard_prompt <- "Design this dashboard consisting of %d plots using the data I give you:
%s\n 
*** DASHBOARD RULES ***
  Make sure all plots can be plotted as `ggplot` objects.
  Quantitatives must be numerics/integers and have n_distinct > 20 in the summary.
  Categoricals must have the type 'Categorical' in the summary.
  Any variables referenced in plot descriptions must also be in the provided summary and list of input columns - never reference a variable that does not refer to a specific column.
  Here are the available plot types & rules:
    scatter plots - must have only quantitatives on the x and y axes, and an optional 3rd categorical or quantitative column for colour (if you use a quantitative for colour, specify to use a continuous colour scale).
    line plot - must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column for colour.
    box plots - must have a categorical on the x-axis, a quantitative on the y axis, and an optional 3rd categorical or quantitative column for separate y-axes or grouped box plots.
    histogram - must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column for stacked bars, multiple axes, or colour.
    bar chart - must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column for stacked bars or multiple axes.

*** OUTPUT RULES ***
Your answer must only be a JSON string with the following keys:
- \"input_columns\": A list of lists of input columns from the summary needed for each plot.
- \"descriptions\": A list of plot descriptions explaining each plot, how it must show the relevant relationship, and how each column should be used in the plot.

Here is a summary of the columns in my input dataframe:
%s

** Only output the JSON string; omit any surrounding formatting such as single or double inverted commas or backticks, or stating json ```.**"

improve_dashboard_prompt <- "Can you improve on previous response by replacing plot descriptions and their input columns according to the following:

Most importantly, replace any plots that do not follow the previously stated DASHBOARD RULES.

Then, where appropriate and not present already, add or improve existing visual enhancements, including:
- Add categorical columns if available in the summary to show relationships accross different categories where relevant
- Group related plots together into one plot - e.g. If there are two box/bar plots with the same categories use multiple separate y-axes to plot them as a single `ggplot`. Or if there are two scatter plots with the same x-axis, group them into one `ggplot` with separate y-axes.
- Add 95%% prediction elipses per category for any scatter plots that have a categorical column
- Add lines of best fit with 5%% confidence intervals to line plots, and scatter plots that do not have a categorical column

Finally, replace any redundant or highly similar plots with different plots then make sure there are %d plots in total and add new plots if there aren't.

Your previous response was:
%s

** Make sure your dashboard designs meets the previously stated DASHBOARD RULES **
** Only output the modified JSON string. **"

generate_code_prompt <- "I want to create this plot: %s
    Please provide a function in R called 'plot_df' that takes a dataframe 'df' as its argument, processes it, and then directly returns a `ggplot` object.
    The function should handle the necessary data transformation, statistical analyses, and plotting within it.
    Only if the plot specifically states to use separate y-axes, use `facet_wrap` to show them.

    *** STYLING RULES ***
      Box plots should always be coloured by category.
      Make sure to use bins for histograms.
      Never colour histograms by count.
      Use `facet_wrap` when separate y-axes are specified.
      Draw prediction ellipses with `ggplot2::stat_ellipse` and the same colour as their category.
      Always use `theme_grey`, the `Set3` colour palette from `RColorBrewer`.
      Make the first colour from the palette the default plotting colour - never plot in black e.g. in single-category scatter plots this should be the default colour for dots.
      Continuous numeric ticks must be rounded to 2 decimal places, and numeric x axis ticks must be rotated.
      Only ever colour by category if the column you are using for colouring has the type 'Categorical' in the provided summary.
    
    *** OUTPUT RULES ***
      Only ever return a single function called `plot_df`
      Make sure the `plot_df` function returns a `ggplot` object
      DO NOT include comments
      Include library requirements with require() statements
      All plots must have a concise title and axes must be labelled
      Respond with only the string of code, without any surrounding formatting like single or double inverted commas or backticks
      Features must be placed on the axes specified in the plot description (e.g. type on x-axis and count on y-axis)
    Here is a summary of the columns in the input data frame df:
    %s"
  
fix_error_prompt <- "Your previous code:
    %s
    Failed with:
    %s
    Rewrite the function completely from scratch so that it does not encounter this error and respond with only the new code and nothing else."

fix_low_quality_plot_prompt <- "Your previous code: %s
    Led to a low quality plot for this reason: %s
    Rewrite the function to account for this and respond with only the new code and nothing else."

overview_prompt <- "My input file is '%s', from the filename and summary of my input data which I will give you, give an appropriate title to my dashboard, and generate a very brief executive summary of my data.

The executive summary should be an overall description of the data without including specifics ignore numeric statistics for the executive summary, DO NOT name the columns in the data.

Try be creative and use your own knowledge to draw insights into the purpose of the data for the executive summary, rather than stating direct observations from the csv summary.

Then identify and list any columns from the summary which are useless for data science, such columns with very low information or high num_na.

In this list, include identifier columns - these are columns which are used purely for identifying individual items, they will include words such as id or code and have a high `n_distinct`. 

Note that box plots must have a category and a continous y-axis.
Scatter and line plots must have continuous x and y axes and an optional category, but never a 'Categorical' on an axis.

Your answer must only be a JSON string with the following keys:
- `title`: The title of the dashboard.
- `summary`: The executive summary giving an overview of the data.
- `ignore_cols`: The list of columns that are useless for the purposes of this dashboard.

Here is a summary of the columns in my input dataframe:
%s.

** Only output the JSON string; omit any surrounding formatting such as single or double inverted commas.**"