#!/usr/bin/env Rscript
#' File Watcher Daemon for esttab.R
#' 
#' Continuously monitors R/esttab.R for changes and triggers
#' automated testing when modifications are detected.
#'
#' Usage:
#'   # Start watching
#'   source(".opencode/workflows/watch_esttab.R")
#'   watch_esttab_start()
#' 
#'   # Stop watching
#'   watch_esttab_stop()
#'
#' Note: This requires the 'later' package for background execution.

# --- Global state ---
watch_state <- new.env()
watch_state$is_running <- FALSE
watch_state$last_modified <- NULL
watch_state$watch_interval <- 2  # seconds
watch_state$handle <- NULL

#' Start watching esttab.R for changes
#' 
#' @param interval Check interval in seconds (default: 2)
#' @param verbose Print status messages
#' @return TRUE if started successfully
watch_esttab_start <- function(interval = 2, verbose = TRUE) {
  
  if (watch_state$is_running) {
    message("Watch daemon is already running. Stop it first with watch_esttab_stop()")
    return(FALSE)
  }
  
  # Check for required packages
  if (!requireNamespace("later", quietly = TRUE)) {
    message("Installing 'later' package for background execution...")
    install.packages("later", repos = "https://cloud.r-project.org/")
  }
  
  library(later)
  
  # Determine file path
  esttab_file <- "R/esttab.R"
  if (!file.exists(esttab_file)) {
    esttab_file <- "D:/R/statart/R/esttab.R"
  }
  
  if (!file.exists(esttab_file)) {
    stop("Could not find esttab.R file")
  }
  
  watch_state$esttab_file <- esttab_file
  watch_state$watch_interval <- interval
  watch_state$is_running <- TRUE
  watch_state$last_modified <- file.info(esttab_file)$mtime
  watch_state$run_count <- 0
  
  message("╔══════════════════════════════════════════════════════════════╗")
  message("║  esttab.R File Watcher Daemon                                ║")
  message("╚══════════════════════════════════════════════════════════════╝")
  message(sprintf("✓ Watching: %s", esttab_file))
  message(sprintf("✓ Check interval: %d seconds", interval))
  message(sprintf("✓ Last modified: %s", format(watch_state$last_modified)))
  message("\nDaemon is running. Press Ctrl+C or run watch_esttab_stop() to stop.")
  message("The test suite will automatically run when esttab.R is modified.\n")
  
  # Start the watcher loop
  schedule_watch_check(verbose)
  
  # Keep R session alive
  if (interactive()) {
    message("[Interactive mode - daemon running in background]")
  } else {
    # Non-interactive: wait indefinitely
    while(watch_state$is_running) {
      Sys.sleep(1)
    }
  }
  
  return(TRUE)
}

#' Schedule the next watch check
#' 
#' @param verbose Print status messages
schedule_watch_check <- function(verbose = TRUE) {
  if (!watch_state$is_running) return(NULL)
  
  later::later(function() {
    check_file_and_run(verbose)
    if (watch_state$is_running) {
      schedule_watch_check(verbose)
    }
  }, delay = watch_state$watch_interval)
}

#' Check if file modified and run tests if needed
#' 
#' @param verbose Print status messages
check_file_and_run <- function(verbose = TRUE) {
  if (!file.exists(watch_state$esttab_file)) {
    if (verbose) message(sprintf("[%s] Warning: esttab.R not found", format(Sys.time(), "%H:%M:%S")))
    return(NULL)
  }
  
  current_mtime <- file.info(watch_state$esttab_file)$mtime
  
  if (current_mtime > watch_state$last_modified) {
    watch_state$last_modified <- current_mtime
    watch_state$run_count <- watch_state$run_count + 1
    
    message(sprintf("\n[%s] 📝 File modified: %s", 
      format(Sys.time(), "%H:%M:%S"),
      format(current_mtime)))
    message(sprintf("[%s] 🚀 Auto-triggering test suite (run #%d)...\n", 
      format(Sys.time(), "%H:%M:%S"),
      watch_state$run_count))
    
    # Run the automation script
    tryCatch({
      automation_script <- ".opencode/workflows/esttab_automation.R"
      if (!file.exists(automation_script)) {
        automation_script <- "D:/R/statart/.opencode/workflows/esttab_automation.R"
      }
      
      source(automation_script)
      
      message(sprintf("\n[%s] ✓ Test suite complete. Watching for changes...\n", 
        format(Sys.time(), "%H:%M:%S")))
      
    }, error = function(e) {
      message(sprintf("\n[%s] ✗ Error running test suite: %s\n", 
        format(Sys.time(), "%H:%M:%S"),
        e$message))
    })
  }
}

#' Stop the watch daemon
#' 
#' @return TRUE if stopped successfully
watch_esttab_stop <- function() {
  if (!watch_state$is_running) {
    message("Watch daemon is not running.")
    return(FALSE)
  }
  
  watch_state$is_running <- FALSE
  if (!is.null(watch_state$handle)) {
    try(later::cancel(watch_state$handle), silent = TRUE)
  }
  
  message(sprintf("\n[%s] Watch daemon stopped.", format(Sys.time(), "%H:%M:%S")))
  message(sprintf("Total runs: %d", watch_state$run_count %||% 0))
  
  return(TRUE)
}

#' Get current watcher status
#' 
#' @return List with status information
watch_esttab_status <- function() {
  list(
    is_running = watch_state$is_running,
    file = watch_state$esttab_file %||% NULL,
    last_modified = watch_state$last_modified %||% NULL,
    run_count = watch_state$run_count %||% 0,
    check_interval = watch_state$watch_interval %||% NULL
  )
}

#' Run tests once immediately (without watching)
#' 
#' @return Test results
watch_esttab_run_now <- function() {
  automation_script <- ".opencode/workflows/esttab_automation.R"
  if (!file.exists(automation_script)) {
    automation_script <- "D:/R/statart/.opencode/workflows/esttab_automation.R"
  }
  
  source(automation_script)
}

#' Helper: NULL default operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# --- Auto-start if called from command line ---
if (!interactive()) {
  # Called from command line
  args <- commandArgs(trailingOnly = TRUE)
  
  if ("--run-once" %in% args) {
    watch_esttab_run_now()
  } else if ("--stop" %in% args) {
    message("To stop the daemon, run watch_esttab_stop() from the same R session")
  } else {
    # Default: start watching
    watch_esttab_start(interval = 2, verbose = TRUE)
  }
}
