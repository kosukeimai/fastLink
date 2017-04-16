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
    ## 9        0       0       1       0       0       0       0     12
    ## 20       1       0       0       0       1       0       0      1
    ## 6        0      NA       0       0       0       0       0  48474
    ## 4        0       2       0       0       0       0       0    691
    ## 26       0       0       0       0       0       2       0  13032
    ## 43       0       0       0       0       0       0       2   1203
    ## 14       0       0       0       2       0       0       0     15
    ## 7        1      NA       0       0       0       0       0     48
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 27       1       0       0       0       0       2       0      9
    ## 39       0       0       0       0       1       2       0      4
    ## 3        2       0       0       0       0       0       0   1181
    ## 10       0      NA       1       0       0       0       0      3
    ## 44       1       0       0       0       0       0       2      2
    ## 11       0       0       2       0       0       0       0     65
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 47       0      NA       0       0       0       0       2    593
    ## 15       0      NA       0       2       0       0       0      8
    ## 29       0       2       0       0       0       2       0     75
    ## 25       0      NA       0       0       2       0       0     27
    ## 46       0       2       0       0       0       0       2     10
    ## 53       0       0       0       0       0       2       2    150
    ## 37       0       0       0       2       0       2       0      4
    ## 31       1      NA       0       0       0       2       0      3
    ## 40       0      NA       0       0       1       2       0      3
    ## 24       0       2       0       0       2       0       0      1
    ## 41       0       0       0       0       2       2       0      3
    ## 8        2      NA       0       0       0       0       0    559
    ## 13       0      NA       2       0       0       0       0     36
    ## 52       0       0       0       0       2       0       2      1
    ## 5        2       2       0       0       0       0       0      9
    ## 28       2       0       0       0       0       2       0    153
    ## 34       0      NA       1       0       0       2       0      1
    ## 12       0       2       2       0       0       0       0      1
    ## 35       0       0       2       0       0       2       0      8
    ## 45       2       0       0       0       0       0       2     19
    ## 49       0       0       2       0       0       0       2      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 50       0      NA       0       2       0       0       2      1
    ## 42       0      NA       0       0       2       2       0      4
    ## 18       2      NA       0      NA       0       0       0      4
    ## 55       0       2       0       0       0       2       2      3
    ## 32       2      NA       0       0       0       2       0     74
    ## 36       0      NA       2       0       0       2       0      3
    ## 48       2      NA       0       0       0       0       2      5
    ## 16       2      NA       0       2       0       0       0      1
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -486.05378338080595 2.325199419697820e-212 2.863757478838720e-01
    ## 2  -475.83118141324735 7.448887994686407e-210 3.333863768687974e-03
    ## 19 -474.01176676420107 1.783691665232075e-210 1.294238890798554e-04
    ## 9  -467.97246632358377 1.079935002485566e-207 1.867486300460568e-04
    ## 20 -463.78916479664241 5.714141900610017e-208 1.506697469301733e-06
    ## 6  -421.30555634797963 3.084441771361388e-184 2.883068048486992e-01
    ## 4  -416.29959864343454 3.084441771361388e-184 1.931056964827189e-03
    ## 26 -416.10293639753530 7.328813604309528e-183 3.769145106752195e-02
    ## 43 -412.94048796830168 1.587708256480867e-182 3.455779167934082e-03
    ## 14 -412.48888908720244 3.433315843290752e-184 4.757317474627726e-05
    ## 7  -411.08295438042103 9.881157326277418e-182 3.356344306575284e-03
    ## 22 -409.26353973137475 2.366116657721322e-182 1.302966057965099e-04
    ## 23 -408.98655692010465 2.668648805074284e-182 1.114028412332929e-04
    ## 27 -405.88033442997664 2.347820630349646e-180 4.387877256779533e-04
    ## 39 -404.06091978093036 5.622031225065940e-181 1.703417352296152e-05
    ## 3  -403.72791111253656 1.496193844181400e-179 3.249315259387583e-04
    ## 10 -403.22423929075745 1.432563849708270e-179 1.880078925547961e-04
    ## 44 -402.71788600074308 5.086299639753823e-180 4.023070055930163e-05
    ## 11 -401.31145155623193 1.606043258525464e-179 3.112477167434274e-05
    ## 33 -398.02161934031312 3.403855286964951e-178 2.457899072571613e-05
    ## 21 -391.68589449593168 1.147750367916713e-177 1.468486842283143e-07
    ## 17 -356.44361914677728 4.554389060831216e-156 2.883546988135652e-01
    ## 30 -351.35470936470898 9.721875304180005e-155 3.794560785152411e-02
    ## 47 -348.19226093547542 2.106139209195820e-154 3.479081792127839e-03
    ## 15 -347.74066205437612 4.554389060831216e-156 4.789396486594202e-05
    ## 29 -346.34875166016383 9.721875304180005e-155 2.541567840021710e-04
    ## 25 -344.23832988727833 3.540036943813835e-154 1.121540404324386e-04
    ## 46 -343.18630323093026 2.106139209195820e-154 2.330262419375648e-05
    ## 53 -342.98964098503109 5.004309639507429e-153 4.548336665057549e-04
    ## 37 -342.53804210393179 1.082149412520959e-154 6.261361170859698e-06
    ## 31 -341.13210739715032 3.114449437139286e-152 4.417465100722750e-04
    ## 40 -339.31269274810410 7.457780955727664e-153 1.714903645973134e-05
    ## 24 -339.23237218273317 3.540036943813835e-154 7.511991991456039e-07
    ## 41 -339.03570993683400 8.411334314840575e-153 1.466232657672632e-05
    ## 8  -338.97968407971024 1.984742793220992e-151 3.271225679208135e-04
    ## 13 -336.56322452340561 2.130461099914208e-151 3.133464875913262e-05
    ## 52 -335.87326150760043 1.822224668374741e-152 1.344330380025045e-06
    ## 5  -333.97372637516509 1.984742793220992e-151 2.191041982055012e-06
    ## 28 -333.77706412926597 4.715864672521393e-150 4.276598420332113e-05
    ## 34 -333.27339230748680 4.515308812587109e-150 2.474472903135143e-05
    ## 12 -331.55726681886046 2.130461099914208e-151 2.098770847899037e-07
    ## 35 -331.36060457296128 5.062099870866426e-150 4.096498454286010e-06
    ## 45 -330.61461570003235 1.021641111544421e-149 3.921042918758394e-06
    ## 49 -328.19815614372766 1.096649225105045e-149 3.755916426362859e-07
    ## 38 -286.49277216350669 1.435501326276531e-126 3.795191143360645e-02
    ## 51 -283.33032373427307 3.109858472288451e-126 3.479659742485983e-03
    ## 56 -278.24141395220477 6.638356073101523e-125 4.579006500964880e-04
    ## 50 -274.62736664187196 3.109858472288451e-126 5.779503581448713e-07
    ## 42 -274.28748290400773 1.115786916760515e-124 1.476119594002186e-05
    ## 18 -274.11774687850794 2.930608368080514e-123 3.271769100192702e-04
    ## 55 -273.23545624765961 6.638356073101523e-125 3.066983590733346e-06
    ## 32 -269.02883709643964 6.255725793146306e-122 4.305435901251417e-05
    ## 36 -266.61237754013496 6.715016424067676e-122 4.124121505225226e-06
    ## 48 -265.86638866720602 1.355235380282872e-121 3.947482857522776e-06
    ## 16 -265.41478978610678 2.930608368080514e-123 5.434209845680946e-08
    ## 54 -260.66376871676169 3.220118332036102e-120 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  1.554726929087816e-215 2.325199419697820e-212 7.136242521161280e-01
    ## 2  4.278324741738529e-211 7.472139988883385e-210 7.102903883474400e-01
    ## 19 2.638976291383453e-210 9.255831654115460e-210 7.101609644583602e-01
    ## 9  1.107312861867451e-207 1.089190834139682e-207 7.099742158283140e-01
    ## 20 7.261981090732198e-206 1.660605024200684e-207 7.099727091308448e-01
    ## 6  2.048574839002138e-187 3.084441771361388e-184 4.216659042821456e-01
    ## 4  3.058522234630219e-185 6.168883542722776e-184 4.197348473173184e-01
    ## 26 3.723239472793727e-185 7.945701958581806e-183 3.820433962497963e-01
    ## 43 8.797410805958984e-184 2.382278452339048e-182 3.785876170818623e-01
    ## 14 1.381916411366832e-183 2.416611610771956e-182 3.785400439071160e-01
    ## 7  5.637304053225689e-183 1.229776893704937e-181 3.751836996005408e-01
    ## 22 3.477228270834152e-182 1.466388559477070e-181 3.750534029947442e-01
    ## 23 4.586963754537807e-182 1.733253439984498e-181 3.749420001535110e-01
    ## 27 1.024567546740685e-180 2.521145974348095e-180 3.745032124278330e-01
    ## 39 6.319785495457418e-180 3.083349096854689e-180 3.744861782543101e-01
    ## 3  8.817108090729928e-180 1.804528753866869e-179 3.741612467283713e-01
    ## 10 1.459042887393754e-179 3.237092603575139e-179 3.739732388358165e-01
    ## 44 2.420886884390378e-179 3.745722567550522e-179 3.739330081352572e-01
    ## 11 9.880552178349418e-179 5.351765826075986e-179 3.739018833635829e-01
    ## 33 2.651778186189900e-177 3.939031869572550e-178 3.738773043728572e-01
    ## 21 1.496606174027913e-174 1.541653554873969e-177 3.738771575241728e-01
    ## 17 3.024358334842234e-159 4.554389060831216e-156 8.552245871060771e-02
    ## 30 4.905899911323913e-157 1.017731421026313e-154 4.757685085908359e-02
    ## 47 1.159184554423779e-155 3.123870630222133e-154 4.409776906695573e-02
    ## 15 1.820872294011908e-155 3.169414520830445e-154 4.404987510208980e-02
    ## 29 7.324508567606665e-155 4.141602051248445e-154 4.379571831808760e-02
    ## 25 6.043980045083643e-154 7.681638995062281e-154 4.368356427765518e-02
    ## 46 1.730662539754618e-153 9.787778204258101e-154 4.366026165346149e-02
    ## 53 2.106792296338787e-153 5.983087459933239e-153 4.320542798695570e-02
    ## 37 3.309395132122154e-153 6.091302401185335e-153 4.319916662578482e-02
    ## 31 1.350014113631245e-152 3.723579677257819e-152 4.275742011571260e-02
    ## 40 8.327220241486835e-152 4.469357772830585e-152 4.274027107925282e-02
    ## 24 9.023662207309958e-152 4.504758142268724e-152 4.273951988005364e-02
    ## 41 1.098480009038593e-151 5.345891573752782e-152 4.272485755347699e-02
    ## 8  1.161779953089839e-151 2.519331950596270e-151 4.239773498555610e-02
    ## 13 1.301903904108109e-150 4.649793050510479e-151 4.236640033679695e-02
    ## 52 2.595530041046296e-150 4.832015517347953e-151 4.236505600641693e-02
    ## 5  1.734537469963144e-149 6.816758310568945e-151 4.236286496443487e-02
    ## 28 2.111509376026154e-149 5.397540503578288e-150 4.232009898023159e-02
    ## 34 3.494096596133841e-149 9.912849316165396e-150 4.229535425120023e-02
    ## 12 1.943742528833424e-148 1.012589542615682e-149 4.229514437411541e-02
    ## 35 2.366181558649179e-148 1.518799529702324e-149 4.229104787566118e-02
    ## 45 4.989154078665230e-148 2.540440641246745e-149 4.228712683274238e-02
    ## 49 5.590903127512693e-147 3.637089866351790e-149 4.228675124109982e-02
    ## 38 7.242693312557043e-129 1.435501326276531e-126 4.334839807493274e-03
    ## 51 1.711330922378901e-127 4.545359798564982e-126 8.551800650073993e-04
    ## 56 2.775999828995951e-125 7.092892052958021e-125 3.972794149108561e-04
    ## 50 1.030339238094330e-123 7.403877900186866e-125 3.967014645527289e-04
    ## 42 1.447404341921062e-123 1.856174706779201e-124 3.819402686127127e-04
    ## 18 1.715162569355371e-123 3.116225838758434e-123 5.476335859344594e-05
    ## 55 4.144567744690990e-123 3.182609399489450e-123 5.169637500268554e-05
    ## 32 2.782215255371037e-121 6.573986733095250e-122 8.642015990156793e-06
    ## 36 3.117782238713496e-120 1.328900315716293e-121 4.517894484967755e-06
    ## 48 6.573923254455440e-120 2.684135695999165e-121 5.704116273763660e-07
    ## 16 1.032646153825681e-119 2.713441779679970e-121 5.160695289996298e-07
    ## 54 1.194796015557211e-117 3.491462510004099e-120 0.000000000000000e+00
    ## 58  9.999999999999627e-01  5.000000000000000e-01 0.000000000000000e+00
    ## 57  1.000000000000000e+00  1.000000000000000e+00 0.000000000000000e+00

