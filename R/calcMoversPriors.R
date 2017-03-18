#' calcMoversPriors
#'
#' calcMoversPriors estimates optimal \eqn{\alpha} and \eqn{\beta} values
#' for the Beta prior on \eqn{\lambda}, and optimal \eqn{\alpha_1} and
#' \eqn{\alpha_2} values for the Dirichlet prior on \eqn{\pi_{k,l}} when matching
#' state voter files over time, using IRS movers data.
#'
#' @param geo.a The state code (if state = TRUE) or county name
#' (if state = FALSE) for the earlier of the two voter files.
#' @param geo.b The state code (if state = TRUE) or county name
#' (if state = FALSE) for the later of the two voter files.
#' @param year.start The year of the voter file for geography A.
#' @param year.end The year of the voter file for geography B.
#' @param var.prior.lambda User-specified variance for the prior probability on lambda.
#' @param var.prior.pi User-specified variance for the prior probability on lambda.
#' @param L Number of agreement categories for \eqn{\pi_{k,l}}. Default is NULL.
#' @param county Whether prior is being calculated on the county or state level.
#' Default is FALSE (for a state-level calculation).
#' @param state.a If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo.a}. Default is NULL.
#' @param state.b If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo.b}. Default is NULL.
#' @param denom.lambda.mean If provided, serves as the default for calculating the
#' prior mean of the beta distribution.
#' @param lambda.count Whether to base the hyperparameter calculations off of
#' counts of "successes" (movers) and "failures" (non-movers) instead of
#' proprotions. Default is FALSE.
#' @param max.iter Maximum powers of 10 that should be tried to find a proper
#' variance for priors before failing. Default is 100.
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @export
calcMoversPriors <- function(geo.a, geo.b, year.start, year.end, L,
                             var.prior.lambda, var.prior.pi = NULL,
                             county = FALSE, state.a = NULL, state.b = NULL,
                             denom.lambda.mean = NULL, lambda.count = FALSE,
                             max.iter = 100){

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
        if(is.null(denom.lambda.mean)){
            meancalc <- b_a / (as.double(denom_a) * as.double(denom_b))
        }else{
            meancalc <- b_a / denom.lambda.mean
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
        if(is.null(denom.lambda.mean)){
            meancalc <- b_a / (as.double(denom_a) * as.double(denom_b))
        }else{
            meancalc <- b_a / denom.lambda.mean
        }
        if(!county){
            dir_mean <- m_a / (nm_a + m_a)
        }else{
            data(cps_statemovers)
            dir_mean <- tab$est[tab$state == state.a]
        }
    }
    if(lambda.count){
        success.counts <- b_a
        failure.counts <- min(denom_a, denom_b) - b_a
    }

    ## Get optimal parameters
    mu <- meancalc^2 * ((1 - meancalc)/var.prior.lambda - (1/meancalc))
    psi <- mu * (1/meancalc - 1)
    if(mu < 1 | psi < 1){
        cat("Your provided variance for lambda is too large given the observed mean. The function will adaptively choose a new prior variance.\n")
        i <- 1
        repeat{
            var.prior.lambda <- 1/(10^i)
            mu <- meancalc^2 * ((1 - meancalc)/var.prior.lambda - (1/meancalc))
            psi <- mu * (1/meancalc - 1)
            if((mu > 1 & psi > 1) | i == max.iter){
                if(i == max.iter){
                    mu <- 1; psi <- 1
                }
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
                if((alpha_1 > 1 & alpha_0 > 1) | i == max.iter){
                    if(i == max.iter){
                        alpha_1 <- 1; alpha_0 <- 1
                    }
                    break
                }else{
                    i <- i + 1
                }
            }
        }
    }

    out <- list()
    if(geo.a == geo.b){
        if(!lambda.count){
            out[["lambda_prior"]] <- list(mu = mu, psi = psi)
        }else{
            out[["lambda_prior"]] <- list(mu = success.counts, psi = failure.counts)
        }
        out[["pi_prior"]] <- list(alpha_0 = alpha_0, alpha_1 = alpha_1)
        out[["parameter_values"]] <- list(lambda.mean = meancalc, lambda.var = var.prior.lambda, pi.mean = dir_mean, pi.var = var.prior.pi)
    }else{
        if(!lambda.count){
            out[["lambda_prior"]] <- list(mu = mu, psi = psi)
        }else{
            out[["lambda_prior"]] <- list(mu = success.counts, psi = failure.counts)
        }
        out[["parameter_values"]] <- list(lambda.mean = meancalc, lambda.var = var.prior.lambda)
    }

    return(out)

}

