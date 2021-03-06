##############################################################################
###
### IMAGE GALLERY
###
### The R/matR code below will work "out of the box" to produce the images shown.
### Begin your session by loading matR with:  library (matR)
###
### The code for each visualization is separate.
###
### Just producing rough-and-ready images is even easier, because the majority of 
### code below represents graphical formatting parameters, that is, finishing touches.
###
##############################################################################

cc <- collection (waters, L1 = view (level = "level1"))
library (Matrix)
image (cc$L1, aspect = 1, 
       xlab = NULL, ylab = NULL, sub = NULL, 
       main = "Fresh and Spring Water Samples: Raw Function Abundance (Level 1)",
       colorkey = TRUE, scales = list (
         x = list (at = 1:24, labels = names (cc), rot = 45),
         y = list(at = 1:28, labels = rownames (cc$L1))))

##############################################################################

l1 <- metadata (Marine) [,c("metadata","env_package","data","misc_param")]
l2 <- metadata (Marine) [,c("metadata","env_package","data","samp_store_temp")]
l3 <- metadata (Marine) [,c("metadata","env_package","data","diss_carb_dioxide")]
l4 <- metadata (Marine) [,c("metadata","env_package","data","atmospheric_data")]
par ("mar" = c (5.1, 14, 4.1, 2.1))
boxplot (Marine$normed, 
         main = "Log-Normalized Diversity of\nFunction Abundance in Marine Samples",
         names = paste(l1, ", ", l2, ",\n", l3, ", ", l4, sep = ""),
         show.names = TRUE, las = 2, outpch = 21, outcex = 0.5, cex.lab = 0.8,
         boxwex = 0.6, cex.axis = 0.7, horizontal = TRUE,
         xlab = "1+log2(N), scaled to [0,1] after mean-centering")

##############################################################################

library (gplots)
par (cex.main = .8)
heatmap.2(as.matrix (Guts$normed), margins = c(8,1), cexCol = .95, labRow = NA,
          labCol = paste (substr (names (metadata (Guts)), 4, 12), names (Guts), sep = "\n"),
          key = FALSE, trace = "none", colsep = 1:7, sepwidth = 0.01, 
          main = "Gut Samples Clustered by Functional Annotation")


##############################################################################
 
library (scatterplot3d)
P <- pco (Coral$normed)
pts <- cbind (x = P$vectors[,1], y = P$vectors[,2], z = P$vectors[,3])
f <- scatterplot3d(pts,
  angle = 50, main = "Initial Principal Coordinates Of Thirteen Coral Samples",
  axis = TRUE, box = FALSE, pch = 19, type = "h", lty.hplot = 3,
  xlab = paste ("R**2 =", format (P$values[1], 3)), 
  ylab = paste ("R**2 =", format (P$values[2], 3)),
  zlab = paste ("R**2 =", format (P$values[3], 3)))
text (f$xyz.convert (pts), substr (names (Coral), 4, 12), cex = .7, pos = 4)

##############################################################################

cc <- collection (guts, 
                  L1 = view (level = "level1"), 
                  L2 = view (level = "level2"), 
                  L3 = view (level = "level3"))
groups (cc) <- c (1,1,1,2,2,3,3)
P1 <- pco (cc$L1)
P2 <- pco (cc$L2)
P3 <- pco (cc$L3)
plot (x = P1$vectors[,1], y = P1$vectors[,2], pch = 19,
      col = factor (groups (cc), labels = c ("blue","purple","plum")),
      main = "Principal Coordinates Analysis\nBy Varying Function Level")
points (x = P2$vectors[,1], y = P2$vectors[,2], pch = 19,
        col = factor (groups (cc), labels = c ("salmon","orange","gold")))
points (x = P3$vectors[,1], y = P3$vectors[,2], pch = 19,
        col = factor (groups (cc), labels = c ("black","grey60","grey80")))
text (x = P1$vectors[,1], y = P1$vectors[,2], labels = names (cc))
legend (...)

##############################################################################

library (gplots)
graphics.off()
plot.new ()
title ("Clustering by Multiple Reference Databases")
split.screen(fig=c(2,2), erase = FALSE)
screen (1, new = FALSE)
image(Guts$normed, asp = 1)
screen (2, new = FALSE)
image(Guts$normed)
heatmap.2(as.matrix (Guts$normed), labRow = NA,
          labCol = paste (names (metadata (Guts)), names (Guts), sep = "\n"),
          cexCol = .7, key = FALSE, trace = "none", colsep = 1:7, sepwidth = 0.01,
          sub = "Greengenes")
screen (2, new = FALSE)
heatmap.2(as.matrix (Guts$normed), labRow = NA,
          labCol = paste (names (metadata (Guts)), names (Guts), sep = "\n"),
          cexCol = .7, key = FALSE, trace = "none", colsep = 1:7, sepwidth = 0.01,
          sub = "Greengenes")
screen (3, new = FALSE)
heatmap.2(as.matrix (Guts$normed), labRow = NA,
          labCol = paste (names (metadata (Guts)), names (Guts), sep = "\n"),
          cexCol = .7, key = FALSE, trace = "none", colsep = 1:7, sepwidth = 0.01,
          sub = "Greengenes")
screen (4, new = FALSE)
heatmap.2(as.matrix (Guts$normed), labRow = NA,
          labCol = paste (names (metadata (Guts)), names (Guts), sep = "\n"),
          cexCol = .7, key = FALSE, trace = "none", colsep = 1:7, sepwidth = 0.01,
          sub = "Greengenes")

function make (exList, filename = "examples.html") {
  f <- file (filename)
  write header
  for () {
    write image
    write code
    write HR  
    }
  close (f)
}
