fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.org/kosukeimai/fastLink.svg?branch=master)](https://travis-ci.org/kosukeimai/fastLink) [![CRAN Version](http://www.r-pkg.org/badges/version/fastLink)](https://CRAN.R-project.org/package=fastLink)
==================================================================================================================================================================================================================================================================================

Authors: [Ted Enamorado](https://www.tedenamorado.com/), [Ben Fifield](https://www.benfifield.com/), [Kosuke Imai](https://imai.princeton.edu/)

Installation Instructions
-------------------------

`fastLink` is available on CRAN and can be installed using:

``` r
install.packages("fastLink")
```

You can also install the most recent development version of `fastLink` using the `devtools` package. First you have to install `devtools` using the following code. Note that you only have to do this once:

``` r
if(!require(devtools)) install.packages("devtools")
```

Then, load `devtools` and use the function `install_github()` to install `fastLink`:

``` r
library(devtools)
install_github("kosukeimai/fastLink",dependencies=TRUE)
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

matches.out <- fastLink(
  dfA = dfA, dfB = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c("firstname", "middlename", "lastname", "streetname", "city"),
  partial.match = c("firstname", "lastname", "streetname")
)
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
    ## Deduping the estimated matches.

-   `varnames` should be a vector of variable names to be used for matching. These variable names should exist in both `dfA` and `dfB`

-   `stringdist.match` should be a vector of variable names present in `varnames`. For those variables included in `stringdist.match`, agreement will be calculated using Jaro-Winkler distance.

-   `partial.match` is another vector of variable names present in both `stringdist.match` and `varnames`. A variable included in `partial.match` will have a partial agreement category calculated in addition to disagreement and absolute agreement, as a function of Jaro-Winkler distance.

Other arguments that can be provided include:

-   `cut.a`: Lower bound for full string-distance match, ranging between 0 and 1. Default is 0.92.

-   `cut.p`: Lower bound for partial string-distance match, ranging between 0 and 1. Default is 0.88.

-   `priors.obj`: The output from `calcMoversPriors()`, allowing the inclusion of auxiliary information on moving behavior to aid matching. We will discuss this option further at the end of this vignette.

-   `w.lambda`: The user-specified weighting of the MLE and prior estimate for the *λ* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `w.pi`: The user-specified weighting of the MLE and prior estimate for the *π* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `address.field`: The name of the address field, to be specified when providing a prior on the probability of moving in-state through `priors.obj`. The variable listed in `address.field` must be listed in `varnames`. We will discuss this option further at the end of this vignette.

-   `gender.field`: The name of the gender field, if matching on gender. If provided, the EM algorithm will implement a prior that enforces near-perfect blocking on gender, so that no matches that disagree on gender will be in the matched set. Can be used in conjunction with movers priors, if the user does not want to specify the same prior for both genders when blocking.

-   `estimate.only`: Whether to stop running the algorithm after running the EM estimation step. Can be used when running the algorithm on a random sample, and then applying those estimates to the full data set.

-   `em.obj`: An EM object, either from an `estimate.only = TRUE` run of `fastLink` or from `emlinkMARmov()`. If provided, the algorithm will skip the EM estimation step and proceed to apply the estimates from the EM object to the full data set. To be used when the EM has been estimated on a random sample of data and should be applied to the full data set.

-   `dedupe.matches`: Whether to dedupe the matches returned by the algorithm, ensuring that each observation in dataset A is matched to at most one observation in dataset B (and vice versa). Can be done either using Winkler's linear assignment solution (recommended) or by iteratively selecting the maximum posterior value for a given observation (if N size makes linear assignment solution prohibitively slow). Default is `TRUE`.

-   `linprog.dedupe`: Whether to use Winkler's linear programming solution to the deduplication problem (recommended when N size is not prohibitively large). Default is `FALSE`.

-   `n.cores`: The number of registered cores to parallelize over. If left unspecified. the function will estimate this on its own.

-   `tol.em`: Convergence tolerance for the EM algorithm. Default is 1e-04

-   `threshold.match`: Lower bound for the posterior probability of a match that will be accepted. Default is 0.85.

-   `verbose`: Whether to print out runtime for each step and EM output. Default is FALSE.

The output from `fastLink()` when `estimate.only = FALSE` will be a list of length 4 with two entries:

-   `matches`: A matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

-   `EM`: The output from the EM algorithm.

-   `nobs.a`: The number of observations in dataset A.

-   `nobs.b`: The number of observations in dataset B.

When `estimate.only = TRUE`, `fastLink()` outputs the EM object.

The datasets can then be subsetted down to the matches as follows:

``` r
dfA.match <- dfA[matches.out$matches$inds.a,]
dfB.match <- dfB[matches.out$matches$inds.b,]
```

We can also examine the EM object:

``` r
matches.out$EM
```

    ## $zeta.j
    ##                         [,1]
    ##  [1,] 2.017241585065853e-180
    ##  [2,] 1.947539595794153e-178
    ##  [3,] 1.890058813715488e-152
    ##  [4,] 7.146252712420212e-155
    ##  [5,] 6.899327389453253e-153
    ##  [6,] 6.695696749532904e-127
    ##  [7,] 5.022801341786176e-157
    ##  [8,] 4.849247887489233e-155
    ##  [9,] 4.706124450272272e-129
    ## [10,] 2.327114606174093e-173
    ## [11,] 5.794365163257927e-150
    ## [12,] 1.542003845622744e-149
    ## [13,] 1.488722802687567e-147
    ## [14,] 5.462681934540921e-124
    ## [15,] 3.839490045303878e-126
    ## [16,] 3.194080014430258e-153
    ## [17,] 7.953053070601347e-130
    ## [18,] 7.451630069159569e-102
    ## [19,] 1.320953831886898e-133
    ## [20,] 1.237670515496255e-105
    ## [21,] 3.141039821088090e-173
    ## [22,] 2.943003972369884e-145
    ## [23,] 7.820986412715230e-150
    ## [24,] 3.623542019132990e-166
    ## [25,] 2.056852594400568e-126
    ## [26,] 1.001645685324987e-149
    ## [27,] 9.384940652542974e-122
    ## [28,] 3.548416435904487e-124
    ## [29,] 2.494033104160974e-126
    ## [30,] 1.374257341937981e-154
    ## [31,] 1.326772463967184e-152
    ## [32,] 1.287613353141345e-126
    ## [33,] 4.868425442987547e-129
    ## [34,] 4.561481622011424e-101
    ## [35,] 3.421812078506934e-131
    ## [36,] 3.303577797322185e-129
    ## [37,] 3.206074138933149e-103
    ## [38,] 1.585360105969209e-147
    ## [39,] 3.947444335090121e-124
    ## [40,] 1.050498919827928e-123
    ## [41,] 2.615674504788649e-100
    ## [42,] 2.175985237992508e-127
    ## [43,] 8.999073364692281e-108
    ## [44,] 2.139851303585291e-147
    ## [45,] 5.328091626923115e-124
    ## [46,] 6.823768393775556e-124
    ## [47,] 1.699074285303070e-100
    ## [48,] 4.158193511107225e-154
    ## [49,] 4.014514954385497e-152
    ## [50,] 3.896028295760991e-126
    ## [51,] 1.473076000292071e-128
    ## [52,] 1.035363344758379e-130
    ## [53,] 9.995883115233687e-129
    ## [54,] 9.700858983107504e-103
    ## [55,] 3.178573370904009e-123
    ## [56,] 1.639383895141320e-103
    ## [57,] 2.722917122514455e-107
    ## [58,] 2.064718782312187e-123
    ## [59,] 2.832793059662758e-128
    ## [60,] 2.654191510568413e-100
    ## [61,] 1.003541431834904e-102
    ## [62,] 7.053471872884754e-105
    ## [63,] 4.410932171523577e-121
    ## [64,]  9.999999999999982e-01
    ## [65,]  9.999999999997478e-01
    ## 
    ## $p.m
    ## [1] 0.0002857142857142751
    ## 
    ## $p.u
    ## [1] 0.9997142857142858
    ## 
    ## $p.gamma.k.m
    ## $p.gamma.k.m[[1]]
    ## [1] 7.284901098762533e-130 3.615941332769613e-101  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 1.851761519001217e-101  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 7.894888670180534e-126 3.803627516075041e-101  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 5.357790657328852e-101  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 8.885842579622446e-123 3.334143076584527e-101  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 2.494206063960704e-103  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 3.763169326054399e-101  1.000000000000000e+00
    ## 
    ## 
    ## $p.gamma.k.u
    ## $p.gamma.k.u[[1]]
    ## [1] 0.986041726207487867 0.012403543869677061 0.001554729922835096
    ## 
    ## $p.gamma.k.u[[2]]
    ## [1] 0.992971419366325603 0.007028580633674448
    ## 
    ## $p.gamma.k.u[[3]]
    ## [1] 0.9990225778793940803 0.0006916261789082700 0.0002857959416976279
    ## 
    ## $p.gamma.k.u[[4]]
    ## [1] 0.9998339060710195181 0.0001660939289805375
    ## 
    ## $p.gamma.k.u[[5]]
    ## [1] 0.9984452700771648814 0.0008516719062589311 0.0007030580165761752
    ## 
    ## $p.gamma.k.u[[6]]
    ## [1] 0.8836924835667334 0.1163075164332667
    ## 
    ## $p.gamma.k.u[[7]]
    ## [1] 0.98807659331237496 0.01192340668762505
    ## 
    ## 
    ## $p.gamma.j.m
    ##                         [,1]
    ##  [1,] 3.009006327879973e-177
    ##  [2,] 3.654281324670529e-177
    ##  [3,] 4.445290741214354e-152
    ##  [4,] 7.545264033533053e-154
    ##  [5,] 9.163329831503880e-154
    ##  [6,] 1.114683343717451e-128
    ##  [7,] 7.545264033533053e-154
    ##  [8,] 9.163329831503880e-154
    ##  [9,] 1.114683343717451e-128
    ## [10,] 2.403140046685401e-173
    ## [11,] 6.026017956091710e-150
    ## [12,] 6.580083420567475e-150
    ## [13,] 7.991168292256600e-150
    ## [14,] 1.649995425760214e-126
    ## [15,] 1.649995425760214e-126
    ## [16,] 7.914744106697671e-154
    ## [17,] 1.984669606360023e-130
    ## [18,] 2.932008930581806e-105
    ## [19,] 1.984669606360023e-130
    ## [20,] 2.932008930581806e-105
    ## [21,] 3.996563231170685e-173
    ## [22,] 5.904236678929788e-148
    ## [23,] 1.002162226330010e-149
    ## [24,] 3.191851429805230e-169
    ## [25,] 2.636038848209564e-126
    ## [26,] 1.052073820442872e-149
    ## [27,] 1.554258616791871e-124
    ## [28,] 2.638138273242596e-126
    ## [29,] 2.638138273242596e-126
    ## [30,] 2.697987141682912e-152
    ## [31,] 3.276564736571669e-152
    ## [32,] 3.985813239976726e-127
    ## [33,] 6.765364749969244e-129
    ## [34,] 9.994666014931651e-104
    ## [35,] 6.765364749969244e-129
    ## [36,] 8.216182808034852e-129
    ## [37,] 9.994666014931651e-104
    ## [38,] 2.154744868944238e-148
    ## [39,] 5.403152133794176e-125
    ## [40,] 5.899947864981731e-125
    ## [41,] 1.479447351535779e-101
    ## [42,] 7.096654344567234e-129
    ## [43,] 1.779528686541704e-105
    ## [44,] 3.583467441963895e-148
    ## [45,] 8.985759768818895e-125
    ## [46,] 9.433285710820711e-125
    ## [47,] 2.365453031201999e-101
    ## [48,] 7.484790188854181e-153
    ## [49,] 9.089887499663816e-153
    ## [50,] 1.105749370420428e-127
    ## [51,] 1.876856079936833e-129
    ## [52,] 1.876856079936833e-129
    ## [53,] 2.279343867927121e-129
    ## [54,] 2.772732937591762e-104
    ## [55,] 1.636771028753625e-125
    ## [56,] 4.936791079553979e-106
    ## [57,] 4.936791079553979e-106
    ## [58,] 2.616994100756443e-125
    ## [59,] 6.711141648528753e-128
    ## [60,] 9.914560682961804e-103
    ## [61,] 1.682859063319548e-104
    ## [62,] 1.682859063319548e-104
    ## [63,] 8.913740626988180e-124
    ## [64,]  5.000000000000000e-01
    ## [65,]  5.000000000000000e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.857213509222646e-01
    ##  [2,] 3.594125092756943e-03
    ##  [3,] 4.505078457280588e-04
    ##  [4,] 2.022430368641518e-03
    ##  [5,] 2.544040798080149e-05
    ##  [6,] 3.188843765335484e-06
    ##  [7,] 2.877437812909061e-01
    ##  [8,] 3.619565500737745e-03
    ##  [9,] 4.536966894933943e-04
    ## [10,] 1.978057058433485e-04
    ## [11,] 1.992058401535667e-04
    ## [12,] 8.173789497658884e-05
    ## [13,] 1.028191342425847e-06
    ## [14,] 5.785678967843724e-07
    ## [15,] 8.231646287337325e-05
    ## [16,] 4.746446532783942e-05
    ## [17,] 4.780043453630252e-05
    ## [18,] 7.536878402088188e-08
    ## [19,] 2.877915817254423e-01
    ## [20,] 4.537720582774151e-04
    ## [21,] 2.437197660118470e-04
    ## [22,] 3.842823309946346e-07
    ## [23,] 2.454448952492300e-04
    ## [24,] 1.687278888621288e-07
    ## [25,] 2.454856689284907e-04
    ## [26,] 2.011914846943468e-04
    ## [27,] 3.172263537740998e-07
    ## [28,] 1.424099974483970e-06
    ## [29,] 2.026155846688308e-04
    ## [30,] 3.760532236689203e-02
    ## [31,] 4.730421170969218e-04
    ## [32,] 5.929375845638836e-05
    ## [33,] 2.661829286886174e-04
    ## [34,] 4.197008637472115e-07
    ## [35,] 3.787150529558064e-02
    ## [36,] 4.763904658996110e-04
    ## [37,] 5.971345932013548e-05
    ## [38,] 2.603427188846492e-05
    ## [39,] 2.621855108889131e-05
    ## [40,] 1.075796359027457e-05
    ## [41,] 1.083411202020283e-05
    ## [42,] 6.247053340130634e-06
    ## [43,] 3.787779656763368e-02
    ## [44,] 3.207726807421036e-05
    ## [45,] 3.230432160341607e-05
    ## [46,] 2.647989243710023e-05
    ## [47,] 2.666732588738419e-05
    ## [48,] 3.447882370093512e-03
    ## [49,] 4.337134940468225e-05
    ## [50,] 5.436408773305789e-06
    ## [51,] 2.440525354606058e-05
    ## [52,] 3.472287623639570e-03
    ## [53,] 4.367834618277343e-05
    ## [54,] 5.474889475444408e-06
    ## [55,] 9.863548738960371e-07
    ## [56,] 5.768217005433588e-07
    ## [57,] 3.472864445340112e-03
    ## [58,] 2.427835969735794e-06
    ## [59,] 4.537943265071782e-04
    ## [60,] 7.155149721169606e-07
    ## [61,] 3.212106564955436e-06
    ## [62,] 4.570064330721336e-04
    ## [63,] 3.870856928151778e-07
    ## [64,] 1.694818367219303e-19
    ## [65,] 2.411323787194386e-17
    ## 
    ## $patterns.w
    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 gamma.7 counts
    ## 1        0       0       0       0       0       0       0 100795
    ## 43       1       0       0       0       0       0       0    164
    ## 51       2       0       0       0       0       0       0   1289
    ## 19       0       2       0       0       0       0       0    722
    ## 47       1       2       0       0       0       0       0      2
    ## 57       2       2       0       0       0       0       0      9
    ## 25       0      NA       0       0       0       0       0  48376
    ## 48       1      NA       0       0       0       0       0     67
    ## 60       2      NA       0       0       0       0       0    597
    ## 13       0       0       1       0       0       0       0     32
    ## 39       0      NA       1       0       0       0       0     10
    ## 16       0       0       2       0       0       0       0     69
    ## 46       1       0       2       0       0       0       0      1
    ## 24       0       2       2       0       0       0       0      1
    ## 41       0      NA       2       0       0       0       0     37
    ## 11       0       0       0       2       0       0       0     15
    ## 33       0      NA       0       2       0       0       0      8
    ## 63       2      NA       0       2       0       0       0      1
    ## 35       0      NA       0      NA       0       0       0    322
    ## 64       2      NA       0      NA       0       0       0      4
    ## 5        0       0       0       0       1       0       0     89
    ## 55       2       0       0       0       1       0       0      4
    ## 29       0      NA       0       0       1       0       0     36
    ## 15       0       0       1       0       1       0       0      1
    ## 38       0      NA       0      NA       1       0       0      1
    ## 8        0       0       0       0       2       0       0     68
    ## 56       2       0       0       0       2       0       0      2
    ## 23       0       2       0       0       2       0       0      1
    ## 31       0      NA       0       0       2       0       0     41
    ## 3        0       0       0       0       0       2       0  12994
    ## 45       1       0       0       0       0       2       0     23
    ## 53       2       0       0       0       0       2       0    160
    ## 21       0       2       0       0       0       2       0     79
    ## 58       2       2       0       0       0       2       0      1
    ## 27       0      NA       0       0       0       2       0   6689
    ## 50       1      NA       0       0       0       2       0      8
    ## 62       2      NA       0       0       0       2       0     76
    ## 14       0       0       1       0       0       2       0      6
    ## 40       0      NA       1       0       0       2       0      1
    ## 18       0       0       2       0       0       2       0      9
    ## 42       0      NA       2       0       0       2       0      3
    ## 12       0       0       0       2       0       2       0      4
    ## 37       0      NA       0      NA       0       2       0     20
    ## 6        0       0       0       0       1       2       0     11
    ## 30       0      NA       0       0       1       2       0      6
    ## 10       0       0       0       0       2       2       0      4
    ## 32       0      NA       0       0       2       2       0      6
    ## 2        0       0       0       0       0       0       2   1198
    ## 44       1       0       0       0       0       0       2      6
    ## 52       2       0       0       0       0       0       2     19
    ## 20       0       2       0       0       0       0       2     11
    ## 26       0      NA       0       0       0       0       2    592
    ## 49       1      NA       0       0       0       0       2      1
    ## 61       2      NA       0       0       0       0       2      5
    ## 17       0       0       2       0       0       0       2      1
    ## 34       0      NA       0       2       0       0       2      1
    ## 36       0      NA       0      NA       0       0       2      3
    ## 9        0       0       0       0       2       0       2      1
    ## 4        0       0       0       0       0       2       2    149
    ## 54       2       0       0       0       0       2       2      3
    ## 22       0       2       0       0       0       2       2      3
    ## 28       0      NA       0       0       0       2       2     92
    ## 7        0       0       0       0       1       2       2      1
    ## 59       2       2       2       2       2       2       2     43
    ## 65       2      NA       2       2       2       2       2      7
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -405.20321331874283 3.009006327879973e-177 2.857213509222646e-01
    ## 43 -400.63320732884682 3.654281324670529e-177 3.594125092756943e-03
    ## 51 -340.79595379420402 4.445290741214354e-152 4.505078457280588e-04
    ## 19 -346.37372889698696 7.545264033533053e-154 2.022430368641518e-03
    ## 47 -341.80372290709101 9.163329831503880e-154 2.544040798080149e-05
    ## 57 -281.96646937244816 1.114683343717451e-128 3.188843765335484e-06
    ## 25 -351.33149939185790 7.545264033533053e-154 2.877437812909061e-01
    ## 48 -346.76149340196196 9.163329831503880e-154 3.619565500737745e-03
    ## 60 -286.92423986731910 1.114683343717451e-128 4.536966894933943e-04
    ## 13 -388.94221956031498 2.403140046685401e-173 1.978057058433485e-04
    ## 39 -335.07050563343000 6.026017956091710e-150 1.992058401535667e-04
    ## 16 -334.09172369312046 6.580083420567475e-150 8.173789497658884e-05
    ## 46 -329.52171770322445 7.991168292256600e-150 1.028191342425847e-06
    ## 24 -275.26223927136459 1.649995425760214e-126 5.785678967843724e-07
    ## 41 -280.22000976623548 1.649995425760214e-126 8.231646287337325e-05
    ## 11 -342.57384773319336 7.914744106697671e-154 4.746446532783942e-05
    ## 33 -288.70213380630844 1.984669606360023e-130 4.780043453630252e-05
    ## 63 -224.29487428176967 2.932008930581806e-105 7.536878402088188e-08
    ## 35 -297.40509089870955 1.984669606360023e-130 2.877915817254423e-01
    ## 64 -232.99783137417077 2.932008930581806e-105 4.537720582774151e-04
    ## 5  -388.64229479572055 3.996563231170685e-173 2.437197660118470e-04
    ## 55 -324.23503527118169 5.904236678929788e-148 3.842823309946346e-07
    ## 29 -334.77058086883557 1.002162226330010e-149 2.454448952492300e-04
    ## 15 -372.38130103729264 3.191851429805230e-169 1.687278888621288e-07
    ## 38 -280.84417237568726 2.636038848209564e-126 2.454856689284907e-04
    ## 8  -334.52316212950853 1.052073820442872e-149 2.011914846943468e-04
    ## 56 -270.11590260496973 1.554258616791871e-124 3.172263537740998e-07
    ## 23 -275.69367770775267 2.638138273242596e-126 1.424099974483970e-06
    ## 31 -280.65144820262361 2.638138273242596e-126 2.026155846688308e-04
    ## 3  -345.71981845689777 2.697987141682912e-152 3.760532236689203e-02
    ## 45 -341.14981246700182 3.276564736571669e-152 4.730421170969218e-04
    ## 53 -281.31255893235897 3.985813239976726e-127 5.929375845638836e-05
    ## 21 -286.89033403514196 6.765364749969244e-129 2.661829286886174e-04
    ## 58 -222.48307451060313 9.994666014931651e-104 4.197008637472115e-07
    ## 27 -291.84810453001290 6.765364749969244e-129 3.787150529558064e-02
    ## 50 -287.27809854011696 8.216182808034852e-129 4.763904658996110e-04
    ## 62 -227.44084500547405 9.994666014931651e-104 5.971345932013548e-05
    ## 14 -329.45882469846993 2.154744868944238e-148 2.603427188846492e-05
    ## 40 -275.58711077158500 5.403152133794176e-125 2.621855108889131e-05
    ## 18 -274.60832883127534 5.899947864981731e-125 1.075796359027457e-05
    ## 42 -220.73661490439048 1.479447351535779e-101 1.083411202020283e-05
    ## 12 -283.09045287134836 7.096654344567234e-129 6.247053340130634e-06
    ## 37 -237.92169603686452 1.779528686541704e-105 3.787779656763368e-02
    ## 6  -329.15889993387543 3.583467441963895e-148 3.207726807421036e-05
    ## 30 -275.28718600699057 8.985759768818895e-125 3.230432160341607e-05
    ## 10 -275.03976726766348 9.433285710820711e-125 2.647989243710023e-05
    ## 32 -221.16805334077856 2.365453031201999e-101 2.666732588738419e-05
    ## 2  -344.61265119932671 7.484790188854181e-153 3.447882370093512e-03
    ## 44 -340.04264520943076 9.089887499663816e-153 4.337134940468225e-05
    ## 52 -280.20539167478796 1.105749370420428e-127 5.436408773305789e-06
    ## 20 -285.78316677757095 1.876856079936833e-129 2.440525354606058e-05
    ## 26 -290.74093727244184 1.876856079936833e-129 3.472287623639570e-03
    ## 49 -286.17093128254589 2.279343867927121e-129 4.367834618277343e-05
    ## 61 -226.33367774790304 2.772732937591762e-104 5.474889475444408e-06
    ## 17 -273.50116157370439 1.636771028753625e-125 9.863548738960371e-07
    ## 34 -228.11157168689240 4.936791079553979e-106 5.768217005433588e-07
    ## 36 -236.81452877929351 4.936791079553979e-106 3.472864445340112e-03
    ## 9  -273.93260001009247 2.616994100756443e-125 2.427835969735794e-06
    ## 4  -285.12925633748171 6.711141648528753e-128 4.537943265071782e-04
    ## 54 -220.72199681294290 9.914560682961804e-103 7.155149721169606e-07
    ## 22 -226.29977191572590 1.682859063319548e-104 3.212106564955436e-06
    ## 28 -231.25754241059681 1.682859063319548e-104 4.570064330721336e-04
    ## 7  -268.56833781445937 8.913740626988180e-124 3.870856928151778e-07
    ## 59   42.52839400921905  5.000000000000000e-01 1.694818367219303e-19
    ## 65   37.57062351434814  5.000000000000000e-01 2.411323787194386e-17
    ## 
    ## $iter.converge
    ## [1] 4
    ## 
    ## $nobs.a
    ## [1] 500
    ## 
    ## $nobs.b
    ## [1] 350
    ## 
    ## attr(,"class")
    ## [1] "fastLink"    "fastLink.EM"

which is a list of parameter estimates for different fields. These fields are:

-   `zeta.j`: The posterior match probabilities for each unique pattern.

-   `p.m`: The posterior probability of a pair matching.

-   `p.u`: The posterior probability of a pair not matching.

-   `p.gamma.k.m`: The posterior of the matching probability for a specific matching field.

-   `p.gamma.k.u`: The posterior of the non-matching probability for a specific matching field.

-   `p.gamma.j.m`: The posterior probability that a pair is in the matched set given a particular agreement pattern.

-   `p.gamma.j.u`: The posterior probability that a pair is in the unmatched set given a particular agreement pattern.

-   `patterns.w`: Counts of the agreement patterns observed (2 = match, 1 = partial match, 0 = non-match), along with the Felligi-Sunter Weights.

-   `iter.converge`: The number of iterations it took the EM algorithm to converge.

-   `nobs.a`: The number of observations in dataset A.

-   `nobs.b`: The number of observations in dataset B.

Lastly, we can summarize the accuracy of the match using the `summary()` function:

``` r
summary(matches.out)
```

    ##                   95%     85%     75%   Exact
    ## 1 Match Count      50      50      50      43
    ## 2  Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 3         FDR      0%      0%      0%        
    ## 4         FNR      0%      0%      0%

where each column gives the match count, match rate, false discovery rate (FDR) and false negative rate (FNR) under different cutoffs for matches based on the posterior probability of a match. Other arguments include:

-   `num.comparisons`: The number of comparisons attempted for each observation in an across-state merge. For instance, if matching each state's voter file to every other state's voter file to try and find movers, `num.comparisons` = 49. Default is 1.

-   `thresholds`: A vector of thresholds between 0 and 1 to summarize the match.

-   `weighted`: Whether to weight the FDR and FNR calculations when doing across-state matches, so that the pooled FDR and FNR calculations are the sum of the within and across-geography FDR and FNR. Default is TRUE.

-   `digits`: Number of digits to include in the summary object. Default is 3.

### Preprocessing Matches via Clustering

In order to reduce the number of pairwise comparisons that need to be conducted, researchers will often cluster similar observations from dataset A and dataset B together so that comparisons are only made between these maximally similar groups. Here, we implement a form of this clustering that uses word embedding, a common preprocessing method for textual data, to form maximally similar groups.

First, we provide some guidance on how to choose the variables to cluster on. We recommend specifically that researchers cluster on first name only - matching on address fields will fail to group people who move into the same group, while matching on last name will fail to cluster women who changed their last name after marriage. Date fields will often change due to administrative errors, and while there may be administrative errors in first name, the word embedding can accomodate those errors while clustering similar spellings in the same group.

The `clusterMatch()` function runs the clustering procedure from start to finish:

``` r
cluster.out <- clusterMatch(vecA = dfA$firstname, vecB = dfB$firstname, nclusters = 3)
```

-   `vecA`: The variable to cluster on in dataset A.

-   `vecB`: The variable to cluster on in dataset B.

-   `nclusters`: The number of clusters to create.

Other arguments that can be provided include:

-   `word.embed`: Whether to use word embedding clustering, which is explained in more detail below. If `FALSE`, then alphabetical clustering is used. Default is FALSE.

-   `max.n`: The maximum size of a dataset in a cluster. `nclusters` is then chosen to reflect this maximum n size. If `nclusters` is filled, then `max.n` should be left as NULL, and vice versa.

-   `min.var`: The amount of variance the least informative dimension of the PCA should contribute in order to be included in the K-means step. Only relevant for word embedding clustering. The default value is .2 (out of 1).

-   `weighted.kmeans`: Whether to weight the dimensions of the PCA used in the K-means algorithm by the amount of variance explained by each feature. Only relevant for word embedding clustering. Default is `TRUE`.

-   `iter.max`: The maximum number of iterations the K-means algorithm should attempt to run. The default value is 5000.

The output of `clusterMatch()` includes the following entries:

-   `clusterA`: Cluster assignments for dataset A.

-   `clusterB`: Cluster assignments for dataset B.

-   `n.clusters`: The number of clusters created.

-   `kmeans`: The output from the K-means algorithm.

-   `pca`: The output from the PCA step (if word embedding clustering is used).

-   `dims.pca`: The number of dimensions from the PCA step included in the K-means algorithm (if word embedding clustering is used).

If using word embedding clustering, the clustering proceeds in three steps. First, a word embedding matrix is created out of the provided data. For instance, a word embedding of the name `ben` would be a vector of length 26, where each entry in the vector represents a different letter. That matrix takes the value 0 for most entries, except for entry 2 (B), 5 (E), and 14 (N), which take the count of 1 (representing the number of times that letter appears in the string). Second, principal components analysis is run on the word embedding matrix. Last, a subset of dimensions from the PCA step are selected according to the amount of variance explained by the dimensions, and then the K-means algorithm is run on that subset of dimensions in order to form the clusters.

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
tc <- tableCounts(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB))
```

    ## Parallelizing gamma calculation using 1 cores.

As with the functions above, `tableCounts()` also includes an `n.cores` argument. If left unspecified, the function will automatically determine the number of available cores for parallelization.

#### 3) Running the EM algorithm

We next run the EM algorithm to calculate the Fellegi-Sunter weights. The only required input to this function is the output from `tableCounts()`, as follows:

``` r
## Run EM algorithm
em.out <- emlinkMARmov(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB))
```

As with the other functions above, `emlinkMARmov()` accepts an `n.cores` argument. Other optional arguments include:

-   `p.m`: Starting values for the probability of being in the matched set

-   `p.gamma.k.m`: Starting values for the probability that conditional on being in the matched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `p.gamma.k.u`: Starting values for the probability that conditional on being in the unmatched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `tol`: Convergence tolerance for the EM algorithm

-   `iter.max`: Maximum number of iterations for the EM algorithm

and additional arguments that allow the user to specify priors calculated from auxiliary information. We will discuss these further at the end of this vignette.

#### 4) Finding the matches

Once we've run the EM algorithm and selected our lower bound for accepting a match, we then run `matchesLink()` to get the paired indices of `dfA` and `dfB` that match. We run the function as follows:

``` r
matches.out <- matchesLink(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB),
                           em = em.out, thresh = .95)
```

    ## Parallelizing gamma calculation using 1 cores.

Here, `thresh` indicates the range of posterior probabilities that we want to declare a match --- in our case, we've chosen to accept as a match any pair with a 95% or higher posterior matching probability. If we specify `thresh = c(.85, .95)`, for instance, the function will return all pairs with a posterior matching probability between 85% and 95%.

As with the other functions above, `matchesLink()` accepts an `n.cores` argument. This returns a matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

The datasets can then be subsetted down to the matches as follows:

``` r
dfA.match <- dfA[matches.out$inds.a,]
dfB.match <- dfB[matches.out$inds.b,]
```

#### 5) Deduping the Matches

After returning the matched pairs, we can dedupe them using the `dedupeMatches()` function to ensure that each observation in dataset A is matched to at most a single observation in dataset B, and vice versa. The deduplication also corrects the EM object so that it displays the proper counts of patterns. We run the function as follows:

``` r
dm.out <- dedupeMatches(dfA.match, dfB.match, EM = em.out, matchesLink = matches.out,
                        varnames = c("firstname", "middlename", "lastname", "housenum", 
                                     "streetname", "city", "birthyear"),
                        stringdist.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, FALSE),
                        partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE))
```

which returns a list with the following elements:

-   `matchesA`: A deduped version of dataset A (post-matching)

-   `matchesB`: A deduped version of dataset B (post-matching)

-   `EM`: The EM object with the counts corrected to reflect deduping.

-   `matchesLink`: Deduped indices of the matched pairs from dataset A and dataset B.

-   `max.zeta`: The posterior matching probability for each matched pair.

Other arguments to `dedupeMatches()` include:

-   `linprog`: Whether to use Winkler's linear assignment solution to the deduping problem. Recommended, but can be slow on larger data sets. If set to `FALSE`, then the deduping is conducted by iteratively selecting the matched pair for a given observation with the largest posterior match probability. Default is `TRUE`.

-   `cut.a`: Lower bound for full string-distance match, ranging between 0 and 1. Default is 0.92.

-   `cut.p`: Lower bound for partial string-distance match, ranging between 0 and 1. Default is 0.88.

Lastly, we can summarize the match as done earlier by feeding the output from `emlinkMARmov()` (or the `EM` entry returned by `dedupeMatches()`) into the `summary()` function:

``` r
## Non-deduped dataframe
summary(em.out)
```

    ##                   95%     85%     75%   Exact
    ## 1 Match Count      50      50      50      43
    ## 2  Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 3         FDR      0%      0%      0%        
    ## 4         FNR      0%      0%      0%

Using Auxiliary Information to Inform `fastLink`
------------------------------------------------

The `fastLink` algorithm also includes several ways to incorporate auxiliary information on migration behavior to inform the matching of data sets over time. Auxiliary information is incorporated into the estimation as priors on two parameters of the model:

-   
    *λ*
    : The probability that a randomly selected pair of observations from dataset A and dataset B are a true match. When matching, for example, the same state to itself in subsequent years, the prior for this quantity is equal to the number of non-movers to the number of in-state movers, divided by the size of the cross-product of A and B. When matching two different states in subsequent years to find movers, the numerator is the size of the outflow from state A to state B, divided by the size of the cross-product of A and B.

-   
    *π*<sub>*k*, *l*</sub>
    : The probability that an address field does not match conditional on being in the matched set. Specified when trying to find movers within the same geography over time. For example, when trying to find movers within the same state over time, this quantity is equal to the estimated number of in-state movers divided by the number of in-state movers and non-movers.

The functions `calcMoversPriors()` can be used to calculate estimates for the corresponding prior distributions using the IRS Statistics of Income Migration Data.

Below, we show an example where we incorporate the auxiliary moving information for California into our estimates. First, we use `calcMoversPriors()` to estimate optimal parameter values for the priors:

``` r
priors.out <- calcMoversPriors(geo.a = "CA", geo.b = "CA", year.start = 2014, year.end = 2015)
names(priors.out)
```

    ## [1] "lambda.prior" "pi.prior"

where the `lambda.prior` entry is the estimate of the match rate, while `pi.prior` is the estimate of the in-state movers rate.

The `calcMoversPriors()` function accepts the following functions:

-   `geo.a`: The state name or county name of dataset A

-   `geo.b`: The state name or county name of dataset B

-   `year.start`: The year of dataset A

-   `year.end`: The year of dataset B

-   `county`: Boolean, whether the geographies in `geo.a` or `geo.b` refer to counties or states. Default is FALSE

-   `state.a`: If `county = TRUE`, the name of the state for `geo.a`

-   `state.b`: If `county = TRUE`, the name of the state for `geo.b`

-   `matchrate.lambda`: If TRUE, then returns the match rate for lambda (the expected share of observations in dataset A that can be found in dataset B). If FALSE, then returns the expected share of matches across all pairwise comparisons of datasets A and B. Default is FALSE.

-   `remove.instate`: If TRUE, then for calculating cross-state movers rates assumes that successful matches have been subsetted out. The interpretation of the prior is then the match rate conditional on being an out-of-state or county mover. Default is TRUE.

### Incorporating Auxiliary Information with `fastLink()` Wrapper

We can re-run the full match above while incorporating auxiliary information as follows:

``` r
## Reasonable prior estimates for this dataset
priors.out <- list(lambda.prior = 50/(nrow(dfA) * nrow(dfB)), pi.prior = 0.02)

matches.out.aux <- fastLink(
  dfA = dfA, dfB = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c("firstname", "middlename", "lastname", "streetname", "city"),
  partial.match = c("firstname", "lastname", "streetname"),
  priors.obj = priors.out, 
  w.lambda = .5, w.pi = .5, 
  address.field = "streetname"
)
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
    ## Deduping the estimated matches.

where `priors.obj` is an input for the the optimal prior parameters. This can be calculated by `calcMoversPriors()`, or can be provided by the user as a list with two entries named `lambda.prior` and `pi.prior`. `w.lambda` and `w.pi` are user-specified weights between 0 and 1 indicating the weighting between the MLE estimate and the prior, where a weight of 0 indicates no weight being placed on the prior. `address_field` is a vector of booleans of the same length as `varnames`, where `TRUE` indicates an address-related field used for matching.

### Incorporating Auxiliary Information when Running the Algorithm Step-by-Step

If we are running the algorithm step-by-step, we can incorporate the prior information into the EM algorithm as follows:

``` r
em.out.aux <- emlinkMARmov(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB),
                           prior.lambda = priors.out$lambda.prior, w.lambda = .5,
                           prior.pi = priors.out$pi.prior, w.pi = .5,
                           address.field = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE))
