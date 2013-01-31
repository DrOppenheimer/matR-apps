plot_pcoa.from_object <- function(
                     matrix,
                     file_in = "matrix_object",
                     my_width = 1000,
                     my_height = 1000,
                     samples = dimnames(matrix)[[2]],
                     input_dir = "./",
                     output_PCoA_dir = "./",
                     print_dist = 1,
                     output_DIST_dir = "./",
                     dist_method = "euclidean",
                     headers = 1,
                     colors = "blue",
                     PC1 = 1,
                     PC2 = 2
                     )
  
{
  # load packages
  suppressPackageStartupMessages(library(matlab))      
  suppressPackageStartupMessages(library(ecodist))

  # define sub functions
  func_usage <- function() {
    writeLines("
     You supplied no arguments

     DESCRIPTION: (MGRAST_plot_pco.r):
     This script will perform a PCoA analysis on the inputdata
     using the selected distance metric.  Output always produces a
     *.PCoA file that has the normalized eigenvalues (top n lines)
     and eigenvectors (bottom n x m matris, n lines) where n is the
     number of variables (e.g.subsystems), and m the number of
     samples. You can also choose to produce *.DIST files that contain
     the distance matrix used to generate the PCoA.

     USAGE: MGRAST_plot_pca(
                            input_matrix = no default arg                            # (string) if data is in matrix, name of matrix
                            file_in = \"my_file\"                                 # (string) if data is in file, name of file
                            input_dir = \"./\"                                       # (string)  directory(path) of input
                            output_PCoA_dir = \"./\"                                 # (string)  directory(path) for output PCoA file
                            print_dist = 0                                         # (boolean) print the DIST file (distance matrix)
                            output_DIST_dir = \"./\"                                 # (string)  directory(path) for output DIST file 
                            dist_method = \"bray-curtis\"                            # (string)  distance/dissimilarity metric,
                                          (choose from one of the following options)
                                          \"euclidean\" | \"maximum\"     | \"canberra\"    |
                                          \"binary\"    | \"minkowski\"   | \"bray-curtis\" |
                                          \"jacccard\"  | \"mahalanobis\" | \"sorensen\"    |
                                          \"difference\"| \"manhattan\"
                            colors = NULL,                                         # character vector of colors for the points
                            PC1 = \"PC1\",                                         # first component to plot
                            PC2 = \"PC2\"                                          # second component to plot
                            headers = 0                                            # (booealan) print headers in output PCoA file 
                            )\n"
               )
    stop("MGRAST_plot_pco stopped\n\n")
  }
  
  find_dist <- function(my_data, dist_method)
    {
      switch(dist_method,
             "euclidean" = dist(my_data, method = "euclidean"), 
             "maximum" = dist(my_data, method = "maximum"),
             "manhattan" = dist(my_data, method = "manhattan"),
             "canberra" = dist(my_data, method = "canberra"),
             "binary" = dist(my_data, method = "binary"),
             "minkowski" = dist(my_data, method = "minkowski"),
             "bray-curtis" = bcdist(my_data), # 1-12-12      
             "jaccard" = distance(my_data, method = "jaccard"),
             "mahalanobis" = distance(my_data, method = "mahalanobis"),
             "sorensen" = distance(my_data, method = "sorensen"),
             "difference" = distance(my_data, method = "difference")
             # unifrac
             # weighted_unifrac
             )
    }


  # stop and give the usage if the proper number of arguments is not given
  if ( nargs() == 0 ){
    func_usage()
  }

  # load data - using matrix or file name
  my_data <<- rot90(matrix)
  dimnames(my_data)[[1]] <<- samples
  
  num_data_rows = dim(my_data)[1] # substitute 0 for NA's if they exist in the data
  num_data_cols = dim(my_data)[2]
  for (row_num in (1:num_data_rows)){
    for (col_num in (1:num_data_cols)){
      #my_data[row_num, col_num] = as.integer(my_data[row_num, col_num]) # added 1-12-12 to fix "Error in vector("double", length) : vector size cannot be NA ...
      if (is.na(my_data[row_num, col_num])){
        my_data[row_num, col_num] <<- 0
      }
    }
  }

  # calculate distance matrix
  dist_matrix <<- find_dist(my_data, dist_method)
  DIST_file_out <- gsub(" ", "", paste(output_DIST_dir, file_in, ".", dist_method, ".DIST"))
  # if (print_dist > 0) { write_file(file_name = DIST_file_out, data = data.matrix(dist_matrix)) }
  if (print_dist > 0) { write.table(data.matrix(dist_matrix), file=DIST_file_out, col.names=NA, row.names=TRUE, append = FALSE, sep="\t", quote = FALSE) }
  
  # perform the pco
  my_pco <<- ecodist::pco(dist_matrix)

  # scale eigen values from 0 to 1, and label them
  eigen_values <<- my_pco$values
  scaled_eigen_values <<- (eigen_values/sum(eigen_values))
  for (i in (1:dim(as.matrix(scaled_eigen_values))[1])) {names(scaled_eigen_values)[i]<<-gsub(" ", "", paste("PCO", i))}
  scaled_eigen_values <<- data.matrix(scaled_eigen_values)
  
  # label the eigen vectors
  eigen_vectors <<- data.matrix(my_pco$vectors) 
  dimnames(eigen_vectors)[[1]] <<- dimnames(my_data)[[1]]

  # write eigen values and then eigen vectors to file_out
  PCoA_file_out = gsub(" ", "", paste(output_PCoA_dir, file_in, ".", dist_method, ".PCoA"))

  if ( headers == 1 ){
    write(file = PCoA_file_out, paste("# file_in    :", file_in,
            "\n# dist_method:", dist_method,
            "\n#________________________________",
            "\n# EIGEN VALUES (scaled 0 to 1) >",
            "\n#________________________________"),
          append=FALSE)
    write.table(scaled_eigen_values, file=PCoA_file_out, col.names=FALSE, row.names=TRUE, append = TRUE, sep="\t")
  }else{
    write.table(scaled_eigen_values, file=PCoA_file_out, col.names=FALSE, row.names=TRUE, append = FALSE, sep="\t")
  }
  
  if ( headers == 1 ){
    write(file = PCoA_file_out, paste("#________________________________",
            "\n# EIGEN VECTORS >",
            "\n#________________________________"),
          append=TRUE)
  }

  write.table(eigen_vectors, file=PCoA_file_out, col.names=FALSE, row.names=TRUE, append = TRUE, sep="\t")

  png(file = gsub(" ", "", paste(file_in, ".", dist_method,".PCoA.png")), width = my_width, height = my_height)
  plot(
       x<-eigen_vectors[,PC1],
       y<-eigen_vectors[,PC2],     
       type="n",             
       #xlab = scaled_eigen_values[PC1],          
       #ylab = scaled_eigen_values[PC2],
       xlab = paste(round(scaled_eigen_values[PC1]*100, digits = 2), "% of variation"),
       ylab = paste(round(scaled_eigen_values[PC2]*100, digits = 2), "% of variation"),
       cex = 0.8
       )
  my_cex <- 1
                                        #points(x=(my_data[,PC1]), y=(my_data[,PC2]), pch=23, col = colors, bg = colors, cex=my_cex) #C
  points(x=(eigen_vectors[,PC1]), y=(eigen_vectors[,PC2]), pch=23, col = colors, bg = colors, cex=my_cex) #C

  title( (paste(file_in,"\n", "PC", PC1, "vs PC", PC2 )), cex.main = 1)
  dev.off()
  
}
