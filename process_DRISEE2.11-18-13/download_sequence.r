download_sequence <- function(
                         mgid = "mgm4473069.3",
                         mg_key = NULL,
                         log = "download_sequence.log"
                         )
{
  
  require(RCurl)
  require(RJSONIO)
  
  if ( identical( mg_key, NULL ) )
    {
      my_call.downloads <- paste("http://api.metagenomics.anl.gov/download/", mgid, sep="", collapse="")
    }else{
      # not implemented yet - auth is not properlay formatted here
      # my_call.downloads <- paste("http://api.metagenomics.anl.gov/download/", mgid, "&auth=", mg_key, sep="", collapse="")
      stop("calls with authentication are not yet supported")
    } 

  # get the information for the uploaded sequence data
  my_api.call <- fromJSON(getURL(my_call.downloads))
  seq_mgid <- (my_api.call)[1][[1]]['id']
  seq_type <- (my_api.call)[1][[1]]['file_type']
  seq_url <- (my_api.call)[1][[1]]['url']
  seq_filename <- (my_api.call)[1][[1]]['file_name']

  unzipped_filename <- paste( seq_mgid, ".", paste="", seq_type, sep="", collapse="" )

  write(
        paste(
              "migid            : ", mgid, "\n",
              "download_api_call: ", my_call.downloads, "\n",
              "seq_mgid         : ", seq_mgid, "\n",
              "seq_type         : ", seq_type, "\n",
              "seq_url          : ", seq_url, "\n",
              "seq_filename     : ", seq_filename, "\n",
              "unzipped_filename: ", unzipped_filename,
              sep="",
              collapse=""
              ),
        file = log
        )

  system_command <- paste( "curl ", "'", seq_url, "'"," | gunzip > ", unzipped_filename, sep="", collapse="")
  
  system(system_command)
  
  write("Download Done\n", file=log, append=TRUE)

}


