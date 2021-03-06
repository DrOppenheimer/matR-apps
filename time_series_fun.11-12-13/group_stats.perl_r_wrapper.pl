#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;


# Default for variables
my $script_path = "/Users/kevin/git/matR-apps.DrOppenheimer/matR-apps/time_series_fun.11-12-13/";
my $file_in = "sample_time_series_data.groups_in_file.txt";
my $file_out = "my_stats.summary.txt";
my $stat_test = "Kruskal-Wallis";
my $order_by = "NULL";
my $order_decreasing = "TRUE";
my $group_lines = 1;
my $group_line_to_process = 1;
my $my_grouping = "NA";


my($help, $verbose, $debug);

if( $debug ){ print STDOUT "made it here"."\n"; }

# check input args and display usage if not suitable
# if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }
if ( $ARGV[0] =~ /-h/ ) { &usage(); }

#unless ( @ARGV > 0 || $file_in ) { &usage(); }
unless ( @ARGV > 0 ) { &usage(); }

if ( ! GetOptions (
		   "s|script_path=s"           => \$script_path,
		   "f|file_in=s"               => \$file_in,
		   "o|file_out=s"              => \$file_out,
		   "t|stat_test=s"             => \$stat_test,
		   "b|order_by=s"              => \$order_by,
                   "d|order_decreasing=s"      => \$order_decreasing,
		   "l|group_lines=s"           => \$group_lines, 
		   "p|group_line_to_process=s" => \$group_line_to_process,
		   "g|my_grouping=s"           => \$my_grouping,
		   "h|help!"                   => \$help,
		   "v|verbose!"                => \$verbose,
		   "d|debug!"                  => \$debug
		   
		  )
   ) { &usage(); }

# time stamp to add to the name of the temporary script to make it unique
my $time_stamp = time();

# a little bit of parsing if user supplies groups string
$my_grouping =~ s/\"//;

# a little bit of parsing to deal with R NULL properly
# my $order_by_value = "NULL";
# unless ( $order_by eq "default" ){ $order_by_value = $order_by; }

# write a temporary R script that will be executed to perform the analysis
my $temp_script = "group_stats_r_script.".$time_stamp.".r";
open(R_SCRIPT, ">", $temp_script);
print R_SCRIPT "# This is a perl generated R script to run group_stats.r"."\n";
print R_SCRIPT "source(\"/".$script_path."/group_stats.r\")"."\n";
print R_SCRIPT "suppressMessages(group_stats( 
file_in=\"".$file_in."\", 
file_out=\"".$file_out."\",
stat_test=\"".$stat_test."\", 
order_by=".$order_by.",
order_decreasing=".$order_decreasing.", 
group_lines=".$group_lines.", 
group_line_to_process=".$group_line_to_process.", 
my_grouping=".$my_grouping.
"))";
#suppressMessanges()
#suppressWarnings()

# run the temporary R script
system "R --vanilla --slave --silent < ".$temp_script;

# delete the temprary R script
unlink $temp_script;


# SUBS

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
