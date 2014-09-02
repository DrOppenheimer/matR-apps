merge_metadata <- function(file1="", file2="", output="default", duplicate_log = "default"){
  
  if( identical( output, "default" )==TRUE ){
    output <- paste( file1, ".AND.", file2,".merged_metadata.txt" ,sep="", collapse="" )
  }
  
  metadata.matrix.1 <- import_metadata(file1)
  metadata.matrix.2 <- import_metadata(file2)
  
  rownames_in.1.only <- rownames(metadata.matrix.1)
  rownames_in.2.only <- rownames(metadata.matrix.2)
  rownames_in_both <- intersect(rownames_in.1.only, rownames_in.2.only)
  
  if( length(rownames_in_both) > 0 ){
    stop( paste("error - there are rownames in common between the two files:", rownames_in_both) )
  }
  
  sum_rownames <- length(rownames_in.1.only) + length(rownames_in.2.only)
  
  colnames_in.1.only <- colnames(metadata.matrix.1)
  colnames_in.2.only <- colnames(metadata.matrix.2)
  colnames_in_both <- intersect(colnames_in.1.only, colnames_in.2.only)
  
  sum_colnames <- length(colnames_in_both) + length(colnames_in.1.only) + length(colnames_in.2.only)
  
  merged_matrix <- matrix(NA, sum_rownames, sum_colnames)
  
  rownames(merged_matrix) <- c(rownames_in.1.only, rownames_in.2.only)
  colnames(merged_matrix) <- c(colnames_in_both, colnames_in.1.only, colnames_in.2.only)
  
  for (i in 1:nrow(my_matrix) ){
    for (j in 1:ncol(my_matrix) ){
      
      if ( !is.na( my_matrix[i,j]) ){
        stop("ERROR - about to overwrite an exisiting value")
      }
      
      merged_matrix[ rownames(my_matrix)[i], colnames(my_matrix)[j] ] <- my_matrix[i,j]
      
      
    }
  }

  write.table(merged_data, file = output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  
}

  


  


 
