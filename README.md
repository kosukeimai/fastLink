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
  df_a = dfA, df_b = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist_match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial_match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)
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

-   `stringdist_match` should be a vector of booleans of the same length as `varnames`. `TRUE` means that string-distance matching using the Jaro-Winkler similarity will be used.

-   `partial_match` is another vector of booleans of the same length as `varnames`. A `TRUE` for an entry in `partial_match` and a `TRUE` for that same entry for `stringdist_match` means that a partial match category will be included in the gamma calculation.

Other arguments that can be provided include:

-   `priors_obj`: The output from `precalcPriors()` or `calcMoversPriors()`, allowing the inclusion of auxiliary information on moving behavior to aid matching. We will discuss this option further at the end of this vignette.

-   `address_field`: A boolean vector the same length as `varnames`, where TRUE indicates an address matching field. Default is NULL. Should be specified in conjunction with `priors_obj`. We will discuss this option further at the end of this vignette.

-   `n.cores`: The number of registered cores to parallelize over. If left unspecified. the function will estimate this on its own.

-   `tol.em`: Convergence tolerance for the EM algorithm. Default is 1e-04

-   `match`: Lower bound for the posterior probability of a match that will be accepted. Default is 0.85.

-   `verbose`: Whether to print out runtime for each step and EM output. Default is FALSE.

The output from `fastLink()` will be a list of length 2 with two entries:

-   `matches`: A matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

-   `EM`: The output from the EM algorithm

The datasets can then be subsetted down to the matches as follows:

``` r
dfA.match <- dfA[matches.out$matches[,1],]
dfB.match <- dfB[matches.out$matches[,2],]
```

We can also examine the EM object:

