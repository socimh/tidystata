pacman::p_load(devtools, usethis, tidyverse, sloop, pkgdown, cpp11)
build_readme()

# usethis::use_pkgdown_github_pages()
# use_pkgdown()
# VPN set to 美国
pkgdown::build_site()
preview_site()

install.packages("htmltools")

devtools::install_github("socimh/statart")
library(statart)
sessionInfo()
library(statart)
ls("package:statart")

# Publish to cran
usethis::use_cran_comments()
urlchecker::url_check()
devtools::check(remote = TRUE, manual = TRUE)
devtools::check_win_devel()

usethis::use_news_md()
devtools::submit_cran()

install.packages("Matrix")
devtools::document()
devtools::load_all()

?browse



sample(1:10, 5) |>
   set_seed(123)

remotes::install_deps(dependencies = TRUE)

library(pkgbuild)
library(cpp11)
compile_dll(
  force = TRUE,
  compile_attributes =
    pkg_links_to_cpp11(
      "C:/Users/socim/AppData/Local/R/win-library/4.3/cpp11"
    )
)

iusethis::use_cpp11()
devtools::document()
devtools::load_all()
cpp11::cpp_register()

tibble(a = 1:5, b = 11:15) %>%
  mutate(across(everything(), as.double)) %>%
  row_max2()

load_all()
document()
check()
library(flextable)

lifeexp %>%
  summ(.by = region, .stat = "mean")

load_all()
lifeexp %>%
  codebook_detail()

means(1:10) |>
  s_try()


?view

diamonds |>
  mutate(cut = fct_rev(cut)) |>
  tab2(cut, color)
slice(1:10002) |>
  print(n = Inf)

library(tidyverse)

diamonds |>
  summarise(mean(carat), .by = everything())

document()
load_all()

?select
starwars %>% select(homeworld, height, mass)
select(diamonds, color)

extract_group_var(diamonds, color)

?rlang::quo_is_null

load_all()
summ(diamonds, .by = color)
summ(diamonds, .by = cut:color)

by <- enquo(by)

install.packages("nnet")

diamonds |>
  mutate(
    cut = as_numeric(cut) %>%
      if_else(. <= 3, 3, .) |>
      as_factor()
  ) %>%
  ?nnet::multinom(cut ~ x + y, data = .) |>
    broom::tidy()

install.packages("easystats")

load_all()
diamonds |>
  # mutate(
  #   cut = as_numeric(cut) %>%
  #     if_else(. <= 3, 3, .) |>
  #     as_factor()
  # ) |>
  regress(
    price ~ x + y + (1 | cut),
    model = "hlm"
  )


diamonds |>
  mutate(
    price5g = datawizard::categorize(
      price,
      split = "equal_range",
      n_groups = 5
    )
  ) |>
  summ(price, .by = price5g) |>
  mutate(range = max - min)

lm(price ~ x + y, data = diamonds) |>
  parameters::parameters() |>
  as_tibble()
# broom::tidy() |>
flextable::as_flextable()

codebook(diamonds)
library(easystats)
data_codebook(diamonds)
load_all()


diamonds |>
  mutate(
    q = cut_quantile(price, 5)
  ) |>
  tab(q)

cut_quantile(c(rep(1, 10), 1:20), labels = FALSE)
cut_length(c(rep(1, 10), 1:20), n = 5)
cut(c(rep(1, 10), 1:20), 5)
cut_breaks(rep(1, 10), labels = FALSE)
cut_breaks(1:10, breaks = c(3, 5), labels = FALSE, right = FALSE)
?categorize()
?cut
variables_search(lifeexp, "e")
# search value labels as well.
string <- "(?i)al"
codebook_detail(lifeexp, as_tibble = TRUE) %>%
  mutate(
    across(
      everything(),
      ~ ifelse(.x == "", NA, .x)
    ),
    .tmp_id = row_number()
  ) %>%
  group_by(row_id) %>%
  fill(everything(), .direction = "updown") %>%
  ungroup() %>%
  filter(
    str_detect(name, string) |
      str_detect(label, string) |
      str_detect(values, string) |
      str_detect(value_labels, string)
  ) %>%
  slice_min(.tmp_id, by = row_id) %>%
  select(name, label, values, value_labels) %>%
  view()

