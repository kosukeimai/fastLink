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

    FALSE 
    FALSE ==================== 
    FALSE fastLink(): Fast Probabilistic Record Linkage
    FALSE ==================== 
    FALSE 
    FALSE Calculating matches for each variable.
    FALSE Getting counts for zeta parameters.
    FALSE Parallelizing gamma calculation using 1 cores.
    FALSE Running the EM algorithm.
    FALSE Getting the indices of estimated matches.
    FALSE Parallelizing gamma calculation using 1 cores.

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
    ## 7        1      NA       0       0       0       0       0     48
    ## 43       0       0       0       0       0       0       2   1203
    ## 14       0       0       0       2       0       0       0     15
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 27       1       0       0       0       0       2       0      9
    ## 44       1       0       0       0       0       0       2      2
    ## 39       0       0       0       0       1       2       0      4
    ## 3        2       0       0       0       0       0       0   1181
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
    ## 53       0       0       0       0       0       2       2    150
    ## 46       0       2       0       0       0       0       2     10
    ## 37       0       0       0       2       0       2       0      4
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 24       0       2       0       0       2       0       0      1
    ## 8        2      NA       0       0       0       0       0    559
    ## 52       0       0       0       0       2       0       2      1
    ## 28       2       0       0       0       0       2       0    153
    ## 5        2       2       0       0       0       0       0      9
    ## 13       0      NA       2       0       0       0       0     36
    ## 45       2       0       0       0       0       0       2     19
    ## 34       0      NA       1       0       0       2       0      1
    ## 35       0       0       2       0       0       2       0      8
    ## 12       0       2       2       0       0       0       0      1
    ## 49       0       0       2       0       0       0       2      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 42       0      NA       0       0       2       2       0      4
    ## 18       2      NA       0      NA       0       0       0      4
    ## 50       0      NA       0       2       0       0       2      1
    ## 55       0       2       0       0       0       2       2      3
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 16       2      NA       0       2       0       0       0      1
    ## 36       0      NA       2       0       0       2       0      3
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -418.56521773105476 4.746482228464756e-183 2.863757478838720e-01
    ## 2  -411.36873388974891 7.375249103916368e-182 3.333863768687974e-03
    ## 19 -408.09735008825902 7.543748884093731e-182 1.294238890798555e-04
    ## 20 -400.90086624695317 1.172173928386854e-180 1.506697469301736e-06
    ## 9  -399.29492632604416 7.238928202814724e-178 1.867486300460568e-04
    ## 6  -362.94484188802454 6.837743822925882e-159 2.883068048486992e-01
    ## 26 -358.31552342184369 9.157738859720653e-158 3.769145106752195e-02
    ## 4  -357.93888418347944 6.837743822925882e-159 1.931056964827189e-03
    ## 7  -355.74835804671869 1.062472407468706e-157 3.356344306575284e-03
    ## 43 -355.61169199772507 1.254152786484739e-157 3.455779167934082e-03
    ## 14 -354.11238763210298 7.732255788607250e-159 4.757317474627734e-05
    ## 22 -352.47697424522880 1.086746349213660e-157 1.302966057965100e-04
    ## 23 -352.13632120319318 1.306276431102175e-157 1.114028412332929e-04
    ## 27 -351.11903958053784 1.422961302035611e-156 4.387877256779533e-04
    ## 44 -348.41520815641923 1.948746201813462e-156 4.023070055930163e-05
    ## 39 -347.84765577904795 1.455471209594744e-156 1.703417352296155e-05
    ## 3  -347.06042981918591 6.100455909442464e-155 3.249315259387583e-04
    ## 10 -343.67455048301395 1.042834128958919e-153 1.880078925547961e-04
    ## 11 -341.75119952930976 1.181533486741306e-153 3.112477167434274e-05
    ## 33 -339.04523201683315 1.396659903371903e-152 2.457899072571613e-05
    ## 21 -336.59256217639023 9.695666231157930e-154 1.468486842283143e-07
    ## 17 -307.19496888147387 1.113902501072594e-134 2.883546988135652e-01
    ## 30 -302.69514757881348 1.319256436788072e-133 3.794560785152411e-02
    ## 47 -299.99131615469486 1.806722337937744e-133 3.479081792127839e-03
    ## 15 -298.49201178907276 1.113902501072594e-134 4.789396486594211e-05
    ## 29 -297.68918987426832 1.319256436788072e-133 2.541567840021710e-04
    ## 25 -296.51594536016296 1.881811237854693e-133 1.121540404324386e-04
    ## 31 -295.49866373750757 2.049906517063739e-132 4.417465100722750e-04
    ## 53 -295.36199768851401 2.419729634705303e-132 4.548336665057549e-04
    ## 46 -294.98535845014970 1.806722337937744e-133 2.330262419375648e-05
    ## 37 -293.86269332289191 1.491841239475829e-133 6.261361170859708e-06
    ## 40 -292.22727993601774 2.096740026365271e-132 1.714903645973134e-05
    ## 41 -291.88662689398211 2.520295633448560e-132 1.466232657672632e-05
    ## 24 -291.50998765561781 1.881811237854693e-133 7.511991991456039e-07
    ## 8  -291.44005397615570 8.788267332313185e-131 3.271225679208135e-04
    ## 52 -289.18279546986349 3.451546107475957e-132 1.344330380025045e-06
    ## 28 -286.81073550997490 1.177006032149002e-129 4.276598420332113e-05
    ## 5  -286.43409627161054 8.788267332313185e-131 2.191041982055012e-06
    ## 13 -286.13082368627954 1.702107563385652e-129 3.133464875913262e-05
    ## 45 -284.10690408585623 1.611910338939421e-129 3.921042918758394e-06
    ## 34 -283.42485617380288 2.012016935350239e-128 2.474472903135143e-05
    ## 35 -281.50150522009869 2.279619854195023e-128 4.096498454286010e-06
    ## 12 -281.12486598173439 1.702107563385652e-129 2.098770847899037e-07
    ## 49 -278.79767379598007 3.121940509615967e-128 3.755916426362859e-07
    ## 38 -246.94527457226286 2.149134396593197e-109 3.795191143360645e-02
    ## 51 -244.24144314814421 2.943240611361930e-109 3.479659742485983e-03
    ## 56 -239.74162184548379 3.485842897216220e-108 4.579006500964880e-04
    ## 42 -236.26625105095187 3.630717459809173e-108 1.476119594002186e-05
    ## 18 -235.69018096960505 1.431652488754559e-106 3.271769100192702e-04
    ## 50 -235.53848605574305 2.943240611361930e-109 5.779503581448722e-07
    ## 55 -234.73566414093867 3.485842897216220e-108 3.066983590733346e-06
    ## 32 -231.19035966694463 1.695585349000019e-105 4.305435901251417e-05
    ## 48 -228.48652824282601 2.322104967989883e-105 3.947482857522776e-06
    ## 16 -226.98722387720392 1.431652488754559e-106 5.434209845680956e-08
    ## 36 -225.88112937706848 3.284001883155257e-104 4.124121505225226e-06
    ## 54 -223.85720977664519 3.109977713761539e-104 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  3.173699286399242e-186 4.746482228464756e-183 7.136242521161280e-01
    ## 2  4.236029691986085e-183 7.849897326762844e-182 7.102903883474400e-01
    ## 19 1.116099539024507e-181 1.539364621085657e-181 7.101609644583602e-01
    ## 20 1.489690849659486e-178 1.326110390495420e-180 7.101594577608908e-01
    ## 9  7.422445134811631e-178 7.252189306719677e-178 7.099727091308448e-01
    ## 6  4.541382522194825e-162 6.837743822925882e-159 4.216659042821456e-01
    ## 26 4.652383952567625e-160 9.841513242013241e-158 3.839744532146235e-01
    ## 4  6.780284105636933e-160 1.052528762430583e-157 3.820433962497963e-01
    ## 7  6.061516694138339e-159 2.115001169899289e-157 3.786870519432211e-01
    ## 43 6.949196888727884e-159 3.369153956384029e-157 3.752312727752870e-01
    ## 14 3.112248234325248e-158 3.446476514270101e-157 3.751836996005408e-01
    ## 22 1.597074732718699e-157 4.533222863483761e-157 3.750534029947442e-01
    ## 23 2.245272076070681e-157 5.839499294585936e-157 3.749420001535110e-01
    ## 27 6.209673564868704e-157 2.006911231494205e-156 3.745032124278330e-01
    ## 44 9.275297279190790e-156 3.955657433307667e-156 3.744629817272737e-01
    ## 39 1.636110770506231e-155 5.411128642902410e-156 3.744459475537507e-01
    ## 3  3.595014066223159e-155 6.641568773732706e-155 3.741210160278120e-01
    ## 10 1.062109531033343e-153 1.109249816696246e-153 3.739330081352572e-01
    ## 11 7.268922056889604e-153 2.290783303437553e-153 3.739018833635829e-01
    ## 33 1.088069836420705e-151 1.625738233715658e-152 3.738773043728572e-01
    ## 21 1.264263933036515e-150 1.722694896027238e-152 3.738771575241728e-01
    ## 17 7.396909373187515e-138 1.113902501072594e-134 8.552245871060771e-02
    ## 30 6.657295875281746e-136 1.430646686895331e-133 4.757685085908359e-02
    ## 47 9.943904083479458e-135 3.237369024833075e-133 4.409776906695573e-02
    ## 15 4.453449574339787e-134 3.348759274940334e-133 4.404987510208980e-02
    ## 29 9.939342741795732e-134 4.668015711728406e-133 4.379571831808760e-02
    ## 25 3.212856179391905e-133 6.549826949583098e-133 4.368356427765518e-02
    ## 31 8.885688419467992e-133 2.704889212022049e-132 4.324181776758296e-02
    ## 53 1.018695508641943e-132 5.124618846727352e-132 4.278698410107717e-02
    ## 46 1.484624879663412e-132 5.305291080521126e-132 4.276368147688336e-02
    ## 37 4.562301729036671e-132 5.454475204468709e-132 4.275742011571260e-02
    ## 40 2.341181122418865e-131 7.551215230833981e-132 4.274027107925282e-02
    ## 41 3.291385488418758e-131 1.007151086428254e-131 4.272560875267606e-02
    ## 24 4.796794275832156e-131 1.025969198806801e-131 4.272485755347699e-02
    ## 8  5.144259923224687e-131 9.814236531119986e-131 4.239773498555610e-02
    ## 52 4.916293674149688e-130 1.015939114186758e-130 4.239639065517609e-02
    ## 28 5.269997010311126e-129 1.278599943567678e-129 4.235362467097281e-02
    ## 5  7.680380065374523e-129 1.366482616890810e-129 4.235143362899074e-02
    ## 13 1.040141254901559e-128 3.068590180276462e-129 4.232009898023159e-02
    ## 45 7.871716350377702e-128 4.680500519215883e-129 4.231617793731279e-02
    ## 34 1.556965828244840e-127 2.480066987271827e-128 4.229143320828144e-02
    ## 35 1.065564607045882e-126 4.759686841466850e-128 4.228733670982721e-02
    ## 12 1.552930893568042e-126 4.929897597805415e-128 4.228712683274238e-02
    ## 49 1.591618045182001e-125 8.051838107421382e-128 4.228675124109982e-02
    ## 38 1.084326502321417e-111 2.149134396593197e-109 4.334839807493274e-03
    ## 51 1.619642409809870e-110 5.092375007955128e-109 8.551800650073993e-04
    ## 56 1.457695125121226e-108 3.995080398011732e-108 3.972794149108561e-04
    ## 42 4.709784759686494e-107 7.625797857820905e-108 3.825182189708398e-04
    ## 18 8.378863541717763e-107 1.507910467332768e-106 5.534130895157308e-05
    ## 50 9.751364301820793e-107 1.510853707944130e-106 5.476335859344594e-05
    ## 55 2.176338821806009e-106 1.545712136916292e-106 5.169637500268554e-05
    ## 32 7.541064907192743e-105 1.850156562691648e-105 8.642015990156793e-06
    ## 48 1.126397677514034e-103 4.172261530681531e-105 4.694533132676426e-06
    ## 16 5.044653704772138e-103 4.315426779556987e-105 4.640191034188668e-06
    ## 36 1.524762129621255e-102 3.715544561110956e-104 5.160695289996298e-07
    ## 54 1.153929327350091e-101 6.825522274872495e-104 0.000000000000000e+00
    ## 58  9.999999999999627e-01  5.000000000000000e-01 0.000000000000000e+00
    ## 57  1.000000000000000e+00  1.000000000000000e+00 0.000000000000000e+00