``` r
matches.out$EM
```

    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 gamma.7 counts
    ## 1        0       0       0       0       0       0       0 101069
    ## 2        1       0       0       0       0       0       0    133
    ## 19       0       0       0       0       1       0       0     40
    ## 20       1       0       0       0       1       0       0      1
    ## 9        0       0       1       0       0       0       0     12
    ## 6        0      NA       0       0       0       0       0  48474
    ## 26       0       0       0       0       0       2       0  13032
    ## 4        0       2       0       0       0       0       0    691
    ## 43       0       0       0       0       0       0       2   1203
    ## 7        1      NA       0       0       0       0       0     48
    ## 27       1       0       0       0       0       2       0      9
    ## 14       0       0       0       2       0       0       0     15
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 39       0       0       0       0       1       2       0      4
    ## 44       1       0       0       0       0       0       2      2
    ## 3        2       0       0       0       0       0       0   1181
    ## 10       0      NA       1       0       0       0       0      3
    ## 11       0       0       2       0       0       0       0     65
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 47       0      NA       0       0       0       0       2    593
    ## 29       0       2       0       0       0       2       0     75
    ## 53       0       0       0       0       0       2       2    150
    ## 31       1      NA       0       0       0       2       0      3
    ## 15       0      NA       0       2       0       0       0      8
    ## 25       0      NA       0       0       2       0       0     27
    ## 46       0       2       0       0       0       0       2     10
    ## 37       0       0       0       2       0       2       0      4
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 24       0       2       0       0       2       0       0      1
    ## 8        2      NA       0       0       0       0       0    559
    ## 52       0       0       0       0       2       0       2      1
    ## 28       2       0       0       0       0       2       0    153
    ## 5        2       2       0       0       0       0       0      9
    ## 45       2       0       0       0       0       0       2     19
    ## 13       0      NA       2       0       0       0       0     36
    ## 34       0      NA       1       0       0       2       0      1
    ## 35       0       0       2       0       0       2       0      8
    ## 12       0       2       2       0       0       0       0      1
    ## 49       0       0       2       0       0       0       2      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 42       0      NA       0       0       2       2       0      4
    ## 55       0       2       0       0       0       2       2      3
    ## 18       2      NA       0      NA       0       0       0      4
    ## 50       0      NA       0       2       0       0       2      1
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 54       2       0       0       0       0       2       2      3
    ## 16       2      NA       0       2       0       0       0      1
    ## 36       0      NA       2       0       0       2       0      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -413.48435561231389 7.637693754018103e-181 2.863757478838720e-01
    ## 2  -407.71945283839318 2.835563105756702e-180 3.333863768687974e-03
    ## 19 -404.59087496776823 2.514374820775025e-180 1.294238890798555e-04
    ## 20 -398.82597219384746 9.334844660513450e-180 1.506697469301736e-06
    ## 9  -394.19039793440328 1.192731756310578e-175 1.867486300460568e-04
    ## 6  -357.34135242517988 1.855570156141767e-156 2.883068048486992e-01
    ## 26 -355.12103561099207 2.234275297265489e-156 3.769145106752195e-02
    ## 4  -352.33539472063478 1.855570156141767e-156 1.931056964827189e-03
    ## 43 -351.81263131756651 5.600947955905334e-156 3.455779167934082e-03
    ## 7  -351.57644965125922 6.888972567315149e-156 3.356344306575284e-03
    ## 27 -349.35613283707130 8.294949765034259e-156 4.387877256779533e-04
    ## 14 -348.95302715714661 1.345823157134646e-156 4.757317474627734e-05
    ## 22 -348.44787178063427 6.108648800339312e-156 1.302966057965100e-04
    ## 23 -348.34713056433839 5.776432148374124e-156 1.114028412332929e-04
    ## 39 -346.22755496644635 7.355368951744782e-156 1.703417352296155e-05
    ## 44 -346.04772854364580 2.079402748070820e-155 4.023070055930163e-05
    ## 3  -343.30350745205237 2.611998634892245e-153 3.249315259387583e-04
    ## 10 -338.04739474726932 2.897730025019659e-151 1.880078925547961e-04
    ## 11 -336.56853825166399 2.104976391151576e-151 3.112477167434274e-05
    ## 33 -335.82707793308145 3.489130600433982e-151 2.457899072571613e-05
    ## 21 -334.41002680750671 8.598856946858716e-153 1.468486842283143e-07
    ## 17 -301.51298106241376 3.269664071709809e-132 2.883546988135652e-01
    ## 30 -298.97803242385811 5.428149773652934e-132 3.794560785152411e-02
    ## 47 -295.66962813043261 1.360744775556491e-131 3.479081792127839e-03
    ## 29 -293.97207471931296 5.428149773652934e-132 2.541567840021710e-04
    ## 53 -293.44931131624469 1.638460517294952e-131 4.548336665057549e-04
    ## 31 -293.21312964993734 2.015249855048767e-131 4.417465100722750e-04
    ## 15 -292.81002397001265 3.269664071709809e-132 4.789396486594211e-05
    ## 25 -292.20412737720443 1.403378486845111e-131 1.121540404324386e-04
    ## 46 -290.66367042588746 1.360744775556491e-131 2.330262419375648e-05
    ## 37 -290.58970715582473 3.936973033112313e-132 6.261361170859708e-06
    ## 40 -290.08455177931239 1.786979624194685e-131 1.714903645973134e-05
    ## 41 -289.98381056301650 1.689795384719733e-131 1.466232657672632e-05
    ## 24 -287.19816967265928 1.403378486845111e-131 7.511991991456039e-07
    ## 8  -287.16050426491842 6.345824892807455e-129 3.271225679208135e-04
    ## 52 -286.67540626959101 4.236029471179189e-131 1.344330380025045e-06
    ## 28 -284.94018745073055 7.640950546571352e-129 4.276598420332113e-05
    ## 5  -282.15454656037326 6.345824892807455e-129 2.191041982055012e-06
    ## 45 -281.63178315730505 1.915456273332498e-128 3.921042918758394e-06
    ## 13 -280.42553506453004 5.114019357936123e-127 3.133464875913262e-05
    ## 34 -279.68407474594750 8.476808342361020e-127 2.474472903135143e-05
    ## 35 -278.20521825034217 6.157744606613453e-127 4.096498454286010e-06
    ## 12 -275.41957735998488 5.114019357936123e-127 2.098770847899037e-07
    ## 49 -274.89681395691662 1.543641784412591e-126 3.755916426362859e-07
    ## 38 -243.14966106109196 9.564837110592796e-108 3.795191143360645e-02
    ## 51 -239.84125676766644 2.397741895491066e-107 3.479659742485983e-03
    ## 56 -237.30630812911073 3.980623648741460e-107 4.579006500964880e-04
    ## 42 -233.84080737588255 4.105341202273754e-107 1.476119594002186e-05
    ## 55 -232.30035042456561 3.980623648741460e-107 3.066983590733346e-06
    ## 18 -231.33213290215230 1.118185458453184e-104 3.271769100192702e-04
    ## 50 -231.13829967526527 2.397741895491066e-107 5.779503581448722e-07
    ## 32 -228.79718426359659 1.856361390676742e-104 4.305435901251417e-05
    ## 48 -225.48877997017109 4.653582103001120e-104 3.947482857522776e-06
    ## 54 -223.26846315598320 5.603336258733411e-104 5.160695289252128e-07
    ## 16 -222.62917580975113 1.118185458453184e-104 5.434209845680956e-08
    ## 36 -222.06221506320821 1.496017972069519e-102 4.124121505225226e-06
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  5.106885910474275e-184 7.637693754018103e-181 7.136242521161280e-01
    ## 2  1.628626957577252e-181 3.599332481158513e-180 7.102903883474400e-01
    ## 19 3.720023852224193e-180 6.113707301933537e-180 7.101609644583602e-01
    ## 20 1.186345501891267e-177 1.544855196244699e-179 7.101594577608908e-01
    ## 9  1.222969170811842e-175 1.192886241830203e-175 7.099727091308448e-01
    ## 6  1.232402689254696e-159 1.855570156141767e-156 4.216659042821456e-01
    ## 26 1.135073482422199e-158 4.089845453407256e-156 3.839744532146235e-01
    ## 4  1.839977215057277e-157 5.945415609549022e-156 3.820433962497963e-01
    ## 43 3.103456813918082e-157 1.154636356545436e-155 3.785876170818623e-01
    ## 7  3.930231216237185e-157 1.843533613276950e-155 3.752312727752870e-01
    ## 27 3.619840553932227e-156 2.673028589780376e-155 3.747924850496090e-01
    ## 14 5.416964801756490e-156 2.807610905493841e-155 3.747449118748628e-01
    ## 22 8.977226983217805e-156 3.418475785527772e-155 3.746146152690663e-01
    ## 23 9.928726794158107e-156 3.996119000365184e-155 3.745032124278330e-01
    ## 39 8.268248992948147e-155 4.731655895539662e-155 3.744861782543101e-01
    ## 44 9.897173184263288e-155 6.811058643610482e-155 3.744459475537507e-01
    ## 3  1.539257388756622e-153 2.680109221328350e-153 3.741210160278120e-01
    ## 10 2.951290711023623e-151 2.924531117232942e-151 3.739330081352572e-01
    ## 11 1.295004288119991e-150 5.029507508384518e-151 3.739018833635829e-01
    ## 33 2.718212037518319e-150 8.518638108818500e-151 3.738773043728572e-01
    ## 21 1.121245765279982e-149 8.604626678287087e-151 3.738771575241728e-01
    ## 17 2.171232113754681e-135 3.269664071709809e-132 8.552245871060771e-02
    ## 30 2.739179290004580e-134 8.697813845362744e-132 4.757685085908359e-02
    ## 47 7.489316562983562e-133 2.230526160092765e-131 4.409776906695573e-02
    ## 29 4.089594679976873e-132 2.773341137458059e-131 4.384361228295353e-02
    ## 53 6.897846544987244e-132 4.411801654753011e-131 4.338877861644785e-02
    ## 31 8.735462885883680e-132 6.427051509801777e-131 4.294703210637552e-02
    ## 15 1.307231472626092e-131 6.754017916972758e-131 4.289913814150959e-02
    ## 25 2.396017811343379e-131 8.157396403817869e-131 4.278698410107717e-02
    ## 46 1.118154962853392e-130 9.518141179374360e-131 4.276368147688336e-02
    ## 37 1.203992650213238e-130 9.911838482685593e-131 4.275742011571260e-02
    ## 40 1.995308388119131e-130 1.169881810688028e-130 4.274027107925282e-02
    ## 41 2.206791907207039e-130 1.338861349160001e-130 4.272560875267606e-02
    ## 24 3.577254592335696e-129 1.479199197844512e-130 4.272485755347699e-02
    ## 8  3.714563001041356e-129 6.493744812591906e-129 4.239773498555610e-02
    ## 52 6.033691639686423e-129 6.536105107303698e-129 4.239639065517609e-02
    ## 28 3.421204771809404e-128 1.417705565387505e-128 4.235362467097281e-02
    ## 5  5.545842560554793e-127 2.052288054668250e-128 4.235143362899074e-02
    ## 45 9.354073921472394e-127 3.967744328000748e-128 4.234751258607194e-02
    ## 13 3.125127122973328e-126 5.510793790736197e-127 4.231617793731279e-02
    ## 34 6.559637093382345e-126 1.398760213309722e-126 4.229143320828144e-02
    ## 35 2.878319689995832e-125 2.014534673971067e-126 4.228733670982721e-02
    ## 12 4.665814794599219e-124 2.525936609764679e-126 4.228712683274238e-02
    ## 49 7.869746754624248e-124 4.069578394177270e-126 4.228675124109982e-02
    ## 38 4.825852857710483e-110 9.564837110592796e-108 4.334839807493274e-03
    ## 51 1.319458710485184e-108 3.354225606550346e-107 8.551800650072883e-04
    ## 56 1.664600459288218e-107 7.334849255291806e-107 3.972794149108561e-04
    ## 42 5.325469040710813e-106 1.144019045756556e-106 3.825182189708398e-04
    ## 55 2.485248485717331e-105 1.542081410630702e-106 3.794512353800794e-04
    ## 18 6.544272052265179e-105 1.133606272559491e-104 5.227432536081267e-05
    ## 50 7.944051408645272e-105 1.136004014454983e-104 5.169637500268554e-05
    ## 32 8.256111523112568e-104 2.992365405131724e-104 8.642015990156793e-06
    ## 48 2.257341569480753e-102 7.645947508132845e-104 4.694533132676426e-06
    ## 54 2.079067644551101e-101 1.324928376686625e-103 4.178463603676796e-06
    ## 16 3.940103104570686e-101 1.436746922531944e-103 4.124121505300060e-06
    ## 36 6.946011696110072e-101 1.639692664322714e-102 0.000000000000000e+00
    ## 58  9.999999999999627e-01  5.000000000000000e-01 0.000000000000000e+00
    ## 57  1.000000000000000e+00  1.000000000000000e+00 0.000000000000000e+00

