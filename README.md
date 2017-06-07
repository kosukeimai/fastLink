fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.com/kosukeimai/fastLink.svg?token=JxpGcfuMTdnnLSenfvSD&branch=master)](https://travis-ci.com/kosukeimai/fastLink)
================================================================================================================================================================================================

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
    ##  [1,] 2.265689914190897e-133
    ##  [2,] 6.886298384652935e-131
    ##  [3,] 2.242176255533292e-112
    ##  [4,] 1.084486250224272e-113
    ##  [5,] 3.296168582612452e-111
    ##  [6,]  1.073231294571635e-92
    ##  [7,] 7.622399055812778e-116
    ##  [8,] 2.316738666507610e-113
    ##  [9,]  7.543292692479568e-95
    ## [10,] 1.229796296191092e-128
    ## [11,] 4.137370285410978e-111
    ## [12,] 8.312817987620266e-110
    ## [13,] 2.526583391730493e-107
    ## [14,]  3.978980862176186e-90
    ## [15,]  2.796658782965287e-92
    ## [16,] 3.954539858576797e-112
    ## [17,]  1.330415106471150e-94
    ## [18,]  1.316607865466632e-73
    ## [19,]  2.209738722088584e-98
    ## [20,]  2.186805733020369e-77
    ## [21,] 6.955576537835112e-127
    ## [22,] 6.883390555342783e-106
    ## [23,] 2.340045727464861e-109
    ## [24,] 3.775424964610830e-122
    ## [25,]  6.783808637641159e-92
    ## [26,] 2.446009778586403e-109
    ## [27,]  2.420624734213282e-88
    ## [28,]  1.170797449455165e-89
    ## [29,]  8.229044279196036e-92
    ## [30,] 7.012998282482714e-115
    ## [31,] 2.131518458980329e-112
    ## [32,]  6.940216368792931e-94
    ## [33,]  3.356814258898590e-95
    ## [34,]  3.321976753480488e-74
    ## [35,]  2.359363969093694e-97
    ## [36,]  7.171009672336122e-95
    ## [37,]  2.334878147502974e-76
    ## [38,] 3.806592975928665e-110
    ## [39,]  1.280641738476516e-92
    ## [40,]  2.573069593708699e-91
    ## [41,]  8.656508165031972e-74
    ## [42,]  1.224050169553390e-93
    ## [43,]  6.839812352819897e-80
    ## [44,] 2.152962151086461e-108
    ## [45,]  7.243152103407796e-91
    ## [46,]  7.571143018609953e-91
    ## [47,]  2.547139087083917e-73
    ## [48,] 5.574773507151971e-114
    ## [49,] 1.694386930738263e-111
    ## [50,]  5.516917698852402e-93
    ## [51,]  2.668399227429084e-94
    ## [52,]  1.875505913281997e-96
    ## [53,]  5.700379941732806e-94
    ## [54,]  1.856041640797322e-75
    ## [55,]  2.045384816205463e-90
    ## [56,]  3.273511897023536e-75
    ## [57,]  5.437104525411842e-79
    ## [58,]  6.018453993412995e-90
    ## [59,]  1.725561683706721e-95
    ## [60,]  1.707653554191946e-74
    ## [61,]  8.259505893427005e-76
    ## [62,]  5.805260316626118e-78
    ## [63,]  5.297404683051640e-89
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
    ## [1] 2.287437535920482e-95 3.588534287818767e-74 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 1.191386200599044e-75 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 2.561283476953127e-94 3.555589628039962e-74 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 3.804930578408218e-74 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 1.147755523578792e-90 1.018413213441087e-74 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 2.886072200167151e-75 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 3.941386330791326e-74 1.000000000000000e+00
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
    ##  [1,] 3.379602789911592e-130
    ##  [2,] 1.292116044135405e-129
    ##  [3,] 5.273447194639989e-112
    ##  [4,] 1.145038585671160e-112
    ##  [5,] 4.377800646029406e-112
    ##  [6,]  1.786689410775372e-94
    ##  [7,] 1.145038585671160e-112
    ##  [8,] 4.377800646029406e-112
    ##  [9,]  1.786689410775372e-94
    ## [10,] 1.269973004681962e-128
    ## [11,] 4.302778117778702e-111
    ## [12,] 3.547269740850954e-110
    ## [13,] 1.356219777871981e-109
    ## [14,]  1.201845595341200e-92
    ## [15,]  1.201845595341200e-92
    ## [16,] 9.799119276589166e-113
    ## [17,]  3.320026161293994e-95
    ## [18,]  5.180485321727610e-77
    ## [19,]  3.320026161293994e-95
    ## [20,]  5.180485321727610e-77
    ## [21,] 8.850063363117643e-127
    ## [22,] 1.380941628819001e-108
    ## [23,] 2.998477829008260e-109
    ## [24,] 3.325639804309154e-125
    ## [25,]  8.694051852001183e-92
    ## [26,] 2.569154832193061e-109
    ## [27,]  4.008844584596373e-91
    ## [28,]  8.704518247546595e-92
    ## [29,]  8.704518247546595e-92
    ## [30,] 1.376814852165920e-112
    ## [31,] 5.263945708643433e-112
    ## [32,]  2.148347267722183e-94
    ## [33,]  4.664767515759897e-95
    ## [34,]  7.278785910303555e-77
    ## [35,]  4.664767515759897e-95
    ## [36,]  1.783470225337442e-94
    ## [37,]  7.278785910303555e-77
    ## [38,] 5.173737280355348e-111
    ## [39,]  1.752906831482172e-93
    ## [40,]  1.445120615482184e-92
    ## [41,]  4.896193335546380e-75
    ## [42,]  3.992058770464637e-95
    ## [43,]  1.352543956376726e-77
    ## [44,] 3.605423311083427e-109
    ## [45,]  1.221548526706203e-91
    ## [46,]  1.046646825193821e-91
    ## [47,]  3.546129752273321e-74
    ## [48,] 1.003464844528235e-112
    ## [49,] 3.836524899349538e-112
    ## [50,]  1.565781305747932e-94
    ## [51,]  3.399825475879069e-95
    ## [52,]  3.399825475879069e-95
    ## [53,]  1.299847738839836e-94
    ## [54,]  5.305002165212598e-77
    ## [55,]  1.053248177456893e-92
    ## [56,]  9.857754721109126e-78
    ## [57,]  9.857754721109126e-78
    ## [58,]  7.628282714025517e-92
    ## [59,]  4.088010891981130e-95
    ## [60,]  6.378829380283159e-77
    ## [61,]  1.385053363056516e-77
    ## [62,]  1.385053363056516e-77
    ## [63,]  1.070515018248445e-91
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
    ## [10,] 1.978057058433490e-04
    ## [11,] 1.992058401535673e-04
    ## [12,] 8.173789497658884e-05
    ## [13,] 1.028191342425847e-06
    ## [14,] 5.785678967843724e-07
    ## [15,] 8.231646287337325e-05
    ## [16,] 4.746446532784001e-05
    ## [17,] 4.780043453630311e-05
    ## [18,] 7.536878402088282e-08
    ## [19,] 2.877915817254423e-01
    ## [20,] 4.537720582774151e-04
    ## [21,] 2.437197660118470e-04
    ## [22,] 3.842823309946346e-07
    ## [23,] 2.454448952492300e-04
    ## [24,] 1.687278888621291e-07
    ## [25,] 2.454856689284907e-04
    ## [26,] 2.011914846943475e-04
    ## [27,] 3.172263537741010e-07
    ## [28,] 1.424099974483975e-06
    ## [29,] 2.026155846688315e-04
    ## [30,] 3.760532236689203e-02
    ## [31,] 4.730421170969218e-04
    ## [32,] 5.929375845638836e-05
    ## [33,] 2.661829286886174e-04
    ## [34,] 4.197008637472115e-07
    ## [35,] 3.787150529558064e-02
    ## [36,] 4.763904658996110e-04
    ## [37,] 5.971345932013548e-05
    ## [38,] 2.603427188846501e-05
    ## [39,] 2.621855108889141e-05
    ## [40,] 1.075796359027457e-05
    ## [41,] 1.083411202020283e-05
    ## [42,] 6.247053340130711e-06
    ## [43,] 3.787779656763368e-02
    ## [44,] 3.207726807421036e-05
    ## [45,] 3.230432160341607e-05
    ## [46,] 2.647989243710033e-05
    ## [47,] 2.666732588738429e-05
    ## [48,] 3.447882370093512e-03
    ## [49,] 4.337134940468225e-05
    ## [50,] 5.436408773305789e-06
    ## [51,] 2.440525354606058e-05
    ## [52,] 3.472287623639570e-03
    ## [53,] 4.367834618277343e-05
    ## [54,] 5.474889475444408e-06
    ## [55,] 9.863548738960371e-07
    ## [56,] 5.768217005433660e-07
    ## [57,] 3.472864445340112e-03
    ## [58,] 2.427835969735803e-06
    ## [59,] 4.537943265071782e-04
    ## [60,] 7.155149721169606e-07
    ## [61,] 3.212106564955436e-06
    ## [62,] 4.570064330721336e-04
    ## [63,] 3.870856928151778e-07
    ## [64,] 1.694818367219328e-19
    ## [65,] 2.411323787194438e-17
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
    ## 1  -296.86556566384121 3.379602789911592e-130 2.857213509222646e-01
    ## 43 -291.14874109223410 1.292116044135405e-129 3.594125092756943e-03
    ## 51 -248.52171108452393 5.273447194639989e-112 4.505078457280588e-04
    ## 19 -251.55063674163412 1.145038585671160e-112 2.022430368641518e-03
    ## 47 -245.83381217002702 4.377800646029406e-112 2.544040798080149e-05
    ## 57 -203.20678216231687  1.786689410775372e-94 3.188843765335484e-06
    ## 25 -256.50840723650504 1.145038585671160e-112 2.877437812909061e-01
    ## 48 -250.79158266489793 4.377800646029406e-112 3.619565500737745e-03
    ## 60 -208.16455265718778  1.786689410775372e-94 4.536966894933943e-04
    ## 13 -285.96367096648606 1.269973004681962e-128 1.978057058433490e-04
    ## 39 -245.60651253914989 4.302778117778702e-111 1.992058401535673e-04
    ## 16 -242.60618917600937 3.547269740850954e-110 8.173789497658884e-05
    ## 46 -236.88936460440229 1.356219777871981e-109 1.028191342425847e-06
    ## 24 -197.29126025380225  1.201845595341200e-92 5.785678967843724e-07
    ## 41 -202.24903074867316  1.201845595341200e-92 8.231646287337325e-05
    ## 11 -247.95429377117480 9.799119276589166e-113 4.746446532784001e-05
    ## 33 -207.59713534383860  3.320026161293994e-95 4.780043453630311e-05
    ## 63 -159.25328076452138  5.180485321727610e-77 7.536878402088282e-08
    ## 35 -216.30009243623971  3.320026161293994e-95 2.877915817254423e-01
    ## 64 -167.95623785692246  5.180485321727610e-77 4.537720582774151e-04
    ## 5  -281.92839069892131 8.850063363117643e-127 2.437197660118470e-04
    ## 55 -233.58453611960402 1.380941628819001e-108 3.842823309946346e-07
    ## 29 -241.57123227158510 2.998477829008260e-109 2.454448952492300e-04
    ## 15 -271.02649600156610 3.325639804309154e-125 1.687278888621291e-07
    ## 38 -201.36291747131978  8.694051852001183e-92 2.454856689284907e-04
    ## 8  -241.52694470737168 2.569154832193061e-109 2.011914846943475e-04
    ## 56 -193.18309012805443  4.008844584596373e-91 3.172263537741010e-07
    ## 23 -196.21201578516460  8.704518247546595e-92 1.424099974483975e-06
    ## 31 -201.16978628003551  8.704518247546595e-92 2.026155846688315e-04
    ## 3  -254.28914797572975 1.376814852165920e-112 3.760532236689203e-02
    ## 45 -248.57232340412264 5.263945708643433e-112 4.730421170969218e-04
    ## 53 -205.94529339641250  2.148347267722183e-94 5.929375845638836e-05
    ## 21 -208.97421905352263  4.664767515759897e-95 2.661829286886174e-04
    ## 58 -160.63036447420538  7.278785910303555e-77 4.197008637472115e-07
    ## 27 -213.93198954839355  4.664767515759897e-95 3.787150529558064e-02
    ## 50 -208.21516497678650  1.783470225337442e-94 4.763904658996110e-04
    ## 62 -165.58813496907629  7.278785910303555e-77 5.971345932013548e-05
    ## 14 -243.38725327837460 5.173737280355348e-111 2.603427188846501e-05
    ## 40 -203.03009485103840  1.752906831482172e-93 2.621855108889141e-05
    ## 18 -200.02977148789788  1.445120615482184e-92 1.075796359027457e-05
    ## 42 -159.67261306056173  4.896193335546380e-75 1.083411202020283e-05
    ## 12 -205.37787608306331  3.992058770464637e-95 6.247053340130711e-06
    ## 37 -173.72367474812825  1.352543956376726e-77 3.787779656763368e-02
    ## 6  -239.35197301080981 3.605423311083427e-109 3.207726807421036e-05
    ## 30 -198.99481458347364  1.221548526706203e-91 3.230432160341607e-05
    ## 10 -198.95052701926022  1.046646825193821e-91 2.647989243710033e-05
    ## 32 -158.59336859192405  3.546129752273321e-74 2.666732588738429e-05
    ## 2  -252.21607651738455 1.003464844528235e-112 3.447882370093512e-03
    ## 44 -246.49925194577750 3.836524899349538e-112 4.337134940468225e-05
    ## 52 -203.87222193806730  1.565781305747932e-94 5.436408773305789e-06
    ## 20 -206.90114759517743  3.399825475879069e-95 2.440525354606058e-05
    ## 26 -211.85891809004835  3.399825475879069e-95 3.472287623639570e-03
    ## 49 -206.14209351844130  1.299847738839836e-94 4.367834618277343e-05
    ## 61 -163.51506351073110  5.305002165212598e-77 5.474889475444408e-06
    ## 17 -197.95670002955271  1.053248177456893e-92 9.863548738960371e-07
    ## 34 -162.94764619738197  9.857754721109126e-78 5.768217005433660e-07
    ## 36 -171.65060328978305  9.857754721109126e-78 3.472864445340112e-03
    ## 9  -196.87745556091502  7.628282714025517e-92 2.427835969735803e-06
    ## 4  -209.63965882927306  4.088010891981130e-95 4.537943265071782e-04
    ## 54 -161.29580424995581  6.378829380283159e-77 7.155149721169606e-07
    ## 22 -164.32472990706597  1.385053363056516e-77 3.212106564955436e-06
    ## 28 -169.28250040193689  1.385053363056516e-77 4.570064330721336e-04
    ## 7  -194.70248386435316  1.070515018248445e-91 3.870856928151778e-07
    ## 59   42.52839400921903  5.000000000000000e-01 1.694818367219328e-19
    ## 65   37.57062351434811  5.000000000000000e-01 2.411323787194438e-17
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

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

where each column gives the match rate, false discovery rate (FDR) and false negative rate (FNR) under different cutoffs for matches based on the posterior probability of a match. Other arguments include:

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

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

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

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

If we assume that the first `fastLink` run was for a within-geography match and the second was an across-geography match, the call to `aggregateEM()` would be:

``` r
agg.out <- aggregateEM(em.list = list(link.1, link.2), within.geo = c(TRUE, FALSE))
summary(agg.out)
```

    ##                               95%     85%     75%   Exact
    ## 1 Match Rate          All 27.473% 27.473% 27.473% 23.626%
    ## 2            Within-State 14.286% 14.286% 14.286% 12.637%
    ## 3            Across-State 13.187% 13.187% 13.187% 10.989%
    ## 4        FDR          All      0%      0%      0%        
    ## 5            Within-State      0%      0%      0%        
    ## 6            Across-State      0%      0%      0%        
    ## 7        FNR          All      0%      0%      0%        
    ## 8            Within-State      0%      0%      0%        
    ## 9            Across-State      0%      0%      0%

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

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

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

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

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
