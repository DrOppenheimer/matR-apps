metadata_check <- function(my_data_file=NA, my_PCoA=NA, my_metadata="", debug=TRUE, output_filename="metadata_check.error_log.txt"){

  ######################
  ######## SUB(1): USAGE
  ######################
  func_usage <- function() {
    writeLines("
     You supplied no arguments
               
               DESCRIPTION: (metadata_check.r):
               This is a tool to check data (abundance table or plot_pcoa.r generated PCoA) and metadata (tab delimited table)
               to make sure that there are no obvious problems (e.g. data and metadata exist for all samples).
               Required to enter a PCoA or data file, metadata file also required.
               
               USAGE: MGRAST_plot_pca(
               my_data_file= NA,      # (string)  tab delimited data file, samples as columns, rows as categories (taxa or functions)
               my_PCoA = NA,      # (string)  *.PCoA generated from plot_pcoa.r
               my_metadata = \"\" # (string)  tab delimited metadata file, samples as rows, metadata categories as columns
               )"
               )
    stop("stopped metadata_check\n\n")
  }
  #######################
  ######## SUB(2): Function to import the data from a pre-calculated PCoA
  ######################
  load_pcoa_data <- function(PCoA_in){
    
    print("loading PCoA")
    
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
  ######## SUB(3): examine sample names
  ######################
  find_discrepancies <- function(data_names, metadata_names, data_out_name){
    ids_in_both <- intersect(data_names, metadata_names)
    write( paste("ids_in_both (", length(ids_in_both) ,")"), file=output_filename, append=TRUE)
    #ids_in_both <- ids_in_both[ order(ids_in_both) ]
    ids_only_in_data <- setdiff(data_names, metadata_names)
    write( paste("ids_in_data_or_PCoA_only (", length(ids_only_in_data) ,")"), file=output_filename, append=TRUE)
    if(debug==TRUE){ ids_only_in_data.test<<-ids_only_in_data }
    #if( length(ids_only_in_data)==0 ){ ids_only_in_data<-"none" }
    ids_only_in_metadata <- setdiff(metadata_names, data_names)
    write( paste("ids_in_metadata_only (", length(ids_only_in_metadata) ,")"), file=output_filename, append=TRUE)
    if(debug==TRUE){ ids_only_in_metadata.test<<-ids_only_in_metadata }
    #if( length(ids_only_in_metadata)==0){ ids_only_in_metadata<-"none" }  

    max_length_lists <- max(length(ids_in_both),length(ids_only_in_data),length(ids_only_in_metadata))
    if(debug){print(paste("max: ",max_length_lists, sep=""))}
    output_matrix <- matrix(data=NA, nrow=max_length_lists, ncol=3)

    if( length(ids_in_both)>0 ){ output_matrix[1:length(ids_in_both),1]<-ids_in_both }
    if( length(ids_only_in_data)>0 ){ output_matrix[1:length(ids_only_in_data),2]<-ids_only_in_data }
    if( length(ids_only_in_metadata)>0 ){ output_matrix[1:length(ids_only_in_metadata),3]<-ids_only_in_metadata }
    
    #output_matrix <- cbind(ids_in_both, ids_only_in_data, ids_only_in_metadata)
    if(debug==TRUE){output_matrix.test<<-output_matrix}
    colnames(output_matrix) <- c("in both", data_out_name, paste("in ", my_metadata," only",sep=""))
    #if( (length(ids_only_in_data) + length(ids_only_in_metadata))==0 ){
    if( (length(ids_only_in_data) + length(ids_only_in_metadata)) == 0 ){
      write("***\t***\t***\t***", file=output_filename, append=TRUE)
      export_data(output_matrix, output_filename)
      print(paste("Data look ok - see output file ( ", output_filename, " ) for details", sep=""))
    }else{
      write("***\t***\t***\t***", file=output_filename, append=TRUE)
      export_data(output_matrix, output_filename)
      print(paste("Data and metadata do not match - see output file ( ", output_filename, " ) for details", sep=""))
    }
  }
  ######################
  ######## OTHER SUBS:
  ######################
  
  # import tab delimited table
  import_data <- function(file_name){
    num_lines_string <- paste("wc -l ", file_name)
    num_lines <- scan(pipe(num_lines_string), what=list(0, NULL))[[1]]  
    data.matrix(read.table(file_name, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE, nrows=num_lines))
  }
  
  # export matrix as tab delimited table
  export_data <- function(data_object, file_name){
    suppressWarnings(write.table(data_object, file=file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n", append=TRUE))
  }
  
  # function to source directly from internet (try devtools for complete R pacakges from github)
  source_https <- function(url, ...) {
    require(RCurl)
    sapply(c(url, ...), function(u) {
      eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
    })
  }
  
  # import metadata
  import_metadata <- function(metadata_file){
    num_lines_string <- paste("wc -l ", metadata_file)
    num_lines <- scan(pipe(num_lines_string), what=list(0, NULL))[[1]]
    metadata_matrix <- as.matrix( # Load the metadata table (same if you use one or all columns)
    read.table(
      file=metadata_file,row.names=1,header=TRUE,sep="\t",
      colClasses = "character", check.names=FALSE,
      comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE, nrows=num_lines
      )
    )   
    metadata_matrix <- metadata_matrix[ order(rownames(metadata_matrix)),,drop=FALSE ]
    return(metadata_matrix)
  }
  ######################
  ######## END SUBS:
  ######################

  ######################
  ######## MAIN:
  ######################

  if( file.exists(output_filename) ){
    print(paste("Deleting old log: ", output_filename, sep=""))
    unlink(output_filename)
  }
  
  if ( is.na(my_data_file) && is.na(my_PCoA) && my_metadata=="" ){
    func_usage()
  }
  
  metadata.matrix <- import_metadata(my_metadata)
  metadata_names <- rownames(metadata.matrix)
  if(debug==TRUE){metadata_names.test<<-metadata_names}
  data_names <- character()
  data_out_name <- character()
  
  if( !(is.na(my_PCoA)) ){
    pcoa_data <- load_pcoa_data(my_PCoA) # import PCoA data from *.PCoA file --- this is always done
    eigen_values <- pcoa_data$eigen_values
    eigen_vectors <- pcoa_data$eigen_vectors
    #data_names <- noquote(rownames(eigen_vectors))
    data_names<-gsub("\"", "", rownames(eigen_vectors))
    #data_out_name <- paste("in_", my_PCoA, "_only", sep="")
    data_out_name  <-  paste("in ", my_PCoA," only",sep="")
    if(debug==TRUE){data_names.test<<-data_names}
  }
  
  if( !(is.na(my_data_file)) ){
    my_data <- import_data(my_data_file)
    data_names <- colnames(my_data)
    #data_out_name <- paste("in_", my_data, "_only", sep="")
    data_out_name  <-  paste("in ", my_data_file," only",sep="")
    if(debug==TRUE){data_names.test<<-data_names}
  }
  
  # checks for unqiueness
  if(!(length(data_names)==length(unique(data_names)))){
    error_string <- paste("There are non unique samples in data or PCoA", sep="")
    print(error_string)
    write(error_string, file=output_filename, append=TRUE)
  }
  
  # checks for unqiueness
  if(!(length(metadata_names)==length(unique(metadata_names)))){
    error_string <- paste("There are non unique samples in ", metadata_names, sep="")
    print(error_string)
    write(error_string, file=output_filename, append=TRUE)
  }
  
  # check for same number of samples
  if(!(length(data_names)==length(metadata_names))){  
    error_string <- paste("The number of samples is different: data(", length(data_names), ") :: metadata(", length(metadata_names),")", sep="")
    print(error_string)
    write(error_string, file=output_filename, append=TRUE)
  }

  if(debug==TRUE){
    data_names.test <<- data_names
    metadata_names.test <<- metadata_names
    data_out_name.test <<- data_out_name
  }
  
  # further checks for discrepencies in samples
  find_discrepancies(data_names, metadata_names, data_out_name)
    
}
