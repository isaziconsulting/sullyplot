system_prompt <- "You are a data science assistant running an automated data science dashboard.
  Your job is to analyse data and produce R code that generates plots to capture the most relevant relationships or trends in the data.
  You must pay specific attention to prompts that tell you how to format your answers.
  Never include any of your own additional formatting or explanations in your answers.
  
*** DASHBOARD RULES ***
  1. Make sure all plots can be plotted as `ggplot` objects.
  2. **Plot Types**:
    - scatter plots: must have only quantitatives on the x and y axes, and an optional 3rd categorical with n_distinct <= 3 or quantitative column for colour (if you use a quantitative for colour, specify to use a continuous colour scale).
    - line plot: must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for colour.
    - box plots: must have a categorical on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for separate y-axes or grouped box plots, or an optional 3rd quantitative column to be plotted on a separate y axis.
    - histogram: must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column with n_distinct <= 3 for stacked bars, multiple axes, or colour.
    - bar chart: must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for stacked bars or multiple axes.

  3. **Column Types**:
    - Quantitative variables must be numeric or integers and must not have the type 'Categorical' in the summary.
    - Categorical variables must have the type 'Categorical' in the summary.
    - For columns with the type 'Large Categorical' or 'Free Text', specify how to select the 10 most interesting categories (e.g. the 10 most expensive car brands).
    - Any variables referenced in plot descriptions must also be in the provided summary and list of input columns. Never reference a variable that does not correspond to a specific column.
    - n_distinct in the summary must be <= 3 to use a column for additional colouring, grouping, or separate y-axes to avoid visual clutter.
"

describe_dashboard_prompt <- "Design a data analysis dashboard consisting of %d plots using the data I give you. 

Explore the dataset with a variety of data analysis plots. Choose plots that give a broad and diverse view of the dataset, highlighting different aspects and relationships.

Ensure the plots each show different relationships by varying them as much as possible using different plot types and different columns, e.g. do not just use scatter plots or repeatedly show the same column on an axis.

As a guideline, include no more than 2 of the same plot type.

*** DASHBOARD RULES ***
  1. Make sure all plots can be plotted as `ggplot` objects.
  2. **Plot Types**:
    - scatter plots: must have only quantitatives on the x and y axes, and an optional 3rd categorical with n_distinct <= 3 or quantitative column for colour (if you use a quantitative for colour, specify to use a continuous colour scale).
    - line plot: must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for colour.
    - box plots: must have a categorical on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for separate y-axes or grouped box plots, or an optional 3rd quantitative column to be plotted on a separate y axis.
    - histogram: must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column with n_distinct <= 3 for stacked bars, multiple axes, or colour.
    - bar chart: must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for stacked bars or multiple axes.

  3. **Column Types**:
    - Quantitative variables must be numeric or integers and must not have the type 'Categorical' in the summary.
    - Categorical variables must have the type 'Categorical' in the summary.
    - For columns with the type 'Large Categorical' or 'Free Text', specify how to select the 10 most interesting categories (e.g. the 10 most expensive car brands).
    - Any variables referenced in plot descriptions must also be in the provided summary and list of input columns. Never reference a variable that does not correspond to a specific column.
    - n_distinct in the summary must be <= 3 to use a column for additional colouring, grouping, or separate y-axes to avoid visual clutter.

*** OUTPUT RULES ***
- Your response must only be a JSON string, formatted as a fenced JSON code block, with the following keys:
  - \"input_columns\": A list of lists of input columns from the summary needed for each plot.
  - \"descriptions\": A list of natural language plot descriptions explaining each plot, how it must show the relevant relationship, and how each column should be used in the plot.
