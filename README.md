fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.com/kosukeimai/fastLink.svg?token=JxpGcfuMTdnnLSenfvSD&branch=master)](https://travis-ci.com/kosukeimai/fastLink)
================================================================================================================================================================================================

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
  dfA = dfA, dfB = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)
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

-   `stringdist.match` should be a vector of booleans of the same length as `varnames`. `TRUE` means that string-distance matching using the Jaro-Winkler similarity will be used.

-   `partial.match` is another vector of booleans of the same length as `varnames`. A `TRUE` for an entry in `partial.match` and a `TRUE` for that same entry for `stringdist.match` means that a partial match category will be included in the gamma calculation.

Other arguments that can be provided include:

-   `priors.obj`: The output from `calcMoversPriors()`, allowing the inclusion of auxiliary information on moving behavior to aid matching. We will discuss this option further at the end of this vignette.

-   `w.lambda`: The user-specified weighting of the MLE and prior estimate for the *λ* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `w.pi`: The user-specified weighting of the MLE and prior estimate for the *π* parameter, a number between 0 and 1. We will discuss this option further at the end of this vignette.

-   `l.address`: The number of possible matching categories used for address fields, used to calculate optimal hyperparameters for the *π* prior. We will discuss this option further at the end of this vignette.

-   `address.field`: A boolean vector the same length as `varnames`, where TRUE indicates an address matching field. Default is NULL. Should be specified in conjunction with `priors_obj`. We will discuss this option further at the end of this vignette.

-   `n.cores`: The number of registered cores to parallelize over. If left unspecified. the function will estimate this on its own.

-   `tol.em`: Convergence tolerance for the EM algorithm. Default is 1e-04

-   `match`: Lower bound for the posterior probability of a match that will be accepted. Default is 0.85.

-   `verbose`: Whether to print out runtime for each step and EM output. Default is FALSE.

The output from `fastLink()` will be a list of length 2 with two entries:

-   `matches`: A matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

-   `EM`: The output from the EM algorithm.

-   `nobs.a`: The number of observations in dataset A.

-   `nobs.b`: The number of observations in dataset B.

The datasets can then be subsetted down to the matches as follows:

``` r
dfA.match <- dfA[matches.out$matches$inds.a,]
dfB.match <- dfB[matches.out$matches$inds.b,]
```

We can also examine the EM object:

