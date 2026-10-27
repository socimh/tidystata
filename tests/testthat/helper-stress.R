# Adversarial inputs and contract checks for the stress matrix and invariant
# suites (test-stress-matrix.R, test-stress-invariants.R). Generators are
# deterministic; classes whose Suggests package is absent are dropped.

stress_n <- 8L

# One test column per class. Each has eight values with missing values,
# repeated values and at least one awkward value for its type.
stress_columns <- function() {
  has <- function(pkg) requireNamespace(pkg, quietly = TRUE)
  latin1 <- c("caf\xe9", "na\xefve", NA, "a", "caf\xe9", "b", "\xfc", "")
  Encoding(latin1) <- "latin1"
  columns <- list(
    dbl = c(1.5, -2, NA, 0, 3.25, 10, -2, 7),
    dbl_extreme = c(NA, NaN, Inf, -Inf, -0, 1e308, 5e-324, 2),
    int = c(3L, 1L, NA, 2L, 3L, 5L, 1L, 4L),
    int_extreme = c(
      .Machine$integer.max,
      -.Machine$integer.max,
      NA,
      0L,
      1L,
      .Machine$integer.max,
      2L,
      -1L
    ),
    lgl = c(TRUE, FALSE, NA, TRUE, TRUE, FALSE, NA, TRUE),
    chr = c("b", "a", NA, "c", "a", "", "b", " "),
    chr_utf8 = c(
      "北京",
      "上海",
      NA,
      "\U0001F600",
      "北京",
      "café",
      "a b",
      "ü"
    ),
    chr_latin1 = latin1,
    fct = factor(
      c("b", "a", NA, "c", "a", "b", "b", "c"),
      levels = c("c", "a", "b", "unused")
    ),
    fct_na_level = addNA(factor(c("b", "a", NA, "c", "a", "b", "b", "c"))),
    ord = factor(
      c("lo", "hi", NA, "mid", "lo", "hi", "mid", "lo"),
      levels = c("lo", "mid", "hi"),
      ordered = TRUE
    ),
    date = as.Date("2020-01-01") + c(0, 31, NA, 59, 0, 365, -1, 1000),
    posixct = as.POSIXct(
      c(
        "2021-03-14 01:30:00",
        "2021-03-14 03:30:00",
        NA,
        "2021-11-07 01:30:00",
        "2021-03-14 01:30:00",
        "1969-12-31 23:59:59",
        "2038-01-19 03:14:08",
        "2021-06-01 12:00:00"
      ),
      tz = "America/New_York"
    ),
    difftime = as.difftime(c(1.5, 2, NA, 0, 3, 24, -1, 7), units = "hours"),
    list = list(1, "a", NULL, 2:3, NA, 1, "b", TRUE),
    complex = complex(
      real = c(1, 2, NA, 0, 1, 3, -1, 2),
      imaginary = c(0, 1, 0, -1, 0, 2, 1, 0)
    )
  )
  if (has("haven")) {
    columns$lbl_dbl <- haven::labelled(
      c(1, 2, NA, 3, 1, 2, 9, 1),
      labels = c(Low = 1, Mid = 2, High = 3, Missing = 9),
      label = "Labelled number"
    )
    columns$lbl_tagged <- haven::labelled(
      c(1, 2, haven::tagged_na("a"), 3, haven::tagged_na("b"), 1, 2, NA),
      labels = c(Low = 1, Mid = 2, Refused = haven::tagged_na("a"))
    )
    columns$lbl_chr <- haven::labelled(
      c("a", "b", NA, "c", "a", "b", "a", ""),
      labels = c(Alpha = "a", Beta = "b")
    )
    columns$lbl_spss <- haven::labelled_spss(
      c(1, 2, -9, 3, 1, NA, -8, 2),
      labels = c(Low = 1, Mid = 2, Refused = -9),
      na_values = c(-9, -8)
    )
  }
  if (has("hms")) {
    columns$hms <- hms::hms(seconds = c(0, 59, NA, 3600, 0, 86399, -1, 90000))
  }
  if (has("bit64")) {
    columns$int64 <- bit64::as.integer64(
      c("9007199254740993", "1", NA, "2", "-5", "3", "1", "0")
    )
  }
  columns
}

# Shapes apply to the test column and the companion columns together.
stress_shapes <- c("regular", "zero", "one", "all_na", "constant")

