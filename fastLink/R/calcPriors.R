#' calcPriors
#'
#' calcPriors estimates optimal \eqn{\alpha} and \eqn{\beta} values
#' for the Beta prior on \eqn{\gamma}, and optimal \eqn{\alpha_1} and
#' \eqn{\alpha_2} values for the Dirichlet prior on \eqn{\pi_{k,l}} when matching
#' state voter files over time.
#'
#' @param geo_a The state code (if state = TRUE) or county name
#' (if state = FALSE) for the earlier of the two voter files.
#' @param geo_b The state code (if state = TRUE) or county name
#' (if state = FALSE) for the later of the two voter files.
#' @param year_start The year of the voter file for geography A.
#' @param year_end The year of the voter file for geography B.
#' @param var_prior User-specified variance for the prior probability.
#' @param L Number of agreement categories for \eqn{\pi_{k,l}}. Default is NULL.
#' @param county Whether prior is being calculated on the county or state level.
#' Default is FALSE (for a state-level calculation).
#' @param state_a If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo_a}. Default is NULL.
#' @param state_b If \code{county = TRUE} (indicating a county-level match),
#' the state code of \code{geo_b}. Default is NULL.
#'
#' @author Ben Fifield <benfifield@gmail.com>
#'
#' @export
calcPriors <- function(geo_a, geo_b, year_start, year_end, var_prior,
                       L = NULL, county = FALSE, state_a = NULL, state_b = NULL,
                       denom_mu = NULL){
    
    if(county & (is.null(state_a) | is.null(state_b))){
        stop("If calculating priors on the county level, provide arguments for 'state_a' and 'state_b'.")
    }
    
    ## Load data
    if(!county){
        data(irs_statemigration); data(statecode_to_fips)
        ## Subset down stateinflow, stateoutflow to the correct years
        outf <- subset(
            stateoutflow, start_year >= year_start & end_year <= year_end
        )
        inf <- subset(
            stateinflow, start_year >= year_start & end_year <= year_end
        )
    }else{
        data(irs_countymigration); data(countyname_to_fips)
        outf <- subset(
            countyoutflow, start_year >= year_start & end_year <= year_end
        )
        inf <- subset(
            countyinflow, start_year >= year_start & end_year <= year_end
        )
    }

    ## Set the n sizes
    inf$n <- inf$n1 + inf$n2; outf$n <- outf$n1 + outf$n2

    ## Cross-geo matching ##
    if(geo_a != geo_b){
        if(!county){
            fips_a <- statefips$statefips[statefips$state == geo_a]
            fips_b <- statefips$statefips[statefips$state == geo_b]
            
            ## QOI's for state A
            nm_a <- outf$n[outf$y1_statefips == fips_a &
                           outf$y2_statefips == fips_a]
            is_a <- outf$n[outf$y1_statefips == fips_a &
                           outf$y2_statefips == 97 &
                           grepl("Same State", outf$y2_state_name)]
            b_a <- outf$n[outf$y1_statefips == fips_a &
                          outf$y2_statefips == fips_b]
            nb_a <- outf$n[outf$y1_statefips == fips_a &
                           outf$y2_statefips == 96] - b_a
            denom_a <- nm_a + is_a + b_a + nb_a
            
            ## QOI's for state B
            nm_b <- inf$n[inf$y1_statefips == fips_b &
                          inf$y2_statefips == fips_b]
            is_b <- inf$n[inf$y2_statefips == fips_b &
                          inf$y1_statefips == 97 &
                          grepl("Same State", inf$y1_state_name)]
            a_b <- inf$n[inf$y1_statefips == fips_a &
                         inf$y2_statefips == fips_b]
            na_b <- inf$n[inf$y2_statefips == fips_b &
                          inf$y1_statefips == 96] - a_b
            denom_b <- nm_b + is_b + a_b + na_b
        }else{
            
            countyfips_sub <- subset(countyfips, state != "PR")
            countyfips_sub$state <- factor(countyfips_sub$state)
            
            namesvec <- as.character(countyfips_sub$name)
            namesvec <- ifelse(
                word(namesvec,-1) == "County", gsub("\\s*\\w*$", "", namesvec),
                namesvec
            )
            namesvec <- gsub("\xb1", "n", namesvec)
            namesvec <- gsub("\x97", "o", namesvec)
            namesvec <- gsub("\x92", "i", namesvec)
            namesvec <- tolower(namesvec)
            
            fips_a <- unique(countyfips_sub$fips[namesvec == geo_a &
                                                 countyfips_sub$state == state_a])
            fips_b <- unique(countyfips_sub$fips[namesvec == geo_b &
                                                 countyfips_sub$state == state_b])

            ## QOI's for geo A
            denom_a <- outf$n[outf$y1_fips == fips_a &
                            grepl("US and Foreign", outf$y2_countyname)] +
                outf$n[outf$y1_fips == fips_a &
                       grepl("Non-migrants", outf$y2_countyname)]
            b_a <- outf$n[outf$y1_fips == fips_a &
                          outf$y2_fips == fips_b]

            ## QOI's for geo B
            denom_b <- inf$n[inf$y2_fips == fips_b &
                             grepl("US and Foreign", inf$y1_countyname)] +
                inf$n[inf$y2_fips == fips_b &
                      grepl("Non-migrants", inf$y1_countyname)]
            
        }
        ## Calculate mean
        if(is.null(denom_mu)){
            meancalc <- b_a / (as.double(denom_a) * as.double(denom_b))
        }else{
            meancalc <- b_a / denom_mu
        }
        
    }

    ## Within-geo matching
    if(geo_a == geo_b){
        if(!county){
            fips <- statefips$statefips[statefips$state == geo_a]
            
            ## QOI's for period a
            nm_a <- outf$n[outf$y1_statefips == fips & outf$y2_statefips == fips]
            is_a <- outf$n[outf$y1_statefips == fips & outf$y2_statefips == 97 &
                           grepl("Same State", outf$y2_state_name)]
            oos_a <- outf$n[outf$y1_statefips == fips & outf$y2_statefips == 96]
            denom_a <- nm_a + is_a + oos_a
            num <- nm_a + is_a
            
            ## QOI's for period b
            nm_b <- inf$n[inf$y1_statefips == fips & inf$y2_statefips == fips]
            is_b <- inf$n[inf$y2_statefips == fips & inf$y1_statefips == 97 &
                          grepl("Same State", inf$y1_state_name)]
            oos_b <- inf$n[inf$y2_statefips == fips & inf$y1_statefips == 96]
            denom_b <- nm_b + is_b + oos_b
        }else{
            fips <- unique(
                countyfips$fips[countyfips$name == gsub(" County", "", geo_a) &
                                countyfips$state == state_a])

            ## QOI's for period a
            denom_a <- outf$n[outf$y1_fips == fips &
                            grepl("US and Foreign", outf$y2_countyname)] +
                outf$n[outf$y1_fips == fips &
                       grepl("Non-migrants", outf$y2_countyname)]
            nm_a <- outf$n[outf$y1_fips == fips & outf$y2_fips == fips]
            num <- nm_a

            ## QOI's for period b
            denom_b <- inf$n[inf$y2_fips == fips &
                             grepl("US and Foreign", inf$y1_countyname)] +
                inf$n[inf$y2_fips == fips &
                      grepl("Non-migrants", inf$y1_countyname)]
        }
        
        ## Calculate mean
        if(is.null(denom_mu)){
            meancalc <- num / (as.double(denom_a) * as.double(denom_b))
        }else{
            meancalc <- num / denom_mu
        }
        if(!county){
            dir_mean <- is_a / (nm_a + is_a)
        }else{
            data(cps_statemovers)
            dir_mean <- tab$est[tab$state == state_a]
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

    if(geo_a == geo_b){
        return(list(gamma_priors = list(mu = mu, psi = psi),
                    pi_prior = list(alpha_0 = alpha_0, alpha_1 = alpha_1)))
    }else{
        return(gamma_priors = list(mu = mu, psi = psi))
    }

}
 
