summarise_df <- function(df, remove_cols=TRUE, max_cols=10) {
  df_stats <- data.frame(name = names(df))
  df_and_fmt <- himunge::autoconvert_dataframe(df)
  df_prime <- df_and_fmt$df
  fmts <- df_and_fmt$formats
  # Use original names
  names(df_prime) <- names(df)
  names(fmts) <- names(df)

  # Convert ints with less than 10 values to text so they can be used as categoricals
  df_prime[] <- lapply(names(df_prime), function(col_name) {
    x <- df_prime[[col_name]]
    if(length(unique(x)) <= 10) {
      df_prime[[col_name]] <- as.character(x)
      fmts[[col_name]] <<- "text"
    }
    return(df_prime[[col_name]])
  })
  
  cat_cutoff <- pmax(nrow(df_prime)/10000, 20)
  df_stats$type <- sapply(df_prime, function(x){
    cx <- paste(class(x), collapse=", ")
    lux <- length(unique(x))
    if(cx == "character" & lux <= cat_cutoff)return("Categorical")
    if(cx == "character" & lux < length(x) / 10)return("Large Categorical")
    if(cx == "character")return("Free Text")
    if(stringr::str_detect(cx, "POSIX"))return("DateTime")
    return(cx)
  })
  df_stats$format <- fmts
  
  df_stats$num_na <- sapply(df_prime, function(x)sum(is.na(x)))
  df_stats$n_distinct <- sapply(df_prime, dplyr::n_distinct)
  # df_stats$is_identifier <- (df_stats$n_distinct == df_stats$count) && df_stats$type
  # df_stats$levels <- sapply(df_prime, function(x){
  #                                       if(dplyr::n_distinct(x) <= cat_cutoff)return(paste(as.character(unique(x)), collapse=", "))
  #                                       return("")
  #                                     })
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
  
  # df_stats$mean <- sapply(df_prime, function(x) if (is.numeric(x)) mean(x, na.rm = TRUE) else NA)
  
  df_stats <- df_stats %>% tidyr::unnest(quantile_stats)
  df_stats$information <- sapply(df_prime, himunge::score_vector_information)
  
  samples <- if(nrow(df_prime) < 3){
    dplyr::sample_n(df_prime, 3, replace = TRUE)
  }else{
    dplyr::sample_n(df_prime, 3)
  }
  
  if (remove_cols) {
    # Filter out free text and primary key columns which are useless for EDA
    df_stats <- df_stats[!df_stats$type %in% c("Free Text"), ]
    # Filter out columns with no information (no entropy)
    df_stats <- df_stats[df_stats$information > 0, ]
    tryCatch({
      pk_cols <- himunge::find_primary_keys(df_prime, max_depth=1, timeout=30)
      # We are only looking for single-column primary keys, so if the returned primary key is longer
      # this means there was an error and all columns were returned
      if(length(pk_cols) == 0 || length(pk_cols[[1]]) > 1) {
        stop("Primary key not found")
      } else {
        log(sprintf("Filtering out the primary key columns: %s", paste(pk_cols, collapse = ", ")))
        df_stats_filtered <<- df_stats[!df_stats$name %in% unlist(pk_cols), ]
      }
    }, error = function(e) {
      log(sprintf("Error finding primary keys: %s", e$message))
      df_stats_filtered <<- df_stats
    })
    df_stats <- df_stats_filtered
  }
  
  if (nrow(df_stats) > max_cols) {
    # Returns the n rows with the lest num_na and then most information
    df_stats <- df_stats[order(df_stats$num_na, -df_stats$information), ]
    df_stats <- df_stats[1:max_cols, ]
  }

    # Remove columns from input df that were removed from df stats
  df_prime <- df_prime[, colnames(df_prime) %in% df_stats$name]
  return(list(clean_df = df_prime, df_stats = df_stats))
}

mi_matrix <- function(file_df) {
  tryCatch({
    # Select numeric columns ignoring columns with less than 20 unique values
    numeric_columns <- file_df %>% 
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

significant_categorical_relationships <- function(file_df, summary_df, significance_level = 0.05) {
  tryCatch({
    cat_cols <- unique(summary_df$name[summary_df$type %in% c("Categorical", "Large Categorical")])
    if (length(cat_cols) < 2) {
      return("None.")
    }
    significant_relationships <- character()
    
    for (i in 1:(length(cat_cols) - 1)) {
      for (j in (i + 1):length(cat_cols)) {
        contingency_table <- table(file_df[[cat_cols[i]]], file_df[[cat_cols[j]]])
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