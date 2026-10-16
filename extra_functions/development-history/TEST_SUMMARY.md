# Test Suite Summary for statart Package

## Test Files Created

| Test File | Lines | Tests | Focus |
|-----------|-------|-------|-------|
| test-tab.R | 472 | 53 | tab() function - complex groupings, missing values, edge cases |
| test-tab1.R | 489 | 42 | tab1() function - output formats, multiple vars, NAs |
| test-tab2.R | 487 | 48 | tab2() function - cross-tabulation, totals, flip |
| test-fre.R | 424 | 45 | fre() function - frequency tables with totals |
| test-fre1.R | 457 | 41 | fre1() function - one-by-one frequencies |
| test-fre2.R | 478 | 44 | fre2() function - cross-tab with totals |
| test-summ.R | 534 | 56 | summ() and tabstat() - statistics, grouping |
| test-complex_tb.R | 311 | 28 | codebook() - complex scenarios only |
| **TOTAL** | **3652** | **357** | **All challenging tests** |

## Installation Status

**Issue**: Cannot update `rlang` package from 1.1.4 to >= 1.1.6
- The package is locked by another R process
- This prevents running the tests with `testthat`

## How to Complete Installation

### Option 1: Restart R and Run (Recommended)

1. **Close all R/RStudio sessions**
2. Open a fresh R session
3. Run: `source("install_statart_deps.R")`

### Option 2: Manual Installation

```r
# Install rlang first (required for testthat >= 3.0.0)
install.packages("rlang")

# Then install testthat
install.packages("testthat")

# Verify versions
packageVersion("rlang")   # Should be >= 1.1.6
packageVersion("testthat") # Should be >= 3.0.0
```

### Option 3: Run Tests Without testthat

```r
# Load the package
devtools::load_all()

# Source individual test files
source("tests/testthat/test-tab.R")
# Check console for errors
```

## Test Coverage Areas

All 357 tests focus on challenging scenarios:

### Missing Values
- Strategic NA placement in variables
- Cascading NAs across columns
- All NA variables
- Factor with NA levels
- Haven labelled with NA values

### Complex Grouping
- Multi-level hierarchies (3+ grouping vars)
- Groups with single observations
- NAs in grouping variables
- Groups that become empty after filtering

### Boolean Expressions
- Complex AND/OR combinations
- is.na() function usage
- %in% operator
- All FALSE conditions

### Edge Cases
- Empty data frames
- Single row datasets
- Extreme numeric values (Inf, -Inf, NaN)
- Floating point precision issues
- All identical values
- All unique values

### Special Data Types
- Date and POSIXct variables
- Haven labelled variables
- Factors with many levels
- Difftime objects
- Integer64 (bit64)

### Unicode & Special Characters
- CJK characters (中文, 日本語)
- Arabic text (مرحبا)
- Emoji (🎉, 😢)
- Right-to-left text
- Zero-width characters

### Output Formats
- tibble vs list vs flextable
- Duration formatting (long vs compact)
- Table mode vs list mode

### Real-world Scenarios
- Clinical trial data
- Survey responses
- Time series with gaps
- Quality control metrics
- Financial data

## Files Created

1. **install_statart_deps.R** - Package installation script
2. **run_tests.R** - Test execution script
3. **test-tab.R** through **test-fre2.R** - Test files
4. **test-complex_tb.R** - Updated codebook tests

## Next Steps

1. Complete the installation by updating rlang
2. Run: `devtools::test()` or `testthat::test_dir("tests/testthat")`
3. Review any failing tests
4. (Remember: Do NOT fix the original code - only report failures)

## Test Categories Summary

- **Basic functionality**: 0 tests (removed - too simple)
- **Challenging edge cases**: 357 tests
  - Missing value handling: ~80 tests
  - Grouping scenarios: ~60 tests
  - Boolean expressions: ~40 tests
  - Special data types: ~50 tests
  - Unicode/encoding: ~30 tests
  - Large data scenarios: ~40 tests
  - Error handling: ~30 tests
  - Real-world scenarios: ~27 tests
