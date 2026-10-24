# row_*(), std(), pc() and is_first() against Stata's egen
# (data-raw/stata-parity/egen.do).
reference <- stata_fixture("egen-output")
values <- reference[c("a", "b", "c", "d")]

test_that("row functions match egen row*()", {
  expect_stata_equal(row_mean(values), reference$r_mean)
  expect_stata_equal(row_sum(values), reference$r_total)
  expect_stata_equal(row_min(values), reference$r_min)
  expect_stata_equal(row_max(values), reference$r_max)
  expect_stata_equal(row_median(values), reference$r_median)
  expect_stata_equal(row_sd(values), reference$r_sd)
  expect_identical(row_miss(values), as.integer(reference$r_miss))
  expect_identical(row_non_miss(values), as.integer(reference$r_nonmiss))
})

test_that("std() and pc() match egen std() and pc(), overall and by group", {
  expect_stata_equal(std(reference$a), reference$s_std)
  expect_stata_equal(std(reference$a, mean = 50, sd = 10), reference$s_std_m)
  expect_stata_equal(pc(reference$d), reference$s_pc)
  expect_stata_equal(pc(reference$d, prop = TRUE), reference$s_prop)
  grouped <- dplyr::mutate(
    reference,
    b_std = std(a),
    b_pc = pc(d),
    .by = g
  )
  expect_stata_equal(grouped$b_std, reference$b_std)
  expect_stata_equal(grouped$b_pc, reference$b_pc)
})

test_that("is_first() matches egen tag()", {
  expect_identical(is_first(reference$g), reference$t_tag == 1)
  expect_identical(
    is_first(reference$g, .missing = TRUE),
    reference$t_tag_m == 1
  )
  expect_identical(is_first(reference$a, reference$b), reference$t_tag_ab == 1)
})
