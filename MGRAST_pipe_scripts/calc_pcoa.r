MGRAST_calc_pco <- function(
                            file_in,
                            file_out.dist = "my_dist",
                            file_out.pcoa_values = "my_pcoa.values",
                            file_out.pcoa_vectors = "my_pcoa.vectors",
                            dist_method = "euclidean",
                            input_dir = "./",
                            input_type = "file",
                            output_PCoA_dir = "./",
                            print_dist = 1,
                            output_DIST_dir = "./",
                            debug=FALSE
                            )

{
  # load packages
  suppressPackageStartupMessages(library(matlab))      
  suppressPackageStartupMessages(library(ecodist))
  #suppressPackageStartupMessages(library(Cairo))
  #suppressPackageStartupMessages(library(gplots))

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
                            file_in = no default arg                               # (string)  input data file
                            input_type = \"file\"                                   # (string) file or r_matrix
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
             
             #"bray-curtis" = distance(my_data, method = "bray-curtis"), # could not handle large data 1-12-12
             
             "bray-curtis" = bcdist(my_data), # 1-12-12
             #"bray-curtis" = vegdist(my_data, method="bray"), # 1-12-12
             #"bray-curtis" = designdist(my_data, method = "(A+B-2*J)/(A+B)") # 1-12-12
             
             "jaccard" = distance(my_data, method = "jaccard"),
             "mahalanobis" = distance(my_data, method = "mahalanobis"),
             "sorensen" = distance(my_data, method = "sorensen"),
             "difference" = distance(my_data, method = "difference")
             # unifrac
             # weighted_unifrac

             # distance methods with {stats}dist: dist(x, method = "euclidean", diag = FALSE, upper = FALSE, p = 2)
             #      euclidean maximum manhattan canberra binary minkowski

             # distance methods with {ecodist}distance: distance(x, method = "euclidean")
             #      euclidean bray-curtis manhattan mahalanobis jaccard "simple difference" sorensen

             )
    }


  # stop and give the usage if the proper number of arguments is not given
  if ( nargs() == 0 ){
    func_usage()
  }

  # input data as an appropriate R object
  if ( identical(input_type, "file") ){
    input_data_path = gsub(" ", "", paste(input_dir, file_in))
    my_data <- flipud(rot90(data.matrix(read.table(input_data_path, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))))
  } else if ( identical(input_type, "r_matrix") ) {
    my_data <- flipud(rot90(file_in))
  } else {
    stop("input_type value is not valid, must be file or r_matrix")
  }
  
  # substitute 0 for NA's if they exist in the data
  data_is_na <- ( is.na(my_data) )
  my_data[data_is_na==TRUE] <- 0
  
  # naming outputs
  if( identical(input_type, "r_matrix") ){
    file_in.name <- deparse(substitute(file_in))
  } else {
    file_in.name <- file_in
  }
   
  # calculate distance matrix and write the results to file
  dist_matrix <- find_dist(my_data, dist_method)
  if (print_dist > 0) { write.table(x=data.matrix(dist_matrix), file=file_out.dist, col.names=NA, row.names=TRUE, append = FALSE, sep="\t", quote = FALSE, eol="\n") }

  # perform the pco
  my_pco <- pco(dist_matrix)
  # scale eigen values from 0 to 1, and label them
  eigen_values <- my_pco$values
  scaled_eigen_values <- (eigen_values/sum(eigen_values))
  #for (i in (1:dim(as.matrix(scaled_eigen_values))[1])) {names(scaled_eigen_values)[i]<<-gsub(" ", "", paste("PCO", i))}
  scaled_eigen_values <- data.matrix(scaled_eigen_values)
  
  # labeling eigen values
  my_PC_names <- vector()
  #for (i in 1:length(scaled_eigen_values) ) { rownames(scaled_eigen_values)[i]<-gsub(" ", "", paste("PCO", i)) }
  for (i in 1:nrow(scaled_eigen_values) ) { my_PC_names <- c(my_PC_names, gsub(" ", "", paste("PCO", i)) ) }
  rownames(scaled_eigen_values) <- my_PC_names
  colnames(scaled_eigen_values) <- "var_per_coordinate"
  # write eigen values to file
  write.table(x=scaled_eigen_values, file=file_out.pcoa_values, col.names=NA, row.names=TRUE, append = FALSE, sep="\t", quote = FALSE, eol="\n")
  
  # label the eigen vectors
  eigen_vectors <- data.matrix(my_pco$vectors)
  colnames(eigen_vectors) <- my_PC_names
  rownames(eigen_vectors) <- rownames(my_data)
  # write eigen vectors to file
  write.table(eigen_vectors, file=file_out.pcoa_vectors, col.names=NA, row.names=TRUE, append = FALSE, sep="\t", eol="\n")
  
}

