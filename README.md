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
  stringdist.match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)
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

-   `stringdist.match` should be a vector of booleans of the same length as `varnames`. `TRUE` means that string-distance matching using the Jaro-Winkler similarity will be used.

-   `partial.match` is another vector of booleans of the same length as `varnames`. A `TRUE` for an entry in `partial.match` and a `TRUE` for that same entry for `stringdist.match` means that a partial match category will be included in the gamma calculation.

Other arguments that can be provided include:

-   `priors.obj`: The output from `calcMoversPriors()`, allowing the inclusion of auxiliary information on moving behavior to aid matching. We will discuss this option further at the end of this vignette.

-   `w.lambda`: The user-specified weighting of the MLE and prior estimate for the *λ* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `w.pi`: The user-specified weighting of the MLE and prior estimate for the *π* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `l.address`: The number of possible matching categories used for address fields, used to calculate optimal hyperparameters for the *π* prior. We will discuss this option further at the end of this vignette.

-   `address.field`: A boolean vector the same length as `varnames`, where TRUE indicates an address matching field. Default is NULL. Should be specified in conjunction with `priors_obj`. We will discuss this option further at the end of this vignette.

-   `n.cores`: The number of registered cores to parallelize over. If left unspecified. the function will estimate this on its own.

-   `tol.em`: Convergence tolerance for the EM algorithm. Default is 1e-04

-   `match`: Lower bound for the posterior probability of a match that will be accepted. Default is 0.85.

-   `verbose`: Whether to print out runtime for each step and EM output. Default is FALSE.

The output from `fastLink()` will be a list of length 2 with two entries:

-   `matches`: A matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

-   `EM`: The output from the EM algorithm.

-   `nobs.a`: The number of observations in dataset A.