stress_shape_rows <- function(shape, n = stress_n) {
  switch(
    shape,
    regular = seq_len(n),
    zero = integer(0),
    one = 1L,
    all_na = seq_len(n),
    constant = seq_len(n)
  )
}

stress_shape_column <- function(x, shape, n = stress_n) {
  switch(
    shape,
    all_na = x[rep(NA_integer_, n)],
    constant = x[rep(1L, n)],
    x[stress_shape_rows(shape, n)]
  )
}

# The test column `x` with a numeric companion `y`, a group key `g` (with a
# missing key and a one-row group), positive integer weights `w` and a gapped
# integer time `t`.
stress_frame <- function(x, shape = "regular") {
  rows <- stress_shape_rows(shape)
  tibble::tibble(
    x = stress_shape_column(x, shape),
    y = c(2, 4, 1, NA, 8, 3, 5, 6)[rows],
    g = c("a", "a", "b", "b", NA, "a", "b", "c")[rows],
    w = c(1, 2, 1, 3, 1, 1, 2, 1)[rows],
    t = c(1L, 2L, 3L, 4L, 5L, 6L, 8L, 9L)[rows]
  )
}

stress_containers <- function() {
  containers <- list(
    tibble = function(d) d,
    data_frame = function(d) {
      out <- as.data.frame(d)
      if (nrow(out)) {
        rownames(out) <- paste0("r", seq_len(nrow(out)))
      }
      out
    },
    grouped = function(d) dplyr::group_by(d, .data$g),
    rowwise = function(d) dplyr::rowwise(d)
  )
  if (requireNamespace("data.table", quietly = TRUE)) {
    containers$data_table <- function(d) data.table::as.data.table(d)
  }
  containers
}

stress_copy <- function(d) {
  if (inherits(d, "data.table")) data.table::copy(d) else d
}

# Base-R and vctrs internals leaking to users signal an unchecked input,
# however they are wrapped.
stress_internal_patterns <- c(
  "subscript out of bounds",
  "non-numeric argument",
  "missing value where TRUE/FALSE needed",
  "argument is of length zero",
  "argument of length 0",
  "object of type '[a-z]+' is not subsettable",
  "invalid 'type'",
  "NAs introduced by coercion",
  "no non-missing arguments",
  "invalid factor level",
  "replacement has",
  "longer object length",
  "arguments imply differing number of rows",
  "cannot coerce type",
  "is not a function",
  "undefined columns selected",
  "index out of bounds",
  "std::",
  "incorrect number of dimensions",
  "number of items to replace",
  "condition has length > 1",
  "unused argument",
  "not meaningful for factors",
  "comparison \\(.*\\) is possible only",
  "invalid argument to unary operator",
  "non-conformable",
  "NA/NaN argument",
  "Can't combine",
  "Can't convert",
  "Can't recycle",
  "Can't subset",
  "must be size",
  "must be a vector, not",
  "Unsupported class",
  "S4 objects",
  "attempt to apply non-function",
  "promise already under evaluation"
)

stress_message_chain <- function(cnd) {
  messages <- character(0)
  while (!is.null(cnd)) {
    messages <- c(messages, conditionMessage(cnd))
    cnd <- cnd$parent
  }
  paste(messages, collapse = "\n")
}

# dplyr's "In argument:" wrappers only add context; judge the condition they
# wrap, keeping parents raised below a package message.
stress_unwrap <- function(cnd) {
  while (
    !is.null(cnd$parent) &&
      (inherits(cnd, "dplyr:::mutate_error") ||
        inherits(cnd, "dplyr:::summarise_error") ||
        inherits(cnd, "dplyr_error") ||
        startsWith(conditionMessage(cnd), "ℹ In ") ||
        grepl("^There (was|were) [0-9]+ warning", conditionMessage(cnd)))
  ) {
    cnd <- cnd$parent
  }
  cnd
}

# The judged condition's own text: rlang conditions are read without the
# "Caused by" text of their parents.
stress_own_message <- function(cnd) {
  if (inherits(cnd, "rlang_error") || inherits(cnd, "rlang_warning")) {
    paste(
      c(rlang::cnd_header(cnd), rlang::cnd_body(cnd)),
      collapse = "
"
    )
  } else {
    conditionMessage(cnd)
  }
}

stress_is_internal <- function(cnd) {
  text <- stress_own_message(stress_unwrap(cnd))
  any(vapply(
    stress_internal_patterns,
    grepl,
    logical(1),
    x = text
  ))
}

