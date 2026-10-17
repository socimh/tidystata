# Function: browse()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-16 21:08:32 | **Status:** PASS


Attaching package: 'dplyr'


The following object is masked from 'package:statart':

    starwars


The following objects are masked from 'package:stats':

    filter, lag


The following objects are masked from 'package:base':

    intersect, setdiff, setequal, union


## Example 1: Browse basic data frame

```r
browse(mtcars)
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

## Example 2: Browse with filter

```r
browse(mtcars, cyl == 4)
```

**Output:**

```
                    cyl == 4
Mazda RX4              FALSE
Mazda RX4 Wag          FALSE
Datsun 710              TRUE
Hornet 4 Drive         FALSE
Hornet Sportabout      FALSE
Valiant                FALSE
Duster 360             FALSE
Merc 240D               TRUE
Merc 230                TRUE
Merc 280               FALSE
Merc 280C              FALSE
Merc 450SE             FALSE
Merc 450SL             FALSE
Merc 450SLC            FALSE
Cadillac Fleetwood     FALSE
Lincoln Continental    FALSE
Chrysler Imperial      FALSE
Fiat 128                TRUE
Honda Civic             TRUE
Toyota Corolla          TRUE
Toyota Corona           TRUE
Dodge Challenger       FALSE
AMC Javelin            FALSE
Camaro Z28             FALSE
Pontiac Firebird       FALSE
Fiat X1-9               TRUE
Porsche 914-2           TRUE
Lotus Europa            TRUE
Ford Pantera L         FALSE
Ferrari Dino           FALSE
Maserati Bora          FALSE
Volvo 142E              TRUE
```

## Example 3: Browse with selection

```r
browse(mtcars, mpg, hp, wt)
```

**Output:**

```
                     mpg  hp    wt
Mazda RX4           21.0 110 2.620
Mazda RX4 Wag       21.0 110 2.875
Datsun 710          22.8  93 2.320
Hornet 4 Drive      21.4 110 3.215
Hornet Sportabout   18.7 175 3.440
Valiant             18.1 105 3.460
Duster 360          14.3 245 3.570
Merc 240D           24.4  62 3.190
Merc 230            22.8  95 3.150
Merc 280            19.2 123 3.440
Merc 280C           17.8 123 3.440
Merc 450SE          16.4 180 4.070
Merc 450SL          17.3 180 3.730
Merc 450SLC         15.2 180 3.780
Cadillac Fleetwood  10.4 205 5.250
Lincoln Continental 10.4 215 5.424
Chrysler Imperial   14.7 230 5.345
Fiat 128            32.4  66 2.200
Honda Civic         30.4  52 1.615
Toyota Corolla      33.9  65 1.835
Toyota Corona       21.5  97 2.465
Dodge Challenger    15.5 150 3.520
AMC Javelin         15.2 150 3.435
Camaro Z28          13.3 245 3.840
Pontiac Firebird    19.2 175 3.845
Fiat X1-9           27.3  66 1.935
Porsche 914-2       26.0  91 2.140
Lotus Europa        30.4 113 1.513
Ford Pantera L      15.8 264 3.170
Ferrari Dino        19.7 175 2.770
Maserati Bora       15.0 335 3.570
Volvo 142E          21.4 109 2.780
```

## Example 4: Browse with both filter and selection

```r
browse(mtcars, cyl == 4, mpg, hp)
```

**Output:**

```
                    cyl == 4  mpg  hp
Mazda RX4              FALSE 21.0 110
Mazda RX4 Wag          FALSE 21.0 110
Datsun 710              TRUE 22.8  93
Hornet 4 Drive         FALSE 21.4 110
Hornet Sportabout      FALSE 18.7 175
Valiant                FALSE 18.1 105
Duster 360             FALSE 14.3 245
Merc 240D               TRUE 24.4  62
Merc 230                TRUE 22.8  95
Merc 280               FALSE 19.2 123
Merc 280C              FALSE 17.8 123
Merc 450SE             FALSE 16.4 180
Merc 450SL             FALSE 17.3 180
Merc 450SLC            FALSE 15.2 180
Cadillac Fleetwood     FALSE 10.4 205
Lincoln Continental    FALSE 10.4 215
Chrysler Imperial      FALSE 14.7 230
Fiat 128                TRUE 32.4  66
Honda Civic             TRUE 30.4  52
Toyota Corolla          TRUE 33.9  65
Toyota Corona           TRUE 21.5  97
Dodge Challenger       FALSE 15.5 150
AMC Javelin            FALSE 15.2 150
Camaro Z28             FALSE 13.3 245
Pontiac Firebird       FALSE 19.2 175
Fiat X1-9               TRUE 27.3  66
Porsche 914-2           TRUE 26.0  91
Lotus Europa            TRUE 30.4 113
Ford Pantera L         FALSE 15.8 264
Ferrari Dino           FALSE 19.7 175
Maserati Bora          FALSE 15.0 335
Volvo 142E              TRUE 21.4 109
```

## Example 5: Browse starwars

```r
browse(starwars, species == 'Human', name, height, mass)
```

**Output:**

```
# A tibble: 87 x 4
   `species == "Human"` name               height  mass
   <lgl>                <chr>               <int> <dbl>
 1 TRUE                 Luke Skywalker        172    77
 2 FALSE                C-3PO                 167    75
 3 FALSE                R2-D2                  96    32
 4 TRUE                 Darth Vader           202   136
 5 TRUE                 Leia Organa           150    49
 6 TRUE                 Owen Lars             178   120
 7 TRUE                 Beru Whitesun Lars    165    75
 8 FALSE                R5-D4                  97    32
 9 TRUE                 Biggs Darklighter     183    84
10 TRUE                 Obi-Wan Kenobi        182    77
# i 77 more rows
```

