import_metaddata <- function(metadata_file){
  start <- Sys.time ()
  print(paste("start:", start))
  
  metadata_matrix.raw <- as.matrix(
                                   fread(
                                         input=metadata_file, header=TRUE, sep="\t", na.strings=NULL, stringsAsFactors=FALSE,
                                         colClasses = "character", showProgress=TRUE
                                         )
                                   )
  
  metadata_matrix.raw.test <<- metadata_matrix.raw
  
  metadata_matrix <- metadata_matrix.raw[ , 2:ncol(metadata_matrix.raw)] # Load the metadata table (same if you use one or all columns)
  dimnames(metadata_matrix)[[1]] <- metadata_matrix.raw[,1]
  
  runtime <- Sys.time () - start
  print(paste("runtime:", round(runtime, digits=2), "seconds"))
  return(metadata_matrix)
}
