# Example on screening data by evalue with matR
# Most of this will be automated in the near future, but
# is helpful if you need to do this sort of screening now, and want to learn a little more about matR and R

# Hi Rima
# This code should do what you want
# You will have to run through the entire script to get the filtered values
# You can comment out and edit commands as needed.
# I'd recommend running it with RStudio - you can change values as needed
# Let me know if you have any questions or problems

# If at any step you get stuck, run this command
msession$debug()
# and send me the file it generates


# INSTALLTION NOTE (October 2014) We are in the process of updating matR code - during this time, it is possible that some matR functionality be temporarily unavaialable in the most current version.
# To install the last stable release of matR, you can use the following commands:
# uninstall current matR
remove.packages("matR")
# install devtools, then use it to install matR from the July 10 2014 commit
library(devtools)
install_github(repo="MG-RAST/matR", dependencies=FALSE, ref="3d068d0c4c644083f588379ca111a575a409c797")
library(matR)
dependencies()



# get auth token for private data
msession$setAuth(file="~/my_key.txt")
# see https://groups.google.com/forum/#!topic/matr-forum/R1anCspxiHs
# for more details on using private data / private data tokens

# use setwd to get into the directory that contains rima_ids.txt
setwd("~/Desktop/my_dir")

# import list of ids
my_ids <- readIDs("rima_ids.txt")

# use variables to fill in my view later
# below values are set for download of level 3 subsystem based functional abundances
my_annot = "function" # c("function, "organism")
my_level = "level3" # many choices - depends function and source
my_source = "Subsystems" # many possibilities

# create view for the counts and parameters that you want to filter them with
my_views <- list(
                 my_counts=     c(entry="counts",     annot=my_annot, level=my_level, source=my_source),
                 my_avg_evalues=c(entry="evalue",     annot=my_annot, level=my_level, source=my_source),
                 my_avg_length= c(entry="length",     annot=my_annot, level=my_level, source=my_source),
                 my_avg_pid=    c(entry="percentid",  annot=my_annot, level=my_level, source=my_source)
                 )


# DEBUG TEST
length_view <-  list( my_avg_length= c(entry="length",     annot=my_annot, level=my_level, source=my_source) )
my_length_collection <- collection(my_ids, length_view)



# perform download, creating a matR collection that will contain all 4 types of data for the selected metagenomes
my_collection <- collection(my_ids, my_views)
# This step could take a while -- 
# Before proceeding to the next step, make sure that all of the data are downloaded.
# Issue these commands to check.
my_collection$my_counts
my_collection$my_avg_evalues
my_collection$my_avg_length # note that this is the length of the hit of the in silco translated protein
my_collection$my_avg_pid
# If you get a ..."data is pending" ... for any of the above, wait a few minutes and try again
# When you see a matrix for all of the above, you can proceed.

# export the 4 matrix objects (not competely necessary - but makes things a little easier later)
my_counts.matrix      <- my_collection$my_counts
my_avg_evalues.matrix <- my_collection$my_avg_evalues 
my_avg_length.matrix  <- my_collection$my_avg_length
my_avg_pid.matrix     <- my_collection$my_avg_pid

# for fun you can look at the distribution of each type of value in your data
# All values in all samples at the same time (historgram)
split.screen(c(2,2))
screen(1)
hist(my_counts.matrix)
screen(2)
hist(my_avg_evalues.matrix)
screen(3)
hist(my_avg_length.matrix) # note that this is the length of the hit of the in silco translated protein
screen(4)
hist(my_avg_pid.matrix)
# sometimes looking at the values can give you a better idea of where you should place
# your cutoffs --- alternatively, if to many/few values are removed, this will allog you
# to see why 
# Values separated by sample (boxplots)
dev.new() # creates a new graphical object so the old one isn't written over
split.screen(c(2,2))
screen(1)
boxplot(my_counts.matrix, las=2, main="counts")
screen(2)
boxplot(my_avg_evalues.matrix, las=2, main="avg_evalue")
screen(3)
boxplot(my_avg_length.matrix, las=2, main="avg_length(in silico translated protein hits)")
screen(4)
boxplot(my_avg_pid.matrix, las=2, main="avg_pid")


# place my filter values in variables -- filters will remove all values above(above *_min) or below(below *_max) the indicate value
# Values are currently set to MG-RAST defaults; these will obviously need to be edited per your requirements.
my_avg_evalue_max <- 1E-06 # avg evalue for hits
my_avg_length_min <- 35 # avg length of hits (translated protein length)
my_avg_pid_min    <- 60 # MG-RAST does not have a pid filter by default

# apply 
# now use a nested loop to go through all of the count values, replacing them with 0 if they do not meet the filter
# In each of the loops, abundance values with a filtered value (e.g. avg evalue) that does not pass the filter
# are replcaed with 0
# Then all of the abundance rows that contain only zeros are removed

# make a copy of the abundance values that will be modified by filtering
my_counts.filtered.matrix <- my_counts.matrix

# filter abundances by evalue
for (i in 1:nrow(my_counts.filtered.matrix)){
  for (j in 1:ncol(my_counts.filtered.matrix)){
    if( my_avg_evalues.matrix[i,j] > my_avg_evalue_max ){
      my_counts.filtered.matrix[i,j] <- 0
    }
  }
} 


