#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use JSON;
use Cwd;


my $json = new JSON ;
my($mgid_list, $output_filename, $verbose, $debug, $help);

my $current_dir = getcwd()."/";
#if($debug) { print STDOUT "current_dir: "."\t".$current_dir."\n";}

#define defaults for variables that need them
my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
chomp $time_stamp;
# date +%m-%d-%y_%H:%M:%S:%N month-day-year_hour:min:sec:nanosec

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $mgid_list ) { &usage(); }

if ( ! GetOptions (
		   "m|mgid_list=s"       => \$mgid_list,
		   "o|output_filename=s" => \$output_filename,
		   "v|verbose!"          => \$verbose,
		   "h|help!"             => \$help,
		   "d|debug!"            => \$debug
		  )
   ) { &usage(); }

if ( $help ){ &usage(); }

unless( $output_filename ){ $output_filename =  $current_dir.$mgid_list.".SHOCK_ids.txt"; }

open(FILE_IN, "<", $current_dir."/".$mgid_list) or die "Couldn't open FILE_IN $mgid_list"."\n";

open(FILE_OUT, ">", $output_filename) or die "Couldn't open FILE_OUT $output_filename"."\n";
print FILE_OUT "# mgid"."\t"."protein.sims node_id"."\n";


# go through list of mgids, and get SHOCK ids for sims file

while (my $mgid = <FILE_IN>){
  chomp $mgid;
    
  my $api_call = "http://api.metagenomics.anl.gov/download/".$mgid;
  if($debug){ print "\n"."API CALL: ".$api_call."\n"; }
  
  my $return = `curl $api_call`;
  
  my $hash = $json->decode($return) ;
  #print Dumper $hash ;

  while( my( $key, $value ) = each %$hash ){
    print "$key: $value\n";
  }

  foreach my $entry (@{$hash->{data}}){
    print $entry->{stage_name} , "\n" ;

    if ($entry->{stage_name} eq "protein.sims"){

      #print  join "\t" , "Found:" , $entry->{node_id} , "\n";
      
      print FILE_OUT $mgid."\t".$entry->{node_id}."\n";
      #exit;
    }

  }



  #exit ;

  #while( my( $key, $value ) = each %$hash->{'data'} ){ 
  #  while( my( $kkey, $vvalue ) = each %$value){
  #    print "$kkey: $vvalue\n";
  #  }
  #}

  #for my $key (keys %$hash) {
  #  print "$key\t$hash{$key}\n";
  #}


   #for my $key ( keys $hash ) {
   #     my $value = %$hash{$key};
   #     print "$key => $value\n";
   # }
  
  #print $hash->{ 'data' } { 'stage_name' }


  }
  


sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $time_stamp
script:               $0

DESCRIPTION:
This script gets the SHOCK ids for the sims file associated with 
a list of mg-rast ids. 
   
USAGE:
    -m or --mgid_list        (string)  no default
                                   single column list of mgids
    -o or --output_filename  (string)  default = appends suffix onto mgid_list
                                    path that containts the data file
    -----------------------------------------------------------------------------------------------
    -h or --help             (flag)       see the help/usage
    -v or --verbose          (flag)       run in verbose mode
    -d or --debug            (flag)       run in debug mode

);
  exit 1;
}
