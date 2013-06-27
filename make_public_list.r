# you need two R pacakages
# RCurl and RJSONIO

# 0 returns all public
# integers return speicified number of mg's
# don't now how it will fail if you request more mg's than exist

make_public_list<- function(num_mg=10){

  require(RJSONIO, RCurl)		 

  my_call <- paste("http://api.metagenomics.anl.gov/metagenome?limit=", num_mg, sep="")
  
  my_json <- fromJSON(getURL(my_call))
  
  my_mgid_list <- vector(mode = "character", length = num_mg)
  
  for (i in 1:num_mg){
    my_mgid_list[i] <- as.character(my_json$data[[1]]['id'])
  }
  
  return(my_mgid_list)
  
}