``` r
matches.out$EM
```

    ##    gamma.1 gamma.2 gamma.3 gamma.4 gamma.5 gamma.6 gamma.7 counts
    ## 1        0       0       0       0       0       0       0 101069
    ## 19       0       0       0       0       1       0       0     40
    ## 9        0       0       1       0       0       0       0     12
    ## 2        1       0       0       0       0       0       0    133
    ## 20       1       0       0       0       1       0       0      1
    ## 6        0      NA       0       0       0       0       0  48474
    ## 43       0       0       0       0       0       0       2   1203
    ## 26       0       0       0       0       0       2       0  13032
    ## 4        0       2       0       0       0       0       0    691
    ## 14       0       0       0       2       0       0       0     15
    ## 23       0       0       0       0       2       0       0     43
    ## 22       0      NA       0       0       1       0       0     17
    ## 10       0      NA       1       0       0       0       0      3
    ## 7        1      NA       0       0       0       0       0     48
    ## 11       0       0       2       0       0       0       0     65
    ## 3        2       0       0       0       0       0       0   1181
    ## 39       0       0       0       0       1       2       0      4
    ## 33       0       0       1       0       0       2       0      3
    ## 44       1       0       0       0       0       0       2      2
    ## 27       1       0       0       0       0       2       0      9
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 47       0      NA       0       0       0       0       2    593
    ## 30       0      NA       0       0       0       2       0   6701
    ## 15       0      NA       0       2       0       0       0      8
    ## 53       0       0       0       0       0       2       2    150
    ## 46       0       2       0       0       0       0       2     10
    ## 29       0       2       0       0       0       2       0     75
    ## 25       0      NA       0       0       2       0       0     27
    ## 37       0       0       0       2       0       2       0      4
    ## 13       0      NA       2       0       0       0       0     36
    ## 52       0       0       0       0       2       0       2      1
    ## 41       0       0       0       0       2       2       0      3
    ## 8        2      NA       0       0       0       0       0    559
    ## 40       0      NA       0       0       1       2       0      3
    ## 24       0       2       0       0       2       0       0      1
    ## 34       0      NA       1       0       0       2       0      1
    ## 31       1      NA       0       0       0       2       0      3
    ## 49       0       0       2       0       0       0       2      1
    ## 35       0       0       2       0       0       2       0      8
    ## 12       0       2       2       0       0       0       0      1
    ## 45       2       0       0       0       0       0       2     19
    ## 28       2       0       0       0       0       2       0    153
    ## 5        2       2       0       0       0       0       0      9
    ## 51       0      NA       0      NA       0       0       2      3
    ## 38       0      NA       0      NA       0       2       0     20
    ## 56       0      NA       0       0       0       2       2     92
    ## 50       0      NA       0       2       0       0       2      1
    ## 55       0       2       0       0       0       2       2      3
    ## 18       2      NA       0      NA       0       0       0      4
    ## 42       0      NA       0       0       2       2       0      4
    ## 36       0      NA       2       0       0       2       0      3
    ## 48       2      NA       0       0       0       0       2      5
    ## 32       2      NA       0       0       0       2       0     74
    ## 16       2      NA       0       2       0       0       0      1
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -427.78127135467042 4.719441699317952e-187 2.863757478838720e-01
    ## 19 -416.01457014797063 2.749047470214713e-185 1.294238890798554e-04
    ## 9  -414.47427984989662 1.850822604355855e-184 1.867486300460568e-04
    ## 2  -414.13888425948932 4.620784064898341e-183 3.333863768687974e-03
    ## 20 -402.37218305278947 2.691579969269040e-181 1.506697469301733e-06
    ## 6  -369.38216604454351 1.094506805907544e-161 2.883068048486992e-01
    ## 43 -365.20847793272753 8.521563250008111e-162 3.455779167934082e-03
    ## 26 -365.06648690168402 1.071228376025911e-160 3.769145106752195e-02
    ## 4  -364.37620833999841 1.094506805907544e-161 1.931056964827189e-03
    ## 14 -361.45345270544675 5.013282289840744e-162 4.757317474627726e-05
    ## 23 -358.17735881779299 3.107747959935274e-160 1.114028412332929e-04
    ## 22 -357.61546483784377 6.375438786218261e-160 1.302966057965099e-04
    ## 10 -356.07517453976971 4.292325376723621e-159 1.880078925547961e-04
    ## 7  -355.73977894936240 1.071626673212482e-157 3.356344306575284e-03
    ## 11 -354.48403403142413 3.488560600172347e-159 3.112477167434274e-05
    ## 3  -353.45674079946019 1.017371879398274e-157 3.249315259387583e-04
    ## 39 -353.29978569498417 6.239843279686732e-159 1.703417352296152e-05
    ## 33 -351.75949539691021 4.201034400028079e-158 2.457899072571613e-05
    ## 44 -351.56609083754643 8.343424112930857e-158 4.023070055930163e-05
    ## 27 -351.42409980650280 1.048834867591031e-156 4.387877256779533e-04
    ## 21 -341.69003959276040 5.926132304445256e-156 1.468486842283143e-07
    ## 17 -311.75730448772100 1.162652689821221e-136 2.883546988135652e-01
    ## 47 -306.80937262260068 1.976273798541341e-136 3.479081792127839e-03
    ## 30 -306.66738159155710 2.484333577870214e-135 3.794560785152411e-02
    ## 15 -303.05434739531984 1.162652689821221e-136 4.789396486594202e-05
    ## 53 -302.49369347974113 1.934241578368796e-135 4.548336665057549e-04
    ## 46 -301.80341491805552 1.976273798541341e-136 2.330262419375648e-05
    ## 29 -301.66142388701195 2.484333577870214e-135 2.541567840021710e-04
    ## 25 -299.77825350766608 7.207317114831647e-135 1.121540404324386e-04
    ## 37 -298.73866825246034 1.137924904694061e-135 6.261361170859698e-06
    ## 13 -296.08492872129722 8.090476719441940e-134 3.133464875913262e-05
    ## 52 -295.60456539585010 5.611441457047637e-135 1.344330380025045e-06
    ## 41 -295.46257436480647 7.054028871043386e-134 1.466232657672632e-05
    ## 8  -295.05763548933328 2.359432570808714e-132 3.271225679208135e-04
    ## 40 -294.90068038485731 1.447109927939268e-133 1.714903645973134e-05
    ## 24 -294.77229580312093 7.207317114831647e-135 7.511991991456039e-07
    ## 34 -293.36039008678330 9.742806534397819e-133 2.474472903135143e-05
    ## 31 -293.02499449637594 2.432399792156258e-131 4.417465100722750e-04
    ## 49 -291.91124060948124 6.299048001832749e-134 3.755916426362859e-07
    ## 35 -291.76924957843772 7.918405066706666e-133 4.096498454286010e-06
    ## 12 -291.07897101675206 8.090476719441940e-134 2.098770847899037e-07
    ## 45 -290.88394737751730 1.836996698216430e-132 3.921042918758394e-06
    ## 28 -290.74195634647378 2.309251169136688e-131 4.276598420332113e-05
    ## 5  -290.05167778478813 2.359432570808714e-132 2.191041982055012e-06
    ## 51 -249.18451106577817 2.099320018199430e-111 3.479659742485983e-03
    ## 38 -249.04252003473459 2.639012476792195e-110 3.795191143360645e-02
    ## 56 -244.09458816961421 4.485786045624740e-110 4.579006500964880e-04
    ## 50 -240.48155397337700 2.099320018199430e-111 5.779503581448713e-07
    ## 55 -239.08863046506909 4.485786045624740e-110 3.066983590733346e-06
    ## 18 -237.43277393251080 2.506334917330972e-107 3.271769100192702e-04
    ## 42 -237.06346905467962 1.635931345341306e-108 1.476119594002186e-05
    ## 36 -233.37014426831081 1.836392689986134e-107 4.124121505225226e-06
    ## 48 -232.48484206739042 4.260261100202042e-107 3.947482857522776e-06
    ## 32 -232.34285103634687 5.355487538992860e-106 4.305435901251417e-05
    ## 16 -228.72981684010966 2.506334917330972e-107 5.434209845680946e-08
    ## 54 -228.16916292453087 4.169652079990292e-106 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  3.155618841992979e-190 4.719441699317952e-187 7.136242521161280e-01
    ## 19 4.067222625520530e-185 2.796241887207893e-185 7.134948282270481e-01
    ## 9  1.897743540232777e-184 2.130446793076645e-184 7.133080795970020e-01
    ## 2  2.653982017878089e-184 4.833828744206005e-183 7.099742158283140e-01
    ## 20 3.420671586566419e-179 2.739918256711100e-181 7.099727091308448e-01
    ## 6  7.269318955919715e-165 1.094506805907544e-161 4.216659042821456e-01
    ## 43 4.721754913931677e-163 1.946663130908355e-161 4.182101251142114e-01
    ## 26 5.442135643415857e-163 1.265894689116746e-160 3.805186740466895e-01
    ## 4  1.085309320118823e-162 1.375345369707501e-160 3.785876170818623e-01
    ## 14 2.017856028213632e-161 1.425478192605908e-160 3.785400439071160e-01
    ## 23 5.341702221497486e-160 4.533226152541182e-160 3.784286410658827e-01
    ## 22 9.369299655647716e-160 1.090866493875944e-159 3.782983444600863e-01
    ## 10 4.371663303219371e-159 5.383191870599565e-159 3.781103365675315e-01
    ## 7  6.113742741834653e-159 1.125458591918478e-157 3.747539922609562e-01
    ## 11 2.146200287841769e-158 1.160344197920201e-157 3.747228674892819e-01
    ## 3  5.995398165824874e-158 2.177716077318475e-157 3.743979359633430e-01
    ## 39 7.014274641000260e-158 2.240114510115343e-157 3.743809017898201e-01
    ## 33 3.272821680783324e-157 2.660217950118151e-157 3.743563227990944e-01
    ## 44 3.971155346026436e-157 3.494560361411236e-157 3.743160920985351e-01
    ## 27 4.577019868267368e-157 1.398290903732155e-156 3.738773043728572e-01
    ## 21 7.727365150871049e-153 7.324423208177412e-156 3.738771575241728e-01
    ## 17 7.720636744076932e-140 1.162652689821221e-136 8.552245871060771e-02
    ## 47 1.087708757606885e-137 3.138926488362562e-136 8.204337691847985e-02
    ## 30 1.253656470386142e-137 2.798226226706470e-135 4.409776906695573e-02
    ## 15 4.648355777640796e-136 2.914491495688593e-135 4.404987510208980e-02
    ## 53 8.143071772366707e-136 4.848733074057389e-135 4.359504143558401e-02
    ## 46 1.623949175107001e-135 5.046360453911523e-135 4.357173881139031e-02
    ## 29 1.871709110286526e-135 7.530694031781737e-135 4.331758202738811e-02
    ## 25 1.230520514672999e-134 1.473801114661339e-134 4.320542798695570e-02
    ## 37 3.479965979505769e-134 1.587593605130745e-134 4.319916662578482e-02
    ## 13 4.944011053551451e-133 9.678070324572685e-134 4.316783197702567e-02
    ## 52 7.992793165471794e-133 1.023921447027745e-133 4.316648764664566e-02
    ## 41 9.212224134702106e-133 1.729324334132083e-133 4.315182532006889e-02
    ## 8  1.381106645553931e-132 2.532365004221922e-132 4.282470275214811e-02
    ## 40 1.615816173085317e-132 2.677075997015849e-132 4.280755371568834e-02
    ## 24 1.837167128406803e-132 2.684283314130681e-132 4.280680251648927e-02
    ## 34 7.539308729833022e-132 3.658563967570462e-132 4.278205778745792e-02
    ## 31 1.054367430161556e-131 2.798256188913305e-131 4.234031127738558e-02
    ## 49 3.211361150638292e-131 2.804555236915138e-131 4.233993568574301e-02
    ## 35 3.701306675237252e-131 2.883739287582204e-131 4.233583918728867e-02
    ## 12 7.381408502952379e-131 2.891829764301646e-131 4.233562931020396e-02
    ## 45 8.970918912558432e-131 3.075529434123289e-131 4.233170826728516e-02
    ## 28 1.033957891888459e-130 5.384780603259977e-131 4.228894228308178e-02
    ## 5  2.061992221812037e-130 5.620723860340848e-131 4.228675124109982e-02
    ## 51 1.155239473155225e-112 2.099320018199430e-111 3.880709149861383e-02
    ## 38 1.331490098096603e-112 2.848944478612138e-110 8.551800650073993e-04
    ## 56 1.875847146257208e-110 7.334730524236878e-110 3.972794149108561e-04
    ## 50 6.955338345272288e-109 7.544662526056821e-110 3.967014645527289e-04
    ## 55 2.800639789362036e-108 1.203044857168156e-109 3.936344809619685e-04
    ## 18 1.466853054572446e-107 2.518365365902654e-107 6.645757094270177e-05
    ## 42 2.122138283541035e-107 2.681958500436785e-107 5.169637500268554e-05
    ## 36 8.526371568684591e-106 4.518351190422919e-107 4.757225349749650e-05
    ## 48 2.066550941934855e-105 8.778612290624960e-107 4.362477063990511e-05
    ## 32 2.381836995998167e-105 6.233348768055356e-106 5.704116273763660e-07
    ## 16 8.831467011322368e-104 6.483982259788453e-106 5.160695289996298e-07
    ## 54 1.547111993329233e-103 1.065363433977874e-105 0.000000000000000e+00
    ## 58  9.999999999999627e-01  5.000000000000000e-01 0.000000000000000e+00
    ## 57  1.000000000000000e+00  1.000000000000000e+00 0.000000000000000e+00

