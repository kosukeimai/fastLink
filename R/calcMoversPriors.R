#' calcMoversPriors
#'
#' calcMoversPriors estimates optimal \eqn{\alpha} and \eqn{\beta} values
#' for the Beta prior on \eqn{\gamma}, and optimal \eqn{\alpha_1} and
#' \eqn{\alpha_2} values for the Dirichlet prior on \eqn{\pi_{k,l}} when matching
#' state voter files over time, using IRS movers data.
#'
#' @param geo.a The state code (if state = TRUE) or county name
#' (if state = FALSE) for the earlier of the two voter files.
#' @param geo.b The state code (if state = TRUE) or county name
#' (if state = FALSE) for the later of the two voter files.
#' @param year.start The year of the voter file for geography A.
#' @param year.end The year of the voter file for geography B.
#' @param var.prior.gamma User-specified variance for the prior probability on gamma.
#' @param var.prior.pi User-specified variance for the prior probability on gamma.
#' @param L Number of agreement categories for \eqn{\pi_{k,l}}. Default is NULL.
#' @param county Whether prior is being calculated on the county or state level.
#' Default is FALSE (for a state-level calculation).
#' @param state.a If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo.a}. Default is NULL.
#' @param state.b If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo.b}. Default is NULL.
#' @param denom.mu If provided, serves as the default for calculating the
#' prior mean of the beta distribution.
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @export
calcMoversPriors <- function(geo.a, geo.b, year.start, year.end, L,
                             var.prior.gamma, var.prior.pi = NULL,
                             county = FALSE, state.a = NULL, state.b = NULL,
                             denom.mu = NULL){

    if(geo.a == geo.b & is.null(var.prior.pi)){
        stop("Please provide a prior variance for pi.")
    }

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
            meancalc <- b_a / (as.double(denom_a) * as.double(denom_b))
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
            meancalc <- b_a / (as.double(denom_a) * as.double(denom_b))
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
    mu <- meancalc^2 * ((1 - meancalc)/var.prior.gamma - (1/meancalc))
    psi <- mu * (1/meancalc - 1)
    if(mu < 1 | psi < 1){
        cat("Your provided variance for gamma is too large given the observed mean. The function will adaptively choose a new prior variance.\n")
        i <- 1
        repeat{
            var.prior.gamma <- 1/(10^i)
            mu <- meancalc^2 * ((1 - meancalc)/var.prior.gamma - (1/meancalc))
            psi <- mu * (1/meancalc - 1)
            if(mu > 1 & psi > 1){
                break
            }else{
                i <- i + 1
            }
        }
    }

    if(geo.a == geo.b){
        alpha_1 <- (
            dir_mean * (1 - dir_mean)^2 + var.prior.pi * dir_mean - var.prior.pi
        ) /
            (var.prior.pi * L - var.prior.pi)
        alpha_0 <- ((L - 1) * alpha_1 * dir_mean) / (1 - dir_mean)
        if(alpha_1 < 1 | alpha_0 < 1){
            cat("Your provided variance for pi is too large given the observed mean. The function will adaptively choose a new prior variance.\n")
            i <- 1
            repeat{
                var.prior.pi <- 1/(10^i)
                alpha_1 <- (
                    dir_mean * (1 - dir_mean)^2 + var.prior.pi * dir_mean - var.prior.pi
                ) /
                    (var.prior.pi * L - var.prior.pi)
                alpha_0 <- ((L - 1) * alpha_1 * dir_mean) / (1 - dir_mean)
                if(alpha_1 > 1 & alpha_0 > 1){
                    break
                }else{
                    i <- i + 1
                }
            }
        }
    }

    out <- list()
    if(geo.a == geo.b){
        out[["gamma_prior"]] <- list(mu = mu, psi = psi)
        out[["pi_prior"]] <- list(alpha_0 = alpha_0, alpha_1 = alpha_1)
        out[["parameter_values"]] <- list(gamma.mean = meancalc, gamma.var = var.prior.gamma, pi.mean = dir_mean, pi.var = var.prior.pi)
    }else{
        out[["gamma_prior"]] <- list(mu = mu, psi = psi)
        out[["parameter_values"]] <- list(gamma.mean = meancalc, gamma.var = var.prior.gamma)
    }

    return(out)

}