```

All other steps are the same. The newly specified arguments include the prior estimates of the parameters (`prior.lambda`, `prior.pi`), the weightings of the prior and MLE estimate (`w.lambda`, `w.pi`), and the vector of boolean indicators where `TRUE` indicates an address field (`address.field`).

Aggregating Multiple Matches Together
-------------------------------------

Often, we run several different matches for a single data set - for instance, when blocking by gender or by some other criterion to reduce the number of pairwise comparisons. Here, we walk through how to aggregate those multiple matches into a single summary. First, we use the `clusterMatch()` function to partition the two datasets into two maximally similar groups:

``` r
cl.out <- clusterMatch(dfA$firstname, dfB$firstname, nclusters = 2)
dfA$cluster <- cl.out$clusterA
dfB$cluster <- cl.out$clusterB
```

and then run `fastLink()` on both subsets:

``` r
link.1 <- fastLink(
  dfA = subset(dfA, cluster == 1), dfB = subset(dfB, cluster == 1), 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c("firstname", "middlename", "lastname", "streetname", "city"),
  partial.match = c("firstname", "lastname", "streetname")
)
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
    ## Deduping the estimated matches.

``` r
link.2 <- fastLink(
  dfA = subset(dfA, cluster == 2), dfB = subset(dfB, cluster == 2), 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c("firstname", "middlename", "lastname", "streetname", "city"),
  partial.match = c("firstname", "lastname", "streetname")
)
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
    ## Deduping the estimated matches.

To aggregate the two matches into a single summary, we use the `aggregateEM()` function as follows:

``` r
agg.out <- aggregateEM(em.list = list(link.1, link.2))
```

`aggregateEM()` accepts two arguments:

-   `em.list`: A list of either `fastLink` or `fastLink.EM` objects to be aggregated together.

-   `within.geo`: A vector of booleans the same length of `em.list`, to be used if the user wants to aggregate together within-geography matches (for instance, CA 2015 voter file to CA 2016 voter file) and across-geography matches (for instance, CA 2015 voter file to NY 2016 voter file). For entry `i` in `em.list`, `within.geo = TRUE` if it is a within-geography match, and `FALSE` if an across-geogpraphy match. Default is `NULL` (assumes all matches are within-geography).

We can then summarize the aggregated output as done previously:

``` r
summary(agg.out)
```

    ##                   95%     85%     75%   Exact
    ## 1 Match Count      50      50      50      43
    ## 2  Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 3         FDR      0%      0%      0%        
    ## 4         FNR      0%      0%      0%

If we assume that the first `fastLink` run was for a within-geography match and the second was an across-geography match, the call to `aggregateEM()` would be:

``` r
agg.out <- aggregateEM(em.list = list(link.1, link.2), within.geo = c(TRUE, FALSE))
summary(agg.out)
```

    ##                                 95%     85%     75%   Exact
    ## 1  Match Count          All      50      50      50      43
    ## 2              Within-State      24      24      24      20
    ## 3              Across-State      26      26      26      23
    ## 4   Match Rate          All 29.762% 29.762% 29.762% 25.595%
    ## 5              Within-State 14.286% 14.286% 14.286% 11.905%
    ## 6              Across-State 15.476% 15.476% 15.476%  13.69%
    ## 7          FDR          All      0%      0%      0%        
    ## 8              Within-State      0%      0%      0%        
    ## 9              Across-State      0%      0%      0%        
    ## 10         FNR          All      0%      0%      0%        
    ## 11             Within-State      0%      0%      0%        
    ## 12             Across-State      0%      0%      0%

Random Sampling with `fastLink`
-------------------------------

The probabilistic modeling framework of `fastLink` is especially flexible in that it allows us to run the matching algorithm on a random smaller subset of data to be matched, and then apply those estimates to the full sample of data. This may be desired, for example, when using blocking along with a prior. We may want to block in order to reduce the number of pairwise comparisons, but may also be uncomfortable making the assumption that the same prior applies to all blocks uniformly. Random sampling allows us to run the EM algorithm with priors on a random sample from the full dataset, and the estimates can then be applied to each block separately to get matches for the entire dataset.

This functionality is incorporated into the `fastLink()` wrapper, which we show in the following example:

``` r
## Take 30% random samples of dfA and dfB
dfA.s <- dfA[sample(1:nrow(dfA), nrow(dfA) * .3),]
dfB.s <- dfB[sample(1:nrow(dfB), nrow(dfB) * .3),]