where the first seven columns are indicators for the matching pattern for that field. `0` indicates no match on that field, `1` indicates a partial match, `2` indicates a complete match, and `NA` indicates an NA. Other columns are:

-   `counts`: Tallies the number of pairwise comparisons between `dfA` and `dfB` that fall in each pattern

-   `weights`: The Fellegi-Sunter weight for each matching pattern

-   `p.gamma.j.m`: Probability of being in the matched set given that matching pattern

-   `p.gamma.j.u`: Probability of being in the unmatched set given that matching pattern

-   `zeta.j`: Posterior probability of a particular pattern representing a true match

Lastly, we can summarize the accuracy of the match using the `summary()` function:

``` r
summary(matches.out)
```

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

where each column gives the match rate, false discovery rate (FDR) and false negative rate (FNR) under different cutoffs for matches based on the posterior probability of a match. Other arguments include:

-   `thresholds`: A vector of thresholds between 0 and 1 to summarize the match.

-   `weighted`: Whether to weight the FDR and FNR calculations when doing across-state matches, so that the pooled FDR and FNR calculations are the sum of the within and across-geography FDR and FNR. Default is TRUE.

-   `digits`: Number of digits to include in the summary object. Default is 3.

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

Lastly, we can summarize the match as done earlier by feeding the output from `emlinkMARmov()` into the `summary()` function:

