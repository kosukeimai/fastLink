#' calcMoversPriors
#'
#' calcMoversPriors estimates optimal \eqn{\alpha} and \eqn{\beta} values
#' for the Beta prior on \eqn{\gamma}, and optimal \eqn{\alpha_1} and
#' \eqn{\alpha_2} values for the Dirichlet prior on \eqn{\pi_{k,l}} when matching
#' state voter files over time.
#'
#' @param geo.a The state code (if state = TRUE) or county name
#' (if state = FALSE) for the earlier of the two voter files.
#' @param geo.b The state code (if state = TRUE) or county name
#' (if state = FALSE) for the later of the two voter files.
#' @param year.start The year of the voter file for geography A.
#' @param year.end The year of the voter file for geography B.
#' @param var.prior User-specified variance for the prior probability.
#' @param L Number of agreement categories for \eqn{\pi_{k,l}}. Default is NULL.
#' @param county Whether prior is being calculated on the county or state level.
#' Default is FALSE (for a state-level calculation).
#' @param state.a If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo_a}. Default is NULL.
#' @param state.b If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo_b}. Default is NULL.
#' @param denom.mu If provided, serves as the default for calculating the
#' prior mean of the beta distribution.
#' @param return.means Whether to return the estimated match rates. Default is
#' FALSE.
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @export
calcMoversPriors <- function(geo.a, geo.b, year.start, year.end, var.prior, L,
                             county = FALSE, state.a = NULL, state.b = NULL,
                             denom.mu = NULL, return.means = FALSE){

    ## Load the correct level of IRS data
    if(!county){
        data(irs_statemigration); data(statecode_to_fips)
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
        data(irs_countymigration); data(countyname_to_fips)
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
    inf$n <- inf$n1 + inf$n2; outf$n <- outf$n1 + outf$n2

    ## Cross-state matching
    if(geo.a != geo.b){
        if(!county){
            b_a <- outf$n[outf$y1_statefips == outfips &
                          outf$y2_statefips == infips]
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
        ## Calculate mean
        if(is.null(denom.mu)){
            meancalc <- b_a / (denom_a * denom_b)
        }else{
            meancalc <- b_a / denom.mu
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
            nm_a <- outf$n[outf$y1_fips == outfips & outf$y2_fips == infips]
            denom_a <- (outf$n[outf$y1_fips == outfips &
                               grepl("US and Foreign", outf$y2_countyname)] + 
                        outf$n[outf$y1_fips == outfips &
                               grepl("Non-migrants", outf$y2_countyname)])
            denom_b <- (inf$n[inf$y2_fips == infips &
                              grepl("US and Foreign", inf$y1_countyname)] +
                        inf$n[inf$y2_fips == infips &
                              grepl("Non-migrants", inf$y1_countyname)])
        }
        if(is.null(denom.mu)){
            meancalc <- b_a / (denom_a * denom_b)
        }else{
            meancalc <- b_a / denom.mu
        }
        if(!county){
            dir_mean <- m_a / (nm_a + m_a)
        }else{
            data(cps_statemovers)
            dir_mean <- tab$est[tab$state == state.a]
        }
    }

    ## Get optimal parameters
    mu <- meancalc^2 * ((1 - meancalc)/var_prior - (1/meancalc))
    psi <- mu * (1/meancalc - 1)
    if(mu < 0 | psi < 0){
        cat("Your provided variance is too large given the observed mean. The function will adaptively choose a new prior variance.\n")
        i <- 1
        repeat{
            var_prior <- 1/(10^i)
            mu <- meancalc^2 * ((1 - meancalc)/var_prior - (1/meancalc))
            psi <- mu * (1/meancalc - 1)
            if(mu > 0 & psi > 0){
                break
            }else{
                i <- i + 1
            }
        }
    }

    if(geo_a == geo_b){
        alpha_1 <- (
            dir_mean * (1 - dir_mean)^2 + var_prior * dir_mean - var_prior
        ) /
            (var_prior * L - var_prior)
        alpha_0 <- ((L - 1) * alpha_1 * dir_mean) / (1 - dir_mean)
    }

    out <- list()
    if(geo_a == geo_b){
        out[["gamma_priors"]] <- list(mu = mu, psi = psi)
        out[["pi_prior"]] <- list(alpha_0 = alpha_0, alpha_1 = alpha_1)
    }else{
        out[["gamma_priors"]] <- list(mu = mu, psi = psi)
    }
    if(return_means){
        out[["est_matchrate"]] <- meancalc
    }

    return(out)

}

