#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
#use FindBin;
use File::Basename;
#use Statistics::Descriptive;

my($blat8_in, $help, $verbose, $debug);





#my $current_dir = getcwd()."/";
# path of this script
#my $DIR=dirname(abs_path($0));  # directory of the current script, used to find other scripts + datafiles
#my $DIR="$FindBin::Bin/";

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
$file_out= $blat8_in.".FILTER_SUMMARY.txt";
open(FILE_IN, "<", $blat8_in) or die "Can't open FILE_IN $blat8_in";
open(FILE_OUT, ">", $file_out) or die "Can't open FILE_OUT $file_out";

# write header to output
print FILE_OUT "# Query id"."\t"."Subject id"."\t"."% identity"."\t"."alignment length"."\t"."mismatches"."\t"."gap openings"."\t"."q. start"."\t"."q. end"."\t"."s. start"."\t"."s. end"."\t"."e-value"."\t"."bit score";

# read one time to get the best values
# ready through second time to print key sorted values that match best (could be more than 1)


# one hash for each of the values 
my $min_evalue_hash;
#my %max_pid_hash;



while (my $line = <FILE_IN>){
  chomp $line;
  my @line_array = split("\t", $line);
  if($debug){ print STDOUT "input line: ".$line."\n"; }
  my $query_id = $line_array[0];
  if($debug){ print STDOUT "ID: ".$query_id."\n"; }
  #my $pid = $line_array[2];
  #my $al = $line_array[3];
  my $evalue = $line_array[10];
  if($debug){ print STDOUT "evalue: ".$evalue."\n"; }  
  #my $bscore = $line_array[11];
  
  # load line into hash if there is not one for the query
  unless( $min_evalue_hash -> { $query_id } ){
    $min_evalue_hash -> { $query_id } = $line;
    if($debug){ print STDOUT "FIRST ENTERED ".$query_id."\n"; }
  # replace existing line if it has a smaller e-value for the same query (just to find min e value used below)
  } else {
    my $hash_line = $min_evalue_hash -> { $query_id };
    my @hash_line_array = split("\t", $hash_line);
    my $hash_evalue = $hash_line_array[10];
    if( $evalue < $hash_evalue ){
      $min_evalue_hash -> { $query_id } = $line;
      if($debug){ print STDOUT $query_id.":      ".$evalue." < ".$hash_evalue."\n"; }
    }
  }
}
close(FILE_IN); 



# second read -- go through the hash keys - print every line with an evalue that matches the min found above
while( my( $key, $value ) = each $min_evalue_hash ){

  # get the min evalue found in the first pass for a query
  my @hash_line_array = split("\t", $value);
  my $min_evalue = $hash_line_array[11];

  # match evalues of hits to the same query to the min, print if they match
  open(FILE_IN, "<", $blat8_in) or die "Can't open FILE_IN $blat8_in";
  while (my $line = <FILE_IN>){
    chomp $line;
    my @line_array = split("\t", $line);
    my $query_id = $line_array[0];
    my $evalue = $line_array[10];
    if ( $evalue==$min_evalue ){
      print FILE_OUT $line."\n";
    }
  }
  close(FILE_IN);
}
  


sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

DESCRIPTION:
Read through blast8 output - print (in order of query) all hits that match min e-value for each wuery
   
USAGE: filter_blat8 -b blat8_file
 
    -b|--blast8_in (string)  no default 
 _______________________________________________________________________________________

    -h|help                       (flag)       see the help/usage
    -v|verbose                    (flag)       run in verbose mode
    -d|debug                      (flag)       run in debug mode

);
  exit 1;
}
