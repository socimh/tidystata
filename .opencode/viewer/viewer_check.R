# Source this file in an interactive editor session; run one case at a time.
# Contract checks do not establish that a viewer opened or rendered correctly.
run_viewer_check <- function(
  candidate_library,
  candidate_id,
  editor_version,
  case = c("selected", "all", "grouped")
) {
  if (!interactive()) {
    stop(
      "Manual viewer check requires interactive R in RStudio or VS Code.",
      call. = FALSE
    )
  }
  case <- match.arg(case)
  if (!nzchar(candidate_id) || !nzchar(editor_version)) {
    stop("Supply the candidate identifier and editor version.", call. = FALSE)
  }
  candidate_library <- normalizePath(candidate_library, mustWork = TRUE)
  candidate_path <- normalizePath(
    file.path(candidate_library, "statart"),
    mustWork = TRUE
  )
  .libPaths(c(candidate_library, .libPaths()))
  loadNamespace("statart", lib.loc = candidate_library)
  loaded_path <- normalizePath(
    getNamespaceInfo(asNamespace("statart"), "path"),
    mustWork = TRUE
  )
  if (!identical(candidate_path, loaded_path)) {
    stop("Another statart is loaded. Restart R and select this library first.")
  }

  survey <- tibble::tibble(
    id = 1:3,
    score = c(4, NA, 8),
    group = c("A", "A", "B")
  )
  attr(survey$score, "label") <- "Assessment score"
  original <- survey

  if (case == "selected") {
    result <- withVisible(statart::browse(survey, id, score))
    expected <- survey[c("id", "score")]
  } else if (case == "all") {
    result <- withVisible(statart::browse(survey))
    expected <- survey
  } else {
    grouped <- dplyr::group_by(survey, group)
    original_grouped <- grouped
    result <- withVisible(statart::browse(grouped, score))
    expected <- dplyr::group_by(survey[c("group", "score")], group)
    stopifnot(
      identical(grouped, original_grouped),
      identical(dplyr::group_vars(result$value), "group")
    )
  }

  stopifnot(
    identical(result$value, expected),
    identical(result$visible, FALSE),
    identical(attr(result$value$score, "label"), "Assessment score"),
    identical(survey, original)
  )
  observation <- list(
    observed_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    candidate_id = candidate_id,
    package_version = as.character(utils::packageVersion("statart")),
    package_path = loaded_path,
    r_version = R.version.string,
    platform = R.version$platform,
    editor_version = editor_version,
    case = case,
    expected_columns = names(expected),
    expected_rows = nrow(expected),
    return_contracts = "passed",
    gui_observation = "pending manual observation"
  )
  print(observation)
  message(
    "Inspect the editor viewer and record its actual appearance separately."
  )
  invisible(observation)
}
