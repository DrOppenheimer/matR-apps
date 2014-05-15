load_metadata_simple.v2 <- function(metadata_table){
    
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

  my_colors.matrix <- create_colors(my_metadata.matrix)

#return(my_metadata.matrix)

  {return(list(metadata=my_metadata.matrix, colors=my_colors.matrix))}

  
}




######################
# SUB(9): Automtically generate colors from metadata with identical text or values
######################
create_colors <- function(color_matrix, color_mode = "auto"){ # function to     
  my_data.color <- data.frame(color_matrix)
  ids <- rownames(color_matrix)
  color_categories <- colnames(color_matrix)
  for ( i in 1:dim(color_matrix)[2] ){
    column_factors <- as.factor(color_matrix[,i])
    column_levels <- levels(as.factor(color_matrix[,i]))
    num_levels <- length(column_levels)
    color_levels <- col.wheel(num_levels)
    levels(column_factors) <- color_levels
    my_data.color[,i]<-as.character(column_factors)
  }
  return(my_data.color)
}
######################
######################


######################
# SUB(6): Create optimal contrast color selection using a color wheel
# adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html 
######################
col.wheel <- function(num_col, my_cex=0.75) {
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
