#' summarise_df
#' Makes a convenient summary structure from an input dataframe, providing some summary stats of each column as well as some examples in a format that's easy to interrogate.
#'
#' @param df - the data frame to be analysed
#' @param max_cols - the maximum number of columns to summarise. Default is `10`.
#'
#' @return Returns a df of summary stats for each column.
#' @importFrom rlang .data
summarise_df <- function(df, remove_cols=TRUE, max_cols=10) {
  df_stats <- data.frame(name = names(df))
  df_and_fmt <- autoconvert_dataframe(df)
  df_prime <- df_and_fmt$df
  fmts <- df_and_fmt$formats
  # Use original names
  names(df_prime) <- names(df)
  names(fmts) <- names(df)
  
  cat_cutoff <- 10
  df_stats$type <- sapply(df_prime, function(x){
    cx <- paste(class(x), collapse=", ")
    lux <- length(unique(x))
    if(lux <= cat_cutoff)return("Categorical")
    if(lux < length(x) / 10)return("Large Categorical")
    if(cx == "character")return("Free Text")
    if(stringr::str_detect(cx, "POSIX"))return("DateTime")
    return(cx)
  })
  df_stats$format <- fmts
  
  df_stats$num_na <- sapply(df_prime, function(x)sum(is.na(x)))
  df_stats$n_distinct <- sapply(df_prime, dplyr::n_distinct)
  df_stats$levels <- sapply(df_prime, function(x){
                                        if(dplyr::n_distinct(x) <= cat_cutoff)return(paste(as.character(unique(x)), collapse=", "))
                                        return("")
                                      })
  df_stats$quantile_stats <- lapply(names(df_prime), 
                      function(x){
                        sx <- sort(df_prime[[x]])
                        n <- nrow(df_prime)
                        data.frame(
                          # min             = sx[1] %>% as.character(),
                          first_quartile  = sx[ceiling(n/4)] %>% as.character(),
                          median          = sx[ceiling(n/2)] %>% as.character(),
                          third_quartile  = sx[ceiling(3 * n/4)] %>% as.character()
                          # max             = sx[n] %>% as.character()
                        )
                      })
  
  df_stats <- df_stats %>% tidyr::unnest(quantile_stats)
  df_stats$information <- sapply(df_prime, score_vector_information)
  
  samples <- if(nrow(df_prime) < 3){
    dplyr::sample_n(df_prime, 3, replace = TRUE)
  }else{
    dplyr::sample_n(df_prime, 3)
  }
  
  # Retrieve the comments for each column in df
  df_stats$comments <- sapply(names(df), function(column_name){
    comment <- comment(df[[column_name]])
    # If there is no comment, return NA
    if(is.null(comment)) comment <- NA
    return(comment)
  })
  
  # If we have too many cols, filter out free text columns which are useless for EDA in most cases
  if (nrow(df_stats) > max_cols) {
    df_stats <- df_stats[!df_stats$type %in% c("Free Text"), ]
  }
  
  # If we still have too many cols, return the n cols with the least num_na and then most information
  if (nrow(df_stats) > max_cols) {
    df_stats <- df_stats[order(df_stats$num_na, -df_stats$information), ]
    df_stats <- df_stats[1:max_cols, ]
  }

  return(df_stats)
}

