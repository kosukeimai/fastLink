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

matches.out <- fastLink(df_a = dfA, df_b = dfB, varnames = c("firstname", "middlename", 
    "lastname", "housenum", "streetname", "city", "birthyear"), stringdist_match = c(TRUE, 
    TRUE, TRUE, FALSE, TRUE, TRUE, FALSE), partial_match = c(TRUE, FALSE, TRUE, 
    FALSE, TRUE, FALSE, FALSE))
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
    ## 4        0       2       0       0       0       0       0    691
    ## 26       0       0       0       0       0       2       0  13032
    ## 7        1      NA       0       0       0       0       0     48
    ## 43       0       0       0       0       0       0       2   1203
    ## 14       0       0       0       2       0       0       0     15
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 27       1       0       0       0       0       2       0      9
    ## 44       1       0       0       0       0       0       2      2
    ## 3        2       0       0       0       0       0       0   1181
    ## 39       0       0       0       0       1       2       0      4
    ## 10       0      NA       1       0       0       0       0      3
    ## 11       0       0       2       0       0       0       0     65
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 47       0      NA       0       0       0       0       2    593
    ## 15       0      NA       0       2       0       0       0      8
    ## 29       0       2       0       0       0       2       0     75
    ## 25       0      NA       0       0       2       0       0     27
    ## 31       1      NA       0       0       0       2       0      3
    ## 46       0       2       0       0       0       0       2     10
    ## 53       0       0       0       0       0       2       2    150
    ## 37       0       0       0       2       0       2       0      4
    ## 24       0       2       0       0       2       0       0      1
    ## 8        2      NA       0       0       0       0       0    559
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 52       0       0       0       0       2       0       2      1
    ## 5        2       2       0       0       0       0       0      9
    ## 28       2       0       0       0       0       2       0    153
    ## 13       0      NA       2       0       0       0       0     36
    ## 45       2       0       0       0       0       0       2     19
    ## 34       0      NA       1       0       0       2       0      1
    ## 12       0       2       2       0       0       0       0      1
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
    ## 1  -403.34865006226613 1.926829253389861e-176 2.863757478838720e-01
    ## 2  -396.88444558028789 1.439538155734743e-175 3.333863768687974e-03
    ## 19 -392.13822123699913 6.435003971635385e-175 1.294238890798555e-04
    ## 20 -385.67401675502083 4.807604894505642e-174 1.506697469301736e-06
    ## 9  -381.91061831131896 2.567930773042685e-170 1.867486300460568e-04
    ## 6  -350.70132885051476 1.419720904711859e-153 2.883068048486992e-01
    ## 4  -345.69537114596966 1.419720904711859e-153 1.931056964827189e-03
    ## 26 -344.98093706333054 5.661422011195896e-152 3.769145106752195e-02
    ## 7  -344.23712436853651 1.060676450303743e-152 3.356344306575284e-03
    ## 43 -342.61551324734569 5.527377985933364e-152 3.455779167934082e-03
    ## 14 -341.84185000462577 1.649426599612396e-153 4.757317474627734e-05
    ## 22 -339.49090002524770 4.741421506011677e-152 1.302966057965100e-04
    ## 23 -339.15454394125072 5.674783811971701e-152 1.114028412332929e-04
    ## 27 -338.51673258135224 4.229660197703070e-151 4.387877256779533e-04
    ## 44 -336.15130876536745 4.129515626732803e-151 4.023070055930163e-05
    ## 3  -334.02417259022036 2.798574495078179e-149 3.249315259387583e-04
    ## 39 -333.77050823806348 1.890736974387130e-150 1.703417352296155e-05
    ## 10 -329.26329709956752 1.892095521140676e-147 1.880078925547961e-04
    ## 11 -327.31464378136559 2.198682571350029e-147 3.112477167434274e-05
    ## 33 -323.54290531238337 7.545110588369091e-146 2.457899072571613e-05
    ## 21 -322.81374376495330 9.346359029511170e-148 1.468486842283143e-07
    ## 17 -297.89748588527550 1.215325862495529e-130 2.883546988135652e-01
    ## 30 -292.33361585157911 4.171433024255027e-129 3.794560785152411e-02
    ## 47 -289.96819203559437 4.072667083016282e-129 3.479081792127839e-03
    ## 15 -289.19452879287439 1.215325862495529e-130 4.789396486594211e-05
    ## 29 -287.32765814703396 4.171433024255027e-129 2.541567840021710e-04
    ## 25 -286.50722272949935 4.181278228676838e-129 1.121540404324386e-04
    ## 31 -285.86941136960081 3.116486316544461e-128 4.417465100722750e-04
    ## 46 -284.96223433104922 4.072667083016282e-129 2.330262419375648e-05
    ## 53 -284.24780024841010 1.624057727933572e-127 4.548336665057549e-04
    ## 37 -283.47413700569018 4.846355763215214e-129 6.261361170859708e-06
    ## 24 -281.50126502495419 4.181278228676838e-129 7.511991991456039e-07
    ## 8  -281.37685137846893 2.062037778939742e-126 3.271225679208135e-04
    ## 40 -281.12318702631211 1.393127493329625e-127 1.714903645973134e-05
    ## 41 -280.78683094231508 1.667368601828795e-127 1.466232657672632e-05
    ## 52 -278.42140712633034 1.627890746522474e-127 1.344330380025045e-06
    ## 5  -276.37089367392377 2.062037778939742e-126 2.191041982055012e-06
    ## 28 -275.65645959128472 8.222789444645304e-125 4.276598420332113e-05
    ## 13 -274.66732256961421 1.620027100937767e-124 3.133464875913262e-05
    ## 45 -273.29103577529992 8.028100584873079e-125 3.921042918758394e-06
    ## 34 -270.89558410063194 5.559367137397107e-123 2.474472903135143e-05
    ## 12 -269.66136486506906 1.620027100937767e-124 2.098770847899037e-07
    ## 35 -268.94693078243000 6.460183165256974e-123 4.096498454286010e-06
    ## 49 -266.58150696644520 6.307227078660030e-123 3.755916426362859e-07
    ## 38 -239.52977288633991 3.570878206568145e-106 3.795191143360645e-02
    ## 51 -237.16434907035512 3.486331446481256e-106 3.479659742485983e-03
    ## 56 -231.60047903665870 1.196633641901471e-104 4.579006500964880e-04
    ## 18 -228.57300841322970 1.765169361013849e-103 3.271769100192702e-04
    ## 50 -228.46139197795395 3.486331446481256e-106 5.779503581448722e-07
    ## 42 -228.13950973056370 1.228545838045583e-104 1.476119594002186e-05
    ## 55 -226.59452133211357 1.196633641901471e-104 3.066983590733346e-06
    ## 32 -223.00913837953334 6.058692563997990e-102 4.305435901251417e-05
    ## 48 -220.64371456354851 5.915242466566565e-102 3.947482857522776e-06
    ## 16 -219.87005132082857 1.765169361013849e-103 5.434209845680956e-08
    ## 36 -216.29960957067860 4.759973968553549e-100 4.124121505225226e-06
    ## 54 -214.92332277636430 2.358821638156864e-100 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  1.288359743522000e-179 1.926829253389861e-176 7.136242521161280e-01
    ## 2  8.268095469753246e-177 1.632221081073729e-175 7.102903883474400e-01
    ## 19 9.520604512044208e-175 8.067225052709114e-175 7.101609644583602e-01
    ## 20 6.109882541048621e-172 5.614327399776553e-174 7.101594577608908e-01
    ## 9  2.633031401733269e-170 2.568492205782662e-170 7.099727091308448e-01
    ## 6  9.429273558678256e-157 1.419720904711859e-153 4.216659042821456e-01
    ## 4  1.407790542310676e-154 2.839441809423717e-153 4.197348473173184e-01
    ## 26 2.876158549295472e-154 5.945366192138268e-152 3.820433962497963e-01
    ## 7  6.051270569852329e-154 7.006042642442011e-152 3.786870519432211e-01
    ## 43 3.062692067234705e-153 1.253342062837537e-151 3.752312727752870e-01
    ## 14 6.638974657119332e-153 1.269836328833661e-151 3.751836996005408e-01
    ## 22 6.967959441409189e-152 1.743978479434829e-151 3.750534029947442e-01
    ## 23 9.754010198291161e-152 2.311456860631999e-151 3.749420001535110e-01
    ## 27 1.845785200235669e-151 6.541117058335069e-151 3.745032124278330e-01
    ## 44 1.965493763188205e-150 1.067063268506787e-150 3.744629817272737e-01
    ## 3  1.649207014119526e-149 2.905280821928857e-149 3.741380502013349e-01
    ## 39 2.125397677120991e-149 3.094354519367570e-149 3.741210160278120e-01
    ## 10 1.927068390670382e-147 1.923039066334352e-147 3.739330081352572e-01
    ## 11 1.352653345701086e-146 4.121721637684381e-147 3.739018833635829e-01
    ## 33 5.878028877211082e-145 7.957282752137529e-146 3.738773043728572e-01
    ## 21 1.218716109291021e-144 8.050746342432641e-146 3.738771575241728e-01
    ## 17 8.070414829946156e-134 1.215325862495530e-130 8.552245871060771e-02
    ## 30 2.105008783129262e-131 4.292965610504580e-129 4.757685085908359e-02
    ## 47 2.241529314553339e-130 8.365632693520862e-129 4.409776906695573e-02
    ## 15 4.858946307960680e-130 8.487165279770415e-129 4.404987510208980e-02
    ## 29 3.142778113212016e-129 1.265859830402544e-128 4.379571831808760e-02
    ## 25 7.138784870939607e-129 1.683987653270228e-128 4.368356427765518e-02
    ## 31 1.350897035637285e-128 4.800473969814689e-128 4.324181776758296e-02
    ## 46 3.346603266627974e-128 5.207740678116317e-128 4.321851514338915e-02
    ## 53 6.837211436734167e-128 2.144831795745204e-127 4.276368147688336e-02
    ## 37 1.482097202636142e-127 2.193295353377356e-127 4.275742011571260e-02
    ## 24 1.065820581231292e-126 2.235108135664124e-127 4.275666891651342e-02
    ## 8  1.207024991988140e-126 2.285548592506154e-126 4.242954634859264e-02
    ## 40 1.555540385309474e-126 2.424861341839117e-126 4.241239731213287e-02
    ## 41 2.177503601986216e-126 2.591598202021996e-126 4.239773498555610e-02
    ## 52 2.318725791320173e-125 2.754387276674244e-126 4.239639065517609e-02
    ## 5  1.802088313038309e-124 4.816425055613985e-126 4.239419961319402e-02
    ## 28 3.681720790383578e-124 8.704431950206703e-125 4.235143362899074e-02
    ## 13 9.899826885159988e-124 2.490470295958437e-124 4.232009898023159e-02
    ## 45 3.920499118952374e-123 3.293280354445745e-124 4.231617793731279e-02
    ## 34 4.302023759103149e-122 5.888695172841682e-123 4.229143320828144e-02
    ## 12 1.478044153954399e-121 6.050697882935458e-123 4.229122333119673e-02
    ## 35 3.019688797350929e-121 1.251088104819243e-122 4.228712683274238e-02
    ## 49 3.215530982264210e-120 1.881810812685246e-122 4.228675124109982e-02
    ## 38 1.801654602002412e-108 3.570878206568145e-106 4.334839807493274e-03
    ## 51 1.918501071090470e-107 7.057209653049401e-106 8.551800650073993e-04
    ## 56 5.004032246401137e-105 1.267205738431965e-104 3.972794149108561e-04
    ## 18 1.033079837469677e-103 1.891889934857045e-103 7.010250489158931e-05
    ## 50 1.155069955215157e-103 1.895376266303527e-103 6.952455453346218e-05
    ## 42 1.593675775836182e-103 2.018230850108085e-103 5.476335859344594e-05
    ## 55 7.471020143876750e-103 2.137894214298232e-103 5.169637500268554e-05
    ## 32 2.694585318561535e-101 6.272481985427814e-102 8.642015990156793e-06
    ## 48 2.869342888508985e-100 1.218772445199438e-101 4.694533132676426e-06
    ## 16 6.219853090420873e-100 1.236424138809576e-101 4.640191034188668e-06
    ## 36  2.210055993713424e-98 4.883616382434507e-100 5.160695289996298e-07
    ## 54  8.752196050192967e-98 7.242438020591371e-100 0.000000000000000e+00
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
