#' deletion
#'
#' This is a function that deletes a character at random from a string.
#' It was created as a form to add noise to a field that
#' holds a string variable in the validation exercises that can be found
#' in Enamorado and Imai (Nd)
#'
#' @param x object that holds the string variable (value) to be modified.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Kosuke Imai
#'
#' @export

## Delitions:

deletion <- function(x) {

	n <- nchar(x)

	if(n > 2) {
	## Typo: 0 Beginning, 1 End
    begend <- rbinom(1, 1, 0.5)

	if(begend == 1) {
		index <- (round(nchar(x)/2, 0) + 1):nchar(x)
		} else {
		index <- 2:round(nchar(x)/2, 0)
		}

	index.2 <- sample(index, 1)

	substr(x, index.2[1], index.2[1]) <- " "
	x <- gsub(" ", "", x, fixed = TRUE)
	}
	return(x)
}


