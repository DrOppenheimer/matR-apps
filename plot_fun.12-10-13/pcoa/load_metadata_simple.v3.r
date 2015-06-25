load_metadata_simple.v3 <- function(metadata_table, sample_names, metadata_column=1, custom_pallete="default", debug=FALSE){


# THIS VERSION DOES NOT WORK YET _ USE v2
  
  my_metadata.matrix <- data.matrix(
                                         as.matrix(
                                                   read.table(
                                                              file=metadata_table,
                                                              row.names=1,
                                                              header=TRUE,
                                                              sep="\t",
                                                              colClasses = "character",
                                                              check.names=FALSE,
                                                              comment.char="",
                                                              quote="",
                                                              fill=TRUE,
                                                              blank.lines.skip=FALSE
                                                              )
                                                   )
                                         )


  metadata_column <-  my_metadata.matrix[, metadata_column, drop=FALSE] 
  metadata_column <- metadata_column[ sample_names,,drop=FALSE ] # order the metadata by sample 1d
    #metadata_column <- metadata_column[ order(rownames(metadata_column)),,drop=FALSE ] # order the metadata by value
  #color_column <- create_colors(metadata_column, custom_pallete, debug)



  my_colors.list <- create_colors(metadata_column, custom_pallete, debug)

#return(my_metadata.matrix)

 
  
  {return(list(metadata=my_metadata.matrix, colors=my_colors.list))}

  
}


######################
# SUB(9): Automtically generate colors from metadata with identical text or values
######################
create_colors <- function(metadata_column, custom_pallete, debug){ # function to     

  if( debug==TRUE ){ print("MADE IT HERE (SUB_9_0)") }
  
  my_data.color <- data.frame(metadata_column)
  column_factors <- as.factor(metadata_column[,1])
  column_levels <- levels(as.factor(metadata_column[,1]))
  num_levels <- length(column_levels)

  if( debug==TRUE ){ print("MADE IT HERE (SUB_9_1)") }
  
  if( identical(custom_pallete, "default") ){
    color_levels <- col.wheel(num_levels)
    if( debug==TRUE ){ print("MADE IT HERE (SUB_9_2a)") }
  }else{
    color_levels <- custom_pallete
    if( debug==TRUE ){ print("MADE IT HERE (SUB_9_2b)") }
  }

  if( debug==TRUE ){ print("MADE IT HERE (SUB_9_3)") }
  
  if(debug==TRUE){ test.color_levels <<- color_levels }

  levels(column_factors) <- color_levels
  my_data.color[,1]<-as.character(column_factors)

  if(debug==TRUE){ test.my_data.color <<- my_data.color }   
  
  return(my_data.color)
}


## create_colors <- function(color_matrix, custom_pallete, metadata_column, debug){ # function to     

##   if( debug==TRUE ){ print("MADE IT HERE (SUB_9_0)") }
  
##   my_data.color <- data.frame(color_matrix[,metadata_column])
##   if(debug==TRUE){
##     print(class(my_data.color))
##     print(dim(my_data.color))
##   }
  
##   ids <- rownames(color_matrix)
##   color_categories <- colnames(color_matrix)
##   #for ( i in 1:dim(color_matrix)[2] ){
##   column_factors <- as.factor(color_matrix[,metadata_column])
##   column_levels <- levels(as.factor(color_matrix[,metadata_column]))
##   num_levels <- length(column_levels)
    
##   if( identical(custom_pallete, "default") ){
##     color_levels <- col.wheel(num_levels)
##     if( debug==TRUE ){ print("MADE IT HERE (SUB_9_2a)") }
##   }else{
##     color_levels <- custom_pallete
##     if( debug==TRUE ){ print("MADE IT HERE (SUB_9_2b)") }
##   }

##     #if( length(levels(column_factors)) != color_levels ){
##     #  color_levels <- rep("black",  length(levels(column_factors)) )
##     #}
##   levels(column_factors) <- color_levels
##   #my_data.color[,i]<-as.character(column_factors)
##   my_data.color[,1]<-as.character(column_factors)
  
##   return(my_data.color)
## }
######################
######################


######################
# SUB(6): Create optimal contrast color selection using a color wheel
# adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html 
######################
col.wheel <- function(num_col, my_cex=0.75){ 
  cols <- rainbow(num_col)
  col_names <- vector(mode="list", length=num_col)
  for (i in 1:num_col){
    col_names[i] <- getColorTable(cols[i])
  }
  cols
}
######################
######################


######################
# SUB(7): The inverse function to col2rgb()
# adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
######################
rgb2col <- function(rgb) {
  rgb <- as.integer(rgb)
  class(rgb) <- "hexmode"
  rgb <- as.character(rgb)
  rgb <- matrix(rgb, nrow=3)
  paste("#", apply(rgb, MARGIN=2, FUN=paste, collapse=""), sep="")
}
######################
######################

  
######################
# SUB(8): Convert all colors into format "#rrggbb"
# adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
######################
getColorTable <- function(col) {
  rgb <- col2rgb(col);
  col <- rgb2col(rgb);
  sort(unique(col))
}
######################
######################