#' mi_matrix
#' Makes a mutual information matrix from the numeric columns in the input df.
#' 
#' @param df - the data frame to be analysed
#' 
#' @return A string representation of the the mutual information matrix of all numeric columns in the input df
#' which can be directly used for prompting.
mi_matrix <- function(df) {
  tryCatch({
    # Select numeric columns ignoring columns with less than 20 unique values
    numeric_columns <- df %>% 
      dplyr::select(where(~is.numeric(.x) && length(unique(.x)) >= 20))
    if (ncol(numeric_columns) < 2) {
      return("")
    }
    
    # Initialize an empty matrix to store mutual information values
    mi_values <- matrix(NA, ncol(numeric_columns), ncol(numeric_columns),
                        dimnames = list(colnames(numeric_columns), colnames(numeric_columns)))
    
    # Calculate mutual information for every pair of numeric columns
    for(i in 1:ncol(numeric_columns)) {
      for(j in 1:ncol(numeric_columns)) {
        if (i == j) {
          mi_values[i, j] <- 0
        } else {
          mi_values[i, j] <- infotheo::mutinformation(infotheo::discretize(numeric_columns[[i]]),
                                                      infotheo::discretize(numeric_columns[[j]]))
        }
      }
    }
    
    # Format the matrix as a string
    mi_matrix_string <- capture.output(print(mi_values))
    
    # Collapse the string vector into a single string
    mi_matrix_string <- paste(mi_matrix_string, collapse = "\n")
    
    return(mi_matrix_string)
  }, error = function(e) {
    warning(sprintf("MI matrix computation failed: %s", e$message))
    return("")
  })
}

#' significant_categorical_relationships
#' Uses a chi squared test to summarise significant categorical to categorical relationships in the input df.
#' 
#' @param df - the data frame to be analysed
#' @param summary_df - a summary of `df` generated using `summarise_df`
#' @param significance_level - the significance level above which relationships will discarded.
#'
#' @return Returns a string summarising significant categorical to categorical relationships and their p values
#' which can be directly used in prompting.
significant_categorical_relationships <- function(df, summary_df, significance_level = 0.05) {
  tryCatch({
    cat_cols <- unique(summary_df$name[summary_df$type %in% c("Categorical", "Large Categorical")])
    if (length(cat_cols) < 2) {
      return("None.")
    }
    significant_relationships <- character()
    
    for (i in 1:(length(cat_cols) - 1)) {
      for (j in (i + 1):length(cat_cols)) {
        contingency_table <- table(df[[cat_cols[i]]], df[[cat_cols[j]]])
        if (all(dim(contingency_table) == 2)) {
          # Use Fisher's Exact Test for 2x2 tables
          test <- fisher.test(contingency_table)
        } else {
          # Use Chi-squared test with simulated p-value for larger tables
          test <- chisq.test(contingency_table, simulate.p.value = TRUE, B = 2000)
        }
        
        if (!is.na(test$p.value) && test$p.value < significance_level) {
          significant_relationships <- c(significant_relationships, 
                                         paste(cat_cols[i], cat_cols[j], test$p.value, sep = ", "))
        }
      }
    }
    significant_relationships_str <- cat(paste(significant_relationships, collapse = "\n"))
    if (is.null(significant_relationships_str)) {
      return("None.")
    } else {
      return(trimws(significant_relationships_str))
    }
  }, error = function(e) {
    warning(sprintf("Signficant categoricals computation failed: %s", e$message))
    return("")
  })
}

#' significant_categorical_numeric_relationships
#' Uses an ANOVA test (or just a t-test if there are two levels) to summarise all significant relationships
#' between categorical and numeric variables.
#' 
#' @param df - the data frame to be analysed
#' @param summary_df - a summary of `df` generated using `summarise_df`
#' @param significance_level - the significance level above which relationships will discarded.
#' 
#' @return Returns a string summarising significant categorical to numeric relationships and their p values
#' which can be directly used in prompting.
significant_categorical_numeric_relationships <- function(df, summary_df, significance_level = 0.05) {
  tryCatch({
    results <- c()
    for(cat_col in summary_df$name[summary_df$type %in% c("Categorical", "Large Categorical")]) {
      for(num_col in names(df)[sapply(df, is.numeric)]) {
        if(!(num_col %in% summary_df$name[summary_df$type %in% c("Categorical", "Large Categorical")])) {
          levels <- length(unique(df[[cat_col]]))
          
          # If only two levels, use t-test
          if(levels < 3) {
            t_test_result <- t.test(df[[num_col]] ~ df[[cat_col]], data = df)
            p_value <- t_test_result$p.value
          } else { # If more than two levels, use ANOVA
            anova_result <- aov(df[[num_col]] ~ df[[cat_col]], data = df)
            p_value <- summary(anova_result)[[1]]$"Pr(>F)"[1]
          }
          
          # Check for significance
          if(p_value < significance_level) {
            result <- sprintf("%s, %s, %.2e", cat_col, num_col, p_value)
            results <- c(results, result)
          }
        }
      }
    }
    
    significant_relationships <- paste(results, collapse = "\n")
    if (nchar(significant_relationships) == 0) {
      return("None.")
    } else {
      return(trimws(significant_relationships))
    }
  }, error = function(e) {
    warning(sprintf("Signficant categorical to numerical computation failed: %s", e$message))
    return("")
  })
}

