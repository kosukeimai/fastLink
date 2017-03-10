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
    ## 27       1       0       0       0       0       2       0      9
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
    ## 1  -409.59744622048953 3.724136075108311e-179 2.863757478838720e-01
    ## 2  -403.82155063628932 1.397902026182233e-178 3.333863768687974e-03
    ## 19 -399.61986184000330 3.625046566730053e-178 1.294238890798555e-04
    ## 20 -393.84396625580308 1.360707514021013e-177 1.506697469301736e-06
    ## 9  -389.40304352968417 1.431081552107460e-173 1.867486300460568e-04
    ## 6  -355.12743420805731 1.698125736247684e-155 2.883068048486992e-01
    ## 26 -350.89219447467804 1.533553933308480e-154 3.769145106752195e-02
    ## 4  -350.12147650351221 1.698125736247684e-155 1.931056964827189e-03
    ## 7  -349.35153862385710 6.374131770530955e-155 3.356344306575284e-03
    ## 43 -348.22416101921476 2.026349652516389e-154 3.455779167934082e-03
    ## 14 -346.30000690808714 1.910645216415473e-155 4.757317474627734e-05
    ## 22 -345.14984982757107 1.652943057372461e-154 1.302966057965100e-04
    ## 27 -345.11629889047776 5.756390495396465e-154 4.387877256779533e-04
    ## 23 -344.77743655474285 2.050964233416771e-154 1.114028412332929e-04
    ## 44 -342.44826543501455 7.606162148422412e-154 4.023070055930163e-05
    ## 39 -340.91461009419180 1.492750079137018e-153 1.703417352296155e-05
    ## 3  -339.78865728892589 8.779160244313343e-152 3.249315259387583e-04
    ## 10 -334.93303151725195 6.525423253317297e-150 1.880078925547961e-04
    ## 11 -333.01587597428778 7.347656624930318e-150 3.112477167434274e-05
    ## 33 -330.69779178387273 5.893019747017827e-149 2.457899072571613e-05
    ## 21 -329.81107290843971 8.545569780635274e-151 1.468486842283143e-07
    ## 17 -300.53295198805608 8.712130140785143e-132 2.883546988135652e-01
    ## 30 -296.42218246224581 6.992675212597475e-131 3.794560785152411e-02
    ## 47 -293.75414900678260 9.239717416809358e-131 3.479081792127839e-03
    ## 15 -291.82999489565498 8.712130140785143e-132 4.789396486594211e-05
    ## 29 -291.41622475770066 6.992675212597475e-131 2.541567840021710e-04
    ## 31 -290.64628687804554 2.624789924691459e-130 4.417465100722750e-04
    ## 25 -290.30742454231057 9.351954597382501e-131 1.121540404324386e-04
    ## 53 -289.51890927340327 8.344261372845783e-130 4.548336665057549e-04
    ## 46 -288.74819130223744 9.239717416809358e-131 2.330262419375648e-05
    ## 37 -287.59475516227565 7.867804579900489e-131 6.261361170859708e-06
    ## 40 -286.44459808175964 6.806618437256255e-130 1.714903645973134e-05
    ## 41 -286.07218480893130 8.445621222741774e-130 1.466232657672632e-05
    ## 8  -285.31864527649367 4.003107741727029e-128 3.271225679208135e-04
    ## 24 -285.30146683776542 9.351954597382501e-131 7.511991991456039e-07
    ## 52 -283.40415135346808 1.115955641225259e-129 1.344330380025045e-06
    ## 28 -281.08340554311445 3.615151394117583e-127 4.276598420332113e-05
    ## 5  -280.31268757194852 4.003107741727029e-128 2.191041982055012e-06
    ## 13 -278.54586396185556 3.350372962819863e-126 3.133464875913262e-05
    ## 45 -278.41537208765112 4.776852389834506e-127 3.921042918758394e-06
    ## 34 -276.22777977144051 2.687089916910661e-125 2.474472903135143e-05
    ## 35 -274.31062422847629 3.025675617246151e-125 4.096498454286010e-06
    ## 12 -273.53990625731041 3.350372962819863e-126 2.098770847899037e-07
    ## 49 -271.64259077301301 3.997953122135653e-125 3.755916426362859e-07
    ## 38 -241.82770024224459 3.587549212875591e-107 3.795191143360645e-02
    ## 51 -239.15966678678132 4.740380460707143e-107 3.479659742485983e-03
    ## 56 -235.04889726097105 3.804803235283166e-106 4.579006500964880e-04
    ## 42 -231.60217279649910 3.851021140928726e-106 1.476119594002186e-05
    ## 18 -230.72416305649244 2.053769922277624e-104 3.271769100192702e-04
    ## 50 -230.45670969438015 4.740380460707143e-107 5.779503581448722e-07
    ## 55 -230.04293955642592 3.804803235283166e-106 3.066983590733346e-06
    ## 32 -226.61339353068217 1.648431072058656e-103 4.305435901251417e-05
    ## 48 -223.94536007521893 2.178141673085431e-103 3.947482857522776e-06
    ## 16 -222.02120596409128 2.053769922277624e-104 5.434209845680956e-08
    ## 36 -219.84061221604406 1.379642830326321e-101 4.124121505225226e-06
    ## 54 -219.71012034183966 1.967049705897617e-102 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  2.490115296997089e-182 3.724136075108311e-179 7.136242521161280e-01
    ## 2  8.028955233865955e-180 1.770315633693065e-178 7.102903883474400e-01
    ## 19 5.363265485415000e-178 5.395362200423118e-178 7.101609644583602e-01
    ## 20 1.729294163272864e-175 1.900243734063324e-177 7.101594577608908e-01
    ## 9  1.467361466553636e-173 1.431271576480866e-173 7.099727091308448e-01
    ## 6  1.127833791202863e-158 1.698125736247684e-155 4.216659042821456e-01
    ## 26 7.790877004696517e-157 1.703366506933248e-154 3.839744532146235e-01
    ## 4  1.683855850265888e-156 1.873179080558017e-154 3.820433962497963e-01
    ## 7  3.636509133424151e-156 2.510592257611112e-154 3.786870519432211e-01
    ## 43 1.122790050182858e-155 4.536941910127501e-154 3.752312727752870e-01
    ## 14 7.690384751591509e-155 4.728006431769048e-154 3.751836996005408e-01
    ## 22 2.429153402229042e-154 6.380949489141509e-154 3.750534029947442e-01
    ## 27 2.512036401635771e-154 1.213733998453797e-153 3.746146152690663e-01
    ## 23 3.525266637801102e-154 1.418830421795474e-153 3.745032124278330e-01
    ## 44 3.620246444339164e-153 2.179446636637716e-153 3.744629817272737e-01
    ## 39 1.678016346905365e-152 3.672196715774734e-153 3.744459475537507e-01
    ## 3  5.173581292355913e-152 9.146379915890816e-152 3.741210160278120e-01
    ## 10 6.646037024405761e-150 6.616887052476205e-150 3.739330081352572e-01
    ## 11 4.520357984496202e-149 1.396454367740652e-149 3.739018833635829e-01
    ## 33 4.590965213994747e-148 7.289474114758480e-149 3.738773043728572e-01
    ## 21 1.114297398788825e-147 7.374929812564832e-149 3.738771575241728e-01
    ## 17 5.785321160222736e-135 8.712130140785143e-132 8.552245871060771e-02
    ## 30 3.528677712071557e-133 7.863888226675989e-131 4.757685085908359e-02
    ## 47 5.085389261090367e-132 1.710360564348535e-130 4.409776906695573e-02
    ## 15 3.483162326120306e-131 1.797481865756386e-130 4.404987510208980e-02
    ## 29 5.268315824122880e-131 2.496749387016134e-130 4.379571831808760e-02
    ## 31 1.137762392734613e-130 5.121539311707593e-130 4.335397180801537e-02
    ## 25 1.596679013982644e-130 6.056734771445843e-130 4.324181776758296e-02
    ## 53 3.512897251633526e-130 1.440099614429163e-129 4.278698410107717e-02
    ## 46 7.592486166807552e-130 1.532496788597256e-129 4.276368147688336e-02
    ## 37 2.406107130488949e-129 1.611174834396261e-129 4.275742011571260e-02
    ## 40 7.600144220281330e-129 2.291836678121886e-129 4.274027107925282e-02
    ## 41 1.102957715130332e-128 3.136398800396064e-129 4.272560875267606e-02
    ## 8  2.343240817037877e-128 4.316747621766635e-128 4.239848618475528e-02
    ## 24 2.383841767876108e-128 4.326099576364018e-128 4.239773498555610e-02
    ## 52 1.589538568731294e-127 4.437695140486543e-128 4.239639065517609e-02
    ## 28 1.618669447601430e-126 4.058920908166238e-127 4.235362467097281e-02
    ## 5  3.498458539837581e-126 4.459231682338940e-127 4.235143362899074e-02
    ## 13 2.047380090952649e-125 3.796296131053757e-126 4.232009898023159e-02
    ## 45 2.332761702188837e-125 4.273981370037208e-126 4.231617793731279e-02
    ## 34 2.079359822745673e-124 3.114488053914382e-125 4.229143320828144e-02
    ## 35 1.414294073727339e-123 6.140163671160534e-125 4.228733670982721e-02
    ## 12 3.056738475792330e-123 6.475200967442520e-125 4.228712683274238e-02
    ## 49 2.038224083189071e-122 1.047315408957817e-124 4.228675124109982e-02
    ## 38 1.810065808853034e-109 3.587549212875591e-107 4.334839807493274e-03
    ## 51 2.608594487027895e-108 8.327929673582735e-107 8.551800650072883e-04
    ## 56 1.591076618096285e-106 4.637596202641440e-106 3.972794149108561e-04
    ## 42 4.995563791331177e-105 8.488617343570166e-106 3.825182189708398e-04
    ## 18 1.201985681582444e-104 2.138656095713326e-104 5.534130895157308e-05
    ## 50 1.570553784258862e-104 2.143396476174033e-104 5.476335859344594e-05
    ## 55 2.375477390817774e-104 2.181444508526865e-104 5.169637500268554e-05
    ## 32 7.331347676929891e-103 1.866575522911343e-103 8.642015990156793e-06
    ## 48 1.056564520416082e-101 4.044717195996774e-103 4.694533132676426e-06
    ## 16 7.236782758768775e-101 4.250094188224536e-103 4.640191034188668e-06
    ## 36 6.405681893409573e-100 1.422143772208566e-101 5.160695289996298e-07
    ## 54 7.298561446105184e-100 1.618848742798327e-101 0.000000000000000e+00
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
