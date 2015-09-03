#!/usr/bin/env perl

# adapted from get_shock_id_from_mgid.pl
# and Andi's code for the annotation service

use strict;
use warnings;
use JSON;
use Data::Dumper;
use Getopt::Long;
use AWE::Workflow; # includes Shock::Client
use AWE::Client;
use Cwd;


my $json = new JSON ;
#my($mgid_list, $output_filename, $verbose, $debug, $help);
my($mgid_list, $verbose, $debug, $help);

#my $verbose    = 0 ;
#my $debug      = 0 ;
#my $shock_sims_node = "edc3f835-e04b-4d5d-81d3-0928fb2c9188" ;
#my $dbfile     = "f755bf50-4405-476e-a035-3a666da8665a" ; # vita_db.berkeleyDB
my $dbfile     = "fa863953-764b-4386-9f8d-1c49ab6e9775"; # Osterman.BerkeleyDB  
my $shock_host  = "http://shock.metagenomics.anl.gov/" ;
#my $awe_host    = "http://140.221.67.82" ;
my $awe_host    = "http://140.221.67.82:8001" ;
#my $awe_host    = "http://10.1.16.74:8001" ; # try the local ip
my $clientgroup = "kevin_starlord" ;
my $workflow_name = "KODB";
my $project_name = "KODB_test";
my $token       = undef ;
my $date        = `date` ; chomp $date;
my $myJobName   = "Custom_Annotation::".$date;
#my $date        = $date ; 



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
		   #"o|output_filename=s" => \$output_filename,
		   #"n|node_url=s"        => \$shock_sims_node ,
		   "b|dbfile"            => \$dbfile,
		   "s|shock_host=s"      => \$shock_host ,
		   "a|awe_host=s"        => \$awe_host ,
		   "j|job_name=s"        => \$myJobName ,
		   "v|verbose!"          => \$verbose,
		   "h|help!"             => \$help,
		   "debug!"              => \$debug
		  )
   ) { &usage(); }

if ( $help ){ &usage(); }

my $config = {
aweserverurl
=> ( $awe_host    || $ENV{'AWE_SERVER_URL'} ),
shockurl
=> ( $shock_host  || $ENV{'SHOCK_SERVER_URL'}),
clientgroup
=> ( $clientgroup || $ENV{'AWE_CLIENT_GROUP'}),
shocktoken
=> ( $token       || $ENV{'KB_AUTH_TOKEN'}) ,
};

print join "\t" , "AWE URL:" , $config->{aweserverurl} , "\n" ;


#unless( $output_filename ){ $output_filename =  $current_dir.$mgid_list.".SHOCK_ids.txt"; }

open(FILE_IN, "<", $current_dir."/".$mgid_list) or die "Couldn't open FILE_IN $mgid_list"."\n";

#open(FILE_OUT, ">", $output_filename) or die "Couldn't open FILE_OUT $output_filename"."\n";
#print FILE_OUT "# mgid"."\t"."protein.sims node_id"."\n";


# create workflow
if( $debug ){ print "\nStart to create workflow\n"; }
my $workflow = new AWE::Workflow(
				 "pipeline"=> "M5NR Mapping",
				 "name"=> $workflow_name,
				 "project"=> $project_name,
				 #"user"=> "wilke",
				 "user"=> "thulsadoon",
				 "clientgroups"=> $config->{clientgroup} ,
				 "noretry"=> JSON::true,
				 "shockhost" =>  $config->{shockurl}   || (die "No Host\n"), # default shock server for output files
				 "shocktoken" => $config->{shocktoken} || (die "No token!\n"),
);
if( $debug ){ print "\nWorkflow created\n"; }


# create user attributes
my $usrattributes = {
		     "task"
		     #=> "M5NR/Mapping.sims2annotation.default",
		     => "m5nr/Mapping.sims2annotation.default",
		     "pipeline"
		     => "M5NR Mapping",
		     "name"      => $myJobName ,
		     "date"      => $date,
		    };