Here is an example response:
```json
{
  \"input_columns\": [
    [\"Sales\", \"Date\"],
    [\"Sales\", \"ProductCategory\"],
    [\"Sales\", \"Region\"],
    [\"Sales\"],
    [\"Date\", \"Sales\", \"Region\"]
  ],
  \"descriptions\": [
    \"A line plot showing the trend of Sales over time. The x-axis represents Date, and the y-axis represents Sales. This plot highlights how sales have varied over the given period.\",
    \"A box plot comparing Sales across different ProductCategories. The x-axis represents ProductCategory, and the y-axis represents Sales. This plot shows the distribution of sales within each category.\",
    \"A bar chart displaying the total Sales per Region. The x-axis represents Region, and the y-axis represents the total Sales. This plot reveals the sales performance across different regions.\",
    \"A histogram showing the distribution of Sales. The x-axis represents Sales in bins, and the y-axis represents the count of sales in each bin. This plot provides insights into the frequency of different sales amounts.\",
    \"A scatter plot illustrating the relationship between Date and Sales, with the points coloured by Region. The x-axis represents Date, the y-axis represents Sales, and the colour represents different Regions. This plot explores how sales trends vary across regions over time.\"
  ]
}
```
Here is a summary of the columns in my input dataframe:
%s

Mutual information matrix of numeric columns:
%s

Significant categorical relationships and Chi-squared values:
%s

Significant categorical-to-numeric relationships and ANOVA values:
%s
"

describe_custom_dashboard_prompt <- "Design this dashboard consisting of %d plots using the data I give you:
%s\n 
*** DASHBOARD RULES ***
  1. Make sure all plots can be plotted as `ggplot` objects.
  2. **Plot Types**:
    - scatter plots: must have only quantitatives on the x and y axes, and an optional 3rd categorical with n_distinct <= 3 or quantitative column for colour (if you use a quantitative for colour, specify to use a continuous colour scale).
    - line plot: must have a DateTime column on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for colour.
    - box plots: must have a categorical on the x-axis, a quantitative on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for separate y-axes or grouped box plots, or an optional 3rd quantitative column to be plotted on a separate y axis.
    - histogram: must have a quantitative on the x-axis in bins, counts on the y axis, and an optional 2nd categorical column with n_distinct <= 3 for stacked bars, multiple axes, or colour.
    - bar chart: must have a categorical on the x-axis and counts on the y axis, and an optional 3rd categorical column with n_distinct <= 3 for stacked bars or multiple axes.

  3. **Column Types**:
    - Quantitative variables must be numeric or integers and must not have the type 'Categorical' in the summary.
    - Categorical variables must have the type 'Categorical' in the summary.
    - For columns with the type 'Large Categorical' or 'Free Text', specify how to select the 10 most interesting categories (e.g. the 10 most expensive car brands).
    - Any variables referenced in plot descriptions must also be in the provided summary and list of input columns. Never reference a variable that does not correspond to a specific column.
    - n_distinct in the summary must be <= 3 to use a column for additional colouring, grouping, or separate y-axes to avoid visual clutter.

*** OUTPUT RULES ***
- Your response must only be a JSON string, formatted as a fenced JSON code block, with the following keys:
  - \"input_columns\": A list of lists of input columns from the summary needed for each plot.
  - \"descriptions\": A list of natural language plot descriptions explaining each plot, how it must show the relevant relationship, and how each column should be used in the plot.
Here is an example response:
```json
{
  \"input_columns\": [
    [\"Sales\", \"Date\"],
    [\"Sales\", \"ProductCategory\"],
    [\"Sales\", \"Region\"],
    [\"Sales\"],
    [\"Date\", \"Sales\", \"Region\"]
  ],
  \"descriptions\": [
    \"A line plot showing the trend of Sales over time. The x-axis represents Date, and the y-axis represents Sales. This plot highlights how sales have varied over the given period.\",
    \"A box plot comparing Sales across different ProductCategories. The x-axis represents ProductCategory, and the y-axis represents Sales. This plot shows the distribution of sales within each category.\",
    \"A bar chart displaying the total Sales per Region. The x-axis represents Region, and the y-axis represents the total Sales. This plot reveals the sales performance across different regions.\",
    \"A histogram showing the distribution of Sales. The x-axis represents Sales in bins, and the y-axis represents the count of sales in each bin. This plot provides insights into the frequency of different sales amounts.\",
    \"A scatter plot illustrating the relationship between Date and Sales, with the points coloured by Region. The x-axis represents Date, the y-axis represents Sales, and the colour represents different Regions. This plot explores how sales trends vary across regions over time.\"
  ]
}
```