library(statart)
lifeexp |> codebook()
lifeexp |>
  mutate(x = units::set_units(1, "m")) |>
  data_codebook() |>
  as_tibble() |>
  rename_with(str_to_lower) |>
  rename_with(~ str_replace_all(., " ", "_")) |>
  rename(row_id = .row_id) |>
  flextable::as_flextable(max_row = Inf)


data_codebook(lifeexp) |>
  print_html()

?glm

tb <- s_print(seeds)
class(tb)
data_summary(diamonds)

data(iris)
out <- assign_labels(
  iris$Species,
  variable = "Labelled Species",
  values = c(`setosa` = "Spec1", `versicolor` = "Spec2", `virginica` = "Spec3")
)

out |>
  as_tibble() %>%
  mutate(value = 1) %>%
  .$value %>%
  attr(which = "label")

out |>
  as_tibble() |>
  codebook()

library(datawizard)

lifeexp |>
  data_codebook()

?ctl_new_rowid_pillar

tb |>
  s_print()
mutate(x = 1) |>
  # head(500) |>
  dim()

?replace
ifelse(1:5 %% 2 == 0, 1, NA) |>
  s_type()

load_all()
?na_if
tibble(
  a = c("a", "b", "c", NA_character_)
) |>
  mutate(a = value_if_na(a, "d"))
s_replace(a, "d", .if = a == "a")

?qcut
c(1:10) |>
  cut(breaks = c(1, 2:3, 5, 10), include.lowest = TRUE, ordered_result = TRUE)
c(1:10) |>
  cut(breaks = 3)
?variable
?s_match

summ(starwars, ends_with("color"))

tab1(starwars, ends_with("color"), .append = TRUE)

who
glimpse(who)
s_print(who)
s_print(who, interval = TRUE)
names_as_column(who)

rnorm(1e3) |>
  cut(breaks = 3, ordered_result = TRUE) |>
  as_tibble_col("x") |>
  fre(x)

diamonds |>
  group_by(color) |>
  summ()

diamonds |>
  slice_sample(n = 1e3) |>
  set_seed(123) %>%
  qplot(data = ., carat, price, fill = I("blue"))

diamonds |>
  slice_sample(n = 1e3) |>
  set_seed(123) |>
  s_plot(carat, price, fill = "blue")

vec <- 1:5e7 %>% as.double()
s_max(vec)
n_distinct10k(vec) %>% s_time()
n_distinct(vec) %>% s_time()
row_sum(diamonds, x:z)

aes_to_tbl() %>%
  print(n = 100)

tb <- tibble(
  x = 1:5,
  y = 2:6,
  z = 11:15
) %>%
  mutate(across(
    everything(),
    as.double
  ))
document()
check()
load_all()
usethis::use_release_issue()

view(diamonds)
check()
test()

mtcars %>%
  dplyr::mutate(mpg20 = mpg > 20) %>%
  regress(mpg20 ~ wt + hp, model = "logit")

tab(starwars) %>%
   print_headtail()
 fre1(starwars, 1)
fre1(starwars, .append = TRUE)


starwars |>
  tab1(s_match("*color"), .by = sex, .type = "list")
starwars |>
  fre(hair_color, .by = sex)

mtcars
test <- tibble(a = 1, b = 2, c = 3)

test |>
  add_row(a = 4)

test[-c(1)]
test |>
  discard_at(c("d"))

starwars |>
  tab1(sex, .by = gender)

starwars |>
  group_by(name, height) |>
  select(3)

tab1(height:mass, .by = gender)

row_unique(tb)
row_min(tb)
row_max(tb)
row_sum(tb)
row_mean(tb)
row_miss(tb)
row_non_miss(tb)

# cpp_source("D:/R/statart/src/sum.cpp")

row_sum(tb)[1:5]
dbl_sd(1:1e7 %>% as.double())
n_distinct(1:1e7 %>% as.double())

tb <- tibble(
  x1 = runif(1e4),
  x2 = runif(1e4),
  x3 = runif(1e4),
  x4 = runif(1e4),
  x5 = runif(1e4),
  x6 = runif(1e4),
  x7 = runif(1e4),
  x8 = runif(1e4),
  x9 = runif(1e4),
  x10 = runif(1e4)
)

