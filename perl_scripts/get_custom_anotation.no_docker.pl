#!/usr/bin/env perl
use strict;
use warnings;

use JSON;
use Data::Dumper;
use Getopt::Long;
use LWP::UserAgent ;
use HTTP::Request::Common;
#use Cwd;

use AWE::Workflow; # includes Shock::Client
use AWE::Client;



my($mgid_list, $verbose, $debug, $help);



# my $workflow_name = "KODB"; #? what is this
# my $project_name = "KODB_test"; #? what is this


#my $shock_node = undef; # replaced by $sims_nodeID
#my $dbfile     = "7ae17089-16cc-4ae1-ac43-ad1ece344d87" ; # vita_db.berkeleyDB
#my $dbfile     = "f755bf50-4405-476e-a035-3a666da8665a"; # second version with KODB as source
#my $dbfile     = "b3411bbd-3603-4add-8e54-f7cee078a0b6" ; # Andi's test db
my $dbfile        = "fa863953-764b-4386-9f8d-1c49ab6e9775"; # Osterman.BerkeleyDB  

#my $awe_host    = "http://10.1.16.74:8001" ; # try the local ip
my $shock_host    = "http://shock.metagenomics.anl.gov/" ;

my $awe_host      = "http://140.221.67.82:8001" ;
my $clientgroup   = "kevin_starlord" ;
my $token         = $ENV{'KB_AUTH_TOKEN'};
my $date          = `date` ; chomp $date ;
my $myJobName     = "Custom_Annotation::".$date;
my $user          = "thulsadoon" ;
my $project       = "kevin.test_re-annotation"; #undef ;
my $pipeline      = "pipe-dream"
my $workflow_name = "KODB";
#my $file         = undef ; # use a list of shock nodes (for sims files) ;
my $logfile       = "kevin_annotation.log";

#my $current_dir = getcwd()."/";

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); exit 0; }

if ( ! GetOptions (
		   "m|mgid_list=s"       => \$mgid_list,
		   #"o|output_filename=s" => \$output_filename,
		   #"n|node_url=s"        => \$shock_sims_node ,
		   "b|dbfile"            => \$dbfile,
		   "s|shock_host=s"      => \$shock_host ,
		   "a|awe_host=s"        => \$awe_host ,
		   "j|job_name=s"        => \$myJobName ,
		   "u|user=s"            => \$user,
		   "p|project=s"         => \$project,
		   #'node_id=s'    => \$shock_node, # replaced by $sims_nodeID in loop
		   #'f|file=s'     => \$file,
		   "l|logfile=s"         => \$logfile,
		   "h|help!"             => \$help,
		   "v|verbose!"          => \$verbose,
		   "d|debug!"            => \$debug
		  )
   ) { &usage(); exit 1; }

# config variables
# my $config = {
# aweserverurl
# => ( $awe_host    || $ENV{'AWE_SERVER_URL'} ),
# shockurl
# => ( $shock_host  || $ENV{'SHOCK_SERVER_URL'}),
# clientgroup
# => ( $clientgroup || $ENV{'AWE_CLIENT_GROUP'}),
# shocktoken
# => ( $token       || $ENV{'KB_AUTH_TOKEN'}) ,
# user
# =>   $user ,
# project         => ( $project || 'undef' ) ,
# workflow_name   => 'KODB' , # Changed from Andi's ARDB
# };

unless( $mgid_list ){ &usage(); exit 1; }

################################################################################################
### START MAIN
################################################################################################

# empty list of input node ids for workflow
my $nodes = undef ;

  # fill list
  #if ($project){
    #$nodes = &list_of_ids($project);
$nodes = &nodes_from_mgid_list($mgid_list, $logfile);
 #}
  # elsif ($file and -f $file){
  #   open(FILE , $file) or die "Can't open FILE $file \n!";
  #   while(my $id = <FILE>){
  #     chomp $id ;
  #     push @$nodes , $id ;
  #   }
  #   close(FILE);
  # }
  # else{
  #   $nodes = [ $shock_node ] ;
  # }

# print STDERR "Submitting:\n";
# print STDERR Dumper $nodes ;

# # init KODB object with config
# my $ardb =  KODB->new(%$config);

# # init workflow
# foreach my $node_id (@$nodes){
#   $ardb->init_workflow() ;
#   unless ($ardb->workflow) {
#     print STDERR "Error, can't find workflow object.\n" ;
#     exit;
#   }

