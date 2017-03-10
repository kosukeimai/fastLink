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
    ## 27       1       0       0       0       0       2       0      9
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
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
    ## 31       1      NA       0       0       0       2       0      3
    ## 25       0      NA       0       0       2       0       0     27
    ## 53       0       0       0       0       0       2       2    150
    ## 46       0       2       0       0       0       0       2     10
    ## 37       0       0       0       2       0       2       0      4
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 8        2      NA       0       0       0       0       0    559
    ## 24       0       2       0       0       2       0       0      1
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
    ## 1  -397.55443536602769 6.327595386778849e-174 2.863757478838720e-01
    ## 2  -391.85023799245766 2.210811712463736e-173 3.333863768687974e-03
    ## 19 -387.04481848405328 1.048541270657708e-172 1.294238890798555e-04
    ## 20 -381.34062111048314 3.663520153351456e-172 1.506697469301736e-06
    ## 9  -377.93389375193283 1.369786380889868e-168 1.867486300460568e-04
    ## 6  -344.81948185296858 5.089283822814845e-151 2.883068048486992e-01
    ## 26 -340.62992146560634 4.390839817237935e-150 3.769145106752195e-02
    ## 4  -339.81352414842348 5.089283822814845e-151 1.931056964827189e-03
    ## 7  -339.11528447939855 1.778155459661744e-150 3.356344306575284e-03
    ## 43 -337.51744217156732 9.048639811012317e-150 3.455779167934082e-03
    ## 14 -336.03374283916656 5.492396557003644e-151 4.757317474627743e-05
    ## 27 -334.92572409203626 1.534124655913469e-149 4.387877256779533e-04
    ## 22 -334.30986497099411 8.433415539593834e-150 1.302966057965100e-04
    ## 23 -334.01835954424251 9.650856605833736e-150 1.114028412332929e-04
    ## 44 -331.81324479799730 3.161523083136866e-149 4.023070055930163e-05
    ## 39 -330.12030458363182 7.276029012286616e-149 1.703417352296155e-05
    ## 3  -329.52522762647658 2.516540035724593e-147 3.249315259387583e-04
    ## 10 -325.19894023887372 1.101718937898730e-145 1.880078925547961e-04
    ## 11 -323.32352580119488 1.189824888734285e-145 3.112477167434274e-05
    ## 33 -321.00937985151148 9.505210454651484e-145 2.457899072571613e-05
    ## 21 -319.01561074450211 4.170140354159204e-146 1.468486842283143e-07
    ## 17 -292.00174641850862 4.417533555392540e-128 2.883546988135652e-01
    ## 30 -287.89496795254723 3.531551669237811e-127 3.794560785152411e-02
    ## 47 -284.78248865850827 7.277819360081795e-127 3.479081792127839e-03
    ## 15 -283.29878932610751 4.417533555392540e-128 4.789396486594220e-05
    ## 29 -282.88901024800208 3.531551669237811e-127 2.541567840021710e-04
    ## 31 -282.19077057897709 1.233896182716705e-126 4.417465100722750e-04
    ## 25 -281.28340603118335 7.762182219015329e-127 1.121540404324386e-04
    ## 53 -280.59292827114598 6.279024739327227e-126 4.548336665057549e-04
    ## 46 -279.77653095396312 7.277819360081795e-127 2.330262419375648e-05
    ## 37 -279.10922893874522 3.811279328153890e-127 6.261361170859719e-06
    ## 40 -277.38535107057277 5.852108815922928e-126 1.714903645973134e-05
    ## 41 -277.09384564382106 6.696914525206818e-126 1.466232657672632e-05
    ## 8  -276.79027411341741 2.024052694652395e-124 3.271225679208135e-04
    ## 24 -276.27744832663819 7.762182219015329e-127 7.511991991456039e-07
    ## 52 -273.98136634978215 1.380099705432863e-125 1.344330380025045e-06
    ## 28 -272.60071372605518 1.746275404021774e-123 4.276598420332113e-05
    ## 5  -271.78431640887226 2.024052694652395e-124 2.191041982055012e-06
    ## 13 -270.58857228813577 9.569759423730208e-123 3.133464875913262e-05
    ## 45 -269.48823443201621 3.598723205475997e-123 3.921042918758394e-06
    ## 34 -268.27442633845232 7.645039046015379e-122 2.474472903135143e-05
    ## 35 -266.39901190077353 8.256423139682943e-122 4.096498454286010e-06
    ## 12 -265.58261458359061 9.569759423730208e-123 2.098770847899037e-07
    ## 49 -263.28653260673451 1.701483138259743e-121 3.755916426362859e-07
    ## 38 -235.07723251808724 3.065411272903296e-104 3.795191143360645e-02
    ## 51 -231.96475322404828 6.317197537524024e-104 3.479659742485983e-03
    ## 56 -227.85797475808684 5.050218459872271e-103 4.579006500964880e-04
    ## 42 -224.35889213076197 5.386327138919511e-103 1.476119594002186e-05
    ## 18 -223.97253867895748 1.756891737188281e-101 3.271769100192702e-04
    ## 50 -223.26179613164712 6.317197537524024e-104 5.779503581448734e-07
    ## 55 -222.85201705354172 5.050218459872271e-103 3.066983590733346e-06
    ## 32 -219.86576021299607 1.404528990971351e-100 4.305435901251417e-05
    ## 48 -216.75328091895710 2.894452421955722e-100 3.947482857522776e-06
    ## 16 -215.26958158655634 1.756891737188281e-101 5.434209845680966e-08
    ## 36 -213.66405838771439  6.640639634907859e-99 4.124121505225226e-06
    ## 54 -212.56372053159484  2.497223064363242e-99 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948859  5.000000000000000e-01 2.444122297210036e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  4.230898589109145e-177 6.327595386778849e-174 7.136242521161280e-01
    ## 2  1.269796304563327e-174 2.843571251141621e-173 7.102903883474400e-01
    ## 19 1.551319439193965e-172 1.332898395771870e-172 7.101609644583602e-01
    ## 20 4.655889640457550e-170 4.996418549123326e-172 7.101594577608908e-01
    ## 9  1.404512377207156e-168 1.370286022744781e-168 7.099727091308448e-01
    ## 6  3.380118530607714e-154 5.089283822814845e-151 4.216659042821456e-01
    ## 26 2.230667746365052e-152 4.899768199519420e-150 3.839744532146235e-01
    ## 4  5.046516966197360e-152 5.408696581800905e-150 3.820433962497963e-01
    ## 7  1.014456368725073e-151 7.186852041462648e-150 3.786870519432211e-01
    ## 43 5.013805359246092e-151 1.623549185247497e-149 3.752312727752870e-01
    ## 14 2.210700467505824e-150 1.678473150817533e-149 3.751836996005408e-01
    ## 27 6.694780320034842e-150 3.212597806731002e-149 3.747449118748628e-01
    ## 22 1.239368770693198e-149 4.055939360690385e-149 3.746146152690663e-01
    ## 23 1.658821848983192e-149 5.021025021273759e-149 3.745032124278330e-01
    ## 44 1.504765803973339e-148 8.182548104410625e-149 3.744629817272737e-01
    ## 39 8.179062117506646e-148 1.545857711669724e-148 3.744459475537507e-01
    ## 3  1.483003395310248e-147 2.671125806891565e-147 3.741210160278120e-01
    ## 10 1.122082747359211e-145 1.128430195967646e-145 3.739330081352572e-01
    ## 11 7.319931660515416e-145 2.318255084701931e-145 3.739018833635829e-01
    ## 33 7.405047398846286e-144 1.182346553935342e-144 3.738773043728572e-01
    ## 21 5.437643911999595e-143 1.224047957476934e-144 3.738771575241728e-01
    ## 17 2.933478947285702e-131 4.417533555392540e-128 8.552245871060771e-02
    ## 30 1.782108747424519e-129 3.973305024777065e-127 4.757685085908359e-02
    ## 47 4.005592676523212e-128 1.125112438485886e-126 4.409776906695573e-02
    ## 15 1.766156635158907e-127 1.169287774039811e-126 4.404987510208980e-02
    ## 29 2.660688359904830e-127 1.522442940963593e-126 4.379571831808760e-02
    ## 31 5.348544887449944e-127 2.756339123680297e-126 4.335397180801537e-02
    ## 25 1.325253809003720e-126 3.532557345581830e-126 4.324181776758296e-02
    ## 53 2.643441733680841e-126 9.811582084909057e-126 4.278698410107717e-02
    ## 46 5.980349866048867e-126 1.053936402091724e-125 4.276368147688336e-02
    ## 37 1.165553398616847e-125 1.092049195373263e-125 4.275742011571260e-02
    ## 40 6.534356436134044e-125 1.677260076965555e-125 4.274027107925282e-02
    ## 41 8.745849888763220e-125 2.346951529486237e-125 4.272560875267606e-02
    ## 8  1.184790216987472e-124 2.258747847601018e-124 4.239848618475528e-02
    ## 24 1.978603936842571e-124 2.266510029820034e-124 4.239773498555610e-02
    ## 52 1.965778593198960e-123 2.404520000363320e-124 4.239639065517609e-02
    ## 28 7.818877649736268e-123 1.986727404058106e-123 4.235362467097281e-02
    ## 5  1.768891793962311e-122 2.189132673523345e-123 4.235143362899074e-02
    ## 13 5.847986220274772e-122 1.175889209725355e-122 4.232009898023159e-02
    ## 45 1.757425807918569e-121 1.535761530272955e-122 4.231617793731279e-02
    ## 34 5.915986262894685e-121 9.180800576288335e-122 4.229143320828144e-02
    ## 35 3.859306744609590e-120 1.743722371597128e-121 4.228733670982721e-02
    ## 12 8.731043426870310e-120 1.839419965834430e-121 4.228712683274238e-02
    ## 49 8.674448658088734e-119 3.540903104094173e-121 4.228675124109982e-02
    ## 38 1.546625789896120e-106 3.065411272903296e-104 4.334839807493274e-03
    ## 51 3.476304656650516e-105 9.382608810427320e-104 8.551800650072883e-04
    ## 56 2.111879119862815e-103 5.988479340915003e-103 3.972794149108561e-04
    ## 42 6.987170373456219e-102 1.137480647983451e-102 3.825182189708398e-04
    ## 18 1.028235290274816e-101 1.870639801986626e-101 5.534130895157308e-05
    ## 50 2.092975148452343e-101 1.876956999524150e-101 5.476335859344594e-05
    ## 55 3.153035525955120e-101 1.927459184122873e-101 5.169637500268554e-05
    ## 32 6.246600497695601e-100 1.597274909383638e-100 8.642015990156793e-06
    ## 48  1.404029762094717e-98 4.491727331339360e-100 4.694533132676426e-06
    ## 16  6.190685575240783e-98 4.667416505058188e-100 4.640191034188668e-06
    ## 36  3.083249094254776e-97  7.107381285413678e-99 5.160695289996298e-07
    ## 54  9.265722124479378e-97  9.604604349776920e-99 0.000000000000000e+00
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

