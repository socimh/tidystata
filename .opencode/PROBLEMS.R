
c:\Users\socim\AppData\Roaming\Tick_Tick\Image\689ddecdeba71e00000004b6.png


c:\Users\socim\AppData\Roaming\Tick_Tick\Image\689de10feba71e00000004cd.png


valid_cum should be ordered in .desc
cut_quantile(x, 2) may not split the sample equally. like neigbhor_grid_out_500m should be 9.89, but the cut is different.

simplify s_time() to 1m1s, etc.
tic() toc() return this: Cross-fitting Random Forest and XGBoost: 499.88 sec elapsed

tab() works but tab1() does not when there are expressions:
tab(
    t1 = temp == 26, 
    t2 = temp == 39
  )

for tidy_coef:
coef = sprintf("%.3f%s (%.3f)", estimate, star, std_error)

should read SAS and SPSS datasets.

add_pca():
pc <- tb %>%
  princomp(
    ~ eduy + log10_family_income + as.numeric(neighborhood_type3g3),
    data = .,
    na.action = na.exclude
  )

tb <- tb %>%
  mutate(
    ses = summary(pc)$scores %>%
      as_tibble() %>%
      pull(1)
  )

summ() should have an arg that drops all missing values of the ".by" vars
summ() does not deal with values such as -Inf

c:\Users\socim\AppData\Roaming\Tick_Tick\Image\6863f456e7bef60000000081.png
but, tab1(tb, everything()) works

compare with this function:
> describe(select(w4a_tb, scared:hopeless)) %>% tibble()
# A tibble: 10 × 13
    vars     n  mean    sd median trimmed   mad   min   max range  skew kurtosis
   <int> <dbl> <dbl> <dbl>  <dbl>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>    <dbl>
 1     1  1929  1.21 0.573      1    1.06     0     1     4     3  3.03   9.19
 2     2  1929  1.16 0.495      1    1.03     0     1     4     3  3.52  13.4
 3     3  1929  1.41 0.753      1    1.23     0     1     4     3  1.86   2.69
 4     4  1929  1.31 0.681      1    1.14     0     1     4     3  2.44   5.61
 5     5  1929  1.20 0.555      1    1.05     0     1     4     3  3.22  10.7
 6     6  1929  1.73 0.995      1    1.55     0     1     4     3  1.14   0.0575
 7     7  1929  1.23 0.611      1    1.06     0     1     4     3  3.03   9.02
 8     8  1929  1.23 0.625      1    1.06     0     1     4     3  3.03   8.95
 9     9  1929  1.30 0.689      1    1.12     0     1     4     3  2.50   5.77
10    10  1929  1.23 0.631      1    1.05     0     1     4     3  3.05   8.92
# ℹ 1 more variable: se <dbl>



tab() may print_headtail() by default?



tidy_coef() does not work for lmer() result

