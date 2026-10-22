## Resubmission

This is a new submission of tidystata 0.3.0. It replaces statart, which was
submitted as version 0.2.0 in June 2024 and returned for revision. The package
is renamed and its scope reduced to exploring and preparing data. Responses to
the 2024 review:

* Software names in the Title and Description are in single quotes
  ('Stata', 'tidyverse').
* No published method underlies the package, so the Description cites no
  references.
* Every exported function's help page has a `\value` section. The functions
  named in the review are handled: `s_ggsave()`, `s_match()` and `s_plot()`
  are removed, and the `na_conversion` and `type_conversion` pages now
  document their return values.
* No examples use `\dontrun{}`.
* Console output comes only from `print()` methods and explicit printing
  functions. Other notices use `message()` conditions (through cli) that
  `suppressMessages()` can silence.
* Functions, examples, vignettes and tests write no files. The file-writing
  helpers are removed.
* No function, example, vignette or shipped script installs packages.
* Imports fall from 33 to 16 packages, two of them base packages.
* Bundled data: `lifeexp` is rebuilt from World Bank World Development
  Indicators (CC BY 4.0); source, indicators and changes are in
  inst/DATA-PROVENANCE.md. The former copy of dplyr's `starwars` is removed;
  examples use `dplyr::starwars`.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.
