load_metadata_simple <- function(metadata_table, metadata_column, color_list){
    
  my_metadata.data_matrix <- data.matrix(
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
  return(my_metadata.data_matrix) 
}
