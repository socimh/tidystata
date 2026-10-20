# Run in a fresh session against an installation of the final source bundle.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Supply candidate library, source tarball and installation receipt.")
}
if (!file.exists(file.path(args[[1L]], "statart", "DESCRIPTION"))) {
  stop("Candidate installation is missing from the supplied library.")
}
if (!file.exists(args[[3L]])) {
  stop("Installation receipt is missing.")
}
if (!file.exists(args[[2L]])) {
  stop("Source tarball is missing.")
}
receipt <- jsonlite::read_json(args[[3L]], simplifyVector = TRUE)
fields <- c(
  "tarball",
  "tarball_sha256",
  "tarball_md5",
  "bundle_library",
  "package",
  "version"
)
if (
  !all(vapply(
    receipt[fields],
    function(x) {
      is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
    },
    logical(1)
  ))
) {
  stop("Installation receipt must contain all required identity fields.")
}
candidate_library <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
tarball <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)
if (
  !identical(
    normalizePath(receipt$bundle_library, winslash = "/", mustWork = TRUE),
    candidate_library
  )
) {
  stop("Receipt library does not match the supplied candidate library.")
}
if (
  !identical(
    normalizePath(receipt$tarball, winslash = "/", mustWork = TRUE),
    tarball
  )
) {
  stop("Receipt tarball does not match the supplied source archive.")
}
if (
  !grepl("^[[:xdigit:]]{64}$", receipt$tarball_sha256) ||
    !identical(unname(tools::md5sum(tarball)), tolower(receipt$tarball_md5))
) {
  stop("Archive checksum does not match the installation receipt.")
}
if (!identical(receipt$package, "statart")) {
  stop("Installation receipt is for a different package.")
}
contents <- utils::untar(tarball, list = TRUE)
description_member <- "statart/DESCRIPTION"
if (sum(contents == description_member) != 1L) {
  stop("Source archive must contain exactly one statart DESCRIPTION.")
}
bundle_directory <- tempfile("statart-bundle-description-")
dir.create(bundle_directory)
utils::untar(tarball, files = description_member, exdir = bundle_directory)
bundle_desc <- read.dcf(file.path(bundle_directory, description_member))
expected_path <- normalizePath(
  file.path(candidate_library, "statart"),
  winslash = "/",
  mustWork = TRUE
)
installed_desc <- read.dcf(file.path(expected_path, "DESCRIPTION"))
identity <- c(Package = receipt$package, Version = receipt$version)
if (
  !identical(bundle_desc[1L, names(identity)], identity) ||
    !identical(installed_desc[1L, names(identity)], identity)
) {
  stop("Bundle and candidate DESCRIPTION must match the installation receipt.")
}
.libPaths(c(candidate_library, .libPaths()))
namespace <- loadNamespace("statart", lib.loc = candidate_library)
namespace_path <- normalizePath(
  getNamespaceInfo(namespace, "path"),
  winslash = "/",
  mustWork = TRUE
)
if (
  !identical(namespace_path, expected_path) ||
    !identical(as.character(getNamespaceVersion(namespace)), receipt$version)
) {
  stop("Loaded namespace does not belong to the candidate installation.")
}
library(statart, lib.loc = candidate_library)
stopifnot(identical(
  normalizePath(find.package("statart"), winslash = "/", mustWork = TRUE),
  expected_path
))
cat("Archive SHA-256 recorded by installer:", receipt$tarball_sha256, "\n")
cat("Verified archive MD5:", receipt$tarball_md5, "\n")
cat("Version:", as.character(packageVersion("statart")), "\n")
cat("Installation:", find.package("statart"), "\n")
stopifnot(
  length(getNamespaceExports("statart")) == 80L,
  !any(grepl(
    "(_fun|_df_to_mat)$",
    names(getDLLRegisteredRoutines("statart")$.Call)
  ))
)
for (name in c(
  "MIGRATION.md",
  "DATA-PROVENANCE.md",
  "THIRD-PARTY-NOTICES.md",
  "examples/VIEWER_CHECKLIST.md"
)) {
  path <- system.file(name, package = "statart", mustWork = TRUE)
  stopifnot(file.info(path)$size > 0)
}
for (name in c("getting-started", "containers-and-missing-values")) {
  stopifnot(file.exists(system.file(
    "doc",
    paste0(name, ".html"),
    package = "statart"
  )))
}
scripts <- list.files(
  system.file("examples", package = "statart"),
  "^[0-9].*R$",
  full.names = TRUE
)
stopifnot(length(scripts) == 7L)
patterns <- c(
  "03_summary_statistics.R" = "non-numeric|factor",
  "04_prepare_and_calculate.R" = "parsing failure|collapsed quantile",
  "05_robustness_and_consistency.R" = "entirely missing|labelled"
)
for (path in scripts) {
  name <- basename(path)
  parse(path)
  if (name == "00_install.R") {
    next
  }
  if (
    name == "06_data_table_optional.R" &&
      !requireNamespace("data.table", quietly = TRUE)
  ) {
    next
  }
  withCallingHandlers(
    source(path, local = new.env(parent = globalenv()), echo = TRUE),
    warning = function(w) {
      pattern <- patterns[name]
      if (is.na(pattern) || !grepl(pattern, conditionMessage(w))) {
        stop("Unexpected script warning: ", conditionMessage(w))
      }
      cat("Expected warning:", conditionMessage(w), "\n")
      invokeRestart("muffleWarning")
    }
  )
  cat("PASS installed script:", name, "\n")
}
stopifnot(
  any(grepl("inst/examples/01_inspect_and_select.R$", contents)),
  any(grepl("inst/doc/getting-started.html$", contents)),
  !any(grepl("/(extra_functions|[.]opencode|vignettes/articles)/", contents)),
  !any(grepl("[.](o|dll|so)$", contents))
)
cat(
  "PASS: source manifest, installed resources, vignettes and six usage scripts.\n"
)
