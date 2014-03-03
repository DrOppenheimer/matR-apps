heatmap_to_file <<- function(my_heatmap, file_out="default"){

  if ( identical(file_out, "default")==TRUE ){
    file_out <- paste( deparse(substitute(my_heatmap)), ".sorted_data", sep="", collapse="")
  }

  
  #(my_heatmap)$call$x
  
  sorted_matrix <- my_heatmap$call$x

  sorted_matrix <- sorted_matrix[ my_heatmap$rowInd ,  my_heatmap$colInd ]
  
  sorted_matrix <- sorted_matrix[ nrow(sorted_matrix):1, ] 
  
  write.table(sorted_matrix, file = file_out, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
##   num_rows <- nrow(my_heatmap$call$x)
##   num_cols <- ncol(my_heatmap$call$x)

##   sorted_matrix <- 
  


## labCol
## labRow


## $colInd


## $carpet

## $call$labCol$x
## $call$labCol
## $call$labRow

## x
## labRow
## labCol



  


}
