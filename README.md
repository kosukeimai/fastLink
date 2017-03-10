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
    ## 20       1       0       0       0       1       0       0      1
    ## 9        0       0       1       0       0       0       0     12
    ## 6        0      NA       0       0       0       0       0  48474
    ## 4        0       2       0       0       0       0       0    691
    ## 7        1      NA       0       0       0       0       0     48
    ## 26       0       0       0       0       0       2       0  13032
    ## 14       0       0       0       2       0       0       0     15
    ## 43       0       0       0       0       0       0       2   1203
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
    ## 15       0      NA       0       2       0       0       0      8
    ## 47       0      NA       0       0       0       0       2    593
    ## 29       0       2       0       0       0       2       0     75
    ## 25       0      NA       0       0       2       0       0     27
    ## 31       1      NA       0       0       0       2       0      3
    ## 46       0       2       0       0       0       0       2     10
    ## 37       0       0       0       2       0       2       0      4
    ## 53       0       0       0       0       0       2       2    150
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
    ## 16       2      NA       0       2       0       0       0      1
    ## 48       2      NA       0       0       0       0       2      5
    ## 36       0      NA       2       0       0       2       0      3
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -408.41960695834950 1.209357307816153e-178 2.863757478838720e-01
    ## 2  -402.30274933732636 6.383865929469568e-178 3.333863768687974e-03
    ## 19 -396.26407437621810 1.039234528660234e-176 1.294238890798554e-04
    ## 20 -390.14721675519490 5.485834382745542e-176 1.506697469301733e-06
    ## 9  -385.81507365307397 5.174875454815672e-172 1.867486300460568e-04
    ## 6  -355.70437027915602 9.536954089583864e-156 2.883068048486992e-01
    ## 4  -350.69841257461093 9.536954089583864e-156 1.931056964827189e-03
    ## 7  -349.58751265813288 5.034296802931736e-155 3.356344306575284e-03
    ## 26 -349.34272020901790 7.221496043548998e-154 3.769145106752195e-02
    ## 14 -346.84853831474140 1.103966483230135e-155 4.757317474627726e-05
    ## 43 -346.72927373175241 9.035156641489676e-154 3.455779167934082e-03
    ## 22 -343.54883769702457 8.195371148036459e-154 1.302966057965099e-04
    ## 23 -343.23424584986452 9.597481739013139e-154 1.114028412332929e-04
    ## 27 -343.22586258799470 3.812029931456788e-153 4.387877256779533e-04
    ## 44 -340.61241611072927 4.769411676618823e-153 4.023070055930163e-05
    ## 3  -338.04461757114251 5.022035771688349e-151 3.249315259387583e-04
    ## 39 -337.18718762688638 6.205633346353174e-152 1.703417352296152e-05
    ## 10 -333.09983697388049 4.080890677463380e-149 1.880078925547961e-04
    ## 11 -331.15496489947890 4.724243383576723e-149 3.112477167434274e-05
    ## 33 -326.73818690374236 3.090099376030832e-147 2.457899072571613e-05
    ## 21 -325.88908498901111 4.315575673437602e-149 1.468486842283143e-07
    ## 17 -302.83625872794909 8.705845327066646e-133 2.883546988135652e-01
    ## 30 -296.62748352982436 5.694849303867775e-131 3.794560785152411e-02
    ## 15 -294.13330163554792 8.705845327066646e-133 4.789396486594202e-05
    ## 47 -294.01403705255893 7.125096406594003e-131 3.479081792127839e-03
    ## 29 -291.62152582527921 5.694849303867775e-131 2.541567840021710e-04
    ## 25 -290.51900917067104 7.568544228328455e-131 1.121540404324386e-04
    ## 31 -290.51062590880122 3.006154939442400e-130 4.417465100722750e-04
    ## 46 -289.00807934801378 7.125096406594003e-131 2.330262419375648e-05
    ## 37 -287.77165156540980 6.592170518449519e-131 6.261361170859698e-06
    ## 53 -287.65238698242081 5.395208472935618e-129 4.548336665057549e-04
    ## 24 -285.51305146612589 7.568544228328455e-131 7.511991991456039e-07
    ## 8  -285.32938089194903 3.960361779045096e-128 3.271225679208135e-04
    ## 40 -284.47195094769296 4.893743142614550e-129 1.714903645973134e-05
    ## 41 -284.15735910053286 5.730992483228408e-129 1.466232657672632e-05
    ## 52 -281.54391262326743 7.170316854694434e-129 1.344330380025045e-06
    ## 5  -280.32342318740388 3.960361779045096e-128 2.191041982055012e-06
    ## 28 -278.96773082181090 2.998833448263434e-126 4.276598420332113e-05
    ## 13 -278.43972822028542 3.725523628624802e-126 3.133464875913262e-05
    ## 45 -276.35428434454542 3.751982938632611e-126 3.921042918758394e-06
    ## 34 -274.02295022454888 2.436842750359256e-124 2.474472903135143e-05
    ## 12 -273.43377051574026 3.725523628624802e-126 2.098770847899037e-07
    ## 35 -272.07807815014729 2.821011183606971e-124 4.096498454286010e-06
    ## 49 -269.46463167288181 3.529501058724804e-124 3.755916426362859e-07
    ## 38 -243.75937197861742 5.198565153477563e-108 3.795191143360645e-02
    ## 51 -241.14592550135197 6.504171738017917e-108 3.479659742485983e-03
    ## 56 -234.93715030322727 4.254644609791851e-106 4.579006500964880e-04
    ## 18 -232.46126934074206 3.615231526096034e-105 3.271769100192702e-04
    ## 50 -232.44296840895080 6.504171738017917e-108 5.779503581448713e-07
    ## 42 -231.44212242133935 4.519442835219675e-106 1.476119594002186e-05
    ## 55 -229.93119259868214 4.254644609791851e-106 3.066983590733346e-06
    ## 32 -226.25249414261739 2.364870723776649e-103 4.305435901251417e-05
    ## 16 -223.75831224834093 3.615231526096034e-105 5.434209845680946e-08
    ## 48 -223.63904766535194 2.958802067790693e-103 3.947482857522776e-06
    ## 36 -219.36284147095378 2.224640639319891e-101 4.124121505225226e-06
    ## 54 -217.27739759521378 2.240440420021715e-101 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  8.086275772403496e-182 1.209357307816153e-178 7.136242521161280e-01
    ## 2  3.666621323004751e-179 7.593223237285721e-178 7.102903883474400e-01
    ## 19 1.537550091071704e-176 1.115166761033091e-176 7.101609644583602e-01
    ## 20 6.971829934803287e-174 6.601001143778634e-176 7.101594577608908e-01
    ## 9  5.306065769227771e-172 5.175535554930050e-172 7.099727091308448e-01
    ## 6  6.334100507274898e-159 9.536954089583864e-156 4.216659042821456e-01
    ## 4  9.456812057361503e-157 1.907390817916773e-155 4.197348473173184e-01
    ## 7  2.872119209845625e-156 6.941687620848509e-155 4.163785030107431e-01
    ## 26 3.668719191623990e-156 7.915664805633849e-154 3.786870519432211e-01
    ## 14 4.443486910054883e-155 8.026061453956862e-154 3.786394787684748e-01
    ## 43 5.006334403497586e-155 1.706121809544654e-153 3.751836996005408e-01
    ## 22 1.204385935618871e-153 2.525658924348300e-153 3.750534029947442e-01
    ## 23 1.649647596490926e-153 3.485407098249614e-153 3.749420001535110e-01
    ## 27 1.663535154469230e-153 7.297437029706401e-153 3.745032124278330e-01
    ## 44 2.270060160030931e-152 1.206684870632522e-152 3.744629817272737e-01
    ## 3  2.959498356893382e-151 5.142704258751601e-151 3.741380502013349e-01
    ## 39 6.975818888652594e-151 5.763267593386919e-151 3.741210160278120e-01
    ## 10 4.156320514716986e-149 4.138523353397249e-149 3.739330081352572e-01
    ## 11 2.906405727670612e-148 8.862766736973972e-149 3.739018833635829e-01
    ## 33 2.407346208253170e-146 3.178727043400572e-147 3.738773043728572e-01
    ## 21 5.627283926795536e-146 3.221882800134948e-147 3.738771575241728e-01
    ## 17 5.781147707208822e-136 8.705845327066679e-133 8.552245871060771e-02
    ## 30 2.873762501647766e-133 5.781907757138442e-131 4.757685085908359e-02
    ## 15 3.480649619581583e-132 5.868966210409109e-131 4.752895689421766e-02
    ## 47 3.921536462187491e-132 1.299406261700311e-130 4.404987510208980e-02
    ## 29 4.290527414960151e-131 1.868891192087089e-130 4.379571831808760e-02
    ## 25 1.292193584767170e-130 2.625745614919934e-130 4.368356427765518e-02
    ## 31 1.303071916215547e-130 5.631900554362334e-130 4.324181776758296e-02
    ## 46 5.854853938045642e-130 6.344410195021735e-130 4.321851514338915e-02
    ## 37 2.015996753447711e-129 7.003627246866687e-130 4.321225378221827e-02
    ## 53 2.271358981903709e-129 6.095571197622287e-129 4.275742011571260e-02
    ## 24 1.929245022057402e-128 6.171256639905572e-129 4.275666891651342e-02
    ## 8  2.318219236060726e-128 4.577487443035653e-128 4.242954634859264e-02
    ## 40 5.464263055690824e-128 5.066861757297108e-128 4.241239731213287e-02
    ## 41 7.484401926183777e-128 5.639961005619950e-128 4.239773498555610e-02
    ## 52 1.021321526548047e-126 6.356992691089393e-128 4.239639065517609e-02
    ## 5  3.461101319438694e-126 1.031735447013449e-127 4.239419961319402e-02
    ## 28 1.342715574525503e-125 3.102006992964778e-126 4.235143362899074e-02
    ## 13 2.276630987136519e-125 6.827530621589580e-126 4.232009898023159e-02
    ## 45 1.832269744221951e-124 1.057951356022219e-125 4.231617793731279e-02
    ## 34 1.885710216676225e-123 2.542637885961478e-124 4.229143320828144e-02
    ## 12 3.399010063794853e-123 2.579893122247726e-124 4.229122333119673e-02
    ## 35 1.318627607054978e-122 5.400904305854697e-124 4.228712683274238e-02
    ## 49 1.799399302533924e-121 8.930405364579501e-124 4.228675124109982e-02
    ## 38 2.622889466054796e-110 5.198565153477564e-108 4.334839807493274e-03
    ## 51 3.579195104509644e-109 1.170273689149548e-107 8.551800650073993e-04
    ## 56 1.779189392548286e-106 4.371671978706805e-106 3.972794149108561e-04
    ## 18 2.115843884379114e-105 4.052398723966714e-105 7.010250489158931e-05
    ## 50 2.154922293956493e-105 4.058902895704733e-105 6.952455453346218e-05
    ## 42 5.862643740036630e-105 4.510847179226700e-105 5.476335859344594e-05
    ## 55 2.656329763074613e-104 4.936311640205885e-105 5.169637500268554e-05
    ## 32 1.051769150732347e-102 2.414233840178708e-103 8.642015990156793e-06
    ## 16 1.273883938664113e-101 2.450386155439669e-103 8.587673891669034e-06
    ## 48 1.435244238880453e-101 5.409188223230362e-103 4.640191034188668e-06
    ## 36  1.032900686278633e-99 2.278732521552195e-101 5.160695289996298e-07
    ## 54  8.312953161701802e-99 4.519172941573910e-101 0.000000000000000e+00
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
                           psi = priors.out$gamma_prior$psi, mu = priors.out$gamma_prior$mu,
                           alpha0 = priors.out$pi_prior$alpha_0, alpha1 = priors.out$pi_prior$alpha_1,
                           address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`address_field`).
