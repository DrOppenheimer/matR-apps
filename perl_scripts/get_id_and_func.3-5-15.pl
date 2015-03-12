#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
#use FindBin;
use File::Basename;
#use Statistics::Descriptive;

my($fasta_in, $file_out, $append, $help, $verbose, $debug);

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

if ( ! GetOptions (
		   "f|fasta_in=s" => \$fasta_in,
		   "o|file_out=s"   => \$file_out,
		   "a|append!"    => \$append, # append output
		   "h|help!"      => \$help, 
		   "v|verbose!"   => \$verbose,
		   "d|debug!"     => \$debug
		  )
   ) { &usage(); }

# create default output name
unless($file_out) { $file_out = $fasta_in.".fastaID_funcName.txt"; }

# display usage if no args or requested with flag
unless ( @ARGV > 0 || $fasta_in ) { &usage(); }
if( $help ){ &usage(); }

# open files
open(FILE_IN, "<", $fasta_in) or die "Can't open FILE_IN $fasta_in";
unless( $append ){  
  open(FILE_OUT, ">", $file_out) or die "Can't open FILE_OUT $file_out"; 
} else {
  open(FILE_OUT, ">>", $file_out) or die "Can't open FILE_OUT $file_out";
}

# get func name from fasta file
#my $func_name = ($fasta_in =~ s/(.*)\.[^.]+$//;)
#$fasta_in =~ s/(.*)\.[^.]+$//;
$fasta_in =~ s/\.fasta$//;
if ($debug) {print STDOUT "func: ".$fasta_in."\n";}

while (my $line = <FILE_IN>){
  chomp $line;
  if( $line =~ m/^>/ ){
    my @line_array = split(" ", $line);
    my $id = $line_array[0];
    chomp $id;
    $id =~ s/^>//;
    print FILE_OUT $id."\t".$fasta_in."\n";
  }
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
 
    -f|--fasta_in  (string)  no default
    -o|--file_out  (string)  default: $file_out
    -a|--append    (flag)    append output to file out (won't work if you use default output name)
 _______________________________________________________________________________________

    -h|help                       (flag)       see the help/usage
    -v|verbose                    (flag)       run in verbose mode
    -d|debug                      (flag)       run in debug mode

);
  exit 1;
}
