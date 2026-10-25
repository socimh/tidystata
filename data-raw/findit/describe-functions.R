# Refresh titles for newly referenced function/package pairs from installed help.
# Run through the protected launcher; it never installs or attaches packages.
scope <- new.env(parent = baseenv())
source("R/findit.R", local = scope, encoding = "UTF-8")
read_utf8 <- function(path) {
  as.data.frame(readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    na = character(),
    locale = readr::locale(encoding = "UTF-8"),
    progress = FALSE
  ))
}
entries <- read_utf8("inst/extdata/stata-to-r.csv")
dictionary <- read_utf8("data-raw/findit/functions.csv")
stopifnot(nrow(entries) > 0L, nrow(dictionary) > 0L)
help_cache <- new.env(parent = emptyenv())
title <- function(package, name) {
  if (is.null(help_cache[[package]])) {
    help_cache[[package]] <- tryCatch(
      tools::Rd_db(package),
      error = function(error) list()
    )
  }
  pages <- help_cache[[package]]
  for (page in pages) {
    tags <- vapply(page, function(node) attr(node, "Rd_tag"), character(1))
    aliases <- unlist(page[tags == "\\alias"], use.names = FALSE)
    if (name %in% aliases) {
      text <- unlist(page[tags == "\\title"], use.names = FALSE)
      return(trimws(gsub("[[:space:]]+", " ", paste(text, collapse = ""))))
    }
  }
  ""
}
for (i in seq_len(nrow(entries))) {
  row <- entries[i, ]
  functions <- scope$findit_calls(row$r)[[1L]]
  calls <- regmatches(
    row$r,
    gregexpr(
      "[A-Za-z][A-Za-z0-9.]*::[A-Za-z_.][A-Za-z0-9_.]*(?=[(])",
      row$r,
      perl = TRUE
    )
  )[[1L]]
  for (name in functions) {
    explicit <- calls[sub("^.*::", "", calls) == name]
    packages <- unique(sub("::.*$", "", explicit))
    if (!length(packages)) {
      if (name %in% dictionary$`function`) {
        next
      }
      packages <- if (exists(name, baseenv(), inherits = FALSE)) {
        "base"
      } else {
        if (exists(name, asNamespace("stats"), inherits = FALSE)) {
          "stats"
        } else {
          row$package
        }
      }
    }
    for (package in packages) {
      if (any(dictionary$`function` == name & dictionary$package == package)) {
        next
      }
      description <- title(package, name)
      if (!nzchar(description)) {
        stop("No official help title for ", package, "::", name, " in ", row$id)
      }
      new <- data.frame(
        "function" = name,
        package = package,
        description = description,
        description_zh = paste0("\u793a\u4f8b\u7528\u9014\uff1a", row$task_zh),
        stata = row$command,
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
      dictionary <- rbind(dictionary, new)
    }
  }
}
readr::write_csv(dictionary, "data-raw/findit/functions.csv", na = "")
cat(nrow(dictionary), "function/package pairs.\n")