where the first seven columns are indicators for the matching pattern for that field. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Fellegi-Sunter weight for each matching pattern

-   `p.gamma.j.m`: Probability of being in the matched set given that matching pattern

-   `p.gamma.j.u`: Probability of being in the unmatched set given that matching pattern

-   `zeta.j`: Posterior probability of a particular pattern representing a true match

### Preprocessing Matches via Clustering

In order to reduce the number of pairwise comparisons that need to be conducted, researchers will often cluster similar observations from dataset A and dataset B together so that comparisons are only made between these maximally similar groups. Here, we implement a form of this clustering that uses word embedding, a common preprocessing method for textual data, to form maximally similar groups.

First, we provide some guidance on how to choose the variables to cluster on. We recommend specifically that researchers cluster on first name only - matching on address fields will fail to group people who move into the same group, while matching on last name will fail to cluster women who changed their last name after marriage. Date fields will often change due to administrative errors, and while there may be administrative errors in first name, the word embedding can accomodate those errors while clustering similar spellings in the same group.

The clustering proceeds in three steps. First, a word embedding matrix is created out of the provided data. For instance, a word embedding of the name `ben` would be a vector of length 26, where each entry in the vector represents a different letter. That matrix takes the value 0 for most entries, except for entry 2 (B), 5 (E), and 14 (N), which take the count of 1 (representing the number of times that letter appears in the string). Second, principal components analysis is run on the word embedding matrix. Last, a subset of dimensions from the PCA step are selected according to the amount of variance explained by the dimensions, and then the K-means algorithm is run on that subset of dimensions in order to form the clusters.