``` r
summary(em.out)
```

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

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

Aggregating Multiple Matches Together
-------------------------------------

Often, we run several different matches for a single data set - for instance, when blocking by gender or by some other criterion to reduce the number of pairwise comparisons. Here, we walk through how to aggregate those multiple matches into a single summary. First, we use the `clusterWordEmbed()` function to partition the two datasets into two maximally similar groups:

``` r
cl.out <- clusterWordEmbed(dfA$firstname, dfB$firstname, nclusters = 2)
dfA$cluster <- cl.out$clusterA
dfB$cluster <- cl.out$clusterB
```

and then run `fastLink()` on both subsets:

``` r
link.1 <- fastLink(
  dfA = subset(dfA, cluster == 1), dfB = subset(dfB, cluster == 1), 
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

``` r
link.2 <- fastLink(
  dfA = subset(dfA, cluster == 2), dfB = subset(dfB, cluster == 2), 
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

To aggregate the two matches into a single summary, we use the `aggregateEM()` function as follows:

``` r
agg.out <- aggregateEM(em.list = list(link.1, link.2))
```

`aggregateEM()` accepts two arguments:

-   `em.list`: A list of either `fastLink` or `fastLink.EM` objects to be aggregated together.

-   `within.geo`: A vector of booleans the same length of `em.list`, to be used if the user wants to aggregate together within-geography matches (for instance, CA 2015 voter file to CA 2016 voter file) and across-geography matches (for instance, CA 2015 voter file to NY 2016 voter file). For entry `i` in `em.list`, `within.geo = TRUE` if it is a within-geography match, and `FALSE` if an across-geogpraphy match. Default is `NULL` (assumes all matches are within-geography).

We can then summarize the aggregated output as done previously:

``` r
summary(agg.out)
```

    ##                  95%     85%     75%   Exact
    ## 1 Match Rate 14.286% 14.286% 14.286% 12.286%
    ## 2        FDR      0%      0%      0%        
    ## 3        FNR      0%      0%      0%

If we assume that the first `fastLink` run was for a within-geography match and the second was an across-geography match, the call to `aggregateEM()` would be:

``` r
agg.out <- aggregateEM(em.list = list(link.1, link.2), within.geo = c(TRUE, FALSE))
summary(agg.out)
```

    ##                               95%     85%     75%   Exact
    ## 1 Match Rate          All 37.037% 37.037% 37.037%  29.63%
    ## 2            Within-State 18.519% 18.519% 18.519% 14.815%
    ## 3            Across-State 18.519% 18.519% 18.519% 14.815%
    ## 4        FDR          All      0%      0%      0%        
    ## 5            Within-State      0%      0%      0%        
    ## 6            Across-State      0%      0%      0%        
    ## 7        FNR          All      0%      0%      0%        
    ## 8            Within-State      0%      0%      0%        
    ## 9            Across-State      0%      0%      0%
