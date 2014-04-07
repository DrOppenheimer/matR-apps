 load_metadata <- function(metadata_table, metadata_column, color_list){
    if ( identical( is.na(metadata_table), FALSE ) ){
      # generate auto colors if the color matrix contains metadata and not colors
      color_matrix <<- as.matrix(
                                read.table(
                                           file=metadata_table,row.names=1,header=TRUE,sep="\t",colClasses = "character", check.names=FALSE,comment.char="",quote="",fill=TRUE,blank.lines.skip=FALSE
                                           )
                                )
      # make sure that the color matrix is sorted (ROWWISE) by id
      color_matrix <<-  color_matrix[order(rownames(color_matrix)),]
      ncol.color_matrix <<- ncol(color_matrix)
      # create the color matrix from the metadata
      pcoa_colors <<- create_colors(color_matrix, color_mode="auto")
      column_factors <<- as.factor(color_matrix[,metadata_column])
      column_levels <<- levels(as.factor(color_matrix[,metadata_column]))
      num_levels <<- length(column_levels)
      color_levels <<- col.wheel(num_levels)
      plot_colors <<- pcoa_colors[,metadata_column]
    }else if ( identical( is.na(color_list), FALSE ) ){
      # use list over table if it is supplied
      column_levels <<- levels(as.factor(as.matrix(color_list)))
      num_levels <<- length(column_levels)
      color_levels <<- col.wheel(num_levels)
      plot_colors <<- color_list
    }else{
      # use a default of black if no table or list is supplied
      column_levels <<- "data"
      num_levels <<- 1
      color_levels <<- 1
      plot_colors <<- "black"
    }
  }
