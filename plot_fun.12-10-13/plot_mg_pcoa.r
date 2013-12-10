# script to plot KBASE JSON formatted pcoa
plot_mg_pcoa <<- function(
                          file_in
                          )

{

###### load the data  
  json_pcoa <- fromJSON(getURL(file_in))

  pco_values.raw <- unlist(as.list(json_pcoa$pco))

  num_values <- length(pco_values.raw)

  pcoa_matrix <- matrix(NA,num_values,num_values)
  

  matrix_in <- data.matrix(read.table(file_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))


my_json <- fromJSON(my_query)

require RJSONIO

}



