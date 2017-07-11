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
    ##  [1,] 1.484455814013144e-132
    ##  [2,] 2.571510147361679e-130
    ##  [3,] 9.388891405647145e-112
    ##  [4,] 7.541098605278518e-113
    ##  [5,] 1.306338080438052e-110
    ##  [6,]  4.769596724662645e-92
    ##  [7,] 5.300321961369163e-115
    ##  [8,] 9.181702533198369e-113
    ##  [9,]  3.352349516940104e-94
    ## [10,] 7.991399731906242e-128
    ## [11,] 2.853368291683355e-110
    ## [12,] 2.532535689711943e-109
    ## [13,] 4.387089978141023e-107
    ## [14,]  1.286538890361050e-89
    ## [15,]  9.042542329260718e-92
    ## [16,] 2.261792347768278e-111
    ## [17,]  8.075840008011241e-94
    ## [18,]  5.107810157016924e-73
    ## [19,]  1.341347996748833e-97
    ## [20,]  8.483762574656806e-77
    ## [21,] 2.878047694936190e-126
    ## [22,] 1.820308628451245e-105
    ## [23,] 1.027620981327656e-108
    ## [24,] 1.549364377208926e-121
    ## [25,]  2.600591727761492e-91
    ## [26,] 8.837487381566048e-109
    ## [27,]  5.589537158399972e-88
    ## [28,]  4.489481137678526e-89
    ## [29,]  3.155468017953410e-91
    ## [30,] 5.145648753586643e-114
    ## [31,] 8.913763454389935e-112
    ## [32,]  3.254521751537836e-93
    ## [33,]  2.614011429145818e-94
    ## [34,]  1.653310877271546e-73
    ## [35,]  1.837279010709801e-96
    ## [36,]  3.182702762167348e-94
    ## [37,]  1.162042881343413e-75
    ## [38,] 2.770101722241677e-109
    ## [39,]  9.890783447390145e-92
    ## [40,]  8.778664202843150e-91
    ## [41,]  3.134464914790669e-73
    ## [42,]  7.840172045068094e-93
    ## [43,]  4.649586456155080e-79
    ## [44,] 9.976330985678584e-108
    ## [45,]  3.562097687119851e-90
    ## [46,]  3.063385619195432e-90
    ## [47,]  1.093796792082848e-72
    ## [48,] 3.278701008299421e-113
    ## [49,] 5.679665796325947e-111
    ## [50,]  2.073713978409842e-92
    ## [51,]  1.665594042436961e-93
    ## [52,]  1.170676203023599e-95
    ## [53,]  2.027952403117720e-93
    ## [54,]  7.404297007432487e-75
    ## [55,]  5.593583346185940e-90
    ## [56,]  1.783701779950406e-74
    ## [57,]  2.962620367615563e-78
    ## [58,]  1.951925986293898e-89
    ## [59,]  1.136513704044062e-94
    ## [60,]  7.188225912532558e-74
    ## [61,]  5.773537903615037e-75
    ## [62,]  4.057977669713413e-77
    ## [63,]  2.203461103597624e-88
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
    ## [1] 9.148229225703652e-95 1.508405876987012e-73 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 5.01504133432507e-75 1.00000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 1.978156689478102e-93 1.523824977164988e-73 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 1.606097757844791e-73 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 4.839575113105332e-90 3.993367215529690e-74 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 1.13197551380494e-74 1.00000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 1.653579247804287e-73 1.000000000000000e+00
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
    ##  [1,] 2.214279623666369e-129
    ##  [2,] 4.825073404411426e-129
    ##  [3,] 2.208203878785376e-111
    ##  [4,] 7.962156163445298e-112
    ##  [5,] 1.735010679563569e-111
    ##  [6,]  7.940308864199677e-94
    ##  [7,] 7.962156163445298e-112
    ##  [8,] 1.735010679563569e-111
    ##  [9,]  7.940308864199677e-94
    ## [10,] 8.252473975223791e-128
    ## [11,] 2.967443037600762e-110
    ## [12,] 1.080690956197910e-109
    ## [13,] 2.354902757269967e-109
    ## [14,]  3.885972695455407e-92
    ## [15,]  3.885972695455407e-92
    ## [16,] 5.604589607710729e-112
    ## [17,]  2.015310858288382e-94
    ## [18,]  2.009781062277024e-76
    ## [19,]  2.015310858288382e-94
    ## [20,]  2.009781062277024e-76
    ## [21,] 3.661940074084448e-126
    ## [22,] 3.651892104793644e-108
    ## [23,] 1.316768596856814e-108
    ## [24,] 1.364780890237028e-124
    ## [25,]  3.332888725898105e-91
    ## [26,] 9.282413181486626e-109
    ## [27,]  9.256943239132246e-91
    ## [28,]  3.337790879466429e-91
    ## [29,]  3.337790879466429e-91
    ## [30,] 1.010210660633312e-111
    ## [31,] 2.201321160786294e-111
    ## [32,]  1.007438751347542e-93
    ## [33,]  3.632538073317596e-94
    ## [34,]  3.622570779951252e-76
    ## [35,]  3.632538073317596e-94
    ## [36,]  7.915559832978902e-94
    ## [37,]  3.622570779951252e-76
    ## [38,] 3.764988440152921e-110
    ## [39,]  1.353822958657215e-92
    ## [40,]  4.930386899345054e-92
    ## [41,]  1.772879541464088e-74
    ## [42,]  2.556956271317325e-94
    ## [43,]  9.194360512435839e-77
    ## [44,] 1.670670163741536e-108
    ## [45,]  6.007433116912926e-91
    ## [46,]  4.234872891443627e-91
    ## [47,]  1.522785059918648e-73
    ## [48,] 5.901694828187857e-112
    ## [49,] 1.286021442463179e-111
    ## [50,]  5.885501213001093e-94
    ## [51,]  2.122144617544894e-94
    ## [52,]  2.122144617544894e-94
    ## [53,]  4.624304647430354e-94
    ## [54,]  2.116321681200676e-76
    ## [55,]  2.880353573638616e-92
    ## [56,]  5.371385593052405e-77
    ## [57,]  5.371385593052405e-77
    ## [58,]  2.474031250650056e-91
    ## [59,]  2.692503226565385e-94
    ## [60,]  2.685115287607186e-76
    ## [61,]  9.681763283806504e-77
    ## [62,]  9.681763283806504e-77
    ## [63,]  4.452818586947707e-91
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
    ## [10,] 1.978057058433496e-04
    ## [11,] 1.992058401535678e-04
    ## [12,] 8.173789497658884e-05
    ## [13,] 1.028191342425847e-06
    ## [14,] 5.785678967843724e-07
    ## [15,] 8.231646287337325e-05
    ## [16,] 4.746446532784043e-05
    ## [17,] 4.780043453630354e-05
    ## [18,] 7.536878402088349e-08
    ## [19,] 2.877915817254423e-01
    ## [20,] 4.537720582774151e-04
    ## [21,] 2.437197660118470e-04
    ## [22,] 3.842823309946346e-07
    ## [23,] 2.454448952492300e-04
    ## [24,] 1.687278888621297e-07
    ## [25,] 2.454856689284907e-04
    ## [26,] 2.011914846943478e-04
    ## [27,] 3.172263537741015e-07
    ## [28,] 1.424099974483977e-06
    ## [29,] 2.026155846688319e-04
    ## [30,] 3.760532236689203e-02
    ## [31,] 4.730421170969218e-04
    ## [32,] 5.929375845638836e-05
    ## [33,] 2.661829286886174e-04
    ## [34,] 4.197008637472115e-07
    ## [35,] 3.787150529558064e-02
    ## [36,] 4.763904658996110e-04
    ## [37,] 5.971345932013548e-05
    ## [38,] 2.603427188846506e-05
    ## [39,] 2.621855108889145e-05
    ## [40,] 1.075796359027457e-05
    ## [41,] 1.083411202020283e-05
    ## [42,] 6.247053340130767e-06
    ## [43,] 3.787779656763368e-02
    ## [44,] 3.207726807421036e-05
    ## [45,] 3.230432160341607e-05
    ## [46,] 2.647989243710037e-05
    ## [47,] 2.666732588738433e-05
    ## [48,] 3.447882370093512e-03
    ## [49,] 4.337134940468225e-05
    ## [50,] 5.436408773305789e-06
    ## [51,] 2.440525354606058e-05
    ## [52,] 3.472287623639570e-03
    ## [53,] 4.367834618277343e-05
    ## [54,] 5.474889475444408e-06
    ## [55,] 9.863548738960371e-07
    ## [56,] 5.768217005433711e-07
    ## [57,] 3.472864445340112e-03
    ## [58,] 2.427835969735807e-06
    ## [59,] 4.537943265071782e-04
    ## [60,] 7.155149721169606e-07
    ## [61,] 3.212106564955436e-06
    ## [62,] 4.570064330721336e-04
    ## [63,] 3.870856928151778e-07
    ## [64,] 1.694818367219352e-19
    ## [65,] 2.411323787194455e-17
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
    ## 1  -294.98581163139488 2.214279623666369e-129 2.857213509222646e-01
    ## 43 -289.83119636297869 4.825073404411426e-129 3.594125092756943e-03
    ## 51 -247.08963079631360 2.208203878785376e-111 4.505078457280588e-04
    ## 19 -249.61137523936762 7.962156163445298e-112 2.022430368641518e-03
    ## 47 -244.45675997095140 1.735010679563569e-111 2.544040798080149e-05
    ## 57 -201.71519440428631  7.940308864199677e-94 3.188843765335484e-06
    ## 25 -254.56914573423853 7.962156163445298e-112 2.877437812909061e-01
    ## 48 -249.41453046582231 1.735010679563569e-111 3.619565500737745e-03
    ## 60 -206.67296489915722  7.940308864199677e-94 4.536966894933943e-04
    ## 13 -284.09215357939718 8.252473975223791e-128 1.978057058433496e-04
    ## 39 -243.67548768224080 2.967443037600762e-110 1.992058401535678e-04
    ## 16 -241.49218169269406 1.080690956197910e-109 8.173789497658884e-05
    ## 46 -236.33756642427784 2.354902757269967e-109 1.028191342425847e-06
    ## 24 -196.11774530066677  3.885972695455407e-92 5.785678967843724e-07
    ## 41 -201.07551579553768  3.885972695455407e-92 8.231646287337325e-05
    ## 11 -246.21041535520274 5.604589607710729e-112 4.746446532784043e-05
    ## 33 -205.79374945804642  2.015310858288382e-94 4.780043453630354e-05
    ## 63 -157.89756862296514  2.009781062277024e-76 7.536878402088349e-08
    ## 35 -214.49670655044750  2.015310858288382e-94 2.877915817254423e-01
    ## 64 -166.60052571536622  2.009781062277024e-76 4.537720582774151e-04
    ## 5  -280.50823714273611 3.661940074084448e-126 2.437197660118470e-04
    ## 55 -232.61205630765483 3.651892104793644e-108 3.842823309946346e-07
    ## 29 -240.09157124557976 1.316768596856814e-108 2.454448952492300e-04
    ## 15 -269.61457909073835 1.364780890237028e-124 1.687278888621297e-07
    ## 38 -200.01913206178870  3.332888725898105e-91 2.454856689284907e-04
    ## 8  -240.24240013902221 9.282413181486626e-109 2.011914846943478e-04
    ## 56 -192.34621930394093  9.256943239132246e-91 3.172263537741015e-07
    ## 23 -194.86796374699492  3.337790879466429e-91 1.424099974483977e-06
    ## 31 -199.82573424186583  3.337790879466429e-91 2.026155846688319e-04
    ## 3  -252.29617675205725 1.010210660633312e-111 3.760532236689203e-02
    ## 45 -247.14156148364106 2.201321160786294e-111 4.730421170969218e-04
    ## 53 -204.39999591697597  1.007438751347542e-93 5.929375845638836e-05
    ## 21 -206.92174036002999  3.632538073317596e-94 2.661829286886174e-04
    ## 58 -159.02555952494870  3.622570779951252e-76 4.197008637472115e-07
    ## 27 -211.87951085490090  3.632538073317596e-94 3.787150529558064e-02
    ## 50 -206.72489558648468  7.915559832978902e-94 4.763904658996110e-04
    ## 62 -163.98333001981962  3.622570779951252e-76 5.971345932013548e-05
    ## 14 -241.40251870005952 3.764988440152921e-110 2.603427188846506e-05
    ## 40 -200.98585280290314  1.353822958657215e-92 2.621855108889145e-05
    ## 18 -198.80254681335640  4.930386899345054e-92 1.075796359027457e-05
    ## 42 -158.38588091620008  1.772879541464088e-74 1.083411202020283e-05
    ## 12 -203.52078047586517  2.556956271317325e-94 6.247053340130767e-06
    ## 37 -171.80707167110987  9.194360512435839e-77 3.787779656763368e-02
    ## 6  -237.81860226339850 1.670670163741536e-108 3.207726807421036e-05
    ## 30 -197.40193636624213  6.007433116912926e-91 3.230432160341607e-05
    ## 10 -197.55276525968458  4.234872891443627e-91 2.647989243710037e-05
    ## 32 -157.13609936252826  1.522785059918648e-73 2.666732588738433e-05
    ## 2  -250.44429580449278 5.901694828187857e-112 3.447882370093512e-03
    ## 44 -245.28968053607656 1.286021442463179e-111 4.337134940468225e-05
    ## 52 -202.54811496941147  5.885501213001093e-94 5.436408773305789e-06
    ## 20 -205.06985941246549  2.122144617544894e-94 2.440525354606058e-05
    ## 26 -210.02762990733640  2.122144617544894e-94 3.472287623639570e-03
    ## 49 -204.87301463892021  4.624304647430354e-94 4.367834618277343e-05
    ## 61 -162.13144907225512  2.116321681200676e-76 5.474889475444408e-06
    ## 17 -196.95066586579193  2.880353573638616e-92 9.863548738960371e-07
    ## 34 -161.25223363114432  5.371385593052405e-77 5.768217005433711e-07
    ## 36 -169.95519072354540  5.371385593052405e-77 3.472864445340112e-03
    ## 9  -195.70088431212008  2.474031250650056e-91 2.427835969735807e-06
    ## 4  -207.75466092515515  2.692503226565385e-94 4.537943265071782e-04
    ## 54 -159.85848009007387  2.685115287607186e-76 7.155149721169606e-07
    ## 22 -162.38022453312786  9.681763283806504e-77 3.212106564955436e-06
    ## 28 -167.33799502799877  9.681763283806504e-77 4.570064330721336e-04
    ## 7  -193.27708643649638  4.452818586947707e-91 3.870856928151778e-07
    ## 59   42.52839400921902  5.000000000000000e-01 1.694818367219352e-19
    ## 65   37.57062351434811  5.000000000000000e-01 2.411323787194455e-17
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
    ## 2              Within-State      26      26      26      23
    ## 3              Across-State      24      24      24      20
    ## 4   Match Rate          All 27.473% 27.473% 27.473% 23.626%
    ## 5              Within-State 14.286% 14.286% 14.286% 12.637%
    ## 6              Across-State 13.187% 13.187% 13.187% 10.989%
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

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

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

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

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
```

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

``` r
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
```

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

    ## Warning in log(x): NaNs produced

``` r
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
