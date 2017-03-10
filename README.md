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
    ## 43       0       0       0       0       0       0       2   1203
    ## 7        1      NA       0       0       0       0       0     48
    ## 22       0      NA       0       0       1       0       0     17
    ## 14       0       0       0       2       0       0       0     15
    ## 23       0       0       0       0       2       0       0     43
    ## 27       1       0       0       0       0       2       0      9
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
    ## 15       0      NA       0       2       0       0       0      8
    ## 53       0       0       0       0       0       2       2    150
    ## 25       0      NA       0       0       2       0       0     27
    ## 46       0       2       0       0       0       0       2     10
    ## 31       1      NA       0       0       0       2       0      3
    ## 40       0      NA       0       0       1       2       0      3
    ## 37       0       0       0       2       0       2       0      4
    ## 41       0       0       0       0       2       2       0      3
    ## 24       0       2       0       0       2       0       0      1
    ## 8        2      NA       0       0       0       0       0    559
    ## 52       0       0       0       0       2       0       2      1
    ## 28       2       0       0       0       0       2       0    153
    ## 13       0      NA       2       0       0       0       0     36
    ## 5        2       2       0       0       0       0       0      9
    ## 45       2       0       0       0       0       0       2     19
    ## 34       0      NA       1       0       0       2       0      1
    ## 35       0       0       2       0       0       2       0      8
    ## 12       0       2       2       0       0       0       0      1
    ## 49       0       0       2       0       0       0       2      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 42       0      NA       0       0       2       2       0      4
    ## 55       0       2       0       0       0       2       2      3
    ## 50       0      NA       0       2       0       0       2      1
    ## 18       2      NA       0      NA       0       0       0      4
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 36       0      NA       2       0       0       2       0      3
    ## 16       2      NA       0       2       0       0       0      1
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -437.59718618621559 2.575686367259669e-191 2.863757478838720e-01
    ## 2  -429.44902653471928 1.036586065776615e-189 3.333863768687974e-03
    ## 19 -429.04482354371953 6.028580877992780e-191 1.294238890798554e-04
    ## 20 -420.89666389222316 2.426204919189472e-189 1.506697469301733e-06
    ## 9  -420.04535269944733 7.044961078921580e-187 1.867486300460568e-04
    ## 6  -378.18000724586852 1.653349163784745e-165 2.883068048486992e-01
    ## 26 -374.85598411654075 6.002849391600592e-165 3.769145106752195e-02
    ## 4  -373.17404954132343 1.653349163784745e-165 1.931056964827189e-03
    ## 43 -372.49234132563549 5.850292676322489e-165 3.455779167934082e-03
    ## 7  -370.03184759437221 6.653910688924747e-164 3.356344306575284e-03
    ## 22 -369.62764460337246 3.869783712852648e-165 1.302966057965099e-04
    ## 14 -369.35196958845893 1.861400654197547e-165 4.757317474627726e-05
    ## 23 -368.99314090317949 6.240383974286203e-165 1.114028412332929e-04
    ## 27 -366.70782446504438 2.415849271628919e-163 4.387877256779533e-04
    ## 39 -366.30362147404463 1.405010466945006e-164 1.703417352296152e-05
    ## 44 -364.34418167413912 2.354452757166704e-163 4.023070055930163e-05
    ## 3  -363.55388444555547 4.191273108226156e-162 3.249315259387583e-04
    ## 10 -360.62817375910032 4.522204510917511e-161 1.880078925547961e-04
    ## 11 -358.69687859711149 5.164533793990003e-161 3.112477167434274e-05
    ## 33 -357.30415062977249 1.641886250749053e-160 2.457899072571613e-05
    ## 21 -355.00152180305940 9.809978899558396e-162 1.468486842283143e-07
    ## 17 -318.63774774051302 1.194844704000263e-139 2.883546988135652e-01
    ## 30 -315.43880517619368 3.853266511049571e-139 3.794560785152411e-02
    ## 47 -313.07516238528848 3.755339402826705e-139 3.479081792127839e-03
    ## 29 -310.43284747164853 3.853266511049571e-139 2.541567840021710e-04
    ## 15 -309.93479064811186 1.194844704000263e-139 4.789396486594202e-05
    ## 53 -309.75113925596065 1.363458931923887e-138 4.548336665057549e-04
    ## 25 -309.57596196283242 4.005741443030923e-139 1.121540404324386e-04
    ## 46 -308.06920468074333 3.755339402826705e-139 2.330262419375648e-05
    ## 31 -307.29064552469731 1.550748733949011e-137 4.417465100722750e-04
    ## 40 -306.88644253369762 9.018849927383837e-139 1.714903645973134e-05
    ## 37 -306.61076751878409 4.338147659050062e-139 6.261361170859698e-06
    ## 41 -306.25193883350454 1.454372924419940e-138 1.466232657672632e-05
    ## 24 -304.57000425828727 4.005741443030923e-139 7.511991991456039e-07
    ## 8  -304.13670550520840 2.690404381823788e-136 3.271225679208135e-04
    ## 52 -303.88829604259934 1.417411418031095e-138 1.344330380025045e-06
    ## 28 -300.81268237588063 9.768107463532199e-136 4.276598420332113e-05
    ## 13 -299.27969965676448 3.315146493831679e-135 3.133464875913262e-05
    ## 5  -299.13074780066324 2.690404381823788e-136 2.191041982055012e-06
    ## 45 -298.44903958497537 9.519860290913621e-136 3.921042918758394e-06
    ## 34 -297.88697168942542 1.053937037603594e-134 2.474472903135143e-05
    ## 35 -295.95567652743665 1.203637171715795e-134 4.096498454286010e-06
    ## 12 -294.27374195221932 3.315146493831679e-135 2.098770847899037e-07
    ## 49 -293.59203373653139 1.173047876312096e-134 3.755916426362859e-07
    ## 38 -255.89654567083818 2.784684073199537e-113 3.795191143360645e-02
    ## 51 -253.53290287993295 2.713913972605476e-113 3.479659742485983e-03
    ## 56 -250.33396031561358 8.752128029273900e-113 4.579006500964880e-04
    ## 42 -246.83475989315755 9.335710624500604e-113 1.476119594002186e-05
    ## 55 -245.32800261106846 8.752128029273900e-113 3.066983590733346e-06
    ## 50 -244.82994578753178 2.713913972605476e-113 5.779503581448713e-07
    ## 18 -244.59444599985289 1.944305230652281e-110 3.271769100192702e-04
    ## 32 -241.39550343553356 6.270209180698092e-110 4.305435901251417e-05
    ## 48 -239.03186064462832 6.110857770340810e-110 3.947482857522776e-06
    ## 36 -236.53849758708961 7.726222169952046e-109 4.124121505225226e-06
    ## 16 -235.89148890745173 1.944305230652281e-110 5.434209845680946e-08
    ## 54 -235.70783751530053 2.218681912589874e-109 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  1.722213123803116e-194 2.575686367259669e-191 7.136242521161280e-01
    ## 2  5.953709889740662e-191 1.062342929449212e-189 7.102903883474400e-01
    ## 19 8.919300525879085e-191 1.122628738229140e-189 7.101609644583602e-01
    ## 20 3.083412094388914e-187 3.548833657418612e-189 7.101594577608908e-01
    ## 9  7.223560673643158e-187 7.080449415495766e-187 7.099727091308448e-01
    ## 6  1.098094808747102e-168 1.653349163784745e-165 4.216659042821456e-01
    ## 26 3.049613076651416e-167 7.656198555385337e-165 3.839744532146235e-01
    ## 4  1.639455549459437e-166 9.309547719170084e-165 3.820433962497963e-01
    ## 43 3.241617457024440e-166 1.515984039549257e-164 3.785876170818623e-01
    ## 7  3.796125945361159e-165 8.169894728474004e-164 3.752312727752870e-01
    ## 22 5.687006718131825e-165 8.556873099759269e-164 3.751009761694905e-01
    ## 14 7.492174415561658e-165 8.743013165179023e-164 3.750534029947442e-01
    ## 23 1.072618287202936e-164 9.367051562607643e-164 3.749420001535110e-01
    ## 27 1.054254626410492e-163 3.352554427889684e-163 3.745032124278330e-01
    ## 39 1.579387309408043e-163 3.493055474584184e-163 3.744861782543101e-01
    ## 44 1.120630753876999e-162 5.847508231750888e-163 3.744459475537507e-01
    ## 3  2.469927822301557e-162 4.776023931401245e-162 3.741210160278120e-01
    ## 10 4.605791447507064e-161 4.999806904057635e-161 3.739330081352572e-01
    ## 11 3.177277159720916e-160 1.016434069804764e-160 3.739018833635829e-01
    ## 33 1.279113762742726e-159 2.658320320553817e-160 3.738773043728572e-01
    ## 21 1.279169704367982e-158 2.756420109549401e-160 3.738771575241728e-01
    ## 17 7.934408964889305e-143 1.194844704000263e-139 8.552245871060771e-02
    ## 30 1.944454052680316e-141 5.048111215049834e-139 4.757685085908359e-02
    ## 47 2.066877352346464e-140 8.803450617876539e-139 4.409776906695573e-02
    ## 29 2.903069900651737e-139 1.265671712892611e-138 4.384361228295353e-02
    ## 15 4.777061397481625e-139 1.385156183292637e-138 4.379571831808760e-02
    ## 53 5.740101994236906e-139 2.748615115216525e-138 4.334088465158192e-02
    ## 25 6.839087199287898e-139 3.149189259519617e-138 4.322873061114940e-02
    ## 46 3.085847887053123e-138 3.524723199802287e-138 4.320542798695570e-02
    ## 31 6.721999248284220e-138 1.903221053929240e-137 4.276368147688336e-02
    ## 40 1.007028097447185e-137 1.993409553203078e-137 4.274653244042370e-02
    ## 37 1.326678606408182e-137 2.036791029793579e-137 4.274027107925282e-02
    ## 41 1.899341440208325e-137 2.182228322235573e-137 4.272560875267606e-02
    ## 24 1.021075718853692e-136 2.222285736665882e-137 4.272485755347699e-02
    ## 8  1.574842789294314e-136 2.912632955490376e-136 4.239773498555610e-02
    ## 52 2.018924438830593e-136 2.926807069670687e-136 4.239639065517609e-02
    ## 28 4.373630697136111e-135 1.269491453320289e-135 4.235362467097281e-02
    ## 13 2.025853540899467e-134 4.584637947151968e-135 4.232229002221366e-02
    ## 5  2.351240284416431e-134 4.853678385334347e-135 4.232009898023159e-02
    ## 45 4.648995548635941e-134 5.805664414425708e-135 4.231617793731279e-02
    ## 34 8.155716404965289e-134 1.634503479046165e-134 4.229143320828144e-02
    ## 35 5.626171256338931e-133 2.838140650761960e-134 4.228733670982721e-02
    ## 12 3.024599336562930e-132 3.169655300145128e-134 4.228712683274238e-02
    ## 49 5.980396365818074e-132 4.342703176457224e-134 4.228675124109982e-02
    ## 38 1.404987396762681e-115 2.784684073199537e-113 4.334839807493274e-03
    ## 51 1.493445744679898e-114 5.498598045805013e-113 8.551800650073993e-04
    ## 56 3.659928097418803e-113 1.425072607507891e-112 3.972794149108561e-04
    ## 42 1.211033028783992e-111 2.358643669957952e-112 3.825182189708398e-04
    ## 55 5.464272649446320e-111 3.233856472885342e-112 3.794512353800794e-04
    ## 50 8.991573345555259e-111 3.505247870145889e-112 3.788732850219523e-04
    ## 18 1.137920573536366e-110 1.979357709353740e-110 5.169637500268554e-05
    ## 32 2.788656698479153e-109 8.249566890051832e-110 8.642015990156793e-06
    ## 48 2.964231201869020e-108 1.436042466039264e-109 4.694533132676426e-06
    ## 36 3.587285083546875e-107 9.162264635991310e-109 5.704116273763660e-07
    ## 16 6.851066625498253e-107 9.356695159056538e-109 5.160695289996298e-07
    ## 54 8.232220172092696e-107 1.157537707164641e-108 0.000000000000000e+00
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
                           address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`address_field`).
