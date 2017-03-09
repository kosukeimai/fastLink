#' typo
#'
#' This is a function that creates a typo within a string. It was created as
#' a form to add noise to a field that holds a string variable in the validation
#' exercises that can be found in Enamorado and Imai (Nd)
#'
#' @param x object that holds the string variable (value) to be modified.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Kosuke Imai
#'
#' @export

## Typos:

typo <- function(x) {

	pairs <- rbind(LETTERS, toupper(c("s","v", "x", "f", "w", "d", "f", "j", "o", "k", "l", "k", "n", "m", "p", "o", "w", "e", "a", "r", "y", "b", "q", "z", "u", "x")))

	n <- nchar(x)

	if(n > 2) {
	## Typo: 0 Beginning, 1 End
    begend <- rbinom(1, 1, 0.5)

	if(begend == 1) {
		index <- (round(nchar(x)/2, 0) + 1):nchar(x)
		} else {
		index <- 2:round(nchar(x)/2, 0)
		}

	index.2 <- sort(sample(index, 1), decreasing = T)

	substr(x, index.2[1], index.2[1]) <- pairs[ , (pairs[1, ] == substr(x, index.2[1], index.2[1])) == 1 ][2]
	}
	return(x)
}

