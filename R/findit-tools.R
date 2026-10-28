#' Look up Stata text from the editor or clipboard
#'
#' Look up one Stata command using the same catalogue and variable customization
#' as [findit()]. The result is printed in the console. Source text and clipboard
#' contents are preserved; no command or returned example is executed.
#'
#' `findit_selection()` reads highlighted text in the source editor. It is also
#' registered as the **Find Stata equivalent** addin. It requires the optional
#' rstudioapi package and an editor providing its source-selection API, such as
#' RStudio or a compatible Positron session.
#'
#' `findit_clip()` reads text copied to the clipboard, for example from a
#' do-file. It requires the optional clipr package and access to a text clipboard.
#'
#' @returns The [findit()] result, invisibly, after printing it once.
#' @seealso [findit()]
#' @examples
#' \dontrun{
#' # Highlight tab sex region, row in the source editor, then run:
#' findit_selection()
#'
#' # Copy tab sex region, row to the clipboard, then run:
#' findit_clip()
#' }
#' @export
findit_selection <- function() {
  findit_text_result(findit_editor_selection())
}

#' @rdname findit_selection
#' @export
findit_clip <- function() {
  findit_text_result(findit_clipboard_text())
}

findit_text_result <- function(text) {
  if (is.character(text) && length(text) && !anyNA(text)) {
    text <- trimws(paste(text, collapse = "\n"))
  }
  if (
    !rlang::is_string(text) ||
      !nzchar(text) ||
      grepl("[\r\n]", text) ||
      ";" %in% findit_text_tokens(text)
  ) {
    cli::cli_abort("Select or copy one nonempty Stata command.")
  }
  result <- findit(!!text)
  print(result)
  invisible(result)
}

findit_editor_selection <- function() {
  if (!requireNamespace("rstudioapi", quietly = TRUE)) {
    cli::cli_abort("Install {.pkg rstudioapi} to look up selected Stata text.")
  }
  if (!rstudioapi::hasFun("getSourceEditorContext")) {
    cli::cli_abort("A supported source-editor selection API is required.")
  }
  context <- tryCatch(
    rstudioapi::getSourceEditorContext(),
    error = function(e) {
      cli::cli_abort(
        "Cannot read the source-editor selection: {conditionMessage(e)}"
      )
    }
  )
  if (length(context$selection) != 1L) {
    cli::cli_abort("Select or copy one nonempty Stata command.")
  }
  context$selection[[1L]]$text
}

findit_clipboard_text <- function() {
  if (!requireNamespace("clipr", quietly = TRUE)) {
    cli::cli_abort("Install {.pkg clipr} to look up copied Stata text.")
  }
  tryCatch(clipr::read_clip(), error = function(e) {
    cli::cli_abort("Cannot read the clipboard: {conditionMessage(e)}")
  })
}
