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
    ## 21       2       0       0       0       1       0       0      3
    ## 33       0       0       1       0       0       2       0      3
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
    ## 24       0       2       0       0       2       0       0      1
    ## 8        2      NA       0       0       0       0       0    559
    ## 52       0       0       0       0       2       0       2      1
    ## 28       2       0       0       0       0       2       0    153
    ## 5        2       2       0       0       0       0       0      9
    ## 45       2       0       0       0       0       0       2     19
    ## 13       0      NA       2       0       0       0       0     36
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
    ## 54       2       0       0       0       0       2       2      3
    ## 36       0      NA       2       0       0       2       0      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -410.33042344835405 1.789359386075474e-179 2.863757478838720e-01
    ## 2  -405.12399868923927 3.800412448742589e-179 3.333863768687974e-03
    ## 19 -400.56073345734018 1.414810382593957e-178 1.294238890798555e-04
    ## 20 -395.35430869822534 3.004909484624653e-178 1.506697469301736e-06
    ## 9  -389.46941870809559 1.339177085652248e-173 1.867486300460568e-04
    ## 6  -355.81536447549416 8.535039295864082e-156 2.883068048486992e-01
    ## 26 -351.52325404273853 8.158932986447881e-155 3.769145106752195e-02
    ## 4  -350.80940677094907 8.535039295864082e-156 1.931056964827189e-03
    ## 7  -350.60893971637938 1.812753203348993e-155 3.356344306575284e-03
    ## 43 -349.06889504195317 8.706649498309213e-155 3.455779167934082e-03
    ## 14 -346.96396868823138 9.836149342608774e-156 4.757317474627734e-05
    ## 27 -346.31682928362375 1.732872151421651e-154 4.387877256779533e-04
    ## 22 -346.04567448448029 6.748483454808100e-155 1.302966057965100e-04
    ## 23 -345.62798307609449 8.761337815684699e-155 1.114028412332929e-04
    ## 44 -343.86247028283839 1.849201417988207e-154 4.023070055930163e-05
    ## 39 -341.75356405172465 6.451103780460587e-154 1.703417352296155e-05
    ## 3  -340.51059820177096 4.264990041784519e-152 3.249315259387583e-04
    ## 10 -334.95435973523570 6.387721292384675e-150 1.880078925547961e-04
    ## 11 -333.01356626889805 7.364647161051927e-150 3.112477167434274e-05
    ## 21 -330.74090821075708 3.372241618834895e-151 1.468486842283143e-07
    ## 33 -330.66224930248012 6.106239017074562e-149 2.457899072571613e-05
    ## 17 -301.15186680777265 4.691730560805993e-132 2.883546988135652e-01
    ## 30 -297.00819506987870 3.891717571861394e-131 3.794560785152411e-02
    ## 47 -294.55383606909334 4.152972073786076e-131 3.479081792127839e-03
    ## 15 -292.44890971537154 4.691730560805993e-132 4.789396486594211e-05
    ## 29 -292.00223736533354 3.891717571861394e-131 2.541567840021710e-04
    ## 31 -291.80177031076386 8.265601657323232e-131 4.417465100722750e-04
    ## 25 -291.11292410323466 4.179057774705216e-131 1.121540404324386e-04
    ## 53 -290.26172563633770 3.969966589495096e-130 4.548336665057549e-04
    ## 46 -289.54787836454818 4.152972073786076e-131 2.330262419375648e-05
    ## 37 -288.15679928261591 4.484984064998152e-131 6.261361170859708e-06
    ## 40 -287.23850507886482 3.077102604228104e-130 1.714903645973134e-05
    ## 41 -286.82081367047897 3.994902794042958e-130 1.466232657672632e-05
    ## 24 -286.10696639868951 4.179057774705216e-131 7.511991991456039e-07
    ## 8  -285.99553922891113 2.034351393374163e-128 3.271225679208135e-04
    ## 52 -284.36645466969367 4.263084212766794e-130 1.344330380025045e-06
    ## 28 -281.70342879615549 1.944705362688818e-127 4.276598420332113e-05
    ## 5  -280.98958152436597 2.034351393374163e-128 2.191041982055012e-06
    ## 45 -279.24906979537008 2.075255183311212e-127 3.921042918758394e-06
    ## 13 -278.49850729603816 3.512852331895989e-126 3.133464875913262e-05
    ## 34 -276.14719032962023 2.912606062607458e-125 2.474472903135143e-05
    ## 35 -274.20639686328258 3.358054459235302e-125 4.096498454286010e-06
    ## 12 -273.49254959149300 3.512852331895989e-126 2.098770847899037e-07
    ## 49 -271.75203786249716 3.583483676279915e-125 3.755916426362859e-07
    ## 38 -242.34469740215718 2.139286022359113e-107 3.795191143360645e-02
    ## 51 -239.89033840137182 2.282898217726695e-107 3.479659742485983e-03
    ## 56 -235.74666666347781 1.893628586201685e-106 4.579006500964880e-04
    ## 42 -232.30575469761916 1.905522870120276e-106 1.476119594002186e-05
    ## 18 -231.33204156118961 1.118287599254167e-104 3.271769100192702e-04
    ## 50 -231.18738130897066 2.282898217726695e-107 5.779503581448722e-07
    ## 55 -230.74070895893269 1.893628586201685e-106 3.066983590733346e-06
    ## 32 -227.18836982329563 9.276021809028640e-104 4.305435901251417e-05
    ## 48 -224.73401082251027 9.898729498579726e-104 3.947482857522776e-06
    ## 16 -222.62908446878845 1.118287599254167e-104 5.434209845680956e-08
    ## 54 -220.44190038975461 9.462530614126531e-103 5.160695289252128e-07
    ## 36 -219.69133789042269 1.601753509678463e-101 4.124121505225226e-06
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  1.196441561003452e-182 1.789359386075474e-179 7.136242521161280e-01
    ## 2  2.182795421258182e-180 5.589771834818064e-179 7.102903883474400e-01
    ## 19 2.093215508736944e-178 1.973787566075763e-178 7.101609644583602e-01
    ## 20 3.818875386062164e-176 4.978697050700416e-178 7.101594577608908e-01
    ## 9  1.373127093619436e-173 1.339226872622755e-173 7.099727091308448e-01
    ## 6  5.668664882490045e-159 8.535039295864082e-156 4.216659042821456e-01
    ## 26 4.144963017364601e-157 9.012436916034290e-155 3.839744532146235e-01
    ## 4  8.463316669557709e-157 9.865940845620697e-155 3.820433962497963e-01
    ## 7  1.034194744937535e-156 1.167869404896969e-154 3.786870519432211e-01
    ## 43 4.824310264021471e-156 2.038534354727890e-154 3.752312727752870e-01
    ## 14 3.959069547233331e-155 2.136895848153978e-154 3.751836996005408e-01
    ## 27 7.562096294949620e-155 3.869767999575629e-154 3.747449118748628e-01
    ## 22 9.917523456731882e-155 4.544616345056439e-154 3.746146152690663e-01
    ## 23 1.505928353157301e-154 5.420750126624909e-154 3.745032124278330e-01
    ## 44 8.801501634733442e-154 7.269951544613116e-154 3.744629817272737e-01
    ## 39 7.251754831896570e-153 1.372105532507370e-153 3.744459475537507e-01
    ## 3  2.513369397324000e-152 4.402200595035256e-152 3.741210160278120e-01
    ## 10 6.505789825846459e-150 6.431743298335028e-150 3.739330081352572e-01
    ## 11 4.530810746449937e-149 1.379639045938695e-149 3.739018833635829e-01
    ## 21 4.397225884773943e-148 1.413361462127044e-149 3.739017365148986e-01
    ## 33 4.757073982301385e-148 7.519600479201607e-149 3.738771575241728e-01
    ## 17 3.115560448807579e-135 4.691730560805993e-132 8.552245871060771e-02
    ## 30 1.963857413649771e-133 4.360890627941993e-131 4.757685085908359e-02
    ## 47 2.285727867306665e-132 8.513862701728069e-131 4.409776906695573e-02
    ## 15 1.875782256420009e-131 8.983035757808668e-131 4.404987510208980e-02
    ## 29 2.932039118579133e-131 1.287475332967006e-130 4.379571831808760e-02
    ## 31 3.582873673264623e-131 2.114035498699329e-130 4.335397180801537e-02
    ## 25 7.134993842849077e-131 2.531941276169851e-130 4.324181776758296e-02
    ## 53 1.671338432266531e-130 6.501907865664947e-130 4.278698410107717e-02
    ## 46 3.412591705888687e-130 6.917205073043555e-130 4.276368147688336e-02
    ## 37 1.371583651999889e-129 7.365703479543370e-130 4.275742011571260e-02
    ## 40 3.435835839530901e-129 1.044280608377147e-129 4.274027107925282e-02
    ## 41 5.217151872760611e-129 1.443770887781443e-129 4.272560875267606e-02
    ## 24 1.065254580737377e-128 1.485561465528495e-129 4.272485755347699e-02
    ## 8  1.190818616112401e-128 2.182907539927013e-128 4.239773498555610e-02
    ## 52 6.072227719107412e-128 2.225538382054681e-128 4.239639065517609e-02
    ## 28 8.707339781932970e-127 2.167259200894286e-127 4.235362467097281e-02
    ## 5  1.777892193855830e-126 2.370694340231702e-127 4.235143362899074e-02
    ## 45 1.013444716064377e-125 4.445949523542914e-127 4.234751258607194e-02
    ## 13 2.146669641438104e-125 3.957447284250280e-126 4.231617793731279e-02
    ## 34 2.253871739816728e-124 3.308350791032486e-125 4.229143320828144e-02
    ## 35 1.569658192662686e-123 6.666405250267787e-125 4.228733670982721e-02
    ## 12 3.204977774667117e-123 7.017690483457387e-125 4.228712683274238e-02
    ## 49 1.826920553487371e-122 1.060117415973730e-124 4.228675124109982e-02
    ## 38 1.079357593348705e-109 2.139286022359113e-107 4.334839807493274e-03
    ## 51 1.256261128103483e-108 4.422184240085808e-107 8.551800650072883e-04
    ## 56 7.918696396503658e-107 2.335847010210266e-106 3.972794149108561e-04
    ## 42 2.471853751296373e-105 4.241369880330541e-106 3.825182189708398e-04
    ## 18 6.544869839675318e-105 1.160701298057472e-104 5.534130895157308e-05
    ## 50 7.563558378167857e-105 1.162984196275199e-104 5.476335859344594e-05
    ## 55 1.182261371998006e-104 1.181920482137215e-104 5.169637500268554e-05
    ## 32 4.125482835981951e-103 1.045794229116586e-103 8.642015990156793e-06
    ## 48 4.801637338208717e-102 2.035667178974558e-103 4.694533132676426e-06
    ## 16 3.940463013818307e-101 2.147495938899975e-103 4.640191034188668e-06
    ## 54 3.510987084657258e-100 1.161002655302651e-102 4.124121505300060e-06
    ## 36 7.436941815024500e-100 1.717853775208728e-101 0.000000000000000e+00
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