# go through list of mgids, and get SHOCK ids for sims file
# Then run the workflow on the corresponding sims file
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
      if($debug){print STDERR "MG-RAST_id:".$mgid."\t"."SHOCK_id: ".$entry->{node_id}."\n";}
      
      # get the node id for the sims file 
      my $shock_sims_node = $entry->{node_id};
      
      # Create tasks
      my $task1 = $workflow->newTask('M5NR/Mapping.sims2annotation.default',
				     shock_resource( $config->{shockurl} , $shock_sims_node ) ,
				     shock_resource( $config->{shockurl} , $dbfile ) ,
				     string_resource( 'KODB')
				    );
      
      $task1->userattr( %$usrattributes );
      


      my $task2 = $workflow->newTask('M5NR/Mapping.splitBySource.default',
				     task_resource($task1->taskid() , 0) ,
				     string_resource('KODB_')
				    );
      
      $task2->userattr( %$usrattributes );
      
      my $task3 = $workflow->newTask('M5NR/Mapping.sims2hits.default',
				     task_resource($task2->taskid() , 0)
				    );
      
      $task3->userattr( %$usrattributes );
      
      my $task4 = $workflow->newTask('M5NR/Mapping.hits2summary.md5',
				     task_resource($task3->taskid() , 0)
				    );  


      $task4->userattr( %$usrattributes );

      my $task5 = $workflow->newTask('M5NR/Mapping.hits2summary.function',
				     task_resource($task3->taskid() , 0)
				    );  
      
      $task5->userattr( %$usrattributes );
      my $task6 = $workflow->newTask('M5NR/Mapping.hits2summary.organism',
				     task_resource($task3->taskid() , 0)
				    );  
      
      $task6->userattr( %$usrattributes );
      
      my $awe = new AWE::Client($awe_host, $config->{shocktoken}, $config->{shocktoken}, $debug); # second token is for AWE
      
      unless (defined $awe) {
	print STDERR "Could not initialize AWE Client!\n" ;
	die;
      }

      $awe->checkClientGroup( $config->{clientgroup} )  == 0 || die 
	"no clients in clientgroup found, " . $config->{clientgroup} . " (AWE server: ". $config->{aweserverurl} .")" ;

      print "submit job to AWE server...\n";
      my $json_2 = JSON->new;
      my $submission_result = $awe->submit_job('json_data' => $json_2->encode($workflow->getHash()));
      unless (defined $submission_result) {
	die "error: submission_result is not defined";
      }
      unless (defined $submission_result->{'data'}) {
	print STDERR Dumper($submission_result);
	exit(1);
      }
      my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";
      print "result from AWE server:\n".$json_2->pretty->encode( $submission_result )."\n";
      
      print "Job ID =  $job_id \n";  

      # Note sure how this fits in
      ##package ARDB ;

      ##use strict ;
      ##use warnings;
      
      
      




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
# END MAIN
################################################################################################
  

################################################################################################
sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $time_stamp
script:               $0

DESCRIPTION:
This script gets performs reannotation of metagenomes specified in the 
mgid_list with the db indicated by the shock id dbfile. 
   
USAGE:
    -m or --mgid_list        (string)   no default
                                   single column list of mgids

    -b or --dbfile           (string)   default = $dbfile
                                   shock id of the berkley db file to use

    -s or --shock_host       (string)   default = $shock_host

    -a or --awe_host         (string)   default = $awe_host

    -j or --job_name         (string)   default = $myJobName

    -----------------------------------------------------------------------------------------------
    -h or --help             (flag)     see the help/usage
    -v or --verbose          (flag)     run in verbose mode
    -d or --debug            (flag)     run in debug mode

);
  exit 1;
}
################################################################################################


################################################################################################
sub new{
  my ($class, %h) = @_;
  my $self = {
	      aweserverurl
	      => $ENV{'AWE_SERVER_URL'},
	      shockurl
	      => $ENV{'SHOCK_SERVER_URL'},
	      clientgroup
	      => $ENV{'AWE_CLIENT_GROUP'},
	      shocktoken
	      => $ENV{'KB_AUTH_TOKEN'}
	     };
  foreach my $key ('aweserverurl', 'shockurl', 'clientgroup', 'shocktoken') {
    if (defined($h{$key}) && $h{$key} ne '') {
      $self->{$key} = $h{$key};
    }
    unless (defined $self->{$key} ) {
      die "variable $key not defined";
	  }
  }
  bless $self, $class;
  return $self;
};



sub config{}; 
      
1;
################################################################################################



################################################################################################
################################################################################################

#########





 

 


# my $cap = new CAP('clientgroup' => "docker", "aweserverurl" => "http://140.221.67.149:8001/");





   
   
 



 
   
   
   












################################################################################################
############ Andi's code from email 6-23-15
################################################################################################

# #!/usr/bin/env perl

# use strict;
# use warnings;

# use JSON;
# use Data::Dumper;
# use Getopt::Long;

# use AWE::Workflow; # includes Shock::Client
# use AWE::Client;


# my $verbose    = 0 ;
# my $debug      = 0 ;
# my $shock_sims_node = "edc3f835-e04b-4d5d-81d3-0928fb2c9188" ;
# my $dbfile     = "b3411bbd-3603-4add-8e54-f7cee078a0b6" ;

# my $shock_host  = "http://shock.metagenomics.anl.gov/" ;
# my $awe_host    = "http://140.221.67.82:8001" ;
# my $clientgroup = "starlord" ;
# my $token       = undef ;
# my $date        = `date` ; chomp $date ;
# my $myJobName   = $date ;
# my $date        = $date ;  

