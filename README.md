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

The linkage algorithm can be run either using the `fastLink()` wrapper, which runs the algorithm from start to finish, or step-by-step. We will outline the workflow from start to finish using both examples. In both examples, we have two dataframes called `dfA` and `dfB` that we want to merge together, and they have seven commonly named fields:

-   `firstname`

-   `middlename`

-   `lastname`

-   `housenum`

-   `streetname`

-   `city`

-   `birthyear`

### Running the algorithm using the `fastLink()` wrapper

The `fastLink` wrapper runs the entire algorithm from start to finish, as seen below:

``` r
## Load the package and data
library(fastLink)
data(samplematch)

matches.out <- fastLink(dfA, dfB, 
                        varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
                        stringdist_match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
                        partial_match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE))
```

    FALSE 
    FALSE ==================== 
    FALSE fastLink(): Fast Probabilistic Record Linkage
    FALSE ==================== 
    FALSE 
    FALSE Calculating matches for each variable.
    FALSE Getting counts for zeta parameters.
    FALSE Parallelizing gamma calculation using 1 cores.
    FALSE Running the EM algorithm.
    FALSE Getting the indices of estimated matches.
    FALSE Parallelizing gamma calculation using 1 cores.

-   `varnames` should be a vector of variable names to be used for matching. These variable names should exist in both `dfA` and `dfB`

-   `stringdist_match` should be a vector of booleans of the same length as `varnames`. `TRUE` means that string-distance matching using the Jaro-Winkler similarity will be used.

-   `partial_match` is another vector of booleans of the same length as `varnames`. A `TRUE` for an entry in `partial_match` and a `TRUE` for that same entry for `stringdist_match` means that a partial match category will be included in the gamma calculation.

Other arguments that can be provided include:

-   `n.cores`: The number of registered cores to parallelize over. If left unspecified. the function will estimate this on its own.

-   `tol.em`: Convergence tolerance for the EM algorithm. Default is 1e-04

-   `match`: Lower bound for the posterior probability of a match that will be accepted. Default is 0.85.

-   `verbose`: Whether to print out runtime for each step and EM output. Default is FALSE.

The output from `fastLink()` will be a list of length 2 with two entries:

-   `matches`: A matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

-   `EM`: The output from the EM algorithm

The datasets can then be subsetted down to the matches as follows:

``` r
dfA.match <- dfA[matches.out$matches[,1],]
dfB.match <- dfB[matches.out$matches[,2],]
```

We can also examine the EM object:

