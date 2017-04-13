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
    ## 14       0       0       0       2       0       0       0     15
    ## 43       0       0       0       0       0       0       2   1203
    ## 7        1      NA       0       0       0       0       0     48
    ## 22       0      NA       0       0       1       0       0     17
    ## 23       0       0       0       0       2       0       0     43
    ## 10       0      NA       1       0       0       0       0      3
    ## 27       1       0       0       0       0       2       0      9
    ## 11       0       0       2       0       0       0       0     65
    ## 3        2       0       0       0       0       0       0   1181
    ## 39       0       0       0       0       1       2       0      4
    ## 44       1       0       0       0       0       0       2      2
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 15       0      NA       0       2       0       0       0      8
    ## 47       0      NA       0       0       0       0       2    593
    ## 29       0       2       0       0       0       2       0     75
    ## 37       0       0       0       2       0       2       0      4
    ## 46       0       2       0       0       0       0       2     10
    ## 53       0       0       0       0       0       2       2    150
    ## 25       0      NA       0       0       2       0       0     27
    ## 31       1      NA       0       0       0       2       0      3
    ## 13       0      NA       2       0       0       0       0     36
    ## 8        2      NA       0       0       0       0       0    559
    ## 24       0       2       0       0       2       0       0      1
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 34       0      NA       1       0       0       2       0      1
    ## 12       0       2       2       0       0       0       0      1
    ## 52       0       0       0       0       2       0       2      1
    ## 35       0       0       2       0       0       2       0      8
    ## 5        2       2       0       0       0       0       0      9
    ## 28       2       0       0       0       0       2       0    153
    ## 49       0       0       2       0       0       0       2      1
    ## 45       2       0       0       0       0       0       2     19
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 50       0      NA       0       2       0       0       2      1
    ## 55       0       2       0       0       0       2       2      3
    ## 18       2      NA       0      NA       0       0       0      4
    ## 42       0      NA       0       0       2       2       0      4
    ## 36       0      NA       2       0       0       2       0      3
    ## 32       2      NA       0       0       0       2       0     74
    ## 16       2      NA       0       2       0       0       0      1
    ## 48       2      NA       0       0       0       0       2      5
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -491.36249215069643 1.150581219973451e-214 2.863757478838720e-01
    ## 2  -477.30726972175125 1.702293484374490e-210 3.333863768687974e-03
    ## 19 -474.63264344055153 9.586861836785409e-211 1.294238890798554e-04
    ## 9  -472.13231040659571 1.685777630992151e-209 1.867486300460568e-04
    ## 20 -460.57742101160636 1.418383348959397e-206 1.506697469301733e-06
    ## 6  -427.57613090701369 5.833116450270452e-187 2.883068048486992e-01
    ## 4  -422.57017320246860 5.833116450270452e-187 1.931056964827189e-03
    ## 26 -421.85812815511207 2.320521805168017e-185 3.769145106752195e-02
    ## 14 -418.75034220251661 6.552382185928990e-187 4.757317474627726e-05
    ## 43 -417.91384407282885 1.098675880615392e-184 3.455779167934082e-03
    ## 7  -413.52090847806858 8.630139232692846e-183 3.356344306575284e-03
    ## 22 -410.84628219686880 4.860263709841649e-183 1.302966057965099e-04
    ## 23 -410.57319089031330 5.460407395795988e-183 1.114028412332929e-04
    ## 10 -408.34594916291303 8.546408597790775e-182 1.880078925547961e-04
    ## 27 -407.80290572616690 3.433229293780206e-181 4.387877256779533e-04
    ## 11 -406.42693157038804 9.641231173470459e-182 3.112477167434274e-05
    ## 3  -405.61747421106247 2.261314860107293e-180 3.249315259387583e-04
    ## 39 -405.12827944496712 1.933502959131122e-181 1.703417352296152e-05
    ## 44 -403.85862164388374 1.625499148207926e-180 4.023070055930163e-05
    ## 33 -402.62794641101141 3.399919695779328e-180 2.457899072571613e-05
    ## 21 -388.88762550091764 1.884170604993651e-176 1.468486842283143e-07
    ## 17 -363.66693805123504 3.321869647592836e-159 2.883546988135652e-01
    ## 30 -358.07176691142934 1.176437932408559e-157 3.794560785152411e-02
    ## 15 -354.96398095883387 3.321869647592836e-159 4.789396486594202e-05
    ## 47 -354.12748282914617 5.569971281889073e-157 3.479081792127839e-03
    ## 29 -353.06580920688418 1.176437932408559e-157 2.541567840021710e-04
    ## 37 -349.24597820693225 1.321501296413784e-157 6.261361170859698e-06
    ## 46 -349.12152512460102 5.569971281889073e-157 2.330262419375648e-05
    ## 53 -348.40948007724450 2.215837781394535e-155 4.548336665057549e-04
    ## 25 -346.78682964663057 2.768269779888372e-155 1.121540404324386e-04
    ## 31 -344.01654448248416 1.740548683000564e-153 4.417465100722750e-04
    ## 13 -342.64057032670530 4.887827402582537e-154 3.133464875913262e-05
    ## 8  -341.83111296737980 1.146421711110188e-152 3.271225679208135e-04
    ## 24 -341.78087194208541 2.768269779888372e-155 7.511991991456039e-07
    ## 40 -341.34191820128444 9.802304888840946e-154 1.714903645973134e-05
    ## 41 -341.06882689472889 1.101269011442553e-153 1.466232657672632e-05
    ## 34 -338.84158516732867 1.723661673141729e-152 2.474472903135143e-05
    ## 12 -337.63461262216015 4.887827402582537e-154 2.098770847899037e-07
    ## 52 -337.12454281244572 5.214075981731549e-153 1.344330380025045e-06
    ## 35 -336.92256757480368 1.944468306828444e-152 4.096498454286010e-06
    ## 5  -336.82515526283464 1.146421711110188e-152 2.191041982055012e-06
    ## 28 -336.11311021547817 4.560677986166171e-151 4.276598420332113e-05
    ## 49 -332.97828349252046 9.206293276691619e-152 3.755916426362859e-07
    ## 45 -332.16882613319495 2.159301796473123e-150 3.921042918758394e-06
    ## 38 -294.16257405565074 6.699632166204138e-130 3.795191143360645e-02
    ## 51 -290.21828997336752 3.172012542011252e-129 3.479659742485983e-03
    ## 56 -284.62311883356182 1.123366137862110e-127 4.579006500964880e-04
    ## 50 -281.51533288096641 3.172012542011252e-129 5.779503581448713e-07
    ## 55 -279.61716112901667 1.123366137862110e-127 3.066983590733346e-06
    ## 18 -277.92192011160114 6.528694425947572e-125 3.271769100192702e-04
    ## 42 -277.28246565104621 5.583117710687871e-126 1.476119594002186e-05
    ## 36 -273.13620633112095 9.857896053485246e-125 4.124121505225226e-06
    ## 32 -272.32674897179544 2.312132800681906e-123 4.305435901251417e-05
    ## 16 -269.21896301919998 6.528694425947572e-125 5.434209845680946e-08
    ## 48 -268.38246488951222 1.094704016670508e-122 3.947482857522776e-06
    ## 54 -262.66446213761060 4.354935414963551e-121 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  7.693273925846378e-218 1.150581219973451e-214 7.136242521161280e-01
    ## 2  9.777250425962782e-212 1.702408542496488e-210 7.102903883474400e-01
    ## 19 1.418378612693344e-210 2.661094726175028e-210 7.101609644583602e-01
    ## 9  1.728514446471050e-209 1.951887103609653e-209 7.099742158283140e-01
    ## 20 1.802593151992417e-204 1.420335236063007e-206 7.099727091308448e-01
    ## 6  3.874145300437720e-190 5.833116450270452e-187 4.216659042821456e-01
    ## 4  5.784098933553565e-188 1.166623290054090e-186 4.197348473173184e-01
    ## 26 1.178889087505194e-187 2.437184134173426e-185 3.820433962497963e-01
    ## 14 2.637346777744774e-186 2.502707956032716e-185 3.819958230750501e-01
    ## 43 6.087707250320536e-186 1.348946676218664e-184 3.785400439071160e-01
    ## 7  4.923585089267055e-184 8.765033900314712e-183 3.751836996005408e-01
    ## 22 7.142609101888645e-183 1.362529761015636e-182 3.750534029947442e-01
    ## 23 9.385532769205717e-183 1.908570500595235e-182 3.749420001535110e-01
    ## 10 8.704377595390800e-182 1.045497909838601e-181 3.747539922609562e-01
    ## 27 1.498230005076150e-181 4.478727203618807e-181 3.743152045352782e-01
    ## 11 5.931389902938501e-181 5.442850320965852e-181 3.742840797636039e-01
    ## 3  1.332598555078836e-180 2.805599892203878e-180 3.739591482376651e-01
    ## 39 2.173471378469183e-180 2.998950188116990e-180 3.739421140641421e-01
    ## 44 7.736763162216606e-180 4.624449336324916e-180 3.739018833635829e-01
    ## 33 2.648712158413760e-179 8.024369032104243e-180 3.738773043728572e-01
    ## 21 2.456859469776297e-173 1.884973041896861e-176 3.738771575241728e-01
    ## 17 2.205899413020997e-162 3.321869647592836e-159 8.552245871060771e-02
    ## 30 5.936598205286313e-160 1.209656628884487e-157 4.757685085908359e-02
    ## 15 1.328103577632640e-158 1.242875325360415e-157 4.752895689421766e-02
    ## 47 3.065621042692206e-158 6.812846607249488e-157 4.404987510208980e-02
    ## 29 8.863341120492543e-158 7.989284539658047e-157 4.379571831808760e-02
    ## 37 4.041373498745203e-156 9.310785836071831e-157 4.378945695691672e-02
    ## 46 4.576972216739243e-156 1.488075711796090e-156 4.376615433272302e-02
    ## 53 9.328579372714303e-156 2.364645352574144e-155 4.331132066621723e-02
    ## 25 4.726325621626984e-155 5.132915132462516e-155 4.319916662578482e-02
    ## 31 7.544721257929186e-154 1.791877834325189e-153 4.275742011571260e-02
    ## 13 2.986903435263406e-153 2.280660574583442e-153 4.272608546695345e-02
    ## 8  6.710641632275558e-153 1.374487768568533e-152 4.239896289903256e-02
    ## 24 7.056404153089147e-153 1.377256038348421e-152 4.239821169983349e-02
    ## 40 1.094507229002107e-152 1.475279087236831e-152 4.238106266337371e-02
    ## 41 1.438204627664079e-152 1.585405988381086e-152 4.236640033679695e-02
    ## 34 1.333826906417088e-151 3.309067661522815e-152 4.234165560776559e-02
    ## 12 4.459446828848303e-151 3.357945935548640e-152 4.234144573068088e-02
    ## 52 7.426795982820635e-151 3.879353533721795e-152 4.234010140030087e-02
    ## 35 9.089044401266935e-151 5.823821840550238e-152 4.233600490184652e-02
    ## 5  1.001898795698750e-150 6.970243551660427e-152 4.233381385986446e-02
    ## 28 2.042025163473829e-150 5.257702341332214e-151 4.229104787566118e-02
    ## 49 4.693523935926177e-149 6.178331669001376e-151 4.229067228401850e-02
    ## 45 1.054488630421039e-148 2.777134963373260e-150 4.228675124109982e-02
    ## 38 3.380239376902627e-132 6.699632166204138e-130 4.334839807493274e-03
    ## 51 1.745533823384248e-130 3.841975758631665e-129 8.551800650073993e-04
    ## 56 4.697645278837947e-128 1.161785895448426e-127 3.972794149108561e-04
    ## 50 1.050931743320308e-126 1.193506020868539e-127 3.967014645527289e-04
    ## 55 7.013584401305115e-126 2.316872158730649e-127 3.936344809619685e-04
    ## 18 3.820971927913598e-125 6.551863147534878e-125 6.645757094270177e-05
    ## 42 7.242448082621192e-125 7.110174918603665e-125 5.169637500268554e-05
    ## 36 4.577021303549149e-123 1.696807097208891e-124 4.757225349749650e-05
    ## 32 1.028314117851635e-122 2.481813510402795e-123 4.517894484967755e-06
    ## 16 2.300488615909357e-121 2.547100454662271e-123 4.463552386479996e-06
    ## 48 5.310147813905165e-121 1.349414062136735e-122 5.160695289996298e-07
    ## 54 1.615859712371931e-118 4.489876821177225e-121 0.000000000000000e+00
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
matches.out.aux <- fastLink(
  dfA = dfA, dfB = dfB, 
  varnames = c("firstname", "middlename", "lastname", "housenum", "streetname", "city", "birthyear"),
  stringdist.match = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  partial.match = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE),
  priors.obj = priors.out, 
  w.lambda = .01, w.pi = .01, l.address = 3, 
  address.field = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE)
)
```

where `priors.obj` is an input for the the optimal prior parameters. This can be calculated by `calcMoversPriors()`, or can be provided by the user as a list with two entries named `lambda.prior` and `pi.prior`. `w.lambda` and `w.pi` are user-specified weights between 0 and 1 indicating the weighting between the MLE estimate and the prior, where a weight of 0 indicates no weight being placed on the prior. `address_field` is a vector of booleans of the same length as `varnames`, where `TRUE` indicates an address-related field used for matching. `l.address` is an integer indicating the number of matching fields used on the address variable - when a single partial match category is included, `l.address = 3`, while for a binary match/no match category `l.address = 2`.

### Incorporating Auxiliary Information when Running the Algorithm Step-by-Step

If we are running the algorithm step-by-step, we can incorporate the prior information into the EM algorithm as follows:

``` r
em.out.aux <- emlinkMARmov(tc, nobs.a = nrow(dfA), nobs.b = nrow(dfB),
                           prior.lambda = priors.out$lambda.prior, w.lambda = .01,
                           prior.pi = priors.out$pi.prior, w.pi = .01,
                           address.field = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE),
                           l.address = 3)
```

All other steps are the same. The newly specified arguments include the prior estimates of the parameters (`prior.lambda`, `prior.pi`), the weightings of the prior and MLE estimate (`w.lambda`, `w.pi`), the vector of boolean indicators where `TRUE` indicates an address field (`address.field`), and an integer indicating the number of matching categories for the address field (`l.address`).
