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

# a little bit of parsing to deal with R NULL properly
my $order_by_value = "NULL";
unless ( $order_by eq "default" ){ $order_by_value = $order_by; }

# write a temporary R script that will be executed to perform the analysis
my $temp_script = "group_stats_r_script.".$time_stamp.".r";
open(R_SCRIPT, ">", $temp_script);
print R_SCRIPT "# This is a perl generated R script to run group_stats.r"."\n";
print R_SCRIPT "source(\"/".$script_path."/group_stats.r\")"."\n";
print R_SCRIPT "suppressMessages(group_stats( 
file_in=\"".$file_in."\", 
file_out=\"".$file_out."\",
stat_test=\"".$stat_test."\", 
order_by=".$order_by_value.", 
group_lines=".$group_lines.", 
group_line_to_process=".$group_line_to_process.", 
my_grouping=".$my_grouping.
"))";
#suppressMessanges()
#suppressWarnings()

# run the temporary R script
system "R --vanilla --slave < ".$temp_script;

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
# test mode
group_stats.perl_r_wrapper.pl go
# normal usage, with groupings taken from file_in
group_stats.perl_r_wrapper.pl -f file_in -l group_lines -p group_line_to_process [other options]
# normal usage, with groupings assigned by properly formatted R string
group_stats.perl_r_wrapper.pl -f file_in -l 0 -p 0 -g "c(1,1,2,2)" [other options]

DESCRIPTION:
Tool to apply matR-based statistical tests.
Designated test is applied with groupings defined in the input file or an input argument.
order_by NULL will order data by the calculated false discovery rate.


OPTIONS:
    -s|script_path             (string)          location of group_stats.r        default: $script_path
    -f|file_in                 (string)          input data file                  default: $file_in
    -o|file_out                (string)          output results file              default: $file_out
    -t|stat_test               (string)          matR statisitical tests          default: $stat_test
    -b|order_by                (string or int)   column to order data             default: $order_by
    -l|group_lines             (int)             number of lines with groupings   default: $group_lines
    -p|group_line_to_process   (int)             line of groupings to use         default: $group_line_to_process
    -g|my_grouping             (string)          R formatted grouping string      default: $my_grouping
________________________________________________________________________________________

    -h|help                       (flag)       see the help/usage
    -v|verbose                    (flag)       run in verbose mode
    -d|debug                      (flag)       run in debug mode

);
  exit 1;
}












#     file_in = "sample_time_series_data.groups_in_file.txt",
#                          stat_test = "Kruskal-Wallis", # (an matR stat test)
#                          order_by = NULL, # column to order by - integer column index (1 based) or column header -- paste(stat_test, "::fdr", sep="") - NULL is the default behavior - to sort by the fdr.  If you don't know the number of the column you want to sort by - run with default settings first time, figure out the column number, then specify it the second time round. Columns are base 1 indexed.
#                          group_lines = 1,           # if groupings are in the file
#                          group_line_to_process = 1, # if groupings are in the file
#                          my_grouping = NA 








# my $conversion = 1;
# my $output_file_pattern;

# if($debug){print STDOUT "made it here"."\n";}
# # check input args and display usage if not suitable
# if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

# unless ( @ARGV > 0 || $input_file ) { &usage(); }

# if ( ! GetOptions (
# 		   "i|input_file=s"               => \$input_file,
# 		   "o|output_file=s"              => \$output_file_pattern,
# 		   "c|conversion=i"               => \$conversion,
# 		   "h|help!"                      => \$help, 
# 		   "v|verbose!"                   => \$verbose,
# 		   "d|debug!"                     => \$debug
# 		  )
#    ) { &usage(); }

# ##################################################
# ##################################################
# ###################### MAIN ######################


















# #! /usr/bin/perl -w

# # Borrowed from http://bioblog5000.blogspot.com/2009/10/perl-wrapper-for-r.html

# unless (@ARGV){
#   warn "\n";
#   warn "Runs an R script with STDERR dumped to STDOUT\n\n";
#   warn "Usage: $0 \n\n";
#   exit(1);
# }

# my $rFile = shift @ARGV;

# die "Stubbornly refusing to run R on a file that doesn't end in .r!\n"
#   unless $rFile =~ /\.r$/;

# my $oFile = `basename $rFile .r`; chomp( $oFile );

# my $args = join(" ", @ARGV);

# if ($args){
#   $args = "--args $args";
# }

# warn "Using: R $args < $rFile > $oFile.dump\n";



# open ( OH, ">$oFile.dump" )
#   or die "cant : $! \n";

# my $pid =
#   open( PH, "R $rFile -q --vanilla $args < $rFile 2>&1 |" )
#   or die "cant : $? : $! \n";

# my $lineNumber;

# while(){
#   $lineNumber++ if /^(\>|\+)/o;
#   print OH;
# }

# close( OH );
# close( PH );

# if ($?) {
#   #warn "killed by $?\n";
#   warn "FAILED AT LINE $lineNumber\n";
#   system("tail -n 5 $oFile.dump");
#   exit(1);
# }

# warn "OK (NO ERRORS DETECTED)\n";
