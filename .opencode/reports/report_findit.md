# Function: findit()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-19 21:26:34 | **Status:** PASS

## Example 1: a bare Stata word, with Stata's abbreviations

```
# Stata to R: 6 entries

regress y x1 x2                   # Linear regression [stats]
  fit <- lm(y ~ x1 + x2, data = data)
regress y x1 x2, robust           # Heteroskedasticity-robust standard errors [fixest]
  fixest::feols(y ~ x1 + x2, data = data, vcov = "hetero")
regress y x1 x2, vce(cluster id)  # Clustered standard errors [fixest]
  fixest::feols(y ~ x1 + x2, data = data, cluster = ~id)
regress y i.group c.x1##c.x2      # Factor variables and interactions [stats]
  lm(y ~ factor(group) + x1 * x2, data = data)
regress y x [pweight = wt]        # Regression with sampling weights [fixest]
  fixest::feols(y ~ x, data = data, weights = ~wt, vcov = "hetero")
regress y ib3.group               # Choose the base category [stats]
  lm(y ~ relevel(factor(group), ref = "3"), data = data)
```

## Example 2: extra words put the closest idiom first

```
# Stata to R: 10 entries
# "merge" is a Stata command and an R function.

## Stata command
merge 1:1 id using data2, keep(match)                           # Keep matched rows only [dplyr]
  inner_join(data1, data2, by = "id")
merge 1:1 id using data2, keep(match) keepusing(id) nogenerate  # Keep rows of data1 whose id is in data2 [dplyr]
  semi_join(data1, data2, by = "id")
merge 1:1 id using data2                                        # Merge with a match report [statart]
  s_merge(data1, data2, "1:1", by = "id")

## R function: merge() [base]: Merge two data frames (base R)
  Related Stata: merge

# ... and 7 more. Use `print(n = Inf)` to see all, or `View()`.
# Stata to R: 28 entries

bysort group: egen x_avg = mean(x)  # Group statistic as a new variable [dplyr]
  mutate(data, x_avg = mean(x, na.rm = TRUE), .by = group)
egen x_avg = mean(x)                # Sample statistic as a new variable [dplyr]
  mutate(data, x_avg = mean(x, na.rm = TRUE))

# ... and 26 more. Use `print(n = Inf)` to see all, or `View()`.
```

## Example 3: packages beyond statart

```
# Stata to R: 1 entry

binscatter y x  # Binned scatter plot [binsreg]
  binsreg::binsreg(y, x, data = data)
# Stata to R: 1 entry

winsor2 x, cuts(1 99)  # Winsorise at the 1st and 99th percentiles [datawizard]
  mutate(data, x_w = datawizard::winsorize(x, threshold = 0.01))
# Stata to R: 7 entries

svy: mean x                 # Survey-weighted mean [srvyr]
  summarise(design, x = srvyr::survey_mean(x, na.rm = TRUE))
svy: tabulate x             # Survey-weighted proportions [srvyr]
  design %>% group_by(x) %>% summarise(p = srvyr::survey_prop())
svy: regress y x            # Survey-weighted regression [survey]
  survey::svyglm(y ~ x, design = design)
svy: mean x, over(g)        # Survey-weighted means by group [srvyr]
  design %>% group_by(g) %>% summarise(x = srvyr::survey_mean(x, na.rm = TRUE))
svy, subpop(rural): mean x  # Subpopulation estimate [srvyr]
  design %>% filter(rural == 1) %>% summarise(x = srvyr::survey_mean(x, na.rm = TRUE))
svy: proportion x           # Survey-weighted proportions with intervals [srvyr]
  design %>% group_by(x) %>% summarise(p = srvyr::survey_prop(vartype = "ci"))
svy: logit y x              # Survey-weighted logit [survey]
  survey::svyglm(y ~ x, design = design, family = quasibinomial())
# Stata to R: 1 entry

stcox x1 x2  # Cox proportional hazards model [survival]
  survival::coxph(survival::Surv(time, died) ~ x1 + x2, data = data)
```

## Example 4: R functions and words with both meanings

```
# Stata to R: 1 entry

## R function: left_join() [dplyr]: Merge keeping all rows of the first table
merge 1:1 id using data2, keep(master match)  # Keep all rows of the master data [dplyr]
  left_join(data1, data2, by = "id")
# Stata to R: 2 entries
# "log" is a Stata command and an R function.

## Stata command
log using results.log  # Record console output in a file [base]
  sink("results.log")

## R function: log() [base]: Logarithm (natural by default)
generate y = ln(x)     # Natural logarithm [base]
  mutate(data, y = log(x))
```

## Example 5: no match suggests similar commands

```
No Stata command, R function or keyword matches "regresss".
Did you mean: regress, regexs, ivregress?
Use `findit()` for the whole list.
```

## Example 6: the whole list

```

statart   dplyr   tidyr  fixest
     76      78       6      11
Entries: 414
```
