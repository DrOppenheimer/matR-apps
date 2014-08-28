download_file <- function(mgid=NA, file_id="100.2", unzip_file=TRUE,  destination_dir="/Users/kevin/test_dir", print_setlist=FALSE, auth="default", debug=TRUE){
  
  require(matR)
  require(RCurl)
  require(RJSONIO)
  
  # get the auth from matR
  if( identical(auth,"default") ){ 
    auth=msession$getAuth()
  }else{
    auth="na"
  }
  #### Sub to perform download
  bdown=function(url, file){
    library('RCurl')
    f = CFILE(file, mode="wb")
    a = curlPerform(url = url, writedata = f@ref, noprogress=FALSE)
    close(f)
    return(a)
  }
  
  #### Sub to fetch and optionally display the setlist
  mg_setlist_fetch <- function(mgid, print_setlist){
    my_url <- paste("http://api.metagenomics.anl.gov//download/", mgid, "?name=setlist", sep="")
    my_json <- fromJSON(getURL(my_url))  
    if ( print_setlist==TRUE ){
      for (i in 1:length(my_json)){ 
        my_entry <- my_json[[i]][ c("id", "stage_id", "stage_name", "file_type", "file_name", "file_id", "url" ) ]
        for (j in 1:length(my_entry)){ print(paste( names(my_entry)[j], "::", (my_entry)[j]))  }
        print("##############################################")
      }
    }
    return(my_json)
  }
  
  my_setlist <- mg_setlist_fetch(mgid, print_setlist)
  
  if(debug==TRUE){  my_setlist.test <<- my_setlist }
  
  my_file_name <- NA
  my_file_url <- NA
  for (i in 1:length(my_setlist)){     
    #if(debug==TRUE){ print(my_setlist[[i]]["file_id"])  }
    if (identical(  as.character(my_setlist[[i]]["file_id"]), as.character(file_id) ) ){
      my_file_name <- my_setlist[[i]]["file_name"]
      if(debug==TRUE){print(paste("my_file_name", my_file_name))}
      my_file_url <- my_setlist[[i]]["url"]
      if(debug==TRUE){print(paste("my_file_url", my_file_url))}
    } 
  }    
  
  if( !is.na(mgid) ){  
    new_file_name <- paste(mgid, ".", my_file_name, sep="")
    new_file_name.no_path <- new_file_name
    # create the new directory if it does not exist     
    if( !is.na(destination_dir) ){ 
      dir.create(file.path(destination_dir), showWarnings = FALSE)
      new_file_name <- paste(destination_dir, "/", new_file_name, sep="")
    }  
  }
  
  if(debug==TRUE){print(paste("new_file_name: ", new_file_name))}
  
  if( !is.na(auth) ){
    my_file_url <- paste(my_file_url, "&auth=", auth, sep="" )  
  }
  
  bdown(my_file_url, new_file_name)  
  
  if( unzip_file==TRUE ){
    unzip_string <- paste("gunzip", new_file_name)
    system(unzip_string)
    new_file_name.no_path <- gsub(pattern=".gz$", replacement="", new_file_name.no_path)
  }
  
  return(new_file_name.no_path)
  
}
