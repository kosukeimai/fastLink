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
    ##  [1,] 6.726338516239716e-169
    ##  [2,] 1.968013532180496e-166
    ##  [3,] 1.680295763347649e-140
    ##  [4,] 1.238692768975625e-144
    ##  [5,] 3.094358404314386e-116
    ##  [6,] 8.296669584565404e-147
    ##  [7,] 2.427465994319746e-144
    ##  [8,] 2.072577631824755e-118
    ##  [9,] 9.953565033282524e-160
    ## [10,] 1.227732444185553e-137
    ## [11,] 7.182658094458477e-137
    ## [12,] 1.322726565448536e-112
    ## [13,] 8.859521536828695e-115
    ## [14,] 4.869812970619062e-143
    ## [15,] 6.006719563445632e-121
    ## [16,]  1.500528914759000e-92
    ## [17,] 9.976796525768816e-125
    ## [18,]  2.492287430012088e-96
    ## [19,] 4.499703606489751e-165
    ## [20,] 1.316537603183890e-162
    ## [21,] 1.124063692014666e-136
    ## [22,] 5.550204462857007e-143
    ## [23,] 8.364129461482081e-143
    ## [24,] 1.540301109987223e-118
    ## [25,] 1.031681922295519e-120
    ## [26,] 6.696328002233358e-146
    ## [27,] 1.959232960472893e-143
    ## [28,] 1.672798885303372e-117
    ## [29,] 1.233166165370534e-121
    ## [30,] 8.259652815609666e-124
    ## [31,] 2.416635510239041e-121
    ## [32,]  2.063330532545025e-95
    ## [33,] 9.909155790107605e-137
    ## [34,] 1.222254741625188e-114
    ## [35,] 7.150611645885274e-114
    ## [36,]  8.819993523998181e-92
    ## [37,] 4.848085608844114e-120
    ## [38,] 9.932283631992761e-102
    ## [39,] 4.479627540175326e-142
    ## [40,] 5.525441437867042e-120
    ## [41,] 8.326811710710902e-120
    ## [42,]  1.027078926965384e-97
    ## [43,] 8.897034385463424e-145
    ## [44,] 2.603122638652995e-142
    ## [45,] 2.222553793294658e-116
    ## [46,] 1.638438525208423e-120
    ## [47,] 1.097413613669459e-122
    ## [48,]  2.741431227757439e-94
    ## [49,] 9.500615511862354e-113
    ## [50,]  7.945183010159628e-97
    ## [51,] 1.319646662626744e-100
    ## [52,] 1.106336638330167e-118
    ## [53,] 8.857339003734515e-122
    ## [54,]  2.212637554083307e-93
    ## [55,]  1.631128399173195e-97
    ## [56,]  1.092517347068471e-99
    ## [57,]  1.000000000000000e+00
    ## [58,]  9.999999999999627e-01
    ## 
    ## $p.m
    ## [1] 0.0002857142857142842
    ## 
    ## $p.u
    ## [1] 0.9997142857142857
    ## 
    ## $p.gamma.k.m
    ## $p.gamma.k.m[[1]]
    ## [1] 1.449981306143429e-122  5.292032030289467e-93  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 1.543700619127885e-94 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 2.444509483250389e-116  4.910509392409854e-94  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 5.482725985436894e-93 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 3.315264862720235e-121  5.783038837008493e-93  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 3.277353765076771e-94 1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 5.622846792831123e-93 1.000000000000000e+00
    ## 
    ## 
    ## $p.gamma.k.u
    ## $p.gamma.k.u[[1]]
    ## [1] 0.987384967133466684 0.011494712775078596 0.001120320091454701
    ## 
    ## $p.gamma.k.u[[2]]
    ## [1] 0.993302076356329500 0.006697923643670462
    ## 
    ## $p.gamma.k.u[[3]]
    ## [1] 0.9992397827950842970 0.0006516147470705930 0.0001086024578450986
    ## 
    ## $p.gamma.k.u[[4]]
    ## [1] 0.9998339060710195181 0.0001660939289805284
    ## 
    ## $p.gamma.k.u[[5]]
    ## [1] 0.9991597599314089306 0.0004515575878822535 0.0003886824807087740
    ## 
    ## $p.gamma.k.u[[6]]
    ## [1] 0.8836924835667334 0.1163075164332666
    ## 
    ## $p.gamma.k.u[[7]]
    ## [1] 0.98807659331237496 0.01192340668762504
    ## 
    ## 
    ## $p.gamma.j.m
    ##                         [,1]
    ##  [1,] 1.005969480687389e-165
    ##  [2,] 3.426460883210723e-165
    ##  [3,] 2.851329655545498e-140
    ##  [4,] 1.249190107317839e-143
    ##  [5,] 3.540716559289022e-118
    ##  [6,] 1.249190107317839e-143
    ##  [7,] 4.254901486169948e-143
    ##  [8,] 3.540716559289022e-118
    ##  [9,] 9.707467192993665e-160
    ## [10,] 1.205451280322474e-137
    ## [11,] 1.167511633223870e-137
    ## [12,] 1.449789492028309e-115
    ## [13,] 1.449789492028309e-115
    ## [14,] 1.209885481376701e-143
    ## [15,] 1.502408376534875e-121
    ## [16,]  4.258440878173093e-96
    ## [17,] 1.502408376534875e-121
    ## [18,]  4.258440878173093e-96
    ## [19,] 3.041362609098279e-165
    ## [20,] 1.035927054627354e-164
    ## [21,] 8.620467685225447e-140
    ## [22,] 3.776695175141565e-143
    ## [23,] 4.866165351925672e-143
    ## [24,] 6.042693873818818e-121
    ## [25,] 6.042693873818818e-121
    ## [26,] 1.318103230272816e-143
    ## [27,] 4.489628408485496e-143
    ## [28,] 3.736044583558422e-118
    ## [29,] 1.636790725057959e-121
    ## [30,] 1.636790725057959e-121
    ## [31,] 5.575118829232217e-121
    ## [32,]  4.639335510546786e-96
    ## [33,] 1.271951496591038e-137
    ## [34,] 1.579480547902744e-115
    ## [35,] 1.529768929055311e-115
    ## [36,]  1.899632393770296e-93
    ## [37,] 1.585290599644335e-121
    ## [38,]  1.968577946267692e-99
    ## [39,] 3.985041252687040e-143
    ## [40,] 4.948533932369688e-121
    ## [41,] 6.376046582478887e-121
    ## [42,]  7.917630174215252e-99
    ## [43,] 1.605687771500473e-143
    ## [44,] 5.469178186138129e-143
    ## [45,] 4.551176997236172e-118
    ## [46,] 1.993906692108620e-121
    ## [47,] 1.993906692108620e-121
    ## [48,]  5.651548472141323e-96
    ## [49,] 1.863534817449074e-115
    ## [50,]  2.398083445189123e-99
    ## [51,]  2.398083445189123e-99
    ## [52,] 7.767176191416143e-121
    ## [53,] 2.103903029919092e-121
    ## [54,]  5.963323159168848e-96
    ## [55,]  2.612579111182405e-99
    ## [56,]  2.612579111182405e-99
    ## [57,]  5.000000000000000e-01
    ## [58,]  5.000000000000000e-01
    ## 
    ## $p.gamma.j.u
    ##                        [,1]
    ##  [1,] 2.863757478838720e-01
    ##  [2,] 3.333863768687974e-03
    ##  [3,] 3.249315259387583e-04
    ##  [4,] 1.931056964827189e-03
    ##  [5,] 2.191041982055012e-06
    ##  [6,] 2.883068048486992e-01
    ##  [7,] 3.356344306575284e-03
    ##  [8,] 3.271225679208135e-04
    ##  [9,] 1.867486300460568e-04
    ## [10,] 1.880078925547961e-04
    ## [11,] 3.112477167434274e-05
    ## [12,] 2.098770847899037e-07
    ## [13,] 3.133464875913262e-05
    ## [14,] 4.757317474627726e-05
    ## [15,] 4.789396486594202e-05
    ## [16,] 5.434209845680946e-08
    ## [17,] 2.883546988135652e-01
    ## [18,] 3.271769100192702e-04
    ## [19,] 1.294238890798554e-04
    ## [20,] 1.506697469301733e-06
    ## [21,] 1.468486842283143e-07
    ## [22,] 1.302966057965099e-04
    ## [23,] 1.114028412332929e-04
    ## [24,] 7.511991991456039e-07
    ## [25,] 1.121540404324386e-04
    ## [26,] 3.769145106752195e-02
    ## [27,] 4.387877256779533e-04
    ## [28,] 4.276598420332113e-05
    ## [29,] 2.541567840021710e-04
    ## [30,] 3.794560785152411e-02
    ## [31,] 4.417465100722750e-04
    ## [32,] 4.305435901251417e-05
    ## [33,] 2.457899072571613e-05
    ## [34,] 2.474472903135143e-05
    ## [35,] 4.096498454286010e-06
    ## [36,] 4.124121505225226e-06
    ## [37,] 6.261361170859698e-06
    ## [38,] 3.795191143360645e-02
    ## [39,] 1.703417352296152e-05
    ## [40,] 1.714903645973134e-05
    ## [41,] 1.466232657672632e-05
    ## [42,] 1.476119594002186e-05
    ## [43,] 3.455779167934082e-03
    ## [44,] 4.023070055930163e-05
    ## [45,] 3.921042918758394e-06
    ## [46,] 2.330262419375648e-05
    ## [47,] 3.479081792127839e-03
    ## [48,] 3.947482857522776e-06
    ## [49,] 3.755916426362859e-07
    ## [50,] 5.779503581448713e-07
    ## [51,] 3.479659742485983e-03
    ## [52,] 1.344330380025045e-06
    ## [53,] 4.548336665057549e-04
    ## [54,] 5.160695289252128e-07
    ## [55,] 3.066983590733346e-06
    ## [56,] 4.579006500964880e-04
    ## [57,] 2.444122297210018e-20
    ## [58,] 3.649074589734563e-18
    ## 
    ## $patterns.w
    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 gamma.7 counts
    ## 1        0       0       0       0       0       0       0 101069
    ## 40       1       0       0       0       0       0       0    133
    ## 46       2       0       0       0       0       0       0   1181
    ## 17       0       2       0       0       0       0       0    691
    ## 51       2       2       0       0       0       0       0      9
    ## 23       0      NA       0       0       0       0       0  48474
    ## 44       1      NA       0       0       0       0       0     48
    ## 53       2      NA       0       0       0       0       0    559
    ## 12       0       0       1       0       0       0       0     12
    ## 36       0      NA       1       0       0       0       0      3
    ## 14       0       0       2       0       0       0       0     65
    ## 22       0       2       2       0       0       0       0      1
    ## 38       0      NA       2       0       0       0       0     36
    ## 10       0       0       0       2       0       0       0     15
    ## 31       0      NA       0       2       0       0       0      8
    ## 56       2      NA       0       2       0       0       0      1
    ## 33       0      NA       0      NA       0       0       0    323
    ## 57       2      NA       0      NA       0       0       0      4
    ## 5        0       0       0       0       1       0       0     40
    ## 43       1       0       0       0       1       0       0      1
    ## 50       2       0       0       0       1       0       0      3
    ## 27       0      NA       0       0       1       0       0     17
    ## 7        0       0       0       0       2       0       0     43
    ## 21       0       2       0       0       2       0       0      1
    ## 29       0      NA       0       0       2       0       0     27
    ## 3        0       0       0       0       0       2       0  13032
    ## 42       1       0       0       0       0       2       0      9
    ## 48       2       0       0       0       0       2       0    153
    ## 19       0       2       0       0       0       2       0     75
    ## 25       0      NA       0       0       0       2       0   6701
    ## 45       1      NA       0       0       0       2       0      3
    ## 55       2      NA       0       0       0       2       0     74
    ## 13       0       0       1       0       0       2       0      3
    ## 37       0      NA       1       0       0       2       0      1
    ## 16       0       0       2       0       0       2       0      8
    ## 39       0      NA       2       0       0       2       0      3
    ## 11       0       0       0       2       0       2       0      4
    ## 35       0      NA       0      NA       0       2       0     20
    ## 6        0       0       0       0       1       2       0      4
    ## 28       0      NA       0       0       1       2       0      3
    ## 9        0       0       0       0       2       2       0      3
    ## 30       0      NA       0       0       2       2       0      4
    ## 2        0       0       0       0       0       0       2   1203
    ## 41       1       0       0       0       0       0       2      2
    ## 47       2       0       0       0       0       0       2     19
    ## 18       0       2       0       0       0       0       2     10
    ## 24       0      NA       0       0       0       0       2    593
    ## 54       2      NA       0       0       0       0       2      5
    ## 15       0       0       2       0       0       0       2      1
    ## 32       0      NA       0       2       0       0       2      1
    ## 34       0      NA       0      NA       0       0       2      3
    ## 8        0       0       0       0       2       0       2      1
    ## 4        0       0       0       0       0       2       2    150
    ## 49       2       0       0       0       0       2       2      3
    ## 20       0       2       0       0       0       2       2      3
    ## 26       0      NA       0       0       0       2       2     92
    ## 52       2       2       2       2       2       2       2     43
    ## 58       2      NA       2       2       2       2       2      7
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -378.67013808343148 1.005969480687389e-165 2.863757478838720e-01
    ## 40 -372.99138907128992 3.426460883210723e-165 3.333863768687974e-03
    ## 46 -313.28223150062718 2.851329655545498e-140 3.249315259387583e-04
    ## 17 -322.79748509516571 1.249190107317839e-143 1.931056964827189e-03
    ## 51 -257.40957851236141 3.540716559289022e-118 2.191041982055012e-06
    ## 23 -327.80344279971081 1.249190107317839e-143 2.883068048486992e-01
    ## 44 -322.12469378756924 4.254901486169948e-143 3.356344306575284e-03
    ## 53 -262.41553621690656 3.540716559289022e-118 3.271225679208135e-04
    ## 12 -357.55497240623953 9.707467192993665e-160 1.867486300460568e-04
    ## 36 -306.68827712251891 1.205451280322474e-137 1.880078925547961e-04
    ## 14 -304.92177652648513 1.167511633223870e-137 3.112477167434274e-05
    ## 22 -249.04912353821933 1.449789492028309e-115 2.098770847899037e-07
    ## 38 -254.05508124276449 1.449789492028309e-115 3.133464875913262e-05
    ## 10 -319.12590107517457 1.209885481376701e-143 4.757317474627726e-05
    ## 31 -268.25920579145395 1.502408376534875e-121 4.789396486594202e-05
    ## 56 -202.87129920864970  4.258440878173093e-96 5.434209845680946e-08
    ## 33 -276.96216288385511 1.502408376534875e-121 2.883546988135652e-01
    ## 57 -211.57425630105084  4.258440878173093e-96 3.271769100192702e-04
    ## 5  -369.86181712362770 3.041362609098279e-165 1.294238890798554e-04
    ## 43 -364.18306811148608 1.035927054627354e-164 1.506697469301733e-06
    ## 50 -304.47391054082345 8.620467685225447e-140 1.468486842283143e-07
    ## 27 -318.99512183990709 3.776695175141565e-143 1.302966057965099e-04
    ## 7  -318.58500434727739 4.866165351925672e-143 1.114028412332929e-04
    ## 21 -262.71235135901156 6.042693873818818e-121 7.511991991456039e-07
    ## 29 -267.71830906355672 6.042693873818818e-121 1.121540404324386e-04
    ## 3  -325.71515256933407 1.318103230272816e-143 3.769145106752195e-02
    ## 42 -320.03640355719244 4.489628408485496e-143 4.387877256779533e-04
    ## 48 -260.32724598652976 3.736044583558422e-118 4.276598420332113e-05
    ## 19 -269.84249958106824 1.636790725057959e-121 2.541567840021710e-04
    ## 25 -274.84845728561339 1.636790725057959e-121 3.794560785152411e-02
    ## 45 -269.16970827347177 5.575118829232217e-121 4.417465100722750e-04
    ## 55 -209.46055070280914  4.639335510546786e-96 4.305435901251417e-05
    ## 13 -304.59998689214211 1.271951496591038e-137 2.457899072571613e-05
    ## 37 -253.73329160842150 1.579480547902744e-115 2.474472903135143e-05
    ## 16 -251.96679101238772 1.529768929055311e-115 4.096498454286010e-06
    ## 39 -201.10009572866707  1.899632393770296e-93 4.124121505225226e-06
    ## 11 -266.17091556107715 1.585290599644335e-121 6.261361170859698e-06
    ## 35 -224.00717736975770  1.968577946267692e-99 3.795191143360645e-02
    ## 6  -316.90683160953023 3.985041252687040e-143 1.703417352296152e-05
    ## 28 -266.04013632580967 4.948533932369688e-121 1.714903645973134e-05
    ## 9  -265.63001883317992 6.376046582478887e-121 1.466232657672632e-05
    ## 30 -214.76332354945930  7.917630174215252e-99 1.476119594002186e-05
    ## 2  -323.12840878703622 1.605687771500473e-143 3.455779167934082e-03
    ## 41 -317.44965977489466 5.469178186138129e-143 4.023070055930163e-05
    ## 47 -257.74050220423192 4.551176997236172e-118 3.921042918758394e-06
    ## 18 -267.25575579877045 1.993906692108620e-121 2.330262419375648e-05
    ## 24 -272.26171350331560 1.993906692108620e-121 3.479081792127839e-03
    ## 54 -206.87380692051133  5.651548472141323e-96 3.947482857522776e-06
    ## 15 -249.38004723008990 1.863534817449074e-115 3.755916426362859e-07
    ## 32 -212.71747649505872  2.398083445189123e-99 5.779503581448713e-07
    ## 34 -221.42043358745988  2.398083445189123e-99 3.479659742485983e-03
    ## 8  -263.04327505088213 7.767176191416143e-121 1.344330380025045e-06
    ## 4  -270.17342327293881 2.103903029919092e-121 4.548336665057549e-04
    ## 49 -204.78551669013453  5.963323159168848e-96 5.160695289252128e-07
    ## 20 -214.30077028467304  2.612579111182405e-99 3.066983590733346e-06
    ## 26 -219.30672798921816  2.612579111182405e-99 4.579006500964880e-04
    ## 52   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
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
    ## 1 Match Rate          All 29.762% 29.762% 29.762% 25.595%
    ## 2            Within-State 14.286% 14.286% 14.286% 11.905%
    ## 3            Across-State 15.476% 15.476% 15.476%  13.69%
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
