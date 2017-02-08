// [[Rcpp::depends(RcppEigen)]]

#include <RcppEigen.h>
#include <ctime>

#ifdef _OPENMP
#include <omp.h>
#endif

using namespace Rcpp;

typedef Eigen::Triplet<double> T;
typedef Eigen::SparseMatrix<double> SpMat;
typedef Eigen::SparseMatrix<double>::InnerIterator InIt;

IntegerMatrix indexing(List s, int l1, int l2, int l3, int l4){
  
  // Get elements, declare matrix object
  IntegerVector s0 = s[0]; IntegerVector s1 = s[1];
  if(sum(s0 > l1 & s0 <= l2) >= 1 & sum(s1 > l3 & s1 <= l4) >= 1){
    
    // Subset vectors to indices that fall in range
    IntegerVector temp0 = as<IntegerVector>(s0[s0 > l1 & s0 <= l2]) - l1;
    IntegerVector temp1 = as<IntegerVector>(s1[s1 > l3 & s1 <= l4]) - l3;
    
    // Expand grid, declare size of matrix
    int i; int j;
    int rowcount = 0;
    IntegerMatrix index_out(temp0.size() * temp1.size(), 2);
    for(i = 0; i < temp0.size(); i++){
      for(j = 0; j < temp1.size(); j++){
	index_out(rowcount,0) = temp0[i];
	index_out(rowcount,1) = temp1[j];
	rowcount++;
      }
    }
    return index_out;
  }

}

List indexing_na(List s, int l1, int l2, int l3, int l4){

  // Unpack
  IntegerVector s0 = s[0]; IntegerVector s1 = s[1];

  // Subset
  IntegerVector temp0 = as<IntegerVector>(s0[s0 > l1 & s0 <= l2]) - l1;
  IntegerVector temp1 = as<IntegerVector>(s1[s1 > l3 & s1 <= l4]) - l3;

  // Output
  List out(2);
  out[0] = temp0;
  out[1] = temp1;
  return out;
  
}

List unpack_matches(List x, IntegerVector dims, bool match){

  // Declare objects
  int len_x = x.size(); int i; int j; int k; List feature_adj;
  int matrix_length; int adj_length;
  List list_out(len_x); int track_row; IntegerMatrix adj_store;
  int val; 
  
  // Loop over features
  for(i = 0; i < len_x; i++){

    // Unpack that feature
    feature_adj = x[i];
    matrix_length = 0;
    IntegerVector is_not_null(feature_adj.size());

    // Loop over entries in feature, delete if null
    for(j = 0; j < feature_adj.size(); j++){
      if(!Rf_isNull(feature_adj[j])){
	is_not_null[j] = 1;
	matrix_length += as<IntegerMatrix>(feature_adj[j]).nrow();
      } 
    }

    // Get correct entry for the sparse list
    if(match){
      val = pow(2, 2 + (i * 3));
    }else{
      val = pow(2, 1 + (i * 3));
    }

    // Create tripletList out of feature_adj
    std::vector<T> tripletList;
    tripletList.reserve(matrix_length);
    for(j = 0; j < feature_adj.size(); j++){
      if(is_not_null[j] == 1){
	adj_store = as<IntegerMatrix>(feature_adj[j]);
	for(k = 0; k < adj_store.nrow(); k++){
	  tripletList.push_back(T(adj_store(k,0)-1, adj_store(k,1)-1, val));
	}
      }
    }

    // Convert to sparse matrix
    SpMat sp(dims(0), dims(1));
    sp.setFromTriplets(tripletList.begin(), tripletList.end());

    // Store in list_out
    list_out[i] = sp;
    
  }

  return list_out;
  
}

IntegerVector getNotIn(IntegerVector vec1, IntegerVector vec2){
  IntegerVector matches = match(vec1,vec2);
  int n_out = sum(is_na(matches)) ;
  IntegerVector output(n_out); int i; int j;
		
  for(i = 0, j = 0; i < vec1.size(); i ++){
    if(matches[i] == NA_INTEGER){
      output[j++] = vec1[i];
    }
  }	
  return output;		
}

List create_sparse_na(List nas, IntegerVector dims){

  int i; int j; int k; int val; int nobs_a = dims[0]; int nobs_b = dims[1];
  IntegerVector nas_a; IntegerVector nas_b; List list_out(nas.size());
  IntegerVector nobs_a_notnull_inb;

  // Create comparison vector of indices of nobs_a
  IntegerVector nobs_a_vec(nobs_a);
  for(i = 0; i < nobs_a; i++){
    nobs_a_vec[i] = i+1;
  }

  for(i = 0; i < nas.size(); i++){

    // Get exponent value
    val = pow(2, 3 + (i * 3));

    // Extract indices of NAs
    nas_a = as<List>(nas[i])[0];
    nas_b = as<List>(nas[i])[1];

    nobs_a_notnull_inb = getNotIn(nobs_a_vec, nas_a);
    
    // Create triplet
    std::vector<T> tripletList;
    tripletList.reserve(nas_a.size() * nobs_b + nas_b.size() * nobs_a);
    for(j = 0; j < nas_a.size(); j++){
      for(k = 0; k < nobs_b; k++){
	tripletList.push_back(T(nas_a[j]-1, k, val));
      }
    }
    for(j = 0; j < nas_b.size(); j++){
      for(k = 0; k < nobs_a_notnull_inb.size(); k++){
	tripletList.push_back(T(nobs_a_notnull_inb[k]-1, nas_b[j]-1, val));
      }
    }

    // Convert to sparse matrix
    SpMat sp(dims(0), dims(1));
    sp.setFromTriplets(tripletList.begin(), tripletList.end());
    
    // Store in list.out
    list_out[i] = sp;

  }

  return list_out;

}

