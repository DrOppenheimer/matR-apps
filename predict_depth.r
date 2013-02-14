predict_depth <- function(abundance_matrix, input_type = "object", file_out_prefix = "depth_prediction", genome_size=5000000, coverage=100, num_to_show=10, create_figure=TRUE){

# Print usage if
   if (nargs() == 0){print_usage()}

# Check to see if abundance_matrix is a file - if so, load it - if not, assume it is an R object and copy it
   if (input_type=="file"){
     my_data.matrix <- data.matrix(read.table(abundance_matrix, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))
   }else{
     # my_data.matrix <- my_data$count
     my_data.matrix <- abundance_matrix
   }
   
# get names
  row_names <- dimnames(my_data.matrix)[1]
  col_names <- dimnames(my_data.matrix)[2]

# get index of exisiting order
  my_data.index <- as.vector(order(my_data.matrix[,1], decreasing=TRUE))

# create index sorted matrix # this preserves the row names, but not columns
  sorted_matrix <- as.matrix(my_data.matrix[my_data.index,])
  dimnames(sorted_matrix)[2] <- col_names
  
# create matrix to hold calcualted depths
  my_coverage_matrix <- matrix("",dim(sorted_matrix)[1],2)
  dimnames(my_coverage_matrix)[[1]] <- dimnames(sorted_matrix)[[1]] # label rows
  dimnames(my_coverage_matrix)[[2]] <- c("16s abundance","WGS depth to assemble (bp)") # label columns
  my_coverage_matrix[,1] <- sorted_matrix[,1] # place abundance in first column

# calculate sequencing depth for each taxon
  for (i in 1:dim(sorted_matrix)[1]){
    my_coverage_matrix[i,2] <- round( ( genome_size * coverage ) / ( sorted_matrix[i,1] / sum(sorted_matrix[,1]) ) )
  }

# generate tab delimited output
  file_out <- gsub(" ", "", paste(file_out_prefix, ".txt"))
  write.table(my_coverage_matrix, file = "my_depth_prediction.txt", col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  
# generate a figure 
  if (create_figure == TRUE){
    image_out <- gsub(" ", "", paste(file_out_prefix, ".pdf"))
    pdf(file=image_out, width = 10, height = 5)
    par(mar=c(15,5,1,5))
    barplot( as.numeric(sorted_matrix[1:num_to_show,1]), las=2, axisnames=(1:10), names.arg = dimnames(my_coverage_matrix)[[1]][1:num_to_show], ylab="" ) # mar=c(1,1,1,50))
    mtext("Taxon Abundance", side=2, line=4 )
    par(new=TRUE)
    plot((1:num_to_show), my_coverage_matrix[1:num_to_show,2], type="o", col="red", lwd=3, lty=1, xlab="", ylab="", xaxt="n", axes=F)
    #axis(2, las=1)
    #mtext("Taxon Abundance", side=2, line=1 )
    axis(4, las=1, col="red")
    mtext( paste("Predicted BPs of sequencing for (", coverage, ") x coverage"),side=4, line=4, adj=1.3, col = "red")
    dev.off()
  }
  
 }


print_usage <- function() {
  writeLines(
             "  ------------------------------------------------------------------------------
  predict_depth.r                     Kevin P. Keegan, kkeegan@anl.gov  Feb 2013
  ------------------------------------------------------------------------------
  DESCRIPTION:
  Script to predict amount of WGS sequencing necessary to achieve a certain level of
  coverage based on relative organism abundance determined from 16s data. 

  USAGE:
  predict_depth <- function(abundance_matrix, input_type = c(\"file\", \"object\"), file_out_prefix= \"depth_prediction\", genome_size=5000000, coverage=100, num_to_show=10, create_figure=TRUE)


  NOTES:

  abundance_matrix : can be a file or R matrix - specify file or it will treat like R matrix
  an output tab delimited text is always created, a pdf is output is optional.
  Calculation is performed on all taxa - but only shows as many as specified by
  num_to_show.

  Two most commone ways to use this script would be like this for an R object:
       predict_depth(my_data.matrix)
  or like this for a tab delimited file as input
       predict_depth(\"test_data.txt\", input_type=\"file\")

  In either case, input is a two column matrix, first with taxa names, second
  with their abundances.
  ------------------------------------------------------------------------------"
             )
  stop("you did not enter the correct args -- see above")
}


