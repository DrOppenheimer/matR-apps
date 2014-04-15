# functions that will cull data from abundance table and metadata file for a list of ids

data_cull.v1 <- function( data_in=NULL, metadata_in=NULL, cull_list="cull_ids.txt", new_file_suffix="CULLED" ){

  # import list of ids to cull
  suppressMessages(id_list <- import_idList(cull_list))
 
  # cull data file
  if( is.null(data_in)==FALSE ){
    data_matrix <- import_data(data_in)
    data_matrix <- data_matrix[ ,!(colnames(data_matrix) %in% id_list)]
    new_data_file_name = paste(data_in, ".", new_file_suffix, ".txt", sep="", collapse="" )
    write.table(data_matrix, file=new_data_file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
  }
  
  # cull metadata file
  if( is.null(metadata_in)==FALSE ){
    metadata_matrix <- import_metadata(metadata_in)
    metadata_matrix <- metadata_matrix[!(rownames(metadata_matrix ) %in% id_list),]
    new_metadata_file_name = paste(metadata_in, ".", new_file_suffix, ".txt", sep="", collapse="" )
    write.table(metadata_matrix, file=new_metadata_file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
  }

}



# func to import single column list of ids to cull
import_idList <- function(cull_list){
  id_list <- scan(file=cull_list, what="character")
  return(id_list)
}

# func to import the data; columns are samples, rows are categories
import_data <- function(data_in){
  data_matrix <- data.matrix(read.table(data_in, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))
  return(data_matrix)
}

# func to import metadata; columns are metadata conditions, rows are samples
import_metadata <- function(metadata_in){
  metadata_matrix <- as.matrix( # Load the metadata table (same if you use one or all columns)
                               read.table(
                                          file=metadata_in,row.names=1,header=TRUE,sep="\t",
                                          colClasses = "character", check.names=FALSE,
                                          comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                          )
                               )   
  
  return(metadata_matrix)
}

# http://stackoverflow.com/questions/9805507/deselecting-a-column-by-name-r
# dd[ ,!(colnames(dd) %in% c("A", "B"))] # remove multiple
# dd[ , names(dd) != "A"] # remove single
  



                                       
