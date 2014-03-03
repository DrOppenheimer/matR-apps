# This script uses matR to generate 2 or 3 dimmensional pcoas

# table_in is the abundance array as tab text -- columns are samples(metagenomes) rows are taxa or functions
# color_table and pch_table are tab tables, with each row as a metagenome, each column as a metadata 
# grouping/coloring. These tables are used to define colors and point shapes for the plot
# It is assumed that the order of samples (left to right) in table_in is the same
# as the order (top to bottom) in color_table and pch_table

# basic operation is to produce a color-less pcoa of the input data

# user can also input a table to specify colors
# This table can contain colors (as hex or nominal) or can contain metadata
# that is automatically interpreted to produce coloring (identical values or text receive the same color
# 
# The user can also input a pch table -- this is more advanced R plotting that allows them to 
# select the shape of the plotted points
#
# example invocations are below - going from simplest to most elaborate

# create a 3d plot, minimum input arguments:
#   plot_mg_pcoa(table_in="test_data.txt")

# create a 2d plot, minimum input arguments:
#   plot_mg_pcoa(table_in="test_data.txt", plot_pcs = c(1,2))

# create a 3d plot with colors specified by a color_table file 
# (by default, first column of color table is used) and the script expecpts
# entries to be literal or hex colors:
#   plot_mg_pcoa(table_in="test_data.txt", color_table="test_colors.txt")

# create a 3d plot with colors generated from the color_table, using second column in color table
# specify option to generate colors from the table (any metadata will work)
# specify that the second column is used:
#   plot_mg_pcoa(table_in="test_data.txt", color_table="test_colors.txt", auto_colors=TRUE, color_column=2)

# create a plot where every input argument is explicitly addressed:
#   plot_mg_pcoa(table_in="test_data.txt", image_out = "wacky_pcoa", plot_pcs = c(1,3,5), label_points=NA, color_table="test_colors.txt", auto_colors=TRUE, color_column=3, pch_table="test_pch.txt", pch_column=3, image_width_in=10, image_height_in=10, image_res_dpi=250)
 
render_pcoa <<- function(
                         PCoA_in="test.PCoA", # annotation abundance table (raw or normalized values)
                         
                         image_out="default",
                         figure_main ="principal coordinates",
                         components=c(1,2,3), # R formated string telling which coordinates to plot, and how many (2 or 3 coordinates)
                            ## dist_metric="euclidean", # distance metric to use one of (bray-curtis, euclidean, maximum, manhattan, canberra, minkowski, difference)
                         label_points=FALSE, # default is off
                         
                         metadata_table="test.metadata", # matrix that contains colors or metadata that can be used to generate colors
                         metadata_column=1, # column of the color matrix to color the pcoa (colors for the points in the matrix) -- rows = samples, columns = colorings
                         color_list=NA, # use explicit list of colors - trumps table if both are supplied
                         pch_table=NA, # additional matrix that allows users to specify the shape of the data points
                         pch_column=1,
                         
                         image_width_in=12,
                         image_height_in=10,
                         image_res_dpi=300,
                         width_legend = 0.4, # fraction of width used by legend
                         width_figure = 0.6, # fraction of width used by figure
                         legend_cex = 0.5, # cex for the legend
                         fig_cex = 0.7, # cex for the figure
                         use_all_metadata_columns=FALSE, # option to overide color_column -- if true, plots are generate for all of the metadata columns
                         debug=TRUE
                         )
  