#' score_vector_information
#' Assign a score to a vector that is low if the vector has lots of repeats
#' and higher if the vector has more variation.
#' The score is the entropy of the histogram (counts) of the vector
#' @param vec vector of characters or factors. Not really intended for numeric data.
#' 
#' @return A single number, the score of the vector
score_vector_information <- function(vec) 
{
  histvec <- table(vec, useNA = "ifany")
  p = histvec/sum(histvec)
  return(-sum(p * base::log(p, base = 2)))
}

#' autoconvert_dataframe
#' 
#' Detect and apply data converters to a dataframe. Specifically will analyse all character columns and see if they match known formats, and convert them if they do.
#' This function is useful in an EDA, but be cautious deploying it in production, since it makes assumptions on the fly.
#'
#' @param df : The dataframe to convert.
#' @param exclusions : columns to explicity exclude from the auto-conversion
#'
#' @return : a named list with two elements: `df` is the input dataframe with all conversions applied and `formats` is a vector of detected formats for the columns of `df`
autoconvert_dataframe <- function(df, exclusions = NULL){
  cat("Resolving column names and bad duplications\n")
  names(df) <- get_standardised_names(names(df), resolve_duplicates = TRUE)
  cat("Replacing char pseudonulls...\n")
  df <- replace_char_pseudonulls(df)
  
  colnames <- names(df)
  coltypes <- sapply(df, function(x)paste(class(x), collapse=","))
  
  charcols <- colnames[coltypes == "character" & !(colnames %in% exclusions)]
  
  formats <- rep("", ncol(df))
  names(formats) <- names(df)
  
  cat("Identifying and applying converters...\n")
  converters <- get_all_converters()
  for(i in charcols){
    if(!all(is.na(df[[i]]))){
      for(fmt in names(converters)){
        cvt <- converters[[fmt]]
        if(all(cvt$is_match(df[[i]]), na.rm = TRUE)){
          formats[[i]] <- fmt
          df[[i]] <- cvt$method(df[[i]])
          break
        }
      }
    }
  }
  formats[coltypes == "numeric"] <- "standard_numeric"
  formats[coltypes == "integer"] <- "standard_integer"
  
  cat("Done.\n")
  return(list(df=df, formats = unlist(formats)))
}

