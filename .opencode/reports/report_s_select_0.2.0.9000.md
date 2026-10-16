# Function: s_select()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-16 18:04:57 | **Status:** PASS

## Example 1: Select columns by name

```r
s_select(mtcars, mpg, cyl, hp)
```

**Output:**

```
                     mpg cyl  hp
Mazda RX4           21.0   6 110
Mazda RX4 Wag       21.0   6 110
Datsun 710          22.8   4  93
Hornet 4 Drive      21.4   6 110
Hornet Sportabout   18.7   8 175
Valiant             18.1   6 105
Duster 360          14.3   8 245
Merc 240D           24.4   4  62
Merc 230            22.8   4  95
Merc 280            19.2   6 123
Merc 280C           17.8   6 123
Merc 450SE          16.4   8 180
Merc 450SL          17.3   8 180
Merc 450SLC         15.2   8 180
Cadillac Fleetwood  10.4   8 205
Lincoln Continental 10.4   8 215
Chrysler Imperial   14.7   8 230
Fiat 128            32.4   4  66
Honda Civic         30.4   4  52
Toyota Corolla      33.9   4  65
Toyota Corona       21.5   4  97
Dodge Challenger    15.5   8 150
AMC Javelin         15.2   8 150
Camaro Z28          13.3   8 245
Pontiac Firebird    19.2   8 175
Fiat X1-9           27.3   4  66
Porsche 914-2       26.0   4  91
Lotus Europa        30.4   4 113
Ford Pantera L      15.8   8 264
Ferrari Dino        19.7   6 175
Maserati Bora       15.0   8 335
Volvo 142E          21.4   4 109
```

## Example 2: With expressions

```r
s_select(mtcars, mpg, kml = mpg * 0.425)
```

**Output:**

```
                     mpg     kml
Mazda RX4           21.0  8.9250
Mazda RX4 Wag       21.0  8.9250
Datsun 710          22.8  9.6900
Hornet 4 Drive      21.4  9.0950
Hornet Sportabout   18.7  7.9475
Valiant             18.1  7.6925
Duster 360          14.3  6.0775
Merc 240D           24.4 10.3700
Merc 230            22.8  9.6900
Merc 280            19.2  8.1600
Merc 280C           17.8  7.5650
Merc 450SE          16.4  6.9700
Merc 450SL          17.3  7.3525
Merc 450SLC         15.2  6.4600
Cadillac Fleetwood  10.4  4.4200
Lincoln Continental 10.4  4.4200
Chrysler Imperial   14.7  6.2475
Fiat 128            32.4 13.7700
Honda Civic         30.4 12.9200
Toyota Corolla      33.9 14.4075
Toyota Corona       21.5  9.1375
Dodge Challenger    15.5  6.5875
AMC Javelin         15.2  6.4600
Camaro Z28          13.3  5.6525
Pontiac Firebird    19.2  8.1600
Fiat X1-9           27.3 11.6025
Porsche 914-2       26.0 11.0500
Lotus Europa        30.4 12.9200
Ford Pantera L      15.8  6.7150
Ferrari Dino        19.7  8.3725
Maserati Bora       15.0  6.3750
Volvo 142E          21.4  9.0950
```

## Example 3: Empty selection returns full data

```r
s_select(mtcars)
```

**Output:**

```
                     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
Mazda RX4           21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
Mazda RX4 Wag       21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
Datsun 710          22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
Hornet 4 Drive      21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
Hornet Sportabout   18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
Valiant             18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
Duster 360          14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
Merc 240D           24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
Merc 230            22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
Merc 280            19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
Merc 280C           17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
Merc 450SE          16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
Merc 450SL          17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
Merc 450SLC         15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
Cadillac Fleetwood  10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
Lincoln Continental 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
Chrysler Imperial   14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
Fiat 128            32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
Honda Civic         30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
Toyota Corolla      33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
Toyota Corona       21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
Dodge Challenger    15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
AMC Javelin         15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
Camaro Z28          13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
Pontiac Firebird    19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
Fiat X1-9           27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
Porsche 914-2       26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
Lotus Europa        30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
Ford Pantera L      15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
Ferrari Dino        19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
Maserati Bora       15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
Volvo 142E          21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2
```

## Example 4: With tidyselect helpers

```r
s_select(mtcars, starts_with('d'))
```

**Output:**

```
                     disp dra
Mazda RX4           160.0 3.90
Mazda RX4 Wag       160.0 3.90
Datsun 710          108.0 3.85
Hornet 4 Drive      258.0 3.08
Hornet Sportabout   360.0 3.15
Valiant             225.0 2.76
Duster 360          360.0 3.21
Merc 240D           146.7 3.69
Merc 230            140.8 3.92
Merc 280            167.6 3.92
Merc 280C           167.6 3.92
Merc 450SE          275.8 3.07
Merc 450SL          275.8 3.07
Merc 450SLC         275.8 3.07
Cadillac Fleetwood  472.0 2.93
Lincoln Continental 460.0 3.00
Chrysler Imperial   440.0 3.23
Fiat 128             78.7 4.08
Honda Civic          75.7 4.93
Toyota Corolla       71.1 4.22
Toyota Corona       120.1 3.70
Dodge Challenger    318.0 2.76
AMC Javelin         304.0 3.15
Camaro Z28          350.0 3.73
Pontiac Firebird    400.0 3.08
Fiat X1-9            79.0 4.08
Porsche 914-2       120.3 4.43
Lotus Europa         95.1 3.77
Ford Pantera L      351.0 4.22
Ferrari Dino        145.0 3.62
Maserati Bora       301.0 3.54
Volvo 142E          121.0 4.11
```

## Example 5: Error handling for non-existent column

```r
tryCatch(
  s_select(mtcars, nonexistent_col),
  error = function(e) cat('Error:', e$message, '\n')
)
```

**Output:**

```
Error: Neither <tidy-select> nor <data-masking> recognised the input.
  select() error: Can't select columns that don't exist.
x Column `nonexistent_col` doesn't exist.
  mutate() error: i In argument: `nonexistent_col`.
Caused by error:
! object 'nonexistent_col' not found
```

## Example 6: With data.table

```r
if (requireNamespace('data.table', quietly = TRUE)) {
  library(data.table)
  dt <- as.data.table(mtcars)
  result <- s_select(dt, mpg, hp)
  class(result)
  print(result)
}
```

**Output:**

```

Attaching package: 'data.table'


The following objects are masked from 'package:dplyr':

    between, first, las


The following object is masked from 'package:base':

    %notin%


Class: data.table, data.frame
      mpg    hp
    <num> <num>
 1:  21.0   110
 2:  21.0   110
 3:  22.8    93
 4:  21.4   110
 5:  18.7   175
 6:  18.1   105
 7:  14.3   245
 8:  24.4    62
 9:  22.8    95
10:  19.2   123
11:  17.8   123
12:  16.4   180
13:  17.3   180
14:  15.2   180
15:  10.4   205
16:  10.4   215
17:  14.7   230
18:  32.4    66
19:  30.4    52
20:  33.9    65
21:  21.5    97
22:  15.5   150
23:  15.2   150
24:  13.3   245
25:  19.2   175
26:  27.3    66
27:  26.0    91
28:  30.4   113
29:  15.8   264
30:  19.7   175
31:  15.0   335
32:  21.4   109
      mpg    hp
    <num> <num>
```