The `fastLink` algorithm also incorporates a number of functionalities to incorporate auxiliary information on migration behavior to inform the matching of data sets over time. Auxiliary information is incorporated into the algorithm as priors on two parameters of the model:

-   
    *γ*
    : The probability that a randomly selected pair of observations from dataset A and dataset B are a true match. When matching, for example, the same state to itself in subsequent years, the prior for this quantity is equal to the number of non-movers to the number of in-state movers, divided by the size of the cross-product of A and B. When matching two different states in subsequent years to find movers, the numerator is the size of the outflow from state A to state B, divided by the size of the cross-product of A and B.

-   
    *π*<sub>*k*, *l*</sub>
    : The probability that an address field does not match conditional on being in the matched set. Specified when trying to find movers within the same geography over time. For example, when trying to find movers within the same state over time, this quantity is equal to the estimated number of in-state movers divided by the number of in-state movers and non-movers.

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

    ## [1] "gamma_prior"      "pi_prior"         "parameter_values"

where each entry in the list outputs the optimal parameter values for the prior distributions, estimated from the IRS data.

If the provided variances are too large (forcing the parameter values for the
*γ*
 prior or the
*π*<sub>*k*, *l*</sub>
 prior below 1), the function will choose new parameter values by testing the sequence
1/(10<sup>*i*</sup>)
 to find new variance values that satisfy those restrictions. The means and variances used to calculate optimal paramter values can be viewed in the `parameter_values` field of the output.

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

### Incorporating Auxiliary Information when Running Algorithm Step-by-Step

If we are running the algorithm step-by-step, we can incorporate the prior information into the EM algorithm as follows:

``` r
em.out.aux <- emlinkMARmov(tc, 
                           psi = priors.out$gamma_prior$psi, mu = priors.out$gamma_prior$mu,
                           alpha0 = priors.out$pi_prior$alpha_0, alpha1 = priors.out$pi_prior$alpha_1,
                           address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`address_field`).
