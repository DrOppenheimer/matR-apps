# Make sure that matR is loaded
require(matR)
require(matlab)
# require(ggplot2)


############################################################################
# Color methods https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
############################################################################
# The inverse function to col2rgb()
col.wheel <- function(num_col, my_cex=0.75) {
  cols <- rainbow(num_col)
  col_names <- vector(mode="list", length=num_col) 
  for (i in 1:num_col){
    col_names[i] <- getColorTable(cols[i])
  }
  # pie(rep(1, length(cols)), labels=col_names, col=cols, cex=my_cex) }
  cols
}

# The inverse function to col2rgb()
rgb2col <- function(rgb) {
  rgb <- as.integer(rgb)
  class(rgb) <- "hexmode"
  rgb <- as.character(rgb)
  rgb <- matrix(rgb, nrow=3)
  paste("#", apply(rgb, MARGIN=2, FUN=paste, collapse=""), sep="")
}

# Convert all colors into format "#rrggbb"
getColorTable <- function(col) {
  rgb <- col2rgb(col);
  col <- rgb2col(rgb);
  sort(unique(col))
}
############################################################################
############################################################################

# stat tests from matR::sigtest, for pair then 3 or more
my_stats = "Kruskal-Wallis" # non normal data  
# my_stats = "ANOVA-one-way" # paramtric   # normal data

# import data
file_name = "sample_data.1_2_are_group.txt"
my_data <- read.table(file_name, header=TRUE, stringsAsFactors=FALSE, sep="\t", comment.char="", quote="", check.names=FALSE, row.names=1 )

# get dimensions of the data
my_data.n_rows <- nrow(my_data)
my_data.n_cols <- ncol(my_data)

# get the sums and averages for all columns in the data
my_data.sum <- as.matrix(rowSums(my_data))
colnames(my_data.sum) <- "sum_all_samples"
my_data.mean <- as.matrix(rowMeans(my_data))
colnames(my_data.mean) <- "mean_all_samples"

# create a groups vector for the data
#my_groups <- c(rep(1,"group"), rep(2,"group"), rep(3,"group3"))
my_groups <- c(rep("group1", 2), rep("group2", 3), rep("group3", 4))
# name the groups vector with sample ids from the imported data
names(my_groups) <- colnames(my_data)

# factor the groups
my_groups.factor <- factor(my_groups)

# get the levels of the factors (get the list of unique groups)
my_groups.levels <- levels(factor(my_groups))

# get the number of groups
num_groups <- nlevels(my_groups.factor)

# sigtest to perform stats
# place selected stat in variable for use below
my_stat = "Kruskal-Wallis"
# perform stat tests (uses matR)
my_stats <- sigtest(my_data, my_groups, my_stat)

# Create headers for the data columns
for (i in 1:dim(my_data)[2]){ colnames(my_data)[i] <- paste( colnames(my_data)[i], "::", (my_groups)[i], sep="" )  }
for (i in 1:dim(my_stats$mean)[2]){ colnames(my_stats$mean)[i] <- paste( colnames(my_stats$mean)[i], "::group_mean", sep="" )  }
for (i in 1:dim(my_stats$sd)[2]){ colnames(my_stats$sd)[i] <- paste( colnames(my_stats$sd)[i], "::group_sd", sep="" )  }
my_stats.statistic <- as.matrix(my_stats$statistic)
colnames(my_stats.statistic) <- paste(my_stat, "::stat", sep="")
my_stats.p <- as.matrix(my_stats$p.value)
colnames(my_stats.p) <- paste(my_stat, "::p", sep="")
my_stats.fdr <- as.matrix(p.adjust(my_stats$p.value))
colnames(my_stats.fdr) <- paste(my_stat, "::fdr", sep="")

# generate a summary object - used to generate the plots, and can be used to create a flat file output
my_stats.summary <- cbind(my_data, my_data.mean, my_stats$mean, my_stats$sd, my_stats.statistic, my_stats.p, my_stats.fdr)

# selection column to order the data by
order_by = "mean_all_samples" 
## or order by mean values in a single group
# order_by = paste("group1", "::group_mean", sep="")
## or order by FDR
# order_by = paste(my_stat, "::fdr", sep="")

# order the data by the selected column - placing ordered data in a new object
my_stats.summary.ordered <- my_stats.summary[ order(my_stats.summary[,order_by], decreasing=TRUE), ]

# flat file output of the summary file
write.table(my_stats.summary.ordered, file = "my_stats.summary.txt", col.names=NA, row.names = rownames(my_stats.summary), sep="\t", quote=FALSE)

# select number of categories (taxa or functions) to plot in the barplot
my_n = 5 

# create a subselection of the data above based on selected number of categories
my_stats.summary.ordered.subset <- as.matrix(my_stats.summary.ordered[1:my_n,])
profile_indices <- as.numeric(grep("group_mean", colnames(my_stats.summary.ordered.subset)))

# Rotate the subselected data so its suitable for the barplot function
my_stats.summary.ordered.subset.rot_90 <- rot90(  my_stats.summary.ordered.subset[,profile_indices]  )

# Genrate colors based on the number of groups
my_data.color <- col.wheel(num_groups)

# create the barplot
barplot( 
  my_stats.summary.ordered.subset.rot_90, 
  beside=TRUE, 
  col=my_data.color,  
  legend=rownames(my_stats.summary.ordered.subset.rot_90),
  args.legend = list(x="topleft")
  #args.legend = list(x=1.5)
)
#par(xpd = TRUE)
#l <- locator(1)


#ggplot(
#my_stats.summary.ordered.subset.rot_90, 
#beside=TRUE, 
#col=my_data.color,  
#legend=rownames(my_stats.summary.ordered.subset.rot_90),
#args.legend = list(x="topleft")