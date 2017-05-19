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

-   `varnames` should be a vector of variable names to be used for matching. These variable names should exist in both `dfA` and `dfB`

-   `stringdist.match` should be a vector of variable names present in `varnames`. For those variables included in `stringdist.match`, agreement will be calculated using Jaro-Winkler distance.

-   `partial.match` is another vector of variable names present in both `stringdist.match` and `varnames`. A variable included in `partial.match` will have a partial agreement category calculated in addition to disagreement and absolute agreement, as a function of Jaro-Winkler distance.

Other arguments that can be provided include:

-   `priors.obj`: The output from `calcMoversPriors()`, allowing the inclusion of auxiliary information on moving behavior to aid matching. We will discuss this option further at the end of this vignette.

-   `w.lambda`: The user-specified weighting of the MLE and prior estimate for the *λ* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `w.pi`: The user-specified weighting of the MLE and prior estimate for the *π* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `address.field`: The name of the address field, to be specified when providing a prior on the probability of moving in-state through `priors.obj`. The variable listed in `address.field` must be listed in `varnames`. We will discuss this option further at the end of this vignette.

-   `gender.field`: The name of the gender field, if matching on gender. If provided, the EM algorithm will implement a prior that enforces near-perfect blocking on gender, so that no matches that disagree on gender will be in the matched set. Can be used in conjunction with movers priors, if the user does not want to specify the same prior for both genders when blocking.

-   `estimate.only`: Whether to stop running the algorithm after running the EM estimation step. Can be used when running the algorithm on a random sample, and then applying those estimates to the full data set.

