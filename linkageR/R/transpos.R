#' transpos
#'
#' This is a function that transposes (chages its order of appeareance) a
#' character at random from a string. It was created as a form to add noise
#' to a field that holds a string variable in the validation exercises that
#' can be found in Enamorado and Imai (Nd)
#'
#' @param x object that holds the string variable (value) to be modified.
#'
#' @author Ted Enamorado <ted.enamorado@gmail.com> and Kosuke Imai
#'
#' @export

## Transpositions:

transpos <- function(x) {
	n <- nchar(x)

	if(n > 2) {
	## Transposition: 0 Beginning, 1 End
    begend <- rbinom(1, 1, 0.5)

	if(begend == 1) {
		index <- (round(nchar(x)/2, 0) + 1):nchar(x)
		} else {
		index <- 1:round(nchar(x)/2, 0)
		}

	diff <- 3
	while(diff > 1){
		diff.o <- diff
		index.2 <- sort(sample(index, 2), decreasing = T)
		diff <- abs(index.2[2] - index.2[1])
	}

	x.0 <- x
	substr(x, index.2[1], index.2[1]) <- substr(x.0, index.2[2], index.2[2])
	substr(x, index.2[2], index.2[2]) <- substr(x.0, index.2[1], index.2[1])
	}

	return(x)
}

