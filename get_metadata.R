#setwd("~/Documents/Projects/get_metadata/")

get_metadata <- function( mgid_list, output_file=NA, debug=FALSE, my_auth_file=NA ){ 
  
  library(RCurl)
  library(RJSONIO)
  library(matlab)
  
  # sub to export data
  export_data <- function(data_object, file_name){
    write.table(data_object, file=file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
  }
  
  
  id_list <- scan(file=mgid_list, comment.char="#", what="character", blank.lines.skip=TRUE)
    
  num_entries <- length(id_list)
  if( num_entries <= 1 ){
    stop("There must be two or more metagnomes in your list")
  }
  
  #id_metadata_matrix <- matrix(data=NA, nrow=num_entries, ncol=2) 
  
  for ( i in 1:num_entries){

    print(paste("Retrieving metadata for sample (", i, ") of", num_entries))
    
    # This bit is for auth of private data -- needs work - syntax is not correct
    if ( is.na(my_auth_file)==TRUE ){
      api_call <- paste("http://api.metagenomics.anl.gov/1/metadata/export/", id_list[i], sep="")
    }else{
      stop("auth not enabled in this script yet")
      #library(matR)
      #auth_key <- my_mgrast_key <- msession$setAuth(file=my_auth_file)
      #api_call <- paste("http://api.metagenomics.anl.gov/1/metadata/export/", id_list[i], "&auth=", auth_key, sep="")
    }
  
    if(debug==TRUE){print(api_call)}
    
    if( i == 1 ){ # what to do for the first entry
      
      first_call <- fromJSON(httpGET(api_call))
      flattened_first_call <- unlist(first_call, recursive=TRUE)
      metadata_matrix <- matrix(flattened_first_call)
      rownames(metadata_matrix) <- names(flattened_first_call)
      colnames(metadata_matrix) <- id_list[i]
      metadata_matrix <- data.frame(metadata_matrix)
      
    }else{ # what do do for the second entry
    
      next_call <- fromJSON(httpGET(api_call))
      flattened_next_call <- unlist(next_call, recursive=TRUE)
      
      temp_metadata_matrix <- matrix(flattened_next_call)
      rownames(temp_metadata_matrix) <- names(flattened_next_call)
      colnames(temp_metadata_matrix) <- id_list[i]
      temp_metadata_matrix <- data.frame(temp_metadata_matrix)
      
      metadata_matrix <- merge(temp_metadata_matrix,metadata_matrix,by="row.names",all=TRUE)
      rownames(metadata_matrix) <- metadata_matrix$Row.names
      metadata_matrix$Row.names <- NULL
    }
    
  }
  
  # change type back to matrix
  metadata_matrix <- as.matrix(metadata_matrix)
  
  # remove any carriage returns and tabs
  metadata_matrix <- gsub("\n", "", metadata_matrix)
  metadata_matrix <- gsub("\r", "", metadata_matrix)
  metadata_matrix <- gsub("\t", "", metadata_matrix)
  
  # print file if option was chosen
  if( is.na(output_file) == FALSE  ){
    output_name = paste(output_file, ".txt", sep="")
    export_data(metadata_matrix, output_name)
  }

  metadata_matrix <- rot90(metadata_matrix)
  return(metadata_matrix)

  if ( is.na(output_file) ){
    print("DONE retrieving metadata - make sure that you directed it to an output: my_metadata <- get_metadata(...)")
  }else{
    print(paste("DONE retrieving metadata, you'll find it in: ", output_name))
  }

}


# name the output object
#assign(new_object_name, object)