-   `nobs.b`: The number of observations in dataset B.

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
    ##  [1,] 1.728527690300522e-229
    ##  [2,] 1.590549470285887e-227
    ##  [3,] 2.203799036318096e-192
    ##  [4,] 2.483942010748443e-197
    ##  [5,] 3.166920055880460e-160
    ##  [6,] 1.663725392329820e-199
    ##  [7,] 1.530919959408431e-197
    ##  [8,] 2.121178871989573e-162
    ##  [9,] 6.792124633430219e-219
    ## [10,] 6.537488687000478e-189
    ## [11,] 4.588302959822955e-188
    ## [12,] 6.593518023401475e-156
    ## [13,] 4.416288026390769e-158
    ## [14,] 1.171484692030105e-195
    ## [15,] 1.127565869955665e-165
    ## [16,] 1.437598362778580e-128
    ## [17,] 1.872818455252826e-169
    ## [18,] 2.387763603698675e-132
    ## [19,] 5.139627531833679e-225
    ## [20,] 4.729361232739413e-223
    ## [21,] 6.552805757898566e-188
    ## [22,] 4.946943505626742e-195
    ## [23,] 7.223290490171730e-195
    ## [24,] 1.038006784910505e-162
    ## [25,] 6.952490186942369e-165
    ## [26,] 2.114442909169381e-197
    ## [27,] 1.945659342341345e-195
    ## [28,] 2.695824470573968e-160
    ## [29,] 3.038512834296303e-165
    ## [30,] 2.035172695442918e-167
    ## [31,] 1.872716804504333e-165
    ## [32,] 2.594758331107769e-130
    ## [33,] 8.308550594785954e-187
    ## [34,] 7.997064019031785e-157
    ## [35,] 5.612698432867272e-156
    ## [36,] 5.402279034724383e-126
    ## [37,] 1.433033161206040e-163
    ## [38,] 2.290948374788364e-137
    ## [39,] 6.287113045072142e-193
    ## [40,] 6.051409923156046e-163
    ## [41,] 8.835979570080726e-163
    ## [42,] 8.504719744636628e-133
    ## [43,] 2.324888235320867e-196
    ## [44,] 2.139306053303761e-194
    ## [45,] 2.964133280188487e-159
    ## [46,] 3.340928577779182e-164
    ## [47,] 2.237728451292260e-166
    ## [48,] 2.853008275292411e-129
    ## [49,] 6.171316566832134e-155
    ## [50,] 1.516588157840387e-132
    ## [51,] 2.518960857810640e-136
    ## [52,] 9.715402984365676e-162
    ## [53,] 2.843948333237620e-164
    ## [54,] 3.625912752972734e-127
    ## [55,] 4.086832268274715e-132
    ## [56,] 2.737329047739236e-134
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
    ## [1] 1.123630082702603e-166 3.241371360540531e-127  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 2.529706571841436e-128  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 1.599412803806365e-158 2.271290624260291e-128  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 3.465619072763821e-127  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 3.630845953893637e-164 3.468495802883088e-127  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 5.730418680501746e-130  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 3.248085450570336e-127  1.000000000000000e+00
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
    ##  [1,] 2.585130229124224e-226
    ##  [2,] 2.769267311240360e-226
    ##  [3,] 3.739673505215096e-192
    ##  [4,] 2.504992250454636e-196
    ##  [5,] 3.623745157692859e-162
    ##  [6,] 2.504992250454636e-196
    ##  [7,] 2.683421158416506e-196
    ##  [8,] 3.623745157692859e-162
    ##  [9,] 6.624192119032542e-219
    ## [10,] 6.418844875494206e-189
    ## [11,] 7.458098397418828e-189
    ## [12,] 7.226900400677448e-159
    ## [13,] 7.226900400677448e-159
    ## [14,] 2.910506684945853e-196
    ## [15,] 2.820282169365103e-166
    ## [16,] 4.079846495616686e-132
    ## [17,] 2.820282169365103e-166
    ## [18,] 4.079846495616686e-132
    ## [19,] 3.473889030705369e-225
    ## [20,] 3.721331802640672e-225
    ## [21,] 5.025360278498065e-191
    ## [22,] 3.366199893072256e-195
    ## [23,] 4.202436855148763e-195
    ## [24,] 4.072163033248157e-165
    ## [25,] 4.072163033248157e-165
    ## [26,] 4.162063190264984e-195
    ## [27,] 4.458524143296620e-195
    ## [28,] 6.020879437449861e-161
    ## [29,] 4.033040935445534e-165
    ## [30,] 4.033040935445534e-165
    ## [31,] 4.320311720313571e-165
    ## [32,] 5.834234640025154e-131
    ## [33,] 1.066495833488717e-187
    ## [34,] 1.033434899307356e-157
    ## [35,] 1.200754857900662e-157
    ## [36,] 1.163531948932379e-127
    ## [37,] 4.685919727354359e-165
    ## [38,] 4.540658134368380e-135
    ## [39,] 5.592966071446807e-194
    ## [40,] 5.419586413167395e-164
    ## [41,] 6.765929061203253e-164
    ## [42,] 6.556188030488794e-134
    ## [43,] 4.195830259641719e-195
    ## [44,] 4.494696418243499e-195
    ## [45,] 6.069727195011271e-161
    ## [46,] 4.065761239496885e-165
    ## [47,] 4.065761239496885e-165
    ## [48,] 5.881568137102292e-131
    ## [49,] 1.210496654393879e-157
    ## [50,] 4.577496767332406e-135
    ## [51,] 4.577496767332406e-135
    ## [52,] 6.820821451242428e-164
    ## [53,] 6.755292433437636e-164
    ## [54,] 9.772269051940032e-130
    ## [55,] 6.545881133828944e-134
    ## [56,] 6.545881133828944e-134
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
    ##  [1,] -518.18400460453381 2.585130229124224e-226 2.863757478838720e-01
    ##  [2,] -513.66202488331135 2.769267311240360e-226 3.333863768687974e-03
    ##  [3,] -432.74544345805998 3.739673505215096e-192 3.249315259387583e-04
    ##  [4,] -444.13870481013038 2.504992250454636e-196 1.931056964827189e-03
    ##  [5,] -358.70014366365643 3.623745157692859e-162 2.191041982055012e-06
    ##  [6,] -449.14466251467547 2.504992250454636e-196 2.883068048486992e-01
    ##  [7,] -444.62268279345307 2.683421158416506e-196 3.356344306575284e-03
    ##  [8,] -363.70610136820159 3.623745157692859e-162 3.271225679208135e-04
    ##  [9,] -493.78965987581415 6.624192119032542e-219 1.867486300460568e-04
    ## [10,] -424.75031778595576 6.418844875494206e-189 1.880078925547961e-04
    ## [11,] -422.80177556169497 7.458098397418828e-189 3.112477167434274e-05
    ## [12,] -348.75647576729148 7.226900400677448e-159 2.098770847899037e-07
    ## [13,] -353.76243347183663 7.226900400677448e-159 3.133464875913262e-05
    ## [14,] -440.28510953093371 2.910506684945853e-196 4.757317474627726e-05
    ## [15,] -371.24576744107537 2.820282169365103e-166 4.789396486594202e-05
    ## [16,] -285.80720629460143 4.079846495616686e-132 5.434209845680946e-08
    ## [17,] -379.94872453347648 2.820282169365103e-166 2.883546988135652e-01
    ## [18,] -294.51016338700259 4.079846495616686e-132 3.271769100192702e-04
    ## [19,] -507.88395362043542 3.473889030705369e-225 1.294238890798554e-04
    ## [20,] -503.36197389921301 3.721331802640672e-225 1.506697469301733e-06
    ## [21,] -422.44539247396165 5.025360278498065e-191 1.468486842283143e-07
    ## [22,] -438.84461153057714 3.366199893072256e-195 1.302966057965099e-04
    ## [23,] -438.46607084718664 4.202436855148763e-195 1.114028412332929e-04
    ## [24,] -364.42077105278315 4.072163033248157e-165 7.511991991456039e-07
    ## [25,] -369.42672875732831 4.072163033248157e-165 1.121540404324386e-04
    ## [26,] -444.29976025093725 4.162063190264984e-195 3.769145106752195e-02
    ## [27,] -439.77778052971485 4.458524143296620e-195 4.387877256779533e-04
    ## [28,] -358.86119910446342 6.020879437449861e-161 4.276598420332113e-05
    ## [29,] -370.25446045653376 4.033040935445534e-165 2.541567840021710e-04
    ## [30,] -375.26041816107892 4.033040935445534e-165 3.794560785152411e-02
    ## [31,] -370.73843843985651 4.320311720313571e-165 4.417465100722750e-04
    ## [32,] -289.82185701460509 5.834234640025154e-131 4.305435901251417e-05
    ## [33,] -419.90541552221760 1.066495833488717e-187 2.457899072571613e-05
    ## [34,] -350.86607343235920 1.033434899307356e-157 2.474472903135143e-05
    ## [35,] -348.91753120809847 1.200754857900662e-157 4.096498454286010e-06
    ## [36,] -279.87818911824007 1.163531948932379e-127 4.124121505225226e-06
    ## [37,] -366.40086517733710 4.685919727354359e-165 6.261361170859698e-06
    ## [38,] -306.06448017987992 4.540658134368380e-135 3.795191143360645e-02
    ## [39,] -433.99970926683886 5.592966071446807e-194 1.703417352296152e-05
    ## [40,] -364.96036717698053 5.419586413167395e-164 1.714903645973134e-05
    ## [41,] -364.58182649359003 6.765929061203253e-164 1.466232657672632e-05
    ## [42,] -295.54248440373175 6.556188030488794e-134 1.476119594002186e-05
    ## [43,] -441.90229456877154 4.195830259641719e-195 3.455779167934082e-03
    ## [44,] -437.38031484754919 4.494696418243499e-195 4.023070055930163e-05
    ## [45,] -356.46373342229771 6.069727195011271e-161 3.921042918758394e-06
    ## [46,] -367.85699477436810 4.065761239496885e-165 2.330262419375648e-05
    ## [47,] -372.86295247891326 4.065761239496885e-165 3.479081792127839e-03
    ## [48,] -287.42439133243931 5.881568137102292e-131 3.947482857522776e-06
    ## [49,] -346.52006552593269 1.210496654393879e-157 3.755916426362859e-07
    ## [50,] -294.96405740531310 4.577496767332406e-135 5.779503581448713e-07
    ## [51,] -303.66701449771421 4.577496767332406e-135 3.479659742485983e-03
    ## [52,] -362.18436081142437 6.820821451242428e-164 1.344330380025045e-06
    ## [53,] -368.01805021517498 6.755292433437636e-164 4.548336665057549e-04
    ## [54,] -282.57948906870115 9.772269051940032e-130 5.160695289252128e-07
    ## [55,] -293.97275042077149 6.545881133828944e-134 3.066983590733346e-06
    ## [56,] -298.97870812531664 6.545881133828944e-134 4.579006500964880e-04
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