# GetOptions ( 
# "node_url=s"   => \$shock_sims_node ,
# 'shock_host=s' => \$shock_host ,
# 'awe_host=s'   => \$awe_host ,
# 'verbose+'     => \$verbose ,
# 'debug+'     => \$debug   ,
# 'job_name=s'   => \$myJobName ,
# );

# my $config = {
# aweserverurl
# => ( $awe_host    || $ENV{'AWE_SERVER_URL'} ),
# shockurl
# => ( $shock_host  || $ENV{'SHOCK_SERVER_URL'}),
# clientgroup
# => ( $clientgroup || $ENV{'AWE_CLIENT_GROUP'}),
# shocktoken
# => ( $token       || $ENV{'KB_AUTH_TOKEN'}) ,
# };

# print join "\t" , "AWE URL:" , $config->{aweserverurl} , "\n" ;
 


# # my $cap = new CAP('clientgroup' => "docker", "aweserverurl" => "http://140.221.67.149:8001/");


# my $workflow = new AWE::Workflow(
# "pipeline"=> "M5NR Mapping",
# "name"=> "ARDB",
# "project"=> "ARDB",
# "user"=> "wilke",
# "clientgroups"=> $config->{clientgroup} ,
# "noretry"=> JSON::true,
# "shockhost" =>  $config->{shockurl}   || (die "No Host\n"), # default shock server for output files
# "shocktoken" => $config->{shocktoken} || (die "No token!\n"),
# );



# my $usrattributes = {
# "task"
# => "M5NR/Mapping.sims2annotation.default",
# "pipeline"
# => "M5NR Mapping",
# "name"      => $myJobName ,
# "date"      => $date,
# };

# # Create tasks

# my $task1 = $workflow->newTask('M5NR/Mapping.sims2annotation.default',
# shock_resource( $config->{shockurl} , $shock_sims_node ) ,
# shock_resource( $config->{shockurl} , $dbfile ) ,
# string_resource( 'ARDB')
# );
# $task1->userattr( %$usrattributes );



# my $task2 = $workflow->newTask('M5NR/Mapping.splitBySource.default',
# task_resource($task1->taskid() , 0) ,
# string_resource('ARDB_')
# );

# $task2->userattr( %$usrattributes );

# my $task3 = $workflow->newTask('M5NR/Mapping.sims2hits.default',
# task_resource($task2->taskid() , 0)
# );

# $task3->userattr( %$usrattributes );

# my $task4 = $workflow->newTask('M5NR/Mapping.hits2summary.md5',
# task_resource($task3->taskid() , 0)
# );  
   
   
   
 


# $task4->userattr( %$usrattributes );


# my $task5 = $workflow->newTask('M5NR/Mapping.hits2summary.function',
# task_resource($task3->taskid() , 0)
# );  
   
   
   
 
# $task5->userattr( %$usrattributes );
# my $task6 = $workflow->newTask('M5NR/Mapping.hits2summary.organism',
# task_resource($task3->taskid() , 0)
# );  
   
   
   
 

# $task6->userattr( %$usrattributes );

# my $awe = new AWE::Client($awe_host, $config->{shocktoken}, $config->{shocktoken}, $debug); # second token is for AWE

# unless (defined $awe) {
# print STDERR "Could not initialize AWE Client!\n" ;
# die;
# }

# $awe->checkClientGroup( $config->{clientgroup} )  == 0 || die 
# "no clients in clientgroup found, " . $config->{clientgroup} . " (AWE server: ". $config->{aweserverurl} .")" ;



# print "submit job to AWE server...\n";
# my $json = JSON->new;
# my $submission_result = $awe->submit_job('json_data' => $json->encode($workflow->getHash()));
# unless (defined $submission_result) {
# die "error: submission_result is not defined";
# }
# unless (defined $submission_result->{'data'}) {
# print STDERR Dumper($submission_result);
# exit(1);
# }
# my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";
# print "result from AWE server:\n".$json->pretty->encode( $submission_result )."\n";

# print "Job ID =  $job_id \n";  
 
   
   
   









# package ARDB ;

# use strict ;
# use warnings;

# sub new{
# my ($class, %h) = @_;
# my $self = {
# aweserverurl
# => $ENV{'AWE_SERVER_URL'},
# shockurl
# => $ENV{'SHOCK_SERVER_URL'},
# clientgroup
# => $ENV{'AWE_CLIENT_GROUP'},
# shocktoken
# => $ENV{'KB_AUTH_TOKEN'}
# };
# foreach my $key ('aweserverurl', 'shockurl', 'clientgroup', 'shocktoken') {
# if (defined($h{$key}) && $h{$key} ne '') {
# $self->{$key} = $h{$key};
# }
# unless (defined $self->{$key} ) {
# die "variable $key not defined";
# }
# }
# bless $self, $class;
# return $self;
# };

# sub config{}; 

# 1;
