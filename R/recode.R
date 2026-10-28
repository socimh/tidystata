#' Recode numeric values with Stata-style rules
#'
#' @description
#' Recode individual values, sets, or closed numeric ranges using ordered rules.
#'
#' * `stata_recode()` (`recode()`): Keep unmatched values unless `.default`
#'   replaces them, and use named rules to assign value labels.
#'
#' @param x An integer or double vector, optionally a numeric
#'   [haven::labelled()] vector. Convert `integer64` input explicitly before
#'   recoding.
#' @param ... Two-sided formulas `values ~ code`, applied in order. Each `code`
#'   is a single number or `NA`; name a rule to label its code. Expressions use
#'   the formula's environment, and stored formulas can be spliced with `!!!`.
#' @param .default Replacement for unmatched elements: a single number, `NA`,
#'   or a vector as long as `x`. By default, keep the input values after SPSS
#'   user-missing codes have been converted to `NA`.
#'
#' @returns An integer or double vector with the length and order of `x`.
#'   Named rules produce a [haven::labelled()] vector; otherwise the result is
#'   numeric without value labels. Names and the variable label are kept;
#'   previous value labels, SPSS missing-value metadata, and other input
#'   attributes are dropped. See Details for integer preservation.
#'
#' @details
#' **Matching rules**
#'
#' Rules apply to the original input, after SPSS missing-value conversion.
#' The first match wins: `1 ~ 2, 2 ~ 1` swaps the codes. Unmatched values stay
#' unchanged unless `.default` replaces them, including unmatched missing values.
#'
#' The left side of a rule accepts:
#'
#' * `a:b`: A closed range, including decimals. Like Stata's `a/b`, `1:5`
#'   matches 4.5. Bounds must be single non-missing numbers in increasing order
#'   (equal bounds are allowed); `lo:hi` reads them from the formula's environment.
#' * `c(...)`: A combination of values and ranges, such as `c(1, 3:5)`.
#' * Other expressions: An evaluated set of values to match exactly. Missing
#'   selectors match all missing types, as described below.
#'
#' Bare `min` and `max` on the left mean `-Inf` and `Inf`, not observed extrema:
#' `min:min` does not select the smallest observed value. Calls such as `min(x)`
#' evaluate normally. Bounds and value sets must use ordinary integer or double
#' numbers; convert classed numbers such as `integer64` explicitly.
#'
#' **Missing values and labels**
#'
#' Any missing selector matches `NA`, `NaN` and every tagged missing value.
#' Thus `NA ~ 0` and `haven::tagged_na("a") ~ 0` both replace all missing types;
#' individual tags cannot be selected separately. Unmatched tags survive when
#' `.default` is omitted. SPSS user-missing codes and ranges become `NA` before
#' matching, so their stored codes cannot be matched as ordinary numbers.
#'
#' Old value labels are removed even if no values change. Named rules create
#' new labels, including for unobserved codes. Labels and codes must correspond
#' one-to-one, and missing codes cannot be labelled.
#'
#' **Output type**
#'
#' Integer input stays integer if all replacement codes and defaults are whole
#' numbers within integer range: `1:5 ~ 1` does not force double output.
#' Fractions, out-of-range values, infinities, `NaN` and tagged missing values
#' require doubles; ordinary `NA` does not. Double input stays double, and the
#' input is never modified.
#'
#' **Stata and other R functions**
#'
#' Use [dplyr::mutate()] to replace or create a variable (Stata's `generate()`),
#' and [dplyr::across()] to recode several columns. Common translations are:
#'
#' | Stata rule | R rule or argument |
#' | --- | --- |
#' | `(1/5 = 1)` | `1:5 ~ 1` |
#' | `(1 3 7 = 0)` | `c(1, 3, 7) ~ 0` |
#' | `(9 = .)` | `9 ~ NA` |
#' | `(missing = 0)` | `NA ~ 0` |
#' | `(else = .)` | `.default = NA` |
#' | `(1/5 = 1 "Low")` | `Low = 1:5 ~ 1` |
#'
#' These functions recode numeric values. For text, use `dplyr::recode_values()`
#' or `dplyr::replace_values()` in dplyr 1.2.0 or later, or [dplyr::case_match()]
#' in older versions. For factors, use `forcats::fct_recode()` or
#' `forcats::fct_collapse()`.
#'
#' The alias `recode()` conflicts with [dplyr::recode()]. Use `stata_recode()`
#' or an explicit namespace to avoid depending on which package was attached last.
#'
#' @name stata_recode
#' @examples
#' # Keep unmatched values
#' x <- c(1, 4.5, 6, 9, 12, NA)
#' stata_recode(x, 1:5 ~ 1, 6:10 ~ 2)
#'
#' # Replace unmatched values with missing
#' stata_recode(x, 1:5 ~ 1, 6:10 ~ 2, .default = NA)
#'
#' # Unbounded intervals and missing values
#' stata_recode(x, min:5 ~ 0, 6:max ~ 1, NA ~ 9)
#'
#' # Swap codes without cascading replacements
#' stata_recode(c(1, 2, 3), 1 ~ 2, 2 ~ 1)
#'
#' # Assign new value labels
#' stata_recode(x, Low = 1:5 ~ 1, High = 6:max ~ 2)
#'
#' # Create a new variable
#' d <- data.frame(score = c(2, 7, 11))
#' dplyr::mutate(
#'   d,
#'   group = stata_recode(score, 1:5 ~ 1, 6:10 ~ 2, .default = NA)
#' )
#'
#' # Apply rules to several variables and prefix the new names
#' items <- data.frame(item1 = c(1, 7, 9), item2 = c(3, 8, 12))
#' dplyr::mutate(
#'   items,
#'   dplyr::across(
#'     dplyr::everything(),
#'     function(v) stata_recode(v, 1:5 ~ 1, 6:10 ~ 2, 11:15 ~ 3),
#'     .names = "r_{.col}"
#'   )
#' )
#' @family variable generation functions