where the first seven columns are indicators for the matching pattern for that field. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Fellegi-Sunter weight for each matching pattern

-   `p.gamma.j.m`: Probability of being in the matched set given that matching pattern

-   `p.gamma.j.u`: Probability of being in the unmatched set given that matching pattern

-   `zeta.j`: Posterior probability of a particular pattern representing a true match

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
tc <- tableCounts(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB))
```

    ## Parallelizing gamma calculation using 1 cores.

As with the functions above, `tableCounts()` also includes an `n.cores` argument. If left unspecified, the function will automatically determine the number of available cores for parallelization.

#### 3) Running the EM algorithm

We next run the EM algorithm to calculate the Fellegi-Sunter weights. The only required input to this function is the output from `tableCounts()`, as follows:

``` r
## Run EM algorithm
em.out <- emlinkMARmov(tc)

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
matches.out <- matchesLink(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB),
                           em = em.out, cut = match.ut)
```

    ## Parallelizing gamma calculation using 1 cores.

As with the other functions above, `matchesLink()` accepts an `n.cores` argument. This returns a matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

The datasets can then be subsetted down to the matches as follows:

``` r
dfA.match <- dfA[matches.out[,1],]
dfB.match <- dfB[matches.out[,2],]
```

Using Auxiliary Information to Inform `fastLink`
------------------------------------------------

The `fastLink` algorithm also includes several ways to incorporate auxiliary information on migration behavior to inform the matching of data sets over time. Auxiliary information is incorporated into the estimation as priors on two parameters of the model:

-   
    *λ*
    : The probability that a randomly selected pair of observations from dataset A and dataset B are a true match. When matching, for example, the same state to itself in subsequent years, the prior for this quantity is equal to the number of non-movers to the number of in-state movers, divided by the size of the cross-product of A and B. When matching two different states in subsequent years to find movers, the numerator is the size of the outflow from state A to state B, divided by the size of the cross-product of A and B.

-   
    *π*<sub>*k*, *l*</sub>
    : The probability that an address field does not match conditional on being in the matched set. Specified when trying to find movers within the same geography over time. For example, when trying to find movers within the same state over time, this quantity is equal to the estimated number of in-state movers divided by the number of in-state movers and non-movers.

The functions `calcMoversPriors()` and `precalcPriors()` can be used to find optimal parameter values for the corresponding prior distributions. `calcMoversPriors()` uses the IRS Statistics of Income Migration Data to estimate these parameters, while `precalcPriors()` accomodates any additional auxiliary information if the prior means are already known.

Below, we show an example where we incorporate the auxiliary moving information for California into our estimates. First, we use `calcMoversPriors()` to estimate optimal parameter values for the priors:

``` r
priors.out <- calcMoversPriors(geo.a = "CA", geo.b = "CA", year.start = 2014, year.end = 2015, 
                               var.prior.lambda = 0.0001, var.prior.pi = 0.1, L = 3)
