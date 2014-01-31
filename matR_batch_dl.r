matR_batch_dl <- function(mgid_list, auth="~/my_auth", sleep_int = 10, my_log = "~/my_log.txt", batch_size = 10, my_entry="counts", my_annot="function", my_source="Subsystems", my_level="level3", output_prefix="my_data_matrix", debug=FALSE, verbose=FALSE){

  require(matR) # load matR
  require(RJSONIO)
  require(RCurl)

  ##source_https("https://raw.github.com/braithwaite/matR-apps/master/collection-merge.R") # get the merge function
  
  # Set authentication (key is in file)
  msession$setAuth(file=auth)

  # delete old data
  if ( file.exists(my_log)==TRUE ){ # delete old log if it exist 
    unlink(my_log)
    print( paste("deleted old log:", my_log) )
  }
  
  ## check to see if mgid_list is a character vector or file
  ## If file check for columns - one column, assume it's the ids
  ## If its two columns, first is ids, second is name
  if ( length(mgid_list) > 1 ){

  }else{
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
    mgid_list <- new_list
  }

  # if ( debug==TRUE ){ print("Made it here 5") }
  
  if ( nargs() == 0){print_usage()} # give usage if no arguemtsn are supplied
  if (identical(mgid_list, "") ){print_usage()}  # give usage if empty arguement is supplied for mgid_list
    
  if ( exists("my_data")==TRUE ){
    suppressWarnings(rm(my_data))
    print("deleted previous object named my_data")
  } # delete my_data object if it exists

  num_batch <- as.integer( length(mgid_list)%/%batch_size )
  if (debug==TRUE) {print(paste("num_batch:", num_batch))}
  batch_remainder <- length(mgid_list)%%batch_size
  if (debug==TRUE) {print(paste("batch_remainder:", batch_remainder))}
  
  for (batch_count in 1:(num_batch)){
    
    if (batch_count == 1){ # process first batch
      print.tic()
      batch_start <- 1
      batch_end <- batch_size
      if (debug==TRUE) {print(paste("first batch      -- batch_start:", batch_start, ":: batch_end:", batch_end))}
      batch_list = mgid_list[batch_start:batch_end]
      write(paste("# Starting with with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes" ), file = my_log, append = TRUE)
      write("# batch members:", file = my_log, append = TRUE)
      for (i in 1:length(batch_list)){write(batch_list[i], file = my_log, append = TRUE)}
      
      first_batch <- collection(batch_list, count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
      check_batch <- first_batch$count
            
      collection_call <- msession$urls()[1]
      matrix_call <- msession$urls()[3]
      write(paste("# API_CALL:\n", matrix_call ), file = my_log, append = TRUE)
      write(paste("# API_CALL:\n", collection_call ), file = my_log, append = TRUE)
      
      # Check to see if the querry is complete before proceeding
      API_status_check<- fromJSON(getURL(collection_call))
      current_status <- API_status_check['status']      
      while ( grepl(current_status, "done")==FALSE ){
        Sys.sleep(sleep_int)
        sleep_int <- sleep_int+10
        print( paste("Sleeping for (", sleep_int, ") more seconds - waiting for call to complete") )
        write(paste("# API_CALL:\n", collection_call, sep="", collapse=""), file = my_log, append = TRUE)
        write( paste("# Sleeping for (", sleep_int, ") more seconds - waiting for call to complete", sep="", collapse=""), file = my_log, append = TRUE )
        API_status_check<- fromJSON(getURL(collection_call))
        current_status <- API_status_check['status']
      }
      sleep_int <- 10
       
      #if ( debug==TRUE ){ print(paste("# API_CALL:\n", msession$urls()[1] ), file = my_log, append = TRUE) }
      my_data <<- first_batch
      #if ( verbose==TRUE ){ print(paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes" )) }
      print( paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes", sep="", collapse="" ), file = my_log, append = TRUE )
      write( paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes", sep="", collapse="" ), file = my_log, append = TRUE )
      
      
      write("# DONE \n# time: user.self sys.self elapsed user.child sys.child", file = my_log, append = TRUE)
      write(print.toc(), file = my_log, append = TRUE)
      write("\n", file = my_log, append = TRUE)
    }else{ # process all batches except first and remainder
      print.tic()
      batch_start <- ((batch_count-1)*batch_size)+1
      batch_end <- (batch_count*batch_size)
      if (debug==TRUE) {print(paste("continuing batch -- batch_start:", batch_start, ":: batch_end:", batch_end))}
      batch_list = mgid_list[batch_start:batch_end]

      if ( verbose==TRUE ){ print(paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes" )) }    
      write(paste("# Starting batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes"  ),file = my_log, append = TRUE)
      write("# batch members", file = my_log, append = TRUE)
      for (i in 1:length(batch_list)){write(batch_list[i], file = my_log, append = TRUE)}
      next_batch <<- collection(batch_list, count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
      check_batch <- next_batch$count

      collection_call <- msession$urls()[1]
      matrix_call <- msession$urls()[3]
      write(paste("# API_CALL:\n", matrix_call ), file = my_log, append = TRUE)
      write(paste("# API_CALL:\n", collection_call ), file = my_log, append = TRUE)
            
      API_status_check<- fromJSON(getURL(collection_call))
      current_status <- API_status_check['status']      
      while ( grepl(current_status, "done")==FALSE ){
        Sys.sleep(sleep_int)
        sleep_int <- sleep_int+10
        print( paste("Sleeping for (", sleep_int, ") more seconds - waiting for call to complete") )
        write(paste("# API_CALL:\n", collection_call, sep="", collapse="" ), file = my_log, append = TRUE)
        write( paste("# Sleeping for (", sleep_int, ") more seconds - waiting for call to complete", sep="", collapse=""), file = my_log, append = TRUE )
        API_status_check<- fromJSON(getURL(collection_call))
        current_status <- API_status_check['status']
      }
      sleep_int <- 10

      #my_data <<- my_data + next_batch # This does not handle metadata yet
      my_data <<- merge(my_data$count, next_batch$count, by="row.names", all=TRUE) # This does not handle metadata yet
      rownames(my_data) <<- my_data$Row.names
      my_data$Row.names <<- NULL

      print( paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes", sep="", collapse="" ), file = my_log, append = TRUE )
      write( paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes", sep="", collapse="" ), file = my_log, append = TRUE )
      write("# DONE \n# time: user.self sys.self elapsed user.child sys.child", file = my_log, append = TRUE)
      write(print.toc(), file = my_log, append = TRUE)
      write("\n", file = my_log, append = TRUE)
    }
  }
  
  if ( batch_remainder > 0 ){ # process remainder batch
    print.tic()
    batch_start <- (num_batch*batch_size)+1
    batch_end <- length(mgid_list)
    if (debug==TRUE) {print(paste("last batch         -- batch_start:", batch_start, ":: batch_end:", batch_end))}
    batch_list = mgid_list[batch_start:batch_end]
    
    write(paste("# Starting batch", (batch_count + 1), ":: with", (batch_end - batch_start + 1), "metagenomes"  ),file = my_log, append = TRUE)
    write("# batch members", file = my_log, append = TRUE)
    for (i in 1:length(batch_list)){write(batch_list[i], file = my_log, append = TRUE)}
    
    last_batch <- collection(batch_list, count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
    check_batch <- last_batch$count

    collection_call <- msession$urls()[1]
    matrix_call <- msession$urls()[3]
    write(paste("# API_CALL:\n", matrix_call ), file = my_log, append = TRUE)
    write(paste("# API_CALL:\n", collection_call ), file = my_log, append = TRUE)
    
    API_status_check<- fromJSON(getURL(collection_call))
    current_status <- API_status_check['status']      
    while ( grepl(current_status, "done")==FALSE ){
      Sys.sleep(sleep_int)
      sleep_int <- sleep_int+10
      print( paste("Sleeping for (", sleep_int, ") more seconds - waiting for call to complete") )
      write(paste("# API_CALL:\n", collection_call, sep="", collapse="" ), file = my_log, append = TRUE)
      write( paste("# Sleeping for (", sleep_int, ") more seconds - waiting for call to complete"), file = my_log, append = TRUE )
      API_status_check<- fromJSON(getURL(collection_call))
      current_status <- API_status_check['status']
    }
    sleep_int <- 10
    
    #my_data <<- my_data + last_batch # This does not handle metadata yet
    my_data <<- merge(my_data$count, last_batch$count, by="row.names", all=TRUE) # This does not handle metadata yet
    rownames(my_data) <<- my_data$Row.names
    my_data$Row.names <<- NULL

    print( paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes", sep="", collapse="" ), file = my_log, append = TRUE )
    write( paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes", sep="", collapse="" ), file = my_log, append = TRUE )
    write("# DONE \n# time: user.self sys.self elapsed user.child sys.child", file = my_log, append = TRUE)
    write(print.toc(), file = my_log, append = TRUE)
    write("\n", file = my_log, append = TRUE)
    
  }

  ###### replace NA's with 0
  #my_data.matrix <<- my_data$count
  #my_data_matrix <<- my_data
  #my_data.matrix[ is.na(my_data.matrix) ]<-0
  my_data[ is.na(my_data) ]<-0

  
  # write output to a file
  my_output = gsub(" ", "", paste(output_prefix, ".", my_entry, ".txt"))
  write.table(my_data, file = my_output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  print(paste("data available as matrix: my_data.matrix and flat file:", my_output))
  write("### ALL DONE ###", file = my_log, append = TRUE)

  # delete data object from memory
  if ( exists("my_data")==TRUE ){ 
    rm(my_data)
  } # get rid of dupilcate data
  
}


################################################################

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

