test_that("clear commands show one default and offer every remaining example", {
  withr::local_envvar(LANGUAGE = "en")
  for (query in c("tab", "reg", "su", "codebook", "lm")) {
    found <- findit(!!query)
    out <- capture.output(print(found))
    expect_identical(sum(startsWith(out, "Stata: ")), 1L, info = query)
    expect_identical(
      sum(startsWith(capture.output(print(found, n = Inf)), "Stata: ")),
      nrow(found)
    )
  }
  out <- capture.output(print(findit(tab)))
  expect_true("Stata: tabulate x" %in% out)
  expect_true(
    paste0(
      "# ",
      nrow(findit(tab)) - 1L,
      " more examples. To see them all: findit(tab) |> print(n = Inf)"
    ) %in%
      out
  )
  expect_identical(
    sum(startsWith(capture.output(print(findit(reshape))), "Stata: ")),
    2L
  )
  expect_identical(
    sum(startsWith(capture.output(print(findit(log))), "Stata: ")),
    2L
  )
})

test_that("comma arguments select tabulation examples without evaluation", {
  sex <- region <- gen <- stop
  two <- findit(tab, sex, region)
  expect_identical(two$stata[1], "tabulate sex region")
  expect_identical(two$r[1], "tab2(data, sex, region)")
  expect_identical(nrow(two), nrow(findit(tab)))
  expect_named(two, c("match", "stata", "r", "package", "task"))
  expect_identical(findit(ta, sex, region)$r[1], two$r[1])
  expect_identical(findit("tabulate", "sex", "region")$r[1], two$r[1])
  expect_identical(findit(tab, gen)$r[1], "as_dummy(data, x)")
  expect_identical(findit(tab, sex, gen)$r[1], "as_dummy(data, sex)")
  expect_identical(findit(tab, "gen")$r[1], "tab(data, gen)")
  cmd <- "tab"
  column <- "sex"
  expect_identical(findit(!!cmd, !!column)$r[1], "tab(data, sex)")
  out <- capture.output(print(two))
  expect_identical(sum(startsWith(out, "Stata: ")), 1L)
  expect_false(any(startsWith(out, "# tab()")))
  expect_false(any(startsWith(
    capture.output(print(findit(tab, gen))),
    "# tab()"
  )))
  expect_true(any(grepl(
    "findit(tab, sex, region) |> print(n = Inf)",
    out,
    fixed = TRUE
  )))
})

test_that("supplied names bind in Stata operand order across command families", {
  expect_identical(
    findit(reg, income, education, age)$r[1],
    "fit <- lm(income ~ education + age, data = data)"
  )
  expect_identical(
    findit(merge, person)$r[1],
    'stata_merge(data1, data2, "1:1", by = "person")'
  )
  expect_identical(
    findit(xtile, quartile, income)$r[1],
    "mutate(data, quartile = xtile(income, 4))"
  )
  expect_identical(
    findit(gen, squared, income)$r[1],
    "mutate(data, squared = income^2)"
  )
  grouped <- findit(summ, region, income, by)
  expect_identical(grouped$stata[1], "bysort region: summarize income")
  expect_identical(grouped$r[1], "summ(data, income, .by = region)")
  expect_identical(
    findit(reshape, measure, person, wave, long)$r[1],
    paste0(
      'tidyr::pivot_longer(data, tidyselect::starts_with("measure"), ',
      'names_to = "wave", names_prefix = "measure", ',
      'names_transform = list(wave = as.integer), values_to = "measure")'
    )
  )
  expect_identical(
    findit(sem, outcome, first, second)$r[1],
    'lavaan::sem("outcome ~ first + second", data = data)'
  )
  expect_identical(
    findit(test, first, second)$r[1],
    'marginaleffects::hypotheses(fit, "first = second")'
  )
})

test_that("customization is simultaneous and leaves incompatible examples intact", {
  found <- findit(tab, sex, region)
  expect_true("tab(data, x)" %in% found$r)
  full <- capture.output(print(found, n = Inf))
  expect_identical(sum(startsWith(full, "Stata: ")), nrow(findit(tab)))
  expect_true(any(grepl("retain.*placeholder", full)))
  expect_identical(findit(tab, x2, x1)$r[1], "tab2(data, x2, x1)")
  expect_identical(
    findit(tab, `first name`, `last name`)$r[1],
    "tab2(data, `first name`, `last name`)"
  )
  expect_identical(
    findit(subinstr, output, source)$r[1],
    'mutate(data, output = str_replace_all(source, fixed("a"), "b"))'
  )
  expect_identical(
    findit(twoway, outcome, predictor, qfit)$r[1],
    paste0(
      'ggplot(data, aes(predictor, outcome)) + ',
      'geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE)'
    )
  )
  unsupported <- findit(xtile, a, b, c, d, e)
  expect_identical(unsupported$r, findit(xtile)$r)
  expect_true(any(grepl("do not fit", capture.output(print(unsupported)))))
})

test_that("extra argument validation never executes supplied calls", {
  expect_error(findit(tab, stop("executed")), "bare name or a non-empty string")
  expect_error(findit(tab, 2), "bare name or a non-empty string")
  expect_error(findit(tab, NULL), "bare name or a non-empty string")
  expect_error(findit(tab, ""), "bare name or a non-empty string")
  expect_error(findit(tab, ), "must not be missing")
  expect_error(findit(tab, column = sex), "must be unnamed")
  expect_error(findit(NULL, sex), "command.*required")
})

