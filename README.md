fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.org/kosukeimai/fastLink.svg?branch=master)](https://travis-ci.org/kosukeimai/fastLink) [![CRAN Version](http://www.r-pkg.org/badges/version/fastLink)](https://CRAN.R-project.org/package=fastLink)
==================================================================================================================================================================================================================================================================================

Authors: [Ted Enamorado](https://www.tedenamorado.com/), [Ben Fifield](https://www.benfifield.com/), [Kosuke Imai](https://imai.princeton.edu/)

For a detailed description of the method see: [Using a Probabilistic Model to Assist Merging of Large-scale Administrative Records](http://imai.princeton.edu/research/files/linkage.pdf)

Applications of the method:

[Validating Self-reported Turnout by Linking Public Opinion Surveys with Administrative Records](http://imai.princeton.edu/research/files/turnout.pdf)

Technical reports:

[User’s Guide and Codebook for the ANES 2016 Time Series Voter Validation Supplemental Data](http://www.electionstudies.org/studypages/anes_timeseries_2016/anes_timeseries_2016voteval_userguidecodebook.pdf)

Data:

[ANES 2016 Time Series Voter Validation Supplemental Data](http://www.electionstudies.org/studypages/download/datacenter_all_NoData.php)

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
    ##  [1,] 1.445212110721072e-138
    ##  [2,] 4.524104002859878e-135
    ##  [3,] 1.090503887771604e-115
    ##  [4,] 5.030999677677237e-118
    ##  [5,] 1.574908320468621e-114
    ##  [6,]  3.796207260640144e-95
    ##  [7,] 3.536078690254572e-120
    ##  [8,] 1.106937012105885e-116
    ##  [9,]  2.668194883354972e-97
    ## [10,] 8.203582373642737e-134
    ## [11,] 2.007214899459360e-115
    ## [12,] 1.295588854399717e-114
    ## [13,] 4.055722117721487e-111
    ## [14,]  4.510138726719416e-94
    ## [15,]  3.169987370980531e-96
    ## [16,] 1.769988455034806e-116
    ## [17,]  4.330726549698002e-98
    ## [18,]  3.267806922102886e-75
    ## [19,] 7.193073879797254e-102
    ## [20,]  5.427628908419087e-79
    ## [21,] 2.010524344272864e-133
    ## [22,] 1.517067700737047e-110
    ## [23,] 4.919258728377095e-115
    ## [24,] 1.141251304919270e-128
    ## [25,]  1.000673191028662e-96
    ## [26,] 5.002967940241145e-115
    ## [27,]  3.775055542889901e-92
    ## [28,]  1.741608024736457e-94
    ## [29,]  1.224103243411470e-96
    ## [30,] 2.313488684783260e-119
    ## [31,] 7.242164206731468e-116
    ## [32,]  1.745673445687303e-96
    ## [33,]  8.053600396170656e-99
    ## [34,]  6.076950557936172e-76
    ## [35,] 5.660537977587809e-101
    ## [36,]  1.771979513095010e-97
    ## [37,]  4.271233700330743e-78
    ## [38,] 1.313225571202797e-114
    ## [39,]  3.213140080531451e-96
    ## [40,]  2.073972486495010e-95
    ## [41,]  5.074500731944464e-77
    ## [42,]  2.833389114679310e-97
    ## [43,]  1.151463851310907e-82
    ## [44,] 3.218437824075225e-114
    ## [45,]  7.874726015091865e-96
    ## [46,]  8.008727323981146e-96
    ## [47,]  1.959538659848260e-77
    ## [48,] 3.535897426669934e-118
    ## [49,] 1.106880269202698e-114
    ## [50,]  2.668058108522895e-95
    ## [51,]  1.230898819758716e-97
    ## [52,] 8.651471606568870e-100
    ## [53,]  2.708263862138352e-96
    ## [54,]  6.528082176948575e-77
    ## [55,]  3.169824873670901e-94
    ## [56,]  1.059567986532308e-77
    ## [57,]  1.759878099051622e-81
    ## [58,]  1.224040494428435e-94
    ## [59,]  5.660247811702184e-99
    ## [60,]  4.271014751828979e-76
    ## [61,]  1.970416986198576e-78
    ## [62,]  1.384923466945852e-80
    ## [63,]  7.874322347303171e-94
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
    ## [1] 8.251694945229049e-98 5.751919690494971e-78 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 2.97977773383417e-77 1.00000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 6.426280161063139e-98 1.189071257529550e-76 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 5.634020147024785e-77 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 1.671362528023856e-95 1.196003798003038e-76 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 7.213966084026865e-77 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 8.944192870324217e-77 1.000000000000000e+00
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
    ##  [1,] 2.155741988705094e-135
    ##  [2,] 8.488838329254409e-134
    ##  [3,] 2.564791529444481e-115
    ##  [4,] 5.311905756525997e-117
    ##  [5,] 2.091711782933297e-115
    ##  [6,]  6.319833709658754e-97
    ##  [7,] 5.311905756525997e-117
    ##  [8,] 2.091711782933297e-115
    ##  [9,]  6.319833709658754e-97
    ## [10,] 8.471588496792964e-134
    ## [11,] 2.087461298189243e-115
    ## [12,] 5.528574241178177e-115
    ## [13,] 2.177031071924912e-113
    ## [14,]  1.362281084237542e-96
    ## [15,]  1.362281084237542e-96
    ## [16,] 4.385928226631884e-117
    ## [17,]  1.080724758195675e-98
    ## [18,]  1.285791026942970e-78
    ## [19,]  1.080724758195675e-98
    ## [20,]  1.285791026942970e-78
    ## [21,] 2.558129831958324e-133
    ## [22,] 3.043531999006537e-113
    ## [23,] 6.303418800355899e-115
    ## [24,] 1.005288358777045e-131
    ## [25,]  1.282451359467631e-96
    ## [26,] 5.254843775156831e-115
    ## [27,]  6.251944283542012e-95
    ## [28,]  1.294831897562437e-96
    ## [29,]  1.294831897562437e-96
    ## [30,] 4.541916956522859e-117
    ## [31,] 1.788507110351424e-115
    ## [32,]  5.403740428383590e-97
    ## [33,]  1.119161520878893e-98
    ## [34,]  1.331521120741587e-78
    ## [35,]  1.119161520878893e-98
    ## [36,]  4.407012186449118e-97
    ## [37,]  1.331521120741587e-78
    ## [38,] 1.784872755824569e-115
    ## [39,]  4.398056871372635e-97
    ## [40,]  1.164811244711427e-96
    ## [41,]  2.870180006915138e-78
    ## [42,]  9.240679954746069e-99
    ## [43,]  2.276971052334267e-80
    ## [44,] 5.389704946897494e-115
    ## [45,]  1.328062675561550e-96
    ## [46,]  1.107139173950953e-96
    ## [47,]  2.728071811097440e-78
    ## [48,] 6.364650970966180e-117
    ## [49,] 2.506259719286617e-115
    ## [50,]  7.572336106887100e-97
    ## [51,]  1.568296498750391e-98
    ## [52,]  1.568296498750391e-98
    ## [53,]  6.175607053154010e-97
    ## [54,]  1.865878939468291e-78
    ## [55,]  1.632266087339590e-96
    ## [56,]  3.190750988586077e-80
    ## [57,]  3.190750988586077e-80
    ## [58,]  1.551449417929524e-96
    ## [59,]  1.340963636596621e-98
    ## [60,]  1.595409930527860e-78
    ## [61,]  3.304232370038077e-80
    ## [62,]  3.304232370038077e-80
    ## [63,]  1.591266070022406e-96
    ## [64,]  5.000000000000000e-01
    ## [65,]  5.000000000000000e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.857213509222646e-01
    ##  [2,] 3.594125092756945e-03
    ##  [3,] 4.505078457280588e-04
    ##  [4,] 2.022430368641518e-03
    ##  [5,] 2.544040798080149e-05
    ##  [6,] 3.188843765335484e-06
    ##  [7,] 2.877437812909061e-01
    ##  [8,] 3.619565500737748e-03
    ##  [9,] 4.536966894933943e-04
    ## [10,] 1.978057058433517e-04
    ## [11,] 1.992058401535699e-04
    ## [12,] 8.173789497658884e-05
    ## [13,] 1.028191342425847e-06
    ## [14,] 5.785678967843724e-07
    ## [15,] 8.231646287337325e-05
    ## [16,] 4.746446532784254e-05
    ## [17,] 4.780043453630565e-05
    ## [18,] 7.536878402088684e-08
    ## [19,] 2.877915817254423e-01
    ## [20,] 4.537720582774151e-04
    ## [21,] 2.437197660118470e-04
    ## [22,] 3.842823309946346e-07
    ## [23,] 2.454448952492300e-04
    ## [24,] 1.687278888621315e-07
    ## [25,] 2.454856689284907e-04
    ## [26,] 2.011914846943500e-04
    ## [27,] 3.172263537741049e-07
    ## [28,] 1.424099974483992e-06
    ## [29,] 2.026155846688340e-04
    ## [30,] 3.760532236689203e-02
    ## [31,] 4.730421170969222e-04
    ## [32,] 5.929375845638836e-05
    ## [33,] 2.661829286886174e-04
    ## [34,] 4.197008637472115e-07
    ## [35,] 3.787150529558064e-02
    ## [36,] 4.763904658996115e-04
    ## [37,] 5.971345932013548e-05
    ## [38,] 2.603427188846534e-05
    ## [39,] 2.621855108889173e-05
    ## [40,] 1.075796359027457e-05
    ## [41,] 1.083411202020283e-05
    ## [42,] 6.247053340131044e-06
    ## [43,] 3.787779656763368e-02
    ## [44,] 3.207726807421036e-05
    ## [45,] 3.230432160341607e-05
    ## [46,] 2.647989243710065e-05
    ## [47,] 2.666732588738462e-05
    ## [48,] 3.447882370093515e-03
    ## [49,] 4.337134940468233e-05
    ## [50,] 5.436408773305798e-06
    ## [51,] 2.440525354606058e-05
    ## [52,] 3.472287623639574e-03
    ## [53,] 4.367834618277351e-05
    ## [54,] 5.474889475444408e-06
    ## [55,] 9.863548738960371e-07
    ## [56,] 5.768217005433967e-07
    ## [57,] 3.472864445340116e-03
    ## [58,] 2.427835969735833e-06
    ## [59,] 4.537943265071785e-04
    ## [60,] 7.155149721169606e-07
    ## [61,] 3.212106564955442e-06
    ## [62,] 4.570064330721340e-04
    ## [63,] 3.870856928151778e-07
    ## [64,] 1.694818367219448e-19
    ## [65,] 2.411323787194592e-17
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
    ## 1  -308.82811433902447 2.155741988705094e-135 2.857213509222646e-01
    ## 43 -300.77919561313303 8.488838329254409e-134 3.594125092756945e-03
    ## 51 -256.15027342859895 2.564791529444481e-115 4.505078457280588e-04
    ## 19 -261.52904987191994 5.311905756525997e-117 2.022430368641518e-03
    ## 47 -253.48013114602853 2.091711782933297e-115 2.544040798080149e-05
    ## 57 -208.85120896149442  6.319833709658754e-97 3.188843765335484e-06
    ## 25 -266.48682036679088 5.311905756525997e-117 2.877437812909061e-01
    ## 48 -258.43790164089944 2.091711782933297e-115 3.619565500737748e-03
    ## 60 -213.80897945636534  6.319833709658754e-97 4.536966894933943e-04
    ## 13 -297.88145913356391 8.471588496792964e-134 1.978057058433517e-04
    ## 39 -255.54016516133029 2.087461298189243e-115 1.992058401535699e-04
    ## 16 -253.67536290176295 5.528574241178177e-115 8.173789497658884e-05
    ## 46 -245.62644417587151 2.177031071924912e-113 1.028191342425847e-06
    ## 24 -206.37629843465842  1.362281084237542e-96 5.785678967843724e-07
    ## 41 -211.33406892952934  1.362281084237542e-96 8.231646287337325e-05
    ## 11 -257.96852536938843 4.385928226631884e-117 4.746446532784254e-05
    ## 33 -215.62723139715484  1.080724758195675e-98 4.780043453630565e-05
    ## 63 -162.94939048672933  1.285791026942970e-78 7.536878402088684e-08
    ## 35 -224.33018848955589  1.080724758195675e-98 2.877915817254423e-01
    ## 64 -171.65234757913035  1.285791026942970e-78 4.537720582774151e-04
    ## 5  -296.98504941842418 2.558129831958324e-133 2.437197660118470e-04
    ## 55 -244.30720850799861 3.043531999006537e-113 3.842823309946346e-07
    ## 29 -254.64375544619057 6.303418800355899e-115 2.454448952492300e-04
    ## 15 -286.03839421296357 1.005288358777045e-131 1.687278888621315e-07
    ## 38 -212.48712356895555  1.282451359467631e-96 2.454856689284907e-04
    ## 8  -254.62688197600107 5.254843775156831e-115 2.011914846943500e-04
    ## 56 -201.94904106557556  6.251944283542012e-95 3.172263537741049e-07
    ## 23 -207.32781750889657  1.294831897562437e-96 1.424099974483992e-06
    ## 31 -212.28558800376749  1.294831897562437e-96 2.026155846688340e-04
    ## 3  -264.60849703395462 4.541916956522859e-117 3.760532236689203e-02
    ## 45 -256.55957830806318 1.788507110351424e-115 4.730421170969222e-04
    ## 53 -211.93065612352910  5.403740428383590e-97 5.929375845638836e-05
    ## 21 -217.30943256685009  1.119161520878893e-98 2.661829286886174e-04
    ## 58 -164.63159165642458  1.331521120741587e-78 4.197008637472115e-07
    ## 27 -222.26720306172101  1.119161520878893e-98 3.787150529558064e-02
    ## 50 -214.21828433582957  4.407012186449118e-97 4.763904658996115e-04
    ## 62 -169.58936215129549  1.331521120741587e-78 5.971345932013548e-05
    ## 14 -253.66184182849403 1.784872755824569e-115 2.603427188846534e-05
    ## 40 -211.32054785626042  4.398056871372635e-97 2.621855108889173e-05
    ## 18 -209.45574559669308  1.164811244711427e-96 1.075796359027457e-05
    ## 42 -167.11445162445949  2.870180006915138e-78 1.083411202020283e-05
    ## 12 -213.74890806431858  9.240679954746069e-99 6.247053340131044e-06
    ## 37 -180.11057118448602  2.276971052334267e-80 3.787779656763368e-02
    ## 6  -252.76543211335431 5.389704946897494e-115 3.207726807421036e-05
    ## 30 -210.42413814112072  1.328062675561550e-96 3.230432160341607e-05
    ## 10 -210.40726467093123  1.107139173950953e-96 2.647989243710065e-05
    ## 32 -168.06597069869761  2.728071811097440e-78 2.666732588738462e-05
    ## 2  -261.88170144330184 6.364650970966180e-117 3.447882370093515e-03
    ## 44 -253.83278271741042 2.506259719286617e-115 4.337134940468233e-05
    ## 52 -209.20386053287635  7.572336106887100e-97 5.436408773305798e-06
    ## 20 -214.58263697619734  1.568296498750391e-98 2.440525354606058e-05
    ## 26 -219.54040747106825  1.568296498750391e-98 3.472287623639574e-03
    ## 49 -211.49148874517684  6.175607053154010e-97 4.367834618277351e-05
    ## 61 -166.86256656064273  1.865878939468291e-78 5.474889475444408e-06
    ## 17 -206.72895000604032  1.632266087339590e-96 9.863548738960371e-07
    ## 34 -168.68081850143224  3.190750988586077e-80 5.768217005433967e-07
    ## 36 -177.38377559383326  3.190750988586077e-80 3.472864445340116e-03
    ## 9  -207.68046908027847  1.551449417929524e-96 2.427835969735833e-06
    ## 4  -217.66208413823202  1.340963636596621e-98 4.537943265071785e-04
    ## 54 -164.98424322780650  1.595409930527860e-78 7.155149721169606e-07
    ## 22 -170.36301967112749  3.304232370038077e-80 3.212106564955442e-06
    ## 28 -175.32079016599840  3.304232370038077e-80 4.570064330721340e-04
    ## 7  -205.81901921763173  1.591266070022406e-96 3.870856928151778e-07
    ## 59   42.52839400921896  5.000000000000000e-01 1.694818367219448e-19
    ## 65   37.57062351434805  5.000000000000000e-01 2.411323787194592e-17
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


Fiding Duplicates within a Dataset via `fastLink`
--------------------------------------------------

The following lines of code represent an example on how to find duplicates withing a dataset via `fastLink`. 

As a first step, we will load a dataset that has 500 observations and among them 50 are duplicates.
``` r
library('fastLink')
data("RLdata500", package = "RecordLinkage")
```

To keep track of observations, we will create two ids:

- `id`: we create an id to keep track of each observation in `RLdata500`. 

- `true_id`: is the true id that identifies the 450 unique observations in `RLdata500`

``` r
## In this example we know the thruth. How well do we do? This ID will tell us.
RLdata500$true_id <- identity.RLdata500 

## We create an ID for each observation (rownumber)
RLdata500$id <- 1:nrow(RLdata500)
```

As before, we use `fastLink` (the wrapper function) to do the merge. Please not that we will set the option `dedupe.matches = FALSE` as we do not want a one-to-one match. If we were to impose a one-to-one match, we will end up with every observation being matched against itself and no duplicates would be found.

```
## Using fastLink for fiding duplicates within a datasetL
rl_matches <- fastLink(
  dfA                = RLdata500,  
  dfB                = RLdata500,
  varnames           = c("fname_c1", "lname_c1", "by", "bm", "bd"),
  stringdist.match   = c("fname_c1", "lname_c1"),
  dedupe.matches = FALSE, 
  return.all = FALSE
)
```

Let's extract the ids of the observations we have matched:
```r
id1 <- RLdata500$id[rl_matches$matches$inds.a]
id2 <- RLdata500$id[rl_matches$matches$inds.b]
```

We can also check how well we did in terms of the thruth:
```r
trueID1 <- RLdata500$true_id[rl_matches$matches$inds.a]
trueID2 <- RLdata500$true_id[rl_matches$matches$inds.b]

sum(trueID1 == trueID2)
## 598
```
We were able to match 598 out of the 600 possible matches. There are 600 possible matches because we have 500 observations + 50 * 2 duplicates. We multiply the duplicates times 2, because if observation `i` in dataset A is a duplicate of observation `j` in dataset B, we also have that observation `j` in dataset A is a duplicate of observation `i` in dataset B. 

Imagine that your goal is to construct an ID to uniquely identify observations in your dataset i.e., if observations `i` and `j` in dataset A are duplicates, then they should have the same ID.

```r
## Getting a UNIQUE ID
## Because in this exercise we have a symmetrical problem e.g.,
## if observation 1 in A matches 2 in B, observation 1 in B matches 2 in A,
## we will remove pairs on the lower diagonal of the sample space
keep <- id1 > id2

## link between original ID and the duplicated ID
id.duplicated <- id1[keep]
id.original <- id2[keep]

## We create a new id and replace the ID for the duplicates
RLdata500$id_new <- RLdata500$id
RLdata500$id_new[RLdata500$id_new %in% id.original] <- id.duplicated
```