where the first seven columns are indicators for the matching pattern for that field. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Felligi-Sunter weight for each matching pattern

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

We next run the EM algorithm to calculate the Felligi-Sunter weights. The only required input to this function is the output from `tableCounts()`, as follows:

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

The code following `emlinkMARmov()` sorts the linkage patterns by the Felligi-Sunter weight, and then selects the lowest weight that is still classified as a positive match according to the posterior probability that a linkage pattern is in the matched set. In this case, we've chosen that probability to be 0.85.

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

The `fastLink` algorithm also incorporates a number of functionalities to incorporate auxiliary information on migration behavior to inform the matching of data sets over time. Auxiliary information is incorporated into the algorithm as priors on two parameters of the model:

-   
    *γ*
    :
    $${\\rm Pr}((a, b) \\in {\\rm Matched \\ Set})$$
    , equivalent to the probability that a randomly selected pair of observations from dataset A and dataset B are a true match. When matching, for example, the same state to itself in subsequent years, the prior for this quantity is equal to the number of non-movers to the number of in-state movers, divided by the size of the cross-product of A and B. When matching two different states in subsequent years to find movers, the numerator is the size of the outflow from state A to state B, divided by the size of the cross-product of A and B.

-   
    *π*<sub>*k*, *l*</sub>
    :
    $${\\rm Pr}({\\rm Address \\ Does \\ Not \\ Match} | (a, b) \\in {\\rm Matched \\ Set})$$
    , can be used when trying to find movers within the same geography over time. For example, when trying to find movers within the same state over time, this quantity is equal to the estimated number of in-state movers divided by the number of in-state movers and non-movers.