test_that("lists, panel context and derived output names preserve their roles", {
  expect_identical(
    findit(su, income, education)$r[1],
    "summ(data, income, education)"
  )
  expect_identical(
    findit(reg, income, education)$r[1],
    "fit <- lm(income ~ education, data = data)"
  )
  expect_identical(
    findit(xtreg, income, education, fe)$r[1],
    "fixest::feols(income ~ education | id, data = data)"
  )
  expect_identical(
    findit(xtreg, income, education, re)$r[1],
    paste0(
      'plm::plm(income ~ education, data = data, ',
      'index = c("id", "year"), model = "random")'
    )
  )
  expect_identical(
    findit(tab, sex, gen)$stata[1],
    "tabulate sex, generate(sex_)"
  )
  expect_identical(
    findit(winsor2, income)$r[1],
    "mutate(data, income_w = datawizard::winsorize(income, threshold = 0.01))"
  )
  expect_identical(
    findit(mdy, birthday, month, day, year)$r[1],
    "mutate(data, birthday = lubridate::make_date(year, month, day))"
  )
})

test_that("hints retain alternatives and explicit print limits remain authoritative", {
  ambiguous <- findit(tab, sex, region, tab)
  out <- capture.output(print(ambiguous, n = 2))
  expect_identical(sum(startsWith(out, "Stata: ")), 2L)
  expect_identical(
    sum(startsWith(capture.output(print(ambiguous, n = Inf)), "Stata: ")),
    nrow(ambiguous)
  )
  conflicting <- findit(tab, chi2, exact)
  expect_true(any(grepl(
    "No example matches all supplied hints",
    capture.output(print(conflicting)),
    fixed = TRUE
  )))
  withr::local_envvar(LANGUAGE = "zh_CN")
  found <- findit(tab, sex, region)
  expect_identical(found$r[1], "tab2(data, sex, region)")
  expect_identical(sum(startsWith(capture.output(print(found)), "Stata: ")), 1L)
})

test_that("rendered example code operates on the supplied columns", {
  data <- tibble::tibble(income = c(10, 20, 30, 40))
  code <- findit(xtile, quartile, income)$r[1]
  environment <- list2env(list(
    data = data,
    mutate = dplyr::mutate,
    xtile = xtile
  ))
  result <- eval(parse(text = code), envir = environment)
  expect_identical(result$income, data$income)
  expect_s3_class(result$quartile, "ordered")
  expect_identical(as.integer(result$quartile), 1:4)
})

test_that("first-argument specificity survives supplied names", {
  expect_identical(
    findit("reg robust", income, age)$r[1],
    'fixest::feols(income ~ age, data = data, vcov = "hetero")'
  )
  expect_identical(
    findit("merge keep(match)", person)$r[1],
    'inner_join(data1, data2, by = "person")'
  )
})

test_that("ambiguous and incompatible hints keep their alternatives", {
  for (query in list(quote(findit(egen, row)), quote(findit(egen, rowm)))) {
    out <- capture.output(print(eval(query)))
    expect_gt(sum(startsWith(out, "Stata: ")), 1L)
    expect_lte(sum(startsWith(out, "Stata: ")), 5L)
  }
  out <- capture.output(print(findit(tab, chi2, exact)))
  expect_identical(sum(startsWith(out, "Stata: ")), 2L)
})

test_that("variable-list sites preserve direction, exclusion and model terms", {
  expect_identical(
    findit(egen, output, a, b, c, rowlast)$r[1],
    "mutate(data, output = coalesce(c, b, a))"
  )
  expect_identical(
    findit(stcox, age, income)$r[1],
    "survival::coxph(survival::Surv(time, died) ~ age + income, data = data)"
  )
  expect_identical(
    findit(drop, age, income)$r[1],
    "select(data, -c(age, income))"
  )
  expect_identical(
    findit(mvdecode, age, income)$r,
    findit(mvdecode)$r
  )
})

test_that("non-syntactic names keep valid replay hints and reference quoting", {
  found <- findit(su, `first name`, age)
  expect_identical(found$stata[1], "summarize `first name` age")
  hint <- attr(found, "input")
  expect_identical(hint, "findit(su, `first name`, age)")
  expect_silent(parse(text = hint))
})

test_that("cross-language operands bind without requiring retained model context", {
  found <- findit(help, myfun)
  expect_identical(found$stata[1], "help myfun")
  expect_identical(found$r[1], "help(myfun)")
  found <- findit(estimates, myfit, store)
  expect_identical(found$stata[1], "estimates store myfit")
  expect_identical(found$r[1], "myfit <- lm(y ~ x, data = data)")
})

test_that("templates explicitly cover the complete catalogue", {
  data <- findit_entries()
  templates <- findit_templates()
  expect_identical(names(templates), data$id)
  for (i in seq_len(nrow(data))) {
    template <- templates[[i]]
    expect_type(template$variables, "character")
    expect_length(template$meaning, 1L)
    expect_type(template$default, "logical")
    variables <- if (length(template$variables)) {
      paste0("column", seq_along(template$variables))
    } else {
      character()
    }
    rendered <- findit_render(template, variables)
    expect_silent(parse(text = rendered$r, encoding = "UTF-8"))
  }
})
