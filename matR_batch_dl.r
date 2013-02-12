matR_batch_dl <<- function(mgid_list, sleep_int = 0, my_log = "my_log.txt", batch_size = 50, my_entry="count", my_annot="func", my_source="Subsystem", my_level="level3", debug=FALSE, verbose=TRUE){

  if ( nargs() == 0){print_usage()} # give usage if no arguemtsn are supplied
  if (identical(mgid_list, "") ){print_usage()}  # give usage if empty arguement is supplied for mgid_list

  if ( file.exists(my_log)==TRUE ){ # delete old log if it exist 
    unlink(my_log)
    print( paste("deleted old log:", my_log) )
  }
  
  require(matR) # load matR
  source_https("https://raw.github.com/braithwaite/matR-apps/master/collection-merge.R") # get the merge function

  if ( exists("my_data")==TRUE ){
    rm(my_data)
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
      write(paste("# API_CALL:\n", msession$urls()[1] ), file = my_log, append = TRUE)
      #first_batch.counts <- first_batch$count
      #my_data <<- first_batch.counts
      my_data <<- first_batch
      Sys.sleep(sleep_int)
      if ( verbose==TRUE ){ print(paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes" )) }
      #write(paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes" ), file = my_log, append = TRUE)
      
      #write("# batch members:", file = my_log, append = TRUE)
      #for (i in 1:length(batch_list)){write(batch_list[i], file = my_log, append = TRUE)}
      write("# DONE \n#time: user.self sys.self elapsed user.child sys.child", file = my_log, append = TRUE)
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
      next_batch <- collection(batch_list, count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
      write(paste("# API_CALL:\n", msession$urls()[1] ), file = my_log, append = TRUE)
      
      my_data <<- my_data + next_batch
      #if ( verbose==TRUE ){ print(paste("# finished with batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes" )) }    
      #write(paste("# finished batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes"  ),file = my_log, append = TRUE)
      Sys.sleep(sleep_int)
      #write("# batch members", file = my_log, append = TRUE)
      #for (i in 1:length(batch_list)){write(batch_list[i], file = my_log, append = TRUE)}
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

    write(paste("# Starting batch", batch_count, ":: with", (batch_end - batch_start + 1), "metagenomes"  ),file = my_log, append = TRUE)
    write("# batch members", file = my_log, append = TRUE)
    for (i in 1:length(batch_list)){write(batch_list[i], file = my_log, append = TRUE)}

    last_batch <- collection(batch_list, count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
    write(paste("# API_CALL:\n", msession$urls()[1] ), file = my_log, append = TRUE)
    my_data <<- my_data + last_batch

    write("# DONE \n# time: user.self sys.self elapsed user.child sys.child", file = my_log, append = TRUE)
    write(print.toc(), file = my_log, append = TRUE)
    write("\n", file = my_log, append = TRUE)
    
if ( verbose==TRUE ){ print(paste("# finished with batch", (batch_count + 1), ":: with", (batch_end - batch_start + 1), "metagenomes" )) }
    write(paste("# finished batch", (batch_count + 1), ":: with", (batch_end - batch_start + 1), "metagenomes"  ), file = my_log, append = TRUE)
    write("# batch members", file = my_log, append = TRUE)
    for (i in 1:length(batch_list)){write(batch_list[i], file = my_log, append = TRUE)}
    write("# DONE \n# time: user.self sys.self elapsed user.child sys.child", file = my_log, append = TRUE)
    write(print.toc(), file = my_log, append = TRUE)
    write("\n", file = my_log, append = TRUE)
  }


  
  ###### replace NA's with 0
  my_data.matrix <<- my_data$count
  my_data.matrix[ is.na(my_data.matrix) ]<-0
  if ( exists("my_data")==TRUE ){
    rm(my_data)
  } # get rid of dupilcate data
  
  # write output to a file
  
  my_output = "my_data.matrix.txt"
  write.table(my_data.matrix, file = my_output, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  print(paste("data available as matrix: my_data.matrix \nand flat file:", my_output))
  
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
}


print_usage <- function() {
  writeLines("  ------------------------------------------------------------------------------
  matR_batch_dl.r
  ------------------------------------------------------------------------------
  DESCRIPTION:
  This script perform a batch download using Dan's matR-apps collection-merge

  USAGE:
  (mgid_list, sleep_int = 0, my_log = \"my_log.txt\", batch_size = 50, my_entry=\"count\", my_annot=\"func\", my_source=\"Subsystem\", my_level=\"level3\", debug=FALSE, verbose=TRUE){

  ")
  stop("You are vieiwing the usage because you did not supply an mgid_list")
}

# quotient 11%/%5
# remainder 11%%5
# readline() to pause the code
# my_data <- collection(data.list, my_counts = c(entry="count", annot = "func", source = "Subsystem", level = "level3"))
