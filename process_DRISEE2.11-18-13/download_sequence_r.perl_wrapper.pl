#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

# Default for variables
my $scripts_path = "/home/ubuntu/matR-apps/process_DRISEE2.11-18-13";
my $mgrast_key = "NULL";
my $drisee_path = "/home/ubuntu/DRISEE/drisee.py";
my $download_log = "download_log.txt";
my $mgid;
my($help, $debug);

# check input args and display usage if not suitable
# if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }
if ( $ARGV[0] =~ /-h/ ) { &usage(); }

unless ( @ARGV > 0 || $mgid ) { &usage(); }
unless ( @ARGV > 0 ) { &usage(); }

if ( ! GetOptions (
		   "r|scripts_path=s"  => \$scripts_path,
		   "m|mgrast_key=s"    => \$mgrast_key,
		   "p|drisee_path=s"   => \$drisee_path,
		   "i|mgid=s"          => \$mgid,
		   "a|download_log=s"  => \$download_log,
		   "h|help!"           => \$help,
		   "d|debug!"          => \$debug
		  )
   ) { &usage(); }


if ( $download_log eq "download_log.txt" ){$download_log = $mgid."."."download_log.txt" };

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

system(qq(echo '$r_cmd' | R --vanilla --slave --silent));

# SUBS
sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

USAGE:


DESCRIPTION:
This is a perl wrapper for download_sequence.r.
This will take an mgrastid ("mgm" prefixed) and return the raw, unzipped
sequence file. The sequence file will be named mgid.type where mgid is the
mg-rast id for the sample, and type is the type of sequence file (fasta or 
fastq).  This can be used on public data without a key (mgrast_key = "NULL"),
or with a key to get private data.

OPTIONS:

    -i|mgid              (string)  mgid of sample                      no default
  
    -r|scripts_path      (string)  path of R scripts                   default: $scripts_path
    -m|mgrast_key        (string)  mgrast key                          default: $mgrast_key
    -a|download_log      (string)  cummulative log of the downloads    default: mgid.download_log.txt
________________________________________________________________________________________
		   
    -h|help              (flag)    display help for this script
    -d|debug		 (flag)    run the script in debug mode

);
  exit 1;
}