cpp_source("D:/R/statart/src/sum.cpp")

bench::mark(
  f1 = tb %>% mutate(total = rowSums(pick(starts_with("x")))) %>% nrow(),
  f2 = tb %>% mutate(total = pmap_dbl(pick(starts_with("x")), sum)) %>% nrow(),
  f3 = tb %>% mutate(total = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10) %>% nrow(),
  f4 = tb %>% mutate(total = row_sum(starts_with("x"))) %>%
    nrow()
) %>%
  arrange(median)

bench::mark(
  f1 = tb %>% mutate(total = (x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10) / 10) %>% nrow(),
  f2 = tb %>% mutate(total = pick(starts_with("x"))) %>% nrow(),
  f3 = tb %>% mutate(total = rowMeans(pick(starts_with("x")))) %>% nrow(),
  f3a = tb %>% mutate(total = rowMeans(pick(starts_with("x")), na.rm = TRUE)) %>% nrow(),
  f3b = tb %>% mutate(total = pick(starts_with("x")) %>% as.matrix() %>% Rfast::rowmeans()) %>% nrow(),
  f4 = tb %>% mutate(total = row_mean(pick(starts_with("x")))) %>% nrow(),
  f5 = tb %>% mutate(total = row_mean2(starts_with("x"))) %>% nrow()
) %>%
  arrange(median)
Rfast::rowmeans()

bench::mark(
  f1 = mitb %>% rowMeans(na.rm = TRUE) %>% head(),
  f2 = mitb %>% row_mean() %>% head()
)

tibble(
  x = c(runif(1e4), rep(NA_real_, 1e4)),
  y = c(rep(NA_real_, 1e4), runif(1e4)),
  z = runif(2e4)
) %>%
  rowMeans(na.rm = TRUE) %>%
  head()

mitb <- tibble(
  x = c(runif(1e4), rep(NA_real_, 1e4)),
  y = c(rep(NA_real_, 1e4), runif(1e4)),
  z = runif(2e4)
)

bench::mark(
  f1 = mitb %>%
    mutate(
      across(
        everything(),
        ~ if_else(is.na(.), -Inf, .)
      )
    ) %>%
    data.frame.to_matrix() %>%
    rowMaxs(value = TRUE) %>%
    if_else(. == -Inf, NA_real_, .) %>%
    head(),
  f2 = mitb %>%
    row_max() %>%
    head()
)

install.packages("Rfast")

# pick() is faster than select(.)
load_all()
bench::mark(
  pmax.int = tb %>% mutate(total = pmax.int(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10)),
  pmap = tb %>% mutate(total = pmap_dbl(pick(starts_with("x")), max)),
  row_max = tb %>% mutate(total = row_max(starts_with("x"))),
  row_max2 = tb %>% mutate(total = row_max2(pick(starts_with("x")))),
  # Fast, but NAs are converted to 0.
  rowMaxs = tb %>% mutate(total = pick(starts_with("x")) %>% data.frame.to_matrix() %>% rowMaxs(value = TRUE)),
  apply = tb %>% mutate(total = apply(pick(starts_with("x")), 1, max, na.rm = TRUE))
) %>%
  arrange(median) %>%
    select(expression, median, mem_alloc)

tb2 <- tb %>% head(1e3)
bench::mark(
  pmax = tb2 %>% mutate(total = pmax(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10)),
  pmap = tb2 %>% mutate(total = pmap_dbl(pick(starts_with("x")), max)),
  # very slow & memory intensive
  c_across = tb2 %>% rowwise() %>%
    mutate(total = c_across(starts_with("x")) %>% max()) %>% ungroup(),
  row_max = tb2 %>% mutate(total = row_max(pick(starts_with("x")))),
  row_max2 = tb2 %>% mutate(total = row_max2(pick(starts_with("x"))))
) %>%
  arrange(median)



vec_tb1 <- runif(1e6) %>%
  c(rep(NA_real_, 1e6)) %>%
  tibble(a = .)
