MGRAST_preprocessing <<- function(
                                  data_in,     # name of the input file (tab delimited text with the raw counts) or R matrix
                                  data_type             ="file",  # c(file, r_matrix)
                                  output_object         ="default", # output R object (matrix)
                                  output_file           ="default", # output flat file                       
                                  removeSg              = TRUE, # boolean to remove singleton counts
                                  removeSg_valueMin     = 2, # lowest retained value (lower converted to 0)
                                  removeSg_rowMin       = 4, # lowest retained row sum (lower, row is removed)
                                  log_transform         = FALSE,
                                  norm_method           = "DESeq", #c("standardize", "quantile", "DESeq", none),
                                  DESeq_metadata_in     = NULL, # only used if method is other than "blind"
                                  DESeq_metadata_column = NULL, # only used if method is other than "blind"
                                  DESeq_metadata_type   = "file",           # c( "file", "r_matrix" )
                                  DESeq_method          = "blind",  # c( "pooled", "pooled-CR", "per-condition", "blind" ) # blind, treat everything as one group
                                  DESeq_sharingMode     = "maximum",  # c( "maximum", "fit-only", "gene-est-only" ) # maximum is the most conservative choice
                                  DESeq_fitType         = "local",          # c( "parametric", "local" )
                                  scale_0_to_1          = FALSE,
                                  produce_boxplots      = FALSE,
                                  boxplot_height_in     = "default", # 11,
                                  boxplot_width_in      = "default", #"8.5,
                                  boxplot_res_dpi       = 300,
                                  create_log            = TRUE,
                                  debug                 = FALSE                                  
                                  )

  {

        
    # check for necessary packages, install if they are not there
    #require(matR) || install.packages("matR", repo="http://mcs.anl.gov/~braithwaite/R", type="source")
    #chooseCRANmirror()
    setRepositories(ind=1:2)
    require(preprocessCore) || install.packages("preprocessCore")
    #source("http://bioconductor.org/biocLite.R")
    require(DESeq) || biocLite("DESeq")
    # (DESeq): www.ncbi.nlm.nih.gov/pubmed/20979621
    
    #library(preprocessCore)
    #library(DESeq)
    ###### MAIN


    
    # get the name of the data object if an object is used -- use the filename if input is filename string
    if ( identical( data_type, "file") ){
      input_name <- data_in
    }else if( identical( data_type, "r_matrix") ){
      input_name <- deparse(substitute(data_in))
    }else{
      stop( paste( data_type, " is not a valid option for data_type", sep="", collapse=""))
    }


    
    
    #if ( identical( method, "DESeq" ) ){

   
    

    # Generate names for the output file and object
    if ( identical( output_object, "default") ){
      output_object <- paste( input_name, ".", norm_method, ".PREPROCESSED" , sep="", collapse="")
    }
    if ( identical( output_file, "default") ){
      output_file <- paste( input_name, ".", norm_method, ".PREPROCESSED.txt" , sep="", collapse="")
    }


    
    # Input the data
    if ( identical( data_type, "file") ){
      input_data <- data.matrix(read.table(data_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote=""))
    }else if( identical( data_type, "r_matrix") ){
      input_data <- data.matrix(data_in)
    }else{
      stop( paste( data_type, " is not a valid option for data_type", sep="", collapse=""))
    }


    
    # sort the data (COLUMNWISE) by id
    input_data <- input_data[,order(colnames(input_data))]
    
    # make a copy of the input data that is not processed
    input_data.og <- input_data
 
    # non optional, convert "na's" to 0
    input_data[is.na(input_data)] <- 0


    
    # remove singletons
    if(removeSg==TRUE){
      input_data <- remove.singletons(x=input_data, lim.entry=removeSg_valueMin, lim.row=removeSg_rowMin, debug=debug)
    }


    
    # log transform log(x+1)2
    if ( log_transform==TRUE ){
      input_data <- log_data(input_data)
    }


    regression_message <- "DESeq regression:      NA"
    # Normalize -- stadardize or quantile norm (depends on user selection)
    switch(
           norm_method,
           standardize={
             input_data <- standardize_data(input_data)
           },
           quantile={
             input_data <- quantile_norm_data(input_data)
           },
           DESeq={
             regression_filename = paste(  input_name, ".DESeq_regression.png", sep="", collapse="" )
             regression_message <- paste("DESeq regression:      ", regression_filename, sep="", collapse="" )
             input_data <- DESeq_norm_data(input_data, regression_filename,
                                           DESeq_metadata_in, DESeq_metadata_column, DESeq_metadata_type,
                                           DESeq_method, DESeq_sharingMode, DESeq_fitType, debug)
             
           },
           none={
             input_data <- input_data
           },
           {
             stop( paste( norm_method, " is not a valid option for method", sep="", collapse=""))
           }
           )
    
    # scale normalized data [max..min] to [0..1] over the entire dataset 
    if ( scale_0_to_1==TRUE ){
      input_data <- scale_data(input_data)
    }
    
    # create object, with specified name, that contains the preprocessed data
    do.call("<<-",list(output_object, input_data))
 
    # write flat file, with specified name, that contains the preprocessed data
    write.table(input_data, file=output_file, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")


    
    # produce boxplots
    boxplot_message <- "output boxplot:        NA"
    if ( produce_boxplots==TRUE ) {
      boxplots_file <- paste(input_name, ".boxplots.png", "\n", sep="", collapse="")
      
      if( identical(boxplot_height_in, "default") ){ boxplot_height_in <- 11 }
      if( identical(boxplot_width_in, "default") ){ boxplot_width_in <- round(ncol(input_data)/14) }

      png(
          filename = boxplots_file,
          height = boxplot_height_in,
          width = boxplot_width_in,
          res = boxplot_res_dpi,
          units = 'in'
          )
      plot.new()
      split.screen(c(2,1))
      screen(1)
      graphics::boxplot(input_data.og, main=(paste(input_name," RAW", sep="", collapse="")), las=2, cex.axis=0.5)
      screen(2)
      graphics::boxplot(input_data, main=(paste(input_name," PREPROCESSED (", norm_method, " norm)", sep="", collapse="")),las=2, cex.axis=0.5)
      dev.off()
      boxplot_message <- paste("output boxplot:       ", boxplots_file, "\n", sep="", collapse="")
    }


    # message to send to the user after completion, given names for object and flat file outputs
    #writeLines( paste("Data have been preprocessed. Proprocessed, see ", log_file, " for details", sep="", collapse=""))

    
    if ( create_log==TRUE ){
      # name log file
      log_file <- paste( output_file, ".log", sep="", collapse="")
      # write log
      writeLines(
                 paste(
                       "##############################################################\n",
                       "###################### INPUT PARAMETERS ######################\n",
                       "data_in:               ", data_in, "\n",
                       "data_type:             ", data_type, "\n",
                       "output_object:         ", output_object, "\n",
                       "output_file:           ", output_file, "\n",
                       "removeSg:              ", as.character(removeSg),
                       "removeSg_valueMin:     ", removeSg_valueMin, "\n",
                       "removeSg_rowMin:       ", removeSg_rowMin, "\n",
                       "log_transform          ", as.character(log_transform), "\n",
                       "norm_method:           ", norm_method, "\n",
                       "DESeq_metadata_in:     ", as.character(DESeq_metadata_in), "\n",
                       "DESeq_metadata_column: ", DESeq_metadata_column, "\n",
                       "DESeq_metadata_type:   ", DESeq_metadata_type, "\n",
                       "DESeq_method:          ", DESeq_method, "\n",
                       "DESeq_sharingMode:     ", DESeq_sharingMode, "\n",
                       "DESeq_fitType:         ", DESeq_fitType, "\n",
                       "scale_0_to_1:          ", as.character(scale_0_to_1), "\n",
                       "produce_boxplots:      ", as.character(produce_boxplots), "\n",
                       "boxplot_height_in:     ", boxplot_height_in, "\n",
                       "boxplot_width_in:      ", boxplot_width_in, "\n",
                       "debug as.character:    ", as.character(debug), "\n",
                       "####################### OUTPUT SUMMARY #######################\n",
                       "output object:         ", output_object, "\n",
                       "otuput file:           ", output_file, "\n",
                       boxplot_message, "\n",
                       regression_message, "\n",
                       "##############################################################",
                       sep="", collapse=""
                       ),
                 con=log_file
                 )
    }


    
  }




### Subs

# Sub to load the metadata (for DESeq)

import_metadata_from_file <- function(file){

  metadata_matrix <- as.matrix(
                               read.table(
                                          file=file,row.names=1,header=TRUE,sep="\t",
                                          colClasses = "character", check.names=FALSE,
                                          comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                          )
                               )
  # return imported matrix
  metadata_matrix
}



# Sub to remove singletons
remove.singletons <- function (x, lim.entry, lim.row, debug) {
  x <- as.matrix (x)
  x [is.na (x)] <- 0
  x [x < lim.entry] <- 0 # less than limit changed to 0
  #x [ apply(x, MARGIN = 1, sum) >= lim.row, ] # THIS DOES NOT WORK - KEEPS ORIGINAL MATRIX
  x <- x [ apply(x, MARGIN = 1, sum) >= lim.row, ] # row sum equal to or greater than limit is retained
  if (debug==TRUE){write.table(x, file="sg_removed.txt", sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")}
  x  
}

# theMatrixWithoutRow5 = theMatrix[-5,]
# t1 <- t1[-(4:6),-(7:9)]
# mm2 <- mm[mm[,1]!=2,] # delete row if first column is 2
# data[rowSums(is.na(data)) != ncol(data),] # remove rows with any NAs

# Sub to log transform (base two of x+1)
log_data <- function(x){
  x <- log2(x + 1)
  x
}

# sub to perform quantile normalization
quantile_norm_data <- function (x, ...){
  data_names <- dimnames(x)
  x <- normalize.quantiles(x)
  dimnames(x) <- data_names
  x
}

# sub to perform standardization
standardize_data <- function (x, ...){
  mu <- matrix(apply(x, 2, mean), nr = nrow(x), nc = ncol(x), byrow = TRUE)
  sigm <- apply(x, 2, sd)
  sigm <- matrix(ifelse(sigm == 0, 1, sigm), nr = nrow(x), nc = ncol(x), byrow = TRUE)
  x <- (x - mu)/sigm
  x
}

# sub to perform DESeq normalization
DESeq_norm_data <- function (x, regression_filename,
                             DESeq_metadata_in, DESeq_metadata_column, DESeq_metadata_type,
                             DESeq_method, DESeq_sharingMode, DESeq_fitType, debug, ...){
  # much of the code in this function is adapted/borrowed from two sources
  # Orignal DESeq publication www.ncbi.nlm.nih.gov/pubmed/20979621
  #     also see vignette("DESeq")
  # and Paul J. McMurdie's example analysis in a later paper http://www.ncbi.nlm.nih.gov/pubmed/24699258
  #     with supporing material # http://joey711.github.io/waste-not-supplemental/simulation-cluster-accuracy/simulation-cluster-accuracy-server.html

  # die if apprpropriate metadata selections are not made for DESeq selections
  if( identical(DESeq_method, "blind")==FALSE && ( is.null(DESeq_metadata_in) || is.null(DESeq_metadata_column) ) ){
    stop("You must supply metadata (DESeq_metadata_in) and selected a metadata column (DESeq_metadata_column) for any DESeq method other than blind")
  }
  
  # import metadata matrix (from object or file)
 
  
  #metadata_matrix <- metadata_matrix[order(rownames(metadata_matrix)),]
  

  # create or import metadata
  if( identical(DESeq_method,"blind") ){
    my_conditions <- rep(1,ncol(x))
    if(debug==TRUE){print("METHOD IS BLIND")}
  }else{
    if(debug==TRUE){print("METHOD IS NOT BLIND")}
    if ( identical(DESeq_metadata_type, "r_matrix") ){
      DESeq_metadata_in <- DESeq_metadata_in
    } else if ( identical(DESeq_metadata_type, "file") ) {
      DESeq_metadata_in <- import_metadata_from_file(DESeq_metadata_in)
    }
    # make sure that the color matrix is sorted (ROWWISE) by id
    DESeq_metadata_in <- DESeq_metadata_in[order(rownames(DESeq_metadata_in)),]
    # factor conditions
    my_conditions <- as.factor( DESeq_metadata_in[,DESeq_metadata_column] )
    if(debug==TRUE){ my.conditions <<- my_conditions; my.data <<- x }
  }

  # add pseudocounts to prevent workflow from crashing on NaNs
  x = x + 1 
 
  # create dataset object
  my_dataset <- newCountDataSet( x, my_conditions )
  
  # estimate the size factors
  my_dataset <- estimateSizeFactors(my_dataset)
 
  # estimate dispersions
  # reproduce this: deseq_varstab(physeq, method = "blind", sharingMode = "maximum", fitType = "local")
  #      see https://stat.ethz.ch/pipermail/bioconductor/2012-April/044901.html
  # with DESeq code directly
  # my_dataset <- estimateDispersions(my_dataset, method = "blind", sharingMode = "maximum", fitType="local")
  # but this is what they did in the supplemental material for the DESeq paper (I think) -- and in figure 1 of McMurdie et al.
  #my_dataset <- estimateDispersions(my_dataset, method = "pooled", sharingMode = "fit-only", fitType="local") ### THIS WORKS
  # This is what they suggest in the DESeq vignette for multiple replicats
  my_dataset <- estimateDispersions(my_dataset, method = DESeq_method, sharingMode = DESeq_sharingMode, fitType = DESeq_fitType)
  
  # Determine which column(s) have the dispersion estimates
  dispcol = grep("disp\\_", colnames(fData(my_dataset)))

  # Enforce that there are no infinite values in the dispersion estimates
  if (any(!is.finite(fData(my_dataset)[, dispcol]))) {
    fData(cds)[which(!is.finite(fData(my_dataset)[, dispcol])), dispcol] <- 0
  }

  # apply variance stabilization normalization
  my_dataset.normed <- varianceStabilizingTransformation(my_dataset)

  # produce a plot of the regression
  png(
      filename = regression_filename,
      height = 8.5,
      width = 8.5,
      res = 300,
      units = 'in'
      )
  #plot.new()    
  plotDispEsts( my_dataset )
  dev.off()
  
  # return matrix of normed values
  x <- exprs(my_dataset.normed)
  x

}

# sub to scale dataset values from [min..max] to [0..1]
scale_data <- function(x){
  shift <- min(x, na.rm = TRUE)
  scale <- max(x, na.rm = TRUE) - shift
  if (scale != 0) x <- (x - shift)/scale
  x
}



### Old version - steps not split into separate functions
## # functiona that performs normalization (log transformation, standardization, scaling fro m 0 to 1)
## normalize_data <- function (x, method = norm_method, ...) {
  
##   switch(
##          method,
##          standard={
##            mu <- matrix(apply(x, 2, mean), nr = nrow(x), nc = ncol(x), byrow = TRUE)
##            sigm <- apply(x, 2, sd)
##            sigm <- matrix(ifelse(sigm == 0, 1, sigm), nr = nrow(x), nc = ncol(x), byrow = TRUE)
##            x <- (x - mu)/sigm
##          },
##          quantile={
##            data_names <- dimnames(x)
##            x <- normalize.quantiles(x)
##            dimnames(x) <- data_names
##          },
##          {
##            stop( paste( method, " is not a valid option for method", sep="", collapse=""))
##          }
##          )
##   x
  
## }
