matR_batch_dl <<- function(mgid_list, batch_size = 50, my_entry="count", my_annot="func", my_source="Subsystem", my_level="level3"){

  require(matR)
  source_https("https://raw.github.com/braithwaite/matR-apps/master/collection-merge.R")

  if ( exists("my_data")==TRUE ){rm(my_data)}
  
  num_batch <- as.integer( length(mgid_list)%/%batch_size )
  batch_remainder <- length(mgid_list)%%batch_size
  
  for (batch_count in 1:(num_batch)){
    
    if (batch_count == 1){
      print.tic()
      batch_start <- 1
      batch_end <- batch_size
      batch_list = mgid_list[batch_start:batch_end]
      first_batch <- collection(batch_list, count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
      #first_batch.counts <- first_batch$count
      #my_data <<- first_batch.counts
      my_data <<- first_batch
      print(paste("finished with batch", batch_count))
      print.toc()
    }else{
      print.tic()
      batch_start <- (batch_count*batch_size)+1
      batch_end <- (batch_count*(batch_size+1))-1
      batch_list = mgid_list[batch_start:batch_end]
      next_batch <- collection(batch_list, my_count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
      my_data <<- my_data + next_batch
      print(paste("finished with batch", batch_count))
      print.toc()
    }
  }
  
  if ( batch_remainder > 0 ){
    print.tic()
    batch_start <- (num_batch*batch_size)+1
    batch_end <- length(mgid_list)
    batch_list = mgid_list[batch_start:batch_end]
    last_batch <- collection(batch_list, my_count = c(entry=my_entry, annot=my_annot, source=my_source, level=my_level))
    my_data <<- my_data + last_batch
    print(paste("finished with batch", batch_count))
    print.toc()
  }
  
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
  sapply(c(url, ...), function(u) {
    eval(parse(text = getURL(u, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))), envir = .GlobalEnv)
  })
}




# quotient 11%/%5
# remainder 11%%5
# readline() to pause the code
# my_data <- collection(data.list, my_counts = c(entry="count", annot = "func", source = "Subsystem", level = "level3"))
