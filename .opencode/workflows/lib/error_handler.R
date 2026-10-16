#' Error Handler for Automated esttab Testing
#' 
#' Structured error capture, categorization, and logging

library(jsonlite)

#' Categorize error by severity and type
#' 
#' @param error_list Error information from test result
#' @param scenario_id Test scenario identifier
#' @return Categorized error information
categorize_error <- function(error_list, scenario_id) {
  if (is.null(error_list)) return(NULL)
  
  error_msg <- tolower(error_list$message)
  
  # Determine severity
  severity <- "MEDIUM"  # Default
  
  # HIGH severity: crashes, data corruption, missing essential functionality
  high_patterns <- c(
    "does not work", "not found", "cannot", "unable",
    "subscript out of bounds", "non-numeric", "infinite recursion",
    "missing essential columns", "data corruption"
  )
  
  # LOW severity: cosmetic, formatting, warnings
  low_patterns <- c(
    "deprecated", "experimental", "naming", "cosmetic",
    "format", "spacing", "alignment"
  )
  
  if (any(sapply(high_patterns, function(p) grepl(p, error_msg)))) {
    severity <- "HIGH"
  } else if (any(sapply(low_patterns, function(p) grepl(p, error_msg)))) {
    severity <- "LOW"
  }
  
  # Determine category
  category <- "General"
  if (grepl("broom|tidy|glance", error_msg)) {
    category <- "Model Tidying"
  } else if (grepl("format|sprintf|glue", error_msg)) {
    category <- "Formatting"
  } else if (grepl("stat|glance|stats", error_msg)) {
    category <- "Statistics"
  } else if (grepl("column|select|name", error_msg)) {
    category <- "Output Structure"
  } else if (grepl("glm|lm|lmer|glmer", error_msg)) {
    category <- "Model Support"
  }
  
  # Generate unique error signature for duplicate detection
  error_sig <- digest::digest(paste(scenario_id, error_msg), algo = "xxhash32")
  
  return(list(
    severity = severity,
    category = category,
    signature = error_sig,
    message = error_list$message,
    call = error_list$call,
    class = error_list$class,
    trace = error_list$trace
  ))
}

#' Log errors to JSON file
#' 
#' @param test_results List of test results
#' @param log_file Path to JSON log file
#' @return Updated error log (invisible)
log_errors <- function(test_results, log_file = ".opencode/reports/esttab_error_log.json") {
  
  # Extract failed tests
  failed_tests <- Filter(function(r) r$status == "FAIL", test_results)
  
  if (length(failed_tests) == 0) {
    message("No errors to log.")
    return(invisible(NULL))
  }
  
  # Build error entries
  error_entries <- lapply(failed_tests, function(result) {
    cat_error <- categorize_error(result$error, result$id)
    list(
      timestamp = result$timestamp,
      scenario_id = result$id,
      description = result$description,
      test_code = result$test_code,
      category = cat_error$category,
      severity = cat_error$severity,
      signature = cat_error$signature,
      error_message = cat_error$message,
      error_call = cat_error$call,
      error_class = cat_error$class,
      stack_trace = cat_error$trace,
      status = "NEW"
    )
  })
  
  # Read existing log or create new
  if (file.exists(log_file)) {
    existing_log <- fromJSON(log_file, flatten = FALSE)
    # Filter out duplicates based on signature
    existing_sigs <- sapply(existing_log$errors, function(e) e$signature)
    new_errors <- Filter(function(e) !(e$signature %in% existing_sigs), error_entries)
    
    if (length(new_errors) > 0) {
      all_errors <- c(existing_log$errors, new_errors)
      log_data <- list(
        last_updated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        total_errors = length(all_errors),
        new_errors = length(new_errors),
        errors = all_errors
      )
      message(sprintf("Added %d new error(s) to log.", length(new_errors)))
    } else {
      log_data <- list(
        last_updated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        total_errors = length(existing_log$errors),
        new_errors = 0,
        errors = existing_log$errors
      )
      message("No new errors (all are duplicates).")
    }
  } else {
    log_data <- list(
      last_updated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      total_errors = length(error_entries),
      new_errors = length(error_entries),
      errors = error_entries
    )
    message(sprintf("Created new error log with %d error(s).", length(error_entries)))
  }
  
  # Write to JSON
  write_json(log_data, log_file, pretty = TRUE, auto_unbox = TRUE)
  
  return(invisible(log_data))
}

#' Get summary of current errors
#' 
#' @param log_file Path to JSON log file
#' @return Summary statistics
get_error_summary <- function(log_file = ".opencode/reports/esttab_error_log.json") {
  if (!file.exists(log_file)) {
    return(list(total = 0, by_severity = list(), by_category = list()))
  }
  
  log_data <- fromJSON(log_file, flatten = FALSE)
  errors <- log_data$errors
  
  list(
    total = length(errors),
    new_errors = sum(sapply(errors, function(e) e$status == "NEW")),
    by_severity = table(sapply(errors, function(e) e$severity)),
    by_category = table(sapply(errors, function(e) e$category)),
    by_status = table(sapply(errors, function(e) e$status))
  )
}