``` r
matches.out$EM
```

    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 gamma.7 counts
    ## 1        0       0       0       0       0       0       0 101069
    ## 2        1       0       0       0       0       0       0    133
    ## 19       0       0       0       0       1       0       0     40
    ## 20       1       0       0       0       1       0       0      1
    ## 9        0       0       1       0       0       0       0     12
    ## 6        0      NA       0       0       0       0       0  48474
    ## 26       0       0       0       0       0       2       0  13032
    ## 7        1      NA       0       0       0       0       0     48
    ## 43       0       0       0       0       0       0       2   1203
    ## 4        0       2       0       0       0       0       0    691
    ## 27       1       0       0       0       0       2       0      9
    ## 14       0       0       0       2       0       0       0     15
    ## 44       1       0       0       0       0       0       2      2
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 39       0       0       0       0       1       2       0      4
    ## 3        2       0       0       0       0       0       0   1181
    ## 10       0      NA       1       0       0       0       0      3
    ## 11       0       0       2       0       0       0       0     65
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 47       0      NA       0       0       0       0       2    593
    ## 31       1      NA       0       0       0       2       0      3
    ## 53       0       0       0       0       0       2       2    150
    ## 29       0       2       0       0       0       2       0     75
    ## 15       0      NA       0       2       0       0       0      8
    ## 46       0       2       0       0       0       0       2     10
    ## 25       0      NA       0       0       2       0       0     27
    ## 37       0       0       0       2       0       2       0      4
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 8        2      NA       0       0       0       0       0    559
    ## 52       0       0       0       0       2       0       2      1
    ## 28       2       0       0       0       0       2       0    153
    ## 24       0       2       0       0       2       0       0      1
    ## 45       2       0       0       0       0       0       2     19
    ## 5        2       2       0       0       0       0       0      9
    ## 13       0      NA       2       0       0       0       0     36
    ## 34       0      NA       1       0       0       2       0      1
    ## 35       0       0       2       0       0       2       0      8
    ## 49       0       0       2       0       0       0       2      1
    ## 12       0       2       2       0       0       0       0      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 55       0       2       0       0       0       2       2      3
    ## 42       0      NA       0       0       2       2       0      4
    ## 18       2      NA       0      NA       0       0       0      4
    ## 50       0      NA       0       2       0       0       2      1
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 54       2       0       0       0       0       2       2      3
    ## 16       2      NA       0       2       0       0       0      1
    ## 36       0      NA       2       0       0       2       0      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##       weights   p.gamma.j.m  p.gamma.j.u        zeta.j      cumsum.m
    ## 1  -349.07432 7.176063e-153 2.863757e-01 4.798220e-156 7.176063e-153
    ## 2  -344.46910 8.354451e-153 3.333864e-03 4.798441e-154 1.553051e-152
    ## 19 -339.22753 6.128749e-152 1.294239e-04 9.067500e-152 7.681801e-152
    ## 20 -334.62231 7.135157e-152 1.506697e-06 9.067919e-150 1.481696e-151
    ## 9  -330.88267 3.721671e-148 1.867486e-04 3.816021e-148 3.723153e-148
    ## 6  -301.98817 2.032623e-132 2.883068e-01 1.349995e-135 2.032623e-132
    ## 26 -299.70012 2.618994e-132 3.769145e-02 1.330521e-134 4.651617e-132
    ## 7  -297.38296 2.366402e-132 3.356344e-03 1.350057e-133 7.018019e-132
    ## 43 -297.31453 2.609071e-132 3.455779e-03 1.445673e-133 9.627090e-132
    ## 4  -296.98222 2.032623e-132 1.931057e-03 2.015543e-133 1.165971e-131
    ## 27 -295.09490 3.049061e-132 4.387877e-04 1.330582e-132 1.470877e-131
    ## 14 -293.13440 2.348056e-132 4.757317e-05 9.450972e-132 1.705683e-131
    ## 44 -292.70931 3.037509e-132 4.023070e-05 1.445740e-131 2.009434e-131
    ## 22 -292.14138 1.735971e-131 1.302966e-04 2.551171e-131 3.745405e-131
    ## 23 -291.72946 2.240791e-131 1.114028e-04 3.851547e-131 5.986196e-131
    ## 39 -289.85333 2.236764e-131 1.703417e-05 2.514370e-130 8.222959e-131
    ## 3  -289.26975 7.647767e-130 3.249315e-04 4.506848e-130 8.470063e-130
    ## 10 -283.79653 1.054165e-127 1.880079e-04 1.073650e-127 1.062635e-127
    ## 11 -281.85055 1.221703e-127 3.112477e-05 7.516050e-127 2.284338e-127
    ## 33 -281.50848 1.358270e-127 2.457899e-05 1.058162e-126 3.642609e-127
    ## 21 -279.42296 6.531610e-129 1.468487e-07 8.516877e-126 3.707925e-127
    ## 17 -254.75122 6.650881e-112 2.883547e-01 4.416541e-115 6.650881e-112
    ## 30 -252.61398 7.418312e-112 3.794561e-02 3.743465e-114 1.406919e-111
    ## 47 -250.22839 7.390207e-112 3.479082e-03 4.067449e-113 2.145940e-111
    ## 31 -248.00876 8.636480e-112 4.417465e-04 3.743638e-112 3.009588e-111
    ## 53 -247.94033 9.522131e-112 4.548337e-04 4.008775e-112 3.961801e-111
    ## 29 -247.60802 7.418312e-112 2.541568e-04 5.588993e-112 4.703632e-111
    ## 15 -246.04826 6.650881e-112 4.789396e-05 2.659062e-111 5.368720e-111
    ## 46 -245.22243 7.390207e-112 2.330262e-05 6.072702e-111 6.107741e-111
    ## 25 -244.64332 6.347051e-111 1.121540e-04 1.083645e-110 1.245479e-110
    ## 37 -243.76021 8.569524e-112 6.261361e-06 2.620705e-110 1.331174e-110
    ## 40 -242.76719 6.335644e-111 1.714904e-05 7.074263e-110 1.964739e-110
    ## 41 -242.35526 8.178045e-111 1.466233e-05 1.068014e-109 2.782543e-110
    ## 8  -242.18361 2.166234e-109 3.271226e-04 1.268017e-109 2.444488e-109
    ## 52 -239.96967 8.147062e-111 1.344330e-06 1.160447e-108 2.525959e-109
    ## 28 -239.89555 2.791148e-109 4.276598e-05 1.249725e-108 5.317107e-109
    ## 24 -239.63736 6.347051e-111 7.511992e-07 1.617883e-108 5.380577e-109
    ## 45 -237.50997 2.780573e-109 3.921043e-06 1.357885e-107 8.161150e-109
    ## 5  -237.17765 2.166234e-109 2.191042e-06 1.893149e-107 1.032738e-108
    ## 13 -234.76441 3.460480e-107 3.133465e-05 2.114665e-106 3.563754e-107
    ## 34 -234.42233 3.847308e-107 2.474473e-05 2.977175e-106 7.411061e-107
    ## 35 -232.47636 4.458758e-107 4.096498e-06 2.084161e-105 1.186982e-106
    ## 49 -230.09077 4.441865e-107 3.755916e-07 2.264538e-104 1.631168e-106
    ## 12 -229.75845 3.460480e-107 2.098771e-07 3.157196e-104 1.977216e-106
    ## 38 -205.37702  2.427322e-91 3.795191e-02  1.224683e-93  2.427322e-91
    ## 51 -202.99143  2.418126e-91 3.479660e-03  1.330676e-92  4.845448e-91
    ## 56 -200.85419  2.697148e-91 4.579007e-04  1.127882e-91  7.542596e-91
    ## 55 -195.84823  2.697148e-91 3.066984e-06  1.683928e-89  1.023974e-90
    ## 42 -195.26912  2.316435e-90 1.476120e-05  3.004891e-89  3.340410e-90
    ## 18 -194.94665  7.088063e-89 3.271769e-04  4.148347e-89  7.422104e-89
    ## 50 -194.28847  2.418126e-91 5.779504e-07  8.011586e-89  7.446285e-89
    ## 32 -192.80941  7.905940e-89 4.305436e-05  3.516143e-88  1.535223e-88
    ## 48 -190.42382  7.875988e-89 3.947483e-06  3.820454e-87  2.322821e-88
    ## 54 -188.13577  1.014805e-88 5.160695e-07  3.765343e-86  3.337626e-88
    ## 16 -186.24369  7.088063e-89 5.434210e-08  2.497591e-85  4.046432e-88
    ## 36 -185.39021  1.262945e-86 4.124122e-06  5.863856e-85  1.303410e-86
    ## 58   39.45891  5.000000e-01 3.649075e-18  1.000000e+00  5.000000e-01
    ## 57   44.46487  5.000000e-01 2.444122e-20  1.000000e+00  1.000000e+00
    ##        cumsum.u
    ## 1  7.136243e-01
    ## 2  7.102904e-01
    ## 19 7.101610e-01
    ## 20 7.101595e-01
    ## 9  7.099727e-01
    ## 6  4.216659e-01
    ## 26 3.839745e-01
    ## 7  3.806181e-01
    ## 43 3.771623e-01
    ## 4  3.752313e-01
    ## 27 3.747925e-01
    ## 14 3.747449e-01
    ## 44 3.747047e-01
    ## 22 3.745744e-01
    ## 23 3.744630e-01
    ## 39 3.744459e-01
    ## 3  3.741210e-01
    ## 10 3.739330e-01
    ## 11 3.739019e-01
    ## 33 3.738773e-01
    ## 21 3.738772e-01
    ## 17 8.552246e-02
    ## 30 4.757685e-02
    ## 47 4.409777e-02
    ## 31 4.365602e-02
    ## 53 4.320119e-02
    ## 29 4.294703e-02
    ## 15 4.289914e-02
    ## 46 4.287584e-02
    ## 25 4.276368e-02
    ## 37 4.275742e-02
    ## 40 4.274027e-02
    ## 41 4.272561e-02
    ## 8  4.239849e-02
    ## 52 4.239714e-02
    ## 28 4.235438e-02
    ## 24 4.235362e-02
    ## 45 4.234970e-02
    ## 5  4.234751e-02
    ## 13 4.231618e-02
    ## 34 4.229143e-02
    ## 35 4.228734e-02
    ## 49 4.228696e-02
    ## 12 4.228675e-02
    ## 38 4.334840e-03
    ## 51 8.551801e-04
    ## 56 3.972794e-04
    ## 55 3.942124e-04
    ## 42 3.794512e-04
    ## 18 5.227433e-05
    ## 50 5.169638e-05
    ## 32 8.642016e-06
    ## 48 4.694533e-06
    ## 54 4.178464e-06
    ## 16 4.124122e-06
    ## 36 0.000000e+00
    ## 58 0.000000e+00
    ## 57 0.000000e+00

