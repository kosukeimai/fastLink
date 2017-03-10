fastLink: Fast Probabilistic Record Linkage
===========================================

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
    ## 9        0       0       1       0       0       0       0     12
    ## 20       1       0       0       0       1       0       0      1
    ## 6        0      NA       0       0       0       0       0  48474
    ## 4        0       2       0       0       0       0       0    691
    ## 26       0       0       0       0       0       2       0  13032
    ## 43       0       0       0       0       0       0       2   1203
    ## 7        1      NA       0       0       0       0       0     48
    ## 14       0       0       0       2       0       0       0     15
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 27       1       0       0       0       0       2       0      9
    ## 3        2       0       0       0       0       0       0   1181
    ## 44       1       0       0       0       0       0       2      2
    ## 10       0      NA       1       0       0       0       0      3
    ## 39       0       0       0       0       1       2       0      4
    ## 11       0       0       2       0       0       0       0     65
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 47       0      NA       0       0       0       0       2    593
    ## 15       0      NA       0       2       0       0       0      8
    ## 29       0       2       0       0       0       2       0     75
    ## 25       0      NA       0       0       2       0       0     27
    ## 46       0       2       0       0       0       0       2     10
    ## 53       0       0       0       0       0       2       2    150
    ## 31       1      NA       0       0       0       2       0      3
    ## 37       0       0       0       2       0       2       0      4
    ## 8        2      NA       0       0       0       0       0    559
    ## 24       0       2       0       0       2       0       0      1
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 13       0      NA       2       0       0       0       0     36
    ## 52       0       0       0       0       2       0       2      1
    ## 5        2       2       0       0       0       0       0      9
    ## 28       2       0       0       0       0       2       0    153
    ## 34       0      NA       1       0       0       2       0      1
    ## 12       0       2       2       0       0       0       0      1
    ## 45       2       0       0       0       0       0       2     19
    ## 35       0       0       2       0       0       2       0      8
    ## 49       0       0       2       0       0       0       2      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 18       2      NA       0      NA       0       0       0      4
    ## 50       0      NA       0       2       0       0       2      1
    ## 42       0      NA       0       0       2       2       0      4
    ## 55       0       2       0       0       0       2       2      3
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 16       2      NA       0       2       0       0       0      1
    ## 36       0      NA       2       0       0       2       0      3
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -342.03416604413110 8.191912428160360e-150 2.863757478838720e-01
    ## 2  -333.23795049104092 6.302963473194355e-148 3.333863768687974e-03
    ## 19 -330.27688112796551 4.727020348001171e-148 1.294238890798555e-04
    ## 9  -324.20968173026074 2.942941772974319e-145 1.867486300460568e-04
    ## 20 -321.48066557487527 3.637030650874362e-146 1.506697469301736e-06
    ## 6  -297.81681114189934 1.317216602818171e-130 2.883068048486992e-01
    ## 4  -292.81085343735424 1.317216602818171e-130 1.931056964827189e-03
    ## 26 -291.57585189942228 8.840143631566646e-129 3.769145106752195e-02
    ## 43 -289.44615684828000 6.818318039757191e-129 3.455779167934082e-03
    ## 7  -289.02059558880916 1.013483506648341e-128 3.356344306575284e-03
    ## 14 -288.96187105566810 1.523407378250308e-130 4.757317474627743e-05
    ## 22 -286.05952622573375 7.600801081371847e-129 1.302966057965100e-04
    ## 23 -285.73993528229005 8.945798564488618e-129 1.114028412332929e-04
    ## 27 -282.77963634633204 6.801720952975200e-127 4.387877256779533e-04
    ## 3  -281.16131712238081 2.540874994207010e-126 3.249315259387583e-04
    ## 44 -280.64994129518982 5.246102168460637e-127 4.023070055930163e-05
    ## 10 -279.99232682802898 4.732096196686827e-126 1.880078925547961e-04
    ## 39 -279.81856698325663 5.101072453121016e-127 1.703417352296155e-05
    ## 11 -278.04414201990272 5.496289116201551e-126 3.112477167434274e-05
    ## 33 -273.75136758555192 3.175818613856050e-124 2.457899072571613e-05
    ## 21 -269.40403220621522 1.466173851914715e-124 1.468486842283143e-07
    ## 17 -253.44747324583750 2.449559256259892e-111 2.883546988135652e-01
    ## 30 -247.35849699719051 1.421448784384999e-109 3.794560785152411e-02
    ## 47 -245.22880194604824 1.096349821122290e-109 3.479081792127839e-03
    ## 15 -244.74451615343634 2.449559256259892e-111 4.789396486594220e-05
    ## 29 -242.35253929264536 1.421448784384999e-109 2.541567840021710e-04
    ## 25 -241.52258038005826 1.438437544095904e-109 1.121540404324386e-04
    ## 46 -240.22284424150311 1.096349821122290e-109 2.330262419375648e-05
    ## 53 -238.98784270357118 7.357855851822296e-108 4.548336665057549e-04
    ## 31 -238.56228144410031 1.093681096516207e-107 4.417465100722750e-04
    ## 37 -238.50355691095925 1.643955566080896e-109 6.261361170859719e-06
    ## 8  -236.94396222014905 4.085593879824472e-107 3.271225679208135e-04
    ## 24 -236.51662267551310 1.438437544095904e-109 7.511991991456039e-07
    ## 40 -235.60121208102490 8.202257270636304e-108 1.714903645973134e-05
    ## 41 -235.28162113758120 9.653685253920789e-108 1.466232657672632e-05
    ## 13 -233.82678711767099 8.837744960336842e-107 3.133464875913262e-05
    ## 52 -233.15192608643889 7.445794894317219e-108 1.344330380025045e-06
    ## 5  -231.93800451560392 4.085593879824472e-107 2.191041982055012e-06
    ## 28 -230.70300297767196 2.741936036990842e-105 4.276598420332113e-05
    ## 34 -229.53401268332016 5.106549956918426e-105 2.474472903135143e-05
    ## 12 -228.82082941312584 8.837744960336842e-107 2.098770847899037e-07
    ## 45 -228.57330792652971 2.114828980619440e-105 3.921042918758394e-06
    ## 35 -227.58582787519390 5.931213944721026e-105 4.096498454286010e-06
    ## 49 -225.45613282405165 4.574688457837178e-105 3.755916426362859e-07
    ## 38 -202.98915910112865  2.643394427036606e-90 3.795191143360645e-02
    ## 51 -200.85946404998637  2.038824781500039e-90 3.479659742485983e-03
    ## 56 -194.77048780133939  1.183104674782263e-88 4.579006500964880e-04
    ## 18 -192.57462432408715  7.597766596800613e-88 3.271769100192702e-04
    ## 50 -192.15650695758521  2.038824781500039e-90 5.779503581448734e-07
    ## 42 -191.06426623534941  1.552262015293709e-88 1.476119594002186e-05
    ## 55 -189.76453009679426  1.183104674782263e-88 3.066983590733346e-06
    ## 32 -186.48564807544022  4.408889503474434e-86 4.305435901251417e-05
    ## 48 -184.35595302429792  3.400534209590679e-86 3.947482857522776e-06
    ## 16 -183.87166723168602  7.597766596800613e-88 5.434209845680966e-08
    ## 36 -183.36847297296214  9.537081299839622e-86 4.124121505225226e-06
    ## 54 -178.11499378182086  2.282176733311822e-84 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948859  5.000000000000000e-01 2.444122297210036e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  5.477460016932761e-153 8.191912428160360e-150 7.136242521161280e-01
    ## 2  3.620154389873716e-149 6.384882597475959e-148 7.102903883474400e-01
    ## 19 6.993638458045495e-148 1.111190294547713e-147 7.101609644583602e-01
    ## 9  3.017549453847820e-145 2.954053675919796e-145 7.099742158283140e-01
    ## 20 4.622224696632647e-144 3.317756741007233e-145 7.099727091308448e-01
    ## 6  8.748477001911993e-134 1.317216602818175e-130 4.216659042821456e-01
    ## 4  1.306147616385472e-131 2.634433205636346e-130 4.197348473173184e-01
    ## 26 4.491036815953509e-131 9.103586952130280e-129 3.820433962497963e-01
    ## 43 3.777995394089443e-130 1.592190499188747e-128 3.785876170818623e-01
    ## 7  5.782029868821537e-130 2.605674005837088e-128 3.752312727752870e-01
    ## 14 6.131744800919962e-130 2.620908079619592e-128 3.751836996005408e-01
    ## 22 1.117008340010843e-128 3.380988187756776e-128 3.750534029947442e-01
    ## 23 1.537634090056425e-128 4.275568044205638e-128 3.749420001535110e-01
    ## 27 2.968209095839955e-127 7.229277757395764e-127 3.745032124278330e-01
    ## 3  1.497344047770311e-126 3.263802769946587e-126 3.741782809018942e-01
    ## 44 2.496946863793688e-126 3.788412986792651e-126 3.741380502013349e-01
    ## 10 4.819562701966102e-126 8.520509183479477e-126 3.739500423087802e-01
    ## 39 5.734170161983309e-126 9.030616428791578e-126 3.739330081352572e-01
    ## 11 3.381376629281022e-125 1.452690554499313e-125 3.739018833635829e-01
    ## 33 2.474125899467487e-123 3.321087669305981e-124 3.738773043728572e-01
    ## 21 1.911813666378261e-121 4.787261521220696e-124 3.738771575241728e-01
    ## 17 1.626638579710550e-114 2.449559256260370e-111 8.552245871060771e-02
    ## 30 7.172983860703850e-112 1.445944376947603e-109 4.757685085908359e-02
    ## 47 6.034130001195333e-111 2.542294198069893e-109 4.409776906695573e-02
    ## 15 9.793486069567369e-111 2.566789790632492e-109 4.404987510208980e-02
    ## 29 1.070926490403094e-109 3.988238575017491e-109 4.379571831808760e-02
    ## 25 2.455874882268381e-109 5.426676119113395e-109 4.368356427765518e-02
    ## 46 9.008956091784711e-109 6.523025940235685e-109 4.366026165346149e-02
    ## 53 3.097624875929196e-108 8.010158445845864e-108 4.320542798695570e-02
    ## 31 4.740757382353679e-108 1.894696941100794e-107 4.276368147688336e-02
    ## 37 5.027492955098767e-108 1.911136496761603e-107 4.275742011571260e-02
    ## 8  2.391524525121728e-107 5.996730376586075e-107 4.243029754779171e-02
    ## 24 3.666621199226725e-107 6.011114752027033e-107 4.242954634859264e-02
    ## 40 9.158488721429462e-107 6.831340479090664e-107 4.241239731213287e-02
    ## 41 1.260725096406221e-106 7.796709004482743e-107 4.239773498555610e-02
    ## 13 5.400659353901196e-106 1.663445396481958e-106 4.236640033679695e-02
    ## 52 1.060559911358588e-105 1.737903345425131e-106 4.236505600641693e-02
    ## 5  3.570546116006771e-105 2.146462733407578e-106 4.236286496443487e-02
    ## 28 1.227690795349909e-104 2.956582310331600e-105 4.232009898023159e-02
    ## 34 3.951618718240629e-104 8.063132267250027e-105 4.229535425120023e-02
    ## 12 8.063184415374325e-104 8.151509716853394e-105 4.229514437411541e-02
    ## 45 1.032770462651664e-103 1.026633869747283e-104 4.229122333119673e-02
    ## 35 2.772432274039673e-103 1.619755264219386e-104 4.228712683274238e-02
    ## 49 2.332253506481818e-102 2.077224110003104e-104 4.228675124109982e-02
    ## 38  1.333700971827628e-92  2.643394427036627e-90 4.334839807493274e-03
    ## 51  1.121949415056756e-91  4.682219208536666e-90 8.551800650072883e-04
    ## 56  4.947457380582189e-89  1.229926866867630e-88 3.972794149108561e-04
    ## 18  4.446655178994880e-88  8.827693463668244e-88 7.010250489158931e-05
    ## 50  6.754909236858942e-88  8.848081711483244e-88 6.952455453346218e-05
    ## 42  2.013602012163954e-87  1.040034372677695e-87 5.476335859344594e-05
    ## 55  7.386553869209062e-87  1.158344840155922e-87 5.169637500268554e-05
    ## 32  1.960840363120000e-85  4.524723987490026e-86 8.642015990156793e-06
    ## 48  1.649517954093951e-84  7.925258197080705e-86 4.694533132676426e-06
    ## 16  2.677193083629328e-84  8.001235863048711e-86 4.640191034188668e-06
    ## 36  4.428067008031926e-84  1.753831716288833e-85 5.160695289996298e-07
    ## 54  8.467812007499367e-82  2.457559904940706e-84 0.000000000000000e+00
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
    *γ*
    : The probability that a randomly selected pair of observations from dataset A and dataset B are a true match. When matching, for example, the same state to itself in subsequent years, the prior for this quantity is equal to the number of non-movers to the number of in-state movers, divided by the size of the cross-product of A and B. When matching two different states in subsequent years to find movers, the numerator is the size of the outflow from state A to state B, divided by the size of the cross-product of A and B.

