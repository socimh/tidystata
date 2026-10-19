# Opt-in reconstruction using a verified Stata Press asset and haven 2.5.5.
# The original Stata release is unknown. This preserves historical note order.
# Run from the package root. This verifies data; it never overwrites data/.
local({
  source_url <- "https://www.stata-press.com/data/r17/lifeexp.dta"
  path <- tempfile(fileext = ".dta")
  download.file(source_url, path, mode = "wb", quiet = TRUE)
  stopifnot(unname(tools::md5sum(path)) == "d1c20705b0842e4f3a4ba4b6d6ef38e6")
  reconstructed <- haven::read_dta(path)
  attr(reconstructed, "notes") <- attr(reconstructed, "notes")[c(3, 2, 1)]
  retained <- new.env(parent = emptyenv())
  load("data/lifeexp.rda", envir = retained)
  stopifnot(identical(reconstructed, retained$lifeexp))
  message("lifeexp: exact reconstruction verified; data/ unchanged.")
})
