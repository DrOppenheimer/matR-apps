sort_check_data_metadata <- function(data_file="sample_data.txt", metadata_file="sample_metadata.txt"){
  
  import_data <- function(file_name){
    data.matrix(read.table(file_name, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
  }

  export_data <- function(data_object, file_name){
    write.table(data_object, file=file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
  }
  
  # create names for output sorted and edited data
  data_matrix.edit.name <- paste(data_file,".sorted_checked.txt", sep="", collapse="")
  metadata_matrix.edit.name <- paste(metadata_file,".sorted_checked.txt", sep="", collapse="")
  
  data_matrix <- import_data(data_file)
  data_matrix <- data_matrix[ ,order(colnames(data_matrix)),drop=FALSE ] # make sure that the data matrix is sorted columnwise by id

  metadata_matrix <- as.matrix( # Load the metadata table (same if you use one or all columns)
                               read.table(
                                          file=metadata_file,row.names=1,header=TRUE,sep="\t",
                                          colClasses = "character", check.names=FALSE,
                                          comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                          )
                               )   
  metadata_matrix <- metadata_matrix[ order(rownames(metadata_matrix)),,drop=FALSE ]  # make sure that the metadata matrix is sorted (ROWWISE) by id

  data_ids <- colnames(data_matrix)
  metadata_ids <- rownames(metadata_matrix)
  
  ids_in_both <<- intersect(data_ids, metadata_ids)
  ids_in_both <- ids_in_both[ order(ids_in_both) ]
  
  ids_only_in_data <<- setdiff(data_ids, metadata_ids) 
  
  ids_only_in_metadata <<- setdiff(metadata_ids,data_ids)

  if( length(ids_only_in_data)>0 || length(ids_only_in_metadata) ){

    print("ids in data and metadata do not match - creating new data and metadata files with only matching ids, and list of those not in both")

    data_matrix.edit <- matrix(,nrow(data_matrix),length(ids_in_both))
    rownames(data_matrix.edit)<-rownames(data_matrix)
    colnames(data_matrix.edit)<-ids_in_both
    for( i in 1:length(ids_in_both) ){
      data_matrix.edit[,i] <- data_matrix[,ids_in_both[i],drop=FALSE]
    }
    export_data(data_matrix.edit, data_matrix.edit.name)
    
    metadata_matrix.edit <- matrix(,length(ids_in_both),ncol(metadata_matrix))
    rownames(metadata_matrix.edit)<-ids_in_both
    colnames(metadata_matrix.edit)<-colnames(metadata_matrix)
    for( j in 1:length(ids_in_both) ){
      metadata_matrix.edit[j,] <- metadata_matrix[ids_in_both[j],]
    }
    export_data(metadata_matrix.edit,metadata_matrix.edit.name)   

    library(plyr)
    not_paired.list <- list(data.frame(ids_only_in_data), data.frame(ids_only_in_metadata))
    not_paired.matrix <- as.matrix(do.call(rbind.fill, not_paired.list))
    export_data(not_paired.matrix,"ids_not_in_both.txt")
    
  }else{
  
    print("ids in data and metadata match - exporting sorted data and metadata files")
    export_data(data_matrix, data_matrix.edit.name)
    export_data(metadata_matrix,metadata_matrix.edit.name)
    
  }

}


  





  
## [1] FALSE  TRUE FALSE
## > intersect(A,B)
## [1] "Cat"
## > setdiff(A,B)
## [1] "Dog"   "Mouse"
## > setdiff(B,A)
## [1] "Tiger" "Lion" 


  

## xtab_set <- function(A,B){
##     both    <-  union(A,B)
##     inA     <-  both %in% A
##     inB     <-  both %in% B
##     return(table(inA,inB))

  



##   if( ncol(data_matrix) != row(metadata_matrix) ){
##     # message
##     print("met")

    
## }



    
##     # eliminate data that isn't in both

##     # write outputs

##     # simple message


##   }else{
##     # write sorted outputs

##     # simple message
    
##   }
  
  
## }
