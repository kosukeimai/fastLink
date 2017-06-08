#' cleanAddressUSPS
#'
#' Apply USPS address standardization to address field.
#'
#' @usage cleanAddressUSPS(address.field)
#' @param address.field A vector containing address information to be cleaned.
#'
#' @return \code{cleanAddressUSPS()} returns a cleaned version of \code{address.field}.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Ben Fifield <benfifield@gmail.com>
#' @examples dfA$streetname <- cleanAddressUSPS(dfA$streetname)
#' @export
cleanAddressUSPS <- function(address.field){
    
    ## Standardization
    address.field <- ifelse(grepl(" avenue", address.field),
                            gsub(" avenue", " ave", address.field),
                     ifelse(grepl(" avn", address.field),
                            gsub(" avn", " ave", address.field),
                            gsub(" av", " ave", address.field)))
    address.field <- gsub(" avee", " ave", address.field)
    address.field <- gsub(" boulevard", " blvd", address.field)
    address.field <- gsub(" circle", " cir", address.field)
    address.field <- gsub(" court", " ct", address.field)
    address.field <- gsub(" drive", " dr", address.field)
    address.field <- gsub(" junction", " jct", address.field)
    address.field <- gsub(" place", " pl", address.field)
    address.field <- gsub(" road", " rd", address.field)
    address.field <- gsub(" route", " rte", address.field)
    address.field <- gsub(" square", " sq", address.field)
    address.field <- gsub(" street", " st", address.field)
    address.field <- gsub(" apartment", " apt", address.field)
    address.field <- gsub(" building", " bldg", address.field)

    return(trimws(address.field))
    
}

