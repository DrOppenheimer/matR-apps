#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
#use FindBin;
use File::Basename;
#use Statistics::Descriptive;

my($blat8_in, $help, $verbose, $debug);

my $min_pid = 90 ;
my $min_al = 50 ;
my $max_evalue = 1.0e-10 ;
my $min_bitscore = 300 ;


# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

if ( ! GetOptions (
		   "i|blat8_in=s"   => \$blat8_in,		   
		   "p|min_pid"      => \$min_pid,
		   "a|min_al"       => \$min_al,
		   "e|max_evalue"   => \$max_evalue,
		   "b|min_bitscore" => \$min_bitscore,		   
		   "h|help!"        => \$help, 
		   "v|verbose!"     => \$verbose,
		   "d|debug!"       => \$debug
		  )
   ) { &usage(); }

unless ( @ARGV > 0 || $blat8_in ) { &usage(); }
if( $help ){ &usage(); }

# open files
$file_out= $blat8_in.".FILTER_SUMMARY.txt";
open(FILE_IN, "<", $blat8_in) or die "Can't open FILE_IN $blat8_in";
open(FILE_OUT, ">", $file_out) or die "Can't open FILE_OUT $file_out";

# write header to output
print FILE_OUT "# Query id"."\t"."Subject id"."\t"."% identity"."\t"."alignment length"."\t"."mismatches"."\t"."gap openings"."\t"."q. start"."\t"."q. end"."\t"."s. start"."\t"."s. end"."\t"."e-value"."\t"."bit score"."\n";

# one hash for each of the values 
my $min_evalue_hash;

while (my $line = <FILE_IN>){

  chomp $line;
  my @line_array = split("\t", $line);
  #if($debug){ print STDOUT "input line: ".$line."\n"; }
  my $query_id = $line_array[0];
  #if($debug){ print STDOUT "ID: ".$query_id."\n"; }
  my $my_pid = $line_array[2];
  my $my_al = $line_array[3];
  my $my_evalue = $line_array[10];
  #if($debug){ print STDOUT "evalue: ".$evalue."\n"; }  
  my $my_bitscore = $line_array[11];
  
  if( ($my_pid >= $min_pid) && ($my_al >= $min_al) && ($my_evalue <= $max_evalue) && ($my_bitscore >= $min_bitscore) ){
    print FILE_OUT $line."\n";
  }

}

  


sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

DESCRIPTION:
Read through blast8 output - print (in order of query) all hits that meet the specified thresholds.
   
USAGE: filter_blat8 -i blat8_file [options]
 
    -p|--min_pid      (float)  : minimum accepted percent identity : default = $min_pid
    -a|--min_al       (int)    : minimum accepted alignment length : default = $min_al
    -e|--max_evalue   (float)  : maximum accepted evalue           : default = $max_evalue
    -b|--min_bitscore (int)    : minimum accepted bitscore         : default = $min_bitscore
 _______________________________________________________________________________________

    -h|help           (flag)   : see the help/usage
    -v|verbose        (flag)   : run in verbose mode
    -d|debug          (flag)   : run in debug mode

);
  exit 1;
}
