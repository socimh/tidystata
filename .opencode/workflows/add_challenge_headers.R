#!/usr/bin/env Rscript
# Add standardized challenge headers to test files

test_info <- list(
  browse = list(
    functions = "browse", 
    behaviors = "interactive data browsing, display modes", 
    edges = "large datasets, console width"
  ),
  complex_tb = list(
    functions = "codebook, complex_tab", 
    behaviors = "variable metadata, type detection", 
    edges = "complex data types, nested structures"
  ),
  cut = list(
    functions = "cut_quantile, cut_length, cut_breaks", 
    behaviors = "interval creation, numeric binning", 
    edges = "boundary values, duplicate breaks"
  ),
  esttab = list(
    functions = "esttab", 
    behaviors = "regression table formatting, model comparison", 
    edges = "complex models, missing statistics"
  ),
  fre = list(
    functions = "fre", 
    behaviors = "frequency tables, output formats", 
    edges = "large factor levels, missing values"
  ),
  fre1 = list(
    functions = "fre1", 
    behaviors = "single variable frequency", 
    edges = "edge cases in univariate analysis"
  ),
  fre2 = list(
    functions = "fre2", 
    behaviors = "bivariate frequency tables", 
    edges = "sparse tables, zero cells"
  ),
  `import-export` = list(
    functions = "read_data, write_data", 
    behaviors = "data import/export, format conversion", 
    edges = "encoding issues, large files"
  ),
  names = list(
    functions = "ds, ds_as_column, names_as_column, variables", 
    behaviors = "variable listing, name manipulation", 
    edges = "special characters, long names"
  ),
  row_egen = list(
    functions = "row_mean, row_sum, row_max, row_min, row_median, row_var, row_sd", 
    behaviors = "row-wise aggregation, missing value handling", 
    edges = "all-NA rows, single column"
  ),
  s_match = list(
    functions = "s_match", 
    behaviors = "pattern matching, regex support", 
    edges = "complex patterns, no matches"
  ),
  s_select = list(
    functions = "s_select", 
    behaviors = "enhanced select, data-masking", 
    edges = "complex expressions, tidyselect integration"
  ),
  s_try = list(
    functions = "s_try", 
    behaviors = "safe evaluation, error handling", 
    edges = "nested expressions, type coercion"
  ),
  s_type = list(
    functions = "s_type, s_unit", 
    behaviors = "type detection, unit extraction", 
    edges = "ambiguous types, compound units"
  ),
  set_seed = list(
    functions = "set_seed", 
    behaviors = "reproducibility, pipeline integration", 
    edges = "parallel processing, multiple seeds"
  ),
  summ = list(
    functions = "summ, tabstat", 
    behaviors = "summary statistics, group analysis", 
    edges = "empty groups, all-NA columns"
  ),
  tab = list(
    functions = "tab", 
    behaviors = "cross-tabulation, percentage calculation", 
    edges = "high-dimensional tables, sparse data"
  ),
  tab1 = list(
    functions = "tab1", 
    behaviors = "one-way tables", 
    edges = "single category, all unique values"
  ),
  tab2 = list(
    functions = "tab2", 
    behaviors = "two-way tables", 
    edges = "empty cells, marginal totals"
  ),
  timer = list(
    functions = "timer", 
    behaviors = "execution timing, performance measurement", 
    edges = "very fast/slow operations, nested timing"
  ),
  type_conversion = list(
    functions = "as_character, as_numeric", 
    behaviors = "type coercion, format preservation", 
    edges = "lossy conversions, factor handling"
  )
)

for (test_name in names(test_info)) {
  info <- test_info[[test_name]]
  file_path <- sprintf("tests/testthat/test-%s.R", test_name)
  
  if (file.exists(file_path)) {
    content <- readLines(file_path)
    
    # Create challenge header
    header <- c(
      sprintf("# CHALLENGE: Comprehensive testing for %s", info$functions),
      sprintf("# FUNCTIONS: %s", info$functions),
      sprintf("# KEY BEHAVIORS: %s", info$behaviors),
      sprintf("# EDGE CASES: %s", info$edges),
      ""
    )
    
    # Check if already has CHALLENGE header
    if (!any(grepl("^# CHALLENGE:", content))) {
      # Find where to insert (after description comments, before library)
      lib_line <- which(grepl("^library", content))[1]
      if (!is.na(lib_line) && lib_line > 1) {
        # Insert before library calls
        new_content <- c(content[1:(lib_line-1)], header, content[lib_line:length(content)])
        writeLines(new_content, file_path)
        cat(sprintf("Updated: %s\n", file_path))
      }
    } else {
      cat(sprintf("Already has header: %s\n", file_path))
    }
  } else {
    cat(sprintf("Not found: %s\n", file_path))
  }
}

cat("Done!\n")