#' precalcPriors
#'
#' precalcPriors calculates optimal \eqn{\alpha} and \eqn{\beta} values
#' for the Beta prior on \eqn{\gamma}, and optimal \eqn{\alpha_1} and
#' \eqn{\alpha_2} values for the Dirichlet prior on \eqn{\pi_{k,l},
#' when the prior means for those parameters are already known.
#'
#' @param L Number of agreement categories for \eqn{\pi_{k,l}}. Default is NULL.
#' @param var.prior.gamma User-specified variance for the prior probability on gamma.
#' @param var.prior.pi User-specified variance for the prior probability on pi.
#' @param gamma.mean Prior mean for \eqn{\gamma}
#' @param pi.mean Prior mean for \eqn{pi_{k,l}}
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @export
precalcPriors <- function(L, var.prior.gamma = NULL, var.prior.pi = NULL, gamma.mean = NULL, pi.mean = NULL){

    if(is.null(gamma.mean) & is.null(pi.mean)){
        stop("Provide an argument for either 'pi.mean' or 'gamma.mean'")
    }
    if(!is.null(gamma.mean) & is.null(var.prior.gamma)){
        stop("Please provide a prior variance for gamma.")
    }
    if(!is.null(pi.mean) & is.null(var.prior.pi)){
        stop("Please provide a prior variance for pi.")
    }

    ## Calculate gamma priors
    out <- list()
    if(!is.null(gamma.mean)){
        mu <- gamma.mean^2 * ((1 - gamma.mean)/var.prior.gamma - (1/gamma.mean))
        psi <- mu * (1/gamma.mean - 1)
        if(mu < 1 | psi < 1){
            cat("Your provided variance for gamma is too large given the observed mean. The function will adaptively choose a new prior variance.\n")
            i <- 1
            repeat{
                var.prior.gamma <- 1/(10^i)
                mu <- gamma.mean^2 * ((1 - gamma.mean)/var.prior.gamma - (1/gamma.mean))
                psi <- mu * (1/gamma.mean - 1)
                if(mu > 1 & psi > 1){
                    break
                }else{
                    i <- i + 1
                }
            }
        }
        out[["gamma_prior"]] <- list(mu = mu, psi = psi)
    }

    ## Calculate pi priors
    if(!is.null(pi.mean)){
        alpha_1 <- (
            pi.mean * (1 - pi.mean)^2 + var.prior.pi * pi.mean - var.prior.pi
        ) /
            (var.prior.pi * L - var.prior.pi)
        alpha_0 <- ((L - 1) * alpha_1 * pi.mean) / (1 - pi.mean)
        if(alpha_1 < 1 | alpha_0 < 1){
            cat("Your provided variance for pi is too large given the observed mean. The function will adaptively choose a new prior variance.\n")
            i <- 1
            repeat{
                var.prior.pi <- 1/(10^i)
                alpha_1 <- (
                    pi.mean * (1 - pi.mean)^2 + var.prior.pi * pi.mean - var.prior.pi
                ) /
                    (var.prior.pi * L - var.prior.pi)
                alpha_0 <- ((L - 1) * alpha_1 * pi.mean) / (1 - pi.mean)
                if(alpha_1 > 1 & alpha_0 > 1){
                    break
                }else{
                    i <- i + 1
                }
            }
        }
        out[["pi_prior"]] <- list(alpha_0 = alpha_0, alpha_1 = alpha_1)
    }
    if(!is.null(gamma.mean) & !is.null(pi.mean)){
        out[["parameter_values"]] <- list(gamma.mean = gamma.mean, gamma.var = var.prior.gamma, pi.mean = pi.mean, pi.var = var.prior.pi)
    }else if(!is.null(gamma.mean)){
        out[["parameter_values"]] <- list(gamma.mean = gamma.mean, gamma.var = var.prior.gamma)
    }else if(!is.null(pi.mean)){
        out[["parameter_values"]] <- list(pi.mean = pi.mean, pi.var = var.prior.pi)
    }

    return(out)

}