{
  

  # function load data
  # function load metadata
  # functoin load pch
  # function plot


  
  require(matR)
  ######### First - read the PCoA results into R objects
  con_1 <- file(PCoA_in)
  con_2 <- file(PCoA_in)

  # read through the first time to get the number of samples
  open(con_1);
  num_values <- 0
  data_type = "NA"
  while ( length(my_line <- readLines(con_1,n = 1, warn = FALSE)) > 0) {
    if ( length( grep("PCO", my_line) ) == 1  ){
      num_values <- num_values + 1
    }
  }
  close(con_1)

  # create object for values
  eigen_values <- matrix("", num_values, 1)
  dimnames(eigen_values)[[1]] <- 1:num_values
  eigen_vectors <- matrix("", num_values, num_values)
  dimnames(eigen_vectors)[[1]] <- 1:num_values
  
 # read through a second time to populate the R objects
  value_index <- 1
  vector_index <- 1
  open(con_2)
  current.line <- 1
  data_type = "NA"
  while ( length(my_line <- readLines(con_2,n = 1, warn = FALSE)) > 0) {
    if ( length( grep("#", my_line) ) == 1  ){
      if ( length( grep("EIGEN VALUES", my_line) ) == 1  ){
        data_type="eigen_values"
      } else if ( length( grep("EIGEN VECTORS", my_line) ) == 1 ){
        data_type="eigen_vectors"
      }
    }else{
      split_line <- noquote(strsplit(my_line, split="\t"))
      if ( identical(data_type, "eigen_values")==TRUE ){
        dimnames(eigen_values)[[1]][value_index] <- noquote(split_line[[1]][1])
        eigen_values[value_index,1] <- noquote(split_line[[1]][2])       
        value_index <- value_index + 1
      }
      if ( identical(data_type, "eigen_vectors")==TRUE ){
        dimnames(eigen_vectors)[[1]][vector_index] <- noquote(split_line[[1]][1])
        for (i in 2:(num_values+1)){
          eigen_vectors[vector_index, (i-1)] <- as.numeric(noquote(split_line[[1]][i]))
        }
        vector_index <- vector_index + 1
      }
    }
  }
  close(con_2)

  # finish labeling of data objects
  dimnames(eigen_values)[[2]] <- "EigenValues"
  dimnames(eigen_vectors)[[2]] <- dimnames(eigen_values)[[1]]
  class(eigen_values) <- "numeric"
  class(eigen_vectors) <- "numeric"

  # create globals of the imported data
  eigen_values <<- eigen_values
  eigen_vectors <<- eigen_vectors
  
#}


  
############### GET THE METADATA AND PRODUCE COLORS

  if(debug==TRUE){ print(paste("is.na(metadata_table) :: ", is.na(metadata_table), sep="", collapse="")) }

  if ( identical( is.na(metadata_table), FALSE ) ){


    if( debug==TRUE ){ print("POOP") }
  # generate auto colors if the color matrix contains metadata and not colors
    color_matrix <- as.matrix(
                              read.table(
                                         file=metadata_table,
                                         row.names=1,
                                         header=TRUE,
                                         sep="\t",
                                         colClasses = "character",
                                         check.names=FALSE,
                                         comment.char = "",
                                         quote="",
                                         fill=TRUE,
                                         blank.lines.skip=FALSE
                                         )
                              )
  
  # make sure that the color matrix is sorted (ROWWISE) by id
    color_matrix <-  color_matrix[order(rownames(color_matrix)),]
    
  # create the color matrix from the metadata
    pcoa_colors <<- create_colors(color_matrix, color_mode="auto")
           


    ##
# Plot metadata colum
#   eigen_values eigen_vectors 
##

    
    



 # this bit is a repeat of the code in the sub below - clean up later
    column_factors <- as.factor(color_matrix[,metadata_column])
    column_levels <- levels(as.factor(color_matrix[,metadata_column]))
    num_levels <- length(column_levels)
    color_levels <- col.wheel(num_levels)
    plot_colors <- pcoa_colors[,metadata_column]
  }else{
    column_levels <- "data"
    num_levels <- 1
    color_levels <- 1
    plot_colors <- "black"
  }


  # use color list for colors if one is supplied
  if ( identical( is.na(color_list), FALSE ) ){
    plot_colors <- color_list
  }
  
                                    
 # load pch matrix if one is specified
  if ( identical( is.na(pch_table), FALSE ) ){
    pch_matrix <- data.matrix(read.table(file=pch_table, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
    pch_matrix <- pch_matrix[order(rownames(pch_matrix)),]
    plot_pch <- pch_matrix[,pch_column]
  }else{
    plot_pch = 19
  }
  



############## IMAGE ATTRIBUTES

    # generate filename for the image output
  if ( identical(image_out, "default") ){
    image_out = paste(PCoA_in, ".pcoa.png", sep="", collapse="")
  }else{
    image_out = paste(image_out, ".png", sep="", collapse="")
  }

  
  png(
      filename = image_out,
      width = image_width_in,
      height = image_height_in,
      res = image_res_dpi,
      units = 'in'
      )

  my_layout <- layout(  matrix(c(1,2), 1, 2, byrow=TRUE ), widths=c( width_legend,width_figure) )
  layout.show(my_layout)

# plot the legend
  plot.new()
  legend( x="center", legend=column_levels, pch=15, col=color_levels, cex=legend_cex)


# plot the pco
  #plot.new()

  par <- list ()
  par$main <- figure_main
#par$labels <- if (length (names (x)) != 0) names (x) else samples (x)
  par$labels <- rownames(eigen_vectors)
#if (length (groups (x)) != 0) par$labels <- paste (par$labels, " (", groups (x), ")", sep = "")
  par [c ("xlab", "ylab", if (length (components) == 3) "zlab" else NULL)] <- paste ("PC", components, ", R^2 = ", format (eigen_values [components], dig = 3), sep = "")

#col <- if (length (groups (x)) != 0) groups (x) else factor (rep (1, length (samples (x))))
#levels (col) <- colors() [sample (length (colors()), nlevels (col))]
#g <- as.character (col)
#par$pch <- 19
  par$cex <- fig_cex

  i <- eigen_vectors [ ,components [1]]
  j <- eigen_vectors [ ,components [2]]
  k <- if (length (components) == 3) eigen_vectors [ ,components [3]] else NULL
  if (is.null (k)) {
#par$col <- col
    par$col <- plot_colors
    par$pch <- plot_pch
    par <- resolveMerge (list (...), par)
    xcall (plot, x = i, y = j, with = par, without = "labels")
    xcall (points, x = i, y = j, with = par, without = "labels")
    grid ()
  } else {
# parameter "color" has to be specially handled.
# "points" above wants "col", scatterplot3d wants "color", and we
# want the user not to worry about it...
                                        #par$color <- col
    par$color <- plot_colors
    par$pch <- plot_pch
    par$type <- "h"
    par$lty.hplot <- "dotted"
    par$axis <- TRUE
    par$box <- FALSE
    #par <- resolveMerge (list (...), par)
    reqPack ("scatterplot3d")
    xys <- xcall (scatterplot3d, x = i, y = j, z = k, with = par,
                  without = c ("cex", "labels")) $ xyz.convert (i, j, k)
    i <- xys$x ; j <- xys$y
  }
  text (x = i, y = j, labels = par$labels, pos = 4, cex = par$cex)
#invisible (P)
#})

  graphics.off()

}








## # 2d (color variable in matR is called "col")
##   if( length(plot_pcs)==2 ){
##     # with labels
##     if( identical(label_points, TRUE) ){
##       plot.new()
##       matR::pco(data_collection, comp = plot_pcs, method = dist_metric, col = plot_colors, pch = plot_pch)
##     }else{
##     # without labels
##       plot.new()
##       matR::pco(data_collection, comp = plot_pcs, method = dist_metric,  col = plot_colors, pch = plot_pch, labels=NA)
##     }
##   }

##   # 3d (color variable in matR is called "color"
##   if( length(plot_pcs)==3 ){
##     # with labels
##     if( identical(label_points, TRUE) ){
##       matR::pco(data_collection, comp = plot_pcs, method = dist_metric, color = plot_colors, pch = plot_pch)
##     }else{
##     # without labels
##       matR::pco(data_collection, comp = plot_pcs, method = dist_metric, color = plot_colors, pch = plot_pch, labels=NA)
##     }
##   }


















###################################################################################################################################
######## SUBS

############################################################################
# $ # Color methods adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
############################################################################

# $ # create optimal contrast color selection using a color wheel
col.wheel <- function(num_col, my_cex=0.75) {
  cols <- rainbow(num_col)
  col_names <- vector(mode="list", length=num_col)
  for (i in 1:num_col){
    col_names[i] <- getColorTable(cols[i])
  }
  cols
}

# $ # The inverse function to col2rgb()
rgb2col <<- function(rgb) {
  rgb <- as.integer(rgb)
  class(rgb) <- "hexmode"
  rgb <- as.character(rgb)
  rgb <- matrix(rgb, nrow=3)
  paste("#", apply(rgb, MARGIN=2, FUN=paste, collapse=""), sep="")
}

# $ # Convert all colors into format "#rrggbb"
getColorTable <- function(col) {
  rgb <- col2rgb(col);
  col <- rgb2col(rgb);
  sort(unique(col))
}
############################################################################

create_colors <- function(color_matrix, color_mode = "auto"){ # function to automtically generate colors from metadata with identical text or values    
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




















######### Import the metadata



######### Generate plot


  
  
  
##   ###################################################################################################################################  
##   # MAIN
##   ###################################################################################################################################
##   # generate filename for the image output
##   if ( identical(image_out, "default") ){
##     image_out = paste(table_in, ".pcoa.png", sep="", collapse="")
##   }else{
##     image_out = paste(image_out, ".png", sep="", collapse="")
##   }
##   ###################################################################################################################################
  
##   ###################################################################################################################################


##   ###### Initialize the figure / figure layout

##   png(
##       filename = image_out,
##       width = image_width_in,
##       height = image_height_in,
##       res = image_res_dpi,
##       units = 'in'
##       )

##   my_layout <- layout(  matrix(c(1,2), 1, 2, byrow=TRUE ), widths=c( width_legend,width_figure) )
##   layout.show(my_layout)

##   ######## import/parse all inputs  
##   # import DATA the data (from tab text)
##   data_matrix <- data.matrix(read.table(table_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
##   # convert data to a matR collection
##   data_collection <- suppressWarnings(as(data_matrix, "collection")) # take the input data and create a matR object with it
  


##   # import colors if the option is selected - generate colors from metadata table if that option is selected
##   if ( identical( is.na(color_table), FALSE ) ){

##   #color_matrix <- as.matrix(read.table(file=color_table, row.names=1, header=TRUE, sep="\t", colClasses = "character", check.names=FALSE, comment.char = ""))
##     # edit 2-3-14 - not sure which option fixed
##     color_matrix <- as.matrix(
##                               read.table(
##                                          file=color_table,
##                                          row.names=1,
##                                          header=TRUE,
##                                          sep="\t",
##                                          colClasses = "character",
##                                          check.names=FALSE,
##                                          comment.char = "",
##                                          quote="",
##                                          fill=TRUE,
##                                          blank.lines.skip=FALSE
##                                          )
##                               ) 
##                                         # generate auto colors if the color matrix contains metadata and not colors

##     # use autocolors created from the metadata, or user specified colors, or just black points                         
##     if ( identical(auto_colors, TRUE) ){

##       # create the color matrix from the metadata
##       pcoa_colors <- create_colors(color_matrix, color_mode="auto")
           
##       # this bit is a repeat of the code in the sub below - clean up later
##       column_factors <- as.factor(color_matrix[,color_column])
##       column_levels <- levels(as.factor(color_matrix[,color_column]))
##       num_levels <- length(column_levels)
##       color_levels <- col.wheel(num_levels)

##       # plot the legend
##       plot.new()
##       legend( x="center", legend=column_levels, pch=15, col=color_levels, cex=legend_cex)
      
##     }else{
##       pcoa_colors <- color_matrix
##     }
##     plot_colors <- pcoa_colors[,color_column]    
##   }else{
##     # use color list if the option is selected
##     if ( identical( is.na(color_list), FALSE ) ){
##       plot_colors <- color_list
##     }else{
##       plot_colors <- "black"
##     }
##   }

##   # load pch matrix if one is specified
##   if ( identical( is.na(pch_table), FALSE ) ){
##     pch_matrix <- data.matrix(read.table(file=pch_table, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
##     plot_pch <- pch_matrix[,pch_column]
##   }else{
##     # use pch list if the option is selected
##     if ( identical( is.na(pch_list), FALSE ) ){
##       plot_pch <- pch_list
##     }else{
##       plot_pch = 16
##     }
##   }
     
##   ###################################################################################################################################

##   ###################################################################################################################################
##   # Generate the plot -- use layout to get legend on one side, PCoA on the other
##   # Have matR calculate the pco and generate an image generate the image (2d)

##   # 2d (color variable in matR is called "col")
##   if( length(plot_pcs)==2 ){
##     # with labels
##     if( identical(label_points, TRUE) ){
##       matR::pco(data_collection, comp = plot_pcs, method = dist_metric, col = plot_colors, pch = plot_pch)
##     }else{
##     # without labels
##       matR::pco(data_collection, comp = plot_pcs, method = dist_metric,  col = plot_colors, pch = plot_pch, labels=NA)
##     }
##   }

##   # 3d (color variable in matR is called "color"
##   if( length(plot_pcs)==3 ){
##     # with labels
##     if( identical(label_points, TRUE) ){
##       pco(data_collection, comp = plot_pcs, method = dist_metric, color = plot_colors, pch = plot_pch)
##     }else{
##     # without labels
##       pco(data_collection, comp = plot_pcs, method = dist_metric, color = plot_colors, pch = plot_pch, labels=NA)
##     }
##   }

##   graphics.off()
  
## }





  














## ###################################################################################################################################

## ###################################################################################################################################


## ###################################################################################################################################
## ######## SUBS

## ############################################################################
## # $ # Color methods adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
## ############################################################################

## # $ # create optimal contrast color selection using a color wheel
## col.wheel <- function(num_col, my_cex=0.75) {
##   cols <- rainbow(num_col)
##   col_names <- vector(mode="list", length=num_col)
##   for (i in 1:num_col){
##     col_names[i] <- getColorTable(cols[i])
##   }
##   cols
## }

## # $ # The inverse function to col2rgb()
## rgb2col <<- function(rgb) {
##   rgb <- as.integer(rgb)
##   class(rgb) <- "hexmode"
##   rgb <- as.character(rgb)
##   rgb <- matrix(rgb, nrow=3)
##   paste("#", apply(rgb, MARGIN=2, FUN=paste, collapse=""), sep="")
## }

## # $ # Convert all colors into format "#rrggbb"
## getColorTable <- function(col) {
##   rgb <- col2rgb(col);
##   col <- rgb2col(rgb);
##   sort(unique(col))
## }
## ############################################################################

## create_colors <- function(color_matrix, color_mode = "auto"){ # function to automtically generate colors from metadata with identical text or values    
##   my_data.color <- data.frame(color_matrix)
##   ids <- rownames(color_matrix)
##   color_categories <- colnames(color_matrix)
##   for ( i in 1:dim(color_matrix)[2] ){
##     column_factors <- as.factor(color_matrix[,i])
##     column_levels <- levels(as.factor(color_matrix[,i]))
##     num_levels <- length(column_levels)
##     color_levels <- col.wheel(num_levels)
##     levels(column_factors) <- color_levels
##     my_data.color[,i]<-as.character(column_factors)
##   }
##   return(my_data.color)
## }
