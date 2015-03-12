fix_lt <- function(my_file){
  command_line_1 <- paste("/Users/kevin/bin/line_term.pl -i ", getwd(), "/",  my_file," -o ", my_file, ".tmp", sep="" )
  command_line_2 <- paste("rm ", getwd(), "/", my_file, sep="")
  command_line_3 <- paste("mv ", getwd(), "/", my_file, ".tmp ", getwd(), "/", my_file, sep="")
  system(command_line_1)
  system(command_line_2)
  system(command_line_3)
}
# simple function to fix line terminators -- problems introduced by excel creation of tab delimited files
# requires /perl_scripts/line_term.pl - expects it in ~/bin
