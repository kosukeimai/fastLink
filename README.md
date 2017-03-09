# fastLink: Fast Probabilistic Record Linkage

## Installation Instructions
As `fastLink` is hosted on a private Github repo, you will need a
Github personal access token (PAT) to install using
`devtools`. Instructions for setting up your own PAT can be found at
<https://github.com/settings/tokens>.

Once you have a PAT, `fastLink` can be installed from the private repo using `devtools` as
follows:
```
library(devtools)
install_github("kosukeimai/fastLink", auth_token = "[YOUR PAT HERE]")
```

## Simple usage example
The linkage algorithm can be run either using the `fastLink()`
wrapper, which runs the algorithm from start to finish, or
piece-by-piece. We will outline the workflow from start to finish
using both examples. In both examples, we will assume we have two dataframes
called `dfA` and `dfB` that we want to merge together, and that they
have four commonly named fields:
- `firstname`
- `lastname`
- `streetname`
- `age`

### Running the algorithm step-by-step
#### 1) Agreement calculation variable-by-variable
The first step for running the `fastLink` algorithm is to determine
which observations agree, partially agree, disagree, and are missing
on which variables. All functions provide the indices of the NA's. There are three separate
`gammapar` functions to calculate this agreement variable-by-variable:
- `gammaKpar()`: Binary agree-disagree on non-string variables.
- `gammaCKpar()`: Agree-partial agree-disagree on string variables
  (using Jaro-Winkler distance to measure agreement).
- `gammaCK2par()`: Binary agree-disagree on string variables (using
Jaro-Winkler distance to measure agreement).

For instance, if we wanted to include partial matches on `firstname`
and `lastname` but only do exact matches on `streetname`, we would
run:
```
g_firstname <- gammaCKpar(dfA$firstname, dfB$firstname)
g_lastname <- gammaCKpar(dfA$lastname, dfB$lastname)
g_streetname <- gammaCK2par(dfA$streetname, dfB$streetname)
g_age <- gammaKpar(dfA$age, dfB$age)
```
All functions include an `n.cores` argument where you can prespecify
the number of registered cores to be used. If you do not specify
this, the function will automatically detect the number of available
cores and wil parallelize over those. In addition, for `gammaCKpar()`
and `gammaCK2par()`, the user can specify the lower bound for an
agreement using `cut.a`. For both functions, the default is 0.92. For
`gammaCKpar()`, the user can also specify the lower bound for a
partial agreement using `cut.p` - here, the default is 0.88.

#### 2) Counting unique agreement patterns
Once we have run the gamma calculations, we then use the
`tableCounts()` function to count the number of unique matching
patterns in our data. This is the only input necessary for the EM
algorithm. We run `tableCounts()` as follows:
```
gammalist <- list(g_firstname, g_lastname, g_streetname, g_age)
tc <- tableCounts(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB))
```
As with the functions above, `tableCounts()` also includes an `n.cores`
argument. If left unspecified, the function will automatically
determine the number of available cores for parallelization.

#### 3) Running the EM algorithm
We next run the EM algorithm to calculate the Felligi-Sunter
weights. The only required input to this function is the output from
`tableCounts()`, as follows:
```
## Run EM algorithm
em.out <- emlinkMAR(tc)

## Postprocessing of EM algorithm
EM <- data.frame(em.out$patterns.w)
EM$zeta.j <- em.out$zeta.j
EM <- EM[order(EM[, "weights"]), ] 
match.ut <- EM$weights[ EM$zeta.j >= 0.85 ][1]
```
The code following `emlinkMAR()` sorts the linkage patterns by the
Felligi-Sunter weight, and then selects the lowest weight that is
still classified as a positive match according to the posterior
probability that a linkage pattern is in the matched set. In this
case, we've chosen that probability to be 0.85.

As with the other functions above, `emlinkMAR()` accepts an `n.cores`
argument. Other optional arguments include:
- `p.m`: Starting values for the probability of being in the matched
set
- `p.gamma.k.m`: Starting values for the probability that conditional
on being in the matched set, we observed a specific agreement value
for field k. A vector with length equal to the number of linkage
fields
- `p.gamma.k.u`: Starting values for the probability that conditional
on being in the unmatched set, we observed a specific agreement value
for field k. A vector with length equal to the number of linkage
fields
- `tol`: Convergence tolerance for the EM algorithm
- `iter.max`: Maximum number of iterations for the EM algorithm

#### 4) Finding the matches
Once we've run the EM algorithm and selected our lower bound for
accepting a match, we then run `matchesLink()` to get the paired
indices of `dfA` and `dfB` that match. We run the function as follows:
```
matches.out <- matchesLink(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB),
                                               em = em.out, cut = match.ut)
```
As with the other functions above, `matchesLink()` accepts an `n.cores`
argument. This returns a matrix where each row is a match with the relevant indices of
`dfA` (column 1) and `dfB` (column 2).

The datasets can then be subsetted down to the matches as follows:
```
dfA.match <- dfA[matches.out[,1],]
dfB.match <- dfB[matches.out[,2],]
```

### Running the algorithm using the `fastLink()` wrapper
`fastLink` also includes a wrapper to automate running the four steps
above. Running the code below would return equivalent results to the
step-by-step process above:
```
matches.out <- fastLink(dfA, dfB, varnames = c("firstname", "lastname", "streetname", "age"),
                                        stringdist_match = c(TRUE, TRUE, TRUE, FALSE),
                                        partial_match = c(TRUE, TRUE, FALSE, FALSE))
```
- `varnames` should be a vector of variable names to be used for
matching. These variable names should exist in both `dfA` and `dfB`
- `stringdist_match` should be a vector of booleans of the same length
  as `varnames`. `TRUE` means that string-distance matching using the
  Jaro-Winkler similarity will be used.
- `partial_match` is another vector of booleans of the same length as
  `varnames`. A `TRUE` for an entry in `partial_match` and a `TRUE`
  for that same entry for `stringdist_match` means that a partial
  match category will be included in the gamma calculation.

Other arguments that can be provided include:
- `n.cores`
- `tol.em`: Convergence tolerance for the EM algorithm. Default is 1e-04
- `match`: Lower bound for the posterior probability of a match that
will be accepted. Default is 0.85.
- `verbose`: Whether to print out runtime for each step and EM
output. Default is FALSE.

The output from `fastLink()` will be a list of length 2 with two
entries:
- `matches`: A matrix where each row is a match with the relevant
indices of `dfA` (column 1) and `dfB` (column 2).
- `EM`: The output from `emlinkMAR()`

