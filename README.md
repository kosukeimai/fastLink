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

-   `n.cores`

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
    ## 4        0       2       0       0       0       0       0    691
    ## 7        1      NA       0       0       0       0       0     48
    ## 26       0       0       0       0       0       2       0  13032
    ## 43       0       0       0       0       0       0       2   1203
    ## 14       0       0       0       2       0       0       0     15
    ## 27       1       0       0       0       0       2       0      9
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 44       1       0       0       0       0       0       2      2
    ## 3        2       0       0       0       0       0       0   1181
    ## 39       0       0       0       0       1       2       0      4
    ## 10       0      NA       1       0       0       0       0      3
    ## 11       0       0       2       0       0       0       0     65
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 47       0      NA       0       0       0       0       2    593
    ## 15       0      NA       0       2       0       0       0      8
    ## 29       0       2       0       0       0       2       0     75
    ## 31       1      NA       0       0       0       2       0      3
    ## 25       0      NA       0       0       2       0       0     27
    ## 46       0       2       0       0       0       0       2     10
    ## 53       0       0       0       0       0       2       2    150
    ## 37       0       0       0       2       0       2       0      4
    ## 8        2      NA       0       0       0       0       0    559
    ## 24       0       2       0       0       2       0       0      1
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 52       0       0       0       0       2       0       2      1
    ## 5        2       2       0       0       0       0       0      9
    ## 28       2       0       0       0       0       2       0    153
    ## 13       0      NA       2       0       0       0       0     36
    ## 45       2       0       0       0       0       0       2     19
    ## 34       0      NA       1       0       0       2       0      1
    ## 12       0       2       2       0       0       0       0      1
    ## 35       0       0       2       0       0       2       0      8
    ## 49       0       0       2       0       0       0       2      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 18       2      NA       0      NA       0       0       0      4
    ## 50       0      NA       0       2       0       0       2      1
    ## 42       0      NA       0       0       2       2       0      4
    ## 55       0       2       0       0       0       2       2      3
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 16       2      NA       0       2       0       0       0      1
    ## 36       0      NA       2       0       0       2       0      3
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##       weights   p.gamma.j.m  p.gamma.j.u        zeta.j      cumsum.m
    ## 1  -416.20563 5.024896e-182 2.863757e-01 3.359859e-185 5.024896e-182
    ## 2  -410.81470 1.283488e-181 3.333864e-03 7.371811e-183 1.785978e-181
    ## 19 -404.69631 2.262758e-180 1.294239e-04 3.347757e-180 2.441356e-180
    ## 20 -399.30538 5.779669e-180 1.506697e-06 7.345258e-178 8.221025e-180
    ## 9  -394.04183 1.383770e-175 1.867486e-04 1.418850e-175 1.383852e-175
    ## 6  -361.92713 1.891897e-158 2.883068e-01 1.256530e-161 1.891897e-158
    ## 4  -356.92118 1.891897e-158 1.931057e-03 1.875999e-159 3.783794e-158
    ## 7  -356.53620 4.832394e-158 3.356344e-03 2.756931e-159 8.616188e-158
    ## 26 -356.15175 7.970861e-157 3.769145e-02 4.049417e-159 8.832480e-157
    ## 43 -353.55540 9.803635e-157 3.455779e-03 5.432144e-158 1.863611e-156
    ## 14 -353.07309 2.186090e-158 4.757317e-05 8.799057e-158 1.885472e-156
    ## 27 -350.76081 2.035964e-156 4.387877e-04 8.884760e-157 3.921436e-156
    ## 22 -350.41782 8.519392e-157 1.302966e-04 1.252004e-156 4.773375e-156
    ## 23 -350.09461 1.006323e-156 1.114028e-04 1.729701e-156 5.779698e-156
    ## 44 -348.16446 2.504101e-156 4.023070e-05 1.191858e-155 8.283799e-156
    ## 3  -345.15266 4.110496e-154 3.249315e-04 2.422326e-154 4.193334e-154
    ## 39 -344.64243 3.589354e-155 1.703417e-05 4.034831e-154 4.552270e-154
    ## 10 -339.76334 5.209959e-152 1.880079e-04 5.306258e-152 5.255481e-152
    ## 11 -337.82023 6.020647e-152 3.112477e-05 3.703967e-151 1.127613e-151
    ## 33 -333.98795 2.195038e-150 2.457899e-05 1.710047e-149 2.307799e-150
    ## 21 -333.64335 1.850995e-152 1.468487e-07 2.413601e-149 2.326309e-150
    ## 17 -307.49755 8.230734e-135 2.883547e-01 5.465648e-138 8.230734e-135
    ## 30 -301.87325 3.001067e-133 3.794561e-02 1.514413e-135 3.083374e-133
    ## 47 -299.27690 3.691115e-133 3.479082e-03 2.031529e-134 6.774489e-133
    ## 15 -298.79459 8.230734e-135 4.789396e-05 3.290697e-134 6.856796e-133
    ## 29 -296.86729 3.001067e-133 2.541568e-04 2.261018e-133 9.857863e-133
    ## 31 -296.48231 7.665499e-133 4.417465e-04 3.322748e-133 1.752336e-132
    ## 25 -295.81612 3.788852e-133 1.121540e-04 6.468787e-133 2.131221e-132
    ## 46 -294.27094 3.691115e-133 2.330262e-05 3.033073e-132 2.500333e-132
    ## 53 -293.50151 1.555125e-131 4.548337e-04 6.547007e-132 1.805158e-131
    ## 37 -293.01920 3.467738e-133 6.261361e-06 1.060493e-131 1.839835e-131
    ## 8  -290.87417 1.547621e-130 3.271226e-04 9.059085e-131 1.731605e-130
    ## 24 -290.81016 3.788852e-133 7.511992e-07 9.657900e-131 1.735394e-130
    ## 40 -290.36393 1.351409e-131 1.714904e-05 1.508958e-130 1.870535e-130
    ## 41 -290.04073 1.596303e-131 1.466233e-05 2.084695e-130 2.030165e-130
    ## 52 -287.44438 1.963348e-131 1.344330e-06 2.796542e-129 2.226500e-130
    ## 5  -285.86821 1.547621e-130 2.191042e-06 1.352521e-128 3.774121e-130
    ## 28 -285.09878 6.520372e-129 4.276598e-05 2.919470e-128 6.897784e-129
    ## 13 -283.54174 2.266802e-128 3.133465e-05 1.385220e-127 2.956580e-128
    ## 45 -282.50243 8.019629e-129 3.921043e-06 3.916362e-127 3.758543e-128
    ## 34 -279.70945 8.264420e-127 2.474473e-05 6.395284e-126 8.640274e-127
    ## 12 -278.53578 2.266802e-128 2.098771e-07 2.068134e-125 8.866955e-127
    ## 35 -277.76635 9.550393e-127 4.096498e-06 4.464148e-125 1.841735e-126
    ## 49 -275.17000 1.174636e-126 3.755916e-07 5.988491e-124 3.016370e-126
    ## 38 -247.44366 1.305620e-109 3.795191e-02 6.587387e-112 1.305620e-109
    ## 51 -244.84732 1.605826e-109 3.479660e-03 8.836738e-111 2.911446e-109
    ## 56 -239.22302 5.855118e-108 4.579007e-04 2.448469e-108 6.146263e-108
    ## 18 -236.44458 6.732955e-107 3.271769e-04 3.940517e-107 7.347581e-107
    ## 50 -236.14436 1.605826e-109 5.779504e-07 5.320325e-107 7.363640e-107
    ## 42 -235.76223 6.010156e-108 1.476120e-05 7.796405e-107 7.964655e-107
    ## 55 -234.21706 5.855118e-108 3.066984e-06 3.655564e-106 8.550167e-107
    ## 32 -230.82028 2.454951e-105 4.305436e-05 1.091832e-104 2.540453e-105
    ## 48 -228.22393 3.019428e-105 3.947483e-06 1.464653e-103 5.559881e-105
    ## 16 -227.74162 6.732955e-107 5.434210e-08 2.372463e-103 5.627210e-105
    ## 36 -223.48785 3.595768e-103 4.124122e-06 1.669515e-101 3.652040e-103
    ## 54 -222.44855 1.272133e-103 5.160695e-07 4.720134e-101 4.924173e-103
    ## 58   39.45891  5.000000e-01 3.649075e-18  1.000000e+00  5.000000e-01
    ## 57   44.46487  5.000000e-01 2.444122e-20  1.000000e+00  1.000000e+00
    ##        cumsum.u
    ## 1  7.136243e-01
    ## 2  7.102904e-01
    ## 19 7.101610e-01
    ## 20 7.101595e-01
    ## 9  7.099727e-01
    ## 6  4.216659e-01
    ## 4  4.197348e-01
    ## 7  4.163785e-01
    ## 26 3.786871e-01
    ## 43 3.752313e-01
    ## 14 3.751837e-01
    ## 27 3.747449e-01
    ## 22 3.746146e-01
    ## 23 3.745032e-01
    ## 44 3.744630e-01
    ## 3  3.741381e-01
    ## 39 3.741210e-01
    ## 10 3.739330e-01
    ## 11 3.739019e-01
    ## 33 3.738773e-01
    ## 21 3.738772e-01
    ## 17 8.552246e-02
    ## 30 4.757685e-02
    ## 47 4.409777e-02
    ## 15 4.404988e-02
    ## 29 4.379572e-02
    ## 31 4.335397e-02
    ## 25 4.324182e-02
    ## 46 4.321852e-02
    ## 53 4.276368e-02
    ## 37 4.275742e-02
    ## 8  4.243030e-02
    ## 24 4.242955e-02
    ## 40 4.241240e-02
    ## 41 4.239773e-02
    ## 52 4.239639e-02
    ## 5  4.239420e-02
    ## 28 4.235143e-02
    ## 13 4.232010e-02
    ## 45 4.231618e-02
    ## 34 4.229143e-02
    ## 12 4.229122e-02
    ## 35 4.228713e-02
    ## 49 4.228675e-02
    ## 38 4.334840e-03
    ## 51 8.551801e-04
    ## 56 3.972794e-04
    ## 18 7.010250e-05
    ## 50 6.952455e-05
    ## 42 5.476336e-05
    ## 55 5.169638e-05
    ## 32 8.642016e-06
    ## 48 4.694533e-06
    ## 16 4.640191e-06
    ## 36 5.160695e-07
    ## 54 0.000000e+00
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