#' precalcPriors
#'
#' precalcPriors calculates optimal \eqn{\alpha} and \eqn{\beta} values
#' for the Beta prior on \eqn{\lambda}, and optimal \eqn{\alpha_1} and
#' \eqn{\alpha_2} values for the Dirichlet prior on \eqn{\pi_{k,l},
#' when the prior means for those parameters are already known.
#'
#' @param L Number of agreement categories for \eqn{\pi_{k,l}}. Default is NULL.
#' @param var.prior.lambda User-specified variance for the prior probability on lambda.
#' @param var.prior.pi User-specified variance for the prior probability on pi.
#' @param lambda.mean Prior mean for \eqn{\lambda}
#' @param pi.mean Prior mean for \eqn{pi_{k,l}}
#' @param max.iter Maximum powers of 10 that should be tried to find a proper
#' variance for priors before failing. Default is 100.
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @export
precalcPriors <- function(L, var.prior.lambda = NULL, var.prior.pi = NULL, lambda.mean = NULL, pi.mean = NULL, max.iter = 100){

    if(is.null(lambda.mean) & is.null(pi.mean)){
        stop("Provide an argument for either 'pi.mean' or 'lambda.mean'")
    }
    if(!is.null(lambda.mean) & is.null(var.prior.lambda)){
        stop("Please provide a prior variance for lambda.")
    }
    if(!is.null(pi.mean) & is.null(var.prior.pi)){
        stop("Please provide a prior variance for pi.")
    }

    ## Calculate lambda priors
    out <- list()
    if(!is.null(lambda.mean)){
        mu <- lambda.mean^2 * ((1 - lambda.mean)/var.prior.lambda - (1/lambda.mean))
        psi <- mu * (1/lambda.mean - 1)
        if(mu < 1 | psi < 1){
            cat("Your provided variance for lambda is too large given the observed mean. The function will adaptively choose a new prior variance.\n")
            i <- 1
            repeat{
                var.prior.lambda <- 1/(10^i)
                mu <- lambda.mean^2 * ((1 - lambda.mean)/var.prior.lambda - (1/lambda.mean))
                psi <- mu * (1/lambda.mean - 1)
                if((mu > 1 & psi > 1) | i == max.iter){
                    if(i == max.iter){
                        mu <- 1; psi <- 1
                    }
                    break
                }else{
                    i <- i + 1
                }
            }
        }
        out[["lambda_prior"]] <- list(mu = mu, psi = psi)
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
                if((alpha_1 > 1 & alpha_0 > 1) | i == max.iter){
                    if(i == max.iter){
                        alpha_1 <- 1; alpha_0 <- 1
                    }
                    break
                }else{
                    i <- i + 1
                }
            }
        }
        out[["pi_prior"]] <- list(alpha_0 = alpha_0, alpha_1 = alpha_1)
    }
    if(!is.null(lambda.mean) & !is.null(pi.mean)){
        out[["parameter_values"]] <- list(lambda.mean = lambda.mean, lambda.var = var.prior.lambda, pi.mean = pi.mean, pi.var = var.prior.pi)
    }else if(!is.null(lambda.mean)){
        out[["parameter_values"]] <- list(lambda.mean = lambda.mean, lambda.var = var.prior.lambda)
    }else if(!is.null(pi.mean)){
        out[["parameter_values"]] <- list(pi.mean = pi.mean, pi.var = var.prior.pi)
    }

    return(out)

}

