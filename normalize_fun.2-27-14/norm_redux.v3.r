MGRAST_preprocessing <<- function(
                                  data_in,     # name of the input file (tab delimited text with the raw counts) or R matrix
                                  data_type        ="file",  # c(file, r_matrix)
                                  output_object    ="default", # output R object (matrix)
                                  output_file      ="default", # output flat file                       
                                  remove_sg        = TRUE, # boolean to remove singleton counts
                                  value.min        = 2, # lowest retained value (lower converted to 0)
                                  row.min          = 4, # lowest retained row sum (lower, row is removed)
                                  log_transform    = FALSE,
                                  norm_method      = "DESeq", #c("standardize", "quantile", "DESeq", none),
                                  scale_0_to_1     = FALSE,
                                  produce_boxplots = FALSE,
                                  boxplot_height_in = 11,
                                  boxplot_width_in = 8.5,
                                  boxplot_res_dpi = 300,
                                  debug=FALSE                                  
                                  )

  {

        
    # check for necessary packages, install if they are not there
    require(matR) || install.packages("matR", repo="http://mcs.anl.gov/~braithwaite/R", type="source")
    require(preprocessCore) || install.packages("preprocessCore")
    source("http://bioconductor.org/biocLite.R")
    require(DESeq) || biocLite("DESeq")
    # (DESeq): www.ncbi.nlm.nih.gov/pubmed/20979621
    
    #library(preprocessCore)
    #library(DESeq)
    ###### MAIN

    # get the name of the object if an object is used -- use the filename if input is filename string
    if ( identical( data_type, "file") ){
      input_name <- data_in
    }else if( identical( data_type, "r_matrix") ){
      input_name <- deparse(substitute(data_in))
    }else{
      stop( paste( data_type, " is not a valid option for data_type", sep="", collapse=""))
    }

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
    # make a copy of the input data that is not processed
    input_data.og <- input_data
 
    # non optional, convert "na's" to 0
    input_data[is.na(input_data)] <- 0
    
    # remove singletons
    if(remove_sg==TRUE){
      input_data <- remove.singletons(x=input_data, lim.entry=value.min, lim.row=row.min, debug=debug)
    }
    
    # log transform log(x+1)2
    if ( log_transform==TRUE ){
      input_data <- log_data(input_data)
    }
    
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
             input_data <- DESeq_norm_data(input_data, input_name, debug)
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
    write.table(input_data, file=output_file, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE)
    
    # produce boxplots
    boxplot_message <- "     boxplot  : NA"
    if ( produce_boxplots==TRUE ) {
      boxplots_file <- paste(input_name, ".boxplots.png", sep="", collapse="")
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
      boxplot(input_data.og, main=(paste(input_name," RAW", sep="", collapse="")), las=2)
      screen(2)
      boxplot(input_data, main=(paste(input_name," PREPROCESSED (", norm_method, " norm)", sep="", collapse="")),las=2)
      dev.off()
      boxplot_message <- paste("     boxplot  : ", boxplots_file, sep="", collapse="")
    }

    # message to send to the user after completion, given names for object and flat file outputs
    writeLines("Data have been preprocessed. Proprocessed data are in")
    writeLines(paste("     object   : ", output_object, sep="", collapse=""))
    writeLines(paste("     and file : ", output_file, sep="", collapse=""))
    writeLines(boxplot_message)
              
  }




### Subs
      
# Sub to remove singletons
remove.singletons <- function (x, lim.entry, lim.row, debug) {
  x <- as.matrix (x)
  x [is.na (x)] <- 0
  x [x < lim.entry] <- 0 # less than limit changed to 0
  #x [ apply(x, MARGIN = 1, sum) >= lim.row, ] # THIS DOES NOT WORK - KEEPS ORIGINAL MATRIX
  x <- x [ apply(x, MARGIN = 1, sum) >= lim.row, ] # row sum equal to or greater than limit is retained
  if (debug==TRUE){write.table(x, file="sg_removed.txt", sep="\t", col.names = NA, row.names = TRUE, quote = FALSE)}
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
DESeq_norm_data <- function (x, input_name, debug, ...){
  # code in this function is borrowed from two sources
  # Orignal DESeq publication www.ncbi.nlm.nih.gov/pubmed/20979621
  #     also see vignette("DESeq")
  # and Paul J. McMurdie's example analysis in a later paper http://www.ncbi.nlm.nih.gov/pubmed/24699258
  #     with supporing material # http://joey711.github.io/waste-not-supplemental/simulation-cluster-accuracy/simulation-cluster-accuracy-server.html

  # add pseudocounts to prevent workflow from crashing on NaNs
  x = x + 1 
  
  # create metadata - simple case - treats all data as single group
  my_conditions <- as.factor(rep(1,ncol(x))) 
  my_dataset <- newCountDataSet( x, my_conditions )

  # estimate the size factors
  my_dataset <- estimateSizeFactors(my_dataset)
 
  # estimate dispersions
  # reproduce this: deseq_varstab(physeq, method = "blind", sharingMode = "maximum", fitType = "local")
  #      see https://stat.ethz.ch/pipermail/bioconductor/2012-April/044901.html
  # with DESeq code directly
  my_dataset <- estimateDispersions(my_dataset, method = "blind", sharingMode = "maximum", fitType="local")
  
  # Determine which column(s) have the dispersion estimates
  dispcol = grep("disp\\_", colnames(fData(my_dataset)))

  # Enforce that there are no infinite values in the dispersion estimates
  if (any(!is.finite(fData(my_dataset)[, dispcol]))) {
    fData(cds)[which(!is.finite(fData(my_dataset)[, dispcol])), dispcol] <- 0
  }

  # apply variance stabilization normalization
  my_dataset.normed <- varianceStabilizingTransformation(my_dataset)

  # produce a plot of the regression
  regression_filename = paste(  input_name, ".DESeq_regression.png", sep="", collapse="" )
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
