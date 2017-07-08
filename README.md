fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.org/kosukeimai/fastLink.svg?branch=master)](https://travis-ci.org/kosukeimai/fastLink)
=====================================================================================================================================================================

Authors: [Ted Enamorado](https://www.tedenamorado.com/), [Ben Fifield](https://www.benfifield.com/), [Kosuke Imai](https://imai.princeton.edu/)

Installation Instructions
-------------------------

You can install the most recent development version of `fastLink` using the `devtools` package. First you have to install `devtools` using the following code. Note that you only have to do this once:

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
    ##                        [,1]
    ##  [1,] 3.945201249340042e-64
    ##  [2,] 6.742621566969617e-56
    ##  [3,] 3.249526978253269e-50
    ##  [4,] 8.840531337894665e-56
    ##  [5,] 1.510907897850074e-47
    ##  [6,] 7.281642499070619e-42
    ##  [7,] 6.213636555712769e-58
    ##  [8,] 1.061953426504383e-49
    ##  [9,] 5.117959349786601e-44
    ## [10,] 6.273876116966052e-52
    ## [11,] 9.881266765013652e-46
    ## [12,] 8.836388858028914e-47
    ## [13,] 1.510199919414523e-38
    ## [14,] 1.980085873345330e-38
    ## [15,] 1.391718834062698e-40
    ## [16,] 1.382941624500748e-55
    ## [17,] 2.178113634596519e-49
    ## [18,] 1.794037507847429e-35
    ## [19,] 3.617776598752631e-53
    ## [20,] 2.979838521775349e-39
    ## [21,] 7.271066581701707e-57
    ## [22,] 5.988928200270368e-43
    ## [23,] 1.145182774101598e-50
    ## [24,] 1.156285017892020e-44
    ## [25,] 6.667617914713970e-46
    ## [26,] 5.126752814526855e-52
    ## [27,] 4.222730484136201e-38
    ## [28,] 1.148818933534660e-43
    ## [29,] 8.074563675497345e-46
    ## [30,] 3.170965621931544e-55
    ## [31,] 5.419399376427379e-47
    ## [32,] 2.611815642434833e-41
    ## [33,] 7.105599735060578e-47
    ## [34,] 5.852638832964762e-33
    ## [35,] 4.994226317006843e-49
    ## [36,] 8.535477900147840e-41
    ## [37,] 4.113572952794365e-35
    ## [38,] 5.042644018853195e-43
    ## [39,] 7.942093503654346e-37
    ## [40,] 7.102270206244769e-38
    ## [41,] 1.118597582048699e-31
    ## [42,] 1.111542877353479e-46
    ## [43,] 2.907797219315885e-44
    ## [44,] 5.844138412256406e-48
    ## [45,] 9.204435915941333e-42
    ## [46,] 4.120640722630925e-43
    ## [47,] 6.489951262025300e-37
    ## [48,] 3.733416303192555e-55
    ## [49,] 6.380666458673649e-47
    ## [50,] 3.075086980747528e-41
    ## [51,] 8.365956953729649e-47
    ## [52,] 5.880078240138501e-49
    ## [53,] 1.004946005328835e-40
    ## [54,] 4.843218803797542e-35
    ## [55,] 8.362036849053477e-38
    ## [56,] 2.061188882308302e-40
    ## [57,] 3.423568350879544e-44
    ## [58,] 4.851540220766721e-43
    ## [59,] 3.000742928326458e-46
    ## [60,] 2.471609047074771e-32
    ## [61,] 6.724159356705446e-38
    ## [62,] 4.726127965427662e-40
    ## [63,] 5.530415369832340e-39
    ## [64,] 9.999999999999982e-01
    ## [65,] 9.999999999997478e-01
    ## 
    ## $p.m
    ## [1] 0.0002857142857142751
    ## 
    ## $p.u
    ## [1] 0.9997142857142858
    ## 
    ## $p.gamma.k.m
    ## $p.gamma.k.m[[1]]
    ## [1] 3.177066738665127e-40 6.711699231452565e-33 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 1.724397769645235e-33 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 1.588424794792025e-38 1.667831479885103e-33 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 8.379089063938958e-33 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 1.117609970183612e-40 8.379368433649732e-33 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 5.206447038972223e-36 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 6.891632761965861e-33 1.000000000000000e+00
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
    ##                        [,1]
    ##  [1,] 5.885137901486000e-61
    ##  [2,] 1.265222063269411e-54
    ##  [3,] 7.643060453271966e-50
    ##  [4,] 9.334612705556244e-55
    ##  [5,] 2.006810740010489e-48
    ##  [6,] 1.212291205588102e-43
    ##  [7,] 9.334618590694180e-55
    ##  [8,] 2.006812005232560e-48
    ##  [9,] 1.212291969894152e-43
    ## [10,] 6.479172504530400e-52
    ## [11,] 1.027683719999708e-45
    ## [12,] 3.770882997885017e-47
    ## [13,] 8.106869281222691e-41
    ## [14,] 5.981122776126547e-41
    ## [15,] 5.981126547009566e-41
    ## [16,] 3.427024612824547e-56
    ## [17,] 5.435720997049375e-50
    ## [18,] 7.059400286453420e-39
    ## [19,] 5.435814343235302e-50
    ## [20,] 7.059521515650434e-39
    ## [21,] 9.251958220305670e-57
    ## [22,] 1.201556822841596e-45
    ## [23,] 1.467484749707957e-50
    ## [24,] 1.018583324936728e-47
    ## [25,] 8.545581775450305e-46
    ## [26,] 5.385137082094387e-52
    ## [27,] 6.993706682253164e-41
    ## [28,] 8.541544797954238e-46
    ## [29,] 8.541550183091352e-46
    ## [30,] 6.225663142267825e-53
    ## [31,] 1.338430211480943e-46
    ## [32,] 8.085302426990765e-42
    ## [33,] 9.874731100804383e-47
    ## [34,] 1.282436673985086e-35
    ## [35,] 9.874737326467562e-47
    ## [36,] 2.122929953991777e-40
    ## [37,] 1.282437482515333e-35
    ## [38,] 6.854069714095379e-44
    ## [39,] 1.087147449152443e-37
    ## [40,] 3.989073440030927e-39
    ## [41,] 6.327205872874255e-33
    ## [42,] 3.625318756646165e-48
    ## [43,] 5.750340870745918e-42
    ## [44,] 9.787294070273884e-49
    ## [45,] 1.552396200569929e-42
    ## [46,] 5.696731327160470e-44
    ## [47,] 9.035780476660520e-38
    ## [48,] 6.720529153445091e-54
    ## [49,] 1.444819459478940e-47
    ## [50,] 8.727987594783073e-43
    ## [51,] 1.065965451854059e-47
    ## [52,] 1.065966123906978e-47
    ## [53,] 2.291677580442692e-41
    ## [54,] 1.384375975982456e-36
    ## [55,] 4.306157229572773e-40
    ## [56,] 6.207317830469166e-43
    ## [57,] 6.207424427081580e-43
    ## [58,] 6.149553563795900e-45
    ## [59,] 7.109391716475316e-46
    ## [60,] 9.233005510591611e-35
    ## [61,] 1.127644234617340e-39
    ## [62,] 1.127644945556516e-39
    ## [63,] 1.117659368967505e-41
    ## [64,] 4.999998423840327e-01
    ## [65,] 5.000001576159674e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.857213556579925e-01
    ##  [2,] 3.594125117546926e-03
    ##  [3,] 4.505078553559633e-04
    ##  [4,] 2.022428403632606e-03
    ##  [5,] 2.544038301651170e-05
    ##  [6,] 3.188840682325889e-06
    ##  [7,] 2.877437840616251e-01
    ##  [8,] 3.619565500563440e-03
    ##  [9,] 4.536966960382894e-04
    ## [10,] 1.978057100939920e-04
    ## [11,] 1.992058430507096e-04
    ## [12,] 8.173789673313659e-05
    ## [13,] 1.028191354571593e-06
    ## [14,] 5.785673374872222e-07
    ## [15,] 8.231646407062377e-05
    ## [16,] 4.746446558106715e-05
    ## [17,] 4.780043445932381e-05
    ## [18,] 7.536878426101946e-08
    ## [19,] 2.877915844960844e-01
    ## [20,] 4.537720648225502e-04
    ## [21,] 2.437197711605943e-04
    ## [22,] 3.842823409561059e-07
    ## [23,] 2.454448987296797e-04
    ## [24,] 1.687278932558082e-07
    ## [25,] 2.454856724090602e-04
    ## [26,] 2.011914889795296e-04
    ## [27,] 3.172263620523160e-07
    ## [28,] 1.424098597545468e-06
    ## [29,] 2.026155875770751e-04
    ## [30,] 3.760532140345427e-02
    ## [31,] 4.730421003999578e-04
    ## [32,] 5.929375722170663e-05
    ## [33,] 2.661826588318290e-04
    ## [34,] 4.197004402667613e-07
    ## [35,] 3.787150406228610e-02
    ## [36,] 4.763904457756811e-04
    ## [37,] 5.971345766197336e-05
    ## [38,] 2.603427134941560e-05
    ## [39,] 2.621855036392501e-05
    ## [40,] 1.075796336753791e-05
    ## [41,] 1.083411172064105e-05
    ## [42,] 6.247053109868903e-06
    ## [43,] 3.787779533406355e-02
    ## [44,] 3.207726739838497e-05
    ## [45,] 3.230432069843673e-05
    ## [46,] 2.647989188379415e-05
    ## [47,] 2.666732514494319e-05
    ## [48,] 3.447881014577337e-03
    ## [49,] 4.337133193375615e-05
    ## [50,] 5.436406662087488e-06
    ## [51,] 2.440521983443754e-05
    ## [52,] 3.472286234411773e-03
    ## [53,] 4.367832828481363e-05
    ## [54,] 5.474887311256265e-06
    ## [55,] 9.863544909642848e-07
    ## [56,] 5.768214632795182e-07
    ## [57,] 3.472863055875055e-03
    ## [58,] 2.427835026715343e-06
    ## [59,] 4.537941289528591e-04
    ## [60,] 7.155146640574935e-07
    ## [61,] 3.212101992454994e-06
    ## [62,] 4.570062309453139e-04
    ## [63,] 3.870855260633659e-07
    ## [64,] 1.694815960028141e-19
    ## [65,] 2.411322728412004e-17
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
    ##                weights           p.gamma.j.m           p.gamma.j.u
    ## 1  -137.43252227549266 5.885137901486000e-61 2.857213556579925e-01
    ## 43 -118.47589269248748 1.265222063269411e-54 3.594125117546926e-03
    ## 51 -105.39032149975104 7.643060453271966e-50 4.505078553559633e-04
    ## 19 -118.20499451737146 9.334612705556244e-55 2.022428403632606e-03
    ## 47  -99.24836493436626 2.006810740010489e-48 2.544038301651170e-05
    ## 57  -86.16279374162984 1.212291205588102e-43 3.188840682325889e-06
    ## 25 -123.16276536301579 9.334618590694180e-55 2.877437840616251e-01
    ## 48 -104.20613578001060 2.006812005232560e-48 3.619565500563440e-03
    ## 60  -91.12056458727417 1.212291969894152e-43 4.536966960382894e-04
    ## 13 -109.33760676222450 6.479172504530400e-52 1.978057100939920e-04
    ## 39  -95.06784984974763 1.027683719999708e-45 1.992058430507096e-04
    ## 16  -97.48219736839735 3.770882997885017e-47 8.173789673313659e-05
    ## 46  -78.52556778539217 8.106869281222691e-41 1.028191354571593e-06
    ## 24  -78.25466961027615 5.981122776126547e-41 5.785673374872222e-07
    ## 41  -83.21244045592049 5.981126547009566e-41 8.231646407062377e-05
    ## 11 -117.75754356285256 3.427024612824547e-56 4.746446558106715e-05
    ## 33 -103.48778665037570 5.435720997049375e-50 4.780043445932381e-05
    ## 63  -71.44558587463408 7.059400286453420e-39 7.536878426101946e-08
    ## 35 -112.19072658142881 5.435814343235302e-50 2.877915844960844e-01
    ## 64  -80.14852580568719 7.059521515650434e-39 4.537720648225502e-04
    ## 5  -120.70302360052064 9.251958220305670e-57 2.437197711605943e-04
    ## 55  -88.66082282477903 1.201556822841596e-45 3.842823409561059e-07
    ## 29 -106.43326668804379 1.467484749707957e-50 2.454448987296797e-04
    ## 15  -92.60810808725249 1.018583324936728e-47 1.687278932558082e-07
    ## 38  -95.46122790645680 8.545581775450305e-46 2.454856724090602e-04
    ## 8  -109.53952864719309 5.385137082094387e-52 2.011914889795296e-04
    ## 56  -77.49732787145149 6.993706682253164e-41 3.172263620523160e-07
    ## 23  -90.31200088907190 8.541544797954238e-46 1.424098597545468e-06
    ## 31  -95.26977173471623 8.541550183091352e-46 2.026155875770751e-04
    ## 3  -116.92772025121646 6.225663142267825e-53 3.760532140345427e-02
    ## 45  -97.97109066821127 1.338430211480943e-46 4.730421003999578e-04
    ## 53  -84.88551947547484 8.085302426990765e-42 5.929375722170663e-05
    ## 21  -97.70019249309527 9.874731100804383e-47 2.661826588318290e-04
    ## 58  -65.65799171735365 1.282436673985086e-35 4.197004402667613e-07
    ## 27 -102.65796333873959 9.874737326467562e-47 3.787150406228610e-02
    ## 50  -83.70133375573441 2.122929953991777e-40 4.763904457756811e-04
    ## 62  -70.61576256299799 1.282437482515333e-35 5.971345766197336e-05
    ## 14  -88.83280473794831 6.854069714095379e-44 2.603427134941560e-05
    ## 40  -74.56304782547144 1.087147449152443e-37 2.621855036392501e-05
    ## 18  -76.97739534412115 3.989073440030927e-39 1.075796336753791e-05
    ## 42  -62.70763843164429 6.327205872874255e-33 1.083411172064105e-05
    ## 12  -97.25274153857636 3.625318756646165e-48 6.247053109868903e-06
    ## 37  -91.68592455715260 5.750340870745918e-42 3.787779533406355e-02
    ## 6  -100.19822157624445 9.787294070273884e-49 3.207726739838497e-05
    ## 30  -85.92846466376758 1.552396200569929e-42 3.230432069843673e-05
    ## 10  -89.03472662291691 5.696731327160470e-44 2.647989188379415e-05
    ## 32  -74.76496971044004 9.035780476660520e-38 2.666732514494319e-05
    ## 2  -116.76443269186193 6.720529153445091e-54 3.447881014577337e-03
    ## 44  -97.80780310885675 1.444819459478940e-47 4.337133193375615e-05
    ## 52  -84.72223191612031 8.727987594783073e-43 5.436406662087488e-06
    ## 20  -97.53690493374073 1.065965451854059e-47 2.440521983443754e-05
    ## 26 -102.49467577938506 1.065966123906978e-47 3.472286234411773e-03
    ## 49  -83.53804619637987 2.291677580442692e-41 4.367832828481363e-05
    ## 61  -70.45247500364344 1.384375975982456e-36 5.474887311256265e-06
    ## 17  -76.81410778476662 4.306157229572773e-40 9.863544909642848e-07
    ## 34  -82.81969706674496 6.207317830469166e-43 5.768214632795182e-07
    ## 36  -91.52263699779807 6.207424427081580e-43 3.472863055875055e-03
    ## 9   -88.87143906356238 6.149553563795900e-45 2.427835026715343e-06
    ## 4   -96.25963066758572 7.109391716475316e-46 4.537941289528591e-04
    ## 54  -64.21742989184412 9.233005510591611e-35 7.155146640574935e-07
    ## 22  -77.03210290946454 1.127644234617340e-39 3.212101992454994e-06
    ## 28  -81.98987375510887 1.127644945556516e-39 4.570062309453139e-04
    ## 7   -79.53013199261372 1.117659368967505e-41 3.870855260633659e-07
    ## 59   42.52839511431205 4.999998423840327e-01 1.694815960028141e-19
    ## 65   37.57062426866772 5.000001576159674e-01 2.411322728412004e-17
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

    ##                95%  85%  75% Exact
    ## 1 Match Count   50   50   50    43
    ## 2  Match Rate 100% 100% 100%   86%
    ## 3         FDR   0%   0%   0%      
    ## 4         FNR   0%   0%   0%

where each column gives the match count, true match rate, false discovery rate (FDR) and false negative rate (FNR) under different cutoffs for matches based on the posterior probability of a match. Other arguments include:

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

    ##                95%  85%  75% Exact
    ## 1 Match Count   50   50   50    43
    ## 2  Match Rate 100% 100% 100%   86%
    ## 3         FDR   0%   0%   0%      
    ## 4         FNR   0%   0%   0%

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

    ##                95%  85%  75% Exact
    ## 1 Match Count   50   50   50    43
    ## 2  Match Rate 100% 100% 100%   86%
    ## 3         FDR   0%   0%   0%      
    ## 4         FNR   0%   0%   0%

If we assume that the first `fastLink` run was for a within-geography match and the second was an across-geography match, the call to `aggregateEM()` would be:

``` r
agg.out <- aggregateEM(em.list = list(link.1, link.2), within.geo = c(TRUE, FALSE))
summary(agg.out)
```

    ##                              95%  85%  75% Exact
    ## 1  Match Count          All   50   50   50    43
    ## 2              Within-State   24   24   24    20
    ## 3              Across-State   26   26   26    23
    ## 4   Match Rate          All 100% 100% 100%   86%
    ## 5              Within-State  48%  48%  48%   40%
    ## 6              Across-State  52%  52%  52%   46%
    ## 7          FDR          All   0%   0%   0%      
    ## 8              Within-State   0%   0%   0%      
    ## 9              Across-State   0%   0%   0%      
    ## 10         FNR          All   0%   0%   0%      
    ## 11             Within-State   0%   0%   0%      
    ## 12             Across-State   0%   0%   0%

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

    ##                95%  85%  75% Exact
    ## 1 Match Count   50   50   50    43
    ## 2  Match Rate 100% 100% 100%   86%
    ## 3         FDR   0%   0%   0%      
    ## 4         FNR   0%   0%   0%

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

    ##                95%  85%  75% Exact
    ## 1 Match Count   50   50   50    43
    ## 2  Match Rate 100% 100% 100%   86%
    ## 3         FDR   0%   0%   0%      
    ## 4         FNR   0%   0%   0%

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
