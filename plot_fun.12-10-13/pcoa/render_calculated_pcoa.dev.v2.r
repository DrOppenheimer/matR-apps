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
                         PCoA_in="", # annotation abundance table (raw or normalized values)
                         image_out="default",
                         figure_main ="principal coordinates",
                         components=c(1,2,3), # R formated string telling which coordinates to plot, and how many (2 or 3 coordinates)
                         label_points=FALSE, # default is off
                         metadata_table=NA, # matrix that contains colors or metadata that can be used to generate colors
                         metadata_column=2, # column of the color matrix to color the pcoa (colors for the points in the matrix) -- rows = samples, columns = colorings
                         amethst_groups=NA,        
                         color_list=NA, # use explicit list of colors - trumps table if both are supplied
                         pch_table=NA, # additional matrix that allows users to specify the shape of the data points
                         pch_column=1,
                         image_width_in=22,
                         image_height_in=17,
                         image_res_dpi=300,
                         width_legend = 0.2, # fraction of width used by legend
                         width_figure = 0.8, # fraction of width used by figure
                         title_cex = 2, # cex for the title of title of the figure
                         legend_cex = 2, # cex for the legend
                         figure_cex = 2, # cex for the figure
                         bar_cex = 2, 
                         use_all_metadata_columns=FALSE, # option to overide color_column -- if true, plots are generate for all of the metadata columns
                         debug=TRUE
                         )
  
