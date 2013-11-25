#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;


# Default for variables
my $scripts_path = "/home/ubuntu/matR-apps/process_DRISEE2.11-18-13";
my $sequence_file;
my $drisee_path = "/home/ubuntu/DRISEE/drisee.py";
#my $file_type = "fastq"; # fasta or fastq
my $num_proc = 8;
my $stat_file;
my $drisee_log;
my $drisee_stdout;
my $data_log = "data_log.txt";
my $command_log = "command_log.txt";
my $download_log = "download_log.txt";
my $help;
my $debug;

if( $debug ){ print STDOUT "made it here"."\n"; }

# check input args and display usage if not suitable
# if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }
if ( $ARGV[0] =~ /-h/ ) { &usage(); }

unless ( @ARGV > 0 || $sequence_file ) { &usage(); }
unless ( @ARGV > 0 ) { &usage(); }

if ( ! GetOptions (
		   "r|scripts_path=s"  => \$scripts_path,
		   "p|drisee_path=s"   => \$drisee_path,
		   "i|sequence_file=s" => \$sequence_file,
		   #"t|file_type=s"     => \$file_type,
		   "n|num_proc=i"      => \$num_proc,
		   "s|stat_file=s"     => \$stat_file,
		   "l|drisee_log=s"    => \$drisee_log,
		   "o|drisee_stdout=s" => \$drisee_stdout,
		   "a|download_log=s"  => \$download_log,
		   "b|command_log=s"   => \$command_log,
		   "c|data_log=s"      => \$data_log,
		   "h|help!"           => \$help,
		   "d|debug!"          => \$debug
		   #"w|cleanup!"        => \$cleanup
		  )
   ) { &usage(); }

my $start_time = time;

# generate default names for output files 
unless ( defined $stat_file && length $stat_file > 0 )         { $stat_file = $sequence_file."."."drisee_STAT.txt" };
unless ( defined $drisee_log  && length $drisee_log > 0 )      { $drisee_log = $sequence_file."."."drisee_log.txt" };
unless ( defined $drisee_stdout && length $drisee_stdout > 0 ) { $drisee_stdout = $sequence_file."."."drisee_stdout.txt" };
unless ( defined $download_log && length $download_log > 0 )   { $download_log = $sequence_file."."."download_log.txt" };
unless ( defined $command_log && length $command_log > 0 )     { $command_log = $sequence_file."."."command_log.txt" };
unless ( defined $data_log  && length $data_log > 0 )          { $data_log = $sequence_file."."."data_log.txt" };

# get the sequence type from the sequence file extension
my(@split_filename) = split(".", $sequence_file);
#my $file_type;

my $file_type = $split_filename[ scalar(@split_filename) ]; 

print STDOUT "\n\n"."SCALAR: ".scalar(@split_filename);
print STDOUT "\n\n"."FILE TYPE IS: ". $file_type."\n\n";
 
unless ( $file_type eq "fasta" || $file_type eq "fastq"){ # stop if extension is not fasta or fastq
  exit "$file_type is not a valid extension/file type -- only fasta and fastq are accepted."
}

# create a cummulative log of the data - add header if the file does not exist
unless (-e $data_log){ 
  open(DATA_LOG, ">", $data_log) or die "\n\n"."can't open DATA_LOG $data_log"."\n\n";
			    
  # print a header
  print DATA_LOG (
		  "# This is a cummulative summary log of the data that process_DRISEE2.pl has produced."."\n".
		  "file"."\t".
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
		  "Non-contam-DRISEE_score"."\n"
		 );
  close (DATA_LOG);
  }

# create a log for the DRISEE commands that the script issues
unless ( -e $command_log ){
  open(COMMAND_LOG, ">", $command_log) or die "\n\n"."can't open COMMAND_LOG $command_log"."\n\n";			    
  # print a header
  print COMMAND_LOG "# This is a log of the system commands that process_DRISEE2.pl has produced."."\n";		    
  close (COMMAND_LOG);
}

# my $start_time = time;

# # DOWNLOAD THE DATA
# # a little bit of parsing to make the NULL value R friendly
# if ( $mgrast_key eq "NULL" ){
#   $mgrast_key =~ s/\"//;
# }

# my $r_cmd = qq(source("$scripts_path/download_sequence.r")
# suppressMessages( download_sequence(
#     mgid="$mgid",
#     mg_key=$mgrast_key,
#     log="$download_log"
# ))
# );
# open(COMMAND_LOG, ">>", $command_log) or die "\n\n"."can't open COMMAND_LOG $command_log"."\n\n";
# print COMMAND_LOG "\n"."R Command:"."\n".$r_cmd."\n";
# system(qq(echo '$r_cmd' | R --vanilla --slave --silent));

