metadata_2_groups <- function(metadata_table="HMP_WGS.meta_data.tab_delim.txt", metadata_column=8, output_file="default", debug=TRUE){

  # Delete output file if it already exists
  if ( file.exists(output_file)==TRUE ){
    print(paste("\n\nOUTPUT FILE: ", output_file,"\nalready exsists, and will now be deleted.\n\n"))
      unlink(output_file)
  }

  # Import the metadata table
  metadata_matrix <<- as.matrix(
                               read.table(
                                          file=metadata_table,row.names=1,header=TRUE,sep="\t",
                                          colClasses = "character", check.names=FALSE,
                                          comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                          )
                               )
  # sort (rowiese) by id (not necessary)
  metadata_matrix <- metadata_matrix[order(rownames(metadata_matrix)),]

  # create default names for the outputs  
  my_col_name <- gsub( "\\s", "_", colnames(metadata_matrix)[metadata_column] ) # replace white space with "_"

  if ( identical(output_file, "default") ){
    output_file <- paste(metadata_table, ".",my_col_name, ".groups.txt", sep="", collapse="")
  }
  
  # determine number of levels = number unique entries for the selected column
  column_factors <<- as.factor(metadata_matrix[,metadata_column])
  column_levels <<- levels(as.factor(metadata_matrix[,metadata_column]))
  num_levels <<- length(column_levels)

  # produce an AMETHST/matR formatted group file for the selected column
  file.create(output_file)
  for (i in 1:num_levels){

    if(debug==TRUE){print(paste("i:", i))}

    group_names_list <- rownames( metadata_matrix[ metadata_matrix[,metadata_column]==column_levels[i], ] )
    
    if(debug==TRUE){print(paste("group_names_list:", group_names_list))}
    
    group_line <- paste(group_names_list ,sep="", collapse=",")

    if(debug==TRUE){print(paste("group_line:", group_line))}
    
    write(group_line, file=output_file, append=TRUE)
  }

}

# group_names <- metadata_matrix[ metadata_matrix[,8]=="human-gut", ] # this works - creates row culled matrix

# mydata[mydata$A_Pval<0.05 & mydata$B_Pval<0.05 & mydata$C_Pval<0.05,]
# gsub("\\s","", " xx yy 11\n22\t 33 ")
# if (file.exists(file or dir))
# unlink
# exists(object)
