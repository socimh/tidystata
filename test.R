# install.packages("fs", repos = "https://cloud.r-project.org")
library(tidyverse)

# Load the current package
devtools::load_all()

# Test the summ() function
test_result <- summ(1:10)
print(test_result)

# Generate a complex tibble for testing
complex_tibble <- tibble(
  id = 1:100,
  group = sample(letters[1:5], 100, replace = TRUE),
  value = rnorm(100, mean = 50, sd = 10),
  date = seq.Date(Sys.Date() - 99, Sys.Date(), by = "day"),
  flag = sample(c(TRUE, FALSE), 100, replace = TRUE),
  category = sample(c("A", "B", "C", "D"), 100, replace = TRUE),
  score = runif(100, min = 0, max = 100),
  nested_list = map(1:100, ~ list(
    x = rnorm(3),
    y = sample(letters, 3),
    z = runif(1)
  ))
)

# Test summ() on the complex tibble
summ_by_group <- complex_tibble %>%
  group_by(group) %>%
  summarise(
    total_value = summ(value),
    mean_score = mean(score),
    count = n()
  )

print(summ_by_group)