# my $start_dl = time;
# print COMMAND_LOG "\n"."waiting for the sequence file to download: start(".$start_dl.") end(";
# # wait for the sequence file to exist before proceeding
# sleep 1 while ( !(-e $sequence_file) );
# # make sure that the file not only exists, but is not being modified before proceeding
# my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($sequence_file);
# sleep 1 while ( !( $mtime > 5 ) );
# my $end_dl = time;
# print COMMAND_LOG time."). It took (".($end_dl-$start_dl).") seconds to complete"."\n";

# RUN DRISEE
my $system_command = (
		      $drisee_path.
		      " -t ".$file_type.
		      " -l ".$drisee_log.
		      " --percent -v".
		      " -p ".$num_proc.
		      " ".$sequence_file.
		      " ".$stat_file.
		      " > ".$drisee_stdout
		     );
open(COMMAND_LOG, ">>", $command_log) or die "\n\n"."can't open COMMAND_LOG $command_log"."\n\n";
print COMMAND_LOG "\n"."DRISEE_command:"."\n".$system_command."\n";
my $start_drisee = time;
print COMMAND_LOG "\n"."DRISEE start (".$start_drisee.") end(";
system($system_command);
# wait for the drisee stdout file to exist before proceeding
sleep 1 while ( !(-e $drisee_stdout) );
# make sure that the file not only exists, and it's size is not zero
my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($drisee_stdout);
sleep 1 while ( !( $size > 0 ) );
# make sure that the file is complete
my $file_done = 0;
while ($file_done == 0){
  sleep 1; 
  my $file_tail = `tail -n 3 $drisee_stdout`;
  chomp $file_tail;
  my @file_tail_array = split("\n", $file_tail);
  my $third_to_last_line = $file_tail_array[0];
  if ( $third_to_last_line =~ /^Non/ ){ # consider the file to be done of the second to last line starts with "Non..-contaminated"
    #print COMMAND_LOG "DRISEE STDOUT is done at (.time"."\n\n";
    $file_done++;
  }  
}
my $end_drisee = time;
print COMMAND_LOG time."). It took (".($end_drisee-$start_drisee).") seconds to complete."."\n";


# COMPILE THE STATS
print COMMAND_LOG "\n"."Parsing the DRISEE outputs - should just take a second."."\n";
my @summary_values = ($sequence_file); # array

open(DRISEE_STDOUT, "<", $drisee_stdout) or die "\n\n"."can't open DRISEE_STDOUT $drisee_stdout"."\n\n";
while (my $line = <DRISEE_STDOUT>){
    chomp $line;
    if ($line =~ /^V|^bp|^se|^av|^st|^le|^In|^Processed|^Dr|^Con|^Non-contam/){ # skip comment lines
      if($debug){ print STDOUT "\n"."line: ".$line; }
      chomp $line;
      my @line_array = split("\t", $line);
      my $array_value = $line_array[1];     
      push (@summary_values, $array_value);
    }
  }
	
my $summary_line;
$summary_line = join("\t", @summary_values);

open(DATA_LOG, ">>", $data_log) or die "\n\n"."can't RE-open DATA_LOG $data_log"."\n\n";
print DATA_LOG $summary_line."\n";
close(DATA_LOG);



# CLEANUP -- FOR NOW, JUST DELETE THE SEQUENCE FILE
# unlink $sequence_file;
my $end_time = time;

print COMMAND_LOG "DONE. It took (".($end_time-$start_time).") seconds to complete analysis of: ".$sequence_file."."."\n\n";


# SUBS
sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

USAGE:


DESCRIPTION:
This is a script that can be used to run DRISEE2 on multiple data sets.
Is designed to run on one dataset at a time, but write consecutive outputs 
to summary files -- one with a summary of  the downloads, another the data
summary, and a third with a summary of DRISEE commands issued.
This version acts on a sequence file that has already been downloaded.
It assumes that the sequence type is indicated by the file extension which 
is fasta or fastq - anything else will be rejected.

OPTIONS:

    -i|file              (string)  sequence file to process            no default
  
    -r|scripts_path      (string)  path of this script                 default: $scripts_path
    -p|drisee_path       (string)  location of DRISEE (/drisee.py)     default: $drisee_path
    -n|num_proc          (int)     num parallel processes              default: $num_proc
    -s|stat_file         (string)  drisee_stats file                   default: mgid.file_type.drisee_STAT.txt
    -l|drisee_log        (string)  drisee_log                          default: mgid.file_type.drisee_log.txt
    -o|drisee_stdout     (string)  drisee_stdout                       default: mgid.file_type.drisee_stdout.txt
    -a|download_log      (string)  cummulative log of the downloads    default: mgid.file_type.download_log.txt
    -b|command_log       (string)  cummulative log of commands         default: mgid.file_type.command_log.txt
    -c|data_log          (string)  cummulative data log                default: mgid.file_type.data_log.txt    
________________________________________________________________________________________
		   
    -h|help              (flag)    display help for this script
    -d|debug		 (flag)    run the script in debug mode

);
  exit 1;
}

