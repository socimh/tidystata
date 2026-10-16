# Test Issue A1: summ() - .na.rm=TRUE with single observation groups

library(statart)
library(dplyr)

# Create test data as described in the issue
df <- data.frame(g = c("a", "a", "b"), x = c(1, 2, NA))
print("Test data:")
print(df)

# Test with .na.rm=TRUE
print("\nResult with .na.rm=TRUE:")
result <- summ(df, x, .by = g, .na.rm = TRUE)
print(result)

# Expected behavior:
# Group "a" should have: min=1, max=2, sd calculated
# Group "b" should have: min=NA, max=NA (since it has only NA values)

# Let's also test what happens without .na.rm
print("\nResult without .na.rm:")
result2 <- summ(df, x, .by = g, .na.rm = FALSE)
print(result2)

# Test case 2: Single observation group (not NA)
df2 <- data.frame(g = c("a", "a", "b"), x = c(1, 2, 3))
print("\nTest data 2 (no NAs):")
print(df2)
print("\nResult:")
result3 <- summ(df2, x, .by = g)
print(result3)

# Test case 3: Single observation with actual value
df3 <- data.frame(g = c("a", "b", "b"), x = c(1, 2, NA))
print("\nTest data 3 (group b has one value and one NA):")
print(df3)
print("\nResult with .na.rm=TRUE:")
result4 <- summ(df3, x, .by = g, .na.rm = TRUE)
print(result4)
