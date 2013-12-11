# script calculates and plots matR PCoAs of mg abundance tables
plot_mg_pcoa <<- function(
                          table_in,        # annotation abundance table (raw or normalized values)
                          image_out = "default",
                          plot_pcs = c(1,2,3), # R formated string telling which coordinates to plot, and how many (2 or 3 coordinates)
  # dist_metric = "",
                          label_points="default", # default or NA
                          color_table=NA,   # matrix that contains colors or metadata that can be used to generate colors
                          color_column=1,    # column of the color matrix to color the pcoa (colors for the points in the matrix) -- rows = samples, columns = colorings
                          auto_colors=FALSE, # automatically generate colors from metadata tables (identical values/text get the same color)
                          pch_table=NA, # additional matrix that allows users to specify the shape of the data points
                          pch_column=1,
                          image_width_in=11,
                          image_height_in=8.5,
                          image_res_dpi=300
                          )
  
{
  
  require(matR)

  ###################################################################################################################################
  # generate filename for the image output
  if ( identical(image_out, "default")  ){  
    image_out = paste(table_in, ".pcoa.png", sep="", collapse="")  
  }else{
    image_out = paste(image_out, ".png", sep="", collapse="")
  }
  ###################################################################################################################################
  
  ###################################################################################################################################
  ######## import/parse all inputs
  
  # import DATA the data (from tab text)
  data_matrix <- data.matrix(read.table(table_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
  # convert data to a matR collection
  data_collection <- suppressWarnings(as(data_matrix, "collection")) # take the input data and create a matR object with it
  
  # import colors if the optionis selected - generate colors from metadata table if that option is selected
  if ( identical( is.na(color_table), FALSE ) ){
    #color_matrix <- matrix(read.table(color_table, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE)) 
    color_matrix <- as.matrix(read.table(color_table)) 
    # generate auto colors if the color matrix contains metadata and not colors
    # this needs more work -- to get legend that maps colors to groups
    if ( identical(auto_colors, TRUE)  ){
      pcoa_colors <- create_colors(color_matrix, color_mode="auto")
    }else{
      pcoa_colors <- color_matrix
    }
    plot_colors <- pcoa_colors[,color_column]
  }else{
    plot_colors <- "black"
  }

  # load pch matrix if one is specified
  if ( identical( is.na(pch_table), FALSE ) ){
    pch_matrix <- data.matrix(read.table(pch_table, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
    plot_pch <- pch_matrix[,pch_column]
  }else{
    plot_pch = 16
  }
      
  ###################################################################################################################################

  ###################################################################################################################################
  # Generate the plot
  # Have matR calculate the pco and generate an image generate the image (2d)
  png(
      filename = image_out,
      width = image_width_in,
      height = image_height_in,
      res = image_res_dpi,
     units = 'in'
    )
  
  # 2d (color variable in matR is called "col")
  if( length(plot_pcs)==2  ){
    # with labels
    if( identical(label_points, "default") ){
      pco(data_collection, comp = plot_pcs, col = plot_colors, pch = plot_pch) 
    }else{
  # without labels
      pco(data_collection, comp = plot_pcs, col = plot_colors, pch = plot_pch, labels=NA)
    }
  }

  # 3d (color variable in matR is called "color"
  if( length(plot_pcs)==3  ){
    # with labels
    if( identical(label_points, "default") ){
      pco(data_collection, comp = plot_pcs, color = plot_colors, pch = plot_pch) 
    }else{
  # without labels
      pco(data_collection, comp = plot_pcs, color = plot_colors, pch = plot_pch, labels=NA)
    }
  }

  dev.off()

}
###################################################################################################################################      

###################################################################################################################################
######## SUBS
   
create_colors <- function(color_matrix, color_mode = "auto"){ # function to automtically generate colors from metadata with identical text or values
############################################################################
# Color methods adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
############################################################################  

  # create optimal contrast color selection using a color wheel
  col.wheel <- function(num_col, my_cex=0.75) {
    cols <- rainbow(num_col)
    col_names <- vector(mode="list", length=num_col) 
    for (i in 1:num_col){
      col_names[i] <- getColorTable(cols[i])
    }
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

       



     ## THIS WORKED
       # png(
       #   filename = image_out,
       #   width = 11,
       #   height = 8.5,
       #   units = 'in',
       #   res = 300,
       # )
       # pco(data_collection)
       # dev.off()
       
       ## SO DID THIS _ A LITTLE MORE ADVANCED
       # png(
       #   filename = image_out,
       #   width = 11,
       #   height = 8.5,
       #   units = 'in',
       #   res = 300
       # )
       # pco(data_collection, color = pcoa_colors[,color_column])#color_matrix[1]), 
       # dev.off()
       
       
       

  

       
  
  
  
