fastLink: Fast Probabilistic Record Linkage
===========================================

Installation Instructions
-------------------------

As `fastLink` is hosted on a private Github repo, you will need a Github personal access token (PAT) to install using `devtools`. Instructions for setting up your own PAT can be found at <https://github.com/settings/tokens>.

Once you have a PAT, `fastLink` can be installed from the private repo using `devtools` as follows:

``` r
library(devtools)
install_github("kosukeimai/fastLink", auth_token = "[YOUR PAT HERE]")
```

Simple usage example
--------------------

The linkage algorithm can be run either using the `fastLink()` wrapper, which runs the algorithm from start to finish, or step-by-step. We will outline the workflow from start to finish using both examples. In both examples, we will assume we have two dataframes called `dfA` and `dfB` that we want to merge together, and that they have six commonly named fields:

-   `firstname`

-   `middlename`

-   `lastname`

-   `address`

-   `city`

-   `birthyear`

### Running the algorithm step-by-step

#### 1) Agreement calculation variable-by-variable

The first step for running the `fastLink` algorithm is to determine which observations agree, partially agree, disagree, and are missing on which variables. All functions provide the indices of the NA's. There are three separate `gammapar` functions to calculate this agreement variable-by-variable:

-   `gammaKpar()`: Binary agree-disagree on non-string variables.

-   `gammaCKpar()`: Agree-partial agree-disagree on string variables (using Jaro-Winkler distance to measure agreement).

-   `gammaCK2par()`: Binary agree-disagree on string variables (using Jaro-Winkler distance to measure agreement).

For instance, if we wanted to include partial matches on `firstname`, `lastname`, and `address`, but only do exact matches on `city` and `middlename`, we would run:

``` r
## Load the package and data
library(fastLink)
data(samplematch)

g_firstname <- gammaCKpar(dfA$firstname, dfB$firstname)
g_middlename <- gammaCK2par(dfA$middlename, dfB$middlename)
g_lastname <- gammaCKpar(dfA$lastname, dfB$lastname)
g_address <- gammaCKpar(dfA$address, dfB$address)
g_city <- gammaCK2par(dfA$city, dfB$city)
g_birthyear <- gammaKpar(dfA$birthyear, dfB$birthyear)
```

All functions include an `n.cores` argument where you can prespecify the number of registered cores to be used. If you do not specify this, the function will automatically detect the number of available cores and wil parallelize over those. In addition, for `gammaCKpar()` and `gammaCK2par()`, the user can specify the lower bound for an agreement using `cut.a`. For both functions, the default is 0.92. For `gammaCKpar()`, the user can also specify the lower bound for a partial agreement using `cut.p` - here, the default is 0.88.

#### 2) Counting unique agreement patterns

Once we have run the gamma calculations, we then use the `tableCounts()` function to count the number of unique matching patterns in our data. This is the only input necessary for the EM algorithm. We run `tableCounts()` as follows:

``` r
gammalist <- list(g_firstname, g_middlename, g_lastname, g_address, g_city, g_birthyear)
tc <- tableCounts(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB))
```

    ## Parallelizing gamma calculation using 1 cores.

As with the functions above, `tableCounts()` also includes an `n.cores` argument. If left unspecified, the function will automatically determine the number of available cores for parallelization.

#### 3) Running the EM algorithm

We next run the EM algorithm to calculate the Felligi-Sunter weights. The only required input to this function is the output from `tableCounts()`, as follows:

``` r
## Run EM algorithm
em.out <- emlinkMAR(tc)

## Postprocessing of EM algorithm
EM <- data.frame(em.out$patterns.w)
EM$zeta.j <- em.out$zeta.j
EM <- EM[order(EM[, "weights"]), ] 
match.ut <- EM$weights[ EM$zeta.j >= 0.85 ][1]
```

The code following `emlinkMAR()` sorts the linkage patterns by the Felligi-Sunter weight, and then selects the lowest weight that is still classified as a positive match according to the posterior probability that a linkage pattern is in the matched set. In this case, we've chosen that probability to be 0.85.

The EM object looks like:

