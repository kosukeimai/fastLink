fastLink: Fast Probabilistic Record Linkage [![Build Status](https://travis-ci.com/kosukeimai/fastLink.svg?token=JxpGcfuMTdnnLSenfvSD&branch=master)](https://travis-ci.com/kosukeimai/fastLink)
================================================================================================================================================================================================

Installation Instructions
-------------------------

As `fastLink` is hosted on a private Github repo, you will need a Github personal access token (PAT) to install using `devtools`. Instructions for setting up your own PAT can be found at <https://github.com/settings/tokens>.

Once you have a PAT, `fastLink` can be installed from the private repo using `devtools` as follows:

``` {.r}
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

``` {.r}
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

``` {.r}
dfA.match <- dfA[matches.out$matches[,1],]
dfB.match <- dfB[matches.out$matches[,2],]
```

We can also examine the EM object:

``` {.r}
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
    ## 10       0      NA       1       0       0       0       0      3
    ## 3        2       0       0       0       0       0       0   1181
    ## 11       0       0       2       0       0       0       0     65
    ## 27       1       0       0       0       0       2       0      9
    ## 44       1       0       0       0       0       0       2      2
    ## 39       0       0       0       0       1       2       0      4
    ## 33       0       0       1       0       0       2       0      3
    ## 21       2       0       0       0       1       0       0      3
    ## 17       0      NA       0      NA       0       0       0    323
    ## 30       0      NA       0       0       0       2       0   6701
    ## 47       0      NA       0       0       0       0       2    593
    ## 15       0      NA       0       2       0       0       0      8
    ## 29       0       2       0       0       0       2       0     75
    ## 46       0       2       0       0       0       0       2     10
    ## 25       0      NA       0       0       2       0       0     27
    ## 53       0       0       0       0       0       2       2    150
    ## 37       0       0       0       2       0       2       0      4
    ## 8        2      NA       0       0       0       0       0    559
    ## 13       0      NA       2       0       0       0       0     36
    ## 31       1      NA       0       0       0       2       0      3
    ## 24       0       2       0       0       2       0       0      1
    ## 40       0      NA       0       0       1       2       0      3
    ## 41       0       0       0       0       2       2       0      3
    ## 52       0       0       0       0       2       0       2      1
    ## 5        2       2       0       0       0       0       0      9
    ## 12       0       2       2       0       0       0       0      1
    ## 34       0      NA       1       0       0       2       0      1
    ## 28       2       0       0       0       0       2       0    153
    ## 45       2       0       0       0       0       0       2     19
    ## 35       0       0       2       0       0       2       0      8
    ## 49       0       0       2       0       0       0       2      1
    ## 38       0      NA       0      NA       0       2       0     20
    ## 51       0      NA       0      NA       0       0       2      3
    ## 56       0      NA       0       0       0       2       2     92
    ## 50       0      NA       0       2       0       0       2      1
    ## 18       2      NA       0      NA       0       0       0      4
    ## 55       0       2       0       0       0       2       2      3
    ## 42       0      NA       0       0       2       2       0      4
    ## 32       2      NA       0       0       0       2       0     74
    ## 48       2      NA       0       0       0       0       2      5
    ## 36       0      NA       2       0       0       2       0      3
    ## 16       2      NA       0       2       0       0       0      1
    ## 54       2       0       0       0       0       2       2      3
    ## 58       2      NA       2       2       2       2       2      7
    ## 57       2       2       2       2       2       2       2     43
    ##                weights            p.gamma.j.m           p.gamma.j.u
    ## 1  -445.30885272958380 1.152812702658263e-194 2.863757478838720e-01
    ## 2  -433.42675451731276 1.941333072445265e-191 3.333863768687974e-03
    ## 19 -430.38963562493473 1.570979889657653e-191 1.294238890798554e-04
    ## 9  -427.35096106907247 4.732528044653391e-190 1.867486300460568e-04
    ## 20 -418.50753741266357 2.645525338944033e-188 1.506697469301733e-06
    ## 6  -387.41754925399476 1.608981533182389e-169 2.883068048486992e-01
    ## 4  -382.41159154944967 1.608981533182389e-169 1.931056964827189e-03
    ## 26 -379.29400516955803 7.094950884736690e-167 3.769145106752195e-02
    ## 43 -379.12169846118962 7.728307090937841e-168 3.455779167934082e-03
    ## 14 -378.58225495747450 1.824642809733329e-169 4.757317474627726e-05
    ## 7  -375.53545104172366 2.709519990643945e-166 3.356344306575284e-03
    ## 22 -372.49833214934569 2.192617782256837e-166 1.302966057965099e-04
    ## 23 -372.21491061540945 2.488940444437106e-166 1.114028412332929e-04
    ## 10 -369.45965759348343 6.605192857050175e-165 1.880078925547961e-04
    ## 3  -368.23608440351791 3.880541711492251e-164 3.249315259387583e-04
    ## 11 -367.52770262141519 7.548366510534427e-165 3.112477167434274e-05
    ## 27 -367.41190695728693 1.194787563335616e-163 4.387877256779533e-04
    ## 44 -367.23960024891852 1.301444555135098e-164 4.023070055930163e-05
    ## 39 -364.37478806490890 9.668548179880882e-164 1.703417352296152e-05
    ## 33 -361.33611350904670 2.912620060485946e-162 2.457899072571613e-05
    ## 21 -353.31686729886883 5.288155635060845e-161 1.468486842283143e-07
    ## 17 -329.39390857428663 2.546655305536861e-144 2.883546988135652e-01
    ## 30 -321.40270169396905 9.902428144705101e-142 3.794560785152411e-02
    ## 47 -321.23039498560064 1.078640386544006e-142 3.479081792127839e-03
    ## 15 -320.69095148188546 2.546655305536861e-144 4.789396486594202e-05
    ## 29 -316.39674398942390 9.902428144705101e-142 2.541567840021710e-04
    ## 46 -316.22443728105549 1.078640386544006e-142 2.330262419375648e-05
    ## 25 -314.32360713982041 3.473816000687497e-141 1.121540404324386e-04
    ## 53 -313.10685090116385 4.756363206783687e-140 4.548336665057549e-04
    ## 37 -312.56740739744873 1.122970894352083e-141 6.261361170859698e-06
    ## 8  -310.34478092792887 5.416074908038107e-139 3.271225679208135e-04
    ## 13 -309.63639914582615 1.053526066561965e-139 3.133464875913262e-05
    ## 31 -309.52060348169789 1.667565876963501e-138 4.417465100722750e-04
    ## 24 -309.31764943527526 3.473816000687497e-141 7.511991991456039e-07
    ## 40 -306.48348458931991 1.349439977391026e-138 1.714903645973134e-05
    ## 41 -306.20006305538368 1.531810862909075e-138 1.466232657672632e-05
    ## 52 -306.02775634701527 1.668553446827115e-139 1.344330380025045e-06
    ## 5  -305.33882322338371 5.416074908038107e-139 2.191041982055012e-06
    ## 12 -304.63044144128099 1.053526066561965e-139 2.098770847899037e-07
    ## 34 -303.44481003345766 4.065145951022427e-137 2.474472903135143e-05
    ## 28 -302.22123684349214 2.388267650566578e-136 4.276598420332113e-05
    ## 45 -302.04893013512373 2.601464917627282e-137 3.921042918758394e-06
    ## 35 -301.51285506138942 4.645619321225403e-137 4.096498454286010e-06
    ## 49 -301.34054835302095 5.060327171434478e-138 3.755916426362859e-07
    ## 38 -263.37906101426086 1.567331299479468e-116 3.795191143360645e-02
    ## 51 -263.20675430589239 1.707244742408984e-117 3.479659742485983e-03
    ## 56 -255.21554742557481 6.638459610287387e-115 4.579006500964880e-04
    ## 50 -254.50379721349125 1.707244742408984e-117 5.779503581448713e-07
    ## 18 -252.32114024822073 8.572426479289366e-114 3.271769100192702e-04
    ## 55 -250.20958972102969 6.638459610287387e-115 3.066983590733346e-06
    ## 42 -248.30875957979461 2.137949542944651e-113 1.476119594002186e-05
    ## 32 -244.32993336790312 3.333306908570316e-111 4.305435901251417e-05
    ## 48 -244.15762665953466 3.630866490308844e-112 3.947482857522776e-06
    ## 36 -243.62155158580038 6.483894288127708e-112 4.124121505225226e-06
    ## 16 -243.61818315581957 8.572426479289366e-114 5.434209845680946e-08
    ## 54 -236.03408257509795 1.601063709340698e-109 5.160695289252128e-07
    ## 58   39.45891089494345  5.000000000000000e-01 3.649074589734563e-18
    ## 57   44.46486859948860  5.000000000000000e-01 2.444122297210018e-20
    ##                    zeta.j               cumsum.m              cumsum.u
    ## 1  7.708194565308436e-198 1.152812702658263e-194 7.136242521161280e-01
    ## 2  1.115019224577227e-192 1.942485885147923e-191 7.102903883474400e-01
    ## 19 2.324268686038478e-191 3.513465774805576e-191 7.101609644583602e-01
    ## 9  4.852504234914044e-190 5.083874622133948e-190 7.099742158283140e-01
    ## 20 3.362141738974576e-186 2.696364085165372e-188 7.099727091308448e-01
    ## 6  1.068627430707408e-172 1.608981533182389e-169 4.216659042821456e-01
    ## 4  1.595460754046174e-170 3.217963066364778e-169 4.197348473173184e-01
    ## 26 3.604430760259890e-169 7.127130515400337e-167 3.820433962497963e-01
    ## 43 4.282215705313698e-169 7.899961224494122e-167 3.785876170818623e-01
    ## 14 7.344223365235670e-169 7.918207652591455e-167 3.785400439071160e-01
    ## 7  1.545809617354564e-167 3.501340755903090e-166 3.751836996005408e-01
    ## 22 3.222255553088255e-166 5.693958538159927e-166 3.750534029947442e-01
    ## 23 4.278074950936991e-166 8.182898982597033e-166 3.749420001535110e-01
    ## 10 6.727281063183073e-165 7.423482755309879e-165 3.747539922609562e-01
    ## 3  2.286813025857163e-164 4.622889987023239e-164 3.744290607350174e-01
    ## 11 4.643836881275276e-164 5.377726638076682e-164 3.743979359633430e-01
    ## 27 5.213944143853741e-164 1.732560227143285e-163 3.739591482376651e-01
    ## 44 6.194385461805630e-164 1.862704682656794e-163 3.739189175371058e-01
    ## 39 1.086851853061804e-162 2.829559500644882e-163 3.739018833635829e-01
    ## 33 2.269080701119497e-161 3.195576010550434e-162 3.738773043728572e-01
    ## 21 6.895477094917265e-158 5.607713236115889e-161 3.738771575241728e-01
    ## 17 1.691115558288496e-147 2.546655305536861e-144 8.552245871060771e-02
    ## 30 4.997011362212457e-144 9.927894697760470e-142 4.757685085908359e-02
    ## 47 5.936660171370727e-144 1.100653508430448e-141 4.409776906695573e-02
    ## 15 1.018168194748866e-143 1.103200163735984e-141 4.404987510208980e-02
    ## 29 7.460537963783262e-142 2.093442978206494e-141 4.379571831808760e-02
    ## 46 8.863433635856068e-142 2.201307016860895e-141 4.377241569389390e-02
    ## 25 5.930919626456764e-141 5.675123017548392e-141 4.366026165346149e-02
    ## 53 2.002407941253501e-140 5.323875508538527e-140 4.320542798695570e-02
    ## 37 3.434234097698286e-140 5.436172597973735e-140 4.319916662578482e-02
    ## 8  3.170328807381615e-139 5.959692167835481e-139 4.287204405786404e-02
    ## 13 6.437994569306685e-139 7.013218234397446e-139 4.284070940910489e-02
    ## 31 7.228364161141812e-139 2.368887700403246e-138 4.239896289903256e-02
    ## 24 8.854863002300024e-139 2.372361516403933e-138 4.239821169983349e-02
    ## 40 1.506759713259193e-137 3.721801493794960e-138 4.238106266337371e-02
    ## 41 2.000471682078978e-137 5.253612356704034e-138 4.236640033679695e-02
    ## 52 2.376644697820814e-137 5.420467701386746e-138 4.236505600641693e-02
    ## 5  4.733300909420792e-137 5.962075192190556e-138 4.236286496443487e-02
    ## 12 9.611925891974962e-137 6.067427798846753e-138 4.236265508735015e-02
    ## 34 3.145745555798728e-136 4.671888730907102e-137 4.233791035831880e-02
    ## 28 1.069337202573938e-135 2.855456523657289e-136 4.229514437411541e-02
    ## 45 1.270417679713777e-135 3.115603015420017e-136 4.229122333119673e-02
    ## 35 2.171505708461342e-135 3.580164947542557e-136 4.228712683274238e-02
    ## 49 2.579840331925688e-135 3.630768219256902e-136 4.228675124109982e-02
    ## 38 7.907829629629005e-119 1.567331299479468e-116 4.334839807493274e-03
    ## 51 9.394834992614099e-119 1.738055773720367e-116 8.551800650073993e-04
    ## 56 2.776043125740971e-115 6.812265187659424e-115 3.972794149108561e-04
    ## 50 5.656338585208022e-115 6.829337635083514e-115 3.967014645527289e-04
    ## 18 5.017082864421828e-114 9.255360242797717e-114 6.952455453346218e-05
    ## 55 4.144632386731305e-113 9.919206203826456e-114 6.645757094270177e-05
    ## 42 2.773358788119234e-112 3.129870163327297e-113 5.169637500268554e-05
    ## 32 1.482478234902568e-110 3.364605610203589e-111 8.642015990156793e-06
    ## 48 1.761246644068690e-110 3.727692259234473e-111 4.694533132676426e-06
    ## 36 3.010472227106607e-110 4.376081688047244e-111 5.704116273763660e-07
    ## 16 3.020629890096725e-110 4.384654114526534e-111 5.160695289996298e-07
    ## 54 5.940603242875243e-107 1.644910250485964e-109 0.000000000000000e+00
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

``` {.r}
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

``` {.r}
gammalist <- list(g_firstname, g_middlename, g_lastname, g_housenum, g_streetname, g_city, g_birthyear)
tc <- tableCounts(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB))
```

    ## Parallelizing gamma calculation using 1 cores.

As with the functions above, `tableCounts()` also includes an `n.cores` argument. If left unspecified, the function will automatically determine the number of available cores for parallelization.

#### 3) Running the EM algorithm

We next run the EM algorithm to calculate the Fellegi-Sunter weights. The only required input to this function is the output from `tableCounts()`, as follows:

``` {.r}
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

``` {.r}
matches.out <- matchesLink(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB),
                           em = em.out, cut = match.ut)
```

    ## Parallelizing gamma calculation using 1 cores.

As with the other functions above, `matchesLink()` accepts an `n.cores` argument. This returns a matrix where each row is a match with the relevant indices of `dfA` (column 1) and `dfB` (column 2).

The datasets can then be subsetted down to the matches as follows:

``` {.r}
dfA.match <- dfA[matches.out[,1],]
dfB.match <- dfB[matches.out[,2],]
```

Using Auxiliary Information to Inform `fastLink`
------------------------------------------------

The `fastLink` algorithm also includes several ways to incorporate auxiliary information on migration behavior to inform the matching of data sets over time. Auxiliary information is incorporated into the estimation as priors on two parameters of the model:

-   \[\gamma\]: The probability that a randomly selected pair of observations from dataset A and dataset B are a true match. When matching, for example, the same state to itself in subsequent years, the prior for this quantity is equal to the number of non-movers to the number of in-state movers, divided by the size of the cross-product of A and B. When matching two different states in subsequent years to find movers, the numerator is the size of the outflow from state A to state B, divided by the size of the cross-product of A and B.

-   \[\pi_{k,l}\]: The probability that an address field does not match conditional on being in the matched set. Specified when trying to find movers within the same geography over time. For example, when trying to find movers within the same state over time, this quantity is equal to the estimated number of in-state movers divided by the number of in-state movers and non-movers.

The functions `calcMoversPriors()` and `precalcPriors()` can be used to find optimal parameter values for the corresponding prior distributions. `calcMoversPriors()` uses the IRS Statistics of Income Migration Data to estimate these parameters, while `precalcPriors()` accomodates any additional auxiliary information if the prior means are already known.

Below, we show an example where we incorporate the auxiliary moving information for California into our estimates. First, we use `calcMoversPriors()` to estimate optimal parameter values for the priors:

``` {.r}
priors.out <- calcMoversPriors(geo.a = "CA", geo.b = "CA", year.start = 2014, year.end = 2015, 
                               var.prior.gamma = 0.0001, var.prior.pi = 0.1, L = 3)
```

    ## Your provided variance for gamma is too large given the observed mean. The function will adaptively choose a new prior variance.
    ## Your provided variance for pi is too large given the observed mean. The function will adaptively choose a new prior variance.

``` {.r}
names(priors.out)
```

    ## [1] "gamma_prior"      "pi_prior"         "parameter_values"

where each entry in the list outputs the optimal parameter values for the prior distributions, estimated from the IRS data.

If the provided variances are too large (forcing the parameter values for the \[\gamma\] prior or the \[\pi_{k,l}\] prior below 1), the function will choose new parameter values by testing the sequence \[1/(10^i)\] to find new variance values that satisfy those restrictions. The means and variances used to calculate optimal paramter values can be viewed in the `parameter_values` field of the `calcMoversPriors()` and `precalcPriors()` output.

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

``` {.r}
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

``` {.r}
em.out.aux <- emlinkMARmov(tc, 
                           psi = priors.out$gamma_prior$psi, mu = priors.out$gamma_prior$mu,
                           alpha0 = priors.out$pi_prior$alpha_0, alpha1 = priors.out$pi_prior$alpha_1,
                           address_field = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE))
```

All other steps are the same. The newly specified arguments include the optimal parameter values (`psi`, `mu`, `alpha0`, `alpha1`) and a vector of boolean indicators where an address field is set to TRUE (`address_field`).