```

    ## Your provided variance for lambda is too large given the observed mean. The function will adaptively choose a new prior variance.
    ## Your provided variance for pi is too large given the observed mean. The function will adaptively choose a new prior variance.

``` r
names(priors.out)
```

    ## [1] "lambda_prior"     "pi_prior"         "parameter_values"

where each entry in the list outputs the optimal parameter values for the prior distributions, estimated from the IRS data.

If the provided variances are too large (forcing the parameter values for the
*λ*
 prior or the
*π*<sub>*k*, *l*</sub>
 prior below 1), the function will choose new parameter values by testing the sequence
1/(10<sup>*i*</sup>)
 to find new variance values that satisfy those restrictions. The means and variances used to calculate optimal paramter values can be viewed in the `parameter_values` field of the `calcMoversPriors()` and `precalcPriors()` output.

The `calcMoversPriors()` function accepts the following functions:

-   `geo.a`: The state name or county name of dataset A

-   `geo.b`: The state name or county name of dataset B

-   `year.start`: The year of dataset A

-   `year.end`: The year of dataset B

-   `L`: The number of matching categories for address. For instance, if partial matches are being calculated, L = 3 (no match, partial match, full match)

-   `var.prior.lambda`: The prior variance for lambda

-   `var.prior.pi`: The prior variance for pi

-   `county`: Boolean, whether the geographies in `geo.a` or `geo.b` refer to counties or states. Default is FALSE

-   `state.a`: If `county = TRUE`, the name of the state for `geo.a`

-   `state.b`: If `county = TRUE`, the name of the state for `geo.b`

-   `denom.lambda.mean`: If known, the denominator for the prior mean of lambda. Can be set as the size of the cross-product of dataset A and dataset B

If the prior means are already known and do not need to be estimated from the IRS data, the user can run `precalcPriors()`, which will calculate the same paramters from that data. `precalcPriors()` takes the following arguments:

-   `L`: The number of matching categories for address. For instance, if partial matches are being calculated, L = 3 (no match, partial match, full match)

-   `lambda.mean`: The estimated prior mean for lambda

-   `pi.mean`: The estimated prior mean for pi

-   `var.prior.lambda`: The prior variance for lambda

-   `var.prior.pi`: The prior variance for pi

### Incorporating Auxiliary Information with `fastLink()` Wrapper

We can re-run the full match above while incorporating auxiliary information as follows:

``` r
matches.out.aux <- fastLink(
  df_a = dfA, df_b = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist_match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial_match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE),
  priors_obj = priors.out, 
  address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE)
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

where `priors_obj` is an input for the the optimal prior parameters calculated by `calcMoversPriors()` or `precalcPriors()`, and `address_field` is a vector of booleans of the same length as `varnames`, where `TRUE` indicates an address-related field used for matching.

### Incorporating Auxiliary Information when Running the Algorithm Step-by-Step

If we are running the algorithm step-by-step, we can incorporate the prior information into the EM algorithm as follows:

``` r
em.out.aux <- emlinkMARmov(tc, 
                           psi = priors.out$lambda_prior$psi, mu = priors.out$lambda_prior$mu,
                           alpha0 = priors.out$pi_prior$alpha_0, alpha1 = priors.out$pi_prior$alpha_1,
                           address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`address_field`).
