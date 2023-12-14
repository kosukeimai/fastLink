#include <Rcpp.h>

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix calcPWDcpp (NumericVector x, NumericVector y) {
  int nrows = x.size(), ncols = y.size() ;
  NumericMatrix out(nrows, ncols) ;
  for(int arow = 0; arow < nrows; arow++) {
    for(int acol = 0; acol < ncols; acol++) {
      double temp1 = std::abs(x[arow] - y[acol]) ;
      out(arow, acol) = temp1 ;
    }
  }
  return(out) ;
}
