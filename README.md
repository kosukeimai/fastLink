fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.org/kosukeimai/fastLink.svg?branch=master)](https://travis-ci.org/kosukeimai/fastLink) [![CRAN Version](http://www.r-pkg.org/badges/version/fastLink)](https://CRAN.R-project.org/package=fastLink) ![CRAN downloads](http://cranlogs.r-pkg.org/badges/grand-total/fastLink)
===========================================================================================================================================================================================================================================================================================================================================================

Authors: [Ted Enamorado](https://www.tedenamorado.com/), [Ben Fifield](https://www.benfifield.com/), [Kosuke Imai](https://imai.fas.harvard.edu/)

Paper: [Using a Probabilistic Model to Assist Merging of Large-scale Administrative Records](http://imai.princeton.edu/research/files/linkage.pdf)

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
    ##                        [,1]
    ##  [1,] 1.915892026004878e-46
    ##  [2,] 8.500993491772351e-41
    ##  [3,] 8.000710469916388e-36
    ##  [4,] 1.705565849704166e-39
    ##  [5,] 7.567756424331703e-34
    ##  [6,] 7.122394355027825e-29
    ##  [7,] 1.142392575318626e-41
    ##  [8,] 5.068903526929744e-36
    ##  [9,] 4.770598819791326e-31
    ## [10,] 1.225479911077157e-38
    ## [11,] 7.307192329287928e-34
    ## [12,] 2.526034919358477e-34
    ## [13,] 1.120825501541136e-28
    ## [14,] 2.248727399634298e-27
    ## [15,] 1.506203636583935e-29
    ## [16,] 1.184881492651387e-38
    ## [17,] 7.065115369053422e-34
    ## [18,] 2.950372032302043e-23
    ## [19,] 1.173586860689027e-37
    ## [20,] 4.900865266009045e-27
    ## [21,] 1.243640822192291e-41
    ## [22,] 5.518151540932488e-36
    ## [23,] 5.193408611693840e-31
    ## [24,] 7.415480738746123e-37
    ## [25,] 7.954815947379759e-34
    ## [26,] 7.617968593902668e-33
    ## [27,] 5.175697524496910e-37
    ## [28,] 4.607510666761263e-30
    ## [29,] 3.086122988052569e-32
    ## [30,] 5.272885590612437e-39
    ## [31,] 2.339629033381747e-33
    ## [32,] 2.201941987276489e-28
    ## [33,] 4.694029449821854e-32
    ## [34,] 3.144073500729149e-34
    ## [35,] 1.395055045094905e-28
    ## [36,] 1.312956128739897e-23
    ## [37,] 3.372745059218284e-31
    ## [38,] 2.011073099003409e-26
    ## [39,] 6.952110529654170e-27
    ## [40,] 4.145348142834824e-22
    ## [41,] 3.261010779512972e-31
    ## [42,] 3.229925884687310e-30
    ## [43,] 3.422727211255923e-34
    ## [44,] 2.040876051680920e-29
    ## [45,] 1.424446708262376e-29
    ## [46,] 8.493575427887089e-25
    ## [47,] 2.755449248755941e-40
    ## [48,] 1.222618801719656e-34
    ## [49,] 1.150667749258057e-29
    ## [50,] 2.452956677872428e-33
    ## [51,] 1.642996954275180e-35
    ## [52,] 7.290132338208993e-30
    ## [53,] 6.861108431836294e-25
    ## [54,] 3.632961005319133e-28
    ## [55,] 1.016109810563146e-27
    ## [56,] 1.687860792645335e-31
    ## [57,] 1.788612887740728e-35
    ## [58,] 7.583500762162510e-33
    ## [59,] 3.166848294314952e-22
    ## [60,] 6.750985830929579e-26
    ## [61,] 4.521828395352140e-28
    ## [62,] 4.922590101602959e-28
    ## [63,] 9.999999999999982e-01
    ## [64,] 9.999999999997602e-01
    ## 
    ## $p.m
    ## [1] 0.0002857142857142756
    ## 
    ## $p.u
    ## [1] 0.9997142857142858
    ## 
    ## $p.gamma.k.m
    ## $p.gamma.k.m[[1]]
    ## [1] 2.749988850626920e-29 2.494653332980402e-23 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 2.209640085612603e-23 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 4.022620149084567e-28 3.942810210727401e-23 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 6.371128276476425e-23 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 1.315238771989726e-29 6.423380845607160e-23 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 6.591860821185402e-25 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 4.522714544789727e-23 1.000000000000000e+00
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
    ##                        [,1]
    ##  [1,] 2.859605500271046e-43
    ##  [2,] 1.493107576764568e-39
    ##  [3,] 2.852013850138708e-35
    ##  [4,] 1.716571445561855e-38
    ##  [5,] 8.962865091647007e-35
    ##  [6,] 1.712014310026680e-30
    ##  [7,] 1.716600041616858e-38
    ##  [8,] 8.963014402404685e-35
    ##  [9,] 1.712042830165181e-30
    ## [10,] 1.193044979111505e-38
    ## [11,] 7.161760811410791e-34
    ## [12,] 1.229589257843423e-34
    ## [13,] 6.420147943554880e-31
    ## [14,] 7.381010456105060e-30
    ## [15,] 7.381133415030847e-30
    ## [16,] 2.937892225648968e-39
    ## [17,] 1.763594984111216e-34
    ## [18,] 1.758913010988263e-26
    ## [19,] 1.763766644115378e-34
    ## [20,] 1.759084215271280e-26
    ## [21,] 2.167813554640074e-41
    ## [22,] 1.131896984790115e-37
    ## [23,] 2.162058466374435e-33
    ## [24,] 1.301322450862548e-36
    ## [25,] 9.044251302384414e-37
    ## [26,] 1.337078571842495e-32
    ## [27,] 3.007231673073579e-37
    ## [28,] 1.805188869477982e-32
    ## [29,] 1.805218941794713e-32
    ## [30,] 1.035833516807725e-36
    ## [31,] 5.408476351250926e-33
    ## [32,] 1.033083597053336e-28
    ## [33,] 6.217928442015939e-32
    ## [34,] 6.218032025367622e-32
    ## [35,] 3.246668370431213e-28
    ## [36,] 6.201524460375251e-24
    ## [37,] 4.321561055557259e-32
    ## [38,] 2.594201153661313e-27
    ## [39,] 4.453935219596658e-28
    ## [40,] 2.673664385732132e-23
    ## [41,] 1.064191279464108e-32
    ## [42,] 6.388883381393027e-28
    ## [43,] 7.852460550497066e-35
    ## [44,] 4.713774017604999e-30
    ## [45,] 1.089308073956401e-30
    ## [46,] 6.539035838719311e-26
    ## [47,] 4.962915129898698e-39
    ## [48,] 2.591324636418867e-35
    ## [49,] 4.949739635831735e-31
    ## [50,] 2.979151634001096e-34
    ## [51,] 2.979201263152396e-34
    ## [52,] 1.555553022365424e-30
    ## [53,] 2.971292111466428e-26
    ## [54,] 2.133982163180771e-30
    ## [55,] 3.060762132689073e-30
    ## [56,] 3.061060052815389e-30
    ## [57,] 3.762293326160880e-37
    ## [58,] 1.797714346308948e-32
    ## [59,] 1.792941793467724e-24
    ## [60,] 1.079136654989059e-27
    ## [61,] 1.079154632132523e-27
    ## [62,] 1.362813691234707e-30
    ## [63,] 4.999958353296493e-01
    ## [64,] 5.000041646703507e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.857222111586799e-01
    ##  [2,] 3.362252492097691e-03
    ##  [3,] 6.823889479934597e-04
    ##  [4,] 1.926647666808348e-03
    ##  [5,] 2.267193681881101e-05
    ##  [6,] 4.601403122199872e-06
    ##  [7,] 2.876488588254883e-01
    ##  [8,] 3.384924428916500e-03
    ##  [9,] 6.869903511156591e-04
    ## [10,] 1.863629298758235e-04
    ## [11,] 1.876195899813462e-04
    ## [12,] 9.318148321526391e-05
    ## [13,] 1.096518443166761e-06
    ## [14,] 6.283301760069545e-07
    ## [15,] 9.380981339127096e-05
    ## [16,] 4.746460297489895e-05
    ## [17,] 4.778466057982481e-05
    ## [18,] 1.141238692331903e-07
    ## [19,] 2.876966434860681e-01
    ## [20,] 6.871044749848927e-04
    ## [21,] 3.336843717810956e-04
    ## [22,] 3.926649965521790e-06
    ## [23,] 7.969367397031042e-07
    ## [24,] 3.359344321237456e-04
    ## [25,] 2.176463528219105e-07
    ## [26,] 3.359902380563041e-04
    ## [27,] 1.112261507878417e-04
    ## [28,] 7.500068091817249e-07
    ## [29,] 1.119761575970234e-04
    ## [30,] 3.760542660818925e-02
    ## [31,] 4.425240124561454e-04
    ## [32,] 8.981285493326948e-05
    ## [33,] 2.535763920494193e-04
    ## [34,] 3.785900300023868e-02
    ## [35,] 4.455079871798740e-04
    ## [36,] 9.041847017999760e-05
    ## [37,] 2.452822079708836e-05
    ## [38,] 2.469361654696033e-05
    ## [39,] 1.226411280412415e-05
    ## [40,] 1.234681069528115e-05
    ## [41,] 6.247069964988192e-06
    ## [42,] 3.786529219469488e-02
    ## [43,] 4.391798279324114e-05
    ## [44,] 4.421412525530738e-05
    ## [45,] 1.463906790235725e-05
    ## [46,] 1.473778030523257e-05
    ## [47,] 3.447889514072570e-03
    ## [48,] 4.057323742580805e-05
    ## [49,] 8.234577524667831e-06
    ## [50,] 2.324939409072287e-05
    ## [51,] 3.471138908163294e-03
    ## [52,] 4.084682600299394e-05
    ## [53,] 8.290103937930262e-06
    ## [54,] 1.124446914997485e-06
    ## [55,] 5.766308103194508e-07
    ## [56,] 3.471715538973612e-03
    ## [57,] 4.026662266851144e-06
    ## [58,] 4.537951584120744e-04
    ## [59,] 1.083796739138925e-06
    ## [60,] 3.059976960202057e-06
    ## [61,] 4.568551353722765e-04
    ## [62,] 5.299705323501783e-07
    ## [63,] 1.541276336420907e-19
    ## [64,] 2.301128467565872e-17
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
    ##               weights           p.gamma.j.m           p.gamma.j.u
    ## 1  -96.70774009056984 2.859605500271046e-43 2.857222111586799e-01
    ## 43 -83.70481491164952 1.493107576764568e-39 3.362252492097691e-03
    ## 52 -72.25254213825433 2.852013850138708e-35 6.823889479934597e-04
    ## 19 -80.70593083137665 1.716571445561855e-38 1.926647666808348e-03
    ## 48 -67.70300565245633 8.962865091647007e-35 2.267193681881101e-05
    ## 57 -56.25073287906113 1.712014310026680e-30 4.601403122199872e-06
    ## 25 -85.71187313631449 1.716600041616858e-38 2.876488588254883e-01
    ## 49 -72.70894795739417 8.963014402404685e-35 3.384924428916500e-03
    ## 59 -61.25667518399898 1.712042830165181e-30 6.869903511156591e-04
    ## 13 -78.73391013929678 1.193044979111505e-38 1.863629298758235e-04
    ## 39 -67.73804318504143 7.161760811410791e-34 1.876195899813462e-04
    ## 16 -68.80025145093555 1.229589257843423e-34 9.318148321526391e-05
    ## 47 -55.79732627201524 6.420147943554880e-31 1.096518443166761e-06
    ## 24 -52.79844219174236 7.381010456105060e-30 6.283301760069545e-07
    ## 41 -57.80438449668021 7.381133415030847e-30 9.380981339127096e-05
    ## 11 -78.76759990733376 2.937892225648968e-39 4.746460297489895e-05
    ## 33 -67.77173295307841 1.763594984111216e-34 4.778466057982481e-05
    ## 62 -43.31653500076290 1.758913010988263e-26 1.141238692331903e-07
    ## 35 -76.47459282567245 1.763766644115378e-34 2.876966434860681e-01
    ## 63 -52.01939487335693 1.759084215271280e-26 6.871044749848927e-04
    ## 5  -85.62695472521493 2.167813554640074e-41 3.336843717810956e-04
    ## 46 -72.62402954629461 1.131896984790115e-37 3.926649965521790e-06
    ## 56 -61.17175677289941 2.162058466374435e-33 7.969367397031042e-07
    ## 29 -74.63108777095958 1.301322450862548e-36 3.359344321237456e-04
    ## 15 -67.65312477394187 9.044251302384414e-37 2.176463528219105e-07
    ## 38 -65.39380746031753 1.337078571842495e-32 3.359902380563041e-04
    ## 9  -74.99068346031366 3.007231673073579e-37 1.112261507878417e-04
    ## 23 -58.98887420112047 1.805188869477982e-32 7.500068091817249e-07
    ## 31 -63.99481650605831 1.805218941794713e-32 1.119761575970234e-04
    ## 3  -79.57725000060951 1.035833516807725e-36 3.760542660818925e-02
    ## 45 -66.57432482168919 5.408476351250926e-33 4.425240124561454e-04
    ## 54 -55.12205204829399 1.033083597053336e-28 8.981285493326948e-05
    ## 21 -63.57544074141631 6.217928442015939e-32 2.535763920494193e-04
    ## 27 -68.58138304635416 6.218032025367622e-32 3.785900300023868e-02
    ## 51 -55.57845786743384 3.246668370431213e-28 4.455079871798740e-04
    ## 61 -44.12618509403865 6.201524460375251e-24 9.041847017999760e-05
    ## 14 -61.60342004933644 4.321561055557259e-32 2.452822079708836e-05
    ## 40 -50.60755309508109 2.594201153661313e-27 2.469361654696033e-05
    ## 18 -51.66976136097522 4.453935219596658e-28 1.226411280412415e-05
    ## 42 -40.67389440671987 2.673664385732132e-23 1.234681069528115e-05
    ## 12 -61.63710981737342 1.064191279464108e-32 6.247069964988192e-06
    ## 37 -59.34410273571211 6.388883381393027e-28 3.786529219469488e-02
    ## 7  -68.49646463525460 7.852460550497066e-35 4.391798279324114e-05
    ## 30 -57.50059768099924 4.713774017604999e-30 4.421412525530738e-05
    ## 10 -57.86019337035333 1.089308073956401e-30 1.463906790235725e-05
    ## 32 -46.86432641609798 6.539035838719311e-26 1.473778030523257e-05
    ## 2  -82.52883236069661 4.962915129898698e-39 3.447889514072570e-03
    ## 44 -69.52590718177629 2.591324636418867e-35 4.057323742580805e-05
    ## 53 -58.07363440838110 4.949739635831735e-31 8.234577524667831e-06
    ## 20 -66.52702310150340 2.979151634001096e-34 2.324939409072287e-05
    ## 26 -71.53296540644126 2.979201263152396e-34 3.471138908163294e-03
    ## 50 -58.53004022752094 1.555553022365424e-30 4.084682600299394e-05
    ## 60 -47.07776745412575 2.971292111466428e-26 8.290103937930262e-06
    ## 17 -54.62134372106232 2.133982163180771e-30 1.124446914997485e-06
    ## 34 -53.59282522320517 3.060762132689073e-30 5.766308103194508e-07
    ## 36 -62.29568509579921 3.061060052815389e-30 3.471715538973612e-03
    ## 6  -71.44804699534168 3.762293326160880e-37 4.026662266851144e-06
    ## 4  -65.39834227073626 1.797714346308948e-32 4.537951584120744e-04
    ## 55 -40.94314431842076 1.792941793467724e-24 1.083796739138925e-06
    ## 22 -49.39653301154308 1.079136654989059e-27 3.059976960202057e-06
    ## 28 -54.40247531648093 1.079154632132523e-27 4.568551353722765e-04
    ## 8  -54.31755690538135 1.362813691234707e-30 5.299705323501783e-07
    ## 58  42.62335039389897 4.999958353296493e-01 1.541276336420907e-19
    ## 64  37.61740808896112 5.000041646703507e-01 2.301128467565872e-17
    ## 
    ## $iter.converge
    ## [1] 3
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
    ## 2              Within-State      28      28      28      28
    ## 3              Across-State      22      22      22      22
    ## 4   Match Rate          All 27.174% 27.174% 27.174% 27.174%
    ## 5              Within-State 15.217% 15.217% 15.217% 15.217%
    ## 6              Across-State 11.957% 11.957% 11.957% 11.957%
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

    ##      firstname middlename  lastname housenum        streetname     city
    ## 382     gerald    francis schofield     5693  hearst ave apt 1 Berkeley
    ## 3821    gerald    francis schofield     5693  hearst ave apt 1 Berkeley
    ##      birthyear gender dedupe.ids
    ## 382       1974      M        501
    ## 3821      1974      M        501