#' get_standardised_names
#'
#' Description converts a vector containing names with camel-case, comma, period and underscore case,  
#' and converts them to snake_case. You might want to use this function over snakecase::to_snake_case(n) where is large,
#' or speed is a concern. This function is 10 times faster than snake_case::to_snake_case(n):
#'       v <- rep("this      is ....%/ a\\tstring", 100000)
#'       system.time(snakecase::to_snake_case(v))
#'        user  system elapsed 
#'         2.685   0.000   2.684 
#'       system.time(get_standardised_names(v))
#'          user  system elapsed 
#'         0.385   0.003   0.389
#'
#' @param name_vec - A character vector containing names to be converted.
#' @param remove_nas - If TRUE, will remove NA elements from the returned vector.
#' @param resolve_duplicates - If TRUE, will replace duplicated names with name, index pairs. E.g. "x", "x" -> "x.1", "x.2"
#'
#' @return - A character vector containing the converted (snake_case) names.
#'
#' @examples
#'\dontrun{
#' v <- c("ggGG", "GG", "gg", "G_G", "g,g","g.g", "g:g")
#' get_standardised_names(v)
#' # [1] "gggg" "gg"   "gg"   "g_g"  "g_g"  "g_g"  "g_g" 
#'}
get_standardised_names <- function(name_vec, remove_nas = FALSE, resolve_duplicates=FALSE){
  result <- unlist(name_vec, use.names=FALSE) %>%
    tolower() %>%
    stringr::str_replace_all("[:punct:]", " ") %>%
    stringr::str_squish() %>%
    stringr::str_replace_all("[:space:]", "_")
  
  if(remove_nas){
    result <- result[!is.na(result)]
  }
  
  if(resolve_duplicates){
    interrim <- data.frame(snam = result, idx = seq_along(result)) %>%
      dplyr::group_by_at("snam") %>%
      dplyr::mutate(r = seq_len(dplyr::n())) %>%
      dplyr::ungroup() %>%
      dplyr::arrange_at("idx")
    
    ifelse(interrim$r == 1, interrim$snam, paste(interrim$snam, interrim$r, sep="."))
  }else{
    result
  }
}

#' replace_char_pseudonulls
#' Replaces pseudonulls with NA in the type-char columns of a data frame
#'
#' @param df - the data frame to be analyzed
#'
#' @return the original data frame with the char columns transformed so that pseudonulls are replaced with nulls
replace_char_pseudonulls <- function(df){
  colnames <- names(df)
  coltypes <- sapply(df, function(x)paste(class(x), collapse=","))
  
  charcols <- colnames[coltypes == "character"]
  for(col in charcols){
    # convert weird unicode to ascii
    Encoding(df[[col]]) -> 'latin1'
    df[[col]] <- stringi::stri_trans_general(df[[col]], 'Latin-ASCII')
    
    # now find the null elements and replace with NA
    actually_null <- stringr::str_detect(toupper(stringr::str_trim(df[[col]])), "^NULL$|^N/A$|^\\?$|^\\.$|^\\-$|^$")
    df[[col]][actually_null] <- NA
  }
  return(df)
}

#' get_all_converters
#' 
#' get all converter functions to be used in summary stats & tidy dfs
#'
#' @return : a named list of converter-lists, each of which has an is_match function and a method function for conversion
get_all_converters <- function(){
  c(
    numeric_converters(), 
    date_converters(), 
    list(text = list(is_match=function(x)return(TRUE), method=as.character)) # fallback function
  )
}

#' numeric_converters
#' 
#' Get checker & converter functions for numeric types
#'
#' @return : Named list. Each element of the list is another list with names (is_match, method). The former is a predicate function that determines if a given vector matches the target type
#' and the latter is a converter function that converts the vector to a numeric type according to a specific pattern.
numeric_converters <- function(){
  list(
    standard_integer = list(is_match=check_standard_integer, method=as.integer),
    standard_numeric = list(is_match=check_standard_numeric, method=convert_standard_numeric),
    comma_sep_numeric = list(is_match=check_comma_sep, method=convert_comma_sep),
    sap_number = list(is_match=check_sap_number, method=convert_sap_number)
  )
}

check_standard_integer <- function(x) {
  regex_match_all(x, "^\\-?\\d+$") && all(is.na(x) | stringr::str_length(x) < 
                                            9)
}

check_standard_numeric <- function(x) {
  regex_match_all(toupper(x), "^\\-?\\d*(\\.)*\\d*(E(\\-?\\+?)\\d+)?\\-?$") && 
    all(is.na(x) | stringr::str_length(x) < 24)
}

convert_standard_numeric <- function(x) {
  ifelse(stringr::str_detect(x, "^\\-|\\-$"), -1, 1) * as.numeric(stringr::str_replace_all(x, 
                                                                                           "^\\-|\\-$", ""))
}

