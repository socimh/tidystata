# Function: codebook()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-19 01:02:41 | **Status:** PASS

## Example 1: Basic codebook

```r
codebook(mtcars)
```

**Output:**

```
   variable   type  n unique
1       mpg double 32     25
2       cyl double 32      3
3      disp double 32     27
4        hp double 32     22
5      drat double 32     22
6        wt double 32     29
7      qsec double 32     30
8        vs double 32      2
9        am double 32      2
10     gear double 32      3
11     carb double 32      6
```

## Example 2: With starwars data

```r
codebook(starwars)
```

**Output:**

```
# A tibble: 14 x 4
   variable   type          n unique
   <chr>      <chr>     <int>  <int>
 1 name       character    87     87
 2 height     integer      81     45
 3 mass       double       59     38
 4 hair_color character    82     11
 5 skin_color character    87     31
 6 eye_color  character    87     15
 7 birth_year double       43     36
 8 sex        character    83      4
 9 gender     character    83      2
10 homeworld  character    77     48
11 species    character    83     37
12 films      list         87     24
13 vehicles   list         87     11
14 starships  list         87     16
```

## Example 3: Select specific columns

```r
codebook(mtcars, mpg, hp, wt)
```

**Output:**

```
  variable   type  n unique
1      mpg double 32     25
2       hp double 32     22
3       wt double 32     29
```

## Example 4: With tidyselect

```r
codebook(starwars, ends_with('color'))
```

**Output:**

```
# A tibble: 3 x 4
  variable   type          n unique
  <chr>      <chr>     <int>  <int>
1 hair_color character    82     11
2 skin_color character    87     31
3 eye_color  character    87     15
```

## Example 5: Numeric variables only

```r
codebook(starwars, where(is.numeric))
```

**Output:**

```
# A tibble: 3 x 4
  variable   type        n unique
  <chr>      <chr>   <int>  <int>
1 height     integer    81     45
2 mass       double     59     38
3 birth_year double     43     36
```

## Example 6: With expressions

```r
codebook(starwars, height > 0)
```

**Output:**

```
# A tibble: 1 x 4
  variable   type        n unique
  <chr>      <chr>   <int>  <int>
1 height > 0 logical    81      1
```

