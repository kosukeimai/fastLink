#' preprocText
#'
#' Preprocess text data such as names and addresses.
#'
#' @usage preprocText(text, convert_text, tolower, soundex,
#' usps_address, convert_text_to)
#' @param text A vector of text data to convert.
#' @param convert_text Whether to convert text to the desired encoding, where
#' the encoding is specified in the 'convert_text_to' argument. Default is
#' TRUE
#' @param tolower Whether to normalize the text to be all lowercase. Default is
#' TRUE.
#' @param soundex Whether to convert the field to the Census's soundex encoding.
#' Default is FALSE.
#' @param usps_address Whether to use USPS address standardization rules to clean address fields.
#' Default is FALSE.
#' @param convert_text_to Which encoding to use when converting text. Default is 'Latin-ASCII'.
#' Full list of encodings in the \code{stri_trans_list()} function in the \code{stringi} package.
#'
#' @return \code{preprocText()} returns the preprocessed vector of text.
#'
#' @author Ben Fifield <benfifield@gmail.com>
#' @export
#' @importFrom stringi stri_trans_list stri_trans_general
#' @importFrom stringdist phonetic
preprocText <- function(text, convert_text = TRUE, tolower = TRUE,
                        soundex = FALSE, usps_address = FALSE, convert_text_to = "Latin-ASCII"){

    if(!(convert_text_to %in% stri_trans_list())){
        stop("Sorry, that encoding is not included in the set of valid encodings. Please check 'stri_trans_list()' in the 'stringi' package for the full set of valid encodings.")
    }
    
    if(convert_text){
        text <- stri_trans_general(text, convert_text_to)
    }
    if(tolower){
        text <- tolower(text)
    }
    if(soundex){
        text <- phonetic(text)
    }
    if(usps_address){
        text <- gsub(" avenue", " ave", text)
        text <- gsub(" boulevard", " blvd", text)
        text <- gsub(" circle", " cir", text)
        text <- gsub(" court", " ct", text)
        text <- gsub(" drive", " dr", text)
        text <- gsub(" junction", " jct", text)
        text <- gsub(" place", " pl", text)
        text <- gsub(" road", " rd", text)
        text <- gsub(" route", " rte", text)
        text <- gsub(" square", " sq", text)
        text <- gsub(" street", " st", text)
        text <- gsub(" apartment", " apt", text)
        text <- gsub(" building", " bldg", text)
    }

    return(text)

}
