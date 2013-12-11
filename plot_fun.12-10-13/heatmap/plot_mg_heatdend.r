# script calculates and plots matR heatmap dendrogram of mg abundance tables
plot_mg_heatdend <<- function(
                          table_in,        # annotation abundance table (raw or normalized values)
                          image_out = "default",
                          #label_columns=TRUE, # default or NA
                          label_rows=FALSE,
                          image_width_in=8.5,
                          image_height_in=11,
                          image_res_dpi=300
                          )
  
{
  
  require(matR)

  ###################################################################################################################################
  # generate filename for the image output
  if ( identical(image_out, "default")  ){  
    image_out = paste(table_in, ".heat-dend.png", sep="", collapse="")  
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

  # Can create heat dend with or without row labels
  if ( identical( label_rows, FALSE ) ){
    suppressWarnings(heatmap(data_collection, colsep=NULL))
  }else{
    suppressWarnings(heatmap(data_collection, colsep=NULL, labRow=dimnames(data_collection$x)[[1]]))
  }
  ##}
  dev.off()

}

