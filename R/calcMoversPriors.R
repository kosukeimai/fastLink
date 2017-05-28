#' calcMoversPriors
#'
#' calcMoversPriors calculates prior estimates of in-state and
#' cross-state movers rates from the IRS SOI Migration data,
#' which can be used to improve the accuracy of the EM algorithm.
#'
#' @usage calcMoversPriors(geo.a, geo.b, year.start, year.end,
#' county, state.a, state.b, matchrate.lambda, remove.instate)
#'
#' @param geo.a The state code (if state = TRUE) or county name
#' (if state = FALSE) for the earlier of the two voter files.
#' @param geo.b The state code (if state = TRUE) or county name
#' (if state = FALSE) for the later of the two voter files.
#' @param year.start The year of the voter file for geography A.
#' @param year.end The year of the voter file for geography B.
#' @param county Whether prior is being calculated on the county or state level.
#' Default is FALSE (for a state-level calculation).
#' @param state.a If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo.a}. Default is NULL.
#' @param state.b If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo.b}. Default is NULL.
#' @param matchrate.lambda If TRUE, then returns the match rate for lambda
#' (the expected share of observations in dataset A that can be found in
#' dataset B). If FALSE, then returns the expected share of matches across
#' all pairwise comparisons of datasets A and B. Default is FALSE
#' @param remove.instate If TRUE, then for calculating cross-state movers rates
#' assumes that successful matches have been subsetted out. The interpretation
#' of the prior is then the match rate conditional on being an out-of-state or
#' county mover. Default is TRUE.
#'
#' @return \code{calcMoversPriors} returns a list with estimates of the expected
#' match rate, and of the expected in-state movers rate when matching within-state.
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @examples calcMoversPriors(geo.a = "CA", geo.b = "CA", year.start = 2014, year.end = 2015)
#' 
#' @export
calcMoversPriors <- function(geo.a, geo.b, year.start, year.end,
                             county = FALSE, state.a = NULL, state.b = NULL,
                             matchrate.lambda = FALSE, remove.instate = TRUE){

    ## For visible bindings
    start_year <- NULL; end_year <- NULL; y1_statefips <- NULL; y2_statefips <- NULL
    y1_fips <- NULL; y2_fips <- NULL
    
    ## Load the correct level of IRS data
    if(!county){
        statefips <- get("statefips")
        stateoutflow <- get("stateoutflow")
        stateinflow <- get("stateinflow")
        outfips <- statefips$statefips[statefips$state == geo.a]
        infips <- statefips$statefips[statefips$state == geo.b]
        outf <- subset(
            stateoutflow, start_year >= year.start & end_year <= year.end
            & y1_statefips == outfips
        )
        inf <- subset(
            stateinflow, start_year >= year.start & end_year <= year.end
            & y2_statefips == infips
        )
    }else{
        countyfips <- get("countyfips")
        countyoutflow <- get("countyoutflow")
        countyinflow <- get("countyinflow")
        geo.a <- tolower(geo.a); geo.b <- tolower(geo.b)
        outfips <- countyfips$fips[countyfips$statecode == state.a &
                                   countyfips$countyname == geo.a]
        infips <- countyfips$fips[countyfips$statecode == state.b &
                                  countyfips$countyname == geo.b]
        outf <- subset(
            countyoutflow, start_year >= year.start & end_year <= year.end
            & y1_fips == outfips
        )
        inf <- subset(
            countyinflow, start_year >= year.start & end_year <= year.end
            & y2_fips == infips
        )
    }

    ## Get the N sizes
    inf$n <- inf$n1; outf$n <- outf$n1

    ## Cross-state matching
    if(geo.a != geo.b){
        if(!county){
            b_a <- outf$n[outf$y1_statefips == outfips &
                          outf$y2_statefips == infips]
            if(remove.instate){
                denom_a <- (outf$n[outf$y1_statefips == outfips &
                                   outf$y2_statefips == 96] +
                            outf$n[outf$y1_statefips == outfips &
                                   grepl("Same State", outf$y2_state_name)])
                denom_b <- (inf$n[inf$y2_statefips == infips &
                                  inf$y1_statefips == 96] +
                            inf$n[inf$y2_statefips == infips &
                                  grepl("Same State", inf$y1_state_name)])
            }else{
                denom_a <- (outf$n[outf$y1_statefips == outfips &
                                   outf$y2_statefips == outfips] +
                            outf$n[outf$y1_statefips == outfips &
                                   outf$y2_statefips == 96] +
                            outf$n[outf$y1_statefips == outfips &
                                   grepl("Same State", outf$y2_state_name)])
                denom_b <- (inf$n[inf$y1_statefips == infips &
                                  inf$y2_statefips == infips] +
                            inf$n[inf$y2_statefips == infips &
                                  inf$y1_statefips == 96] +
                            inf$n[inf$y2_statefips == infips &
                                  grepl("Same State", inf$y1_state_name)])
            }
        }else{
            b_a <- outf$n[outf$y1_fips == outfips & outf$y2_fips == infips]
            denom_a <- (outf$n[outf$y1_fips == outfips &
                               grepl("US and Foreign", outf$y2_countyname)] +
                        outf$n[outf$y1_fips == outfips &
                               grepl("Non-migrants", outf$y2_countyname)])
            denom_b <- (inf$n[inf$y2_fips == infips &
                              grepl("US and Foreign", inf$y1_countyname)] +
                        inf$n[inf$y2_fips == infips &
                              grepl("Non-migrants", inf$y1_countyname)])
        }
        ## Calculate mean
        if(matchrate.lambda){
            meancalc <- b_a / as.double(denom_a)
        }else{
            meancalc <- b_a / (as.double(denom_a) * as.double(denom_b))
        }

    }

    ## Within-state matching
    if(geo.a == geo.b){
        if(!county){
            nm_a <- outf$n[outf$y1_statefips == outfips &
                           outf$y2_statefips == infips]
            m_a <- outf$n[outf$y1_statefips == outfips &
                          grepl("Same State", outf$y2_state_name)]
            b_a <- nm_a + m_a
            denom_a <- (outf$n[outf$y1_statefips == outfips &
                               outf$y2_statefips == outfips] +
                        outf$n[outf$y1_statefips == outfips &
                               outf$y2_statefips == 96] +
                        outf$n[outf$y1_statefips == outfips &
                               grepl("Same State", outf$y2_state_name)])
            denom_b <- (inf$n[inf$y1_statefips == infips &
                              inf$y2_statefips == infips] +
                        inf$n[inf$y2_statefips == infips &
                              inf$y1_statefips == 96] +
                        inf$n[inf$y2_statefips == infips &
                              grepl("Same State", inf$y1_state_name)])            
        }else{
            b_a <- outf$n[outf$y1_fips == outfips & outf$y2_fips == infips]
            denom_a <- (outf$n[outf$y1_fips == outfips &
                               grepl("US and Foreign", outf$y2_countyname)] + 
                        outf$n[outf$y1_fips == outfips &
                               grepl("Non-migrants", outf$y2_countyname)])
            denom_b <- (inf$n[inf$y2_fips == infips &
                              grepl("US and Foreign", inf$y1_countyname)] +
                        inf$n[inf$y2_fips == infips &
                              grepl("Non-migrants", inf$y1_countyname)])
        }
        if(matchrate.lambda){
            meancalc <- b_a / as.double(denom_a)
        }else{
            meancalc <- b_a / (as.double(denom_a) * as.double(denom_b))
        }
        if(!county){
            dir_mean <- m_a / (nm_a + m_a)
        }else{
            statemove <- get("statemove")
            dir_mean <- statemove$est[statemove$state == state.a]
        }
    }

    ## Return object
    out <- list()
    if(geo.a == geo.b){
        if(meancalc < 0){
            meancalc <- 1e-08
        }
        if(dir_mean < 0){
            dir_mean <- 1e-08
        }
        out[["lambda.prior"]] <- meancalc
        out[["pi.prior"]] <- dir_mean
    }else{
        if(meancalc < 0){
            meancalc <- 1e-08
        }
        out[["lambda.prior"]] <- meancalc
    }
    
    return(out)

}