{
  
  require(matR)
  
  argument_test <<- is.na(c(metadata_table,amethst_groups,color_list)) # check that incompatible options were not selected
  if ( 3 - length(subset(argument_test, argument_test==TRUE) ) > 1){
    stop(
         paste(
               "\n\nOnly on of these can have a non NA value:\n",
               "     metadata_table: ", metadata_table,"\n",
               "     amethst_groups: ", amethst_groups, "\n",
               "     color_list    : ", color_list, "\n\n",
               sep="", collapse=""
               )
         )
  }
  
  ######################
  ######## MAIN ########
  ######################
  
  my_data <- load_pcoa_data(PCoA_in) # import_data
  my_eigen_values <- my_data$eigen_values
  my_eigen_vetors <- my_data$eigen_vectors
  #return(list(eigen_values=eigen_values, eigen_vectors=eigen_vectors))

  my_metadata_matrix <- load_metadata(metadata_table, metadata_column, color_list, amethst_groups) # import_metadata_coloring

  load_pch(pch_table) # import_pch
  
  #####################################################################################
  # PLOT WITH NO METADATA OR COLORS SPECIFIED (colors generated by load_metadata)
  if ( length(argument_test==TRUE)==0 ){
    if ( identical(image_out, "default") ){
      image_out = paste( PCoA_in,".NO_COLOR.PCoA.png", sep="", collapse="" )
      figure_main = paste( PCoA_in, ".NO_COLOR.PCoA", sep="", collapse="" )
    }else{
      image_out = paste(image_out, ".png", sep="", collapse="")
      figure_main = paste( image_out,".PCoA", sep="", collapse="")
    }
    create_plot(
                PCoA_in,
                ncol.color_matrix,
                eigen_values, eigen_vectors, components,
                column_levels, num_levels, color_levels, pcoa_colors, plot_pch,
                image_out,figure_main,
                image_width_in, image_height_in, image_res_dpi,
                width_legend, width_figure,
                title_cex, legend_cex, figure_cex, bar_cex, label_points
                )
  }
  #####################################################################################
  
  #####################################################################################
  # PLOT WITH AMETHST GROUPS (colors generated by load_metadata)
  if ( identical( is.na(amethst_groups), FALSE ) ){
    if ( identical(image_out, "default") ){
      image_out = paste( PCoA_in,".AMETHST_GROUPS.PCoA.png", sep="", collapse="" )
      figure_main = paste( PCoA_in, ".AMETHST_GROUPS.PCoA", sep="", collapse="" )
    }else{
      image_out = paste(image_out, ".png", sep="", collapse="")
      figure_main = paste( image_out,".PCoA", sep="", collapse="")
    }

    column_levels <<- levels(metadata_column)
    #num_levels <<- length(column_levels)
    #color_levels <<- col.wheel(num_levels)
    #ncol.color_matrix <<- 1
    #pcoa_colors <<- color_list
    
    column_levels <<- column_levels[ order(column_levels) ] # NEW (order by levels values)
    color_levels <<- color_levels[ order(column_levels) ] # NEW (order by levels values)

    plot_column(
                metadata_matrix,1,
                PCoA_in,
                eigen_values, eigen_vectors, components,
                plot_pch,
                image_width_in, image_height_in, image_res_dpi,
                width_legend, width_figure,
                title_cex, legend_cex, figure_cex, bar_cex, label_points
                )







    
    ## create_plot(
    ##             PCoA_in,
    ##             ncol.color_matrix,
    ##             eigen_values, eigen_vectors, components,
    ##             column_levels, num_levels, color_levels, pcoa_colors, plot_pch,
    ##             image_out,figure_main,
    ##             image_width_in, image_height_in, image_res_dpi,
    ##             width_legend, width_figure,
    ##             title_cex, legend_cex, figure_cex, bar_cex, label_points
    ##             )
    
  }
  #####################################################################################

  #####################################################################################
  # PLOT WITH LIST OF COLORS (colors generated by load_metadata)
  if ( identical( is.na(color_list), FALSE ) ){
    if ( identical(image_out, "default") ){
      image_out = paste( PCoA_in,".color_List.PCoA.png", sep="", collapse="" )
      figure_main = paste( PCoA_in, ".color_list.PCoA", sep="", collapse="" )
    }else{
      image_out = paste(image_out, ".png", sep="", collapse="")
      figure_main = paste( image_out,".PCoA", sep="", collapse="")
    }
    create_plot(
                PCoA_in,
                ncol.color_matrix,
                eigen_values, eigen_vectors, components,
                column_levels, num_levels, color_levels, pcoa_colors, plot_pch,
                image_out,figure_main,
                image_width_in, image_height_in, image_res_dpi,
                width_legend, width_figure,
                title_cex, legend_cex, figure_cex, bar_cex, label_points
                )
  }
  #####################################################################################
  
  #####################################################################################
  # PLOT WITH METADATA_TABLE (colors produced from color_matrix)
  if ( identical( is.na(metadata_table), FALSE ) ){
    if ( use_all_metadata_columns==TRUE ){ # autogenerate plots for all columns in the metadata table file
      for (i in 1:ncol.color_matrix){ # generate filename and title for each image 
        plot_column(
                    my_metadata_matrix,i,
                    PCoA_in,
                    eigen_values, eigen_vectors, components,
                    plot_pch,
                    image_width_in, image_height_in, image_res_dpi,
                    width_legend, width_figure,
                    title_cex, legend_cex, figure_cex, bar_cex, label_points
                    )
      }
    }else if ( use_all_metadata_columns==FALSE ){ # auto generate colors from a single selected column
      plot_column(
                  my_metadata_matrix,metadata_column,
                  PCoA_in,
                  eigen_values, eigen_vectors, components,
                  plot_pch,
                  image_width_in, image_height_in, image_res_dpi,
                  width_legend, width_figure,
                  title_cex, legend_cex, figure_cex, bar_cex, label_points  
                  )   
    }else{
      stop(paste("invalid value for use_all_metadata_columns(", use_all_metadata_columns,") was specified, please try again", sep="", collapse=""))
    }
  }

}
#####################################################################################

######################
###### END MAIN ######
######################
  
######################
######## SUBS ########
######################

#######################
######## SUB(1): Function to import the data from a pre-calculated PCoA
######################
load_pcoa_data <- function(PCoA_in){
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
  # write imported data to global objects
  #eigen_values <<- eigen_values
  #eigen_vectors <<- eigen_vectors
  return(list(eigen_values=eigen_values, eigen_vectors=eigen_vectors))
  
}
######################
######################
######################


