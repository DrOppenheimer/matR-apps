#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
#use File::ReadBackwards;


# use File::ReadBackwards
# my $bw = File::ReadBackwards->new("some_file");
# print reverse map { $bw->readline() } (1 .. 3);




my $debug=1;

my $file = "mgm4473069.3.fastq.drisee_stdout.txt";

my $file_done = 0;

while ($file_done == 0){
 
  sleep 10;
  
  my $file_tail = `tail -n 3 $file`;
  chomp $file_tail;

  my @file_tail_array = split("\n", $file_tail);
  
  my $third_to_last_line = $file_tail_array[0];


  if ( $third_to_last_line =~ /^Non/ ){ # consider the file to be done of the second to last line starts with "Non..-contaminated"
    print STDOUT "Third to last matches ^Non"."\n\n";
  }
  
  $file_done++;
}







# my $debug=1;

# my $file = "mgm4473069.3.fastq.drisee_stdout.txt";

# my $file_done = 0;

# while ($file_done == 0){
 
#   sleep 10;
  
#   my $file_tail = `tail -n 4 $file`;
#   chomp $file_tail;

#   my @file_tail_array = split("\n", $file_tail);
  
#   my $third_to_last_line = $file_tail_array[1];


#   #if($debug){ print "\n\n"."last three lines out stdout:"."\n".$file_tail."\n"; }
  
#   #if($debug){print "\n"."Fourth to last line: "."\n".$file_tail_array[0]."\n";}
#   #if($debug){print "\n"."Third to last line: "."\n".$file_tail_array[1]."\n";}
#   #if($debug){print STDOUT "Third to last line:"."\n".($third_to_last_line)."\n" ;}

#   if ( $third_to_last_line =~ /^Non/ ){ # consider the file to be done of the second to last line starts with "Non..-contaminated"
#     print STDOUT "Third to last matches ^Non"."\n\n";
#   }
  
#   #  $file_done++;
# }
  