## Run the algorithm on the random samples
rs.out <- fastLink(
  dfA = dfA.s, dfB = dfB.s, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c("firstname", "middlename", "lastname", "streetname", "city"),
  partial.match = c("firstname", "lastname", "streetname"),
  estimate.only = TRUE
)
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

``` r
class(rs.out)
```

    ## [1] "fastLink"    "fastLink.EM"

``` r
## Apply to the whole dataset
fs.out <- fastLink(
  dfA = dfA, dfB = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c("firstname", "middlename", "lastname", "streetname", "city"),
  partial.match = c("firstname", "lastname", "streetname"),
  em.obj = rs.out
)
```

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for zeta parameters.
    ## Parallelizing gamma calculation using 1 cores.
    ## Imputing matching probabilities using provided EM object.
    ## Getting the indices of estimated matches.
    ## Parallelizing gamma calculation using 1 cores.
    ## Deduping the estimated matches.

``` r
summary(fs.out)
```

    ##                   95%     85%     75%   Exact
    ## 1 Match Count      50      50      50      43
    ## 2  Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 3         FDR      0%      0%      0%        
    ## 4         FNR      0%      0%      0%

In the first run of `fastLink()`, we specify `estimate.only = TRUE`, which runs the algorithm only through the EM estimation step and returns the EM object. In the second run of `fastLink()`, we provide the EM object from the first stage as an argument to `em.obj`. Then, using the parameter values calculated in the previous EM stage, we estimate posterior probabilities of belonging to the matched set for all matching patterns in the full dataset that were not present in the random sample.

