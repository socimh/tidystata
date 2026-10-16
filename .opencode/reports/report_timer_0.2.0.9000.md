# Function: timer()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-15 22:21:42 | **Status:** PASS

## Example 1: Basic timing

```r
timer(Sys.sleep(0.5))
```

**Output:**

```
Time spent: 0.509s
 
```

## Example 2: Timing with return value

```r
result <- timer(mean(1:1000000))
result
```

**Output:**

```
Time spent: 0.004s
 
```

**Return value:**

```
[1] 500000.5
```

## Example 3: Quick operation

```r
timer(1 + 1)
```

**Output:**

```
Time spent: 0.000s
 
```

## Example 4: With pipe operations

```r
result <- mtcars %>% filter(cyl == 4) %>% timer()
nrow(result)
```

**Output:**

```
Time spent: 0.001s
 
```

**Return value (nrow):**

```
[1] 11
```

## Example 5: Multiple operations

```r
timer({
  x <- rnorm(10000)
  mean(x)
  sd(x)
})
```

**Output:**

```
Time spent: 0.001s
 
```

## Example 6: Duration formatting helper

```r
duration_to_chr(0.05)   # Sub-second
duration_to_chr(5.23)   # Seconds
duration_to_chr(75)     # Minutes
duration_to_chr(3700)   # Hours
```

**Output:**

```
[1] "0.050s"
[1] "5.23s"
[1] "1m15s"
[1] "1h1m"
```