# Evaluates one cell. Returns the value, the error and every warning, with
# printed output discarded.
stress_run <- function(call) {
  warnings <- list()
  value <- NULL
  error <- NULL
  utils::capture.output(
    value <- tryCatch(
      withCallingHandlers(
        suppressMessages(call()),
        warning = function(w) {
          warnings[[length(warnings) + 1L]] <<- w
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        error <<- e
        NULL
      }
    )
  )
  list(value = value, error = error, warnings = warnings)
}

# A short machine-readable summary of one cell, used by both suites and by
# the discovery probe.
stress_outcome <- function(result) {
  if (!is.null(result$error)) {
    kind <- if (stress_is_internal(result$error)) {
      "internal_error"
    } else if (inherits(stress_unwrap(result$error), "rlang_error")) {
      "error"
    } else {
      "base_error"
    }
  } else {
    kind <- "ok"
  }
  warning_kinds <- vapply(
    result$warnings,
    function(w) {
      if (stress_is_internal(w)) {
        "internal_warning"
      } else if (inherits(stress_unwrap(w), "rlang_warning")) {
        "warning"
      } else {
        "base_warning"
      }
    },
    character(1)
  )
  list(
    kind = kind,
    warnings = unique(warning_kinds),
    warning_kinds = unname(warning_kinds),
    message = if (!is.null(result$error)) {
      stress_message_chain(result$error)
    } else {
      ""
    },
    warning_messages = vapply(
      result$warnings,
      conditionMessage,
      character(1)
    )
  )
}

# Each entry calls one export on a stress frame `d` with test column `x`.
# `kind` = "frame" for functions returning a summary, "vector" for functions
# evaluated inside mutate() that must return one value per row. Vector
# expressions see the columns of `d`, including grouped and rowwise slices.
stress_registry <- function() {
  frame <- function(f) list(kind = "frame", call = f)
  mutate_cell <- function(expr) {
    expr <- substitute(expr)
    list(
      kind = "vector",
      expr = expr,
      call = function(d) dplyr::mutate(d, out = !!expr)$out
    )
  }
  registry <- list(
    tab = frame(function(d) tidystata::tab(d, x)),
    tab_wt = frame(function(d) tidystata::tab(d, x, .wt = w)),
    tab_by = frame(function(d) tidystata::tab(d, x, .by = g)),
    tab1 = frame(function(d) tidystata::tab1(d, x, y)),
    tab2 = frame(function(d) tidystata::tab2(d, x, g)),
    tab2_chi2 = frame(function(d) tidystata::tab2(d, x, g, .chi2 = TRUE)),
    fre = frame(function(d) tidystata::fre(d, x)),
    fre1 = frame(function(d) tidystata::fre1(d, x, y)),
    fre2 = frame(function(d) tidystata::fre2(d, x, g)),
    summ = frame(function(d) tidystata::summ(d, x)),
    summ_detail = frame(function(d) tidystata::summ(d, x, .detail = TRUE)),
    summ_wt = frame(function(d) tidystata::summ(d, x, .wt = w)),
    summ_aw = frame(function(d) {
      tidystata::summ(d, x, .detail = TRUE, .wt = w, .wt_type = "analytic")
    }),
    summ_by = frame(function(d) tidystata::summ(d, x, .by = g)),
    tabstat = frame(function(d) tidystata::tabstat(d, x, .by = g)),
    corr = frame(function(d) tidystata::corr(d, x, y)),
    pwcorr = frame(function(d) tidystata::pwcorr(d, x, y, .wt = w)),
    spearman = frame(function(d) tidystata::spearman(d, x, y)),
    misstable = frame(function(d) tidystata::misstable(d, x, y)),
    misstable_patterns = frame(function(d) {
      tidystata::misstable(d, x, y, .patterns = TRUE)
    }),
    codebook = frame(function(d) tidystata::codebook(d, x)),
    browse = frame(function(d) tidystata::browse(d, x)),
    ds = frame(function(d) tidystata::ds(d, .type = "table")),
    variables = frame(function(d) tidystata::variables(d)),
    isid = frame(function(d) tidystata::isid(d, x, t, .missing = TRUE)),
    duplicates_report = frame(function(d) tidystata::duplicates_report(d, x)),
    duplicates_tag = frame(function(d) tidystata::duplicates_tag(d, x)),
    duplicates_list = frame(function(d) tidystata::duplicates_list(d, x)),
    duplicates_drop = frame(function(d) {
      tidystata::duplicates_drop(d, x, .force = TRUE)
    }),
    select_or_transmute = frame(function(d) {
      tidystata::select_or_transmute(d, x, copy = x)
    }),
    as_dummy = frame(function(d) tidystata::as_dummy(d, x)),
    assert = frame(function(d) tidystata::assert(d, !is.na(t))),
    print_headtail = frame(function(d) tidystata::print_headtail(d, n = 2)),
    print_interval = frame(function(d) tidystata::print_interval(d, n = 2)),
    preview = frame(function(d) {
      print(tidystata::preview(d, n = 2))
      tidystata::unpreview(tidystata::preview(d))
    }),
    stata_merge = frame(function(d) {
      using <- dplyr::distinct(dplyr::ungroup(d), x)
      using$z <- seq_len(nrow(using))
      tidystata::stata_merge(
        d,
        using,
        relationship = "m:1",
        by = "x",
        report = FALSE
      )
    }),
    stata_lag_time = frame(function(d) {
      d <- dplyr::ungroup(d)
      d <- d[!duplicated(d$x), ]
      dplyr::mutate(d, out = tidystata::stata_lag(y, time = x))$out
    }),
    preview_interval = frame(function(d) {
      print(tidystata::preview_interval(d, n = 2))
    }),
    variables_search = frame(function(d) {
      tidystata::variables_search(d, "x")
    }),
    var_type = frame(function(d) tidystata::var_type(d$x)),
    var_unit = frame(function(d) tidystata::var_unit(d$x)),
    destring = mutate_cell(tidystata::destring(x)),
    tostring = mutate_cell(tidystata::tostring(x)),
    decode = mutate_cell(tidystata::decode(x)),
    mvdecode = mutate_cell(tidystata::mvdecode(x, 1)),
    mvencode = mutate_cell(tidystata::mvencode(x, 0)),
    na_if_value = mutate_cell(tidystata::na_if_value(x, 1)),
    value_if_na = mutate_cell(tidystata::value_if_na(x, 0)),
    std = mutate_cell(tidystata::std(x)),
    pc = mutate_cell(tidystata::pc(x)),
    xtile = mutate_cell(tidystata::xtile(x, 3)),
    xtile_wt = mutate_cell(tidystata::xtile(x, 3, wt = w)),
    cut_length = mutate_cell(tidystata::cut_length(x, 3)),
    cut_breaks = mutate_cell(tidystata::cut_breaks(x, breaks = c(0, 2))),
    stata_recode = mutate_cell(tidystata::stata_recode(
      x,
      min:1 ~ 0,
      2:max ~ 1
    )),
    is_first = mutate_cell(tidystata::is_first(x)),
    is_first_pair = mutate_cell(tidystata::is_first(x, g)),
    row_mean = mutate_cell(tidystata::row_mean(x, y)),
    row_sum = mutate_cell(tidystata::row_sum(x, y)),
    row_min = mutate_cell(tidystata::row_min(x, y)),
    row_max = mutate_cell(tidystata::row_max(x, y)),
    row_median = mutate_cell(tidystata::row_median(x, y)),
    row_var = mutate_cell(tidystata::row_var(x, y)),
    row_sd = mutate_cell(tidystata::row_sd(x, y)),
    row_unique = mutate_cell(tidystata::row_unique(x, g)),
    row_nvals = mutate_cell(tidystata::row_nvals(x, g)),
    row_miss = mutate_cell(tidystata::row_miss(x, y)),
    row_non_miss = mutate_cell(tidystata::row_non_miss(x, y)),
    stata_lag = mutate_cell(tidystata::stata_lag(x, time = t)),
    stata_lead = mutate_cell(tidystata::stata_lead(x, time = t)),
    stata_diff = mutate_cell(tidystata::stata_diff(x, time = t))
  )
  for (name in names(registry)) {
    export <- stress_entry_exports[[name]]
    registry[[name]]$export <- if (is.null(export)) name else export
  }
  registry
}

# Registry entries that exercise an export under another name.
stress_entry_exports <- list(
  tab_wt = "tab",
  tab_by = "tab",
  tab2_chi2 = "tab2",
  summ_detail = "summ",
  summ_wt = "summ",
  summ_aw = "summ",
  summ_by = "summ",
  misstable_patterns = "misstable",
  preview = c("preview", "preview_headtail", "unpreview"),
  stata_lag_time = "stata_lag",
  xtile_wt = "xtile",
  is_first_pair = "is_first"
)

# Exports outside the data matrix, with the reason.
stress_unregistered_exports <- list(
  findit = "Stata command lookup; no data input",
  varlist = "string pattern helper; no data input",
  capture = "expression wrapper; covered by test-capture.R",
  timer = "expression wrapper; covered by test-timer.R",
  set_seed = "RNG wrapper; covered by test-set_seed.R",
  as_character = "alias of decode()",
  as_numeric = "alias of destring()",
  cut_quantile = "alias of xtile()",
  pct = "alias of pc()",
  recode = "alias of stata_recode()",
  tab_gen = "alias of as_dummy()"
)

stress_aliases <- c(
  as_character = "decode",
  as_numeric = "destring",
  cut_quantile = "xtile",
  pct = "pc",
  recode = "stata_recode",
  tab_gen = "as_dummy"
)

# Warnings that state a real, unavoidable conversion rather than a leak.
stress_allowed_warning <- function(messages) {
  grepl("integer precision lost while converting to double", messages)
}

# Confirmed but unfixed defects, excluded from the matrix and recorded as
# skipped contract tests in test-stress-matrix.R; none are open. Patterns
# are regular expressions matched against the whole cell field.
stress_known_issues <- data.frame(
  id = character(),
  fn = character(),
  class = character(),
  shape = character(),
  stringsAsFactors = FALSE
)

stress_is_known_issue <- function(fn, class, shape) {
  full <- function(patterns, value) {
    vapply(
      patterns,
      function(pattern) grepl(paste0("^(", pattern, ")$"), value),
      logical(1),
      USE.NAMES = FALSE
    )
  }
  any(
    full(stress_known_issues$fn, fn) &
      full(stress_known_issues$class, class) &
      full(stress_known_issues$shape, shape)
  )
}

# Skips a known-issue contract test. TIDYSTATA_STRESS_KNOWN=true runs it
# instead, to confirm the defect still reproduces (the test then fails).
stress_skip_known <- function(id, reason) {
  if (!identical(Sys.getenv("TIDYSTATA_STRESS_KNOWN"), "true")) {
    testthat::skip(paste0("known issue ", id, ": ", reason))
  }
}

# "cran" on CRAN, "full" with TIDYSTATA_STRESS=full, otherwise "default".
stress_tier <- function() {
  if (identical(Sys.getenv("TIDYSTATA_STRESS"), "full")) {
    "full"
  } else if (identical(Sys.getenv("NOT_CRAN"), "true")) {
    "default"
  } else {
    "cran"
  }
}

stress_core_classes <- c("dbl", "int", "lgl", "chr", "fct", "date", "lbl_dbl")

stress_cells <- function(registry, columns, containers, tier = stress_tier()) {
  grid <- function(classes, container, shape) {
    expand.grid(
      fn = names(registry),
      class = classes,
      container = intersect(container, names(containers)),
      shape = shape,
      stringsAsFactors = FALSE
    )
  }
  all_classes <- names(columns)
  other_shapes <- setdiff(stress_shapes, "regular")
  cells <- switch(
    tier,
    cran = grid(
      intersect(stress_core_classes, all_classes),
      "tibble",
      "regular"
    ),
    default = rbind(
      grid(all_classes, "tibble", c("regular", "zero", "all_na")),
      grid(
        intersect(stress_core_classes, all_classes),
        c("grouped", "data_table"),
        "regular"
      )
    ),
    full = rbind(
      grid(all_classes, names(containers), "regular"),
      grid(all_classes, "tibble", other_shapes)
    )
  )
  keep <- mapply(
    function(fn, class, container, shape) {
      stress_cell_applies(fn, class, container, registry) &&
        !stress_is_known_issue(fn, class, shape)
    },
    cells$fn,
    cells$class,
    cells$container,
    cells$shape
  )
  cells[keep, , drop = FALSE]
}

# Cells that cannot represent a real call: a rowwise slice of a list column
# exposes a bare NULL element to mutate().
stress_cell_applies <- function(fn, class, container, registry) {
  !(identical(container, "rowwise") &&
    identical(class, "list") &&
    identical(registry[[fn]]$kind, "vector"))
}
