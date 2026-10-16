# Verification Script: New summ() Features
# Tests: .mode, .duration_format, data.table support, class preservation

library(dplyr)
library(tibble)

# Check if data.table is available
has_data_table <- requireNamespace("data.table", quietly = TRUE)
if (has_data_table) {
  library(data.table)
}

# Load statart
devtools::load_all(".", quiet = TRUE)

cat("\n========================================\n")
cat("NEW FEATURES VERIFICATION\n")
cat("========================================\n\n")

# Create test data with mixed types
test_data <- data.frame(
  num1 = c(1:10, NA),
  num2 = rnorm(11),
  date_var = c(as.Date("2020-01-01") + 0:9, NA),
  datetime_var = c(as.POSIXct("2020-01-01 12:00:00", tz = "UTC") + 0:9*86400, NA)
)

cat("\n========================================\n")
cat("TEST 1: List Mode (Default)\n")
cat("========================================\n")

result_list <- summ(test_data, .mode = "list")
cat("\nList mode result:\n")
print(result_list)

cat("\n========================================\n")
cat("TEST 2: Table Mode\n")
cat("========================================\n")

result_table <- summ(test_data, .mode = "table")
cat("\nTable mode result:\n")
print(result_table)

cat("\n========================================\n")
cat("TEST 3: Duration Format - Long\n")
cat("========================================\n")

result_long <- summ(test_data, date_var, .duration_format = "long")
cat("\nLong format (should show 'X days'):\n")
print(result_long)

cat("\n========================================\n")
cat("TEST 4: Duration Format - Compact\n")
cat("========================================\n")

result_compact <- summ(test_data, date_var, .duration_format = "compact")
cat("\nCompact format (should show 'Xd'):\n")
print(result_compact)

cat("\n========================================\n")
cat("TEST 5: data.frame Input → data.frame Output\n")
cat("========================================\n")

df_input <- as.data.frame(test_data)
result_df <- summ(df_input, num1, num2, .mode = "table")
cat("\nInput class:", class(df_input)[1], "\n")
cat("Output class:", class(result_df)[1], "\n")
print(result_df)

cat("\n========================================\n")
cat("TEST 6: tibble Input → tibble Output\n")
cat("========================================\n")

tbl_input <- as_tibble(test_data)
result_tbl <- summ(tbl_input, num1, num2, .mode = "table")
cat("\nInput class:", class(tbl_input)[1], "\n")
cat("Output class:", class(result_tbl)[1], "\n")
print(result_tbl)

if (has_data_table) {
  cat("\n========================================\n")
  cat("TEST 7: data.table Input → data.table Output\n")
  cat("========================================\n")
  
  dt_input <- as.data.table(test_data)
  result_dt <- summ(dt_input, num1, num2, .mode = "table")
  cat("\nInput class:", class(dt_input)[1], "\n")
  cat("Output class:", class(result_dt)[1], "\n")
  print(result_dt)
} else {
  cat("\n========================================\n")
  cat("TEST 7: SKIPPED (data.table not installed)\n")
  cat("========================================\n")
}

cat("\n========================================\n")
cat("TEST 8: List Mode Returns Raw Date Types\n")
cat("========================================\n")

result_dates <- summ(test_data, date_var, datetime_var, .mode = "list")
cat("\nResult structure:\n")
print(str(result_dates))

cat("\n========================================\n")
cat("VERIFICATION COMPLETE\n")
cat("========================================\n")
