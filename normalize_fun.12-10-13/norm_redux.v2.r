MGRAST_preprocessing <<- function(
                                  file_in,     # name of the input file (tab delimited text with the raw counts)
                                  file_out = "preprocessed_data",    # name of the output data file (tab delimited text of preprocessed data)
                                  remove_sg                   =TRUE, # boolean to remove singleton counts
                                  sg.lim.entry = 1, # limit for individual values to be removed
                                  sg.lim.row = 1,
                                  log_transform = TRUE,
                                  norm_method = c("standard", "quantile"),
                                  scale_0_to_1 = TRUE
                                  )

  {

  
# Sub to remove singletons
    remove.singletons <- function (x, lim.entry = sg_threshold, lim.row = sg_threshold, ...) {
      x <- as.matrix (x)
      x [is.na (x)] <- 0
      x [x <= lim.entry] <- 0
      x [apply (x, MARGIN = 1, sum) >= lim.row, ]
    }




    remove.singletons <- function (x, lim.entry = 0, lim.row = 1, ...) {
      x <- as.matrix (x)
      x [is.na (x)] <- 0
      x [x <= lim.entry] <- 0
      x [apply (x, MARGIN = 1, sum) >= lim.row, ]
    }

    
  
# functiona that performs normalization (log transformation, standardization, scaling fro m 0 to 1)
    normalize <- function (x, method = c("standard"), ...) {
      method <- match.arg(method)

      # convert data to matrix
      x <- as.matrix(x)

      # convert "na's" to 0
      x[is.na(x)] <- 0

      # log transform (base two of x+1)
      x <- log2(x + 1)

      # Standardize
      mu <- matrix(apply(x, 2, mean), nr = nrow(x), nc = ncol(x), byrow = TRUE)
      sigm <- apply(x, 2, sd)
      sigm <- matrix(ifelse(sigm == 0, 1, sigm), nr = nrow(x), nc = ncol(x), byrow = TRUE)
      x <- (x - mu)/sigm

      # scale from 0 to one
      shift <- min(x, na.rm = TRUE)
      scale <- max(x, na.rm = TRUE) - shift
      if (scale != 0) x <- (x - shift)/scale
      x
    }
    
    
    
###### MAIN
### Input the data
    input_data = data.matrix(read.table(file_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote=""))
    
### remove singletons
    if(remove_sg==TRUE){
      input_data <- remove.singletons(x=input_data)
    }
    
### Norm, standardize, and scale the data
    input_data <- normalize(x=input_data)
    
###### write the log transformed and centered data to a file
    write.table(input_data, file=file_out, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE)
    
  }
