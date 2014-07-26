# Example on screening data by evalue with matR
# Most of this will be automated in the near future, but
# is helpful if you need to do this sort of screening now, and want to learn a little more about matR and R

# create list of ids
my_idList <- readIDs("file_with_ids")

# create views for counts and evalues
view_counts <- c(entry="counts", annot="function", level="level3", source="Subsystems" )
view_evals <- c(entry="evalue", annot="function", level="level3", source="Subsystems" )

# create collection with both views
my_collection <- collection(my_idList, list(counts=view_counts, evals=view_evals))

# you now have a collectionf with "counts" and "evals" matrices in it try these
my_collection$counts
my_collection$evals
# if you get the "data pending" message, just try again a few minutes later - download is stil in progess
# cell in counts corresonds to the same cell in evals
# note that evals represent thet average evalue exponent for all grouped annotations
# i.e. my_collection$evals[1,1] contains the average evalue exponent for all annotations counted in my_collection$counts[1,1]


# filter the counts by the evalues
# first select an exponent value to filter by
# I would recommend not to just use a value picked out of the air -- you can look at the
# distribution of evalue exponets easily like this:

hist( my_collection$evals ) # note that most of the data has evalue exponent > -5

# just for the sake of the example, say you want to apply a pretty stringent evalue filter

# first select the exponent filter value
eval_filter = -6

# lets see the sum of counts in each colmn
col_sums.pre_filter <- colSums(my_collection$counts)

# get the dimensions of the matrices
num_rows_counts <- nrow(my_collection$counts)
num_cols_counts <- ncol(my_collection$counts)

num_rows_evals <- nrow(my_collection$counts)
num_cols_evals <- ncol(my_collection$counts)

# probably a good idea to make sure that the counts and evalue matrices are the same size -- shoud be unless there is a problem
# check the row count
if ( num_rows_counts == num_rows_evals ){
  print(paste("same numer of rows: (", num_rows_counts,")"))
}else{
  print(paste("num rows differs between counts (", num_rows_counts, ") and evalues (", num_rows_evals, ")" ))
}
# then check the column count
if ( num_cols_counts == num_cols_evals ){
  print(paste("same numer of rows: (", num_cols_counts,")"))
}else{
  print(paste("num rows differs between counts (", num_cols_counts, ") and evalues (", num_cols_evals, ")" ))
}

# export the counts and evalue matrices so they are no longer in a matR collection
counts_matrix <- my_collection$counts
evals_matrix <- my_collection$evals

# now use a nested loop to go through all of the count values, replacing them with 0 if the corresponding evalue > filter
for (i in 1:num_rows){
  for (j in 1:num_cols){
    if( evals_matrix[i,j] > eval_filter ){
      counts_matrix[i,j] <- 0
    }
    
  }
} 

# Now look at the sum of columns after filtering -- would guess it should be pretty different from before
col_sums.post_filter <- colSums(counts_matrix) # compare to col_sums.pre_filter from above

# use the remove.singletons function 
# first look at dimensions of the data before singleton removal
dim(counts_matrix)
# remove the singletons
counts_matrix.sg_rm <- remove_singletons(counts_matrix)
# check dimensions after                                      
dim(counts_matrix.sg_rm)
# you'll see that a lot of the rows have been removed

# you can normalize at this point
counts_matrix.sg_rm.norm <- normalize(counts_matrix.sg_rm)

# and then place the non normalized(counts_matrix.sg_rm) or normalized (counts_matrix.sg_rm.norm) value back into a matR collection
counts_matrix.sg_rm.norm.collection <- as(counts_matrix.sg_rm.norm, "collection")
# you can ignore tha warnings -- currently the metadat  is dumped
# now your counts are in counts_matrix.sg_rm.norm.collection$x

# you can treat counts_matrix.sg_rm.norm.collection as you would any other collection for analysis


