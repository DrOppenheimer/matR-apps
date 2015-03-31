
get_mgrast_metadata <- function(
                                mgid_list="mgrast_ids.txt",
                                use_auth=TRUE,
                                auth="~/my_auth_key.txt",
                                output_file="metadata_out.txt",
                                verbose=FALSE,
                                debug=FALSE
                                ){

  # load packages
  require(matR) 
  require(RJSONIO)
  require(RCurl)
  require(plyr)

# Still have to pull out some of the other stats that appear in the browse page -- must be in other parts of the API - not metadata ....


  
  # get auth toekn from file if option is selected
  #if (use_auth==TRUE){
  #  my_auth <- scan(file=auth, what="character")
  #}

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

  # pick out just the ones in browse
#[1] "mixs_compliant"                                                      
# [2] "job_id"                                                              
# [3] "project1"                                                            
# [4] "project2"                                                            
# [5] "version"                                                             
# [6] "status"                                                              
# [7] "name"                                                                
# [8] "sequence_type"                                                       
# [9] "library1"                                                            
#[10] "library2"                                                            
#[11] "created"                                                             
#[12] "pipeline_version"                                                    
#[13] "url"                                                                 
#[14] "metadata.env_package.name"                                           
#[15] "metadata.env_package.type"                                           
#[16] "metadata.env_package.data.body_site"                                 
#[17] "metadata.env_package.data.env_package"                               
#[18] "metadata.env_package.data.sample_name"                               
#[19] "metadata.env_package.id"                                             
#[20] "metadata.project.public"                                             
#[21] "metadata.project.name"                                               
#[22] "metadata.project.data.firstname"                                     
#[23] "metadata.project.data.misc_param"                                    
#[24] "metadata.project.data.PI_firstname"                                  
#[25] "metadata.project.data.PI_organization_url"                           
#[26] "metadata.project.data.lastname"                                      
#[27] "metadata.project.data.organization_url"                              
#[28] "metadata.project.data.email"                                         
#[29] "metadata.project.data.PI_organization_address"                       
#[30] "metadata.project.data.PI_lastname"                                   
#[31] "metadata.project.data.organization_country"                          
#[32] "metadata.project.data.project_name"                                  
#[33] "metadata.project.data.PI_email"                                      
#[34] "metadata.project.data.organization"                                  
#[35] "metadata.project.data.administrative-contact_PI_email"               
#[36] "metadata.project.data.project_funding"                               
#[37] "metadata.project.data.PI_organization"                               
#[38] "metadata.project.data.administrative-contact_PI_organization"        
#[39] "metadata.project.data.administrative-contact_PI_organization_country"
#[40] "metadata.project.data.administrative-contact_PI_organization_address"
#[41] "metadata.project.data.administrative-contact_PI_organization_url"    
#[42] "metadata.project.data.project-description_project_name"              
#[43] "metadata.project.data.PI_organization_country"                       
#[44] "metadata.project.data.organization_address"                          
#[45] "metadata.project.data.project-description_project_description"       
#[46] "metadata.project.data.project_description"                           
#[47] "metadata.project.id"                                                 
#[48] "metadata.library.name"                                               
#[49] "metadata.library.type"                                               
#[50] "metadata.library.data.misc_param"                                    
#[51] "metadata.library.data.metagenome_id"                                 
#[52] "metadata.library.data.seq_meth"                                      
#[53] "metadata.library.data.seq_center"                                    
#[54] "metadata.library.data.metagenome_name"                               
#[55] "metadata.library.data.file_name"                                     
#[56] "metadata.library.data.file_checksum"                                 
#[57] "metadata.library.data.sample_name"                                   
#[58] "metadata.library.data.seq_model"                                     
#[59] "metadata.library.data.investigation_type"                            
#[60] "metadata.library.data.seq_url"                                       
#[61] "metadata.library.id"                                                 
#[62] "metadata.sample.name"                                                
#[63] "metadata.sample.data.country"                                        
#[64] "metadata.sample.data.misc_param"                                     
#[65] "metadata.sample.data.collection_date"                                
#[66] "metadata.sample.data.feature"                                        
#[67] "metadata.sample.data.env_package"                                    
#[68] "metadata.sample.data.continent"                                      
#[69] "metadata.sample.data.sample_name"                                    
#[70] "metadata.sample.data.biome"                                          
#[71] "metadata.sample.data.material"                                       
#[72] "metadata.sample.data.temperature"                                    
#[73] "metadata.sample.id"                                                  
#[74] "pipeline_parameters.priority"                                        
#[75] "pipeline_parameters.assembled"                                       
#[76] "pipeline_parameters.min_qual"                                        
#[77] "pipeline_parameters.rna_pid"                                         
#[78] "pipeline_parameters.fgs_type"                                        
#[79] "pipeline_parameters.prefix_length"                                   
#[80] "pipeline_parameters.aa_pid"                                          
#[81] "pipeline_parameters.max_lqb"                                         
#[82] "pipeline_parameters.m5nr_sims_version"                               
#[83] "pipeline_parameters.m5nr_annotation_version"                         
#[84] "pipeline_parameters.dynamic_trim"                                    
#[85] "pipeline_parameters.m5rna_annotation_version"                        
#[86] "pipeline_parameters.file_type"                                       
#[87] "pipeline_parameters.m5rna_sims_version"                              
#[88] "pipeline_parameters.bowtie"                                          
#[89] "pipeline_parameters.dereplicate"                                     
#[90] "pipeline_parameters.screen_indexes"                                  
#[91] "sample1"                                                             
#[92] "sample2"                                                             
#[93] "id" 






  
  # add names
  #my_metadata_matrix.test <<- my_metadata_matrix
  rownames(my_metadata_matrix) <- mgid_list
  #my_metadata_matrix.test2 <<- my_metadata_matrix
  
  # export metadata to file
  export_data(my_metadata_matrix, output_file)
                                     
}

