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
    ## 9        0       0       1       0       0       0       0     12
    ## 20       1       0       0       0       1       0       0      1
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
    ## 3        2       0       0       0       0       0       0   1181
    ## 44       1       0       0       0       0       0       2      2
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
    ## 53       0       0       0       0       0       2       2    150
    ## 46       0       2       0       0       0       0       2     10
    ## 37       0       0       0       2       0       2       0      4
    ## 31       1      NA       0       0       0       2       0      3
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 8        2      NA       0       0       0       0       0    559
    ## 24       0       2       0       0       2       0       0      1
    ## 52       0       0       0       0       2       0       2      1
    ## 13       0      NA       2       0       0       0       0     36
    ## 28       2       0       0       0       0       2       0    153
    ## 34       0      NA       1       0       0       2       0      1
    ## 5        2       2       0       0       0       0       0      9
    ## 45       2       0       0       0       0       0       2     19
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
    ## 36       0      NA       2       0       0       2       0      3
    ## 16       2      NA       0       2       0       0       0      1
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -329.59807415341601 2.062107897950746e-144 2.863757478838720e-01
    ## 2  -320.79490219183356 1.597688115648318e-142 3.333863768687974e-03
    ## 19 -320.03756647564927 1.322712091823112e-143 1.294238890798556e-04
    ## 9  -314.66943618849160 4.093150037461496e-141 1.867486300460570e-04
    ## 20 -311.23439451406676 1.024816107648984e-141 1.506697469301736e-06
    ## 6  -285.42509152803774 3.171850035156768e-125 2.883068048486992e-01
    ## 26 -281.33323560180162 2.481824455093657e-124 3.769145106752195e-02
    ## 4  -280.41913382349264 3.171850035156768e-125 1.931056964827189e-03
    ## 43 -279.34211295333489 1.666509383941215e-124 3.455779167934082e-03
    ## 14 -276.64164498414107 3.415248060119977e-125 4.757317474627751e-05
    ## 7  -276.62191956645523 2.457498519270013e-123 3.356344306575284e-03
    ## 22 -275.86458385027100 2.034541645042295e-124 1.302966057965101e-04
    ## 23 -275.48563084369880 2.541013358620229e-124 1.114028412332929e-04
    ## 27 -272.53006364021911 1.922877770347984e-122 4.387877256779533e-04
    ## 39 -271.77272792403483 1.591933777954568e-123 1.703417352296155e-05
    ## 3  -271.33131612050482 4.721701101446878e-122 3.249315259387583e-04
    ## 44 -270.53894099175238 1.291184733827651e-122 4.023070055930163e-05
    ## 10 -270.49645356311333 6.295915991169087e-122 1.880078925547963e-04
    ## 11 -268.57050199403369 7.151862499818143e-122 3.112477167434274e-05
    ## 33 -266.40459763687721 4.926260100858260e-121 2.457899072571613e-05
    ## 21 -261.77080844273809 3.028673304178123e-121 1.468486842283146e-07
    ## 17 -241.17161945116399 5.253194893596870e-106 2.883546988135652e-01
    ## 30 -237.16025297642335 3.817440878319048e-105 3.794560785152411e-02
    ## 47 -235.16913032795662 2.563356579593215e-105 3.479081792127839e-03
    ## 15 -232.46866235876283 5.253194893596870e-106 4.789396486594228e-05
    ## 29 -232.15429527187820 3.817440878319048e-105 2.541567840021710e-04
    ## 25 -231.31264821832050 3.908482829091093e-105 1.121540404324386e-04
    ## 53 -231.07727440172050 2.005706756575917e-104 4.548336665057549e-04
    ## 46 -230.16317262341150 2.563356579593215e-105 2.330262419375648e-05
    ## 37 -228.37680643252671 4.110379560759115e-105 6.261361170859730e-06
    ## 31 -228.35708101484084 2.957691946935297e-103 4.417465100722750e-04
    ## 40 -227.59974529865659 2.448647432362945e-104 1.714903645973137e-05
    ## 41 -227.22079229208438 3.058205198869754e-104 1.466232657672632e-05
    ## 8  -227.15833349512656 7.262727532107899e-103 3.271225679208135e-04
    ## 24 -226.30669051377535 3.908482829091093e-105 7.511991991456039e-07
    ## 52 -225.22966964361765 2.053540753647732e-104 1.344330380025045e-06
    ## 13 -224.39751936865545 1.100070240942668e-102 3.133464875913262e-05
    ## 28 -223.06647756889043 5.682744959591382e-102 4.276598420332113e-05
    ## 34 -222.23161501149895 7.577371819208207e-102 2.474472903135143e-05
    ## 5  -222.15237579058143 7.262727532107899e-103 2.191041982055012e-06
    ## 45 -221.07535492042371 3.815881410253316e-102 3.921042918758394e-06
    ## 35 -220.30566344241933 8.607535652792194e-102 4.096498454286010e-06
    ## 12 -219.39156166411030 1.100070240942668e-102 2.098770847899037e-07
    ## 49 -218.31454079395260 5.779836244480013e-102 3.755916426362859e-07
    ## 38 -192.90678089954957  6.322417739274491e-86 3.795191143360645e-02
    ## 51 -190.91565825108287  4.245412470681668e-86 3.479659742485983e-03
    ## 56 -186.90429177634221  3.085096106116375e-85 4.579006500964880e-04
    ## 42 -183.04780966670609  4.704006166307601e-85 1.476119594002186e-05
    ## 18 -182.90486141825281  1.202847636627557e-83 3.271769100192702e-04
    ## 50 -182.21270115868171  4.245412470681668e-86 5.779503581448743e-07
    ## 55 -181.89833407179708  3.085096106116375e-85 3.066983590733346e-06
    ## 32 -178.89349494351217  8.740965891154310e-83 4.305435901251417e-05
    ## 48 -176.90237229504547  5.869432728177801e-83 3.947482857522776e-06
    ## 36 -176.13268081704103  1.323975932105903e-82 4.124121505225226e-06
    ## 16 -174.20190432585167  1.202847636627557e-83 5.434209845680975e-08
    ## 54 -172.81051636880932  4.592556874019670e-82 5.160695289252128e-07
    ## 58   39.45891089494344  5.000000000000000e-01 3.649074589734588e-18
    ## 57   44.46486859948859  5.000000000000000e-01 2.444122297210036e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  1.378812781591587e-147 2.062107897950746e-144 7.136242521161280e-01
    ## 2  9.176441637511258e-144 1.618309194627826e-142 7.102903883474400e-01
    ## 19 1.956955856601620e-143 1.750580403810137e-142 7.101609644583602e-01
    ## 9  4.196917102976234e-141 4.268208077842510e-141 7.099742158283140e-01
    ## 20 1.302416937603562e-139 5.293024185491494e-141 7.099727091308448e-01
    ## 6  2.106628251322853e-128 3.171850035156769e-125 4.216659042821456e-01
    ## 26 1.260835283123571e-126 2.799009458609333e-124 3.839744532146235e-01
    ## 4  3.145195979225047e-126 3.116194462125010e-124 3.820433962497963e-01
    ## 43 9.234043850733838e-126 4.782703846066226e-124 3.785876170818623e-01
    ## 14 1.374644092937549e-124 5.124228652078224e-124 3.785400439071160e-01
    ## 7  1.402028720526013e-124 2.969921384477835e-123 3.751836996005408e-01
    ## 22 2.989947982169069e-124 3.173375548982064e-123 3.750534029947442e-01
    ## 23 4.367579635666194e-124 3.427476884844088e-123 3.749420001535110e-01
    ## 27 8.391263516388112e-123 2.265625458832393e-122 3.745032124278330e-01
    ## 39 1.789509804710842e-122 2.424818836627850e-122 3.744861782543101e-01
    ## 3  2.782510377614426e-122 7.146519938074727e-122 3.741612467283713e-01
    ## 44 6.145552580145929e-122 8.437704671902378e-122 3.741210160278120e-01
    ## 10 6.412287625723985e-122 1.473362066307147e-121 3.739330081352572e-01
    ## 11 4.399903316845390e-121 2.188548316288961e-121 3.739018833635829e-01
    ## 33 3.837809769698386e-120 7.114808417147221e-121 3.738773043728572e-01
    ## 21 3.949230854418176e-118 1.014348172132534e-120 3.738771575241728e-01
    ## 17 3.488402845869461e-109 5.253194893596879e-106 8.552245871060771e-02
    ## 30 1.926375547974519e-107 4.342760367678737e-105 4.757685085908359e-02
    ## 47 1.410829512869426e-106 6.906116947271951e-105 4.409776906695573e-02
    ## 15 2.100259092719965e-105 7.431436436631639e-105 4.404987510208980e-02
    ## 29 2.876078693125981e-105 1.124887731495069e-104 4.379571831808760e-02
    ## 25 6.673035507965284e-105 1.515736014404178e-104 4.368356427765518e-02
    ## 53 8.443937022019924e-105 3.521442770980094e-104 4.322873061114940e-02
    ## 46 2.106368462714072e-104 3.777778428939416e-104 4.320542798695570e-02
    ## 37 1.257023286448178e-103 4.188816385015328e-104 4.319916662578482e-02
    ## 31 1.282064760635071e-103 3.376573585436829e-103 4.275742011571260e-02
    ## 40 2.734114421445539e-103 3.621438328673124e-103 4.274027107925282e-02
    ## 41 3.993869639171387e-103 3.927258848560099e-103 4.272560875267606e-02
    ## 8  4.251276931386794e-103 1.118998638066800e-102 4.239848618475528e-02
    ## 24 9.962842013392254e-103 1.122907120895891e-102 4.239773498555610e-02
    ## 52 2.925010735015150e-102 1.143442528432368e-102 4.239639065517609e-02
    ## 13 6.722421458594479e-102 2.243512769375036e-102 4.236505600641693e-02
    ## 28 2.544426122670610e-101 7.926257728966418e-102 4.232229002221366e-02
    ## 34 5.863623105318917e-101 1.550362954817463e-101 4.229754529318230e-02
    ## 5  6.347156458560538e-101 1.622990230138541e-101 4.229535425120023e-02
    ## 45 1.863474373392069e-100 2.004578371163873e-101 4.229143320828144e-02
    ## 35 4.023427559039207e-100 2.865331936443093e-101 4.228733670982721e-02
    ## 12  1.003657523768136e-99 2.975338960537360e-101 4.228712683274238e-02
    ## 49  2.946658219968122e-99 3.553322584985361e-101 4.228675124109982e-02
    ## 38  3.189919217853391e-88  6.322417739274495e-86 4.334839807493274e-03
    ## 51  2.336217453003262e-87  1.056783020995616e-85 8.551800650072883e-04
    ## 56  1.290112517121097e-85  4.141879127111991e-85 3.972794149108561e-04
    ## 42  6.102060211733267e-84  8.845885293419593e-85 3.825182189708398e-04
    ## 18  7.039764389714172e-84  1.291306489561753e-83 5.534130895157308e-05
    ## 50  1.406564025152997e-83  1.295551902032435e-83 5.476335859344594e-05
    ## 55  1.926137988061760e-83  1.326402863093598e-83 5.169637500268554e-05
    ## 32  3.887518323723838e-82  1.006736875424791e-82 8.642015990156793e-06
    ## 48  2.847121678167534e-81  1.593680148242571e-82 4.694533132676426e-06
    ## 36  6.147220475603009e-81  2.917656080348474e-82 5.704116273763660e-07
    ## 16  4.238423663600320e-80  3.037940844011230e-82 5.160695289996298e-07
    ## 54  1.704027022767565e-79  7.630497718030900e-82 0.000000000000000e+00
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

If the provided variances are too large (forcing the parameter values for the
*γ*
 prior or the
*π*<sub>*k*, *l*</sub>
 prior below 1), the function will choose new parameter values by testing the sequence
1/(10<sup>*i*</sup>)
. The means and variances used to calculate optimal paramter values can be viewed in the `parameter_values` field of the output.

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