######################
# SUB(2): Function to load the metadata/ generate or import colors for the points
######################
#load_metadata <- function(metadata_table, metadata_column, color_list, amethst_groups){
load_metadata <- function(metadata_table, ...){
  
  if ( identical( is.na(metadata_table), FALSE ) ){ # HANDLE METADATA TABLE for generating colors
    metadata_matrix <- as.matrix( # Import metadata table, use it to generate colors
                              read.table(
                                         file=metadata_table,row.names=1,header=TRUE,sep="\t",
                                         colClasses = "character", check.names=FALSE,
                                         comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                         )
                              )   
    metadata_matrix <- metadata_matrix[ order(rownames(metadata_matrix)),,drop=FALSE ]  # make sure that the metadata matrix is sorted (ROWWISE) by id
    return(metadata_matrix)
    
  } else if ( identical( is.na(amethst_groups), FALSE ) ){ # HANDLE AMETHST GROUPS for generating colors

    con_grp <- file(amethst_groups)
    open(con_grp)
    line_count <- 1
    groups.list <- vector(mode="character")
    while ( length(my_line <- readLines(con_grp,n = 1, warn = FALSE)) > 0) {
      new_line <- my_line
      split_line <- unlist(strsplit(my_line, split=","))
      split_line.list <- rep(line_count, length(split_line))
      names(split_line.list) <- split_line
      groups.list <- c(groups.list, split_line.list)
      line_count <- line_count + 1
    }
    close(con_grp)
    if ( length(groups.list) != length(unique(names(groups.list))) ){
      stop("One or more groups have redundant entries - this is not allowed for coloring the PCoA")
    }
    metadata_matrix <- matrix(groups.list, ncol=1)
    metadata_matrix <- metadata_matrix[ order(metadata_matrix),,drop=FALSE ] # order by metadata value
    colnames(metadata_matrix) <- "amethst_metadata"
    #column_levels <<- levels(metadata_column)
    #num_levels <<- length(column_levels)
    #color_levels <<- col.wheel(num_levels)
    #ncol.color_matrix <<- 1
    #pcoa_colors <<- color_list
    return(metadata_matrix)
    
  }else if ( identical( is.na(color_list), FALSE ) ){ # HANDLE COLOR LIST; use list of color if it is supplied
    
    column_levels <<- levels(as.factor(as.matrix(color_list)))
    num_levels <<- length(column_levels)
    color_levels <<- col.wheel(num_levels)
    ncol.color_matrix <<- 1
    pcoa_colors <<- color_list
   
  }else{ # HANDLE NO INPUT METADATA OR COLORS; use a default of black if no table or list is supplied
                                     
    column_levels <<- "data"
    num_levels <<- 1
    color_levels <<- 1
    ncol.color_matrix <<- 1
    pcoa_colors <<- "black"    

  }
}
######################
######################

  
######################
# SUB(3): Function to import the pch information for the points # load pch matrix if one is specified
######################
load_pch <- function(pch_table){
  if ( identical( is.na(pch_table), FALSE ) ){
    pch_matrix <- data.matrix(read.table(file=pch_table, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
    pch_matrix <- pch_matrix[order(rownames(pch_matrix)),]
    plot_pch <<- pch_matrix[,pch_column]
  }else{
    plot_pch <<- 19
  }
}
######################
######################
  
######################
# SUB(4): Workhorse function that creates the plot
######################
create_plot <- function(
                        PCoA_in,
                        ncol.color_matrix,
                        eigen_values, eigen_vectors, components,
                        column_levels, num_levels, color_levels, pcoa_colors, plot_pch,
                        image_out,figure_main,
                        image_width_in, image_height_in, image_res_dpi,
                        width_legend, width_figure,
                        title_cex, legend_cex, figure_cex, bar_cex, label_points 
                        ){                      
  png( # initialize the png 
      filename = image_out,
      width = image_width_in,
      height = image_height_in,
      res = image_res_dpi,
      units = 'in'
      )
  # CREATE THE LAYOUT
  my_layout <- layout(  matrix(c(1,1,2,3,4,4), 3, 2, byrow=TRUE ), widths=c(width_legend,width_figure), heights=c(0.1,0.8,0.1) )
  layout.show(my_layout)
  # PLOT THE TITLE
  plot.new()
  text(x=0.5, y=0.5, figure_main, cex=title_cex)
  # PLOT THE LEGEND
  plot.new()
  legend( x="center", legend=column_levels, pch=15, col=color_levels, cex=legend_cex)
  # PLOT THE FIGURE
  # set par options (Most of the code in this section is copied/adapted from Dan Braithwaite's pco plotting in matR)
  par <- list ()
  par$main <- ""#figure_main
  #par$labels <- if (length (names (x)) != 0) names (x) else samples (x)
  if ( label_points==TRUE ){
    par$labels <-  rownames(eigen_vectors)
  } else {
    par$labels <- NA
  }
  #if (length (groups (x)) != 0) par$labels <- paste (par$labels, " (", groups (x), ")", sep = "")
  par [c ("xlab", "ylab", if (length (components) == 3) "zlab" else NULL)] <- paste ("PC", components, ", R^2 = ", format (eigen_values [components], dig = 3), sep = "")
  #col <- if (length (groups (x)) != 0) groups (x) else factor (rep (1, length (samples (x))))
  #levels (col) <- colors() [sample (length (colors()), nlevels (col))]
  #g <- as.character (col)
  #par$pch <- 19
  par$cex <- figure_cex
  # main plot paramters - create the 2d or 3d plot
  i <- eigen_vectors [ ,components [1]]
  j <- eigen_vectors [ ,components [2]]
  k <- if (length (components) == 3) eigen_vectors [ ,components [3]] else NULL
  if (is.null (k)) {
  #par$col <- col
    par$col <- pcoa_colors ####<--------------
    par$pch <- plot_pch
    par <- resolveMerge (list (...), par)
    xcall (plot, x = i, y = j, with = par, without = "labels")
    xcall (points, x = i, y = j, with = par, without = "labels")
    grid ()
  } else {
    # parameter "color" has to be specially handled.
    # "points" above wants "col", scatterplot3d wants "color", and we
    # want the user not to worry about it...
    # par$color <- col
    par$color <- pcoa_colors
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
  # PLOT THE COLOR BAR
  bar_x <- 1:num_levels
  bar_y <- 1
  bar_z <- matrix(1:num_levels, ncol=1)
  image(x=bar_x,y=bar_y,z=bar_z,col=color_levels,axes=FALSE,xlab="",ylab="")
  loc <- par("usr")
  # this worked ? #text(loc[1], loc[1], column_levels[1], pos = 1, xpd = T, cex=bar_cex)
  # text(loc[1], loc[3], column_levels[1], pos = 4, xpd = T, cex=bar_cex)
  text(loc[1], loc[1], column_levels[1], pos = 4, xpd = T, cex=bar_cex, adj=c(0,0))
  text(loc[2], loc[3], column_levels[num_levels], pos = 2, xpd = T, cex=bar_cex, adj=c(0,1))
  graphics.off()
}
######################
######################


######################
# SUB(5): Handle partially formatted metadata to produce colors for a single column in a metadata table
######################
## column_color <- function( color_matrix, my_color_mode="auto", my_column ){
##   ncol.color_matrix <<- ncol(color_matrix)
##   plot_colors.matrix <<- create_colors(color_matrix, color_mode=my_color_mode)
##   column_factors <<- as.factor(color_matrix[,my_column])
##   column_levels <<- levels(as.factor(color_matrix[,my_column]))
##   num_levels <<- length(column_levels)
##   color_levels <<- col.wheel(num_levels)
##   pcoa_colors <<- plot_colors.matrix[,my_column]
## }
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


######################
# SUB(9): Automtically generate colors from metadata with identical text or values
######################
create_colors <- function(metadata_matrix, color_mode = "auto"){ # function to     
  my_data.color <- data.frame(metadata_matrix)
  ids <- rownames(metadata_matrix)
  color_categories <- colnames(metadata_matrix)
  for ( i in 1:dim(metadata_matrix)[2] ){
    column_factors <- as.factor(metadata_matrix[,i])
    column_levels <- levels(as.factor(metadata_matrix[,i]))
    num_levels <- length(column_levels)
    color_levels <- col.wheel(num_levels)
    levels(column_factors) <- color_levels
    my_data.color[,i]<-as.character(column_factors)
  }
  return(my_data.color)
}
## create_colors <- function(metadata_matrix, color_mode = "auto"){ # function to     
##   #my_data.color <- data.frame(metadata_matrix)
##   my_data.color <- vector(length=nrow(metadata_matrix), mode="character")
##   ids <- rownames(metadata_matrix)
##   color_categories <- colnames(metadata_matrix)
##   for ( i in 1:dim(metadata_matrix)[2] ){
##     column_factors <- as.factor(metadata_matrix[,i])
##     column_levels <- levels(as.factor(metadata_matrix[,i]))
##     num_levels <- length(column_levels)
##     color_levels <- col.wheel(num_levels)
##     levels(column_factors) <- color_levels
##     my_data.color[i] <- as.character(column_factors)
##   }
##   return(my_data.color)
## }
######################
######################


######################
# SUB(10): Plot operations for a single metadata column
######################

plot_column <- function(
                        metadata_matrix,i,
                        PCoA_in,
                        ncol.color_matrix,
                        eigen_values, eigen_vectors, components,
                        plot_pch,
                        image_width_in, image_height_in, image_res_dpi,
                        width_legend, width_figure,
                        title_cex, legend_cex, figure_cex, bar_cex, label_points
                        )
{
  metadata_column <- metadata_matrix[ ,i,drop=FALSE ] # get column i from the metadata matrix
  
  suppressWarnings( numericCheck <- as.numeric(metadata_column) ) # check to see if metadata are numeric, and sort accordingly
  if( is.numeric(numericCheck[1]) ){
    column_name = colnames(metadata_column)[1]
    row_names = rownames(metadata_column)
    metadata_column <- matrix(numericCheck, ncol=1)
    colnames(metadata_column) <- column_name
    rownames(metadata_column) <- row_names
  }

  metadata_column <- metadata_column[ order(metadata_column),,drop=FALSE ] # order the metadata by value
  
  color_column <- create_colors(metadata_matrix=metadata_column, color_mode = "auto")
  #pcoa_colors <<- #color_column[ ,1,drop=FALSE ]
  ncol.color_matrix <- 1 
  column_factors <- as.factor(metadata_column) 
  column_levels <- levels(as.factor(metadata_column))
  num_levels <- length(column_levels)
  color_levels <- col.wheel(num_levels)
  pcoa_colors <- color_column #[,1, drop=FALSE]

  image_out = paste(PCoA_in,".", colnames(metadata_column), ".pcoa.png", sep="", collapse="") # generate name for plot file
  figure_main = paste( PCoA_in,".", colnames(metadata_column),".PCoA", sep="", collapse="") # generate title for the plot

  #rownames(eigen_vectors) <<- noquote(rownames(eigen_vectors))
  # test2 <- test2[rownames(test1),,drop=FALSE]
  # eigen_vectors <<- eigen_vectors[ rownames(color_column),,drop=FALSE ] # sort vectors by ordering of colors
  #test2[match(row.names(test2), row.names(test1)),1,drop=FALSE]


###### HERE
  
  #vector_rownames <<- rownames(eigen_vectors)
  #vector_colnames <<- colnames(eigen_vectors)
  #color_column <<- as.matrix(color_column)
  #rownames(eigen_vectors) <<-

  #test_2 <- eigen_vectors
  #rownames(test_2) <- gsub("\"", "", rownames(test_2))

  rownames(eigen_vectors) <- gsub("\"", "", rownames(eigen_vectors))
  
  #eigen_vectors[ match(rownames(eigen_vectors), rownames(pcoa_colors)),1,drop=FALSE]
  #eigen_vectors[ match(rownames(pcoa_colors), rownames(eigen_vectors)),1,drop=FALSE]
  eigen_vectors <- eigen_vectors[ rownames(pcoa_colors), ]
  #eigen_vectors[ rownames(pcoa_colors)),]
  
  create_plot( # generate the  plot
              PCoA_in,
              ncol.color_matrix,
              eigen_values, eigen_vectors, components,
              column_levels, num_levels, color_levels, pcoa_colors, plot_pch,
              image_out,figure_main,
              image_width_in, image_height_in, image_res_dpi,
              width_legend, width_figure,
              title_cex, legend_cex, figure_cex, bar_cex, label_points              
              ) 
}



  
######################
###### END SUBS ######
######################

