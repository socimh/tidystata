# Problems and Issues

Quick reference for current bugs and feature requests in statart.

## Active Issues (Needs Fix)

### Issue A1: summ() - .na.rm=TRUE with single observation groups

**Priority:** Medium | **Function:** `summ()`

**Problem:** When using `.na.rm=TRUE` with `.by` grouping, single observation groups show the value in min/max instead of NA.

**Example:**

```r
df <- data.frame(g = c("a", "a", "b"), x = c(1, 2, NA))
summ(df, x, .by = g, .na.rm = TRUE)
# Group "b" shows: min=4, max=4 (should be NA, NA for single observation after NA removal)
```

**Expected:** Single observation groups should have NA for min/max when there's only one value.

**Status:** 🔴 Active

---

### Issue A2: summ() - .stat performance optimization

**Priority:** High | **Function:** `summ()`

**Problem:** Custom `.stat` selection calculates ALL statistics then subsets, rather than only calculating requested statistics. This makes `.stat = c("mean", "sd")` slower than calling `summ()` without `.stat`.

**Current behavior:**

- Calls `.detail = TRUE` internally
- Calculates all 18 statistics
- Then subsets to only requested stats

**Expected behavior:**

- Only calculate requested statistics
- Should be faster when requesting fewer stats

**Verification needed:**

- Benchmark with large dataset using `benchmark` package
- Compare timing: `.stat = c("mean", "sd")` vs full `summ()`

**Status:** 🔴 Active

---

### Issue A3: summ() - Remove .name argument

**Priority:** Low | **Function:** `summ()`

**Problem:** The `.name` argument (default TRUE, can be FALSE to omit name column) has no clear use case. It adds complexity without clear benefit.

**Suggested action:**

- Deprecate `.name` argument
- Always include name column
- Simplify function signature

**Status:** 🟡 Pending Decision

---

### Issue A4: Test Coverage - Insufficient test scenarios

**Priority:** High | **Function:** All functions

**Problem:** Current tests only have 2-3 test scenarios per function. Need comprehensive testing with 20+ scenarios per function.

**Requirements:**

- **20 tests for each major function:** summ(), tab(), tab1(), fre(), esttab(), etc.
- **Test datasets should include:**
  - More complex variables
  - Greater number of variables
  - Edge cases (strange distributions)
  - Rare scenarios
- **Progressive complexity:** Start simple, increase complexity

**Functions needing tests:**

- [ ] summ() - 20 tests
- [ ] tab() - 20 tests
- [ ] tab1() - 20 tests
- [ ] fre() - 20 tests
- [ ] esttab() - 20 tests
- [ ] codebook() - 20 tests
- [ ] timer() - 10 tests
- [ ] s_select() - 10 tests

**Test data requirements:**

- Logical variables treated as numeric in tibbles
- Complex nested structures
- Various NA patterns
- Extreme values (Inf, -Inf, very large/small numbers)
- Different data types (integer, double, Date, POSIXct, character, factor, logical)

**Status:** 🔴 Active

---

### Issue A5: Logical variables in summ()

**Priority:** Medium | **Function:** `summ()`

**Problem:** Need to verify how logical variables are handled in tibbles. They should be treated as numeric (0/1) for summary statistics.

**Test case:**

```r
complex_tb <- tibble::tibble(
  logical_var = c(TRUE, FALSE, TRUE, NA)
)
summ(complex_tb)
# Should treat logical as numeric
```

**Status:** 🟡 Needs Verification

---

## Recently Resolved Issues ✓ (2026-03-02)

### summ() - Date/Datetime Formatting

**Issue 3.1 & 3.3: Date/Datetime formatting - FIXED**

- ✅ mean, min, max now return actual Date/POSIXct types in list mode
- ✅ SD format now configurable: "long" ("548 days") or "compact" ("548d")
- ✅ summ() now preserves input class: data.frame → data.frame, tibble → tibble, data.table → data.table
- ✅ Added `.mode` parameter: "list" (default) returns grouped tables by type, "table" returns single combined table
- ✅ Added `.duration_format` parameter for controlling duration display

**New Parameters:**

- `.mode = c("list", "table")`: "list" groups by variable type, "table" combines into single table
- `.duration_format = c("long", "compact")`: "long" shows "548 days", "compact" shows "548d"

**Implementation Details:**

- `data.table` added to Suggests in DESCRIPTION
- Input class detected and output converted back to match
- List mode returns `$numeric`, `$date`, `$datetime` tables with proper types
- Table mode converts all values to character for compatibility

---

### Data Type Support

**Issue: data.table support - FIXED**

- ✅ summ() now supports data.table input/output
- ✅ data.table added to Suggests
- ✅ Automatic conversion: data.table → tibble → process → data.table

---

### Output Mode for summ()

**Issue: Grouped output by variable type - FIXED**

- ✅ List mode (default) now returns separate tables by type:
  - `$numeric`: all numeric variables (doubles, integers)
  - `$date`: all Date variables (actual Date type preserved)
  - `$datetime`: all POSIXct variables (actual POSIXct type preserved)
- ✅ Each table has appropriate column types for its data
- ✅ Duration columns (sd, mad, etc.) use configured format

---

## Resolved Issues ✓

### Summary Statistics (summ) - Fixed v0.2.x

| ID  | Resolution                               |
| --- | ---------------------------------------- |
| 3.1 | Inf/-Inf now shown in min/max correctly  |
| 3.2 | Dates/datetimes now formatted as strings |
| 3.3 | as_numeric() called once per var; faster |
| 3.4 | Added .na.rm arg (default FALSE)         |
| 3.5 | Added .name arg (default TRUE)           |

### Tabulation (tab, tab1, fre) - Fixed v0.2.x

| ID  | Resolution                               |
| --- | ---------------------------------------- |
| 2.1 | tab1()/fre1() now support expressions    |
| 2.2 | fre() ~10x faster (add_total rewritten)  |
| 2.3 | Missing values at bottom of each group   |
| 2.4 | .n renaming documented (known behaviour) |
| 2.5 | .desc now sorts non-NA desc, NA last     |

### Helper Functions - Fixed v0.2.x

| ID  | Resolution                                  |
| --- | ------------------------------------------- |
| 4.1 | cut_quantile() rank-based fallback for ties |
| 4.2 | row_min/max/mean/sum return plain vectors   |
| 4.3 | codebook() Hmisc warning suppressed         |

### Estimation Tables (esttab) - Fixed v0.2.0

| ID  | Version | Resolution                   |
| --- | ------- | ---------------------------- |
| 1.1 | v0.2.0  | lmer p-value fallback        |
| 1.2 | v0.2.0  | Graceful broom errors        |
| 1.3 | v0.2.0  | glue-style format arg        |
| 1.4 | v0.2.0  | stats arg with Stata aliases |
| 1.5 | v0.2.0  | Simplified output            |

---

## Feature Requests - Pending

| Feature                | Priority | Notes                     |
| ---------------------- | -------- | ------------------------- |
| Data import (SAS/SPSS) | LOW      | use() or import()         |
| PCA helper             | LOW      | add_pca()                 |
| write_as_docx          | LOW      | Export to Word            |
| s_mean                 | LOW      | mean() replacement?       |
| SF support             | LOW      | Handle sf objects         |
| drop()                 | LOW      | filter(!is.na(x)) wrapper |

---

*Last Updated: 2026-03-02*
