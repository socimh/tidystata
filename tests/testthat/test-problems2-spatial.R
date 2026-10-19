test_that("spatial aggregation counts attributes without sticky geometry", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    data.frame(x = c(1, 1, 2), g = c("a", "a", "b"), lon = 1:3, lat = 4:6),
    coords = c("lon", "lat")
  )
  ordinary <- sf::st_drop_geometry(d)
  calls <- list(
    tab = function(x) tab(x, x),
    tab1 = function(x) tab1(x, x),
    tab2 = function(x) tab2(x, g, x),
    fre = function(x) fre(x, x),
    fre1 = function(x) fre1(x, x),
    fre2 = function(x) fre2(x, g, x),
    summ = function(x) summ(x, x),
    tabstat = function(x) tabstat(x, x)
  )
  for (call in calls) {
    expect_no_warning(actual <- call(d))
    expect_equal(actual, call(ordinary))
  }
  expect_equal(tab(d, x)$n, c(2L, 1L))
  expect_identical(summ(d, x, .name = TRUE)$name, "x")
  expect_s3_class(d, "sf")
  expect_identical(names(d), c("x", "g", "geometry"))
})

test_that("aggregation excludes alternate and additional geometry columns", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    tibble::tibble(x = c(1, 3, 5), g = c("b", "a", "b"), lon = 1:3, lat = 4:6),
    coords = c("lon", "lat"),
    sf_column_name = "shape"
  )
  d$extra_geometry <- sf::st_geometry(d)
  attributes_only <- tibble::tibble(x = d$x, g = d$g)
  expect_equal(summ(d, x, .by = g), summ(attributes_only, x, .by = g))
  expect_equal(tab(d, x, .by = g), tab(attributes_only, x, .by = g))
  expect_equal(tab1(d), tab1(attributes_only))
  expect_warning(spatial_summary <- summ(d), "g is non-numeric")
  expect_warning(attribute_summary <- summ(attributes_only), "g is non-numeric")
  expect_equal(spatial_summary, attribute_summary)
  expect_error(tab(d, shape), "shape")
  expect_error(summ(d, x, .by = shape), "shape")
  grouped <- dplyr::group_by(d, g)
  expect_equal(tab(grouped, x), tab(dplyr::group_by(attributes_only, g), x))
  expect_equal(summ(grouped, x), summ(dplyr::group_by(attributes_only, g), x))
})

test_that("spatial inspection and selection keep their geometry", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    data.frame(x = 1:2, lon = 1:2, lat = 3:4),
    coords = c("lon", "lat")
  )
  expect_true("geometry" %in% ds(d))
  expect_s3_class(s_select(d, x), "sf")
  expect_identical(sf::st_geometry(d), sf::st_geometry(s_select(d, x)))
})

test_that("explicit attribute grouping overrides inherited geometry groups", {
  skip_if_not_installed("sf")
  d <- sf::st_as_sf(
    tibble::tibble(x = c(1, 1, 2), g = c("a", "a", "b"), lon = 1:3, lat = 4:6),
    coords = c("lon", "lat")
  )
  grouped <- dplyr::group_by(d, geometry)
  for (fun in list(tab, fre, tab1, fre1, summ, tabstat)) {
    expect_equal(fun(grouped, x, .by = g), fun(d, x, .by = g))
    expect_error(fun(grouped, x), "Geometry.*grouping")
    expect_error(fun(d, x, .by = geometry), "geometry")
  }
})

test_that("data-frame sf objects keep added grouping columns", {
  skip_if_not_installed("sf")
  shape <- sf::st_read(
    system.file("shape/nc.shp", package = "sf"),
    quiet = TRUE
  )[1:12, c("NAME", "BIR74")]
  d <- dplyr::mutate(
    shape,
    grp = ifelse(BIR74 > 3000, "hi", "lo"),
    big = BIR74 > 1000
  )
  plain <- tibble::as_tibble(sf::st_drop_geometry(d))
  expect_equal(
    tab(d, big, .by = grp),
    as.data.frame(tab(plain, big, .by = grp))
  )
  expect_equal(
    fre(d, big, .by = grp),
    as.data.frame(fre(plain, big, .by = grp))
  )
  expect_named(tab1(d, .by = big), c("NAME", "BIR74", "grp"))
  expect_equal(
    fre1(d, grp, .by = big),
    lapply(fre1(plain, grp, .by = big), as.data.frame)
  )
  expect_equal(
    summ(d, BIR74, .by = grp),
    as.data.frame(summ(plain, BIR74, .by = grp))
  )
  expect_equal(
    tabstat(d, BIR74, .by = grp),
    as.data.frame(tabstat(plain, BIR74, .by = grp))
  )
  grouped <- dplyr::group_by(d, grp)
  expect_equal(tab(grouped, big), tab(plain, big, .by = grp))
  expect_warning(counts <- summ(d, .stat = "n"), "non-numeric")
  expect_identical(counts$name, c("BIR74", "big"))
})
