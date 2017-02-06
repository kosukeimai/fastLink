#!/bin/bash

# Build documentation, compile C++ attributes
cd fastLink
R -e 'library(devtools);document()'
R -e 'library(Rcpp);compileAttributes(verbose = TRUE)'

# Clean up src folder before build
cd src/
rm -rf *.o
rm -rf *.so
rm -rf *.rds

cd ../..

# Build and run CRAN checks
R CMD BUILD fastLink --resave-data 
R CMD CHECK fastLink_0.1.0.tar.gz --as-cran
