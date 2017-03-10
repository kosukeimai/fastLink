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
    ## 19       0       0       0       0       1       0       0     40
    ## 2        1       0       0       0       0       0       0    133
    ## 9        0       0       1       0       0       0       0     12
    ## 20       1       0       0       0       1       0       0      1
    ## 6        0      NA       0       0       0       0       0  48474
    ## 4        0       2       0       0       0       0       0    691
    ## 43       0       0       0       0       0       0       2   1203
    ## 26       0       0       0       0       0       2       0  13032
    ## 14       0       0       0       2       0       0       0     15
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 7        1      NA       0       0       0       0       0     48
    ## 10       0      NA       1       0       0       0       0      3
    ## 39       0       0       0       0       1       2       0      4
    ## 11       0       0       2       0       0       0       0     65
    ## 3        2       0       0       0       0       0       0   1181
    ## 44       1       0       0       0       0       0       2      2
    ## 27       1       0       0       0       0       2       0      9
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 47       0      NA       0       0       0       0       2    593
    ## 30       0      NA       0       0       0       2       0   6701
    ## 15       0      NA       0       2       0       0       0      8
    ## 46       0       2       0       0       0       0       2     10
    ## 29       0       2       0       0       0       2       0     75
    ## 25       0      NA       0       0       2       0       0     27
    ## 53       0       0       0       0       0       2       2    150
    ## 37       0       0       0       2       0       2       0      4
    ## 24       0       2       0       0       2       0       0      1
    ## 52       0       0       0       0       2       0       2      1
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 13       0      NA       2       0       0       0       0     36
    ## 8        2      NA       0       0       0       0       0    559
    ## 31       1      NA       0       0       0       2       0      3
    ## 12       0       2       2       0       0       0       0      1
    ## 34       0      NA       1       0       0       2       0      1
    ## 49       0       0       2       0       0       0       2      1
    ## 5        2       2       0       0       0       0       0      9
    ## 35       0       0       2       0       0       2       0      8
    ## 45       2       0       0       0       0       0       2     19
    ## 28       2       0       0       0       0       2       0    153
    ## 51       0      NA       0      NA       0       0       2      3
    ## 38       0      NA       0      NA       0       2       0     20
    ## 56       0      NA       0       0       0       2       2     92
    ## 50       0      NA       0       2       0       0       2      1
    ## 55       0       2       0       0       0       2       2      3
    ## 42       0      NA       0       0       2       2       0      4
    ## 18       2      NA       0      NA       0       0       0      4
    ## 36       0      NA       2       0       0       2       0      3
    ## 48       2      NA       0       0       0       0       2      5
    ## 32       2      NA       0       0       0       2       0     74
    ## 16       2      NA       0       2       0       0       0      1
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -535.30096372891501 9.520977337481058e-234 2.863757478838720e-01
    ## 19 -522.41421195511452 1.699827793162914e-231 1.294238890798554e-04
    ## 2  -518.08514997340296 3.322202187519361e-228 3.333863768687974e-03
    ## 9  -517.21186896038898 4.456529238820261e-229 1.867486300460566e-04
    ## 20 -505.19839819960237 5.931294039133533e-226 1.506697469301733e-06
    ## 6  -464.11477931469000 7.895275099257151e-203 2.883068048486992e-01
    ## 4  -459.10882161014490 7.895275099257151e-203 1.931056964827189e-03
    ## 43 -457.83425606350187 5.054229376346352e-202 3.455779167934082e-03
    ## 26 -457.15331044769908 1.089137587268385e-200 3.769145106752195e-02
    ## 14 -455.41730740476339 7.800789618347231e-203 4.757317474627726e-05
    ## 22 -451.22802754088946 1.409583026266984e-200 1.302966057965099e-04
    ## 23 -451.06446283520262 1.419348605150076e-200 1.114028412332929e-04
    ## 7  -446.89896555917790 2.754937783809521e-197 3.356344306575284e-03
    ## 10 -446.02568454616392 3.695579044165436e-198 1.880078925547960e-04
    ## 39 -444.26655867389849 1.944491910645822e-198 1.703417352296152e-05
    ## 11 -444.09399574384867 4.222156979309487e-198 3.112477167434274e-05
    ## 3  -442.66875966884169 1.833125568250158e-196 3.249315259387583e-04
    ## 44 -440.61844230798977 1.763597506342329e-196 4.023070055930163e-05
    ## 27 -439.93749669218693 3.800382194681381e-195 4.387877256779533e-04
    ## 33 -439.06421567917300 5.097978212438288e-196 2.457899072571609e-05
    ## 21 -429.78200789504115 3.272770933928015e-194 1.468486842283143e-07
    ## 17 -392.93408008293943 6.468808594452409e-172 2.883546988135652e-01
    ## 47 -386.64807164927680 4.191222174630348e-171 3.479081792127839e-03
    ## 30 -385.96712603347402 9.031678752740445e-170 3.794560785152411e-02
    ## 15 -384.23112299053832 6.468808594452409e-172 4.789396486594202e-05
    ## 46 -381.64211394473165 4.191222174630348e-171 2.330262419375648e-05
    ## 29 -380.96116832892886 9.031678752740445e-170 2.541567840021710e-04
    ## 25 -379.87827842097755 1.176995522853702e-169 1.121540404324386e-04
    ## 53 -379.68660278228583 5.781708109717603e-169 4.548336665057549e-04
    ## 37 -377.26965412354735 8.923593537261016e-170 6.261361170859698e-06
    ## 24 -374.87232071643240 1.176995522853702e-169 7.511991991456039e-07
    ## 52 -373.59775516978937 7.534639734080151e-169 1.344330380025045e-06
    ## 40 -373.08037425967348 1.612470864980616e-167 1.714903645973134e-05
    ## 41 -372.91680955398658 1.623642049036626e-167 1.466232657672632e-05
    ## 13 -372.90781132962354 3.501225733693246e-167 3.133464875913262e-05
    ## 8  -371.48257525461656 1.520120271250116e-165 3.271225679208135e-04
    ## 31 -368.75131227796180 3.151468787895279e-164 4.417465100722750e-04
    ## 12 -367.90185362507839 3.501225733693246e-167 2.098770847899037e-07
    ## 34 -367.87803126494788 4.227500918290245e-165 2.474472903135138e-05
    ## 49 -366.62728807843536 2.241340261610161e-166 3.755916426362859e-07
    ## 5  -366.47661755007141 1.520120271250116e-165 2.191041982055012e-06
    ## 35 -365.94634246263263 4.829871663921413e-165 4.096498454286010e-06
    ## 45 -365.20205200342843 9.731182807366397e-165 3.921042918758394e-06
    ## 28 -364.52110638762565 2.096975854258566e-163 4.276598420332113e-05
    ## 51 -315.46737241752618 3.433979650317598e-140 3.479659742485983e-03
    ## 38 -314.78642680172339 7.399894291658175e-139 3.795191143360645e-02
    ## 56 -308.50041836806071 4.794484268975915e-138 4.579006500964880e-04
    ## 50 -306.76441532512507 3.433979650317598e-140 5.779503581448713e-07
    ## 55 -303.49446066351555 4.794484268975915e-138 3.066983590733346e-06
    ## 42 -301.73062513976151 1.346405960804228e-136 1.476119594002186e-05
    ## 18 -300.30187602286600 1.245474914001322e-134 3.271769100192702e-04
    ## 36 -294.76015804840750 4.005173432211678e-134 4.124121505225226e-06
    ## 48 -294.01586758920331 8.069588087650085e-134 3.947482857522776e-06
    ## 32 -293.33492197340053 1.738918249568308e-132 4.305435901251417e-05
    ## 16 -291.59891893046483 1.245474914001322e-134 5.434209845680946e-08
    ## 54 -287.05439872221240 1.113183719318387e-131 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  6.366129172585262e-237 9.520977337481058e-234 7.136242521161280e-01
    ## 19 2.514899482365522e-231 1.709348770500395e-231 7.134948282270481e-01
    ## 2  1.908131767595510e-229 3.323911536289862e-228 7.101609644583602e-01
    ## 9  4.569508474191447e-229 3.769564460171888e-228 7.099742158283140e-01
    ## 20 7.537955112938660e-224 5.968989683735252e-226 7.099727091308448e-01
    ## 6  5.243756606304656e-206 7.895275099257151e-203 4.216659042821456e-01
    ## 4  7.828928613212918e-204 1.579055019851430e-202 4.197348473173184e-01
    ## 43 2.800522825888607e-203 6.633284396197782e-202 4.162790681493842e-01
    ## 26 5.533119376697562e-203 1.155470431230363e-200 3.785876170818623e-01
    ## 14 3.139833236222634e-202 1.163271220848710e-200 3.785400439071160e-01
    ## 22 2.071513225279360e-200 2.572854247115694e-200 3.784097473013195e-01
    ## 23 2.439624350157221e-200 3.992202852265770e-200 3.782983444600863e-01
    ## 7  1.571720945455776e-198 2.758929986661787e-197 3.749420001535110e-01
    ## 10 3.763886908279186e-198 3.128487891078331e-197 3.747539922609562e-01
    ## 39 2.185824176526094e-197 3.322937082142913e-197 3.747369580874331e-01
    ## 11 2.597516730498958e-197 3.745152780073861e-197 3.747058333157588e-01
    ## 3  1.080265524550759e-196 2.207640846257544e-196 3.743809017898201e-01
    ## 44 8.394059286397767e-196 3.971238352599873e-196 3.743406710892607e-01
    ## 27 1.658452188190293e-195 4.197506029941368e-195 3.739018833635829e-01
    ## 33 3.971587002886128e-195 4.707303851185197e-195 3.738773043728572e-01
    ## 21 4.267521338099187e-191 3.743501319046535e-194 3.738771575241728e-01
    ## 17 4.295635468955878e-175 6.468808594452409e-172 8.552245871060771e-02
    ## 47 2.306780096860267e-172 4.838103034075589e-171 8.204337691847985e-02
    ## 30 4.557609576942895e-172 9.515489056148003e-170 4.409776906695573e-02
    ## 15 2.586268803033432e-171 9.580177142092528e-170 4.404987510208980e-02
    ## 46 3.444022684612213e-170 9.999299359555562e-170 4.402657247789610e-02
    ## 29 6.804511098375801e-170 1.903097811229601e-169 4.377241569389390e-02
    ## 25 2.009509382581931e-169 3.080093334083303e-169 4.366026165346149e-02
    ## 53 2.434073625074784e-169 8.861801443800906e-169 4.320542798695570e-02
    ## 37 2.728985172616018e-168 9.754160797527008e-169 4.319916662578482e-02
    ## 24 3.000197508194849e-167 1.093115632038071e-168 4.319841542658565e-02
    ## 52 1.073214742269329e-166 1.846579605446086e-168 4.319707109620563e-02
    ## 40 1.800455136103450e-166 1.797128825525224e-167 4.317992205974597e-02
    ## 41 2.120398816575866e-166 3.420770874561850e-167 4.316525973316920e-02
    ## 13 2.139564741192680e-166 6.921996608255096e-167 4.313392508441005e-02
    ## 8  8.898106411852990e-166 1.589340237332667e-165 4.280680251648927e-02
    ## 31 1.366060816911154e-164 3.310402811628546e-164 4.236505600641693e-02
    ## 12 3.194370158600698e-164 3.313904037362239e-164 4.236484612933222e-02
    ## 34 3.271381245857072e-164 3.736654129191264e-164 4.234010140030087e-02
    ## 49 1.142673153054574e-163 3.759067531807365e-164 4.233972580865819e-02
    ## 5  1.328487287289663e-163 3.911079558932377e-164 4.233753476667612e-02
    ## 35 2.257630934463765e-163 4.394066725324518e-164 4.233343826822189e-02
    ## 45 4.752194273017768e-163 5.367185006061158e-164 4.232951722530309e-02
    ## 28 9.389124762988694e-163 2.633694354864682e-163 4.228675124109982e-02
    ## 51 1.889692284962384e-141 3.433979650317598e-140 3.880709149861383e-02
    ## 38 3.733550357549253e-141 7.743292256689935e-139 8.551800650073993e-04
    ## 56 2.004937271251639e-138 5.568813494644908e-138 3.972794149108561e-04
    ## 50 1.137725079153149e-137 5.603153291148084e-138 3.967014645527289e-04
    ## 55 2.993371345978723e-136 1.039763756012400e-137 3.936344809619685e-04
    ## 42 1.746564513692639e-135 1.450382336405468e-136 3.788732850219523e-04
    ## 18 7.289244024664159e-135 1.259978737365377e-134 5.169637500268554e-05
    ## 36 1.859602091986022e-132 5.265152169577054e-134 4.757225349749650e-05
    ## 48 3.914364512252244e-132 1.333474025722714e-133 4.362477063990511e-05
    ## 32 7.733786680823747e-132 1.872265652140580e-132 5.704116273763660e-07
    ## 16 4.388627609332279e-131 1.884720401280593e-132 5.160695289996298e-07
    ## 54 4.130368313464367e-129 1.301655759446446e-131 0.000000000000000e+00
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
                           address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`address_fieldd`).
