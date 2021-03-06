#!/usr/bin/env perl 

use strict ;
use BerkeleyDB ;

my $filename = shift @ARGV ;


print $filename , "\n" ;

unless ($filename and -f $filename){
	print STDERR "No file $filename !\n";
	exit;
}


tie my %h, "BerkeleyDB::Hash",
                -Filename => $filename,
                -Flags    => DB_RDONLY
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

  
    # print the contents of the file
    while ((my $k, my $v) = each %h)
      { print "$k -> $v\n" }

