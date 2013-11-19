#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;


# Default for variables
my $drisee_path = "/home/ubuntu/DRISEE/drisee.py";
my $file_in;
my $file_type = "fastq"; # fasta or fastq
#my $percent = 1;
#my $verbose = 1;
my $stat_file;
my $drisee_log;
my $drisee_stdout;
my $cummulative_log; = "cummulative_log.txt"
my $help;
my $debug;

my($help, $verbose, $debug);

if( $debug ){ print STDOUT "made it here"."\n"; }

# check input args and display usage if not suitable
# if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }
if ( $ARGV[0] =~ /-h/ ) { &usage(); }

unless ( @ARGV > 0 || $file_in ) { &usage(); }
unless ( @ARGV > 0 ) { &usage(); }

if ( ! GetOptions (
		   "d|drisee_path=s"   => \$drisee_path,
		   "f|file_in=s"       => \$file_in,
		   "t|file_type=s"     => \$file_type,
		   #"p|percent!"        => \$percent,
		   #"v|verbose!"        => \$verbose,
		   "s|stat_file=s"     => \$stat_file,
		   "l|drisee_log=s"    => \$drisee_log,
		   "o|drisee_stdout"   => \$drisee_stdout,
		   "c|cummulative_log" => \$cummulative_log,		   
		   "h|help!"           => \$help,
		   "d|debug!"          => \$debug
		  )
   ) { &usage(); }


# generate default names for output files 

unless ( $stat_file )       { $file_in."."."STAT.txt" };
unless ( $drisee_log )      { $file_in."."."drisee_log.txt" };
unless ( $drisee_stdout )   { $file_in."."."drisee_stdout.txt" };
unless ( $cummulative_log ) { "DRISEE_cummulative_log.txt" };

my $system_command = (
		      $drisee_path.
		      " -t ".$file_type.
		      " -l ".$drisee_log.
		      " --percent -v".
		      " ".$file_in.
		      " ".$stat_file.
		      " > ".$drisee_stdout
		     );

system($system_command);

# create file and add header if the file does not exist
unless (-e $cummulative_log){ 
  open(CUMMULATIVE_LOG, ">", $cummulative_log) or die "\n\n"."can't open CUMMULATIVE_LOG $cummulative_log"."\n\n";
			    
  # print a header
  print CUMMULATIVE_LOG ( 
			 "file_in"."\t".
			 "Version"."\t".
			 "bp_count"."\t".
			 "sequence_count"."\t".
			 "average_length"."\t".
			 "standard_deviation_length"."\t".
			 "length_min"."\t".
			 "length_max"."\t".
			 "input_seqs"."\t".
			 "procesed_bins"."\t".
			 "processed_seqs"."\t".
			 "OG_DRISEE_score"."\t".
			 "Contam_bins"."\t".
			 "Contam_seqs"."\t".
			 "Contam_DRISEE_score"."\t".
			 "Non-contam_bins"."\t".
			 "Non-contam_seqs"."\t".
			 "Non-contam-DRISEE_score"."\n";
			)
    close (CUMMULATIVE_LOG)
  }


my @summary_values = ($file_in); # array

while (my $line = <CUMMULATIVE_LOG>){
    chomp $line;
    if ($line =~ m/^V||^bp||^se||^av||^st||^le||^In||^Pr||^Dr||^Con||^Dr/){ # skip comment lines
      my @line_array = split("\t", $line)
      chomp $line;
      my @line_array = split("\t", $line);
      my $array_value = @line_array[1];
      push (@summary_values, $array_value);
    }
  }
	
my $summary_line = join("\t", @summary_values);

open(CUMMULATIVE_LOG, ">>", $cummulative_log) or die "\n\n"."can't RE-open CUMMULATIVE_LOG $cummulative_log"."\n\n";

print CUMMULATIVE_LOG $summary_line."\n";

# python ~/DRISEE/drisee.py -t fastq -l v1p5_mgm4473069_log --percent -v mgm4473069.fq mgm4473069.v1p5.STAT> v1.5_mgm4473069_stdout



 SUBS

sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

USAGE:
# general usage
group_stats.perl_r_wrapper.pl [options]

# test mode
group_stats.perl_r_wrapper.pl go

# normal usage, with groupings taken from file_in (using first, and only, line of groupings)
group_stats.perl_r_wrapper.pl -f sample_time_series_data.groups_in_file.txt -l 1 -p 1

# normal usage, with groupings assigned by properly formatted R string
group_stats.perl_r_wrapper.pl -f sample_time_series_data.groups_in_file.txt -l 1 -p 0 -g "c(1,1,1,2,2,2,3,3,3)"



DESCRIPTION:
Tool to apply matR-based statistical tests.
Designated test is applied with groupings defined in the input file or an input argument.
order_by NULL will order data by the calculated false discovery rate.
Use an integer value for -b|order_by to order the data by any other column in the output data file.

OPTIONS:
    -s|script_path             (string)          location of group_stats.r        default: $script_path
    -f|file_in                 (string)          input data file                  default: $file_in
    -o|file_out                (string)          output results file              default: $file_out
    -t|stat_test               (string)          matR statisitical tests          default: $stat_test
    -b|order_by                (NULL or int)     column to order data             default: $order_by
    -d|order_decreasing        (bool)            order by decreasing              default: $order_decreasing
    -l|group_lines             (int)             number of lines with groupings   default: $group_lines
    -p|group_line_to_process   (int)             line of groupings to use         default: $group_line_to_process
    -g|my_grouping             (string)          R formatted grouping string      default: $my_grouping
________________________________________________________________________________________
 
    -h|help                    (flag)            see the help/usage
    -v|verbose                 (flag)            run in verbose mode
    -d|debug                   (flag)            run in debug mode

NOTES:
Supported statistical tests (-t|stat_test) include the following tests available in matR
    Kruskal-Wallis 
    t-test-paired 
    Wilcoxon-paired 
    t-test-unpaired 
    Mann-Whitney-unpaired-Wilcoxon 
    ANOVA-one-way

Groups can be entered in two ways, as a properly formatted R list (e.g. c(1,1,2,2) or c("grp1", "grp1", "grp2", grp"2") )
with the -g|my_grouping option, or if grouping information is contained in the first n lines of the input, use the 
-l|group_lines and -p|group_line_to_process arguments to sepcify the number of lines that contain group information 
and the group line that should be used respectively.


);
  exit 1;
}