#' @rdname stata_recode
#' @export
stata_recode <- function(x, ..., .default = x) {
  if (missing(x)) {
    cli::cli_abort("Missing {.arg x}. Use {.code stata_recode(x, 1:5 ~ 1)}.")
  }
  data <- recode_input(x)
  n <- length(data)
  rules <- rlang::list2(...)
  if (length(rules) == 0L) {
    cli::cli_abort("Supply at least one rule, such as {.code 1:5 ~ 1}.")
  }
  labels <- names(rules)
  if (is.null(labels)) {
    labels <- rep("", length(rules))
  }
  call <- rlang::current_env()
  rules <- lapply(seq_along(rules), function(i) {
    recode_rule(rules[[i]], i, call = call)
  })

  if (missing(.default)) {
    default <- NULL
  } else {
    default <- recode_default(.default, n)
  }
  ptype <- rlang::inject(vctrs::vec_ptype_common(
    vector(typeof(data)),
    if (is.null(default)) NULL else vector(typeof(default)),
    !!!lapply(rules, `[[`, "code")
  ))
  # Stata-style literals such as `~ 1` are doubles; keep integer input integer
  # when every replacement fits, as Stata keeps a variable's storage type.
  if (
    is.integer(data) &&
      is.double(ptype) &&
      all(vapply(
        rules,
        function(rule) recode_fits_integer(rule$code),
        logical(1)
      )) &&
      (is.null(default) || recode_fits_integer(default))
  ) {
    ptype <- integer()
  }
  rules <- lapply(rules, function(rule) {
    rule$code <- vctrs::vec_cast(rule$code, ptype)
    rule
  })
  out <- recode_apply(data, rules, default, ptype)

  if (
    !is.null(default) &&
      !inherits(default, "haven_labelled") &&
      !is.null(attributes(default))
  ) {
    # Same-type defaults retain non-class metadata; promotion can drop it.
    # A zero-length cast reproduces that decision without copying row data.
    attrs <- attributes(vctrs::vec_cast(
      vctrs::vec_slice(default, integer()),
      ptype
    ))
    attrs$names <- names(x)
    attributes(out) <- attrs
  }
  names(out) <- names(x)
  label <- attr(x, "label", exact = TRUE)
  value_labels <- recode_labels(labels, rules, ptype)
  if (length(value_labels)) {
    return(haven::labelled(out, labels = value_labels, label = label))
  }
  attr(out, "label") <- label
  out
}

#' @rdname stata_recode
#' @export
recode <- stata_recode

# Validate without copying the vector. The native reader normalizes SPSS
# user-missing codes per element and preserves existing missing payloads.
recode_input <- function(x, call = rlang::caller_env()) {
  if (inherits(x, "integer64")) {
    cli::cli_abort(
      "Convert {.arg x} from {.cls integer64} explicitly to ordinary numeric values before recoding.",
      call = call
    )
  }
  labelled <- inherits(x, "haven_labelled")
  if (
    !typeof(x) %in% c("integer", "double") ||
      (!labelled && is.object(x)) ||
      !is.null(dim(x))
  ) {
    cli::cli_abort(
      c(
        "{.arg x} must be a numeric vector, not {.obj_type_friendly {x}}.",
        i = "For text, use {.fn dplyr::recode_values} or {.fn dplyr::replace_values} (dplyr >= 1.2.0), or {.fn dplyr::case_match}; for factors, use {.fn forcats::fct_recode} or {.fn forcats::fct_collapse}."
      ),
      call = call
    )
  }
  x
}

recode_default <- function(default, n, call = rlang::caller_env()) {
  if (inherits(default, "haven_labelled")) {
    default <- recode_input(default, call = call)
  } else if (!recode_is_code(default, scalar = FALSE)) {
    cli::cli_abort(
      "{.arg .default} must be numeric or {.code NA}, not {.obj_type_friendly {default}}.",
      call = call
    )
  }
  if (length(default) != 1L && length(default) != n) {
    vctrs::vec_recycle(default, n, x_arg = ".default", call = call)
  }
  default
}

# Whole numbers within integer range, or untagged missing values, cast to
# integer without changing any value.
recode_fits_integer <- function(value) {
  if (!is.double(value)) {
    return(TRUE)
  }
  missing <- is.na(value)
  if (any(is.nan(value) | haven::is_tagged_na(value))) {
    return(FALSE)
  }
  observed <- value[!missing]
  all(abs(observed) <= .Machine$integer.max & observed == trunc(observed))
}

