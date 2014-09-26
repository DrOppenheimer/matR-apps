metadata_parser <- function(mgids){

# working example
# setwd("/Users/kevin/Documents/Projects/matR/example_analyses.5-7-14/small/HMP")  
# my_ids <- readIDs("HMP_24_list.txt")
# test_metadata <- metadata(my_ids[1])



  
# test_metadata <- fromJSON(getURL(collection_call))
# my_call <- "http://api.metagenomics.anl.gov/metagenome/mgm4472575.3?verbosity=full&auth=ByBRVZnees3EjzVkbVPcbwSsq"
# my_metadata <- fromJSON(getURL(my_call))


test_metadata <- metadata(my_ids[1])
test_metadata[[300]]



  
require(matR)
require(RJSONIO)
require(RCurl)




 metadata_matrix <- as.matrix( # Load the metadata table (same if you use one or all columns)
                              read.table(
                                         file=metadata_table,row.names=1,header=TRUE,sep="\t",
                                         colClasses = "character", check.names=FALSE,
                                         comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                         )
                              )   
    #metadata_matrix <- metadata_matrix[ order(rownames(metadata_matrix)),,drop=FALSE ]  # make sure that the metadata matrix is sorted (ROWWISE) by id
    metadata_matrix <- metadata_matrix[ order(sample_names),,drop=FALSE ]



}
