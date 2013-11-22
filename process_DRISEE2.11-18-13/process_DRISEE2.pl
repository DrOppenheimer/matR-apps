#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;


# Default for variables
my $scripts_path = "/home/ubuntu/matR-apps/process_DRISEE2.11-18-13/";
my $mgrast_key = "NULL";
my $drisee_path = "/home/ubuntu/DRISEE/drisee.py";
my $mgid;
my $file_type = "fastq"; # fasta or fastq
my $num_proc = 1;
#my $percent = 1;
#my $verbose = 1;
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

unless ( @ARGV > 0 || $mgid ) { &usage(); }
unless ( @ARGV > 0 ) { &usage(); }

if ( ! GetOptions (
		   "r|scripts_path=s"  => \$scripts_path,
		   "m|mgrast_key=s"    => \$mgrast_key,
		   "p|drisee_path=s"   => \$drisee_path,
		   "i|mgid=s"       => \$mgid,
		   "t|file_type=s"     => \$file_type,
		   "n|num_proc=i"      => \$num_proc,
		   #"p|percent!"        => \$percent,
		   #"v|verbose!"        => \$verbose,
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


# generate default names for output files 
my $sequence_file = $mgid.".".$file_type;
unless ( defined $stat_file && length $stat_file > 0 )         { $stat_file = $sequence_file."."."drisee_STAT.txt" };
unless ( defined $drisee_log  && length $drisee_log > 0 )      { $drisee_log = $sequence_file."."."drisee_log.txt" };
unless ( defined $drisee_stdout && length $drisee_stdout > 0 ) { $drisee_stdout = $sequence_file."."."drisee_stdout.txt" };
unless ( defined $download_log && length $download_log > 0 )   { $download_log = $sequence_file."."."download_log.txt" };
unless ( defined $command_log && length $command_log > 0 )     { $command_log = $sequence_file."."."command_log.txt" };
unless ( defined $data_log  && length $data_log > 0 )          { $data_log = $sequence_file."."."data_log.txt" };

# create a cummulative log of the data - add header if the file does not exist
unless (-e $data_log){ 
  open(DATA_LOG, ">", $data_log) or die "\n\n"."can't open DATA_LOG $data_log"."\n\n";
			    
  # print a header
  print DATA_LOG (
		  "# This is a cummulative summary log of the data that process_DRISEE2.pl has produced."."\n".
		  "mgid"."\t".
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


# DOWNLOAD THE DATA
# a little bit of parsing to make the NULL value R friendly
if ( $mgrast_key eq "NULL" ){
  $mgrast_key =~ s/\"//;
}

my $r_cmd = qq(source("$scripts_path/download_sequence.r")
suppressMessages( download_sequence(
    mgid="$mgid",
    mg_key=$mgrast_key,
    log="$download_log"
))
);
open(COMMAND_LOG, ">>", $command_log) or die "\n\n"."can't open COMMAND_LOG $command_log"."\n\n";
print COMMAND_LOG "\n"."R Command:"."\n".$r_cmd."\n";
close (COMMAND_LOG);
system(qq(echo '$r_cmd' | R --vanilla --slave --silent));

open(COMMAND_LOG, ">>", $command_log) or die "\n\n"."can't RE-open COMMAND_LOG $command_log"."\n\n";
print COMMAND_LOG "\n"."waiting for the sequence file to download: start(".time.") end(";
# wait for the sequence file to exist before proceeding
sleep 10 while ( !(-e $sequence_file) );
# make sure that the file not only exists, but is not being modified before proceeding
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($sequence_file);
sleep 10 if ( !( $mtime > 10 ) );
print COMMAND_LOG time.")"."\n";
close (COMMAND_LOG);

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
open(COMMAND_LOG, ">>", $command_log) or die "\n\n"."can't RE-open COMMAND_LOG $command_log"."\n\n";
print COMMAND_LOG "\n"."DRISEE_command:"."\n".$system_command."\n";
close(COMMAND_LOG);
system($system_command);

open(COMMAND_LOG, ">>", $command_log) or die "\n\n"."can't RE-open COMMAND_LOG $command_log"."\n\n";
print COMMAND_LOG "\n"."waiting for the DRISEE stats: start(".time.") end(";
# wait for the drisee stdout file to exist before proceeding
sleep 10 while ( !(-e $drisee_stdout) );
# make sure that the file not only exists, but is not being modified before proceeding
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($drisee_stdout);
sleep 10 if ( !( $mtime > 10 ) );
print COMMAND_LOG time.")"."\n";
close (COMMAND_LOG);

# COMPILE THE STATS
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
unlink $sequence_file;



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
It will download the sequence data for a given mgid, run DRISEE, summarize 
results, and delete the sequence file.
Is designed to run on one dataset at a time, but write consecutive outputs 
to summary files -- one with a summary of  the downloads, another the data
summary, and a third with a summary of DRISEE commands issued.

OPTIONS:

    -i|mgid              (string)  mgid of sample                      no default
  
    -r|scripts_path      (string)  path of this script                 default: $scripts_path
    -m|mgrast_key        (string)  mgrast key                          default: $mgrast_key
    -p|drisee_path       (string)  location of DRISEE (/drisee.py)     default: $drisee_path
    -t|file_type         (string)  fasta or fastq                      default: $file_type
    -n|num_proc          (int)     num parallel processes              default: $num_proc
    -s|stat_file         (string)  drisee_stats file                   default: sequence_file.drisee_STAT.txt
    -l|drisee_log        (string)  drisee_log                          default: sequence_file.drisee_log.txt
    -o|drisee_stdout     (string)  drisee_stdout                       default: sequence_file.drisee_stdout.txt
    -a|download_log      (string)  cummulative log of the downloads    default: sequence_file.download_log.txt
    -b|command_log       (string)  cummulative log of commands         default: sequence_file.command_log.txt
    -c|data_log          (string)  cummulative data log                default: sequence_file.data_log.txt    
________________________________________________________________________________________
		   
    -h|help              (flag)    display help for this script
    -d|debug		 (flag)    run the script in debug mode


);
  exit 1;
}



      # Version        
      # bp_count        
      # sequence_count 
      # average_length  
      # standard_deviation_length     
      # length_min     
      # length_max     
      # Completed in
      # Input seqs     
      # Processed bins 
      # Processed seqs  
      # Drisee score    
      # Contam bins    
      # Contam seqs     
      # Drisee score    
      # Non-contam bins 
      # Non-contam seqs
      # Drisee score    






# python ~/DRISEE/drisee.py -t fastq -l v1p5_mgm4473069_log --percent -v mgm4473069.fq mgm4473069.v1p5.STAT> v1.5_mgm4473069_stdout
