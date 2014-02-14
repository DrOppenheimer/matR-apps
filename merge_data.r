merge_data <- function(mode="file", file1="", file2="", output="default"){

  if( identical( output, "default" )==TRUE ){
    output <- paste( file1, ".AND.", file2 ,sep="", collapse="" )
  }
  
  # can merge from flat file or data matrices
  if ( identical(mode, "file")==TRUE ){
    data1 = import_data(file1)
    data2 = import_data(file2)
  }else{
    data1 <- file1
    data2 <- file2
  }
  
  merged_data <- merge(data1, data2, by="row.names", all=TRUE)
  
  write.table(merged_data, file = output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

}

#### SUBS
import_data <- function(file_name)
{
  data.matrix(read.table(file_name, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
}
