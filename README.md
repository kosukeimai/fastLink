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

#### Running the algorithm piece-by-piece
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

Once we have run the gamma calculations, we then use the
`tableCounts()` function to count the number of unique matching
patterns in our data. This is the only input necessary for the EM
algorithm. We run `tableCounts()` as follows:
```
gammalist <- list(g_firstname, g_lastname, g_streetname, g_age)
tc <- tableCounts(gammalist, nr1 = nrow(dfA), nr2 = nrow(dfB))
```
As with the functions above, `tableCounts()` also includes an `n.cores
argument. If left unspecified, the function will automatically
determine the number of available cores for parallelization.



