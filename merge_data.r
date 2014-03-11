merge_data <- function(mode="file", file1="", file2="", output="default", duplicate_log = "default"){

  

# duplicated()
  

  
  
  if( identical( output, "default" )==TRUE ){
    output <- paste( file1, ".AND.", file2,".data" ,sep="", collapse="" )
  }
  
  # can merge from flat file or data matrices
  if ( identical(mode, "file")==TRUE ){
    data1 <- import_data(file1)
    data2 <- import_data(file2)
  }else{
    data1 <- file1
    data2 <- file2
  }
  
  merged_data <- merge(data1, data2, by="row.names", all=TRUE, suffixes=(c("rep1","rep2")))
  rownames(merged_data) <- merged_data$Row.names
  merged_data$Row.names <- NULL

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
