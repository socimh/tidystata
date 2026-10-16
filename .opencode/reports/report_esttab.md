# Function: esttab()

**Generated:** 2026-03-03 23:09:15

---

Loading required package: Matrix
 
## Example 1: Simple linear regression

```r
model <- lm(mpg ~ wt, data = mtcars)
esttab(model)
```

**Output:**

```
# A tibble: 2 × 3
  term        coef             star 
  <chr>       <glue>           <chr>
1 (Intercept) 37.285***
(1.878) ***  
2 wt          -5.344***
(0.559) ***  
```

## Example 2: Multiple regression

```r
model <- lm(mpg ~ wt + hp + cyl, data = mtcars)
esttab(model)
```

**Output:**

```
# A tibble: 4 × 3
  term        coef             star 
  <chr>       <glue>           <chr>
1 (Intercept) 38.752***
(1.787) "***"
2 wt          -3.167***
(0.741) "***"
3 hp          -0.018
(0.012)    ""   
4 cyl         -0.942+
(0.551)   "+"  
```

## Example 3: Logistic regression (GLM)

```r
model <- glm(vs ~ wt + disp, data = mtcars, family = binomial)
esttab(model)
```

**Output:**

```
# A tibble: 3 × 3
  term        coef           star 
  <chr>       <glue>         <chr>
1 (Intercept) 1.609
(2.439)   ""   
2 wt          1.626
(1.491)   ""   
3 disp        -0.034*
(0.015) "*"  
```

## Example 4: Linear mixed effects (lmer)

```r
model <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
esttab(model)
```

**Output:**

```
# A tibble: 6 × 5
  term                  coef              star  effect   group   
  <chr>                 <glue>            <chr> <chr>    <chr>   
1 (Intercept)           251.405***
(6.825) "***" fixed    <NA>    
2 Days                  10.467***
(1.546)  "***" fixed    <NA>    
3 sd__(Intercept)       24.741
()          ""    ran_pars Subject 
4 cor__(Intercept).Days 0.066
()           ""    ran_pars Subject 
5 sd__Days              5.922
()           ""    ran_pars Subject 
6 sd__Observation       25.592
()          ""    ran_pars Residual
```

## Example 5: With custom statistics

```r
model <- lm(mpg ~ wt, data = mtcars)
esttab(model, stats = c('n.obs', 'r.squared'))
```

**Output:**

```
# A tibble: 4 × 3
  term        coef             star 
  <chr>       <glue>           <chr>
1 (Intercept) 37.285***
(1.878) "***"
2 wt          -5.344***
(0.559) "***"
3 n.obs       32               ""   
4 r.squared   0.753            ""   
```

## Example 6: With custom format

```r
model <- lm(mpg ~ wt, data = mtcars)
esttab(model, format = '{estimate} ({std.error})')
```

**Output:**

```
# A tibble: 2 × 3
  term        coef           star 
  <chr>       <glue>         <chr>
1 (Intercept) 37.285 (1.878) ***  
2 wt          -5.344 (0.559) ***  
```

## Example 7: With factor variables

```r
mtcars$cyl_f <- factor(mtcars$cyl)
model <- lm(mpg ~ wt + cyl_f, data = mtcars)
esttab(model)
```

**Output:**

```
# A tibble: 4 × 3
  term        coef             star 
  <chr>       <glue>           <chr>
1 (Intercept) 33.991***
(1.888) ***  
2 wt          -3.206***
(0.754) ***  
3 cyl_f6      -4.256**
(1.386)  **   
4 cyl_f8      -6.071***
(1.652) ***  
```

## Example 8: With interaction terms

```r
model <- lm(mpg ~ wt * hp, data = mtcars)
esttab(model)
```

**Output:**

```
# A tibble: 4 × 3
  term        coef             star 
  <chr>       <glue>           <chr>
1 (Intercept) 49.808***
(3.605) ***  
2 wt          -8.217***
(1.270) ***  
3 hp          -0.120***
(0.025) ***  
4 wt:hp       0.028***
(0.007)  ***  
```


