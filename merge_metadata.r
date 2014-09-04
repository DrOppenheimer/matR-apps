merge_metadata <- function(file1="", file2="", output="default", play_safe=FALSE){

  # generate a default output name
  if( identical( output, "default" )==TRUE ){
    output <- paste( file1, ".AND.", file2,".merged_metadata.txt" ,sep="", collapse="" )
  }

  # import data
  metadata.matrix.1 <- import_metadata(file1)
  metadata.matrix.2 <- import_metadata(file2)

  # find row names that are unique to each file and found in both
  rownames_in.1.only <- setdiff( rownames(metadata.matrix.1), rownames(metadata.matrix.2) )
  rownames_in.2.only <- setdiff( rownames(metadata.matrix.2), rownames(metadata.matrix.1) )
  rownames_in_both <- intersect( rownames(metadata.matrix.1), rownames(metadata.matrix.2) )

  # die if there are rownames in common between the two files
  if( length(rownames_in_both) > 0 ){
    stop( paste("error - there are rownames in common between the two files:", rownames_in_both) )
  }

  # count the number of rows between the two matrices
  sum_rownames <- length(rownames_in.1.only) + length(rownames_in.2.only)

  #determine if colnames within each matrix are unique
  num_columns.file1 <- ncol(metadata.matrix.1)
  num_col_levels.file1 <- length(levels(as.factor(colnames(metadata.matrix.1))))
  if ( num_columns.file1 != num_col_levels.file1){ warning(paste("column names in", file1, "are not unique")) }

  num_columns.file2 <- ncol(metadata.matrix.2)
  num_col_levels.file2 <- length(levels(as.factor(colnames(metadata.matrix.2))))
  if ( num_columns.file2 != num_col_levels.file2){ warning(paste("column names in", file2, "are not unique")) }
    
  # find column names that are unique to each file and found in both
  colnames_in.1.only <- setdiff( colnames(metadata.matrix.1), colnames(metadata.matrix.2) )
  colnames_in.2.only <- setdiff( colnames(metadata.matrix.2), colnames(metadata.matrix.1) )
  colnames_in_both <- intersect( colnames(metadata.matrix.1), colnames(metadata.matrix.2) )

  # figure out number of unique columns in output
  sum_colnames <- length(colnames_in_both) + length(colnames_in.1.only) + length(colnames_in.2.only)

  # create output matrix
  merged_matrix <- matrix(NA, sum_rownames, sum_colnames)

  # specify row and column names for output matrix
  rownames(merged_matrix) <- c(rownames_in.1.only, rownames_in.2.only)
  colnames(merged_matrix) <- c(colnames_in_both, colnames_in.1.only, colnames_in.2.only)

  # load data from the originals
  merged_matrix <- load_matrix(metadata.matrix.1, merged_matrix, play_safe)
  merged_matrix <- load_matrix(metadata.matrix.2, merged_matrix, play_safe)
  
  # write output  
  write.table(merged_matrix, file = output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  
}



load_matrix <- function(my_matrix, merged_matrix, play_safe){
  
  for (i in 1:nrow(my_matrix) ){
    for (j in 1:ncol(my_matrix) ){
      
      if( play_safe==TRUE ){
        if( !is.na( merged_matrix[ rownames(my_matrix)[i], colnames(my_matrix)[j] ] ) ){
          stop("ERROR: about to overwrite an existing value")
        }
      }else{
        if( !is.na( merged_matrix[ rownames(my_matrix)[i], colnames(my_matrix)[j] ] ) ){
          print(paste("overwriting an exisiting value, row:", rownames(my_matrix)[i], "column:", colnames(my_matrix)[j], "value:", my_matrix[i,j] ))
        }
      }
      
      merged_matrix[ rownames(my_matrix)[i], colnames(my_matrix)[j] ] <- my_matrix[i,j]
      
    }
  }
  return(merged_matrix)
}



  


 