recode_is_code <- function(value, scalar = TRUE) {
  ok_type <- (typeof(value) %in% c("integer", "double") && !is.object(value)) ||
    (is.logical(value) && all(is.na(value)))
  ok_type && is.null(dim(value)) && (!scalar || length(value) == 1L)
}

# Selectors contain only rule-sized data; matching never builds row masks.
recode_rule <- function(rule, i, call = rlang::caller_env()) {
  if (!rlang::is_formula(rule, lhs = TRUE)) {
    cli::cli_abort(
      c(
        "Rule {i} must be a two-sided formula such as {.code 1:5 ~ 1}.",
        x = "It is {.obj_type_friendly {rule}}."
      ),
      call = call
    )
  }
  env <- rlang::f_env(rule)
  code <- eval(rlang::f_rhs(rule), env)
  if (!recode_is_code(code)) {
    cli::cli_abort(
      c(
        "The code in rule {i} must be a single number or {.code NA}.",
        x = "{.code {rlang::expr_deparse(rlang::f_rhs(rule))}} is {.obj_type_friendly {code}}."
      ),
      call = call
    )
  }
  # `min` and `max` are open range ends; functions such as min() still work.
  mask <- rlang::env(env, min = -Inf, max = Inf)
  list(
    select = recode_selector(rlang::f_lhs(rule), mask, i, call),
    code = code
  )
}

recode_selector <- function(expr, mask, i, call) {
  while (rlang::is_call(expr, "(")) {
    expr <- expr[[2]]
  }
  if (rlang::is_call(expr, "c")) {
    parts <- lapply(
      rlang::call_args(expr),
      recode_selector,
      mask = mask,
      i = i,
      call = call
    )
    return(list(
      values = as.double(unlist(
        lapply(parts, `[[`, "values"),
        use.names = FALSE
      )),
      lower = as.double(unlist(
        lapply(parts, `[[`, "lower"),
        use.names = FALSE
      )),
      upper = as.double(unlist(
        lapply(parts, `[[`, "upper"),
        use.names = FALSE
      )),
      missing = any(vapply(parts, `[[`, logical(1), "missing"))
    ))
  }
  if (rlang::is_call(expr, ":", n = 2)) {
    lower <- recode_bound(expr[[2]], mask, i, call)
    upper <- recode_bound(expr[[3]], mask, i, call)
    if (lower > upper) {
      cli::cli_abort(
        c(
          "The range in rule {i} must run from low to high.",
          x = "{.code {rlang::expr_deparse(expr)}} has a lower bound above its upper bound."
        ),
        call = call
      )
    }
    return(list(
      values = double(),
      lower = lower,
      upper = upper,
      missing = FALSE
    ))
  }
  values <- eval(expr, mask)
  if (inherits(values, "haven_labelled")) {
    values <- vctrs::vec_data(values)
  }
  if (!is.null(values) && !recode_is_code(values, scalar = FALSE)) {
    cli::cli_abort(
      c(
        "The values in rule {i} must be numeric or {.code NA}.",
        x = "{.code {rlang::expr_deparse(expr)}} is {.obj_type_friendly {values}}."
      ),
      call = call
    )
  }
  missing <- is.na(values)
  values <- as.double(values[!missing])
  list(
    values = values,
    lower = double(),
    upper = double(),
    missing = any(missing)
  )
}

recode_bound <- function(expr, mask, i, call) {
  bound <- eval(expr, mask)
  if (!recode_is_code(bound) || is.na(bound)) {
    cli::cli_abort(
      c(
        "Range bounds in rule {i} must be single non-missing numbers.",
        x = "{.code {rlang::expr_deparse(expr)}} is {.obj_type_friendly {bound}}."
      ),
      call = call
    )
  }
  as.double(bound)
}

# Rule names become value labels; repeated identical pairs collapse.
recode_labels <- function(labels, rules, ptype, call = rlang::caller_env()) {
  named <- labels != ""
  if (!any(named)) {
    return(NULL)
  }
  codes <- vctrs::vec_c(
    !!!lapply(rules[named], `[[`, "code"),
    .ptype = ptype
  )
  labels <- labels[named]
  if (anyNA(codes)) {
    cli::cli_abort(
      "Missing codes cannot be labelled; remove the name of rule {.val {labels[is.na(codes)]}}.",
      call = call
    )
  }
  pairs <- !duplicated(data.frame(labels, codes))
  labels <- labels[pairs]
  codes <- codes[pairs]
  if (anyDuplicated(codes)) {
    code <- codes[duplicated(codes)][1]
    cli::cli_abort(
      "Code {code} has more than one label: {.val {labels[codes == code]}}.",
      call = call
    )
  }
  if (anyDuplicated(labels)) {
    label <- labels[duplicated(labels)][1]
    cli::cli_abort(
      "Label {.val {label}} names more than one code: {codes[labels == label]}.",
      call = call
    )
  }
  rlang::set_names(codes, labels)
}
