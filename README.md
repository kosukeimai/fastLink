fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.org/kosukeimai/fastLink.svg?branch=master)](https://travis-ci.org/kosukeimai/fastLink) [![CRAN Version](http://www.r-pkg.org/badges/version/fastLink)](https://CRAN.R-project.org/package=fastLink) ![CRAN downloads](http://cranlogs.r-pkg.org/badges/grand-total/fastLink)
===========================================================================================================================================================================================================================================================================================================================================================

Authors:

-   [Ted Enamorado](https://www.tedenamorado.com/)
-   [Ben Fifield](https://www.benfifield.com/)
-   [Kosuke Imai](https://imai.fas.harvard.edu/)

For a detailed description of the method see:

-   [Using a Probabilistic Model to Assist Merging of Large-scale Administrative Records](http://imai.fas.harvard.edu/research/files/linkage.pdf)

Applications of the method:

-   [Validating Self-reported Turnout by Linking Public Opinion Surveys with Administrative Records](http://imai.fas.harvard.edu/research/files/turnout.pdf)

Technical reports:

-   [User’s Guide and Codebook for the ANES 2016 Time Series Voter Validation Supplemental Data](http://www.electionstudies.org/studypages/anes_timeseries_2016/anes_timeseries_2016voteval_userguidecodebook.pdf)

-   [User’s Guide and Codebook for the CCES 2016 Voter Validation Supplemental Data](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/2NNA4L)

Data:

-   [ANES 2016 Time Series Voter Validation Supplemental Data](http://www.electionstudies.org/studypages/download/datacenter_all_NoData.php)

-   [CCES 2016 Voter Validation Supplemental Data](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/2NNA4L)

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
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

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

or using the `getMatches()` function:

``` r
matched_dfs <- getMatches(
  dfA = dfA, dfB = dfB, 
  fl.out = matches.out, threshold.match = 0.85
)
```

We can also examine the EM object:

``` r
matches.out$EM
```

    ## $zeta.j
    ##                         [,1]
    ##  [1,] 1.207656408265713e-128
    ##  [2,] 5.657949732711577e-125
    ##  [3,] 3.432327739420451e-107
    ##  [4,] 9.574801038485382e-110
    ##  [5,] 4.485857285704384e-106
    ##  [6,]  2.721291832584999e-88
    ##  [7,] 6.413128625911300e-112
    ##  [8,] 3.004592957605139e-108
    ##  [9,]  1.822700490679874e-90
    ## [10,] 1.255605123007581e-122
    ## [11,] 6.667755085044734e-106
    ## [12,] 1.149867869578468e-105
    ## [13,] 5.387206626658066e-102
    ## [14,]  9.116629528403746e-87
    ## [15,]  6.106248846887922e-89
    ## [16,] 2.607669940136451e-108
    ## [17,]  1.384774893384904e-91
    ## [18,]  3.935723146821050e-70
    ## [19,]  2.300027027959088e-95
    ## [20,]  6.536997208351493e-74
    ## [21,] 7.774170249207759e-124
    ## [22,] 3.642249913344882e-120
    ## [23,] 2.209527479397395e-102
    ## [24,] 4.128388954562034e-107
    ## [25,] 8.082835420098416e-118
    ## [26,]  1.480619948749537e-90
    ## [27,] 8.042785291321856e-107
    ## [28,]  6.376653858878035e-88
    ## [29,]  4.271034064888132e-90
    ## [30,] 3.400783036678983e-110
    ## [31,] 1.593289228765004e-106
    ## [32,]  9.665499120984980e-89
    ## [33,]  2.696281883521711e-91
    ## [34,]  1.805949017764024e-93
    ## [35,]  8.460989973979834e-90
    ## [36,]  5.132758678068546e-72
    ## [37,] 3.535807514343848e-104
    ## [38,]  1.877652304972575e-87
    ## [39,]  3.238049430715543e-87
    ## [40,]  1.719531097927037e-70
    ## [41,]  7.343247331755186e-90
    ## [42,]  6.476919136146932e-77
    ## [43,] 2.189220884914531e-105
    ## [44,]  1.162562052368025e-88
    ## [45,]  2.264863383258107e-88
    ## [46,]  1.202731182274673e-71
    ## [47,] 7.149418110280873e-110
    ## [48,] 3.349549425585100e-106
    ## [49,]  2.031964218686404e-88
    ## [50,]  5.668355293637622e-91
    ## [51,]  3.796621094197973e-93
    ## [52,]  1.778741963202353e-89
    ## [53,]  1.079052602088962e-71
    ## [54,]  6.807305550591534e-87
    ## [55,]  8.197973060604397e-73
    ## [56,]  1.361633555312417e-76
    ## [57,] 4.602368123224235e-105
    ## [58,]  2.013289513901138e-91
    ## [59,]  5.722049250722945e-70
    ## [60,]  1.596219454186967e-72
    ## [61,]  1.069135602268555e-74
    ## [62,]  1.296035472911578e-86
    ## [63,]  9.999999999999982e-01
    ## [64,]  9.999999999997602e-01
    ## 
    ## $p.m
    ## [1] 0.0002857142857142756
    ## 
    ## $p.u
    ## [1] 0.9997142857142858
    ## 
    ## $p.gamma.k.m
    ## $p.gamma.k.m[[1]]
    ## [1] 1.878726587957007e-90 1.141124681931439e-71 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 3.992127384225308e-71 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 3.755304609945282e-89 5.208122224669178e-71 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 5.45053029192462e-71 1.00000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 2.778376998191891e-88 6.143622388843456e-71 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 8.972132609420587e-72 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 2.685521134957106e-71 1.000000000000000e+00
    ## 
    ## 
    ## $p.gamma.k.u
    ## $p.gamma.k.u[[1]]
    ## [1] 0.986041726207487867 0.011603315232923702 0.002354958559588454
    ## 
    ## $p.gamma.k.u[[2]]
    ## [1] 0.993302076356329500 0.006697923643670463
    ## 
    ## $p.gamma.k.u[[3]]
    ## [1] 0.9990225778793940803 0.0006516147470706017 0.0003258073735352958
    ## 
    ## $p.gamma.k.u[[4]]
    ## [1] 0.999833906071019518 0.000166093928980537
    ## 
    ## $p.gamma.k.u[[5]]
    ## [1] 0.998445270077164881 0.001166047442126322 0.000388682480708784
    ## 
    ## $p.gamma.k.u[[6]]
    ## [1] 0.8836924835667334 0.1163075164332666
    ## 
    ## $p.gamma.k.u[[7]]
    ## [1] 0.98807659331237496 0.01192340668762505
    ## 
    ## 
    ## $p.gamma.j.m
    ##                         [,1]
    ##  [1,] 1.801993307498769e-125
    ##  [2,] 9.934720788926649e-124
    ##  [3,] 1.223169123383511e-106
    ##  [4,] 9.633816962049978e-109
    ##  [5,] 5.311300616451082e-107
    ##  [6,]  6.539306999238446e-90
    ##  [7,] 9.633816962049978e-109
    ##  [8,] 5.311300616451082e-107
    ##  [9,]  6.539306999238446e-90
    ## [10,] 1.222020421603489e-122
    ## [11,] 6.533165809564399e-106
    ## [12,] 5.595557046648413e-106
    ## [13,] 3.084933594682586e-104
    ## [14,]  2.991496814321914e-89
    ## [15,]  2.991496814321914e-89
    ## [16,] 6.463805836497378e-109
    ## [17,]  3.455679998805259e-92
    ## [18,]  2.345669685477147e-73
    ## [19,]  3.455679998805357e-92
    ## [20,]  2.345669685477147e-73
    ## [21,] 1.354739480124911e-123
    ## [22,] 7.468928114642879e-122
    ## [23,] 9.195791657059227e-105
    ## [24,] 7.242708465383512e-107
    ## [25,] 9.187155711265992e-121
    ## [26,]  2.597981971174823e-90
    ## [27,] 4.671829239239061e-107
    ## [28,]  2.497653436418940e-90
    ## [29,]  2.497653436418940e-90
    ## [30,] 6.678752200211899e-108
    ## [31,] 3.682119020721067e-106
    ## [32,]  4.533448287534479e-89
    ## [33,]  3.570594627847915e-91
    ## [34,]  3.570594627847915e-91
    ## [35,]  1.968534540638615e-89
    ## [36,]  2.423672209396145e-72
    ## [37,] 4.529190838570036e-105
    ## [38,]  2.421396091950090e-88
    ## [39,]  2.073888886334824e-88
    ## [40,]  1.108742515715088e-71
    ## [41,]  2.395689111197149e-91
    ## [42,]  1.280783358029497e-74
    ## [43,] 5.021089282599544e-106
    ## [44,]  2.684374847419155e-89
    ## [45,]  1.731526398058188e-89
    ## [46,]  9.257086757444129e-73
    ## [47,] 1.287330993889636e-108
    ## [48,] 7.097292722455542e-107
    ## [49,]  8.738231805566713e-90
    ## [50,]  6.882329203497945e-92
    ## [51,]  6.882329203497945e-92
    ## [52,]  3.794354769781673e-90
    ## [53,]  4.671633653492396e-73
    ## [54,]  3.997425508880797e-89
    ## [55,]  2.468712813146602e-75
    ## [56,]  2.468712813146602e-75
    ## [57,] 9.678160924090567e-107
    ## [58,]  4.771252297143867e-91
    ## [59,]  3.238662688397923e-72
    ## [60,]  2.550806993520197e-74
    ## [61,]  2.550806993520197e-74
    ## [62,]  3.587029890554621e-89
    ## [63,]  5.000000000000000e-01
    ## [64,]  5.000000000000000e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.857221939649586e-01
    ##  [2,] 3.362255975078642e-03
    ##  [3,] 6.823888974051229e-04
    ##  [4,] 1.926649993020625e-03
    ##  [5,] 2.267198904301176e-05
    ##  [6,] 4.601408613655589e-06
    ##  [7,] 2.876488439579793e-01
    ##  [8,] 3.384927964121654e-03
    ##  [9,] 6.869903060187786e-04
    ## [10,] 1.863629504231389e-04
    ## [11,] 1.876196122601122e-04
    ## [12,] 9.318147521156793e-05
    ## [13,] 1.096519550858413e-06
    ## [14,] 6.283309184866356e-07
    ## [15,] 9.380980613005467e-05
    ## [16,] 4.746460537537336e-05
    ## [17,] 4.778466340217972e-05
    ## [18,] 1.141238743808869e-07
    ## [19,] 2.876966286213814e-01
    ## [20,] 6.871044298931594e-04
    ## [21,] 3.336844225881423e-04
    ## [22,] 3.926654867333284e-06
    ## [23,] 7.969368499218280e-07
    ## [24,] 3.359344861254866e-04
    ## [25,] 2.176464230545365e-07
    ## [26,] 3.359902920731962e-04
    ## [27,] 1.112281408627170e-04
    ## [28,] 7.500211791147484e-07
    ## [29,] 1.119781620418319e-04
    ## [30,] 3.760543332427121e-02
    ## [31,] 4.425245765313530e-04
    ## [32,] 8.981286971966362e-05
    ## [33,] 2.535767587611006e-04
    ## [34,] 3.785901008303230e-02
    ## [35,] 4.455085588410718e-04
    ## [36,] 9.041848583375451e-05
    ## [37,] 2.452822935802919e-05
    ## [38,] 2.469362537527819e-05
    ## [39,] 1.226411467901442e-05
    ## [40,] 1.234681268763892e-05
    ## [41,] 6.247071772539155e-06
    ## [42,] 3.786529927936164e-02
    ## [43,] 4.391799996651740e-05
    ## [44,] 4.421414291976428e-05
    ## [45,] 1.463933332217284e-05
    ## [46,] 1.473804763992183e-05
    ## [47,] 3.447892543334091e-03
    ## [48,] 4.057331754450934e-05
    ## [49,] 8.234584644501390e-06
    ## [50,] 2.324944398741802e-05
    ## [51,] 3.471141987321509e-03
    ## [52,] 4.084690700873392e-05
    ## [53,] 8.290111176156823e-06
    ## [54,] 1.124447874001128e-06
    ## [55,] 5.766313856959634e-07
    ## [56,] 3.471718618707204e-03
    ## [57,] 4.026666660026763e-06
    ## [58,] 4.537956654620387e-04
    ## [59,] 1.083797934996405e-06
    ## [60,] 3.059984258004306e-06
    ## [61,] 4.568556497200431e-04
    ## [62,] 5.299712371005844e-07
    ## [63,] 1.541307791353605e-19
    ## [64,] 2.301172532490936e-17
    ## 
    ## $patterns.w
    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 gamma.7 counts
    ## 1        0       0       0       0       0       0       0 100827
    ## 43       1       0       0       0       0       0       0    261
    ## 52       2       0       0       0       0       0       0   1193
    ## 19       0       2       0       0       0       0       0    690
    ## 48       1       2       0       0       0       0       0      1
    ## 57       2       2       0       0       0       0       0      9
    ## 25       0      NA       0       0       0       0       0  48376
    ## 49       1      NA       0       0       0       0       0    101
    ## 59       2      NA       0       0       0       0       0    563
    ## 13       0       0       1       0       0       0       0     37
    ## 39       0      NA       1       0       0       0       0     11
    ## 16       0       0       2       0       0       0       0     64
    ## 47       1       0       2       0       0       0       0      1
    ## 24       0       2       2       0       0       0       0      1
    ## 41       0      NA       2       0       0       0       0     36
    ## 11       0       0       0       2       0       0       0     15
    ## 33       0      NA       0       2       0       0       0      8
    ## 62       2      NA       0       2       0       0       0      1
    ## 35       0      NA       0      NA       0       0       0    322
    ## 63       2      NA       0      NA       0       0       0      4
    ## 5        0       0       0       0       1       0       0    124
    ## 46       1       0       0       0       1       0       0      2
    ## 56       2       0       0       0       1       0       0      4
    ## 29       0      NA       0       0       1       0       0     49
    ## 15       0       0       1       0       1       0       0      1
    ## 38       0      NA       0      NA       1       0       0      1
    ## 9        0       0       0       0       2       0       0     33
    ## 23       0       2       0       0       2       0       0      1
    ## 31       0      NA       0       0       2       0       0     28
    ## 3        0       0       0       0       0       2       0  12998
    ## 45       1       0       0       0       0       2       0     30
    ## 54       2       0       0       0       0       2       0    154
    ## 21       0       2       0       0       0       2       0     75
    ## 27       0      NA       0       0       0       2       0   6689
    ## 51       1      NA       0       0       0       2       0      9
    ## 61       2      NA       0       0       0       2       0     75
    ## 14       0       0       1       0       0       2       0      7
    ## 40       0      NA       1       0       0       2       0      1
    ## 18       0       0       2       0       0       2       0      8
    ## 42       0      NA       2       0       0       2       0      3
    ## 12       0       0       0       2       0       2       0      4
    ## 37       0      NA       0      NA       0       2       0     20
    ## 7        0       0       0       0       1       2       0     13
    ## 30       0      NA       0       0       1       2       0      8
    ## 10       0       0       0       0       2       2       0      2
    ## 32       0      NA       0       0       2       2       0      4
    ## 2        0       0       0       0       0       0       2   1199
    ## 44       1       0       0       0       0       0       2      6
    ## 53       2       0       0       0       0       0       2     19
    ## 20       0       2       0       0       0       0       2     10
    ## 26       0      NA       0       0       0       0       2    592
    ## 50       1      NA       0       0       0       0       2      1
    ## 60       2      NA       0       0       0       0       2      5
    ## 17       0       0       2       0       0       0       2      1
    ## 34       0      NA       0       2       0       0       2      1
    ## 36       0      NA       0      NA       0       0       2      3
    ## 6        0       0       0       0       1       0       2      1
    ## 4        0       0       0       0       0       2       2    149
    ## 55       2       0       0       0       0       2       2      3
    ## 22       0       2       0       0       0       2       2      3
    ## 28       0      NA       0       0       0       2       2     92
    ## 8        0       0       0       0       1       2       2      1
    ## 58       2       2       2       2       2       2       2     43
    ## 64       2      NA       2       2       2       2       2      7
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -285.98150788900506 1.801993307498769e-125 2.857221939649586e-01
    ## 43 -277.52937265027970 9.934720788926649e-124 3.362255975078642e-03
    ## 52 -236.58266389270563 1.223169123383511e-106 6.823888974051229e-04
    ## 19 -242.46452308834290 9.633816962049978e-109 1.926649993020625e-03
    ## 48 -234.01238784961760 5.311300616451082e-107 2.267198904301176e-05
    ## 57 -193.06567909204352  6.539306999238446e-90 4.601408613655589e-06
    ## 25 -247.47048079288805 9.633816962049978e-109 2.876488439579793e-01
    ## 49 -239.01834555416275 5.311300616451082e-107 3.384927964121654e-03
    ## 59 -198.07163679658868  6.539306999238446e-90 6.869903060187786e-04
    ## 13 -272.12706133374735 1.222020421603489e-122 1.863629504231389e-04
    ## 39 -233.61603423763040 6.533165809564399e-106 1.876196122601122e-04
    ## 16 -233.07108533919762 5.595557046648413e-106 9.318147521156793e-05
    ## 47 -224.61895010047232 3.084933594682586e-104 1.096519550858413e-06
    ## 24 -189.55410053853549  2.991496814321914e-89 6.283309184866356e-07
    ## 41 -194.56005824308062  2.991496814321914e-89 9.380980613005467e-05
    ## 11 -239.16003057857583 6.463805836497378e-109 4.746460537537336e-05
    ## 33 -200.64900348245888  3.455679998805259e-92 4.778466340217972e-05
    ## 62 -151.25015948615948  2.345669685477147e-73 1.141238743808869e-07
    ## 35 -209.35196057485996  3.455679998805357e-92 2.876966286213814e-01
    ## 63 -159.95311657856055  2.345669685477147e-73 6.871044298931594e-04
    ## 5  -274.90904241382867 1.354739480124911e-123 3.336844225881423e-04
    ## 46 -266.45690717510342 7.468928114642879e-122 3.926654867333284e-06
    ## 56 -225.51019841752932 9.195791657059227e-105 7.969368499218280e-07
    ## 29 -236.39801531771172 7.242708465383512e-107 3.359344861254866e-04
    ## 15 -261.05459585857108 9.187155711265992e-121 2.176464230545365e-07
    ## 38 -198.27949509968363  2.597981971174823e-90 3.359902920731962e-04
    ## 9  -235.73112711247413 4.671829239239061e-107 1.112281408627170e-04
    ## 23 -192.21414231181197  2.497653436418940e-90 7.500211791147484e-07
    ## 31 -197.22010001635712  2.497653436418940e-90 1.119781620418319e-04
    ## 3  -243.49965213391167 6.678752200211899e-108 3.760543332427121e-02
    ## 45 -235.04751689518636 3.682119020721067e-106 4.425245765313530e-04
    ## 54 -194.10080813761226  4.533448287534479e-89 8.981286971966362e-05
    ## 21 -199.98266733324951  3.570594627847915e-91 2.535767587611006e-04
    ## 27 -204.98862503779466  3.570594627847915e-91 3.785901008303230e-02
    ## 51 -196.53648979906936  1.968534540638615e-89 4.455085588410718e-04
    ## 61 -155.58978104149526  2.423672209396145e-72 9.041848583375451e-05
    ## 14 -229.64520557865401 4.529190838570036e-105 2.452822935802919e-05
    ## 40 -191.13417848253701  2.421396091950090e-88 2.469362537527819e-05
    ## 18 -190.58922958410423  2.073888886334824e-88 1.226411467901442e-05
    ## 42 -152.07820248798726  1.108742515715088e-71 1.234681268763892e-05
    ## 12 -196.67817482348246  2.395689111197149e-91 6.247071772539155e-06
    ## 37 -166.87010481976657  1.280783358029497e-74 3.786529927936164e-02
    ## 7  -232.42718665873531 5.021089282599544e-106 4.391799996651740e-05
    ## 30 -193.91615956261833  2.684374847419155e-89 4.421414291976428e-05
    ## 10 -193.24927135738071  1.731526398058188e-89 1.463933332217284e-05
    ## 32 -154.73824426126373  9.257086757444129e-73 1.473804763992183e-05
    ## 2  -242.75662687370664 1.287330993889636e-108 3.447892543334091e-03
    ## 44 -234.30449163498133 7.097292722455542e-107 4.057331754450934e-05
    ## 53 -193.35778287740723  8.738231805566713e-90 8.234584644501390e-06
    ## 20 -199.23964207304448  6.882329203497945e-92 2.324944398741802e-05
    ## 26 -204.24559977758963  6.882329203497945e-92 3.471141987321509e-03
    ## 50 -195.79346453886433  3.794354769781673e-90 4.084690700873392e-05
    ## 60 -154.84675578129023  4.671633653492396e-73 8.290111176156823e-06
    ## 17 -189.84620432389920  3.997425508880797e-89 1.124447874001128e-06
    ## 34 -157.42412246716043  2.468712813146602e-75 5.766313856959634e-07
    ## 36 -166.12707955956154  2.468712813146602e-75 3.471718618707204e-03
    ## 6  -231.68416139853028 9.678160924090567e-107 4.026666660026763e-06
    ## 4  -200.27477111861324  4.771252297143867e-91 4.537956654620387e-04
    ## 55 -150.87592712231384  3.238662688397923e-72 1.083797934996405e-06
    ## 22 -156.75778631795112  2.550806993520197e-74 3.059984258004306e-06
    ## 28 -161.76374402249624  2.550806993520197e-74 4.568556497200431e-04
    ## 8  -189.20230564343689  3.587029890554621e-89 5.299712371005844e-07
    ## 58   42.62333831511589  5.000000000000000e-01 1.541307791353605e-19
    ## 64   37.61738061057074  5.000000000000000e-01 2.301172532490936e-17
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
    ## $varnames
    ## [1] "firstname"  "middlename" "lastname"   "housenum"   "streetname"
    ## [6] "city"       "birthyear" 
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

### Preprocessing Matches via Blocking

In order to reduce the number of pairwise comparisons that need to be conducted, researchers will often block similar observations from dataset A and dataset B together so that comparisons are only made between these maximally similar groups. Here, we implement a form of this clustering that uses word embedding, a common preprocessing method for textual data, to form maximally similar groups.

In , the function `blockData()` can block two data sets using a single variable or combinations of variables using several different blocking techniques. The basic functionality is similar to that of `fastLink()`, where the analyst inputs two data sets and a vector of variable names that they want to block on. A simple example follows, where we are blocking the two sample data sets by gender:

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

``` r
blockgender_out <- blockData(dfA, dfB, varnames = "gender")
```

    ## 
    ## ==================== 
    ## blockData(): Blocking Methods for Record Linkage
    ## ==================== 
    ## 
    ## Blocking variables.
    ##     Blocking variable gender using exact blocking.
    ## 
    ## Combining blocked variables for final blocking assignments.

``` r
names(blockgender_out)
```

    ## [1] "block.1" "block.2"

In its simplest usage, takes two data sets and a single variable name for the argument, and it returns the indices of the member observations for each block. Data sets can then be subsetted as follows and the match can then be run within each block separately:

``` r
## Subset dfA into blocks
dfA_block1 <- dfA[blockgender_out$block.1$dfA.inds,]
dfA_block2 <- dfA[blockgender_out$block.2$dfA.inds,]

## Subset dfB into blocks
dfB_block1 <- dfB[blockgender_out$block.1$dfB.inds,]
dfB_block2 <- dfB[blockgender_out$block.2$dfB.inds,]

## Run fastLink on each
fl_out_block1 <- fastLink(
  dfA_block1, dfB_block1,
  varnames = c("firstname", "lastname", "housenum",
               "streetname", "city", "birthyear")
)
```

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

``` r
fl_out_block2 <- fastLink(
  dfA_block2, dfB_block2,
  varnames = c("firstname", "lastname", "housenum",
               "streetname", "city", "birthyear")
)
```

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

`blockData()` also implements other methods of blocking other than exact blocking. Analysts commonly use {} for numeric variables, where a given observation in dataset A will be compared to all observations in dataset B where the value of the blocking variable is within ±*K* of the value of the same variable in dataset A. The value of *K* is the size of the window --- for instance, if we wanted to compare observations where birth year is within ±1 year, the window size is 1. Below, we block `dfA` and `dfB` on gender and birth year, using exact blocking on gender and window blocking with a window size of 1 on birth year:

``` r
## Exact block on gender, window block (+/- 1 year) on birth year
blockdata_out <- blockData(dfA, dfB, varnames = c("gender", "birthyear"),
                           window.block = "birthyear", window.size = 1)
```

    ## 
    ## ==================== 
    ## blockData(): Blocking Methods for Record Linkage
    ## ==================== 
    ## 
    ## Blocking variables.
    ##     Blocking variable gender using exact blocking.
    ##     Blocking variable birthyear using window blocking.
    ## 
    ## Combining blocked variables for final blocking assignments.

`blockData()` also allows users to block variables using k-means clustering, so that similar values of string and numeric variables are blocked together. When applying k-means blocking to string variables such as name, the algorithm orders observations so that alphabetically close names are grouped together in a block. In the following example, we block `dfA` and `dfB` on gender and first name, again using exact blocking on gender and k-means blocking on first name while specifying 2 clusters for the k-means algorithm:

``` r
## Exact block on gender, k-means block on first name with 2 clusters
blockdata_out <- blockData(dfA, dfB, varnames = c("gender", "firstname"),
                           kmeans.block = "firstname", nclusters = 2)
```

    ## 
    ## ==================== 
    ## blockData(): Blocking Methods for Record Linkage
    ## ==================== 
    ## 
    ## Blocking variables.
    ##     Blocking variable gender using exact blocking.
    ##     Blocking variable firstname using k-means blocking.
    ## 
    ## Combining blocked variables for final blocking assignments.

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
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

where `priors.obj` is an input for the the optimal prior parameters. This can be calculated by `calcMoversPriors()`, or can be provided by the user as a list with two entries named `lambda.prior` and `pi.prior`. `w.lambda` and `w.pi` are user-specified weights between 0 and 1 indicating the weighting between the MLE estimate and the prior, where a weight of 0 indicates no weight being placed on the prior. `address_field` is a vector of booleans of the same length as `varnames`, where `TRUE` indicates an address-related field used for matching.

Aggregating Multiple Matches Together
-------------------------------------

Often, we run several different matches for a single data set - for instance, when blocking by gender or by some other criterion to reduce the number of pairwise comparisons. Here, we walk through how to aggregate those multiple matches into a single summary. Here, we run `fastLink()` on the subsets of data defined by blocking on gender in the previous section:

``` r
## Run fastLink on each
link.1 <- fastLink(
  dfA_block1, dfB_block1,
  varnames = c("firstname", "lastname", "housenum",
               "streetname", "city", "birthyear")
)
```

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

``` r
link.2 <- fastLink(
  dfA_block2, dfB_block2,
  varnames = c("firstname", "lastname", "housenum",
               "streetname", "city", "birthyear")
)
```

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

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
    ## 1 Match Count      50      50      50      50
    ## 2  Match Rate 14.286% 14.286% 14.286% 14.286%
    ## 3         FDR      0%      0%      0%        
    ## 4         FNR      0%      0%      0%

If we assume that the first `fastLink` run was for a within-geography match and the second was an across-geography match, the call to `aggregateEM()` would be:

``` r
agg.out <- aggregateEM(em.list = list(link.1, link.2), within.geo = c(TRUE, FALSE))
summary(agg.out)
```

    ##                                 95%     85%     75%   Exact
    ## 1  Match Count          All      50      50      50      50
    ## 2              Within-State      24      24      24      24
    ## 3              Across-State      26      26      26      26
    ## 4   Match Rate          All  29.24%  29.24%  29.24%  29.24%
    ## 5              Within-State 14.035% 14.035% 14.035% 14.035%
    ## 6              Across-State 15.205% 15.205% 15.205% 15.205%
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
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
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
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Imputing matching probabilities using provided EM object.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Deduping the estimated matches.
    ## Getting the match patterns for each estimated match.

``` r
summary(fs.out)
```

    ##                   95%     85%     75%   Exact
    ## 1 Match Count      50      50      50      43
    ## 2  Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 3         FDR      0%      0%      0%        
    ## 4         FNR      0%      0%      0%

In the first run of `fastLink()`, we specify `estimate.only = TRUE`, which runs the algorithm only through the EM estimation step and returns the EM object. In the second run of `fastLink()`, we provide the EM object from the first stage as an argument to `em.obj`. Then, using the parameter values calculated in the previous EM stage, we estimate posterior probabilities of belonging to the matched set for all matching patterns in the full dataset that were not present in the random sample.

Finding Duplicates within a Dataset via `fastLink`
--------------------------------------------------

The following lines of code represent an example on how to find duplicates withing a dataset via `fastLink`. As before, we use `fastLink()` (the wrapper function) to do the merge. `fastLink()` will automatically detect that two datasets are identical, and will use the probabilistic match algorithm to indicate duplicated entries in the `dedupe.ids` covariate in the returned data frame.

``` r
## Add duplicates
dfA <- rbind(dfA, dfA[sample(1:nrow(dfA), 10, replace = FALSE),])

## Run fastLink
fl_out_dedupe <- fastLink(
  dfA = dfA, dfB = dfA,
  varnames = c("firstname", "lastname", "housenum",
               "streetname", "city", "birthyear")
)
```

    ## 
    ## ==================== 
    ## fastLink(): Fast Probabilistic Record Linkage
    ## ==================== 
    ## 
    ## dfA and dfB are identical, assuming deduplication of a single data set.
    ## Setting return.all to FALSE.
    ## 
    ## Calculating matches for each variable.
    ## Getting counts for parameter estimation.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Running the EM algorithm.
    ## Getting the indices of estimated matches.
    ##     Parallelizing calculation using OpenMP. 1 threads out of 8 are used.
    ## Calculating the posterior for each pair of matched observations.
    ## Getting the match patterns for each estimated match.

``` r
## Run getMatches
dfA_dedupe <- getMatches(dfA = dfA, dfB = dfA, fl.out = fl_out_dedupe)

## Look at the IDs of the duplicates
names(table(dfA_dedupe$dedupe.ids)[table(dfA_dedupe$dedupe.ids) > 1])
```

    ##  [1] "501" "502" "503" "504" "505" "506" "507" "508" "509" "510"

``` r
## Show duplicated observation
dfA_dedupe[dfA_dedupe$dedupe.ids == 501,]
```

    ##      firstname middlename lastname housenum   streetname       city
    ## 170       evan       <NA>    jones     3701  overmoor st Pleasanton
    ## 1701      evan       <NA>    jones     3701  overmoor st Pleasanton
    ##      birthyear gender dedupe.ids
    ## 170       1953      F        501
    ## 1701      1953      F        501
