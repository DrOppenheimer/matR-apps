download_for_qiime <- function(mgid_list="/Users/kevin/test_id_list.txt", my_file_id="100.2", my_unzip_file=TRUE, mapping_file="/Users/kevin/test_dir/test_mapping.txt", my_destination_dir="/Users/kevin/test_dir", output_filename="my_combined_seqs.fna", add_qiime_labels=TRUE, debug=TRUE){  
  
  require(matR)
  require(RCurl)
  require(RJSONIO)
  
  my_ids <- readIDs(mgid_list)
  
  # create the mapping file, write its header - also create matrix to hold data that will be written to it
  if( !is.na(mapping_file) ){
    file.create(file.path(mapping_file), showWarnings = FALSE)
    writeLines("#SampleID\tBarcodeSequence\tLinkerPrimerSequence\tInputFileName\tDescription", con=mapping_file)
    mapping_matrix <- matrix("",length(my_ids),5)
  }
  
  # perform the downloads and create a mapping file
  for (i in 1:length(my_ids)){
    new_file_name <- download_file(mgid=my_ids[i], file_id=my_file_id, unzip_file=my_unzip_file, destination_dir=my_destination_dir, debug=debug )
    if( !is.na(mapping_file) ){
      mapping_matrix[i,1]<-my_ids[i]
      mapping_matrix[i,4]<-new_file_name
      mapping_matrix[i,5]<-my_ids[i]
    }
  }
  
  # write the rest of the mapping file
  if( !is.na(mapping_file) ){
    write.table(mapping_matrix, file=mapping_file, append=TRUE, sep="\t", row.names=FALSE, col.names=FALSE)
  }
  
  # Use qiime add_qiime_labels.py to create input for qiime (fasta, mapping is the other input) 
  if( add_qiime_labels==TRUE ){
    
    #output_dir <- paste(my_destination_dir, "/", "add_qiime_labels.output", sep="")
    add_qiime_labels.string <- paste("add_qiime_labels.py -i ", my_destination_dir,
                                     " -m ", mapping_file,
                                     " -o ", my_destination_dir,
                                     " -c InputFileName",
                                     sep=""
                                     )
    if( debug==TRUE ){ print(cat("\n\n", "add_qiime_labels.string:","\n", add_qiime_labels.string, "\n\n"))  }
    system(add_qiime_labels.string)
    # rename the file from qiimes default
    rename_string <- paste("mv ", my_destination_dir, "/combined_seqs.fna ", my_destination_dir, "/", output_filename)
    if(debug=TRUE){ print(rename_string) }
    system(rename_string)
    
  }

  
  
    
}
