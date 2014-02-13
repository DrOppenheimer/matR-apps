merge_data <- functon(file1="", file2="", output=""){

  data1 = import_data(file1)

  data2 = import_data(file2)

  merged_data <- merge(data1, data2, by="row.names", all=TRUE)

  merged_data

}

#### SUBS
    import_data <- function(file_name)
{
 data.matrix(read.table(file_name, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
}




    
}
