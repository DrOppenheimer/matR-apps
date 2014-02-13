matR_batch_dl <- function(
                          mgid_list,    # file with list of IDs - no header
                          list_is_file=TRUE,
                          print_list=FALSE, # print copy of list of ids to variable "my_list"
                          start_sample=1, # list entry to start with
                          start_batch=1, # batch to start with
                          auth="~/my_auth", # file with auth key
                          sleep_int = 10, # initial sleep time (in seconds) -- incremented by 10 with each sleep
                          my_log = "default", # name for the log file
                          batch_size = 50, # number of IDs to process at one time (100 is the hard coded limit for the API - would suggest much smaller)
                          my_entry="counts", 
                          my_annot="function",
                          my_source="Subsystems",
                          my_level="level3",
                          my_data_name = "default", # name for the data object
                          output_prefix="my_data_matrix",
                          debug=FALSE,
                          verbose=TRUE
                          ){

  # NOTE: -- If this fails -- make sure that you are using the most up to date matR
  # get the zip from here https://github.com/MG-RAST/matR
  # install it like this install.packages("~/some_path/matR-master", repos=NULL, type="source")
  # also make sure that RCurl and RJSONIO are installed
  
  # check for necessary arguments - show usage if they are not supplied
  if ( nargs() == 0){print_usage()} 
  if (identical(mgid_list, "") ){print_usage()}

  # create name for "default" log
  if ( identical(my_log, "default")==TRUE ){ my_log=paste(mgid_list,".download_log",sep="", collapse="") }
  
  # load required pacakges
  require(matR) 
  require(RJSONIO)
  require(RCurl)

  if( debug==TRUE ){ print("made it here 1") }
  # source Dan's matR object merging script
  ##source_https("https://raw.github.com/braithwaite/matR-apps/master/collection-merge.R") # get the merge function
  
  # Set authentication (key is in file)
  msession$setAuth(file=auth)
  
  # delete old log file if it exists
  ## if ( file.exists(my_log)==TRUE ){ # delete old log if it exist 
  ##   unlink(my_log)
  ##   print( paste("deleted old log:", my_log) )
  ## }

  # delete my_data object if it exists
  if ( exists("my_data")==TRUE ){
    suppressWarnings(rm(my_data))
    print("deleted previous object named my_data")
  } 

  ## check to see if mgid_list is a character vector or file
  ## If it's a file check for columns - one column, assume it's the ids
  ## If it's two columns, first is ids, second is name
  #if ( length(mgid_list) > 1 ){

  if (list_is_file==TRUE){
    temp_list <- read.table(mgid_list)
    num_samples <- dim(temp_list)[1]
    new_list <- vector(mode="character", length=num_samples)
    for( i in 1:num_samples ){ # add ids to list
      new_list[i] <- as.character(temp_list[i,1])
    }
    if( dim(temp_list)[2] == 2 ){ # name the ids in the list -- if names were supplied
      for( j in 1:num_samples ){
        names(new_list)[j] <- as.character(temp_list[j,2])
      }
    }
    mgid_list <- new_list[start_sample:num_samples]
  }

  # make sure the id list has only unique ids
  mgid_list <- levels(as.factor(mgid_list))

  if (print_list==TRUE){ my_list <<- mgid_list }
  
  write( date(), file = my_log, append = TRUE)
  # calculate and print some information to the log
  num_batch <- as.integer( length(mgid_list)%/%batch_size )
  batch_remainder <- length(mgid_list)%%batch_size
  write(
        paste(
              "# Num unique samples:   ", length(mgid_list), "\n", 
              "# Batch size:           ", batch_size, "\n",
              "# Num complete batches: ", num_batch, "\n",
              "# Remainder batch size: ", batch_remainder, "\n",
              sep="",
              collapse=""
              ),
        file = my_log,
        append = TRUE
        )

  ############################################################################
  # MAIN LOOP - PROCESSES ALL BATCHES EXCEPT (IF THERE IS ONE) THE REMAINDER #
  ############################################################################
  this_is_first_batch = TRUE
  for (batch_count in start_batch:(num_batch)){

    # Process the first batch
    if( this_is_first_batch==TRUE ){
      this_is_first_batch=FALSE
      #if (batch_count == 1){ 

      # calculate start and stop (will be one unless first_batch is > 1) 
      batch_start <- ((batch_count-1)*batch_size)+1
      batch_end <- (batch_count*batch_size)
      
      # Get the first batch of data and use to initialize my_data object
      batch_start <- 1
      batch_end <- batch_size
      first_batch <- process_batch(batch_count, batch_start, batch_end, mgid_list, my_log, my_entry, my_annot, my_source, my_level, sleep_int, debug)
      my_data <- data.matrix(first_batch$count)

      # write information to the log
      write(
            paste(
                  "# finished with batch (", batch_count, ") :: with (", (batch_end - batch_start + 1), ") metagenomes",
                  sep="",
                  collapse=""
                  ),
            file = my_log,
            append = TRUE
            )
      write( date(), file = my_log, append = TRUE)
      write("\n\n", file = my_log, append = TRUE)

      # replace NA's with 0
      my_data[ is.na(my_data) ]<-0

      # write current data to file
      my_output = gsub(" ", "", paste(output_prefix,".BATCH_", batch_count,".", my_entry, ".txt"))
      write.table(my_data, file = my_output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
      
    }else{ # process all batches except first and remainder

      # Process the continuing (next) batch
      batch_start <- ((batch_count-1)*batch_size)+1
      batch_end <- (batch_count*batch_size)
      next_batch <- process_batch(batch_count, batch_start, batch_end, mgid_list, my_log, my_entry, my_annot, my_source, my_level, sleep_int, debug)
      
      # Add the next batch to my_data
      my_data <- merge(my_data, data.matrix(next_batch$count), by="row.names", all=TRUE) # This does not handle metadata yet
      rownames(my_data) <- my_data$Row.names
      my_data$Row.names <- NULL

      # write information to the log
      write(
            paste(
                  "# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes",
                  sep="",
                  collapse=""
                  ),
            file = my_log,
            append = TRUE
            )
      write( date(), file = my_log, append = TRUE)
      write("\n\n", file = my_log, append = TRUE)
      
      # replace NA's with 0
      my_data[ is.na(my_data) ]<-0

      # write current data to file
      my_output = gsub(" ", "", paste(output_prefix,".BATCH_1_to_", batch_count,".", my_entry, ".txt"))
      write.table(my_data, file = my_output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
      
    }
  }

  # process remainder batch
  if ( batch_remainder > 0 ){ 

    # Process the last batch (if there is a remainder
    batch_start <- (num_batch*batch_size)+1
    batch_end <- length(mgid_list)
    last_batch <- process_batch( (batch_count+1) , batch_start, batch_end, mgid_list, my_log, my_entry, my_annot, my_source, my_level, sleep_int, debug)

    # Add the next batch to my_data
    my_data <- merge(my_data, data.matrix(last_batch$count), by="row.names", all=TRUE) # This does not handle metadata yet
    rownames(my_data) <- my_data$Row.names
    my_data$Row.names <- NULL

    # write information to the log
    write(
          paste(
                "# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes",
                sep="",
                collapse=""
                ),
            file = my_log,
          append = TRUE
          )
    write( date(), file = my_log, append = TRUE)
    write("\n\n", file = my_log, append = TRUE)
      
    # replace NA's with 0
    my_data[ is.na(my_data) ]<-0

    # write current data to file
    my_output = gsub(" ", "", paste(output_prefix,".BATCH_1_to_", (batch_count+1) ,".", my_entry, ".txt"))
    write.table(my_data, file = my_output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
    #rm(my_data)
    
  }

  # write final outputs
  my_output = gsub(" ", "", paste(output_prefix,".ALL_BATCHES.", my_entry, ".txt"))
  write.table(my_data, file = my_output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

   # rename the R object in memory if that option was selected - otherwise, named as mgid_list.data
  if ( identical(my_data_name, "default")==TRUE ){
    if ( debug==TRUE ){ print("made it into rename loop A") }
    my_data_name <- paste(mgid_list, ".data", sep="", collapse="" )
    data_name <- my_data_name
    assign( my_data_name, my_data )
  }else{
    if ( debug==TRUE ){ print("made it into rename loop B") }
    data_name <- my_data_name
    assign( my_data_name, my_data )
  }
  
  # create named object with downloaded data avaialable in the workplace
  my_data_name <<- my_data_name
    
  #print(paste("data available as data.matrix: my_data and as flat file ", my_output, sep="", collapse=""))
  write( paste("data available as data.matrix: ", data_name," and as flat file: ", my_output, sep="", collapse=""), file = my_log, append = TRUE ) 
  print( paste("data available as data.matrix: ", data_name," and as flat file: ", my_output, sep="", collapse=""), file = my_log, append = TRUE )
    
  # cleanup of temp data object
  if ( exists("my_data")==TRUE ){ 
      rm(my_data)
    }
  
}
  
############################################################################
############################################################################
############################################################################
### SUBS

process_batch <- function(batch_count, batch_start, batch_end, mgid_list, my_log, my_entry, my_annot, my_source, my_level, sleep_int, debug){

  if( debug==TRUE ){ print("made it to process_batch 1") }
  
  # create list of ids in the batch from the main list
  batch_list = mgid_list[batch_start:batch_end]

  # write batch informatin to log
  write( date(), file = my_log, append = TRUE)
  write( paste("BATCH:", batch_count," :: batch_start(", batch_start, ") batch_end(", batch_end, ")", sep="", collapse="" ), file = my_log, append = TRUE)
  write( paste("# batch ( ", batch_count, ") members:", file = my_log, append = TRUE) )
  for (i in 1:length(batch_list)){ write(batch_list[i], file = my_log, append = TRUE) }

  if( debug==TRUE ){ print("made it to process_batch 2") }
  # make the call
  current_batch <- collection(batch_list, count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
  if( debug==TRUE ){ print("made it to process_batch 3") }
  if( debug==TRUE ){ debug_batch <<- current_batch}
  
  check_batch <- current_batch$count
  
  if( debug==TRUE ){ print("made it to process_batch 4") }
  
  collection_call <- msession$urls()[1]
  matrix_call <- msession$urls()[2]
  write(paste("# API_CALL (matrix_call):\n", matrix_call ), file = my_log, append = TRUE)
  write(paste("# API_CALL (status_call):\n", collection_call ), file = my_log, append = TRUE)

  
  # check the status of the call -- proceed only when the data are available
  check_status(collection_call, sleep_int, my_log, debug)
      
  return(current_batch)
}



check_status <- function (collection_call, sleep_int, my_log, debug)  {

  if( debug==TRUE ){ print("made it to check_status function") }
  API_status_check<- fromJSON(getURL(collection_call))
  current_status <- API_status_check['status']      
  while ( grepl(current_status, "done")==FALSE ){
    Sys.sleep(sleep_int)
    sleep_int <- sleep_int+10
    print( paste("Sleeping for (", sleep_int, ") more seconds - waiting for call to complete") )
    write(paste("# API_CALL: (status check)\n", collection_call, sep="", collapse="" ), file = my_log, append = TRUE)
    write( paste("# Sleeping for (", sleep_int, ") more seconds - waiting for call to complete", sep="", collapse=""), file = my_log, append = TRUE )
    API_status_check<- fromJSON(getURL(collection_call))
    current_status <- API_status_check['status']
  }
  
}
     


print.tic <- function(x,...) {
    if (!exists("proc.time"))
        stop("cannot measure time")
    gc(FALSE)
    assign(".temp.tictime", proc.time(), envir = .GlobalEnv)
}

print.toc <- function(x,...) {
    if (!exists(".temp.tictime", envir = .GlobalEnv))
        stop("Did you tic?")
    time <- get(".temp.tictime", envir = .GlobalEnv)
    rm(".temp.tictime", envir = .GlobalEnv)
    print(res <- structure(proc.time() - time,
                           class = "proc_time"), ...)
    invisible(res)
}



source_https <- function(url, ...) {
  require(RCurl)
  sapply(c(url, ...), function(u) { eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv) } )
} # Sourced code is commented out below in case you need it



print_usage <- function() {
  writeLines("  ------------------------------------------------------------------------------
  matR_batch_dl.r
  ------------------------------------------------------------------------------
  DESCRIPTION:
  This script perform a batch download using Dan's matR-apps collection-merge

  USAGE:
  (mgid_list, sleep_int = 10, my_log = \"my_log.txt\", batch_size = 50, my_entry=\"count\", my_annot=\"func\", my_source=\"Subsystem\", my_level=\"level3\", debug=FALSE, verbose=TRUE){

  ")
  stop("You are vieiwing the usage because you did not supply an mgid_list")
}

# quotient 11%/%5
# remainder 11%%5
# readline() to pause the code
# my_data <- collection(data.list, my_counts = c(entry="count", annot = "func", source = "Subsystem", level = "level3"))


############# DAN's MERGE FUNCTION (BUGGED)
## setMethod ("+", signature ("collection", "collection"), 
##           function (e1, e2) {
## #             mm <- merge (e1$count, e2$count, all = TRUE, by = 0, sort = TRUE)
## #             rownames (mm) <- mm$Row.names
## #             mm$Row.names <- NULL
## #             as.matrix (mm)

##             cc <- new("collection")
##             mm <- character (0)
##             class (mm) <- "metadata"
##             cc@sel <- new ("selection",
##             							 ids = append (e1@sel@ids, e2@sel@ids),
##             							 groups = as.factor (append (groups (e1), groups (e2))),
##             							 metadata = mm)
            
##             if (length (metadata (e1)) != 0 && length (metadata (e2)) != 0) 
##             	warning ("dropping metadata")

##             n <- sum (is.null (names (e1)), is.null (names (e2)))
##             if (n == 1) warning ("not both collections are named; dropping names")
##             else if (n == 2) names (cc) <- append (names (e1), names (e2))

##             v <- intersect (viewnames (e1), viewnames (e2))
##             if (!identical (viewnames (e1), viewnames (e2)))
##           		warning ("only views with names in common will be retained: ", paste (v, collapse = ", "))

##             cc@views <- list()
##             for (j in v) {
##             	view <- matR:::view.of.matrix (e1@views [[j]])
##             	if (!identical (view, matR:::view.of.matrix (e2@views [[j]]))) {
##             		warning ("not-same views named same; dropping: ", j)
##             		next
##             	}

##             	m <- merge (e1@views [[j]], e2@views [[j]], all = TRUE, by = 0, sort = TRUE)
##               rownames (m) <- m$Row.names
##               m$Row.names <- NULL
##             	m <- as.matrix (m)
##             	attributes (m) [names (view)] <- view

##             	cc@views [[j]] <- m
##             }
##             cc
##           } )

