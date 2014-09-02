merge_data <- function(mode="file", data_type = "data", file1="", file2="", output="default", duplicate_log = "default"){

  

# duplicated()
  

  
  
  if( identical( output, "default" )==TRUE ){
    output <- paste( file1, ".AND.", file2,".data" ,sep="", collapse="" )
  }
  
  # can merge from flat file or data matrices
  if ( identical(mode, "file")==TRUE ){
    if (identical(data_type, "data")){
      data1 <- import_data(file1)
      data2 <- import_data(file2)
    }else if (identical(data_type, "metadata")){
      data1 <- import_metadata(file1)
      data2 <- import_metadata(file2)
    }else{
      stop(paste("invalid data_type(", data_type, ") please use \"data\" or \"metadata\""))
    }
  }else{
    data1 <- file1
    data2 <- file2
  }

  if  (identical(data_type, "data")){
    merged_data <- merge(data1, data2, by="row.names", all=TRUE, suffixes=(c("rep1","rep2")))
    rownames(merged_data) <- merged_data$Row.names
    merged_data$Row.names <- NULL
  }else if (identical(data_type, "metadata")){
    merged_data <- merge(data1, data2, by="col.names", all=TRUE, suffixes=(c("rep1","rep2")))
    rownames(merged_data) <- merged_data$Row.names
    merged_data$Row.names <- NULL
  }else{
    stop(paste("invalid data_type(", data_type, ") please use \"data\" or \"metadata\""))
  }

  ## # determine if there are dupilcate datasets -- report if there are
  ## duplicate_entries <- duplicated( c( dimnames(data1)[2], dimnames(data2)[2] ) )
  ## if ( length(duplicate_entries) > 0 ){
  ##   if ( identical( duplicate_log, "default" )==TRUE ){
  ##     duplicate_log <- paste( file1, ".AND.", file2,".duplicate_log" ,sep="", collapse="" )
  ##   }
  ##   write.table( as.matrix(duplicate_entries, ncol=1), file = duplicate_log, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE ) 
  ## }
  
  # non optional, convert "na's" to 0
    merged_data[is.na(merged_data)] <- 0
  
  # write output
  write.table(merged_data, file = output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

}

#### SUBS
import_data <- function(file_name)
{
  data.matrix(read.table(file_name, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
}


import_metadata <- function(file_name){

  metadata_matrix <- as.matrix( # Load the metadata table (same if you use one or all columns)
                              read.table(
                                         file=file_name,row.names=1,header=TRUE,sep="\t",
                                         colClasses = "character", check.names=FALSE,
                                         comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                         )
                              ) 
}


