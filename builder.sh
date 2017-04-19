#!/bin/bash

# Build documentation, compile C++ attributes
# R -e 'sink("src/fastLink_init.c");tools::package_native_routine_registration_skeleton(".");sink()'
R -e 'devtools::document()'
R -e 'Rcpp::compileAttributes(verbose = TRUE)'

# Clean up src folder before build
cd src/
rm -rf *.o
rm -rf *.so
rm -rf *.rds

cd ../..

# Build and run CRAN checks
R CMD BUILD fastLink --resave-data 
# R CMD CHECK fastLink_*.tar.gz --as-cran
R CMD INSTALL fastLink_*.tar.gz
