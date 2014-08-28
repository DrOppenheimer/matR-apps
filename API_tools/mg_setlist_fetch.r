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