The functions `calcMoversPriors()` and `precalcPriors()` can be used to find optimal parameter values for the corresponding prior distributions. `calcMoversPriors()` uses the IRS Statistics of Income Migration Data to estimate these parameters, while `precalcPriors()` accomodates any additional auxiliary information if the prior means are already known.

Below, we'll walk through an example where we incorporate the auxiliary moving information for California into our estimates. First, we use `calcMoversPriors()` to estimate optimal parameter values for the priors:

``` r
priors.out <- calcMoversPriors(geo.a = "CA", geo.b = "CA", year.start = 2014, year.end = 2015, 
                               var.prior.gamma = 0.0001, var.prior.pi = 0.1, L = 3)
```

    ## Your provided variance for gamma is too large given the observed mean. The function will adaptively choose a new prior variance.
    ## Your provided variance for pi is too large given the observed mean. The function will adaptively choose a new prior variance.

``` r
names(priors.out)
```

    ## [1] "gamma_prior" "pi_prior"

where each entry in the list outputs the optimal parameter values for the prior distributions, estimated from the IRS data.

The `calcMoversPriors()` function accepts the following functions:

-   `geo.a`: The state name or county name of dataset A

-   `geo.b`: The state name or county name of dataset B

-   `year.start`: The year of dataset A

-   `year.end`: The year of dataset B