This functionality can also be run step-by-step as follows:

``` r
## --------------
## 30% sample run
## --------------
## Calculate gammas 
g_firstname <- gammaCKpar(dfA.s$firstname, dfB.s$firstname)
g_middlename <- gammaCK2par(dfA.s$middlename, dfB.s$middlename)
g_lastname <- gammaCKpar(dfA.s$lastname, dfB.s$lastname)
g_housenum <- gammaKpar(dfA.s$housenum, dfB.s$housenum)
g_streetname <- gammaCKpar(dfA.s$streetname, dfB.s$streetname)
g_city <- gammaCK2par(dfA.s$city, dfB.s$city)
g_birthyear <- gammaKpar(dfA.s$birthyear, dfB.s$birthyear)

## Get counts
gammalist <- list(g_firstname, g_middlename, g_lastname, g_housenum, g_streetname, g_city, g_birthyear)
tc <- tableCounts(gammalist, nobs.a = nrow(dfA.s), nobs.b = nrow(dfB.s))
```

    ## Parallelizing gamma calculation using 1 cores.

``` r
## Run EM algorithm
em.out.rs <- emlinkMARmov(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB))

## ------------------------
## Calculate on full sample
## ------------------------
## Calculate gammas 
g_firstname <- gammaCKpar(dfA$firstname, dfB$firstname)
g_middlename <- gammaCK2par(dfA$middlename, dfB$middlename)
g_lastname <- gammaCKpar(dfA$lastname, dfB$lastname)
g_housenum <- gammaKpar(dfA$housenum, dfB$housenum)
g_streetname <- gammaCKpar(dfA$streetname, dfB$streetname)
g_city <- gammaCK2par(dfA$city, dfB$city)
g_birthyear <- gammaKpar(dfA$birthyear, dfB$birthyear)

## Get counts
gammalist <- list(g_firstname, g_middlename, g_lastname, g_housenum, g_streetname, g_city, g_birthyear)
tc <- tableCounts(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB))
```

    ## Parallelizing gamma calculation using 1 cores.

``` r
## Apply random sample EM object to full dataset
em.obj.full <- emlinkRS(patterns.out = tc, em.out = em.out.rs, nobs.a = nrow(dfA), nobs.b = nrow(dfB))
summary(em.obj.full)
```

    ##                   95%     85%     75%   Exact
    ## 1 Match Count      50      50      50      43
    ## 2  Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 3         FDR      0%      0%      0%        
    ## 4         FNR      0%      0%      0%

``` r
## Get matches
matches.out <- matchesLink(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB), em = em.obj.full, thresh = .95)
```

    ## Parallelizing gamma calculation using 1 cores.

where `emlinkRS()` takes an EM object and applies the parameter estimates to all new matching patterns. The arguments are:

-   `patterns.out`: The output from `tableCounts()`, with counts of the occurence of each matching pattern.

-   `em.out`: The output from `emlinkMARmov()`

-   `nobs.a`: The number of rows in dataset A

-   `nobs.b`: The number of rows in dataset B
