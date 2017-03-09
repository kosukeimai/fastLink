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

As with the other functions above, `emlinkMAR()` accepts an `n.cores` argument. Other optional arguments include:

-   `p.m`: Starting values for the probability of being in the matched set

-   `p.gamma.k.m`: Starting values for the probability that conditional on being in the matched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `p.gamma.k.u`: Starting values for the probability that conditional on being in the unmatched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `tol`: Convergence tolerance for the EM algorithm

-   `iter.max`: Maximum number of iterations for the EM algorithm

The code following `emlinkMAR()` sorts the linkage patterns by the Felligi-Sunter weight, and then selects the lowest weight that is still classified as a positive match according to the posterior probability that a linkage pattern is in the matched set. In this case, we've chosen that probability to be 0.85.

The EM object looks like:

``` r
EM
```

    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 counts    weights
    ## 1        0       0       0       0       0       0 102856 -173.94160
    ## 2        1       0       0       0       0       0    172 -162.68030
    ## 7        0      NA       0       0       0       0  45137 -152.40341
    ## 10       0       0       1       0       0       0     18 -152.31734
    ## 22       0       0       0       0       2       0  15540 -151.28637
    ## 36       0       0       0       0       0       2   1293 -148.82303
    ## 4        0       2       0       0       0       0    657 -147.36984
    ## 18       0       0       0       1       0       0      8 -144.54164
    ## 8        1      NA       0       0       0       0     81 -141.14211
    ## 23       1       0       0       0       2       0     24 -140.02507
    ## 37       1       0       0       0       0       2      6 -137.56173
    ## 3        2       0       0       0       0       0   1129 -137.37382
    ## 5        1       2       0       0       0       0      4 -136.10854
    ## 12       0      NA       1       0       0       0     10 -130.77914
    ## 27       0      NA       0       0       2       0   6162 -129.74818
    ## 30       0       0       1       0       2       0      3 -129.66211
    ## 40       0      NA       0       0       0       2    540 -127.28484
    ## 45       0       0       0       0       2       2    209 -126.16780
    ## 13       0       0       2       0       0       0     86 -125.50681
    ## 25       0       2       0       0       2       0    111 -124.71461
    ## 20       0       0       0       2       0       0     12 -123.45122
    ## 19       0      NA       0       1       0       0      3 -123.00344
    ## 39       0       2       0       0       0       2     14 -122.25127
    ## 33       0       0       0       1       2       0      1 -121.88641
    ## 28       1      NA       0       0       2       0      9 -118.48688
    ## 41       1      NA       0       0       0       2      3 -116.02354
    ## 9        2      NA       0       0       0       0    509 -115.83563
    ## 11       2       0       1       0       0       0      1 -115.74956
    ## 24       2       0       0       0       2       0    131 -114.71859
    ## 38       2       0       0       0       0       2     14 -112.25525
    ## 6        2       2       0       0       0       0      8 -110.80206
    ## 48       0      NA       0       0       2       2     69 -104.62961
    ## 15       0      NA       2       0       0       0     33 -103.96862
    ## 31       0       0       2       0       2       0     12 -102.85158
    ## 21       0      NA       0       2       0       0      4 -101.91303
    ## 35       0       0       0       2       2       0      4 -100.79599
    ## 43       0       0       2       0       0       2      1 -100.38824
    ## 34       0      NA       0       1       2       0      2 -100.34822
    ## 47       0       2       0       0       2       2      1  -99.59604
    ## 29       2      NA       0       0       2       0     59  -93.18040
    ## 16       1      NA       2       0       0       0      1  -92.70732
    ## 42       2      NA       0       0       0       2      2  -90.71706
    ## 46       2       0       0       0       2       2      1  -89.60002
    ## 14       2       0       2       0       0       0      5  -88.93903
    ## 26       2       2       0       0       2       0      2  -88.14683
    ## 32       0      NA       2       0       2       0      1  -81.31339
    ## 44       0      NA       2       0       0       2      1  -78.85005
    ## 17       2      NA       2       0       0       0      1  -67.40084
    ## 50       2      NA       2       2       2       2      9   30.86333
    ## 49       2       2       2       2       2       2     41   35.89690
    ##     p.gamma.j.m  p.gamma.j.u       zeta.j
    ## 1  1.212477e-76 4.222301e-01 8.207807e-80
    ## 2  1.015919e-73 4.550041e-03 6.381845e-75
    ## 7  2.756957e-67 4.249992e-01 1.854149e-70
    ## 10 2.408274e-70 3.406309e-04 2.020805e-70
    ## 22 1.225285e-67 6.181184e-02 5.665890e-70
    ## 36 1.225296e-67 5.263337e-03 6.653996e-69
    ## 4  2.756957e-67 2.769098e-03 2.845734e-68
    ## 18 8.130457e-68 4.827804e-05 4.813578e-67
    ## 8  2.310017e-64 4.579881e-03 1.441663e-65
    ## 23 1.026650e-64 6.660974e-04 4.405419e-65
    ## 37 1.026659e-64 5.671884e-05 5.173705e-64
    ## 3  1.601275e-63 7.330893e-04 6.243265e-64
    ## 5  2.310017e-64 2.984038e-05 2.212654e-63
    ## 12 5.475984e-61 3.428648e-04 4.565012e-61
    ## 27 2.786079e-58 6.221722e-02 1.279928e-60
    ## 30 2.433713e-61 4.986623e-05 1.394972e-60
    ## 40 2.786105e-58 5.297856e-03 1.503142e-59
    ## 45 1.238239e-58 7.705196e-04 4.593287e-59
    ## 13 2.406026e-59 7.730630e-05 8.895862e-59
    ## 25 2.786079e-58 4.053786e-04 1.964424e-58
    ## 20 8.216065e-59 3.379463e-05 6.948945e-58
    ## 19 1.848721e-58 4.859466e-05 1.087390e-57
    ## 39 2.786104e-58 3.451837e-05 2.307011e-57
    ## 33 8.216340e-59 7.067603e-06 3.322837e-57
    ## 28 2.334418e-55 6.704659e-04 9.951869e-56
    ## 41 2.334439e-55 5.709081e-05 1.168743e-54
    ## 9  3.641013e-54 7.378971e-04 1.410357e-54
    ## 11 3.180520e-57 5.914142e-07 1.537125e-54
    ## 24 1.618190e-54 1.073197e-04 4.309757e-54
    ## 38 1.618204e-54 9.138373e-06 5.061360e-53
    ## 6  3.641013e-54 4.807796e-06 2.164607e-52
    ## 48 2.815535e-49 7.755729e-04 1.037626e-49
    ## 15 5.470872e-50 7.781330e-05 2.009581e-49
    ## 31 2.431441e-50 1.131716e-05 6.140858e-49
    ## 21 1.868186e-49 3.401626e-05 1.569771e-48
    ## 35 8.302853e-50 4.947322e-06 4.796891e-48
    ## 43 2.431463e-50 9.636668e-07 7.211796e-48
    ## 34 1.868249e-49 7.113954e-06 7.506308e-48
    ## 47 2.815535e-49 5.053273e-06 1.592541e-47
    ## 29 3.679474e-45 1.080235e-04 9.735767e-45
    ## 16 4.583970e-47 8.385325e-07 1.562516e-44
    ## 42 3.679508e-45 9.198305e-06 1.143364e-43
    ## 46 1.635298e-45 1.337801e-06 3.493882e-43
    ## 14 3.177551e-46 1.342217e-07 6.766634e-43
    ## 26 3.679474e-45 7.038311e-07 1.494239e-42
    ## 32 5.528662e-41 1.139138e-05 1.387223e-39
    ## 44 5.528712e-41 9.699868e-07 1.629149e-38
    ## 17 7.225183e-37 1.351019e-07 1.528587e-33
    ## 50 5.000000e-01 1.973306e-14 1.000000e+00
    ## 49 5.000000e-01 1.285715e-16 1.000000e+00

where the first six columns are indicators for the matching pattern. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Felligi-Sunter weight for each matching pattern

-   `p.gamma.j.m`: Probability of being in the matched set given that matching pattern

-   `p.gamma.j.u`: Probability of being in the unmatched set given that matching pattern

-   `zeta.j`: Posterior probability of a particular pattern representing a true match

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