``` r
EM
```

    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 counts    weights
    ## 1        0       0       0       0       0       0 102856 -204.48178
    ## 2        1       0       0       0       0       0    172 -191.15198
    ## 10       0       0       1       0       0       0     18 -181.56540
    ## 22       0       0       0       0       2       0  15540 -178.30453
    ## 7        0      NA       0       0       0       0  45137 -177.90180
    ## 36       0       0       0       0       0       2   1293 -175.84121
    ## 4        0       2       0       0       0       0    657 -172.86824
    ## 18       0       0       0       1       0       0      8 -171.46120
    ## 23       1       0       0       0       2       0     24 -164.97473
    ## 8        1      NA       0       0       0       0     81 -164.57200
    ## 3        2       0       0       0       0       0   1129 -162.80491
    ## 37       1       0       0       0       0       2      6 -162.51140
    ## 5        1       2       0       0       0       0      4 -159.53843
    ## 30       0       0       1       0       2       0      3 -155.38815
    ## 12       0      NA       1       0       0       0     10 -154.98542
    ## 27       0      NA       0       0       2       0   6162 -151.72455
    ## 13       0       0       2       0       0       0     86 -149.84438
    ## 45       0       0       0       0       2       2    209 -149.66396
    ## 40       0      NA       0       0       0       2    540 -149.26123
    ## 20       0       0       0       2       0       0     12 -146.84874
    ## 25       0       2       0       0       2       0    111 -146.69099
    ## 33       0       0       0       1       2       0      1 -145.28395
    ## 19       0      NA       0       1       0       0      3 -144.88122
    ## 39       0       2       0       0       0       2     14 -144.22766
    ## 11       2       0       1       0       0       0      1 -139.88853
    ## 28       1      NA       0       0       2       0      9 -138.39475
    ## 24       2       0       0       0       2       0    131 -136.62766
    ## 9        2      NA       0       0       0       0    509 -136.22493
    ## 41       1      NA       0       0       0       2      3 -135.93142
    ## 38       2       0       0       0       0       2     14 -134.16434
    ## 6        2       2       0       0       0       0      8 -131.19137
    ## 31       0       0       2       0       2       0     12 -123.66713
    ## 15       0      NA       2       0       0       0     33 -123.26440
    ## 48       0      NA       0       0       2       2     69 -123.08398
    ## 43       0       0       2       0       0       2      1 -121.20381
    ## 35       0       0       0       2       2       0      4 -120.67149
    ## 21       0      NA       0       2       0       0      4 -120.26876
    ## 34       0      NA       0       1       2       0      2 -118.70397
    ## 47       0       2       0       0       2       2      1 -118.05041
    ## 29       2      NA       0       0       2       0     59 -110.04768
    ## 16       1      NA       2       0       0       0      1 -109.93460
    ## 14       2       0       2       0       0       0      5 -108.16751
    ## 46       2       0       0       0       2       2      1 -107.98709
    ## 42       2      NA       0       0       0       2      2 -107.58436
    ## 26       2       2       0       0       2       0      2 -105.01412
    ## 32       0      NA       2       0       2       0      1  -97.08715
    ## 44       0      NA       2       0       0       2      1  -94.62383
    ## 17       2      NA       2       0       0       0      1  -81.58753
    ## 50       2      NA       2       2       2       2      9   30.86333
    ## 49       2       2       2       2       2       2     41   35.89690
    ##     p.gamma.j.m  p.gamma.j.u       zeta.j
    ## 1  6.610581e-90 4.222301e-01 4.475000e-93
    ## 2  4.382947e-86 4.550041e-03 2.753301e-87
    ## 10 4.780049e-83 3.406309e-04 4.010985e-83
    ## 22 2.261505e-79 6.181184e-02 1.045752e-81
    ## 7  2.326042e-78 4.249992e-01 1.564343e-81
    ## 36 2.261490e-79 5.263337e-03 1.228107e-80
    ## 4  2.326042e-78 2.769098e-03 2.400943e-79
    ## 18 1.656140e-79 4.827804e-05 9.805056e-79
    ## 23 1.499423e-75 6.660974e-04 6.434120e-76
    ## 8  1.542212e-74 4.579881e-03 9.624819e-76
    ## 3  1.445047e-74 7.330893e-04 5.634140e-75
    ## 37 1.499413e-75 5.671884e-05 7.556083e-75
    ## 5  1.542212e-74 2.984038e-05 1.477210e-73
    ## 30 1.635273e-72 4.986623e-05 9.373171e-72
    ## 12 1.681939e-71 3.428648e-04 1.402135e-71
    ## 27 7.957478e-68 6.221722e-02 3.655675e-70
    ## 13 6.480763e-70 7.730630e-05 2.396150e-69
    ## 45 7.736646e-69 7.705196e-04 2.869933e-69
    ## 40 7.957426e-68 5.297856e-03 4.293141e-69
    ## 20 5.665656e-69 3.379463e-05 4.791872e-68
    ## 25 7.957478e-68 4.053786e-04 5.610704e-68
    ## 33 5.665719e-69 7.067603e-06 2.291319e-67
    ## 19 5.827401e-68 4.859466e-05 3.427591e-67
    ## 39 7.957426e-68 3.451837e-05 6.589082e-67
    ## 11 1.044900e-67 5.914142e-07 5.049933e-65
    ## 28 5.275967e-64 6.704659e-04 2.249200e-64
    ## 24 4.943560e-64 1.073197e-04 1.316628e-63
    ## 9  5.084634e-63 7.378971e-04 1.969548e-63
    ## 41 5.275933e-64 5.709081e-05 2.641409e-63
    ## 38 4.943528e-64 9.138373e-06 1.546218e-62
    ## 6  5.084634e-63 4.807796e-06 3.022849e-61
    ## 31 2.217094e-59 1.131716e-05 5.599503e-58
    ## 15 2.280363e-58 7.781330e-05 8.376313e-58
    ## 48 2.722266e-57 7.755729e-04 1.003253e-57
    ## 43 2.217080e-59 9.636668e-07 6.575928e-57
    ## 35 1.938243e-58 4.947322e-06 1.119801e-56
    ## 21 1.993554e-57 3.401626e-05 1.675113e-56
    ## 34 1.993577e-57 7.113954e-06 8.009853e-56
    ## 47 2.722266e-57 5.053273e-06 1.539786e-55
    ## 29 1.739473e-52 1.080235e-04 4.602588e-52
    ## 16 1.511926e-54 8.385325e-07 5.153632e-52
    ## 14 1.416669e-54 1.342217e-07 3.016814e-51
    ## 46 1.691200e-53 1.337801e-06 3.613319e-51
    ## 42 1.739462e-52 9.198305e-06 5.405174e-51
    ## 26 1.739473e-52 7.038311e-07 7.064020e-50
    ## 32 7.801210e-48 1.139138e-05 1.957440e-46
    ## 44 7.801159e-48 9.699868e-07 2.298773e-45
    ## 17 4.984783e-43 1.351019e-07 1.054599e-39
    ## 50 5.000000e-01 1.973306e-14 1.000000e+00
    ## 49 5.000000e-01 1.285715e-16 1.000000e+00

