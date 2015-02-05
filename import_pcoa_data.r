my_object <- load_pcoa_data.original("wgs_raw_ssL3.counts.10-15-14.txt.bray-curtis.PCoA")


load_pcoa_data.original <- function(PCoA_in){

  start <- Sys.time ()
  print(paste("start:", start))
  
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
  
  runtime <- Sys.time () - start
  print(paste("runtime:", round(runtime, digits=2), "seconds"))
  return(list(eigen_values=eigen_values, eigen_vectors=eigen_vectors))
  
}



my_object2 <- load_pcoa_data.new("fierer_data.raw.genus_counts.10-7-14.txt.DESeq_blind.PREPROCESSED.txt.bray-curtis.PCoA")

load_pcoa_data.new <- function(PCoA_in){
  
  start <- Sys.time ()
  print(paste("start:", start))
  
  con_1 <- file(PCoA_in)
  
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
  
  eigen_vectors.raw <- as.matrix(
                                 fread(
                                       input=metadata_file, sep="\t", stringsAsFactors=FALSE,
                                       skip="mgm", showProgress=TRUE, colClasses="character"
                                       )
                                 )
  
  eigen_vectors.raw.test <<- eigen_vectors.raw
  
  eigen_vectors <- eigen_vectors.raw[ , 2:ncol(eigen_vectors.raw)] # Load the metadata table (same if you use one or all columns)
  dimnames(eigen_vectors)[[1]] <- eigen_vectors.raw[,1]
  
  #test_table <- fread(PCoA_in, skip="PCO1", colClasses="character")

  runtime <- Sys.time () - start
  print(paste("runtime:", round(runtime, digits=2), "seconds"))
  #return(test_table)

  return(list(eigen_values=eigen_values, eigen_vectors=eigen_vectors))

}
  
  
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

runtime <- Sys.time () - start
print(paste("runtime:", round(runtime, digits=2), "seconds"))
return(list(eigen_values=eigen_values, eigen_vectors=eigen_vectors))
