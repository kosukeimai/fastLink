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

#### Using the wrapper