check_comma_sep <- function(x) {
  regex_match_all(x, "^\\-?\\d+(\\,\\d\\d\\d)*(\\.\\d+)?(E(\\-?)\\d+)?\\-?$")
}

convert_comma_sep <- function(x) {
  ifelse(stringr::str_detect(x, "^\\-|\\-$"), -1, 1) * as.numeric(stringr::str_replace_all(x, 
                                                                                           ",|^\\-|\\-$", ""))
}

check_sap_number <- function(x) {
  regex_match_all(x, "^\\-?\\d+(\\.\\d\\d\\d)*(\\,\\d+)?\\-?$")
}

convert_sap_number <- function(x) {
  ifelse(stringr::str_detect(x, "^\\-|\\-$"), -1, 1) * as.numeric(stringr::str_replace_all(x, 
                                                                                           c(`\\.|^\\-|\\-$` = "", `\\,` = ".")))
}

#' date_converters
#' 
#' Returns all the converter objects for date formats
#'
#' @return : named list of <is_match, method> pairs
date_converters <- function(){
  dd <- "(0?[1-9])|([1-2]\\d)|(3[0-1])"
  mm <- "(0?[1-9])|(1[0-2])"
  yyyy <- "[1-2]\\d\\d\\d"
  HM <- "(0|1|2|3|4|5)\\d"
  S <- "(0|1|2|3|4|5)?\\d(\\.\\d+)?"
  dsep <- "\\-|\\.|\\/"
  
  yyyymmdd <- sprintf("^(%2$s)(%1$s)(%3$s)(%1$s)(%4$s)$", dsep, yyyy,mm,dd)
  ddmmyyyy <- sprintf("^(%2$s)(%1$s)(%3$s)(%1$s)(%4$s)$", dsep, dd,mm,yyyy)
  mmddyyyy <- sprintf("^(%2$s)(%1$s)(%3$s)(%1$s)(%4$s)$", dsep, mm,dd,yyyy)
  yyyymmddhm <- sprintf("^(%2$s)(%1$s)(%3$s)(%1$s)(%4$s)( )(%5$s)(\\:)(%6$s)$", dsep, yyyy,mm,dd, HM, HM)
  yyyymmddhms <- sprintf("^(%2$s)(%1$s)(%3$s)(%1$s)(%4$s)( )(%5$s)(\\:)(%6$s)(\\:)(%7$s)$", dsep, yyyy,mm,dd, HM, HM, S)
  
  list(
    date_yyyymmdd = list(
      is_match = function(x) regex_match_all(x, yyyymmdd),
      method = function(x) as.Date(stringr::str_replace_all(x, "\\-|\\.|\\/", "-"))
    ),
    date_yyyymmddhm = list( # YYYY-MM-DD H:M
      is_match = function(x) regex_match_all(x, yyyymmddhm), 
      method = function(x)as.POSIXct(stringr::str_replace_all(x, dsep, "-"))
    ),
    date_ddmmyyyy = list( # DD-MM-YYYY
      is_match = function(x) regex_match_all(x, ddmmyyyy),
      method = function(x) as.Date(strptime(stringr::str_replace_all(x, dsep, "-"), format="%d-%m-%Y"))
    ),
    date_mmddyyyy = list( # DD-MM-YYYY
      is_match = function(x) regex_match_all(x, mmddyyyy),
      method = function(x) as.Date(strptime(stringr::str_replace_all(x, dsep, "-"), format="%m-%d-%Y"))
    ),
    date_yyyymmddhms = list( # YYYY-MM-DD H:M:S
      is_match = function(x) regex_match_all(x, yyyymmddhms),
      method = function(x)as.POSIXct(stringr::str_replace_all(x, dsep, "-"))
    )
  )
}

regex_match_all <- function(v, regexpr) {
  all(stringr::str_detect(v, regexpr))
}