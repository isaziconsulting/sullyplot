% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/stats_helpers.R
\name{summarise_df}
\alias{summarise_df}
\title{summarise_df
Makes a convenient summary structure from an input dataframe, providing some summary stats of each column as well as some examples in a format that's easy to interrogate.}
\usage{
summarise_df(df, remove_cols = TRUE, max_cols = 10)
}
\arguments{
\item{df}{- the data frame to be analysed}

\item{max_cols}{- the maximum number of columns to summarise. Default is `10`.}
}
\value{
Returns a df of summary stats for each column.
}
\description{
summarise_df
Makes a convenient summary structure from an input dataframe, providing some summary stats of each column as well as some examples in a format that's easy to interrogate.
}
