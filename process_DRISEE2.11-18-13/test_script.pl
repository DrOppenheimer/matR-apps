#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

my $debug=1;

my $file = "mgm4473069.3.fastq.drisee_stdout.txt";

my $file_done = 0;

while ($file_done == 0){
 
  sleep 10;
  my $file_tail = system("tail -n 3 $file");
  if($debug){ print "\n\n"."last three lines out stdout:"."\n"; }
  my @file_tail_array = split("\n", $file_tail);
  if ( $file_tail_array[1] =~ m/^Con/ ){ # consider the file to be done of the second to last line starts with "Con..taminated"
    if($debug){print STDOUT "Second to last line: "."\n".$file_tail_array[1]."\n\n";}
    $file_done++;
  }
  
}