> m1 <- lmer(paste0("cognition ~", CVs, "+ d_igc_lib + d_igc_pubssr + (1 | dcc$
+              as.formula(), data = w4a_tb)
> m1
Linear mixed model fit by REML ['lmerMod']
Formula: cognition ~ age + male + eduy + married + whwk2 + bornhk + social1 +
    social2 + social3 + ca_ses16 + d_igc_community + d_igc_pos +
    d_igc_health + d_igc_eld + d_igc_station + t_ma16 + d_igc_lib +
    d_igc_pubssr + (1 | dcca)
   Data: w4a_tb
REML criterion at convergence: 187.5198
Random effects:
 Groups   Name        Std.Dev.
 dcca     (Intercept) 1.688
 Residual             1.208
Number of obs: 48, groups:  dcca, 45
Fixed Effects:
    (Intercept)              age             male             eduy
       11.22176         -0.08627         -1.06171          0.24854
        married            whwk2           bornhk          social1
       -1.19467          1.13987         -0.92053          0.30032
        social2          social3         ca_ses16  d_igc_community
        0.77897         -0.19928          0.27153         -0.25511
      d_igc_pos     d_igc_health        d_igc_eld    d_igc_station
        1.03170         -0.80543          0.17838         -0.07085
         t_ma16        d_igc_lib     d_igc_pubssr
        0.11188          0.88902         -0.53781
> tidy_coef(m1)
Error in `dplyr::mutate()`:
ℹ In argument: `star = dplyr::case_when(...)`.
Caused by error in `dplyr::case_when()`:
! Failed to evaluate the left-hand side of formula 1.
Caused by error:
! object 'p.value' not found
Run `rlang::last_trace()` to see where the error occurred.
> tidy_coef(m1)
Error in `dplyr::mutate()`:
ℹ In argument: `star = dplyr::case_when(...)`.
Caused by error in `dplyr::case_when()`:
! Failed to evaluate the left-hand side of formula 1.
Caused by error:
! object 'p.value' not found
Run `rlang::last_trace()` to see where the error occurred.
> tidy(m1)
# A tibble: 21 × 6
   effect group term        estimate std.error statistic
   <chr>  <chr> <chr>          <dbl>     <dbl>     <dbl>
 1 fixed  NA    (Intercept)  11.2       8.59       1.31
 2 fixed  NA    age          -0.0863    0.0599    -1.44
 3 fixed  NA    male         -1.06      0.711     -1.49
 4 fixed  NA    eduy          0.249     0.0970     2.56
 5 fixed  NA    married      -1.19      0.915     -1.31
 6 fixed  NA    whwk2         1.14      0.996      1.14
 7 fixed  NA    bornhk       -0.921     0.929     -0.991
 8 fixed  NA    social1       0.300     0.515      0.583
 9 fixed  NA    social2       0.779     0.537      1.45
10 fixed  NA    social3      -0.199     0.350     -0.570
# ℹ 11 more rows
# ℹ Use `print(n = ...)` to see more rows







cannot cut a dummy?
> y_cut = cut_quantile(commtype, 10, labels = FALSE)

cut_... with weights

std() a varaible
pct() a var
fre() is slower than tab()

print_all() as print all rows and all columns

write sth better than reformulate()
lm(reformulate(c("ecdi", "girl", "preterm", "countyid"), asq_var), data = .)

c:\Users\socim\AppData\Roaming\Tick_Tick\Image\682a20b6e7bef600000002e0.png

> tb %>%
+   feols(
+     asq_time ~ eduy + family_income + 
+     age_in_month + asq_score + mother |
+       kinderid,
+     data = .
+   ) %>%
+   tidy_coef()
Error in tidy_coef(.) : tidy() does not work for the model.
In addition: Warning messages:
1: In broom.mixed::tidy(model) : restarting interrupted promise evaluation
2: In broom.mixed::tidy(model) : restarting interrupted promise evaluation
> tb %>%
+   feols(
+     asq_time ~ eduy + family_income + 
+     age_in_month + asq_score + mother |
+       kinderid,
+     data = .
+   )
Error in feols(asq_time ~ eduy + family_income + age_in_month + asq_score +  :
  The variable 'age_in_month' is in the RHS (first part) of the formula but
not in the data set.

------




create a column type for stars: If empty, do not show ""

add row_total() 
row_max() does not deal with missing values, but row_mean() does.

summ() allow any q*n* ranging from 1 to 99

s_select() tells me what are the wrong variable names.

https://hughjonesd.github.io/huxtable/design-principles.html

as_dummy()

fre() is very slow in some cases: 
![image](67f0b50de7bef600000001cc/67f0b50de7bef600000001cb.png)
when ss23_tb is large but the filter() outcome is very small like the figure shows. 

I wanna know the specific n of obs and r2 for each model when I run tidy_coef(). Could be messages. r2, ll, and n by default, could choose any others that appear in glance()

Error in tidy_coef(.) : tidy() does not work for the model.
It could be because the model is totally wrong/broken.

run multiple regression models at the same time in R.
Something like globals in stata.

show_percentile(), something like:
tb %>%
  arrange(age_in_months) %>%
  select(age_in_months) %>%
  print_interval(20)
  
  write_as_docx() writes a tb into a docx wrapping the flexable.


tidy_coef() make two versions. One with coef only, and one very similar to Stata.

cut_headtail() in a separate package?

`codebook` Warning messages:
1: In lab[i] <- at$label :
  number of items to replace is not a multiple of replacement length


The following object is masked from 'package:scales':
pvalue

flextable() is better than as_flextable()?

### make the text consistent
count():
Storing counts in `nn`, as `n` already present in input
ℹ Use `name = "new_name"` to pick a new name.

tab():
+   tab(n)
To avoid duplicates in `tab()`, `n` is renamed as `.n`.
Better to rename them before `tab()`.

print_everything()
print_tail()

time
output of @time in Julia:
208.896641 seconds (197.50 k allocations: 2.350 GiB, 0.09% gc time, 0.00% compilation time)

when there is Inf, summ() returns NA. Is it correct?

ds() should recursively work on ds()
make ds() a vector possible

use() or import() to replace read_data()

tab(.desc) does not descend groups

summ() is way too slow

reg: tidyselect variables

browse_interval(), etc.

s_mean() to replace mean() ?
tb %>%
    s_mean(statue)

pmin(x, 10) works, 
but row_min(x, 10) does not.

s_time() can be inserted in a long pipe multiple times.

> grid_sf %>%
+   summ(consumed_1)
New names:
• `geometry` -> `geometry...1`
• `geometry` -> `geometry...3`
# A tibble: 3 × 8
  name            type        n unique   min  mean    sd   max
  <chr>           <chr>   <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
1 ***geometry...1 POLYGON 89838  89838    NA   NA    NA     NA
2 consumed_1      dbl     89838   2688     0  206.  514. 21020
3 ***geometry...3 POLYGON 89838  89838    NA   NA    NA     NA

should remove geometries 


capture() in R

if a function ends with an error, I also want to know its s_time()

### .by cannot be type in summ()
> lines_tb %>%
+   summ(margin, .by = type)
Error in `tidyr::unnest()`:
! Can't duplicate names between the affected columns and the
  original data.
✖ These names are duplicated:
  ℹ `type`, from `value`.
ℹ Use `names_sep` to disambiguate using the column name.
ℹ Or use `names_repair` to specify a repair strategy.
Run `rlang::last_trace()` to see where the error occurred.


when tidy_coef() a misspecified model with an error (e.g., the data do not include a variable listed), it throws a wrong error message:
Error in tidy_coef(.) : tidy() does not work for the model.

if cut_quantile has a group like 29%-35%, as 10 groups , the 3rd would be 20%-35%, which is too large. Adjust to make sure the groups are equally distributed.

For a variable with units (m^2) but no missing values 
Error in if (type == "hvn_lbll") { : 
  missing value where TRUE/FALSE needed

pull categories of some given variable(s)

create a drop() function
wrapper function for  filter(!is.na(x))
wrapper function for select(matches("x")): browse()?

convert sf to tibble before tab() or summ()

print_system() that randomly sample rows
print_sample() as the standard output
print_head()
print_tail()
glimpse_headtail()
glimpse_head()
etc.

try to keep the property of a interval tb or a headtail tb

rewrite summ() to make it faster

if summ() a scalar, it should be better add the variable first with all-the-same value
tb %>%
  summ(1, .by = c(girl, ca3_2))

  print_interval(Inf) does not work

tab(.by) missing values should be at the bottom of each group, rather than at the very end.

deal with missing variables as Stata

summ() a single vector

rewrite regress() based on dvs, ivs, and cvs

add missing grouping variables when calling 
diamonds %>%
+   group_by(clarity) %>%
+   summ(price) %>%
+   print(n = Inf)
Adding missing grouping variables: `clarity`
Adding missing grouping variables: `clarity`

tab1() different factors cannot be combined
diamonds %>%
  tab1(where(~ !is.numeric(.)), .type = "tibble")
  
  summ(.stat = "sum") throws an error? add it.
  summ(dttm) returns numeric mean, min, and max?
  
  s_plot(date, logical) returns a character * character plot, where I expect a continuous smoothed plot.
  
  s_plot(var, n) for tab() results: (each group only has one obs.)
  1: Groups with fewer than two datapoints have been dropped.
ℹ Set `drop = FALSE` to consider such groups for position adjustment purposes. 

cannot replace a labelled factor

tb %>%
+   s_plot(prosperity)
Error: value for 'GeomMapTile' not found+ 

corr()
smart correlation:
tb %>%
  select(prosperity, asq_z, asqse_z) %>%
  cor(use = "pairwise.complete.obs") %>%
  as_tibble() %>%
  mutate(
    .var = names(.),
    .before = 1
  )
  
  summ(finish_asqse, .by = age_groups)
  not automatically sorted by the grouping var
  
  deal with sf in all functions
  
  suns_15m_isochrone %>%
    s_plot(resid)
    w2_adult_nomi2 %>%
  s_plot(livingness_workday)
  Error: value for 'GeomMapTile' not found
  
  fields = row_non_miss(matches("field.*new")) gives:
  fields$value
  .$value should be removed.
  
  no sum in summ() result, even no sum in summ(.detail)
  
  value_if_na(4)
  Caused by error in `value_if_na()`:
! argument ".value" is missing, with no default
As a common error, it should be clearly stated.

row_sum() adds na.rm = FALSE argument

row_non_miss() sdistance_migrant_nomi$value


add possible quantile numbers in statart
`post_tb %>%
  summarise(
    q = quantile(female, c(0.025, .5, 0.975)) %>% list(),
    mean = mean(female)
  ) %>%
  unnest_wider(q)`
  
  TRUE or FALSE or NA, the order shall be defined in tab2(), fre2(), etc.
  
  summ(x, by = (g1, g2)) returns unarranged varaible values
  
  summ() remove row if n == 0
  
summ() give some types that are preloaded senarios, such as stata-type

  If there is only one variable, do not show name column in summ()
  
  datetime becomes pure numbers instead of datetime format in summ() 且 no sd!
  
  add a drop() function
  
  is it possible to tab() a vector? like tab(tb$x)
  
  select an element from a list: create a function?
  
  neighbor_live_pct2 = pmin(neighbor_live_pct2, .5) works, but 
  neighbor_live_pct2 = row_min(neighbor_live_pct2, .5)
  does not. 
  Try to make it work.
  
  revise the scale()
  