The `clusterWordEmbed()` function runs the clustering procedure from start to finish:

``` r
cluster.out <- clusterWordEmbed(vecA = dfA$firstname, vecB = dfB$firstname, nclusters = 3)
```

-   `vecA`: The variable to cluster on in dataset A.

-   `vecB`: The variable to cluster on in dataset B.

-   `nclusters`: The number of clusters to create.

Other arguments that can be provided include:

-   `max.n`: The maximum size of a dataset in a cluster. `nclusters` is then chosen to reflect this maximum n size. If `nclusters` is filled, then `max.n` should be left as NULL, and vice versa.

-   `min.var`: The amount of variance the least informative dimension of the PCA should contribute in order to be included in the K-means step. The default value is .2 (out of 1).

-   `weighted.kmeans`: Whether to weight the dimensions of the PCA used in the K-means algorithm by the amount of variance explained by each feature. Default is `TRUE`.

-   `iter.max`: The maximum number of iterations the K-means algorithm should attempt to run. The default value is 5000.

The output of `clusterWordEmbed()` includes the following entries:

-   `clusterA`: Cluster assignments for dataset A.

-   `clusterB`: Cluster assignments for dataset B.

-   `n.clusters`: The number of clusters created.

-   `kmeans`: The output from the K-means algorithm.