where the first seven columns are indicators for the matching pattern for that field. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Felligi-Sunter weight for each matching pattern

-   `p.gamma.j.m`: Probability of being in the matched set given that matching pattern

-   `p.gamma.j.u`: Probability of being in the unmatched set given that matching pattern

-   `zeta.j`: Posterior probability of a particular pattern representing a true match

### Running the algorithm step-by-step

The algorithm can also be run step-by-step for more flexibility. We outline how to do this in the following section, which replicates the example in the wrapper above.

#### 1) Agreement calculation variable-by-variable

The first step for running the `fastLink` algorithm is to determine which observations agree, partially agree, disagree, and are missing on which variables. All functions provide the indices of the NA's. There are three separate `gammapar` functions to calculate this agreement variable-by-variable:

-   `gammaKpar()`: Binary agree-disagree on non-string variables.

-   `gammaCKpar()`: Agree-partial agree-disagree on string variables (using Jaro-Winkler distance to measure agreement).

-   `gammaCK2par()`: Binary agree-disagree on string variables (using Jaro-Winkler distance to measure agreement).

For instance, if we wanted to include partial string matches on `firstname`, `lastname`, and `streetname`, but only do exact string matches on `city` and `middlename` (with exact non-string matches on `birthyear` and `housenum`), we would run:

``` r
g_firstname <- gammaCKpar(dfA$firstname, dfB$firstname)
g_middlename <- gammaCK2par(dfA$middlename, dfB$middlename)
g_lastname <- gammaCKpar(dfA$lastname, dfB$lastname)
g_housenum <- gammaKpar(dfA$housenum, dfB$housenum)
g_streetname <- gammaCKpar(dfA$streetname, dfB$streetname)
g_city <- gammaCK2par(dfA$city, dfB$city)
g_birthyear <- gammaKpar(dfA$birthyear, dfB$birthyear)
```

All functions include an `n.cores` argument where you can prespecify the number of registered cores to be used. If you do not specify this, the function will automatically detect the number of available cores and wil parallelize over those. In addition, for `gammaCKpar()` and `gammaCK2par()`, the user can specify the lower bound for an agreement using `cut.a`. For both functions, the default is 0.92. For `gammaCKpar()`, the user can also specify the lower bound for a partial agreement using `cut.p` - here, the default is 0.88.

#### 2) Counting unique agreement patterns

Once we have run the gamma calculations, we then use the `tableCounts()` function to count the number of unique matching patterns in our data. This is the only input necessary for the EM algorithm. We run `tableCounts()` as follows:

``` r
gammalist <- list(g_firstname, g_middlename, g_lastname, g_housenum, g_streetname, g_city, g_birthyear)
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
