#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Data::Dumper;
use Getopt::Long;
use LWP::UserAgent ;
use HTTP::Request::Common;

use AWE::Workflow; # includes Shock::Client
use AWE::Client;

# use ARDB;

my $verbose    = 0 ;
my $debug      = 0 ;
my $shock_node = "edc3f835-e04b-4d5d-81d3-0928fb2c9188" ;
#my $dbfile     = "7ae17089-16cc-4ae1-ac43-ad1ece344d87" ; # vita_db.berkeleyDB
my $dbfile     = "b3411bbd-3603-4add-8e54-f7cee078a0b6" ; # Andi's test db

my $shock_host  = "http://shock.metagenomics.anl.gov/" ;
my $awe_host    = "http://140.221.67.82:8001" ;
my $clientgroup = "kevin_starlord" ;
my $token       = "un=thulsadoon|tokenid=0b33976a-3874-11e4-9fb3-12313b077182|expiry=1441839178|client_id=thulsadoon|token_type=Bearer|SigningSubject=https://nexus.api.globusonline.org/goauth/keys/aa346168-3523-11e4-928a-22000ab68755|sig=42bdee25bc51e4563d94244c458a1eb33e39363724c4511952fce14b17adc5591c3f475806969a5cb5acc11706b7230226dcfffc9adc2a5ea80cf31efe72a2a22659707e461e3ddcdc1a52453f109e7fde767979c89584a77490beb56882f887d087c605fe5880cb923111eec206be5c41dc04b1d4fba2ddeb764ab5772d3795";
my $date        = `date` ; chomp $date ;
my $myJobName   = $date ;
my $user        = 'thulsadoon' ;
my $project     = undef ;
my $file        = undef ; #"test.sim_shock_node_list.andi" ;


GetOptions ( 
	    "node_url=s"   => \$shock_node ,
	    'shock_host=s' => \$shock_host ,
	    'awe_host=s'   => \$awe_host ,
	    'verbose+'     => \$verbose ,
	    'debug+'       => \$debug   ,
	    'job_name=s'   => \$myJobName ,
	    'user=s'       => \$user,
	    'project=s'    => \$project,
	    'node_id=s'    => \$shock_node,
	    'dbnode=s'     => \$dbfile,
	    'file=s'       => \$file,
	   );

my $config = {
aweserverurl
=> ( $awe_host    || $ENV{'AWE_SERVER_URL'} ),
shockurl
=> ( $shock_host  || $ENV{'SHOCK_SERVER_URL'}),
clientgroup
=> ( $clientgroup || $ENV{'AWE_CLIENT_GROUP'}),
shocktoken
=> ( $token       || $ENV{'KB_AUTH_TOKEN'}) ,
user
=>   $user ,
project         => ( $project || 'undef' ) ,
workflow_name   => 'KODB' , # Kevin change this for your wf 
};




# empty list of input node ids for workflow
my $nodes = undef ;

# fill list
if ($project){
$nodes = &list_of_ids($project);
}
elsif ($file and -f $file){
open(FILE , $file) or die "Can't open file $file \n!";
while(my $id = <FILE>){
chomp $id ;
push @$nodes , $id ;
}
close(FILE);
}
else{
$nodes = [ $shock_node ] ;
}





print STDERR "Submitting:\n";
print STDERR Dumper $nodes ;



# init KODB object with config
my $ardb =  KODB->new(%$config);

# init workflow

foreach my $node_id (@$nodes){
$ardb->init_workflow() ;
unless ($ardb->workflow) {
print STDERR "Error, can't find workflow object.\n" ;
exit;
}


# Create steps for list of input IDs
$ardb->create([$node_id]);

# subit workflow ;
$ardb->submit;

}

exit; 
# get list of shock nodes for all metagenomes within project
sub list_of_ids {
my ($project) = @_ ;

my $ua          = LWP::UserAgent->new('HMP Download');
my $json        = new JSON ;
my $base        = 'http://api.metagenomics.anl.gov';
my $verbose = 1;
my $logfile = "submission.log";

my $list        = [];


open(LOG , ">$logfile") or die "Can't open $logfile for writing!\n";
print STDERR "Retrieving project from ".$base."/project/".$project."?verbosity=full\n" if ($verbose);

# Project URL
my $get = $ua->get($base."/project/".$project."?verbosity=full");

# check response status
unless ( $get->is_success ) {
       print STDERR join "\t", "ERROR:", $get->code, $get->status_line;
   exit 1;
}


# decode response
my $res         = $json->decode( $get->content );
my $mglist      = $res->{metagenomes} ;

# print STDERR $mglist, "\n";
print STDERR "Searching for sims file\n" if ($verbose) ;

foreach my $tuple ( @$mglist ) {
   # url for all genome features
   my $mg = $tuple->[0] ;
print STDERR "Checking download url ". $base."/download/$mg\n";

   my $get = $ua->get($base."/download/$mg");

   # check response status
unless ( $get->is_success ) {
print STDERR join "\t", "ERROR:", $get->code, $get->status_line;
       exit 1;
        }



        my $res = $json->decode( $get->content );

        my $download = undef ;
        my $dstage   = undef ;

        foreach my $stage ( @{$res->{data} } ) {
if ($stage->{stage_name} eq "protein.sims"){
$download = $stage->{url}; # use shock curl http://shock.metagenomics.anl.gov/node/caab6ef9-8087-4337-a217-54f8e9e40e7a
$dstage   = $stage;
print STDERR join "\t" , $dstage->{stage_name} , $dstage->{file_name} , $dstage->{file_format} , $dstage->{node_id} , "\n"  if(defined $dstage);
       
print STDERR Dumper $stage ;
push @$list , $stage->{node_id}
}

}
}    
return $list;           
};





# Workflow specific functions

package KODB ;

use strict ;
use warnings;
use Data::Dumper;

use AWE::Workflow; # includes Shock::Client
use AWE::Client;

sub new{
my ($class, %h) = @_;
my $self = { config => {
aweserverurl
=> $ENV{'AWE_SERVER_URL'},
shockurl
=> $ENV{'SHOCK_SERVER_URL'},
clientgroup
=> $ENV{'AWE_CLIENT_GROUP'},
shocktoken
=> $ENV{'KB_AUTH_TOKEN'},
}
};
foreach my $key ('aweserverurl', 'shockurl', 'clientgroup', 'shocktoken') {
if (defined($h{$key}) && $h{$key} ne '') {
$self->{config}->{$key} = $h{$key};
}
unless (defined $self->{config}->{$key} ) {
die "variable $key not defined";
}
}
# set all keys
foreach my $key ( keys %h) {
if (defined($h{$key}) && $h{$key} ne '') {
$self->{config}->{$key} = $h{$key};
}
}
bless $self, $class;
return $self;
};

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

# return workflow object
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

# submit workflow
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


# create task list for set of input IDs
# list of tasks is identical for every input ID
sub create{
my ($self , $nodes ) = @_ ;
foreach my $shock_node (@$nodes){
print STDERR "Creating task list for $shock_node\n" ;
my $config   = $self->config ;
my $workflow = $self->workflow;
print $config , "\n" ;
print $config->{shockurl} , "\n" ;
print Dumper $config;
#exit;
my $usrattributes = {
"task"
=> "M5NR/Mapping.sims2annotation.default",
"pipeline"
=> "M5NR Mapping",
"name"      => $myJobName ,
"date"      => $date,
};

# Create tasks

my $task1 = $workflow->newTask('M5NR/Mapping.sims2annotation.default',
shock_resource( $config->{shockurl} , $shock_node ) ,
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

}
};


1;
