create_colors <- function(file_name, color_mode = "auto"){
# scripts to generate color vectors for PCoA --
# input is tab delimited table - rows are samples, columns correspond to metadata to color by
# auto will generate colors from any arbitrary numbers or text
# color_mode set to anything other than "auto" will try to use the text in the table
# as colors.
# output of this script is a table hard coded as my_data.color
# use column referencing of this table to color PCoA
# Example
# data_location	/Users/kevin/Documents/Projects/Stuff_for_Others/Dion/tax_filtering_func.Oct_2013
## data_file			dion_SS_data.tax_filtered.terminal_annotation_only.txt
## colors_file		test_colors.txt

## # go to the directory with the data
## setwd("/Users/kevin/Documents/Projects/Stuff_for_Others/Dion/tax_filtering_func.Oct_2013")



## # import the data
## my_data <- data.matrix(read.table("dion_SS_data.tax_filtered.terminal_annotation_only.txt", row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))

## # import the script to generate the colors
## source("~/bin/create_colors2.r")

## # generate the colors matrix
## create_colors("test_colors.txt")

## # make sure that colors are in the same order as the data # VERY IMPORTANT
## my_data.color <- my_data.color[ colnames(my_data), ]

## # Generate pcoa colored by first column in colors matrix
## pco(my_data,col=my_data.color[,1],comp=c(1,2),labels="",main="")
## pco(my_data,color=my_data.color[,1]=c(1,2,3),labels="",main="")


## # had to do this - matR pco would not work for some reason
## plot_pcoa.from_object(my_data, colors=my_data.color[,2])

  
# SUBS
############################################################################
# Color methods https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
############################################################################
# The inverse function to col2rgb()
  col.wheel <- function(num_col, my_cex=0.75) {
    cols <- rainbow(num_col)
    col_names <- vector(mode="list", length=num_col) 
    for (i in 1:num_col){
      col_names[i] <- getColorTable(cols[i])
    }
    # pie(rep(1, length(cols)), labels=col_names, col=cols, cex=my_cex) }
    cols
  }
  
  
  
  # The inverse function to col2rgb()
  rgb2col <- function(rgb) {
    rgb <- as.integer(rgb)
    class(rgb) <- "hexmode"
    rgb <- as.character(rgb)
    rgb <- matrix(rgb, nrow=3)
    paste("#", apply(rgb, MARGIN=2, FUN=paste, collapse=""), sep="")
  }

  # Convert all colors into format "#rrggbb"
  getColorTable <- function(col) {
    rgb <- col2rgb(col);
    col <- rgb2col(rgb);
    sort(unique(col))
  }
  
# MAIN  
############################################################################  
  my_data <- read.table(file_name, header=TRUE, stringsAsFactors=FALSE )
  
  my_data.color <<- my_data
  
  if ( identical( color_mode, "auto") ==TRUE ){
    
    ids <- rownames(my_data)
    color_categories <- colnames(my_data)
    
    for ( i in 1:dim(my_data)[2] ){
      
      column_factors <- as.factor(my_data[,i])
      
      column_levels <- levels(as.factor(my_data[,i]))
      num_levels <- length(column_levels)
      
      color_levels <- col.wheel(num_levels)
      
      levels(column_factors) <- color_levels
      
      my_data.color[,i]<<-as.character(column_factors)

    }
    
  }else{

    for ( i in 1:dim(my_data)[2] ){
      my_data.color[,i]<<-as.character(my_data.color[,i])
    }
  
  }
 

  


}