get_single_metagenome_metadata <- function(mgid, use_auth, auth, debug){

  
  
  if ( use_auth==TRUE ){
    my_auth <- scan(file=auth, what="character")
    if( debug==TRUE ){ print(paste("auth:", auth)) }
    my_call <- paste("http://api.metagenomics.anl.gov//metagenome/", mgid, "?verbosity=metadata&auth=", my_auth, sep="", collapse="")
    if( debug==TRUE ){ print(paste("my_call:", my_call)) }
  }else{
    my_call <- paste("http://api.metagenomics.anl.gov//metagenome/", mgid, "?verbosity=metadata", sep="", collapse="")
    if( debug==TRUE ){ print(paste("my_call:", my_call)) }
  }
  
  my_api.call <- fromJSON(getURL(my_call))
  flat_list <- unlist(my_api.call)
  flat_list <- gsub("\r","",flat_list)
  flat_list <- gsub("\n","",flat_list)
  flat_list <- gsub("\t","",flat_list)
  col_names <- names(flat_list)
  col_names.test <<- col_names
  num_col <- length(flat_list)
  row_name <- flat_list['id']
  row_name.test <<- row_name
  #edited_list <- flat_list[which(names(flat_list) %in% c("metadata.project.data.project_description"))] <- NULL
  #edited_list <- flat_list$metadata.project.data.project_description <- NULL
  #colnames(my_metadata_matrix) <- col_names
  #rownames(my_metadata_matrix) <- row_name
  #my_metadata_matrix <- as.matrix(flat_list, nrow=1, ncol=length(flat <- list))

  my_metadata_matrix <- matrix(flat_list, ncol = num_col, byrow = FALSE)

  
  
  colnames(my_metadata_matrix) <- col_names
  rownames(my_metadata_matrix) <- row_name

  #df[ , -which(names(df) %in% c("z","u"))]
#df[,-which(names(df)=="X2")] 
  #my_metadata_matrix <- my_metadata_matrix[ ,-which(names(my_metadata_matrix)=="metadata.project.data.project_description")]
  
  #my_metadata_matrix <- my_metadata_matrix[,-c('metadata.project.data.project_description')] #<- NULL
  
  my_metadata_matrix.test <<- my_metadata_matrix


  #output <- matrix(unlist(z), ncol = 10, byrow = TRUE)


                                        #edited_list.test <<- edited_list
  #myList[which(names(myList) %in% c("two","three"))] <- NULL


  #edited_list <-flat_list[-'metadata.project.data.project_description']
    
#metadata.project.data.project_description
  
  #unlist.test <<- unlist(my_api.call)

  #my_metadata_matrix <- matrix(unlist(my_api.call), nrow=1, ncol=length(unlist(my_api.call)))
  #colnames(my_metadata_matrix) <- names(unlist(my_api.call))
  #rownames(my_metadata_matrix) <- (unlist(my_api.call))['id']
  return(my_metadata_matrix)
}
 
export_data <- function(data_object, file_name){
  write.table(data_object, file=file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
}



  
