#' Test Runner for Automated esttab Testing
#' 
#' Core test execution logic with comprehensive error capture

#' Run a single test scenario
#' 
#' @param scenario_id Unique identifier for the test
#' @param description Human-readable description
#' @param test_code R code to execute
#' @param category Test category (basic, edge_case, formatting, etc.)
#' @param expected_result Expected outcome: "success", "warning", or "error"
#' @return List with test results
run_test_scenario <- function(scenario_id, description, test_code, 
                               category = "general", expected_result = "success") {
  
  test_env <- new.env(parent = globalenv())
  result <- list(
    id = scenario_id,
    description = description,
    category = category,
    test_code = test_code,
    expected_result = expected_result,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    status = "PENDING",
    output = NULL,
    error = NULL,
    warning = NULL,
    execution_time = NULL
  )
  
  # Copy functions to test environment
  tryCatch({
    test_env$esttab <- get("esttab", envir = globalenv())
    test_env$s_try <- get("s_try", envir = globalenv())
  }, error = function(e) {
    # Functions not in global env, ignore
  })
  
  start_time <- Sys.time()
  
  # Execute test with comprehensive error capture
  output_capture <- NULL
  warning_list <- list()
  test_error <- NULL
  test_result <- NULL
  
  # Try to execute the test code
  try_result <- tryCatch({
    withCallingHandlers({
      output_capture <- capture.output({
        test_result <- eval(parse(text = test_code), envir = test_env)
      }, type = "output")
      "success"
    }, warning = function(w) {
      warning_list[[length(warning_list) + 1]] <<- list(
        message = conditionMessage(w),
        call = deparse(conditionCall(w))
      )
      invokeRestart("muffleWarning")
    }, error = function(e) {
      test_error <<- list(
        message = conditionMessage(e),
        call = deparse(conditionCall(e))[1],
        class = class(e),
        trace = utils::capture.output({
          try(traceback(max.lines = 5), silent = TRUE)
        })
      )
      "error"
    })
  }, error = function(e) {
    # Fallback error capture
    test_error <<- list(
      message = conditionMessage(e),
      call = deparse(conditionCall(e))[1],
      class = class(e),
      trace = "Traceback not available"
    )
    "error"
  })
  
  end_time <- Sys.time()
  result$execution_time <- as.numeric(end_time - start_time, units = "secs")
  
  # Determine status based on result
  if (!is.null(test_error)) {
    result$status <- "FAIL"
    result$error <- test_error
    result$output <- paste(output_capture, collapse = "\n")
    
    # Check if error was expected
    if (expected_result == "error") {
      result$status <- "PASS (Expected Error)"
    }
  } else {
    result$status <- "PASS"
    result$obj <- test_result
    result$output <- paste(output_capture, collapse = "\n")
  }
  
  if (length(warning_list) > 0) {
    result$warning <- warning_list
    if (result$status == "PASS") {
      result$status <- "WARNING"
    }
  }
  
  return(result)
}

#' Run complete test suite
#' 
#' @param scenarios List of test scenario definitions
#' @param verbose Print progress messages
#' @return List of all test results
run_test_suite <- function(scenarios, verbose = TRUE) {
  results <- list()
  total <- length(scenarios)
  
  if (verbose) message(sprintf("\n=== Starting Test Suite: %d Scenarios ===", total))
  
  for (i in seq_along(scenarios)) {
    scen <- scenarios[[i]]
    if (verbose) message(sprintf("\n[%d/%d] %s: %s", i, total, scen$id, scen$description))
    
    result <- run_test_scenario(
      scenario_id = scen$id,
      description = scen$description,
      test_code = scen$code,
      category = scen$category %||% "general",
      expected_result = scen$expected %||% "success"
    )
    
    results[[i]] <- result
    
    if (verbose) {
      status_msg <- switch(result$status,
        "PASS" = "✓ PASS",
        "FAIL" = "✗ FAIL",
        "WARNING" = "⚠ WARNING",
        "PASS (Expected Error)" = "✓ PASS (Expected Error)",
        paste("?", result$status)
      )
      message(sprintf("    %s (%.3fs)", status_msg, result$execution_time))
    }
  }
  
  if (verbose) {
    passes <- sum(sapply(results, function(r) grepl("PASS", r$status)))
    fails <- sum(sapply(results, function(r) r$status == "FAIL"))
    warnings <- sum(sapply(results, function(r) r$status == "WARNING"))
    
    message(sprintf("\n=== Test Suite Complete ==="))
    message(sprintf("Results: %d PASS, %d FAIL, %d WARNING", passes, fails, warnings))
  }
  
  return(results)
}

#' Helper: NULL default operator
`%||%` <- function(x, y) if (is.null(x)) y else x
