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
    ## 26       0       0       0       0       0       2       0  13032
    ## 4        0       2       0       0       0       0       0    691
    ## 43       0       0       0       0       0       0       2   1203
    ## 14       0       0       0       2       0       0       0     15
    ## 7        1      NA       0       0       0       0       0     48
    ## 22       0      NA       0       0       1       0       0     17
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
    ## 53       0       0       0       0       0       2       2    150
    ## 15       0      NA       0       2       0       0       0      8
    ## 25       0      NA       0       0       2       0       0     27
    ## 46       0       2       0       0       0       0       2     10
    ## 37       0       0       0       2       0       2       0      4
    ## 31       1      NA       0       0       0       2       0      3
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 24       0       2       0       0       2       0       0      1
    ## 52       0       0       0       0       2       0       2      1
    ## 8        2      NA       0       0       0       0       0    559
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
    ## 55       0       2       0       0       0       2       2      3
    ## 50       0      NA       0       2       0       0       2      1
    ## 18       2      NA       0      NA       0       0       0      4
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 36       0      NA       2       0       0       2       0      3
    ## 54       2       0       0       0       0       2       2      3
    ## 16       2      NA       0       2       0       0       0      1
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -528.04439380578572 1.349490422242806e-230 2.863757478838720e-01
    ## 2  -519.32041656830575 9.659543309145973e-229 3.333863768687974e-03
    ## 19 -519.17085279360515 4.354897249353338e-230 1.294238890798554e-04
    ## 20 -510.44687555612529 3.117200233039942e-228 1.506697469301733e-06
    ## 9  -508.94407385620542 1.736419088817473e-225 1.867486300460568e-04
    ## 6  -455.90528724484852 2.902046534663520e-199 2.883068048486992e-01
    ## 26 -453.15173356514885 5.955874052582328e-199 3.769145106752195e-02
    ## 4  -450.89932954030343 2.902046534663520e-199 1.931056964827189e-03
    ## 43 -450.15301556194606 1.095406494928852e-198 3.455779167934082e-03
    ## 14 -447.28221041905459 2.661744075518837e-199 4.757317474627726e-05
    ## 7  -447.18131000736861 2.077261440666524e-197 3.356344306575284e-03
    ## 22 -447.03174623266807 9.365101273039586e-199 1.302966057965099e-04
    ## 23 -446.69088138812373 1.125929930041281e-198 1.114028412332929e-04
    ## 27 -444.42775632766882 4.263166481694859e-197 4.387877256779533e-04
    ## 39 -444.27819255296833 1.922001008793932e-198 1.703417352296152e-05
    ## 44 -441.42903832446621 7.840831105194775e-197 4.023070055930163e-05
    ## 3  -440.54316364386341 1.535772332519365e-195 3.249315259387583e-04
    ## 10 -436.80496729526823 3.734127279726380e-194 1.880078925547961e-04
    ## 11 -435.08116011678578 3.465446155949409e-194 3.112477167434274e-05
    ## 33 -434.05141361556855 7.663554498081406e-194 2.457899072571613e-05
    ## 21 -431.66962263168296 4.956041625998145e-195 1.468486842283143e-07
    ## 17 -383.84606095051856 5.724016297709099e-168 2.883546988135652e-01
    ## 30 -381.01262700421159 1.280796319136755e-167 3.794560785152411e-02
    ## 47 -378.01390900100893 2.355645190406576e-167 3.479081792127839e-03
    ## 29 -376.00666929966644 1.280796319136755e-167 2.541567840021710e-04
    ## 53 -375.26035532130919 4.834493830147900e-167 4.548336665057549e-04
    ## 15 -375.14310385811746 5.724016297709099e-168 4.789396486594202e-05
    ## 25 -374.55177482718653 2.421285099837598e-167 1.121540404324386e-04
    ## 46 -373.00795129646377 2.355645190406576e-167 2.330262419375648e-05
    ## 37 -372.38955017841766 1.174740643779466e-167 6.261361170859698e-06
    ## 31 -372.28864976673162 9.167836474403317e-166 4.417465100722750e-04
    ## 40 -372.13908599203120 4.133216712957398e-167 1.714903645973134e-05
    ## 41 -371.79822114748674 4.969206705605021e-167 1.466232657672632e-05
    ## 24 -369.54581712264138 2.421285099837598e-167 7.511991991456039e-07
    ## 52 -368.79950314428413 9.139382820902726e-167 1.344330380025045e-06
    ## 8  -368.40405708292616 3.302641280115756e-164 3.271225679208135e-04
    ## 28 -365.65050340322648 6.778015193856765e-164 4.276598420332113e-05
    ## 5  -363.39809937838100 3.302641280115756e-164 2.191041982055012e-06
    ## 13 -362.94205355584859 7.452358195489251e-163 3.133464875913262e-05
    ## 45 -362.65178540002375 1.246614988921324e-163 3.921042918758394e-06
    ## 34 -361.91230705463130 1.648028871327600e-162 2.474472903135143e-05
    ## 35 -360.18849987614891 1.529448486676661e-162 4.096498454286010e-06
    ## 12 -357.93609585130343 7.452358195489251e-163 2.098770847899037e-07
    ## 49 -357.18978187294618 2.812967150032701e-162 3.755916426362859e-07
    ## 38 -308.95340070988163 2.526251359933704e-136 3.795191143360645e-02
    ## 51 -305.95468270667891 4.646290574754920e-136 3.479659742485983e-03
    ## 56 -303.12124876037194 1.039646212776793e-135 4.579006500964880e-04
    ## 42 -299.65911458654961 1.068615891030925e-135 1.476119594002186e-05
    ## 55 -298.11529105582679 1.039646212776793e-135 3.066983590733346e-06
    ## 50 -297.25172561427780 4.646290574754920e-136 5.779503581448713e-07
    ## 18 -296.34483078859620 6.514152094760020e-133 3.271769100192702e-04
    ## 32 -293.51139684228929 1.457595784380340e-132 4.305435901251417e-05
    ## 48 -290.51267883908656 2.680815401895165e-132 3.947482857522776e-06
    ## 36 -288.04939331521166 3.289042002483934e-131 4.124121505225226e-06
    ## 54 -287.75912515938683 5.501841097721281e-132 5.160695289252128e-07
    ## 16 -287.64187369619503 6.514152094760020e-133 5.434209845680946e-08
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  9.023265197097129e-234 1.349490422242806e-230 7.136242521161280e-01
    ## 2  5.548031217934014e-230 9.794492351370254e-229 7.102903883474400e-01
    ## 19 6.443081400484006e-230 1.022998207630559e-228 7.101609644583602e-01
    ## 20 3.961583303688245e-226 4.140198440670501e-228 7.101594577608908e-01
    ## 9  1.780439735923215e-225 1.740559287258143e-225 7.099727091308448e-01
    ## 6  1.927434509454542e-202 2.902046534663520e-199 4.216659042821456e-01
    ## 26 3.025748308637965e-201 8.857920587245848e-199 3.839744532146235e-01
    ## 4  2.877659722615656e-200 1.175996712190937e-198 3.820433962497963e-01
    ## 43 6.069591750290718e-200 2.271403207119789e-198 3.785876170818623e-01
    ## 14 1.071357250165585e-198 2.537577614671672e-198 3.785400439071160e-01
    ## 7  1.185099472906627e-198 2.331019202133691e-197 3.751836996005408e-01
    ## 22 1.376288645767759e-198 2.424670214864087e-197 3.750534029947442e-01
    ## 23 1.935286415143294e-198 2.537263207868215e-197 3.749420001535110e-01
    ## 27 1.860407037503004e-197 6.800429689563074e-197 3.745032124278330e-01
    ## 39 2.160541912943208e-197 6.992629790442467e-197 3.744861782543101e-01
    ## 44 3.731940021175170e-196 1.483346089563724e-196 3.744459475537507e-01
    ## 3  9.050345121546918e-196 1.684106941475737e-195 3.741210160278120e-01
    ## 10 3.803147656711604e-194 3.902537973873954e-194 3.739330081352572e-01
    ## 11 2.131980031257400e-193 7.367984129823363e-194 3.739018833635829e-01
    ## 33 5.970302769484047e-193 1.503153862790477e-193 3.738773043728572e-01
    ## 21 6.462417877217701e-192 1.552714279050458e-193 3.738771575241728e-01
    ## 17 3.801053482152401e-171 5.724016297709099e-168 8.552245871060771e-02
    ## 30 6.463216562524079e-170 1.853197948907665e-167 4.757685085908359e-02
    ## 47 1.296508563393865e-168 4.208843139314241e-167 4.409776906695573e-02
    ## 29 9.649582327848533e-168 5.489639458450996e-167 4.384361228295353e-02
    ## 53 2.035300589244818e-167 1.032413328859890e-166 4.338877861644785e-02
    ## 15 2.288496337875201e-167 1.089653491836981e-166 4.334088465158192e-02
    ## 25 4.133911328933969e-167 1.331782001820740e-166 4.322873061114940e-02
    ## 46 1.935687285146947e-166 1.567346520861398e-166 4.320542798695570e-02
    ## 37 3.592554709218135e-166 1.684820585239345e-166 4.319916662578482e-02
    ## 31 3.973963579025435e-166 1.085265705964266e-165 4.275742011571260e-02
    ## 40 4.615073314557051e-166 1.126597873093840e-165 4.274027107925282e-02
    ## 41 6.489546155901544e-166 1.176289940149890e-165 4.272560875267606e-02
    ## 24 6.171929614098469e-165 1.200502791148266e-165 4.272485755347699e-02
    ## 52 1.301790228173836e-164 1.291896619357293e-165 4.272351322309687e-02
    ## 8  1.933218976580116e-164 3.431830942051485e-164 4.239639065517609e-02
    ## 28 3.034828950047945e-163 1.020984613590825e-163 4.235362467097281e-02
    ## 5  2.886295932034138e-162 1.351248741602401e-163 4.235143362899074e-02
    ## 13 4.554063075786842e-162 8.803606937091652e-163 4.232009898023159e-02
    ## 45 6.087807338821651e-162 1.005022192601298e-162 4.231617793731279e-02
    ## 34 1.275299721158324e-161 2.653051063928897e-162 4.229143320828144e-02
    ## 35 7.149113799405921e-161 4.182499550605558e-162 4.228733670982721e-02
    ## 12 6.799216172149814e-160 4.927735370154483e-162 4.228712683274238e-02
    ## 49 1.434098203571141e-159 7.740702520187184e-162 4.228675124109982e-02
    ## 38 1.274597486990083e-138 2.526251359933704e-136 4.334839807493274e-03
    ## 51 2.556817554814506e-137 7.172541934688624e-136 8.551800650073993e-04
    ## 56 4.347548816459104e-136 1.756900406245655e-135 3.972794149108561e-04
    ## 42 1.386213852564811e-134 2.825516297276580e-135 3.825182189708398e-04
    ## 55 6.490890382973499e-134 3.865162510053373e-135 3.794512353800794e-04
    ## 50 1.539380500243490e-133 4.329791567528865e-135 3.788732850219523e-04
    ## 18 3.812460909383887e-133 6.557450010435309e-133 5.169637500268554e-05
    ## 32 6.482613467346154e-132 2.113340785423871e-132 8.642015990156793e-06
    ## 48 1.300399544449796e-130 4.794156187319036e-132 4.694533132676426e-06
    ## 36 1.527102257110389e-129 3.768457621215837e-131 5.704116273763660e-07
    ## 54 2.041408775692345e-129 4.318641730987965e-131 5.434209848775851e-08
    ## 16 2.295364395787676e-129 4.383783251935566e-131 0.000000000000000e+00
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

-   `L`: The number of matching categories for address. For instance, if partial matches are being calculated, L = 3 (no match, partial match, full match)

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