-   
    *π*<sub>*k*, *l*</sub>
    : The probability that an address field does not match conditional on being in the matched set. Specified when trying to find movers within the same geography over time. For example, when trying to find movers within the same state over time, this quantity is equal to the estimated number of in-state movers divided by the number of in-state movers and non-movers.

The functions `calcMoversPriors()` and `precalcPriors()` can be used to find optimal parameter values for the corresponding prior distributions. `calcMoversPriors()` uses the IRS Statistics of Income Migration Data to estimate these parameters, while `precalcPriors()` accomodates any additional auxiliary information if the prior means are already known.

Below, we show an example where we incorporate the auxiliary moving information for California into our estimates. First, we use `calcMoversPriors()` to estimate optimal parameter values for the priors:

``` r
priors.out <- calcMoversPriors(geo.a = "CA", geo.b = "CA", year.start = 2014, year.end = 2015, 
                               var.prior.gamma = 0.0001, var.prior.pi = 0.1, L = 3)
```

    ## Your provided variance for gamma is too large given the observed mean. The function will adaptively choose a new prior variance.
    ## Your provided variance for pi is too large given the observed mean. The function will adaptively choose a new prior variance.

``` r
names(priors.out)
```

    ## [1] "gamma_prior"      "pi_prior"         "parameter_values"