-   'L': The number of matching categories for address. For instance, if partial matches are being calculated, L = 3 (no match, partial match, full match)

-   `var.prior.gamma`: The prior variance for gamma

-   `var.prior.pi`: The prior variance for pi

-   `county`: Boolean, whether the geographies in `geo.a` or `geo.b` refer to counties or states. Default is FALSE

-   `state.a`: If `county = TRUE`, the name of the state for `geo.a`

-   `state.b`: If `county = TRUE`, the name of the state for `geo.b`

-   `denom.mu`: If known, the denominator for mu. Can be set as the size of the cross-product of dataset A and dataset B

If the prior means are already known and do not need to be estimated from the IRS data, the user can run `precalcPriors()`, which will calculate the same paramters from that data. `precalcPriors()` takes the following arguments:

-   'L': The number of matching categories for address. For instance, if partial matches are being calculated, L = 3 (no match, partial match, full match)

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

### Incorporating Auxiliary Information when Running Algorithm Step-by-Step

If we are running the algorithm step-by-step, we can incorporate the prior information into the EM algorithm as follows:

``` r
em.out.aux <- emlinkMARmov(tc, 
                           psi = priors.out$gamma_prior$psi, mu = priors.out$gamma_prior$mu,
                           alpha0 = priors.out$pi_prior$alpha_0, alpha1 = priors.out$pi_prior$alpha_1,
                           pos.ad = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`pos.ad`).
