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
    ##  [1,] 3.891040132378424e-232
    ##  [2,] 4.024699163514023e-226
    ##  [3,] 1.184862438367142e-192
    ##  [4,] 9.479846966239521e-201
    ##  [5,] 2.886712603732536e-161
    ##  [6,] 6.349529113355284e-203
    ##  [7,] 6.567638379922933e-197
    ##  [8,] 1.933498060102151e-163
    ##  [9,] 1.010799104755589e-222
    ## [10,] 1.649455704656619e-193
    ## [11,] 1.149111286256616e-192
    ## [12,] 2.799611098905149e-161
    ## [13,] 1.875158137243888e-163
    ## [14,] 4.435359444144053e-199
    ## [15,] 7.237767527618250e-170
    ## [16,] 2.203975952277391e-130
    ## [17,] 1.202149245709791e-173
    ## [18,] 3.660670252923505e-134
    ## [19,] 2.922974452888088e-224
    ## [20,] 3.023379979460831e-218
    ## [21,] 8.900763085722438e-185
    ## [22,] 4.769807237855967e-195
    ## [23,] 6.430937100269240e-195
    ## [24,] 1.566786707049452e-163
    ## [25,] 1.049421772973502e-165
    ## [26,] 7.403890725866905e-200
    ## [27,] 7.658217802275138e-194
    ## [28,] 2.254562204551775e-160
    ## [29,] 1.803830046673808e-168
    ## [30,] 1.208191591877958e-170
    ## [31,] 1.249693532773683e-164
    ## [32,] 3.679069829311059e-131
    ## [33,] 1.923353618262568e-190
    ## [34,] 3.138592607362932e-161
    ## [35,] 2.186534732579159e-160
    ## [36,] 3.568060330795798e-131
    ## [37,] 8.439624248828126e-167
    ## [38,] 2.287455628471783e-141
    ## [39,] 5.561850484039289e-192
    ## [40,] 9.076013192120442e-163
    ## [41,] 1.223681944555406e-162
    ## [42,] 1.996845025520941e-133
    ## [43,] 4.987432737387234e-198
    ## [44,] 5.158753362426810e-192
    ## [45,] 1.518725459868381e-158
    ## [46,] 1.215101810732129e-166
    ## [47,] 8.138659147569907e-169
    ## [48,] 2.478306877995039e-129
    ## [49,] 1.472900574909913e-158
    ## [50,] 9.277179747507361e-136
    ## [51,] 1.540883234122160e-139
    ## [52,] 8.243005760610698e-161
    ## [53,] 9.490112086728060e-166
    ## [54,] 2.889838440341194e-126
    ## [55,] 2.312101834314683e-134
    ## [56,] 1.548628154263003e-136
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
    ## [1] 7.498161196642120e-166 2.158501731882402e-132  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[2]]
    ## [1] 2.01616635372641e-127  1.00000000000000e+00
    ## 
    ## $p.gamma.k.m[[3]]
    ## [1] 6.277185214725897e-163 1.736970158877196e-127  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[4]]
    ## [1] 1.736947458249128e-127  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[5]]
    ## [1] 5.445607915272281e-164 1.736991407491579e-127  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[6]]
    ## [1] 2.522415868038644e-130  1.000000000000000e+00
    ## 
    ## $p.gamma.k.m[[7]]
    ## [1] 6.101792487415635e-131  1.000000000000000e+00
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
    ##  [1,] 5.819314047088338e-229
    ##  [2,] 7.007306619072030e-225
    ##  [3,] 2.010618298249671e-192
    ##  [4,] 9.560184208475398e-200
    ##  [5,] 3.303118056296643e-163
    ##  [6,] 9.560184208475398e-200
    ##  [7,] 1.151186231599173e-195
    ##  [8,] 3.303118056296643e-163
    ##  [9,] 9.858075086978473e-223
    ## [10,] 1.619521012440576e-193
    ## [11,] 1.867833296434516e-193
    ## [12,] 3.068545577734095e-164
    ## [13,] 3.068545577734095e-164
    ## [14,] 1.101947246954486e-199
    ## [15,] 1.810319667174220e-170
    ## [16,] 6.254795357406301e-134
    ## [17,] 1.810319667174220e-170
    ## [18,] 6.254795357406301e-134
    ## [19,] 1.975646839392125e-224
    ## [20,] 2.378968219037418e-220
    ## [21,] 6.826013605758982e-188
    ## [22,] 3.245665651080007e-195
    ## [23,] 3.741453721138170e-195
    ## [24,] 6.146598463690658e-166
    ## [25,] 6.146598463690658e-166
    ## [26,] 1.457379668244635e-197
    ## [27,] 1.754898620895242e-193
    ## [28,] 5.035360189807639e-161
    ## [29,] 2.394237186267115e-168
    ## [30,] 2.394237186267115e-168
    ## [31,] 2.883012318496938e-164
    ## [32,] 8.272275835443310e-132
    ## [33,] 2.468840499677215e-191
    ## [34,] 4.055902425487423e-162
    ## [35,] 4.677771723380666e-162
    ## [36,] 7.684816285708480e-133
    ## [37,] 2.759698995783102e-168
    ## [38,] 4.533735513523580e-139
    ## [39,] 4.947778229639706e-193
    ## [40,] 8.128392954098605e-164
    ## [41,] 9.370036637897624e-164
    ## [42,] 1.539344252150997e-134
    ## [43,] 9.001043955374891e-197
    ## [44,] 1.083857553943407e-192
    ## [45,] 3.109930746748652e-160
    ## [46,] 1.478724770405342e-167
    ## [47,] 1.478724770405342e-167
    ## [48,] 5.109109179181446e-131
    ## [49,] 2.889077555615481e-161
    ## [50,] 2.800118152356426e-138
    ## [51,] 2.800118152356426e-138
    ## [52,] 5.787106371723936e-163
    ## [53,] 2.254206998865077e-165
    ## [54,] 7.788460638635025e-129
    ## [55,] 3.703294577127585e-136
    ## [56,] 3.703294577127585e-136
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
    ##  [1,] -524.28035337550671 5.819314047088338e-229 2.863757478838720e-01
    ##  [2,] -510.43106915955389 7.007306619072030e-225 3.333863768687974e-03
    ##  [3,] -433.36599948176701 2.010618298249671e-192 3.249315259387583e-04
    ##  [4,] -452.00972382746107 9.560184208475398e-200 1.931056964827189e-03
    ##  [5,] -361.09536993372126 3.303118056296643e-163 2.191041982055012e-06
    ##  [6,] -457.01568153200617 9.560184208475398e-200 2.883068048486992e-01
    ##  [7,] -443.16639731605335 1.151186231599173e-195 3.356344306575284e-03
    ##  [8,] -366.10132763826641 3.303118056296643e-163 3.271225679208135e-04
    ##  [9,] -502.60243774281844 9.858075086978473e-223 1.867486300460568e-04
    ## [10,] -435.33776589931779 1.619521012440576e-193 1.880078925547961e-04
    ## [11,] -433.39663731479345 1.867833296434516e-193 3.112477167434274e-05
    ## [12,] -361.12600776674765 3.068545577734095e-164 2.098770847899037e-07
    ## [13,] -366.13196547129280 3.068545577734095e-164 3.133464875913262e-05
    ## [14,] -448.16411315517280 1.101947246954486e-199 4.757317474627726e-05
    ## [15,] -380.89944131167226 1.810319667174220e-170 4.789396486594202e-05
    ## [16,] -289.98508741793245 6.254795357406301e-134 5.434209845680946e-08
    ## [17,] -389.60239840407337 1.810319667174220e-170 2.883546988135652e-01
    ## [18,] -298.68804451033361 6.254795357406301e-134 3.271769100192702e-04
    ## [19,] -506.14574739359949 1.975646839392125e-224 1.294238890798554e-04
    ## [20,] -492.29646317764667 2.378968219037418e-220 1.506697469301733e-06
    ## [21,] -415.23139349985979 6.826013605758982e-188 1.468486842283143e-07
    ## [22,] -438.88107555009890 3.245665651080007e-195 1.302966057965099e-04
    ## [23,] -438.58226117643437 3.741453721138170e-195 1.114028412332929e-04
    ## [24,] -366.31163162838862 6.146598463690658e-166 7.511991991456039e-07
    ## [25,] -371.31758933293378 6.146598463690658e-166 1.121540404324386e-04
    ## [26,] -449.95430127199654 1.457379668244635e-197 3.769145106752195e-02
    ## [27,] -436.10501705604366 1.754898620895242e-193 4.387877256779533e-04
    ## [28,] -359.03994737825678 5.035360189807639e-161 4.276598420332113e-05
    ## [29,] -377.68367172395079 2.394237186267115e-168 2.541567840021710e-04
    ## [30,] -382.68962942849595 2.394237186267115e-168 3.794560785152411e-02
    ## [31,] -368.84034521254307 2.883012318496938e-164 4.417465100722750e-04
    ## [32,] -291.77527553475619 8.272275835443310e-132 4.305435901251417e-05
    ## [33,] -428.27638563930816 2.468840499677215e-191 2.457899072571613e-05
    ## [34,] -361.01171379580757 4.055902425487423e-162 2.474472903135143e-05
    ## [35,] -359.07058521128317 4.677771723380666e-162 4.096498454286010e-06
    ## [36,] -291.80591336778258 7.684816285708480e-133 4.124121505225226e-06
    ## [37,] -373.83806105166258 2.759698995783102e-168 6.261361170859698e-06
    ## [38,] -315.27634630056315 4.533735513523580e-139 3.795191143360645e-02
    ## [39,] -431.81969529008921 4.947778229639706e-193 1.703417352296152e-05
    ## [40,] -364.55502344658868 8.128392954098605e-164 1.714903645973134e-05
    ## [41,] -364.25620907292409 9.370036637897624e-164 1.466232657672632e-05
    ## [42,] -296.99153722942350 1.539344252150997e-134 1.476119594002186e-05
    ## [43,] -445.74421542592688 9.001043955374891e-197 3.455779167934082e-03
    ## [44,] -431.89493120997406 1.083857553943407e-192 4.023070055930163e-05
    ## [45,] -354.82986153218712 3.109930746748652e-160 3.921042918758394e-06
    ## [46,] -373.47358587788113 1.478724770405342e-167 2.330262419375648e-05
    ## [47,] -378.47954358242629 1.478724770405342e-167 3.479081792127839e-03
    ## [48,] -287.56518968868653 5.109109179181446e-131 3.947482857522776e-06
    ## [49,] -354.86049936521351 2.889077555615481e-161 3.755916426362859e-07
    ## [50,] -302.36330336209238 2.800118152356426e-138 5.779503581448713e-07
    ## [51,] -311.06626045449349 2.800118152356426e-138 3.479659742485983e-03
    ## [52,] -360.04612322685443 5.787106371723936e-163 1.344330380025045e-06
    ## [53,] -371.41816332241660 2.254206998865077e-165 4.548336665057549e-04
    ## [54,] -280.50380942867690 7.788460638635025e-129 5.160695289252128e-07
    ## [55,] -299.14753377437086 3.703294577127585e-136 3.066983590733346e-06
    ## [56,] -304.15349147891601 3.703294577127585e-136 4.579006500964880e-04
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