-   `em.obj`: An EM object, either from an `estimate.only = TRUE` run of `fastLink` or from `emlinkMARmov()`. If provided, the algorithm will skip the EM estimation step and proceed to apply the estimates from the EM object to the full data set. To be used when the EM has been estimated on a random sample of data and should be applied to the full data set.

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
    ##  [1,] 8.423399523083861e-219
    ##  [2,] 2.552509514529968e-215
    ##  [3,] 1.086335889365416e-182
    ##  [4,] 2.590615387887478e-188
    ##  [5,] 3.341024563410653e-152
    ##  [6,] 1.735174405818792e-190
    ##  [7,] 5.258030523286990e-187
    ##  [8,] 2.237792741735180e-154
    ##  [9,] 1.806927705507407e-209
    ## [10,] 3.722172620649529e-181
    ## [11,] 2.535576040070425e-180
    ## [12,] 7.798160693392347e-150
    ## [13,] 5.223148488541379e-152
    ## [14,] 1.185490854055395e-186
    ## [15,] 2.442046566415371e-158
    ## [16,] 3.149420636322098e-122
    ## [17,] 4.056091089693347e-162
    ## [18,] 5.230996474990890e-126
    ## [19,] 1.433279928089470e-213
    ## [20,] 4.343211601690741e-210
    ## [21,] 1.848450166852156e-177
    ## [22,] 2.952478557830702e-185
    ## [23,] 3.944494164800863e-185
    ## [24,] 1.213128648684224e-154
    ## [25,] 8.125443058835993e-157
    ## [26,] 3.528343429996265e-188
    ## [27,] 1.069179984982842e-184
    ## [28,] 4.550379080925206e-152
    ## [29,] 1.085141546290278e-157
    ## [30,] 7.268195219626714e-160
    ## [31,] 2.202452513467920e-156
    ## [32,] 9.373532973660953e-124
    ## [33,] 7.568751168377665e-179
    ## [34,] 1.559121501406908e-150
    ## [35,] 1.062086992041795e-149
    ## [36,] 2.187841334479752e-121
    ## [37,] 4.965713492235800e-156
    ## [38,] 1.698991281200261e-131
    ## [39,] 6.003637609449217e-183
    ## [40,] 1.236716635982800e-154
    ## [41,] 1.652246225872856e-154
    ## [42,] 3.403537200614500e-126
    ## [43,] 1.188495489625814e-186
    ## [44,] 3.601450978233286e-183
    ## [45,] 1.532760379216541e-150
    ## [46,] 3.655216276304682e-156
    ## [47,] 2.448235951979141e-158
    ## [48,] 3.157402866836770e-122
    ## [49,] 3.577558774184457e-148
    ## [50,] 3.445593814809507e-126
    ## [51,] 5.722922143727463e-130
    ## [52,] 5.565465001243176e-153
    ## [53,] 4.978299130783954e-156
    ## [54,] 6.420335398964102e-120
    ## [55,] 1.531075226619922e-125
    ## [56,] 1.025502496061560e-127
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
    ## [1] 1.321471508080756e-157 1.312849658045964e-122  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 4.47930376671913e-121  1.00000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 3.118243002813833e-152 3.903965608653493e-121  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 4.028932373122356e-121  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 7.420299815896822e-156 4.035233365892518e-121  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 3.787774420033002e-123  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 1.514490578373478e-122  1.000000000000000e+00
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
    ##  [1,] 1.259776447973984e-215
    ##  [2,] 4.444112737309158e-214
    ##  [3,] 1.843426499546639e-182
    ##  [4,] 2.612569634269080e-187
    ##  [5,] 3.822964069115501e-154
    ##  [6,] 2.612569634269080e-187
    ##  [7,] 9.216360575271510e-186
    ##  [8,] 3.822964069115501e-154
    ##  [9,] 1.762252154144999e-209
    ## [10,] 3.654621796787107e-181
    ## [11,] 4.121474925821486e-181
    ## [12,] 8.547262696424840e-153
    ## [13,] 8.547262696424840e-153
    ## [14,] 2.945304432182650e-187
    ## [15,] 6.108078092405673e-159
    ## [16,] 8.937929451649369e-126
    ## [17,] 6.108078092405673e-159
    ## [18,] 8.937929451649369e-126
    ## [19,] 9.687580256120389e-214
    ## [20,] 3.417487196174223e-212
    ## [21,] 1.417580253174008e-180
    ## [22,] 2.009045179991131e-185
    ## [23,] 2.294866539789997e-185
    ## [24,] 4.759176635027596e-157
    ## [25,] 4.759176635027596e-157
    ## [26,] 6.945180808106827e-186
    ## [27,] 2.450051081829723e-184
    ## [28,] 1.016285894723384e-152
    ## [29,] 1.440316534965337e-157
    ## [30,] 1.440316534965337e-157
    ## [31,] 5.081003910726385e-156
    ## [32,] 2.107610181600352e-124
    ## [33,] 9.715342638526223e-180
    ## [34,] 2.014802642544630e-151
    ## [35,] 2.272180004789232e-151
    ## [36,] 4.712128484107293e-123
    ## [37,] 1.623754107272321e-157
    ## [38,] 3.367399573949623e-129
    ## [39,] 5.340788564511359e-184
    ## [40,] 1.107591910384888e-155
    ## [41,] 1.265165980436328e-155
    ## [42,] 2.623746640218716e-127
    ## [43,] 2.144931211341200e-185
    ## [44,] 7.566672747616554e-184
    ## [45,] 3.138670389536204e-152
    ## [46,] 4.448235366963885e-157
    ## [47,] 4.448235366963885e-157
    ## [48,] 6.509087358212886e-124
    ## [49,] 7.017340433195035e-151
    ## [50,] 1.039978748831230e-128
    ## [51,] 1.039978748831230e-128
    ## [52,] 3.907305042076638e-155
    ## [53,] 1.182506238124549e-155
    ## [54,] 1.730357269929704e-122
    ## [55,] 2.452323898439606e-127
    ## [56,] 2.452323898439606e-127
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
    ##       gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 gamma.7 counts
    ##  [1,]       0       0       0       0       0       0       0 101069
    ##  [2,]       1       0       0       0       0       0       0    133
    ##  [3,]       2       0       0       0       0       0       0   1181
    ##  [4,]       0       2       0       0       0       0       0    691
    ##  [5,]       2       2       0       0       0       0       0      9
    ##  [6,]       0      NA       0       0       0       0       0  48474
    ##  [7,]       1      NA       0       0       0       0       0     48
    ##  [8,]       2      NA       0       0       0       0       0    559
    ##  [9,]       0       0       1       0       0       0       0     12
    ## [10,]       0      NA       1       0       0       0       0      3
    ## [11,]       0       0       2       0       0       0       0     65
    ## [12,]       0       2       2       0       0       0       0      1
    ## [13,]       0      NA       2       0       0       0       0     36
    ## [14,]       0       0       0       2       0       0       0     15
    ## [15,]       0      NA       0       2       0       0       0      8
    ## [16,]       2      NA       0       2       0       0       0      1
    ## [17,]       0      NA       0      NA       0       0       0    323
    ## [18,]       2      NA       0      NA       0       0       0      4
    ## [19,]       0       0       0       0       1       0       0     40
    ## [20,]       1       0       0       0       1       0       0      1
    ## [21,]       2       0       0       0       1       0       0      3
    ## [22,]       0      NA       0       0       1       0       0     17
    ## [23,]       0       0       0       0       2       0       0     43
    ## [24,]       0       2       0       0       2       0       0      1
    ## [25,]       0      NA       0       0       2       0       0     27
    ## [26,]       0       0       0       0       0       2       0  13032
    ## [27,]       1       0       0       0       0       2       0      9
    ## [28,]       2       0       0       0       0       2       0    153
    ## [29,]       0       2       0       0       0       2       0     75
    ## [30,]       0      NA       0       0       0       2       0   6701
    ## [31,]       1      NA       0       0       0       2       0      3
    ## [32,]       2      NA       0       0       0       2       0     74
    ## [33,]       0       0       1       0       0       2       0      3
    ## [34,]       0      NA       1       0       0       2       0      1
    ## [35,]       0       0       2       0       0       2       0      8
    ## [36,]       0      NA       2       0       0       2       0      3
    ## [37,]       0       0       0       2       0       2       0      4
    ## [38,]       0      NA       0      NA       0       2       0     20
    ## [39,]       0       0       0       0       1       2       0      4
    ## [40,]       0      NA       0       0       1       2       0      3
    ## [41,]       0       0       0       0       2       2       0      3
    ## [42,]       0      NA       0       0       2       2       0      4
    ## [43,]       0       0       0       0       0       0       2   1203
    ## [44,]       1       0       0       0       0       0       2      2
    ## [45,]       2       0       0       0       0       0       2     19
    ## [46,]       0       2       0       0       0       0       2     10
    ## [47,]       0      NA       0       0       0       0       2    593
    ## [48,]       2      NA       0       0       0       0       2      5
    ## [49,]       0       0       2       0       0       0       2      1
    ## [50,]       0      NA       0       2       0       0       2      1
    ## [51,]       0      NA       0      NA       0       0       2      3
    ## [52,]       0       0       0       0       2       0       2      1
    ## [53,]       0       0       0       0       0       2       2    150
    ## [54,]       2       0       0       0       0       2       2      3
    ## [55,]       0       2       0       0       0       2       2      3
    ## [56,]       0      NA       0       0       0       2       2     92
    ## [57,]       2       2       2       2       2       2       2     43
    ## [58,]       2      NA       2       2       2       2       2      7
    ##                   weights            p.gamma.j.m           p.gamma.j.u
    ##  [1,] -493.57441018408292 1.259776447973984e-215 2.863757478838720e-01
    ##  [2,] -485.55800630412904 4.444112737309158e-214 3.333863768687974e-03
    ##  [3,] -410.42696476982599 1.843426499546639e-182 3.249315259387583e-04
    ##  [4,] -423.37339034288374 2.612569634269080e-187 1.931056964827189e-03
    ##  [5,] -340.22594492862675 3.822964069115501e-154 2.191041982055012e-06
    ##  [6,] -428.37934804742883 2.612569634269080e-187 2.883068048486992e-01
    ##  [7,] -420.36294416747489 9.216360575271510e-186 3.356344306575284e-03
    ##  [8,] -345.23190263317190 3.822964069115501e-154 3.271225679208135e-04
    ##  [9,] -472.08794474195878 1.762252154144999e-209 1.867486300460568e-04
    ## [10,] -406.89288260530464 3.654621796787107e-181 1.880078925547961e-04
    ## [11,] -404.97418420194992 4.121474925821486e-181 3.112477167434274e-05
    ## [12,] -334.77316436075068 8.547262696424840e-153 2.098770847899037e-07
    ## [13,] -339.77912206529584 8.547262696424840e-153 3.133464875913262e-05
    ## [14,] -419.54995869423317 2.945304432182650e-187 4.757317474627726e-05
    ## [15,] -354.35489655757908 6.108078092405673e-159 4.789396486594202e-05
    ## [16,] -271.20745114332215 8.937929451649369e-126 5.434209845680946e-08
    ## [17,] -363.05785364998025 6.108078092405673e-159 2.883546988135652e-01
    ## [18,] -279.91040823572331 8.937929451649369e-126 3.271769100192702e-04
    ## [19,] -481.52994764285967 9.687580256120389e-214 1.294238890798554e-04
    ## [20,] -473.51354376290573 3.417487196174223e-212 1.506697469301733e-06
    ## [21,] -398.38250222860279 1.417580253174008e-180 1.468486842283143e-07
    ## [22,] -416.33488550620558 2.009045179991131e-185 1.302966057965099e-04
    ## [23,] -416.04520978866469 2.294866539789997e-185 1.114028412332929e-04
    ## [24,] -345.84418994746540 4.759176635027596e-157 7.511991991456039e-07
    ## [25,] -350.85014765201055 4.759176635027596e-157 1.121540404324386e-04
    ## [26,] -423.06445731436315 6.945180808106827e-186 3.769145106752195e-02
    ## [27,] -415.04805343440921 2.450051081829723e-184 4.387877256779533e-04
    ## [28,] -339.91701190010622 1.016285894723384e-152 4.276598420332113e-05
    ## [29,] -352.86343747316391 1.440316534965337e-157 2.541567840021710e-04
    ## [30,] -357.86939517770907 1.440316534965337e-157 3.794560785152411e-02
    ## [31,] -349.85299129775507 5.081003910726385e-156 4.417465100722750e-04
    ## [32,] -274.72194976345213 2.107610181600352e-124 4.305435901251417e-05
    ## [33,] -401.57799187223901 9.715342638526223e-180 2.457899072571613e-05
    ## [34,] -336.38292973558487 2.014802642544630e-151 2.474472903135143e-05
    ## [35,] -334.46423133223016 2.272180004789232e-151 4.096498454286010e-06
    ## [36,] -269.26916919557607 4.712128484107293e-123 4.124121505225226e-06
    ## [37,] -349.04000582451340 1.623754107272321e-157 6.261361170859698e-06
    ## [38,] -292.54790078026048 3.367399573949623e-129 3.795191143360645e-02
    ## [39,] -411.01999477313984 5.340788564511359e-184 1.703417352296152e-05
    ## [40,] -345.82493263648581 1.107591910384888e-155 1.714903645973134e-05
    ## [41,] -345.53525691894487 1.265165980436328e-155 1.466232657672632e-05
    ## [42,] -280.34019478229078 2.623746640218716e-127 1.476119594002186e-05
    ## [43,] -419.54742739308836 2.144931211341200e-185 3.455779167934082e-03
    ## [44,] -411.53102351313441 7.566672747616554e-184 4.023070055930163e-05
    ## [45,] -336.39998197883142 3.138670389536204e-152 3.921042918758394e-06
    ## [46,] -349.34640755188917 4.448235366963885e-157 2.330262419375648e-05
    ## [47,] -354.35236525643433 4.448235366963885e-157 3.479081792127839e-03
    ## [48,] -271.20491984217733 6.509087358212886e-124 3.947482857522776e-06
    ## [49,] -330.94720141095536 7.017340433195035e-151 3.755916426362859e-07
    ## [50,] -280.32791376658457 1.039978748831230e-128 5.779503581448713e-07
    ## [51,] -289.03087085898568 1.039978748831230e-128 3.479659742485983e-03
    ## [52,] -342.01822699767013 3.907305042076638e-155 1.344330380025045e-06
    ## [53,] -349.03747452336859 1.182506238124549e-155 4.548336665057549e-04
    ## [54,] -265.89002910911165 1.730357269929704e-122 5.160695289252128e-07
    ## [55,] -278.83645468216935 2.452323898439606e-127 3.066983590733346e-06
    ## [56,] -283.84241238671450 2.452323898439606e-127 4.579006500964880e-04
    ## [57,]   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ## [58,]   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
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
dfA.match <- dfA[matches.out[,1],]
dfB.match <- dfB[matches.out[,2],]
```

Lastly, we can summarize the match as done earlier by feeding the output from `emlinkMARmov()` into the `summary()` function:

``` r
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
    ## Getting the indices of estimated matches.
    ## Parallelizing gamma calculation using 1 cores.

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