Here is a summary of the columns in my input dataframe:
%s
"

improve_dashboard_prompt <- "Can you improve the previous response by replacing plot descriptions and their input columns according to the following guidelines:

1. **Compliance with DASHBOARD RULES**:
   - Ensure all plots adhere to the previously stated DASHBOARD RULES.
   - Replace any plots that do not follow these rules.
   - Remove any additional categorical columns used for colouring, grouping, or separate y-axes, which have n_distinct > 3 to avoid visual clutter

2. **Logical Sense**:
   - Replace any plots that do not make logical sense (e.g. a plot using an ID number as a continuous value).

3. **Visual Enhancements**:
   - Where appropriate and not present already, add or improve existing visual enhancements:
     - If they have at most 3 distinct categories (n_distinct <= 3) and are logically relevant, add categorical columns from the summary to show relationships across different categories. Explain how these should be used.
     - For large categorical variables (e.g. more than 10 categories), avoid using them for colour or separate y-axes. Instead, summarise the data by selecting the top categories based on a relevant metric (e.g. top 10 regions by sales).
     - Add 95%% prediction ellipses per category for any scatter plots that have a categorical column for colour.
     - Add lines of best fit with 95%% confidence intervals to line plots, and scatter plots without categories.
     - Be creative to make the plots more interesting and insightful.

4. **Redundancy and Variety**:
   - Replace any redundant or highly similar plots with different plots.
   - Ensure there are %d plots in total. Add new plots if the number of plots is insufficient.

Your previous response was:
%s

** Ensure your dashboard design meets the previously stated DASHBOARD RULES and OUTPUT RULES **"


generate_code_prompt <- "I want to create this plot: %s
    Please provide a function in R called 'plot_df' that takes a dataframe 'df' as its argument, processes it, and then directly returns a `ggplot` object.
    The function must perform preprocessing, data transformation, statistical analyses, and plotting.
    Preprocessing includes:
      - Converting numeric variables to factors with `as.factor()` when used categorically.
      - For scatter, box and line plots, removing outliers and downsampling remaining data to 1000 rows when count > 1000 (use strategic downsampling if there is a category).
      - Creating derived variables when necessary, such as computing aggregates, differences, or ratios that may be more informative for the plot.
      - Handling missing values by imputation or removal, depending on the amount and nature of the missing data.

    *** STYLING RULES ***
      - Box plots should always be coloured by category.
      - Never colour by count.
      - Use `facet_wrap` when separate y-axes are specified.
      - Prediction ellipses must be drawn with `ggplot2::stat_ellipse` with default asthetics.
      - Always use `theme_grey`
      - When colouring categoricals, use the `Set3` colour palette from `RColorBrewer`.
      - Only when asked for a continuous colour scale, use `scale_colour_gradient(low = 'blue', high = 'red')`.
      - Make the first colour from the `Set3` palette the default plotting colour, including for scatter plots.
      - Continuous numeric ticks must be rounded to 2 decimal places
      - X axis ticks must be rotated.

    *** OUTPUT RULES ***
      - The response should consist of only the R code for the `plot_df` function without comments, formatted as a fenced R code block, like so:
      ```r
        plot_df <- function(df) { your code here }
      ```
      - Include library requirements in the function code with require() statements.
      - The `plot_df` function must return only a `ggplot` object.
      - All plots must have a concise title and axes must be labelled.
      - DO NOT include comments in the code.

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