where the first seven columns are indicators for the matching pattern for that field. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Fellegi-Sunter weight for each matching pattern

-   `p.gamma.j.m`: Probability of being in the matched set given that matching pattern

-   `p.gamma.j.u`: Probability of being in the unmatched set given that matching pattern

-   `zeta.j`: Posterior probability of a particular pattern representing a true match

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

## Postprocessing of EM algorithm
EM <- data.frame(em.out$patterns.w)
EM$zeta.j <- em.out$zeta.j
EM <- EM[order(EM[, "weights"]), ] 
match.ut <- EM$weights[ EM$zeta.j >= 0.85 ][1]
```

As with the other functions above, `emlinkMARmov()` accepts an `n.cores` argument. Other optional arguments include:

-   `p.m`: Starting values for the probability of being in the matched set

-   `p.gamma.k.m`: Starting values for the probability that conditional on being in the matched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `p.gamma.k.u`: Starting values for the probability that conditional on being in the unmatched set, we observed a specific agreement value for field k. A vector with length equal to the number of linkage fields

-   `tol`: Convergence tolerance for the EM algorithm

-   `iter.max`: Maximum number of iterations for the EM algorithm

and additional arguments that allow the user to specify priors calculated from auxiliary information. We will discuss these further at the end of this vignette.

The code following `emlinkMARmov()` sorts the linkage patterns by the Fellegi-Sunter weight, and then selects the lowest weight that is still classified as a positive match according to the posterior probability that a linkage pattern is in the matched set. In this case, we've chosen that probability to be 0.85.

#### 4) Finding the matches

Once we've run the EM algorithm and selected our lower bound for accepting a match, we then run `matchesLink()` to get the paired indices of `dfA` and `dfB` that match. We run the function as follows:

``` r
matches.out <- matchesLink(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB),
                           em = em.out, cut = match.ut)