-   `pca`: The output from the PCA step.

-   `dims.pca`: The number of dimensions from the PCA step included in the K-means algorithm.

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
tc <- tableCounts(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB))
```

    ## Parallelizing gamma calculation using 1 cores.

As with the functions above, `tableCounts()` also includes an `n.cores` argument. If left unspecified, the function will automatically determine the number of available cores for parallelization.

#### 3) Running the EM algorithm

We next run the EM algorithm to calculate the Fellegi-Sunter weights. The only required input to this function is the output from `tableCounts()`, as follows:

``` r
## Run EM algorithm
em.out <- emlinkMARmov(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB))

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
matches.out <- matchesLink(gammalist, nobs.a = nrow(dfA), nobs.b = nrow(dfB),
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
    *λ*
    : The probability that a randomly selected pair of observations from dataset A and dataset B are a true match. When matching, for example, the same state to itself in subsequent years, the prior for this quantity is equal to the number of non-movers to the number of in-state movers, divided by the size of the cross-product of A and B. When matching two different states in subsequent years to find movers, the numerator is the size of the outflow from state A to state B, divided by the size of the cross-product of A and B.

-   
    *π*<sub>*k*, *l*</sub>
    : The probability that an address field does not match conditional on being in the matched set. Specified when trying to find movers within the same geography over time. For example, when trying to find movers within the same state over time, this quantity is equal to the estimated number of in-state movers divided by the number of in-state movers and non-movers.

The functions `calcMoversPriors()` can be used to calculate estimates for the corresponding prior distributions using the IRS Statistics of Income Migration Data.

Below, we show an example where we incorporate the auxiliary moving information for California into our estimates. First, we use `calcMoversPriors()` to estimate optimal parameter values for the priors:

``` r
priors.out <- calcMoversPriors(geo.a = "CA", geo.b = "CA", year.start = 2014, year.end = 2015)
names(priors.out)
```

    ## [1] "lambda.prior" "pi.prior"

where the `lambda.prior` entry is the estimate of the match rate, while `pi.prior` is the estimate of the in-state movers rate.

The `calcMoversPriors()` function accepts the following functions:

-   `geo.a`: The state name or county name of dataset A

-   `geo.b`: The state name or county name of dataset B

-   `year.start`: The year of dataset A

-   `year.end`: The year of dataset B

-   `county`: Boolean, whether the geographies in `geo.a` or `geo.b` refer to counties or states. Default is FALSE

-   `state.a`: If `county = TRUE`, the name of the state for `geo.a`

-   `state.b`: If `county = TRUE`, the name of the state for `geo.b`

-   `matchrate.lambda`: If TRUE, then returns the match rate for lambda (the expected share of observations in dataset A that can be found in dataset B). If FALSE, then returns the expected share of matches across all pairwise comparisons of datasets A and B. Default is FALSE.

-   `remove.instate`: If TRUE, then for calculating cross-state movers rates assumes that successful matches have been subsetted out. The interpretation of the prior is then the match rate conditional on being an out-of-state or county mover. Default is TRUE.

### Incorporating Auxiliary Information with `fastLink()` Wrapper

We can re-run the full match above while incorporating auxiliary information as follows:

``` r
## Reasonable prior estimates for this dataset
priors.out <- list(lambda.prior = 50/(nrow(dfA) * nrow(dfB)), pi.prior = 0.02)

matches.out.aux <- fastLink(
  dfA = dfA, dfB = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE),
  priors.obj = priors.out, 
  w.lambda = .5, w.pi = .5, l.address = 3, 
  address.field = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE)
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

where `priors.obj` is an input for the the optimal prior parameters. This can be calculated by `calcMoversPriors()`, or can be provided by the user as a list with two entries named `lambda.prior` and `pi.prior`. `w.lambda` and `w.pi` are user-specified weights between 0 and 1 indicating the weighting between the MLE estimate and the prior, where a weight of 0 indicates no weight being placed on the prior. `address_field` is a vector of booleans of the same length as `varnames`, where `TRUE` indicates an address-related field used for matching. `l.address` is an integer indicating the number of matching fields used on the address variable - when a single partial match category is included, `l.address = 3`, while for a binary match/no match category `l.address = 2`.

### Incorporating Auxiliary Information when Running the Algorithm Step-by-Step

If we are running the algorithm step-by-step, we can incorporate the prior information into the EM algorithm as follows:

``` r
em.out.aux <- emlinkMARmov(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB),
                           prior.lambda = priors.out$lambda.prior, w.lambda = .5,
                           prior.pi = priors.out$pi.prior, w.pi = .5,
                           address.field = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE),
                           l.address = 3)
```

All other steps are the same. The newly specified arguments include the prior estimates of the parameters (`prior.lambda`, `prior.pi`), the weightings of the prior and MLE estimate (`w.lambda`, `w.pi`), the vector of boolean indicators where `TRUE` indicates an address field (`address.field`), and an integer indicating the number of matching categories for the address field (`l.address`).
