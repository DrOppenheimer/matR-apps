#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;


# Default for variables
my $drisee_path = "/home/ubuntu/DRISEE/drisee.py";
my $file_in;
my $file_type = "fastq"; # fasta or fastq
my $num_proc = 1;
#my $percent = 1;
#my $verbose = 1;
my $stat_file;
my $drisee_log;
my $drisee_stdout;
my $data_log = "DRISEE_data_log.txt";
my $command_log = "DRISEE_command_log.txt";
my $help;
my $debug;

if( $debug ){ print STDOUT "made it here"."\n"; }

# check input args and display usage if not suitable
# if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }
if ( $ARGV[0] =~ /-h/ ) { &usage(); }

unless ( @ARGV > 0 || $file_in ) { &usage(); }
unless ( @ARGV > 0 ) { &usage(); }

if ( ! GetOptions (
		   "p|drisee_path=s"   => \$drisee_path,
		   "f|file_in=s"       => \$file_in,
		   "t|file_type=s"     => \$file_type,
		   "n|num_proc=i"      => \$num_proc,
		   #"p|percent!"        => \$percent,
		   #"v|verbose!"        => \$verbose,
		   "s|stat_file=s"     => \$stat_file,
		   "l|drisee_log=s"    => \$drisee_log,
		   "o|drisee_stdout=s" => \$drisee_stdout,
		   "c|data_log=s"      => \$data_log,
		   "b|command_log=s"   => \$command_log,
		   "h|help!"           => \$help,
		   "d|debug!"          => \$debug
		  )
   ) { &usage(); }


# generate default names for output files 

unless ( defined $stat_file && length $stat_file > 0 )         { $stat_file = $file_in."."."drisee_STAT.txt" };
unless ( defined $drisee_log  && length $drisee_log > 0 )      { $drisee_log = $file_in."."."drisee_log.txt" };
unless ( defined $drisee_stdout && length $drisee_stdout > 0 ) { $drisee_stdout = $file_in."."."drisee_stdout.txt" };
unless ( defined $data_log  && length $data_log > 0 )          { $data_log = "DRISEE_data_log.txt" };
unless ( defined $command_log && length $command_log > 0 )     { $command_log = "DRISEE_command_log.txt" };

# create a cummulative log of the data - add header if the file does not exist
unless (-e $data_log){ 
  open(DATA_LOG, ">", $data_log) or die "\n\n"."can't open DATA_LOG $data_log"."\n\n";
			    
  # print a header
  print DATA_LOG (
		  "# This is a cummulative summary log of the data that process_DRISEE2.pl has produced."."\n".
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
		  "Non-contam-DRISEE_score"."\n"
		 );
  close (DATA_LOG);
  }

# create a log for the DRISEE commands that the script issues
unless ( -e $command_log ){
  open(COMMAND_LOG, ">", $command_log) or die "\n\n"."can't open COMMAND_LOG $command_log"."\n\n";			    
  # print a header
  print COMMAND_LOG "# This is a log of the system commands that process_DRISEE2.p has produced."."\n";		    
  close (COMMAND_LOG);
}


my $system_command = (
		      $drisee_path.
		      " -t ".$file_type.
		      " -l ".$drisee_log.
		      " --percent -v".
		      " -p ".$num_proc.
		      " ".$file_in.
		      " ".$stat_file.
		      " > ".$drisee_stdout
		     );
open(COMMAND_LOG, ">>", $command_log) or die "\n\n"."can't RE-open COMMAND_LOG $command_log"."\n\n";
print COMMAND_LOG "DRISEE_command:"."\n".$system_command."\n"."\n";
close(COMMAND_LOG);
# system($system_command);



my @summary_values = ($file_in); # array

open(DRISEE_STDOUT, "<", $drisee_stdout) or die "\n\n"."can't open DRISEE_STDOUT $drisee_stdout"."\n\n";
while (my $line = <DRISEE_STDOUT>){
    chomp $line;
    if($debug){ print STDOUT "\n"."line: ".$line; }
    if ($line =~ m/^V||^bp||^se||^av||^st||^le||^In||^Pr||^Dr||^Con||^Dr/){ # skip comment lines
      chomp $line;
      my @line_array = split("\t", $line);
      my $array_value = $line_array[1];
      if($debug){ print STDOUT "value: ".$array_value."\n";}
      push (@summary_values, $array_value);
    }
  }
	
my $summary_line = join("\t", @summary_values);

open(DATA_LOG, ">>", $data_log) or die "\n\n"."can't RE-open DATA_LOG $data_log"."\n\n";
print DATA_LOG $summary_line."\n";
close(DATA_LOG);

# python ~/DRISEE/drisee.py -t fastq -l v1p5_mgm4473069_log --percent -v mgm4473069.fq mgm4473069.v1p5.STAT> v1.5_mgm4473069_stdout



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
Is designed to run on on dataset at a time, but write consecutive outputs 
to two summary files -- one with a summary of the data, the other with 
a summary of the DRISEE commands issued to the system.

OPTIONS:

    -p|drisee_path       (string)  location of the version of DRISEE   default: $drisee_path
    -f|file_in           (string)  sequence file in                    no default
    -t|file_type         (string)  fasta or fastq                      default: $file_type
    -n|num_proc          (int)     num parallel processes              default: $num_proc
    -s|stat_file         (string)  drisee_stats file                   default: file_in.drisee_STAT.txt
    -l|drisee_log        (string)  drisee_log                          default: file_in.drisee_log.txt
    -o|drisee_stdout     (string)  drisee_stdout                       default: file_in.drisee_stdout.txt
    -c|data_log          (string)  cummulative summary log             default: $data_log
    -b|command_log       (string)  cummulative commands log            default: $command_log
________________________________________________________________________________________
		   
    -h|help              (flag)    display help for this script
    -d|debug		 (flag)    run the script in debug mode


);
  exit 1;
}