```

    ## Parallelizing gamma calculation using 1 cores.

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
  stringdist.match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE),
  priors.obj = priors.out, 
  w.lambda = .5, w.pi = .5, 
  address.field = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE)
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

where `priors.obj` is an input for the the optimal prior parameters. This can be calculated by `calcMoversPriors()`, or can be provided by the user as a list with two entries named `lambda.prior` and `pi.prior`. `w.lambda` and `w.pi` are user-specified weights between 0 and 1 indicating the weighting between the MLE estimate and the prior, where a weight of 0 indicates no weight being placed on the prior. `address_field` is a vector of booleans of the same length as `varnames`, where `TRUE` indicates an address-related field used for matching. `l.address` is an integer indicating the number of matching fields used on the address variable - when a single partial match category is included, `l.address = 3`, while for a binary match/no match category `l.address = 2`.

### Incorporating Auxiliary Information when Running the Algorithm Step-by-Step

If we are running the algorithm step-by-step, we can incorporate the prior information into the EM algorithm as follows:

``` r
em.out.aux <- emlinkMARmov(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB),
                           prior.lambda = priors.out$lambda.prior, w.lambda = .5,
                           prior.pi = priors.out$pi.prior, w.pi = .5,
                           address.field = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE))
```

All other steps are the same. The newly specified arguments include the prior estimates of the parameters (`prior.lambda`, `prior.pi`), the weightings of the prior and MLE estimate (`w.lambda`, `w.pi`), the vector of boolean indicators where `TRUE` indicates an address field (`address.field`), and an integer indicating the number of matching categories for the address field (`l.address`).

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
  stringdist.match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)
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
  stringdist.match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)
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
    ## 1 Match Rate          All 29.762% 29.762% 29.762% 25.595%
    ## 2            Within-State 14.286% 14.286% 14.286% 11.905%
    ## 3            Across-State 15.476% 15.476% 15.476%  13.69%
    ## 4        FDR          All      0%      0%      0%        
    ## 5            Within-State      0%      0%      0%        
    ## 6            Across-State      0%      0%      0%        
    ## 7        FNR          All      0%      0%      0%        
    ## 8            Within-State      0%      0%      0%        
    ## 9            Across-State      0%      0%      0%
