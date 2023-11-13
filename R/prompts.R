system_prompt <- "You are a data science assistant running an automated data science dashboard.
  Your job is to analyse data and produce R code that generates plots to capture the most relevant relationships or trends in the data.
  You must pay specific attention to prompts that tell you how to format your answers.
  Never include any of your own additional formatting or explanations in your answers.
"

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

describe_dashboard_prompt <- "Identify %d plots for a comprehensive data analysis and exploration dashboard using the data I give you. 

Explore the dataset with a variety of data analysis plots, ensure each plot captures significant and insightful relationships or patterns within the dataset. Choose plots that give a broad and diverse view of the dataset, highlighting different aspects and relationships.
Ensure there is never more than two of a plot type.

Make sure your plots follow the available plot types & rules:
  Note for all cases where I refer to quantitatives, they must have n_distinct > 20; and for categoricals, they must have they type 'Categorical'
  Here are the available plot types & rules:
    scatter plots - must have quantitatives on the x and y axes, and an optional 3rd categorical or quantitative column for colour.
    line plot - must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column for colour.
    box plots - must have a categorical on the x axis and a quantitative on the y axis. Can have multiple quantitative y-axes if related, but you must explicitly state how they should be used together (e.g. separate y-axes or an additional category for which quantitative it is).
    histogram - must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column for stacked bars, multiple axes, or colour.
    bar chart - must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column for stacked bars or multiple axes.

** Make sure all plots can be plotted as `ggplot` objects. **

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

describe_custom_dashboard_prompt <- "Identify %d plots for this dashboard:
%s\n 

Make sure your plots follow the available plot types & rules:
  Note for all cases where I refer to quantitatives, they must have n_distinct > 20; and for categoricals, they must have they type 'Categorical'
  Here are the available plot types & rules:
    scatter plots - must have quantitatives on the x and y axes, and an optional 3rd categorical or quantitative column for colour.
    line plot - must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column for colour.
    box plots - must have a categorical on the x axis and a quantitative on the y axis. Can have multiple quantitative y-axes if related, but you must explicitly state how they should be used together (e.g. separate y-axes or an additional category for which quantitative it is).
    histogram - must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column for stacked bars, multiple axes, or colour.
    bar chart - must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column for stacked bars or multiple axes.

** Make sure all plots can be plotted as `ggplot` objects. **

Your answer must only be a JSON string with the following keys:
- \"input_columns\": A list of lists of input columns from the summary needed for each plot.
- \"descriptions\": A list of plot descriptions explaining each plot, how it must show the relevant relationship, and how each column should be used in the plot.

Here is a summary of the columns in my input dataframe:
%s

** Only output the JSON string; omit any surrounding formatting such as single or double inverted commas or backticks, or stating json ```.**"

improve_dashboard_prompt <- "Can you improve on previous response by replacing plot descriptions and their input columns according to the following:

Never reduce the amount information in plots e.g. never separate one plot into two

Most importantly, replace any plots that do not follow the plot rules:
  Here are the available plot types & rules:
    scatter plots - must have quantitatives on the x and y axes, and an optional 3rd categorical or quantitative column for colour.
    line plot - must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column for colour.
    box plots - must have a categorical on the x axis and a quantitative on the y axis. Can have multiple quantitative y-axes if related, but you must explicitly state how they should be used together (e.g. use separate y-axes or an additional category for which quantitative it is).
    histogram - must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column for stacked bars, multiple axes, or colour.
    bar chart - must have a categorical on the x-axis and a quantitative or counts on the y axis, and an optional 3rd categorical column for stacked bars or multiple axes.
  Note for all cases where I refer to quantitatives, they must have n_distinct > 20; and for categoricals, they must have they type 'Categorical'

Then, where appropriate and not present already, add or improve existing visual enhancements such as:
- Add categorical columns to show relationships accross categories where relevant (Pay attention to the optional additional category columns in the plot rules)
- Add 95%% prediction elipses per category for any scatter plots that have a 3rd categorical column
- Add lines of best fit with 5%% confidence intervals where relevant
- Split plots into multiple y axes if there are too many columns to show for one graph.
- Group related plots together - e.g. If there are two box/bar plots with the same categories use multiple separate y-axes to plot them as a single `ggplot` and add a new scatter plot.
- Replace any redundant plots with different plots.

Finally, make sure there are still at least %d plots in total and add plots if there aren't.

Your previous response was:
%s

** Make sure the listed input columns meet the plot rules described in the system prompt **
** Only output the modified JSON string. **"

generate_code_prompt <- "I want to create this plot: %s
    Please provide a function in R called 'plot_df' that takes a dataframe 'df' as its argument, processes it, and then directly returns a `ggplot` object.
    The function should handle the necessary data transformation, statistical analyses, and plotting within it.
    Make sure to handle NA values.
    Make sure continuous numeric ticks are rounded to 2 decimal places, and numeric x axis ticks are rotated.
    
    For scatter plots with categoricals, always include the 95%% predictions elipses per category.
    Box plots should always be coloured by category.
    Make sure to use bins for histograms.
    Never colour histograms by count.
    Multi-category scatter/line plots, should have different colours for each category.
    Use `facet_wrap` when separate y-axes are specified.
    Prediction elipses should have the same colour as their category.
    Always use `theme_grey`, the `Set3` colour palette from `RColorBrewer`.
    Make the first colour from the palette the default plotting colour - always use this colour for single colour plots.
    
    ** Only ever return a single function called `plot_df` **
    ** Your code must be compatible with only the libraries ggfortify, ggplot2, ggcorrplot, tidyverse, dplyr, broom, Cairo, gridExtra, reshape2, modelr **
    ** Make sure the `plot_df` function returns a `ggplot` object **
    ** DO NOT include comments **
    ** DO NOT include library requirements (only write the code without library() or require() statements) **
    ** Make sure all plots have a concise title and axes are labelled **
    ** Your answer must be just the string of code, without any surrounding formatting like single or double inverted commas or backticks **
    ** Make sure to place features on the axes specified in the plot description (e.g. type on x-axis and count on y-axis) **
    Here is a summary of the columns in the input data frame df:
    %s"

# ** The default theme should be black axes, a white background with grey grid lines, and light blue for data, never plot in black**
# ** When colouring by category, use a colour palette of light blue, pink, light green, yellow, light red and orange **

fix_error_prompt <- "Your previous code: %s
    Failed with: %s
    Rewrite the function completely from scratch so that it does not encounter this error and respond with only the new code and nothing else."

fix_low_quality_plot_prompt <- "Your previous code: %s
    Led to a low quality plot for this reason: %s
    Rewrite the function to account for this and respond with only the new code and nothing else."