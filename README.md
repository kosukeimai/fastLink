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

-   [User’s Guide and Codebook for the ANES 2016 Time Series Voter Validation Supplemental Data](https://www.electionstudies.org/wp-content/uploads/2018/03/anes_timeseries_2016voteval_userguidecodebook.pdf)

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
    ##  [1,] 5.140243772082558e-104
    ##  [2,] 1.207055866289496e-101
    ##  [3,]  7.650188609975762e-87
    ##  [4,]  4.899168963127878e-88
    ##  [5,]  1.150445562329993e-85
    ##  [6,]  7.291398669383124e-71
    ##  [7,]  3.281425963247137e-90
    ##  [8,]  7.705596532686194e-88
    ##  [9,]  4.883723154308954e-73
    ## [10,] 3.254952564149871e-100
    ## [11,]  2.077894809415214e-86
    ## [12,]  1.420537067059675e-85
    ## [13,]  3.335770979167710e-83
    ## [14,]  1.353914603760525e-69
    ## [15,]  9.068416636038526e-72
    ## [16,]  2.046874885656473e-86
    ## [17,]  1.306682852239560e-72
    ## [18,]  1.944726887729658e-55
    ## [19,]  2.170320888599748e-76
    ## [20,]  3.230073295771142e-59
    ## [21,] 3.155027784483807e-100
    ## [22,]  7.408782471078426e-98
    ## [23,]  4.695605634912566e-83
    ## [24,]  2.014104884091221e-86
    ## [25,]  1.997855789027882e-96
    ## [26,]  1.332120227831835e-72
    ## [27,]  7.120669841437030e-86
    ## [28,]  6.786714060783790e-70
    ## [29,]  4.545689257055413e-72
    ## [30,]  4.023799438631091e-89
    ## [31,]  9.448872334714695e-87
    ## [32,]  5.988592370157348e-72
    ## [33,]  3.835085299000524e-73
    ## [34,]  2.568710849966839e-75
    ## [35,]  6.031965871139529e-73
    ## [36,]  3.822994269934483e-58
    ## [37,]  2.547987387588575e-85
    ## [38,]  1.626582772799451e-71
    ## [39,]  1.112001007429602e-70
    ## [40,]  7.098785852831457e-57
    ## [41,]  1.602300276221234e-71
    ## [42,]  1.698934206316614e-61
    ## [43,]  2.469765947097805e-85
    ## [44,]  1.576647813079722e-71
    ## [45,]  5.574083366680972e-71
    ## [46,]  3.558380242600910e-57
    ## [47,]  3.669623541092290e-88
    ## [48,]  8.617180076957280e-86
    ## [49,]  5.461474875848022e-71
    ## [50,]  3.497520070259037e-72
    ## [51,]  2.342612237280044e-74
    ## [52,]  5.501030629729718e-72
    ## [53,]  3.486493296789465e-57
    ## [54,]  1.014122382792083e-69
    ## [55,]  9.328417810382070e-57
    ## [56,]  1.549393565298416e-60
    ## [57,]  2.252376491096126e-84
    ## [58,]  2.872593168602245e-73
    ## [59,]  4.275260184913621e-56
    ## [60,]  2.737870015376239e-57
    ## [61,]  1.833804430928528e-59
    ## [62,]  1.763167597163696e-69
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
    ## [1] 2.185959982758001e-73 1.095341050219602e-57 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 2.982739663893358e-57 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 3.253165545599419e-73 8.048706314263162e-57 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 4.395866354147246e-57 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 3.781263084876334e-71 8.189963046024995e-57 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 4.4273484835967e-57 1.0000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 5.176152502532613e-57 1.000000000000000e+00
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
    ##  [1,] 7.669967064148554e-101
    ##  [2,] 2.119453790635916e-100
    ##  [3,]  2.726276511509150e-86
    ##  [4,]  4.929365828827828e-87
    ##  [5,]  1.362139237882084e-86
    ##  [6,]  1.752134548085000e-72
    ##  [7,]  4.929365828827828e-87
    ##  [8,]  1.362139237882123e-86
    ##  [9,]  1.752134548085050e-72
    ## [10,] 3.167889674752518e-100
    ## [11,]  2.035952303525970e-86
    ## [12,]  6.912703977480085e-86
    ## [13,]  1.910198117681300e-85
    ## [14,]  4.442684888526995e-72
    ## [15,]  4.442684888527121e-72
    ## [16,]  5.073725638680528e-87
    ## [17,]  3.260802762121879e-73
    ## [18,]  1.159046695335960e-58
    ## [19,]  3.260802762121971e-73
    ## [20,]  1.159046695335960e-58
    ## [21,] 5.498002440796680e-100
    ## [22,]  1.519271467088838e-99
    ## [23,]  1.954255447148770e-85
    ## [24,]  3.533478714029356e-86
    ## [25,]  2.270813553473508e-99
    ## [26,]  2.337415714456310e-72
    ## [27,]  4.136198140722506e-86
    ## [28,]  2.658268752083891e-72
    ## [29,]  2.658268752083891e-72
    ## [30,]  7.902285757169161e-87
    ## [31,]  2.183650772244828e-86
    ## [32,]  2.808853788656415e-72
    ## [33,]  5.078673357425520e-73
    ## [34,]  5.078673357425520e-73
    ## [35,]  1.403397616804769e-72
    ## [36,]  1.805205650581702e-58
    ## [37,]  3.263843149222056e-86
    ## [38,]  2.097620075271474e-72
    ## [39,]  7.122085626691424e-72
    ## [40,]  4.577251143919458e-58
    ## [41,]  5.227405739164018e-73
    ## [42,]  3.359570518170772e-59
    ## [43,]  5.664533630642381e-86
    ## [44,]  3.640505660793874e-72
    ## [45,]  4.261481096710478e-72
    ## [46,]  2.738786115068187e-58
    ## [47,]  6.607558891488454e-87
    ## [48,]  1.825876906939481e-86
    ## [49,]  2.348645366220768e-72
    ## [50,]  4.246572995589048e-73
    ## [51,]  4.246572995589169e-73
    ## [52,]  1.173462044548227e-72
    ## [53,]  1.509437017845745e-58
    ## [54,]  5.955188366339870e-72
    ## [55,]  2.809131526126177e-59
    ## [56,]  2.809131526126177e-59
    ## [57,]  4.736444708207517e-86
    ## [58,]  6.807697879425447e-73
    ## [59,]  2.419784422918906e-58
    ## [60,]  4.375199139599925e-59
    ## [61,]  4.375199139600049e-59
    ## [62,]  4.879908771999724e-72
    ## [63,]  4.999999999999961e-01
    ## [64,]  5.000000000000039e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.857221939649586e-01
    ##  [2,] 3.362255975078642e-03
    ##  [3,] 6.823888974051224e-04
    ##  [4,] 1.926649993020625e-03
    ##  [5,] 2.267198904301176e-05
    ##  [6,] 4.601408613655581e-06
    ##  [7,] 2.876488439579793e-01
    ##  [8,] 3.384927964121654e-03
    ##  [9,] 6.869903060187781e-04
    ## [10,] 1.863629504231385e-04
    ## [11,] 1.876196122601119e-04
    ## [12,] 9.318147521156777e-05
    ## [13,] 1.096519550858411e-06
    ## [14,] 6.283309184866345e-07
    ## [15,] 9.380980613005451e-05
    ## [16,] 4.746460537537378e-05
    ## [17,] 4.778466340218014e-05
    ## [18,] 1.141238743808879e-07
    ## [19,] 2.876966286213814e-01
    ## [20,] 6.871044298931587e-04
    ## [21,] 3.336844225881423e-04
    ## [22,] 3.926654867333284e-06
    ## [23,] 7.969368499218280e-07
    ## [24,] 3.359344861254866e-04
    ## [25,] 2.176464230545361e-07
    ## [26,] 3.359902920731962e-04
    ## [27,] 1.112281408627176e-04
    ## [28,] 7.500211791147510e-07
    ## [29,] 1.119781620418323e-04
    ## [30,] 3.760543332427121e-02
    ## [31,] 4.425245765313530e-04
    ## [32,] 8.981286971966362e-05
    ## [33,] 2.535767587611006e-04
    ## [34,] 3.785901008303230e-02
    ## [35,] 4.455085588410718e-04
    ## [36,] 9.041848583375434e-05
    ## [37,] 2.452822935802914e-05
    ## [38,] 2.469362537527814e-05
    ## [39,] 1.226411467901440e-05
    ## [40,] 1.234681268763889e-05
    ## [41,] 6.247071772539211e-06
    ## [42,] 3.786529927936164e-02
    ## [43,] 4.391799996651740e-05
    ## [44,] 4.421414291976428e-05
    ## [45,] 1.463933332217292e-05
    ## [46,] 1.473804763992188e-05
    ## [47,] 3.447892543334091e-03
    ## [48,] 4.057331754450934e-05
    ## [49,] 8.234584644501390e-06
    ## [50,] 2.324944398741802e-05
    ## [51,] 3.471141987321509e-03
    ## [52,] 4.084690700873392e-05
    ## [53,] 8.290111176156823e-06
    ## [54,] 1.124447874001126e-06
    ## [55,] 5.766313856959685e-07
    ## [56,] 3.471718618707204e-03
    ## [57,] 4.026666660026763e-06
    ## [58,] 4.537956654620387e-04
    ## [59,] 1.083797934996405e-06
    ## [60,] 3.059984258004306e-06
    ## [61,] 4.568556497200431e-04
    ## [62,] 5.299712371005844e-07
    ## [63,] 1.541307791353627e-19
    ## [64,] 2.301172532490969e-17
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
    ## 1  -229.27104678114122 7.669967064148554e-101 2.857221939649586e-01
    ## 43 -223.81220778068851 2.119453790635916e-100 3.362255975078642e-03
    ## 52 -189.72947040262679  2.726276511509150e-86 6.823888974051224e-04
    ## 19 -192.47772020668282  4.929365828827828e-87 1.926649993020625e-03
    ## 48 -187.01888120623013  1.362139237882084e-86 2.267198904301176e-05
    ## 57 -152.93614382816844  1.752134548085000e-72 4.601408613655581e-06
    ## 25 -197.48367791122797  4.929365828827828e-87 2.876488439579793e-01
    ## 49 -192.02483891077526  1.362139237882123e-86 3.384927964121654e-03
    ## 59 -157.94210153271356  1.752134548085050e-72 6.869903060187781e-04
    ## 13 -220.51762921165422 3.167889674752518e-100 1.863629504231385e-04
    ## 39 -188.73026034174097  2.035952303525970e-86 1.876196122601119e-04
    ## 16 -186.80799550272536  6.912703977480085e-86 9.318147521156777e-05
    ## 47 -181.34915650227265  1.910198117681300e-85 1.096519550858411e-06
    ## 24 -150.01466892826699  4.442684888526995e-72 6.283309184866345e-07
    ## 41 -155.02062663281208  4.442684888527121e-72 9.380980613005451e-05
    ## 11 -188.74530142808709  5.073725638680528e-87 4.746460537537378e-05
    ## 33 -156.95793255817384  3.260802762121879e-73 4.778466340218014e-05
    ## 62 -117.41635617965943  1.159046695335960e-58 1.141238743808879e-07
    ## 35 -165.66088965057492  3.260802762121971e-73 2.876966286213814e-01
    ## 63 -126.11931327206052  1.159046695335960e-58 6.871044298931587e-04
    ## 5  -220.54880961153583 5.498002440796680e-100 3.336844225881423e-04
    ## 46 -215.08997061108312  1.519271467088838e-99 3.926654867333284e-06
    ## 56 -181.00723323302142  1.954255447148770e-85 7.969368499218280e-07
    ## 29 -188.76144074162258  3.533478714029356e-86 3.359344861254866e-04
    ## 15 -211.79539204204883  2.270813553473508e-99 2.176464230545361e-07
    ## 38 -156.93865248096952  2.337415714456310e-72 3.359902920731962e-04
    ## 9  -187.49861381221382  4.136198140722506e-86 1.112281408627176e-04
    ## 23 -150.70528723775541  2.658268752083891e-72 7.500211791147510e-07
    ## 31 -155.71124494230057  2.658268752083891e-72 1.119781620418323e-04
    ## 3  -194.97714430078736  7.902285757169161e-87 3.760543332427121e-02
    ## 45 -189.51830530033465  2.183650772244828e-86 4.425245765313530e-04
    ## 54 -155.43556792227295  2.808853788656415e-72 8.981286971966362e-05
    ## 21 -158.18381772632895  5.078673357425520e-73 2.535767587611006e-04
    ## 27 -163.18977543087411  5.078673357425520e-73 3.785901008303230e-02
    ## 51 -157.73093643042139  1.403397616804769e-72 4.455085588410718e-04
    ## 61 -123.64819905235970  1.805205650581702e-58 9.041848583375434e-05
    ## 14 -186.22372673130036  3.263843149222056e-86 2.452822935802914e-05
    ## 40 -154.43635786138711  2.097620075271474e-72 2.469362537527814e-05
    ## 18 -152.51409302237147  7.122085626691424e-72 1.226411467901440e-05
    ## 42 -120.72672415245823  4.577251143919458e-58 1.234681268763889e-05
    ## 12 -154.45139894773322  5.227405739164018e-73 6.247071772539211e-06
    ## 37 -131.36698717022105  3.359570518170772e-59 3.786529927936164e-02
    ## 7  -186.25490713118197  5.664533630642381e-86 4.391799996651740e-05
    ## 30 -154.46753826126869  3.640505660793874e-72 4.421414291976428e-05
    ## 10 -153.20471133185995  4.261481096710478e-72 1.463933332217292e-05
    ## 32 -121.41734246194672  2.738786115068187e-58 1.473804763992188e-05
    ## 2  -192.76669671860816  6.607558891488454e-87 3.447892543334091e-03
    ## 44 -187.30785771815545  1.825876906939481e-86 4.057331754450934e-05
    ## 53 -153.22512034009375  2.348645366220768e-72 8.234584644501390e-06
    ## 20 -155.97337014414978  4.246572995589048e-73 2.324944398741802e-05
    ## 26 -160.97932784869488  4.246572995589169e-73 3.471141987321509e-03
    ## 50 -155.52048884824219  1.173462044548227e-72 4.084690700873392e-05
    ## 60 -121.43775147018050  1.509437017845745e-58 8.290111176156823e-06
    ## 17 -150.30364544019227  5.955188366339870e-72 1.124447874001126e-06
    ## 34 -120.45358249564076  2.809131526126177e-59 5.766313856959685e-07
    ## 36 -129.15653958804185  2.809131526126177e-59 3.471718618707204e-03
    ## 6  -184.04445954900274  4.736444708207517e-86 4.026666660026763e-06
    ## 4  -158.47279423825427  6.807697879425447e-73 4.537956654620387e-04
    ## 55 -118.93121785973989  2.419784422918906e-58 1.083797934996405e-06
    ## 22 -121.67946766379590  4.375199139599925e-59 3.059984258004306e-06
    ## 28 -126.68542536834103  4.375199139600049e-59 4.568556497200431e-04
    ## 8  -149.75055706864887  4.879908771999724e-72 5.299712371005844e-07
    ## 58   42.62333831511587  4.999999999999961e-01 1.541307791353627e-19
    ## 64   37.61738061057073  5.000000000000039e-01 2.301172532490969e-17
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
    ## 2              Within-State      26      26      26      26
    ## 3              Across-State      24      24      24      24
    ## 4   Match Rate          All 27.027% 27.027% 27.027% 27.027%
    ## 5              Within-State 14.054% 14.054% 14.054% 14.054%
    ## 6              Across-State 12.973% 12.973% 12.973% 12.973%
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
    ## 1 Match Count      78      78      78      43
    ## 2  Match Rate 22.286% 22.286% 22.286% 12.286%
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

    ##      firstname middlename lastname housenum   streetname          city
    ## 289      bruce        the    davis     2650  granger ave Castro Valley
    ## 2891     bruce        the    davis     2650  granger ave Castro Valley
    ##      birthyear gender dedupe.ids
    ## 289       1989      F        501
    ## 2891      1989      F        501
