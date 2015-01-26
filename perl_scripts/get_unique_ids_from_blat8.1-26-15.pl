#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
#use FindBin;
use File::Basename;
#use Statistics::Descriptive;

my($blat8_in, $help, $verbose, $debug);

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

if ( ! GetOptions (
		   "b|blat8_in=s" => \$blat8_in,
		   "h|help!"      => \$help, 
		   "v|verbose!"   => \$verbose,
		   "d|debug!"     => \$debug
		  )
   ) { &usage(); }

unless ( @ARGV > 0 || $blat8_in ) { &usage(); }
if( $help ){ &usage(); }

# open files
$file_out= $blat8_in.".UNIQUE_IDs.txt";
open(FILE_IN, "<", $blat8_in) or die "Can't open FILE_IN $blat8_in";
open(FILE_OUT, ">", $file_out) or die "Can't open FILE_OUT $file_out";

my $id_hash;


while (my $line = <FILE_IN>){
  chomp $line;
  my @line_array = split("\t", $line);
  my $query_id = $line_array[0];
  unless( $id_hash -> { $query_id } ){
    $id_hash -> { $query_id } = 1;
  }
}


while( my( $key, $value ) = each $id_hash ){
  print FILE_OUT $key."\n";
}



sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

DESCRIPTION:
return a single column list that contains only the unique ids contained in a blast8 output
   
USAGE: get_unique_ids_from_blat8 -b blat8_file
 
    -b|--blast8_in (string)  no default 
 _______________________________________________________________________________________

    -h|help                       (flag)       see the help/usage
    -v|verbose                    (flag)       run in verbose mode
    -d|debug                      (flag)       run in debug mode

);
  exit 1;
}