vec_tb2 <- runif(2e6) %>% tibble(a = .)
bench::mark(
  f1a = vec_tb1 %>% summarise(mean = mean(a, na.rm = TRUE)) %>% nrow(),
  f1b = vec_tb2 %>% summarise(mean = mean(a, na.rm = TRUE)) %>% nrow(),
  f2a = vec_tb1 %>% summarise(mean = mean(a)) %>% nrow(),
  f2b = vec_tb2 %>% summarise(mean = mean(a)) %>% nrow(),
  f3a = vec_tb1 %>% summarise(mean = s_mean(a)) %>% nrow(),
  f3b = vec_tb2 %>% summarise(mean = s_mean(a)) %>% nrow()
) %>%
  arrange(median)

vec_tb <- runif(1e6) %>%
  c(rep(NA_real_, 1e6)) %>%
  tibble(a = .)
bench::mark(
  f1a = vec_tb %>% summarise(mean = mean(a, na.rm = TRUE)) %>% nrow(),
  f2b = vec_tb %>% summarise(mean = mean(a)) %>% nrow(),
  f3a = vec_tb %>% summarise(mean = s_mean(a)) %>% nrow()
) %>%
  arrange(median)



vec <- sample(1:20, 1e4, replace = TRUE) %>% as.double()
s_mean(c(1:4, NA_integer_, NA_integer_) %>% as.double())
s_median(1:(1e5 + 1) %>% as.double())
s_median(1:4 %>% as.double())
s_unique2(c(1:5, 5, 1, 1, 1:5) %>% as.double())

# cpp_source("D:/R/statart/src/sum.cpp")
bench::mark(
  mean(vec) %>% length(),
  sum(vec) %>% length(),
  s_sum(vec) %>% length(),
  s_mean(vec) %>% length(),
  s_max(vec) %>% length(),
  dbl_sd(vec) %>% length(),
  n_distinct10k(vec) %>% length(),
  sd(vec) %>% length(),
  min(vec) %>% length(),
  max(vec) %>% length(),
  length(vec) %>% length(),
  n_distinct(vec) %>% length(),
  median(vec) %>% length(),
  s_median(vec) %>% length()
) %>%
  arrange(median)



vec_tb <- tibble(
  vec1 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec2 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec3 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec4 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec5 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec6 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec7 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec8 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec9 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double(),
  vec10 = sample(1:1e4, 1e5, replace = TRUE) %>% as.double()
)

mres <- bench::mark(
  f1 = vec_tb %>%
    summarise(
      across(
        everything(),
        n_distinct10k
      )
    ) %>% nrow(),
  f2 = vec_tb %>%
    summarise(
      across(
        everything(),
        n_distinct
      )
    ) %>% nrow()
) %>%
  arrange(median)
mres %>%
  print(width = Inf)


tibble(
  x = runif(1e4),
  y = runif(1e4),
  z = runif(1e4)
) %>%
  mutate(total = rowSums(pick(x, y, z))) %>%
  s_time()


# add works like a regular R function
add
add(1, 2, 3)

x <- runif(1e6)
y <- runif(1e6)

pmax(x, y) %>%
  s_time()
psum(x, y) %>%
  s_time()

load_all()
# 0.04 secs
tb <- tibble(x, y)
tb %>%
  mutate(max = pmax(x, y)) %>%
  s_print() %>%
  s_time()

# 0.03 secs
load_all()
tibble(x, y) %>%
  mutate(max = row_max(x, y)) %>%
  s_print() %>%
  s_time()

tibble(x, y) %>%
  mutate(max = row_max2(pick(x, y))) %>%
  s_print() %>%
  s_time()

# My row_max() is faster??
bench::mark(
  tb %>%
    mutate(max = pmax(x, y)),
  tb %>%
    mutate(max = row_max(x, y)),
  tb %>%
    mutate(max = row_max2(x, y))
)




# 43 secs
tb %>%
  rowwise() %>%
  mutate(temp = sum(c_across(ends_with("temp")), na.rm = TRUE)) %>%
  s_time()

# 0.005 secs
tb %>%
  mutate(temp = rowSums(pick(ends_with("temp")))) %>%
  select(ends_with("temp")) %>%
  s_time()

