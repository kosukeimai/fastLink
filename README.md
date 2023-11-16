fastLink: Fast Probabilistic Record Linkage 
===========================================================================================================================================================================================================================================================================================================================================================
[![CRAN Version](https://www.r-pkg.org/badges/version-last-release/fastLink)](https://CRAN.R-project.org/package=fastLink) [![Build Status](https://travis-ci.org/kosukeimai/fastLink.svg?branch=master)](https://travis-ci.org/kosukeimai/fastLink) ![CRAN downloads](http://cranlogs.r-pkg.org/badges/grand-total/fastLink)

Authors:

-   [Ted Enamorado](https://www.tedenamorado.com/)
-   [Ben Fifield](https://www.benfifield.com/)
-   [Kosuke Imai](https://imai.fas.harvard.edu/)

Suggested citation: 

Enamorado, Ted, Benjamin Fifield, and Kosuke Imai. 2017. fastLink: Fast Probabilistic Record Linkage with Missing Data. Version 0.6.

For a detailed description of the method see:

-   [Using a Probabilistic Model to Assist Merging of Large-scale Administrative Records](https://imai.fas.harvard.edu/research/files/linkage.pdf) *American Political Science Review*

Applications of the method:

-   [Validating Self-reported Turnout by Linking Public Opinion Surveys with Administrative Records](https://imai.fas.harvard.edu/research/files/turnout.pdf) *Public Opinion Quarterly*

Technical reports:

-   [User’s Guide and Codebook for the ANES 2016 Time Series Voter Validation Supplemental Data](https://www.electionstudies.org/wp-content/uploads/2018/03/anes_timeseries_2016voteval_userguidecodebook.pdf)

-   [User’s Guide and Codebook for the CCES 2016 Voter Validation Supplemental Data](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/2NNA4L)

Data:

-   [ANES 2016 Time Series Voter Validation Supplemental Data](https://www.electionstudies.org/studypages/download/datacenter_all_NoData.php)

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
    ##                        [,1]
    ##  [1,] 8.419262663555981e-51
    ##  [2,] 1.173389252413153e-44
    ##  [3,] 2.646379720944128e-39
    ##  [4,] 7.292362103666283e-44
    ##  [5,] 1.016333574457344e-37
    ##  [6,] 2.292167373808125e-32
    ##  [7,] 4.884447551998586e-46
    ##  [8,] 6.807434915054858e-40
    ##  [9,] 1.535301066870949e-34
    ## [10,] 1.079286196570246e-42
    ## [11,] 6.261494659814906e-38
    ## [12,] 6.134545488083132e-38
    ## [13,] 8.549691382494763e-32
    ## [14,] 5.313449505995162e-31
    ## [15,] 3.558965540010417e-33
    ## [16,] 1.439847112134032e-42
    ## [17,] 8.353294086616594e-38
    ## [18,] 2.625644187298435e-26
    ## [19,] 1.387480211241783e-41
    ## [20,] 4.361188908068464e-30
    ## [21,] 1.930419723058928e-46
    ## [22,] 2.690418206678263e-40
    ## [23,] 6.067780294024032e-35
    ## [24,] 1.119935826618175e-41
    ## [25,] 2.474652999844177e-38
    ## [26,] 3.181298971380373e-37
    ## [27,] 1.707446874189434e-41
    ## [28,] 1.478908709341025e-34
    ## [29,] 9.905778021278484e-37
    ## [30,] 2.238814676230162e-43
    ## [31,] 3.120227012995646e-37
    ## [32,] 7.037140893315709e-32
    ## [33,] 1.939154051190646e-36
    ## [34,] 1.298851609895281e-38
    ## [35,] 1.810204266613223e-32
    ## [36,] 4.082607584891215e-27
    ## [37,] 2.869992151680382e-35
    ## [38,] 1.665030145717010e-30
    ## [39,] 1.631272359534779e-30
    ## [40,] 9.463850460044200e-26
    ## [41,] 3.828780470440601e-35
    ## [42,] 3.689528625057814e-34
    ## [43,] 5.133290384176191e-39
    ## [44,] 2.978085926600283e-34
    ## [45,] 4.540370426219810e-34
    ## [46,] 2.634102545525005e-29
    ## [47,] 3.394906490426527e-42
    ## [48,] 4.731467526316184e-36
    ## [49,] 1.067101960086819e-30
    ## [50,] 2.940505413073872e-35
    ## [51,] 1.969559967312416e-37
    ## [52,] 2.744967807729040e-31
    ## [53,] 6.190807633595693e-26
    ## [54,] 2.473638028120859e-29
    ## [55,] 3.368305924680413e-29
    ## [56,] 5.594748332146245e-33
    ## [57,] 7.784047973023133e-38
    ## [58,] 9.027591582450696e-35
    ## [59,] 2.837592345963584e-23
    ## [60,] 7.819267479111464e-28
    ## [61,] 5.237370464306236e-30
    ## [62,] 2.069901075532344e-30
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
    ## [1] 1.045899998017705e-32 5.738488046606488e-27 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 1.97971724297674e-24 1.00000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 3.330463517437124e-32 1.715455616718354e-24 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 1.720608579049464e-24 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 4.145053488044031e-32 1.721132582175325e-24 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 6.717885850595282e-27 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 1.233034196225684e-26 1.000000000000000e+00
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
    ##  [1,] 1.256399674811630e-47
    ##  [2,] 2.060546975326111e-43
    ##  [3,] 9.431785057462963e-39
    ##  [4,] 7.338045922313829e-43
    ##  [5,] 1.203469615056597e-38
    ##  [6,] 5.508666809503376e-34
    ##  [7,] 7.338171562281326e-43
    ##  [8,] 1.203490220526336e-38
    ##  [9,] 5.508761127353962e-34
    ## [10,] 1.050523991385343e-42
    ## [11,] 6.135726897759652e-38
    ## [12,] 2.985532184605382e-38
    ## [13,] 4.896395180657548e-34
    ## [14,] 1.743710438039141e-33
    ## [15,] 1.743740293360991e-33
    ## [16,] 3.569406544797919e-43
    ## [17,] 2.084759979358002e-38
    ## [18,] 1.565028104982090e-29
    ## [19,] 2.084833361073622e-38
    ## [20,] 1.565083192593362e-29
    ## [21,] 3.364320242426266e-46
    ## [22,] 5.517623124663102e-42
    ## [23,] 2.525593250873270e-37
    ## [24,] 1.964976561545296e-41
    ## [25,] 2.813037284415120e-41
    ## [26,] 5.582655917033155e-37
    ## [27,] 9.919085761919092e-42
    ## [28,] 5.793276477824970e-37
    ## [29,] 5.793375668682601e-37
    ## [30,] 4.397222945753068e-41
    ## [31,] 7.211625904045630e-37
    ## [32,] 3.300992710007279e-32
    ## [33,] 2.568213328408084e-36
    ## [34,] 2.568257300637548e-36
    ## [35,] 4.212047263925987e-32
    ## [36,] 1.927989263090582e-27
    ## [37,] 3.676686879655797e-36
    ## [38,] 2.147418504207121e-31
    ## [39,] 1.044894462377137e-31
    ## [40,] 6.102846875179852e-27
    ## [41,] 1.249242313267853e-36
    ## [42,] 7.296624853678739e-32
    ## [43,] 1.177464978974648e-39
    ## [44,] 6.877142837202175e-35
    ## [45,] 3.471541133576188e-35
    ## [46,] 2.027600367495960e-30
    ## [47,] 6.113514608419635e-41
    ## [48,] 1.002641459365209e-36
    ## [49,] 4.589411863778055e-32
    ## [50,] 3.570619432868422e-36
    ## [51,] 3.570680568014515e-36
    ## [52,] 5.856062518784984e-32
    ## [53,] 2.680507827369658e-27
    ## [54,] 1.452729970439422e-31
    ## [55,] 1.014423263900051e-31
    ## [56,] 1.014458970705730e-31
    ## [57,] 1.637044434332457e-39
    ## [58,] 2.139644513945760e-34
    ## [59,] 1.606229893201929e-25
    ## [60,] 1.249666807110153e-29
    ## [61,] 1.249688203555295e-29
    ## [62,] 5.729426307709991e-33
    ## [63,] 4.999957196066489e-01
    ## [64,] 5.000042803933511e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.857222021425374e-01
    ##  [2,] 3.362254983728925e-03
    ##  [3,] 6.823889211463050e-04
    ##  [4,] 1.926648248471532e-03
    ##  [5,] 2.267196118026699e-05
    ##  [6,] 4.601404475550817e-06
    ##  [7,] 2.876488503910090e-01
    ##  [8,] 3.384926944909193e-03
    ##  [9,] 6.869903256218560e-04
    ## [10,] 1.863629534853647e-04
    ## [11,] 1.876196141691340e-04
    ## [12,] 9.318147878207447e-05
    ## [13,] 1.096519238186349e-06
    ## [14,] 6.283303556365234e-07
    ## [15,] 9.380980913771111e-05
    ## [16,] 4.746460468440405e-05
    ## [17,] 4.778466240758362e-05
    ## [18,] 1.141238727097045e-07
    ## [19,] 2.876966350534165e-01
    ## [20,] 6.871044494945657e-04
    ## [21,] 3.336843317846764e-04
    ## [22,] 3.926652528652952e-06
    ## [23,] 7.969366379738929e-07
    ## [24,] 3.359343926079321e-04
    ## [25,] 2.176463611748304e-07
    ## [26,] 3.359901985376971e-04
    ## [27,] 1.112281407071491e-04
    ## [28,] 7.500204774680678e-07
    ## [29,] 1.119781611846171e-04
    ## [30,] 3.760543117422202e-02
    ## [31,] 4.425244080882689e-04
    ## [32,] 8.981286513890621e-05
    ## [33,] 2.535765073961155e-04
    ## [34,] 3.785900768161813e-02
    ## [35,] 4.455083864748133e-04
    ## [36,] 9.041848065640018e-05
    ## [37,] 2.452822765667481e-05
    ## [38,] 2.469362350795442e-05
    ## [39,] 1.226411409675275e-05
    ## [40,] 1.234681202420250e-05
    ## [41,] 6.247071145631768e-06
    ## [42,] 3.786529687727697e-02
    ## [43,] 4.391798424745776e-05
    ## [44,] 4.421412681808147e-05
    ## [45,] 1.463933204572155e-05
    ## [46,] 1.473804626265387e-05
    ## [47,] 3.447889746981670e-03
    ## [48,] 4.057327151410437e-05
    ## [49,] 8.234578016798621e-06
    ## [50,] 2.324940341398909e-05
    ## [51,] 3.471139150395658e-03
    ## [52,] 4.084686041238120e-05
    ## [53,] 8.290104451895364e-06
    ## [54,] 1.124446972941322e-06
    ## [55,] 5.766308895235820e-07
    ## [56,] 3.471715781285182e-03
    ## [57,] 4.026662183272914e-06
    ## [58,] 4.537952584858708e-04
    ## [59,] 1.083796969704861e-06
    ## [60,] 3.059978655387542e-06
    ## [61,] 4.568552371412581e-04
    ## [62,] 5.299706024223191e-07
    ## [63,] 1.541304880963882e-19
    ## [64,] 2.301170322413746e-17
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
    ##                weights           p.gamma.j.m           p.gamma.j.u
    ## 1  -106.74051387948300 1.256399674811630e-47 2.857222021425374e-01
    ## 43  -92.59304412518260 2.060546975326111e-43 3.362254983728925e-03
    ## 52  -80.26682245539131 9.431785057462963e-39 6.823889211463050e-04
    ## 19  -90.76611297005071 7.338045922313829e-43 1.926648248471532e-03
    ## 48  -76.61864321575030 1.203469615056597e-38 2.267196118026699e-05
    ## 57  -64.29242154595902 5.508666809503376e-34 4.601404475550817e-06
    ## 25  -95.77205448087018 7.338171562281326e-43 2.876488503910090e-01
    ## 49  -81.62458472656978 1.203490220526336e-38 3.384926944909193e-03
    ## 59  -69.29836305677848 5.508761127353962e-34 6.869903256218560e-04
    ## 13  -88.07147040378285 1.050523991385343e-42 1.863629534853647e-04
    ## 39  -77.10301100517003 6.135726897759652e-38 1.876196141691340e-04
    ## 16  -77.12349393498485 2.985532184605382e-38 9.318147878207447e-05
    ## 47  -62.97602418068444 4.896395180657548e-34 1.096519238186349e-06
    ## 24  -61.14909302555255 1.743710438039141e-33 6.283303556365234e-07
    ## 41  -66.15503453637201 1.743740293360991e-33 9.380980913771111e-05
    ## 11  -87.78323336148534 3.569406544797919e-43 4.746460468440405e-05
    ## 33  -76.81477396287252 2.084759979358002e-38 4.778466240758362e-05
    ## 62  -50.34108253878082 1.565028104982090e-29 1.141238727097045e-07
    ## 35  -85.51769589994474 2.084833361073622e-38 2.876966350534165e-01
    ## 63  -59.04400447585304 1.565083192593362e-29 6.871044494945657e-04
    ## 5   -96.70037321692315 3.364320242426266e-46 3.336843317846764e-04
    ## 46  -82.55290346262274 5.517623124663102e-42 3.926652528652952e-06
    ## 56  -70.22668179283144 2.525593250873270e-37 7.969366379738929e-07
    ## 29  -85.73191381831032 1.964976561545296e-41 3.359343926079321e-04
    ## 15  -78.03132974122300 2.813037284415120e-41 2.176463611748304e-07
    ## 38  -75.47755523738486 5.582655917033155e-37 3.359901985376971e-04
    ## 9   -85.31018600554725 9.919085761919092e-42 1.112281407071491e-04
    ## 23  -69.33578509611496 5.793276477824970e-37 7.500204774680678e-07
    ## 31  -74.34172660693443 5.793375668682601e-37 1.119781611846171e-04
    ## 3   -89.64440882688763 4.397222945753068e-41 3.760543117422202e-02
    ## 45  -75.49693907258722 7.211625904045630e-37 4.425244080882689e-04
    ## 54  -63.17071740279593 3.300992710007279e-32 8.981286513890621e-05
    ## 21  -73.67000791745534 2.568213328408084e-36 2.535765073961155e-04
    ## 27  -78.67594942827481 2.568257300637548e-36 3.785900768161813e-02
    ## 51  -64.52847967397440 4.212047263925987e-32 4.455083864748133e-04
    ## 61  -52.20225800418311 1.927989263090582e-27 9.041848065640018e-05
    ## 14  -70.97536535118748 3.676686879655797e-36 2.452822765667481e-05
    ## 40  -60.00690595257466 2.147418504207121e-31 2.469362350795442e-05
    ## 18  -60.02738888238947 1.044894462377137e-31 1.226411409675275e-05
    ## 42  -49.05892948377664 6.102846875179852e-27 1.234681202420250e-05
    ## 12  -70.68712830888997 1.249242313267853e-36 6.247071145631768e-06
    ## 37  -68.42159084734936 7.296624853678739e-32 3.786529687727697e-02
    ## 7   -79.60426816432776 1.177464978974648e-39 4.391798424745776e-05
    ## 30  -68.63580876571494 6.877142837202175e-35 4.421412681808147e-05
    ## 10  -68.21408095295187 3.471541133576188e-35 1.463933204572155e-05
    ## 32  -57.24562155433905 2.027600367495960e-30 1.473804626265387e-05
    ## 2   -86.92549407999672 6.113514608419635e-41 3.447889746981670e-03
    ## 44  -72.77802432569632 1.002641459365209e-36 4.057327151410437e-05
    ## 53  -60.45180265590503 4.589411863778055e-32 8.234578016798621e-06
    ## 20  -70.95109317056443 3.570619432868422e-36 2.324940341398909e-05
    ## 26  -75.95703468138390 3.570680568014515e-36 3.471139150395658e-03
    ## 50  -61.80956492708349 5.856062518784984e-32 4.084686041238120e-05
    ## 60  -49.48334325729219 2.680507827369658e-27 8.290104451895364e-06
    ## 17  -57.30847413549856 1.452729970439422e-31 1.124446972941322e-06
    ## 34  -56.99975416338624 1.014423263900051e-31 5.766308895235820e-07
    ## 36  -65.70267610045846 1.014458970705730e-31 3.471715781285182e-03
    ## 6   -76.88535341743686 1.637044434332457e-39 4.026662183272914e-06
    ## 4   -69.82938902740135 2.139644513945760e-34 4.537952584858708e-04
    ## 55  -43.35569760330964 1.606229893201929e-25 1.083796969704861e-06
    ## 22  -53.85498811796905 1.249666807110153e-29 3.059978655387542e-06
    ## 28  -58.86092962878852 1.249688203555295e-29 4.568552371412581e-04
    ## 8   -59.78924836484148 5.729426307709991e-33 5.299706024223191e-07
    ## 58   42.62333164255424 4.999957196066489e-01 1.541304880963882e-19
    ## 64   37.61739013173478 5.000042803933511e-01 2.301170322413746e-17
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

`blockData()` also implements other methods of blocking other than exact blocking. Analysts commonly use *window blocking* for numeric variables, where a given observation in dataset A will be compared to all observations in dataset B where the value of the blocking variable is within ±*K* of the value of the same variable in dataset A. The value of *K* is the size of the window --- for instance, if we wanted to compare observations where birth year is within ±1 year, the window size is 1. Below, we block `dfA` and `dfB` on gender and birth year, using exact blocking on gender and window blocking with a window size of 1 on birth year:

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
    ## 2              Within-State      20      20      20      20
    ## 3              Across-State      30      30      30      30
    ## 4   Match Rate          All  29.94%  29.94%  29.94%  29.94%
    ## 5              Within-State 11.976% 11.976% 11.976% 11.976%
    ## 6              Across-State 17.964% 17.964% 17.964% 17.964%
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
    ## 374  alejandro       <NA>    white     3127  e juana ave Pleasanton
    ## 3741 alejandro       <NA>    white     3127  e juana ave Pleasanton
    ##      birthyear gender dedupe.ids
    ## 374       1993      M        501
    ## 3741      1993      M        501
