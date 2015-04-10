get_mgrast_metadata.v2 <- function(
  mgid_list="mgrast_ids.txt",
  use_auth=TRUE,
  auth="~/my_auth_key.txt",
  output_file="metadata_out.txt",
  verbose=FALSE,
  debug=FALSE
){
  
  
  start <- Sys.time ()
  print(paste("start:", start))
  
  # load packages
  require(matR) 
  require(RJSONIO)
  require(RCurl)
  require(plyr)
  
  #import the list of mgids from file
  #if (list_is_file==TRUE){
  if( verbose==TRUE )( print(paste("metagenome (1)", sep="")))
  temp_list <- read.table(mgid_list)
  num_samples <- dim(temp_list)[1]
  new_list <- vector(mode="character", length=num_samples)
  for( i in 1:num_samples ){ # add ids to list
    new_list[i] <- as.character(temp_list[i,1])
  }
  if( dim(temp_list)[2] == 2 ){ # name the ids in the list -- if names were supplied
    for( j in 1:num_samples ){
      names(new_list)[j] <- as.character(temp_list[j,2])
    }
  }
  mgid_list <- new_list[1:num_samples]
  #}
  num_samples.test <<- num_samples
  
  # first id
  my_metadata_matrix <- get_single_metagenome_metadata(mgid=mgid_list[1], use_auth, auth, debug)
  
  first <<- my_metadata_matrix
  
  # second and all other ids
  if ( num_samples > 1 ){
    for ( i in 2:num_samples ){
      my_metadata_matrix.tmp <- get_single_metagenome_metadata(mgid=mgid_list[i], use_auth, auth, debug)
      my_metadata_matrix <- rbind.fill.matrix(my_metadata_matrix, my_metadata_matrix.tmp)
      last <<- my_metadata_matrix.tmp
      if( verbose==TRUE )( print(paste("metagenome (", i, ")", sep="")))
    }
  }
  
  # add rownames (mgrast ids)
  rownames(my_metadata_matrix) <- mgid_list
  
  # export metadata to file
  export_data(my_metadata_matrix, output_file)
  
  runtime <- Sys.time () - start
  print(paste("runtime:", round(runtime, digits=2), "seconds"))
  
}



get_single_metagenome_metadata <- function(mgid, use_auth, auth, debug){
  
  if ( use_auth==TRUE ){
    my_auth <- scan(file=auth, what="character", quiet=TRUE)
    my_call <- paste("http://api.metagenomics.anl.gov//metagenome/", mgid, "?verbosity=full&asynchronous=1&auth=", my_auth, sep="", collapse="")
  }else{
    my_call <- paste("http://api.metagenomics.anl.gov//metagenome/", mgid, "?verbosity=full&asynchronous=1", sep="", collapse="")
  }
  
  my_api.call <- fromJSON(getURL(my_call))
  
  num_col <- 0
  col_names <- vector(mode="character", length=0)
  
  my_api.call.metadata <- my_api.call$metadata
  my_api.call.metadata.flat <- flatten_list(my_api.call.metadata)
  num_col <- length(my_api.call.metadata.flat)
  if( debug==TRUE ){ metadata_names.test <<- names(my_api.call.metadata.flat) }
  col_names <- c(col_names, names(my_api.call.metadata.flat))
  
  my_api.call.stats.sequence_stats <- my_api.call$statistics$sequence_stats # this list is already flat
  #my_api.call.stats.sequence_stats.flat <- flatten_list(my_api.call.stats.sequence_stats)
  if( debug==TRUE ){ my_api.call.stats.sequence_stats.test <<- my_api.call.stats.sequence_stats }
  #num_col <- num_col + length(my_api.call.stats.sequence_stats.flat)
  num_col <- num_col + length(my_api.call.stats.sequence_stats)
  if( debug==TRUE ){ sequence_stats_names.test <<- names(my_api.call.stats.sequence_stats) } # <---
  col_names <- c(col_names, names(my_api.call.stats.sequence_stats))
  
  my_api.call.metadata.env_package <- my_api.call$metadata$env_package
  my_api.call.metadata.env_package.flat <- flatten_list(my_api.call.metadata.env_package)
  num_col <- num_col + length(my_api.call.metadata.env_package.flat)
  if( debug==TRUE ){ env_package_names.test <<- names(my_api.call.metadata.env_package.flat) }
  col_names <- c(col_names, names(my_api.call.metadata.env_package.flat))
  
  my_api.call.mixs <- my_api.call$mixs
  my_api.call.mixs.flat <- flatten_list(my_api.call.mixs)
  num_col <- num_col + length(my_api.call.mixs.flat)
  if( debug==TRUE ){ mixs_names.test <<- names(my_api.call.mixs.flat) }
  col_names <- c(col_names, names(my_api.call.mixs.flat))
  
  my_metadata_matrix <- matrix(c(
    my_api.call.metadata.flat,
    my_api.call.stats.sequence_stats, # .flat
    my_api.call.metadata.env_package.flat,
    my_api.call.mixs.flat
  ), ncol = num_col, byrow = FALSE)
  
  if( debug==TRUE ){ col_names.test <<- col_names }
  
  colnames(my_metadata_matrix) <- col_names
  rownames(my_metadata_matrix) <- (unlist(my_api.call))['id']
  
  return(my_metadata_matrix)
}



flatten_list <- function(some_list){
  flat_list <- unlist(some_list)
  flat_list <- gsub("\r","",flat_list)
  flat_list <- gsub("\n","",flat_list)
  flat_list <- gsub("\t","",flat_list)
}

