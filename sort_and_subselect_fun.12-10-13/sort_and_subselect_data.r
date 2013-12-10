# simple function to sort a matrix with a single line header by values in selected column

sort_and_subselect_data <<- function(
                                     file_in,
                                     file_out="default",
                                     sort_column="last",
                                     decreasing_sort = FALSE,
                                     first_n_rows = 0, # count ingores header row
                                     first_n_cols = 0  # count ignores header column
                                     )
  
{
  
###### assign default output name if none other is given  
  if ( identical(file_out, "default") ){
    file_out <- paste(file_in, ".sorted.txt", sep="", collapse="")
  }

###### load the data  
  matrix_in <- data.matrix(read.table(file_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))

##### make sure selected sort column exists
  if( sort_column > ncol(matrix_in) ) { stop(paste("There are only (", ncol(matrix_in), ") columns in the data, and column (", sort_column,") was selected to sort the data.")) }

#### make sure row and col selections exist
  if ( first_n_rows > nrow(matrix_in) ){ stop(paste("There are only (", nrow(matrix_in), ") rows in the data, and the first (", first_n_rows,") were selected.")) }
  if ( first_n_cols > ncol(matrix_in) ){ stop(paste("There are only (", ncol(matrix_in), ") columns in the data, and the first (", first_n_cols,") were selected.")) }
    
##### sort the data by the selected column
  if( identical( sort_column, "last") ){
    sort_column = ncol(matrix_in)
  }
  matrix_in.sorted <- matrix_in[ order(matrix_in[,sort_column], decreasing=decreasing_sort), ]

##### select first_n_rows if option is > 0
  if ( first_n_rows > 1 ){
    matrix_in.sorted.first_n_rows <- matrix_in.sorted[ 1:first_n_rows , ]
    matrix_in.sorted <- matrix_in.sorted.first_n_rows
  }

##### select first_n_cols if option is > 0 # use this to remove stats etc from data for viz (heatdend, pcoa, parallel coord) 
  if ( first_n_cols > 1 ){
    matrix_in.sorted.first_n_cols <- matrix_in.sorted[ , 1:first_n_cols ]
    matrix_in.sorted <- matrix_in.sorted.first_n_cols
  }  

##### export sorted and subselected data
  write.table(
              matrix_in.sorted,
              file = file_out,
              col.names=NA,
              sep="\t",
              quote=FALSE
              )                                   
  
}

