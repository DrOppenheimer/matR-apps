MGRAST_preprocessing <<- function(
                                  file_in,     # name of the input file (tab delimited text with the raw counts)
                                  file_out         = "preprocessed_data",    # name of the output data file (tab delimited text of preprocessed data)
                                  remove_sg        = TRUE, # boolean to remove singleton counts
                                  sg.lim.entry     = 0, # limit for individual values to be removed
                                  sg.lim.row       = 1,
                                  log_transform    = TRUE,
                                  norm_method      = "quantile", #c("standard", "quantile"),
                                  scale_0_to_1     = TRUE,
                                  output_object    ="default",
                                  output_file      ="default",
                                  produce_boxplots = TRUE,
                                  boxplot_height_in = 11,
                                  boxplot_width_in = 8.5,
                                  boxplot_res_dpi = 300
                                  )

  {

    # check for necessary package, install if it isn't there
    require(preprocessCore) || install.packages("preprocessCore")            
    library(preprocessCore)
###### MAIN

    # Generate names for the output file and object
    if ( identical( output_object, "default") ){
      output_object <- paste( file_in, ".PREPROCESSED" , sep="", collapse="")
    }

    if ( identical( output_file, "default") ){
      output_file <- paste( file_in, ".PREPROCESSED.txt" , sep="", collapse="")
    }
    
    # Input the data
    input_data = data.matrix(read.table(file_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote=""))
    # make a copy of the input data that is not processed
    input_data.og <- input_data

    # convert data to matrix
    input_data <- as.matrix(input_data)

    # convert "na's" to 0
    input_data[is.na(input_data)] <- 0

    # remove singletons
    if(remove_sg==TRUE){
      input_data <- remove.singletons(x=input_data, lim.entry=sg.lim.entry, lim.row=sg.lim.row)
    }
    
    # log transform log(x+1)2
    if ( log_transform==TRUE ){
      input_data <- log_data(input_data)
    }
        
    # Norm, standardize, and scale the data within each column (sample)
    input_data <- normalize_data(x=input_data, method=norm_method)
    # test_data <<- input_data # data has lost labels 
    
    # scale data [max..min] to [0..1] over the entire dataset 
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
      boxplots_file <- paste(file_in, ".boxplots.png", sep="", collapse="")
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
      boxplot(input_data.og, main=(paste(file_in," RAW", sep="", collapse="")), las=2)
      screen(2)
      boxplot(input_data, main=(paste(file_in," PREPROCESSED (", norm_method, " norm)", sep="", collapse="")),las=2)
      dev.off()
      boxplot_message <- paste("     boxplot  : ", boxplots_file, sep="", collapse="")
    }

    # message to send to the user after completion, given names for object and flat file outputs
    writeLines("Data have been preprocessed. Proprocessed data are in")
    writeLines(paste("     object   : ",output_object, sep="", collapse=""))
    writeLines(paste("     and file : ", output_file, sep="", collapse=""))
    writeLines(boxplot_message)
              
  }




### Subs
      
# Sub to remove singletons
remove.singletons <- function (x, lim.entry=sg.lim.entry, lim.row=sg.lim.row , ...) {
  x <- as.matrix (x)
  x [is.na (x)] <- 0
  x [x <= lim.entry] <- 0
  x [apply (x, MARGIN = 1, sum) >= lim.row, ]
  x
}

# Sub to log transform (base two of x+1)
log_data <- function(x){
  log2(x + 1)
  x
}



# functiona that performs normalization (log transformation, standardization, scaling fro m 0 to 1)
normalize_data <- function (x, method = norm_method, ...) {
  
  switch(
         method,
         standard={
           mu <- matrix(apply(x, 2, mean), nr = nrow(x), nc = ncol(x), byrow = TRUE)
           sigm <- apply(x, 2, sd)
           sigm <- matrix(ifelse(sigm == 0, 1, sigm), nr = nrow(x), nc = ncol(x), byrow = TRUE)
           x <- (x - mu)/sigm
         },
         quantile={
           data_names <- dimnames(x)
           x <- normalize.quantiles(x)
           dimnames(x) <- data_names
         },
         {
           stop( paste( method, " is not a valid option for method", sep="", collapse=""))
         }
         )
  x
  
}


      
# scale from 0 to one
scale_data <- function(x){
  shift <- min(x, na.rm = TRUE)
  scale <- max(x, na.rm = TRUE) - shift
  if (scale != 0) x <- (x - shift)/scale
  x
}
