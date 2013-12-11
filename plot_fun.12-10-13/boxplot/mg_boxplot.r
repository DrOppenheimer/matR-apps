# script calculates and plots matR boxplots
mg_boxplot <<- function(
                          table_in,        # annotation abundance table (raw or normalized values)
                          image_out = "default",
                          #label_columns=TRUE, # default or NA
                          label_rows=FALSE,
                          image_width_in=10.5,
                          image_height_in=8,
                          image_res_dpi=150
                          )
  
{
  
  require(matR)

  ###################################################################################################################################
  # generate filename for the image output
  if ( identical(image_out, "default")  ){  
    image_out = paste(table_in, ".boxplot.png", sep="", collapse="")  
  }else{
    image_out = paste(image_out, ".png", sep="", collapse="")
  }
  ###################################################################################################################################
  
  ###################################################################################################################################
  ######## import/parse all inputs
  
  # import DATA the data (from tab text)
  data_matrix <- data.matrix(read.table(table_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
  
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

  # create a boxplot
 boxplot(data_matrix, las=2, mai = c(2, 0.5, 0.5, 0.5), cex=0.5 )
  

  dev.off()

}