#   # Create steps for list of input IDs
#   $ardb->create([$node_id]);
### ($self, $nodes, $pipeline, $myJobName, $project, $user, $clientgroup )

#   # subit workflow ;
#   $ardb->submit;



exit;
################################################################################################
### END MAIN
################################################################################################
 
################################################################################################
### SUB usage
################################################################################################
sub usage {
  my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;
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

    -u or --user             (string)   default = $user

    -p or --project          (string)   default = $project

    -----------------------------------------------------------------------------------------------
    -h or --help             (flag)     see the help/usage
    -v or --verbose          (flag)     run in verbose mode
    -d or --debug            (flag)     run in debug mode

);
  exit 1;
}
################################################################################################

################################################################################################
### SUB get_sims_nodeID
################################################################################################
sub get_sims_nodeID{
    
  my $api_call = "http://api.metagenomics.anl.gov/download/".$_[0];
  print "\n"."API CALL: ".$api_call."\n";
  
  my $return = `curl $api_call`;
  
  my $json        = new JSON ;

  my $hash = $json->decode( $return ) ;
  #print Dumper $hash ;
  
  while( my( $key, $value ) = each %$hash ){
    print "$key: $value\n";
  }

  foreach my $entry (@{$hash->{data}}){
    print $entry->{stage_name} , "\n" ;
    
    if ($entry->{stage_name} eq "protein.sims"){
      
      print  join "\t" , "Found:" , $entry->{node_id} , "\n";
      
      return $entry->{node_id};
      #exit;
    }
    
  }
  
}
################################################################################################

################################################################################################
### SUB get nodes from input list of mg-rast ids
################################################################################################

# open list of mgrast ids

sub nodes_from_mgid_list{

  my ( $file_in, $log ) =@_;

  my $node_list = [];

  open(FILE_IN, "<", $file_in) or die "Couldn't open FILE_IN $file_in"."\n";
  open(FILE_OUT, ">", $log) or die "Could not open FILE_OUT $log";
  print FILE_OUT "mgIDs"."\t"."simsIDs"."\n";

  # outer loop gets the shock node id from the mgrastid
  while (my $mgid = <FILE_IN>){
    chomp $mgid;
    my $sims_nodeID = &get_sims_nodeID($mgid);
  
    print FILE_OUT $mgid."\t".$sims_nodeID."\n";
		   
    push @$node_list , $sims_nodeID;

  }
  
  return $node_list

}
################################################################################################
  
###################################################################################
### SUB get list of shock nodes for all metagenomes within project
###################################################################################
# sub list_of_ids {
#   my ($project) = @_ ;

#   my $ua          = LWP::UserAgent->new('HMP Download');
#   my $json        = new JSON ;
#   my $base        = 'http://api.metagenomics.anl.gov';
#   my $verbose = 1;
#   my $id_logfile = "submission.log";

#   my $list        = [];


#   open(ID_LOG , ">", $id_logfile) or die "Can't open $logfile for writing!\n";
#   print ID_LOG "Retrieving project from ".$base."/project/".$project."?verbosity=full\n" if ($verbose);

#   # Project URL
#   my $get = $ua->get($base."/project/".$project."?verbosity=full");

#   # check response status
#   unless ( $get->is_success ) {
#     print ID_LOG join "\t", "ERROR:", $get->code, $get->status_line;
#     exit 1;
#   }


#   # decode response
#   my $res         = $json->decode( $get->content );
#   my $mglist      = $res->{metagenomes} ;

#   # print STDERR $mglist, "\n";
#   print LOG "Searching for sims file\n" if ($verbose) ;

#   foreach my $tuple ( @$mglist ) {
#     # url for all genome features
#     my $mg = $tuple->[0] ;
#     print LOG "Checking download url ". $base."/download/$mg\n";

#     my $get = $ua->get($base."/download/$mg");

#     # check response status
#     unless ( $get->is_success ) {
# 	print LOG join "\t", "ERROR:", $get->code, $get->status_line;
# 	exit 1;
#     }

#     my $res = $json->decode( $get->content );

#     my $download = undef ;
#     my $dstage   = undef ;