List m_func(List x){

  // Unpack the matched object and convert to sparse matrix
  List matches = x[0]; List pmatches = x[1];
  List nas = x[2]; IntegerVector lims = x[3];
  int i;
  matches  = unpack_matches(matches,  lims, true);
  pmatches = unpack_matches(pmatches, lims, false);

  // Insert nas into the matches object
  List nas_sp = create_sparse_na(nas, lims);
  
  // Add up everything
  SpMat sp(lims(0), lims(1));
  SpMat match_pmatch(lims(0), lims(1));
  SpMat match_pmatch_na(lims(0), lims(1));
  for(i = 0; i < matches.size(); i++){
    match_pmatch = as<SpMat>(matches[i]) + as<SpMat>(pmatches[i]);
    match_pmatch_na = match_pmatch + as<SpMat>(nas_sp[i]);
    sp = sp + match_pmatch_na;
  }

  // Create table by iterating through
  IntegerVector nz(sp.nonZeros());
  int counter = 0;
  for(i = 0; i < sp.outerSize(); i++){
    for(InIt it(sp,i); it; ++it){
      nz[counter] = it.value();
      counter++;
    }
  }
  IntegerVector tab = table(nz);
  CharacterVector names = tab.names();

  IntegerVector out_num(tab.size() + 1);
  CharacterVector out_char(tab.size() + 1);
  for(i = 0; i < out_num.size(); i++){
    if(i == out_num.size()-1){
      out_char[i] = "0";
      out_num[i] = lims(0)*lims(1) - sum(tab);
    }else{
      out_char(i) = names[i];
      out_num(i) = tab[i];
    }
  }

  return List::create(
		      _["names"] = out_char,
		      _["nobs"] = out_num
		      );
  
}

// [[Rcpp::export]]
List m_func_par(List temp, List ptemp, List natemp,
		IntegerVector limit1, IntegerVector limit2,
		IntegerVector nlim1, IntegerVector nlim2,
		IntegerMatrix ind, int threads = 1){

  // Declare objects
  int i; int j; int k; int n; int m; List step1(4);
  List templist(temp.size()); List ptemplist(ptemp.size());
  List natemplist(natemp.size());
  IntegerVector lims(2);
  List ind_out(ind.nrow());
  
  // Declare pragma environment
  #ifdef _OPENMP
  omp_set_num_threads(threads);
  threadsused = omp_get_max_threads();
  Rcout << "Gamma calculation is parallelized. "
	<< threadsused << " threads out of "
	<< omp_get_num_procs() << " are used."
	<< std::endl;
  #pragma omp parallel for
  #endif
  for(i = 0; i < ind.nrow(); i++){

    // Get indices of the rows
    n = ind(i,0)-1; m = ind(i, 1)-1;
    lims[0] = nlim1[n]; lims[1] = nlim2[m];

    // Loop over the number of features
    for(j = 0; j < temp.size(); j++){

      // Within this, loop over the list of each feature
      List temp_feature = temp[j];
      List ptemp_feature = ptemp[j];
      List indlist(temp_feature.size());
      List pindlist(ptemp_feature.size());
      for(k = 0; k < temp_feature.size(); k++){
	if(temp_feature.size() > 0){
	  indlist[k] = indexing(temp_feature[k], limit1[n], limit1[n+1],
				limit2[m], limit2[m+1]);
	}
      }
      for(k = 0; k < ptemp_feature.size(); k++){
	if(ptemp_feature.size() > 0){
	  pindlist[k] = indexing(ptemp_feature[k], limit1[n], limit1[n+1],
				 limit2[m], limit2[m+1]);
	}
      }

      templist[j] = indlist;
      ptemplist[j] = pindlist;
      natemplist[j] = indexing_na(natemp[j], limit1[n], limit1[n+1],
       				  limit2[m], limit2[m+1]);
      
    }

    // Create step1
    step1[0] = templist; step1[1] = ptemplist;
    step1[2] = natemplist; step1[3] = lims;

    // Run m_func
    List mf_out = m_func(step1);
    ind_out[i] = mf_out;
    
  }

  return ind_out;
  
}