# 0.005 secs
tb %>%
  mutate(temp = pmax(pick(ends_with("temp")))) %>%
  select(ends_with("temp")) %>%
  s_time()

# 0.196 secs
tb %>%
  mutate(temp = pmap_dbl(pick(ends_with("temp")), max)) %>%
  select(ends_with("temp")) %>%
  s_time()

?rowSums


?mutate
load_all()
tibble(x = c(1:100, 190:200)) %>%
  s_plot(1, x, geom = c("violin", "boxplot"))
  s_ggsave()

tibble(x = c(1:100, 190:200)) %>%
  ggplot() +
  art_violin(aes(1, x))


gg <- ggplot(iris, aes(Species, Sepal.Length)) +
  geom_violinbox()
s_ggsave(gg)

iris
gg <- ggplot(iris, aes(Species, Sepal.Width)) +
  geom_violinbox()
s_ggsave(gg, "plot2.png")

load_all()
starwars %>%
  filter(mass < 500) %>%
  s_plot(height, mass) %>%
  s_ggsave("plot.png")

plot_tb <- tibble(
  x = sample(1:8, 5e3, prob = 1:8, replace = TRUE),
  y = sample(1:8, 5e3, prob = 1:8, replace = TRUE)
)

load_all()
plot_tb %>%
  s_plot(x, y) %>%
  s_ggsave("plot.png")

load_all()
gg <- tibble(
  x = sample(c(T, F), 1e2, replace = TRUE, prob = c(.3, .7))
) %>%
  s_plot(x) +
  geom_text(aes(x, after_stat(count) * .5, label = after_stat(count)), stat = "count")
s_ggsave(gg, "plot.png")

# Labelling the upper hinge of a boxplot,
# inspired by June Choe
# Labelling a bar plot
ggplot(mpg, aes(class)) +
  geom_bar() +
  geom_text(
    aes(
      y = after_stat(count + 2),
      label = after_stat(count)
    ),
    stat = "count"
  )

vec <- 1:5 * 10
s_type(vec)

load_all()
plot_tb %>%
  s_plot(factor(x), factor(y)) %>%
  s_ggsave("plot.png")

plot_tb %>%
  s_plot(factor(x), y) %>%
  s_ggsave("plot.png")


lifeexp %>%
  ggplot() +
  geom_bar(aes(x = region))

lifeexp %>%
  s_plot(gnppc, lexp, fill = as_character(region)) %>%
  s_ggsave()

ggplot(starwars) +
  geom_smooth(aes(x = height, y = mass), method = "lm")

starwars %>%
  filter(mass < 500) %>%
  s_plot(height, mass, geom = c("smooth", "point"))
starwars %>%
  filter(mass < 500) %>%
  s_plot(height, mass, geom = c("point", "smooth"))

document()
check()

load_all()
codebook(starwars)
codebook(lifeexp)
variables(lifeexp)

lifeexp
load_all()
# change_ggplot_style()
s_plot(lifeexp, region, NULL)
s_plot(lifeexp, NULL, region)
s_plot(lifeexp, factor(region))
s_plot(lifeexp, country)
s_plot(lifeexp, country, region)
s_plot(lifeexp, region, country)
s_plot(lifeexp, popgrowth)
s_plot(lifeexp, safewater)
s_plot(data = lifeexp, gnppc, lexp, fill = as_character(region))
s_plot(data = lifeexp, gnppc, lexp, fill = seq_along(country))
s_plot(lifeexp, gnppc, lexp) +
  scale_x_log10()


s3_dispatch(s_type(lifeexp))

s3_methods_generic("mutate")
s3_methods_generic("select")

s3_methods_class("ordered")
s3_methods_class("data.frame") |> print(n = 100)
s3_methods_class("tbl_df") |> print(n = 100)

tb <- class_tbl(lifeexp, "head_tail", 5)

tb
s3_methods_generic(class_tbl(lifeexp, "head_tail", 5))
s3_methods_generic("class_tbl")
s3_class(tb)
str(tb)
unclass(tb)
tb


s3_methods_generic("tbl_sum")
s3_methods_generic("ctl_new_rowid_pillar")
s3_methods_generic("tbl_format_footer")

s3_methods_class("head_tail")