#     foreach my $stage ( @{$res->{data} } ) {
# 	if ($stage->{stage_name} eq "protein.sims"){
# 	  $download = $stage->{url}; # use shock curl http://shock.metagenomics.anl.gov/node/caab6ef9-8087-4337-a217-54f8e9e40e7a
# 	  $dstage   = $stage;
# 	  print LOG join "\t" , $dstage->{stage_name} , $dstage->{file_name} , $dstage->{file_format} , $dstage->{node_id} , "\n"  if(defined $dstage);

# 	  print LOG Dumper $stage ;
# 	  push @$list , $stage->{node_id}
# 	}

#     }
#   }    
#   return $list;           
# };
###################################################################################



# Workflow specific functions
package KODB ;

use strict ;
use warnings;
use Data::Dumper;

use AWE::Workflow; # includes Shock::Client
use AWE::Client;


###################################################################################
### SUB new
###################################################################################
# sub new{
#   my ($class, %h) = @_;
#   my $self = { config => {
# 			    aweserverurl
# 			    => $ENV{'AWE_SERVER_URL'},
# 			    shockurl
# 			    => $ENV{'SHOCK_SERVER_URL'},
# 			    clientgroup
# 			    => $ENV{'AWE_CLIENT_GROUP'},
# 			    shocktoken
# 			    => $ENV{'KB_AUTH_TOKEN'},
# 			   }
# 	       };
#   foreach my $key ('aweserverurl', 'shockurl', 'clientgroup', 'shocktoken') {
#     if (defined($h{$key}) && $h{$key} ne '') {
# 	$self->{config}->{$key} = $h{$key};
#     }
#     unless (defined $self->{config}->{$key} ) {
# 	die "variable $key not defined";
#     }
#   }
#   # set all keys
#   foreach my $key ( keys %h) {
#     if (defined($h{$key}) && $h{$key} ne '') {
# 	$self->{config}->{$key} = $h{$key};
#     }
#   }
#   bless $self, $class;
#   return $self;
# };
###################################################################################

###################################################################################
### SUB config
###################################################################################
sub config{
  my ($self , %config) = @_ ;
  if(%config){
    foreach my $key (keys %config){
      $self->{config}->{$key} = $config{$key} ;
    }
  }
  return $self->{config} ;
}; 
# create and initialize new workflow object
sub init_workflow{
  my ($self , %new_config) = @_;
  my $config = $self->config ;
  # overwrite config with new settings
  if(keys %new_config){
    map { $config->{$_} = $new_config{$_} } keys %new_config ;
  }
  my $workflow = new AWE::Workflow(
				   "pipeline"=> ( $config->{pipeline}      
						  || "M5NR Mapping" ),
				   "name"    => ( $config->{workflow_name} || "KODB" ),
				   "project" => ( $config->{project} || "KODB" ),
				   "user"    => ( $config->{user} || (die "No user!\n") ) ,
				   "clientgroups" => $config->{clientgroup} ,
				   "noretry"      => JSON::true,
				   "shockhost"    => $config->{shockurl}   || (die "No Host\n"), # default shock server for output files
				   "shocktoken"   => $config->{shocktoken} || (die "No token!\n"),
				  );
  $self->{workflow} = $workflow ;
  return $self->{workflow} ;
};
###################################################################################

###################################################################################
### SUB  return workflow object
sub workflow {
  my ($self , $wf) = @_ ;
  
  if($wf and ref $wf){
    $self->{workflow} = $wf ;
  }
  
  unless(defined $self->{workflow} and ref $self->{workflow}){
    print STDERR "No workflow object defined in KODB->workflow!\n" ;
  }
  
  return $self->{workflow} ;
};
###################################################################################

###################################################################################
### SUB submit workflow
###################################################################################
sub submit{
  my ($self) = @_;
  my $config = $self->config ;
  my $workflow = $self->workflow;
  my $awe = new AWE::Client($awe_host,$config->{shocktoken}, 
			    $config->{shocktoken}, $debug); # second token is for AWE
  
  unless (defined $awe) {
    print STDERR "Could not initialize AWE Client!\n" ;
    die;
  }
  
  $awe->checkClientGroup( $config->{clientgroup} )  == 0 || die 
    "no clients in clientgroup found, " . $config->{clientgroup} . " (AWE server: ". $config->{aweserverurl} .")" ;
  
  
  
  print STDERR "submit job to AWE server...\n";
  my $json = JSON->new;
  my $submission_result = $awe->submit_job('json_data' => $json->encode($workflow->getHash()));
  unless (defined $submission_result) {
    die "error: submission_result is not defined";
  }
  unless (defined $submission_result->{'data'}) {
    print STDERR Dumper($submission_result);
    exit(1);
  }
  my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";
  print "result from AWE server:\n".$json->pretty->encode( $submission_result )."\n";
  print "Job ID = $job_id\n";   
  $self->{submission}->{job} = $job_id ;
  $self->{submission}->{document} = $submission_result ;
  return $job_id ;
}; 
###################################################################################