where the first six columns are indicators for the matching pattern. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Felligi-Sunter weight for each matching pattern

-   `p.gamma.j.m`: Posterior probability of being in the matched set given that matching pattern

-   `p.gamma.j.u`: Posterior probability of being in the unmatched set given that matching pattern

-   `zeta.j`: The posterior probability of a particular pattern representing a true match

As with the other functions above, `emlinkMAR()` accepts an `n.cores` argument. Other optional arguments include:

-   `p.m`: Starting values for the probability of being in the matched set

-   `p.gamma.k.m`: Starting values for the probability that conditional on being in the matched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `p.gamma.k.u`: Starting values for the probability that conditional on being in the unmatched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `tol`: Convergence tolerance for the EM algorithm

-   `iter.max`: Maximum number of iterations for the EM algorithm

#### 4) Finding the matches

Once we've run the EM algorithm and selected our lower bound for accepting a match, we then run `matchesLink()` to get the paired indices of `dfA` and `dfB` that match. We run the function as follows:

``` r
matches.out <- matchesLink(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB),
                           em = em.out, cut = match.ut)
```

    ## Parallelizing gamma calculation using 1 cores.

As with the other functions above, `matchesLink()` accepts an `n.cores` argument. This returns a matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

The datasets can then be subsetted down to the matches as follows:

``` r
dfA.match <- dfA[matches.out[,1],]
dfB.match <- dfB[matches.out[,2],]
```

### Running the algorithm using the `fastLink()` wrapper

`fastLink` also includes a wrapper to automate running the four steps above. Running the code below would return equivalent results to the step-by-step process above:

``` r
matches.out <- fastLink(dfA, dfB, 
                        varnames = c("firstname", "middlename", "lastname", "address", "city", "birthyear"),
                        stringdist_match = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
                        partial_match = c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE))
```

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for zeta parameters.
    ## Parallelizing gamma calculation using 1 cores.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ## Parallelizing gamma calculation using 1 cores.

-   `varnames` should be a vector of variable names to be used for matching. These variable names should exist in both `dfA` and `dfB`

-   `stringdist_match` should be a vector of booleans of the same length as `varnames`. `TRUE` means that string-distance matching using the Jaro-Winkler similarity will be used.

-   `partial_match` is another vector of booleans of the same length as `varnames`. A `TRUE` for an entry in `partial_match` and a `TRUE` for that same entry for `stringdist_match` means that a partial match category will be included in the gamma calculation.

Other arguments that can be provided include:

-   `n.cores`

-   `tol.em`: Convergence tolerance for the EM algorithm. Default is 1e-04

-   `match`: Lower bound for the posterior probability of a match that will be accepted. Default is 0.85.

-   `verbose`: Whether to print out runtime for each step and EM output. Default is FALSE.

The output from `fastLink()` will be a list of length 2 with two entries:

-   `matches`: A matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

-   `EM`: The output from `emlinkMAR()`
