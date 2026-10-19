# Opt-in reconstruction from the historically matching dplyr 1.1.3 object.
# Run from the package root. This verifies data; it never overwrites data/.
local({
  source_url <- paste0(
    "https://raw.githubusercontent.com/tidyverse/dplyr/",
    "v1.1.3/data/starwars.rda"
  )
  path <- tempfile(fileext = ".rda")
  download.file(source_url, path, mode = "wb", quiet = TRUE)
  stopifnot(unname(tools::md5sum(path)) == "a1c7281e62ffbd808fda4e3496ca5387")
  source <- new.env(parent = emptyenv())
  retained <- new.env(parent = emptyenv())
  load(path, envir = source)
  load("data/starwars.rda", envir = retained)
  stopifnot(identical(source$starwars, retained$starwars))
  message("starwars: exact reconstruction verified; data/ unchanged.")
})