################################################################################################
### SUB new
################################################################################################
sub new {
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
################################################################################################

###################################################################################
### SUB create (workflow)
###################################################################################

# create task list for set of input IDs
# list of tasks is identical for every input ID     # is every ID for a sims file?
sub create{

  my ($self, $node, $pipeline, $myJobName, $project, $user, $clientgroup ) = @_ ;
  foreach my $shock_node (@$nodes){
    print STDERR "Creating task list for $shock_node\n" ;
    my $config   = $self->config ;
    my $workflow = $self->workflow;
    print $config , "\n" ;
    print $config->{shockurl} , "\n" ;
    print Dumper $config;
    #exit;
    
    # my $usrattributes = {
    # 			 "task"
    # 			 => "M5NR/Mapping.sims2annotation.default",
    # 			 "pipeline"
    # 			 => "M5NR Mapping",
    # 			 "name"      => $myJobName ,
    # 			 "date"      => $date,
    # 			};
    
    # # Create tasks
    
    Do the workflow for each metagenome -- make name mgrast id


    my $workflow = new AWE::Workflow(
				     "pipeline"=> $pipeline,
				     "name"=> $myJobName,
				     "project"=> $project,
				     "user"=> $user,
				     "clientgroups"=> $clientgroup,
				     "noretry"=> JSON::true
				    );

    for i in nodes

    my $newtask = $workflow->addTask(new AWE::Task());
    $newtask->command('perl ~/scripts/perl/sims2annotation.batch.pl -sims ${SIMS} -dbfile ${DBFILE} -source ${SOURCE} -verbose 1 1> ${SIMS}.mapped 2> error.log')
    



		
		$newtask->command('AMETHST.pl -f @'.$input_filename.' -z --all_name '.$analysis_filename);
		
		
		
				
		# define and add input nodes to the task
		foreach my $filename (keys(%$used_files)) {
			my $node = $used_files->{$filename};
			$newtask->addInput(new AWE::TaskInput('node' => $node,	'host' => $self->shockurl, 'filename' => $filename));
		}
		$newtask->addInput(new AWE::TaskInput('data' => \$pair_file, 'filename' => $input_filename));

		
		# define and add output nodes to the task; return value is a reference that can be used to create an input node for the next task
		my $output_reference = $newtask->addOutput(new AWE::TaskOutput($analysis_filename, $self->shockurl));
		push (@summary_inputs, new AWE::TaskInput('reference' => $output_reference));



    
    # my $task1 = $workflow->newTask('M5NR/Mapping.sims2annotation.default',
    # 				   shock_resource( $config->{shockurl} , $shock_node ) ,
    # 				   shock_resource( $config->{shockurl} , $dbfile ) ,
    # 				   string_resource( 'KODB')
    # 				  );
    # $task1->userattr( %$usrattributes );
    
    
    
    # my $task2 = $workflow->newTask('M5NR/Mapping.splitBySource.default',
    # 				   task_resource($task1->taskid() , 0) ,
    # 				   string_resource('KODB_')
    # 				  );
    
    # $task2->userattr( %$usrattributes );
    
    # my $task3 = $workflow->newTask('M5NR/Mapping.sims2hits.default',
    # 				   task_resource($task2->taskid() , 0)
    # 				  );
    
    # $task3->userattr( %$usrattributes );
    
    # my $task4 = $workflow->newTask('M5NR/Mapping.hits2summary.md5',
    # 				   task_resource($task3->taskid() , 0)
    # 				  );  
    
    # $task4->userattr( %$usrattributes );
    
    # my $task5 = $workflow->newTask('M5NR/Mapping.hits2summary.function',
    # 				   task_resource($task3->taskid() , 0)
    # 				  );  
    
    # $task5->userattr( %$usrattributes );
    # my $task6 = $workflow->newTask('M5NR/Mapping.hits2summary.organism',
    # 				   task_resource($task3->taskid() , 0)
    # 				  );  
    
    # $task6->userattr( %$usrattributes );
    
  }
};


1;
################################################################################################





