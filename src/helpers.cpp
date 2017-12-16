#include <Rcpp.h>

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix calcPWDcpp (NumericMatrix x, NumericMatrix y) {
  int nrows = x.nrow() ;
  int ncols = y.nrow() ;
  NumericMatrix out(nrows, ncols) ;

  for(int arow = 0; arow < nrows; arow++) {
    for(int acol = 0; acol < ncols; acol++) {
      double temp1 = std::abs(x(arow, 0) - y(acol, 0)) ;
      out(arow, acol) = temp1 ;
    }
  }
  return(out) ;
}