# filter abundances avg_length
for (i in  1:nrow(my_counts.filtered.matrix)){
  for (j in 1:ncol(my_counts.filtered.matrix)){
    if( my_avg_length.matrix[i,j] < my_avg_length_min ){
      my_counts.filtered.matrix[i,j] <- 0
    } 
  }
} 


# filter abundances avg_pid
for (i in 1:nrow(my_counts.filtered.matrix)){
  for (j in 1:ncol(my_counts.filtered.matrix)){
    if( my_avg_pid.matrix[i,j] < my_avg_pid_min ){
      my_counts.filtered.matrix[i,j] <- 0
    } 
  }
} 


# sort the filtered data by row (not necessary, but I usually like to
my_counts.filtered.matrix <- my_counts.filtered.matrix[ order(rownames(my_counts.filtered.matrix)), ]
# sort the unfiltered data the same way for export below
my_counts.matrix  <- my_counts.matrix[ order(rownames(my_counts.matrix )), ]



# If you want to export any of the values (say as tab delimited text for excel etc, this is an easy way to do it
# load this function
export_data <- function(data_object, file_name){
    write.table(data_object, file=file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
  }
# use it like this
export_data(data_object=my_counts.matrix, file_name="unfiltered_counts.txt")
export_data(data_object=my_counts.filtered.matrix, file_name="filtered_counts.txt")






### END
### END
### END
##############################################################
##############################################################
##############################################################
##############################################################
### JUST NOTES FOR MYSELF FROM HERE ON, PLEASE IGNORE




#####
######################################################################
### Sub to remove singletons
######################################################################
rem_singletons <- function (x, lim.entry, lim.row) {
  x <- as.matrix (x)
  x [is.na (x)] <- 0
  x [x < lim.entry] <- 0 # less than limit changed to 0
  #x [ apply(x, MARGIN = 1, sum) >= lim.row, ] # THIS DOES NOT WORK - KEEPS ORIGINAL MATRIX
  x <- x [ apply(x, MARGIN = 1, sum) > lim.row, ] # row sum greater than limit is retained
  retained_rownames <- rownames(x)
  return list(x=x, retained_rownames=retained_rownames)  
}
######################################################################

######################################################################
### Sub to remove rows from other objects that were removed by remove.singletons
######################################################################
reconcile_rows <- function (x, retained_rownames) {
  x <- x[ c(retained_rownames), ]
  x  
}
######################################################################



# remove empty rows
# load this function
rem_empty_rows <- function (x, lim.row) {
  x <- as.matrix (x)
  x [is.na (x)] <- 0
  x <- x [ apply(x, MARGIN = 1, sum) > lim.row, ] # row sum greater than limit is retained
  retained_rownames <- rownames(x)
  output_list <- list("x"=x, "retained_rownames"=retained_rownames)
  return(output_list)  
}
# use the function
my_counts.filtered.EmptyRowsRemoved.object <- rem_empty_rows(x=my_counts.filtered.matrix, lim.row=0)
# see how many rows were lost
nrow(my_counts.matrix) - nrow(my_counts.filtered.EmptyRowsRemoved.object$x)
# export filtered data, with empty rows removed as simple matrix
my_counts.filtered.EmptyRowsRemoved.matrix <- my_counts.filtered.EmptyRowsRemoved.object$x
# export names of the retained rows into a character vector
retained_rownames <- my_counts.filtered.EmptyRowsRemoved.object$retained_rownames

# remove the corresponding rows from the avg_evalue, avg_lenght, and avg_pid matrices
# load this function
reconcile_rows <- function (x, retained_rownames) {
  x <- x[ c(retained_rownames), ]
  x  
}
# use the function
my_avg_evalues.filtered.EmptyRowsRemoved.matrix <- reconcile_rows(my_avg_evalues.matrix, retained_rownames)
my_avg_length.filtered.EmptyRowsRemoved.matrix <-  reconcile_rows(my_avg_length.matrix, retained_rownames)
my_avg_pid.matrix.filtered.EmptyRowsRemoved.matrix <- reconcile_rows(my_avg_pid.matrix, retained_rownames)


# Make sure that all of the matrices are sorted in the same way
ordered_rownames <- retained_rownames[ order(retained_rownames) ]
my_counts.filtered.EmptyRowsRemoved.matrix <- my_counts.filtered.EmptyRowsRemoved.matrix[ ordered_rownames, ]
my_avg_evalues.filtered.EmptyRowsRemoved.matrix <- my_avg_evalues.filtered.EmptyRowsRemoved.matrix[ ordered_rownames, ]
my_avg_length.filtered.EmptyRowsRemoved.matrix <- my_avg_length.filtered.EmptyRowsRemoved.matrix[ ordered_rownames, ]
my_avg_pid.matrix.filtered.EmptyRowsRemoved.matrix <- my_avg_pid.matrix.filtered.EmptyRowsRemoved.matrix[ ordered_rownames, ]





# remove rows
# g[!rownames(g) %in% remove, ]
# test3 <- test2[!rownames(test2) %in% "one", ]

# select rows
# test3 <- test2[ c("one","three"), ]




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


