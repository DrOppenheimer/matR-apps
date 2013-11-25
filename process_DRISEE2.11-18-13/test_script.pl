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
 
  #sleep 10;
  #my $file_tail = system("tail -n 3 $file");
  
  my $file_tail = `tail -n 4 $file`;
  chomp $file_tail;

  #if($debug){ print "\n\n"."last three lines out stdout:"."\n".$file_tail."\n"; }
  my @file_tail_array = split("\n", $file_tail);
  if($debug){print STDOUT "Fourth to last line: "."\n".$file_tail_array[0]."\n\n";}
 #if ( $file_tail_array[0] =~ m/^Con/ ){ # consider the file to be done of the second to last line starts with "Con..taminated"
    
  #  $file_done++;
  }
  
}
