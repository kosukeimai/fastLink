context("Tests fastLink() wrapper.")

data(samplematch)
set.seed(738969) ## From random.org, 2018/04/16

## ---------
## Run tests
## ---------
test_that("fastLink() gives correct results on sample data.", {

    ## Run match
    fl_out <- fastLink(
        dfA = dfA, dfB = dfB,
        varnames = c("firstname", "middlename", "lastname", "housenum",
                     "streetname", "city", "birthyear"),
        return.all = TRUE, n.cores = 1
    )

    ## Test class
    expect_is(fl_out, "fastLink", label = "Test class is fastLink.")
    expect_is(fl_out, "confusionTable", label = "Test class is confusionTable.")

    ## Confusion table
    ct_out <- confusion(fl_out)
    
    ## Test output
    expect_equivalent(
        as.vector(round(ct_out$confusion.table, 2)),
        round(c(50.0, 0.3, 0.0, 299.7), 2),
        label = "We get the right baseline results from fastLink()."
    )

})

test_that("fastLink() throws errors when we expect it to.", {

    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname", "not_in_df")
        ), label = "Variable provided not in data frame."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            stringdist.match = "middlename"
        ), label = "Variable for stringdist.match not in varnames."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            numeric.match = "birthyear"
        ), label = "Variable for numeric.match not in varnames."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname", "birthyear"),
            stringdist.match = "birthyear",
            numeric.match = "birthyear"
        ), label = "Variable provided for both stringdist.match and numeric.match."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "middlename", "lastname"),
            partial.match = "middlename"
        ), label = "Variable in partial.match but not in either stringdist.match or numeric.match"
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            address.field = "street_name"
        ), label = "Variable in address.field not present in data frame or varnames."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            address.field = c("streetname", "city")
        ), label = "Multiple variables provided for address.field."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            gender.field = "male"
        ), label = "Variable in gender.field not in data frame."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            gender.field = c("female", "male")
        ), label = "Multiple variables provided for gender.field."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            reweight.names = TRUE
        ), label = "No argument provided for firstname.field when reweight.names = TRUE."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("middlename", "lastname"),
            firstname.field = "firstname", reweight.names = TRUE
        ), label = "Argument for firstname.field not present in varnames."
    )
    expect_error(
        fastLink(
            dfA = dfA, dfB = dfB,
            varnames = c("firstname", "lastname"),
            stringdist.match = "firstname",
            stringdist.method = "jaro-winkler"
        ), label = "Invalid string distance method provided."
    )

})