where each entry in the list outputs the optimal parameter values for the prior distributions, estimated from the IRS data.

If the provided variances are too large (forcing the parameter values for the
*γ*
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

-   `var.prior.gamma`: The prior variance for gamma

-   `var.prior.pi`: The prior variance for pi

-   `county`: Boolean, whether the geographies in `geo.a` or `geo.b` refer to counties or states. Default is FALSE

-   `state.a`: If `county = TRUE`, the name of the state for `geo.a`

-   `state.b`: If `county = TRUE`, the name of the state for `geo.b`

-   `denom.gamma.mean`: If known, the denominator for the prior mean of gamma. Can be set as the size of the cross-product of dataset A and dataset B

If the prior means are already known and do not need to be estimated from the IRS data, the user can run `precalcPriors()`, which will calculate the same paramters from that data. `precalcPriors()` takes the following arguments:

-   `L`: The number of matching categories for address. For instance, if partial matches are being calculated, L = 3 (no match, partial match, full match)

-   `gamma.mean`: The estimated prior mean for gamma

-   `pi.mean`: The estimated prior mean for pi

-   `var.prior.gamma`: The prior variance for gamma

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
  address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE)
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
                           psi = priors.out$gamma_prior$psi, mu = priors.out$gamma_prior$mu,
                           alpha0 = priors.out$pi_prior$alpha_0, alpha1 = priors.out$pi_prior$alpha_1,
                           address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`address_field`).
