#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Data::Dumper;
use Getopt::Long;

use AWE::Workflow; # includes Shock::Client
use AWE::Client;


my $verbose    = 0 ;
my $debug      = 0 ;
my $shock_node = "edc3f835-e04b-4d5d-81d3-0928fb2c9188" ;
my $dbfile     = "b3411bbd-3603-4add-8e54-f7cee078a0b6" ;

my $shock_host  = "http://shock.metagenomics.anl.gov/" ;
my $awe_host    = "http://140.221.67.82:8001" ;
my $clientgroup = "starlord" ;
my $token       = undef ;
my $date        = `date` ; chomp $date ;
my $myJobName   = $date ;
my $date        = $date ;  

GetOptions ( 
	"node_url=s"   => \$shock_node ,
	'shock_host=s' => \$shock_host ,
	'awe_host=s'   => \$awe_host ,
	'verbose+'     => \$verbose ,
	'debug+'   	  => \$debug   ,
	'job_name=s'   => \$myJobName ,
	);

my $config = {
		aweserverurl	=> ( $awe_host    || $ENV{'AWE_SERVER_URL'} ),
		shockurl		=> ( $shock_host  || $ENV{'SHOCK_SERVER_URL'}),
		clientgroup		=> ( $clientgroup || $ENV{'AWE_CLIENT_GROUP'}),
		shocktoken		=> ( $token       || $ENV{'KB_AUTH_TOKEN'}) ,
	};
	
	

print join "\t" , "AWE URL:" , $config->{aweserverurl} , "\n" ;
 


# my $cap = new CAP('clientgroup' => "docker", "aweserverurl" => "http://140.221.67.149:8001/");


my $workflow = new AWE::Workflow(
	"pipeline"=> "M5NR Mapping",
	"name"=> "ARDB",
	"project"=> "ARDB",
	"user"=> "wilke",
	"clientgroups"=> $config->{clientgroup} ,
	"noretry"=> JSON::true,
	"shockhost" =>  $config->{shockurl}   || (die "No Host\n"), # default shock server for output files
	"shocktoken" => $config->{shocktoken} || (die "No token!\n"),
);



my $usrattributes = {
	"task"		=> "M5NR/Mapping.sims2annotation.default",
	"pipeline"	=> "M5NR Mapping",
	"name"      => $myJobName ,
	"date"      => $date,
};

# Create tasks

my $task1 = $workflow->newTask('M5NR/Mapping.sims2annotation.default',
								shock_resource( $config->{shockurl} , $shock_node ) ,
								shock_resource( $config->{shockurl} , $dbfile ) ,
								string_resource( 'ARDB')
								);
						
$task1->userattr( %$usrattributes );



my $task2 = $workflow->newTask('M5NR/Mapping.splitBySource.default',
								task_resource($task1->taskid() , 0) ,
								string_resource('ARDB_')
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

print "Job ID =  $job_id \n";   		 	  	  	  	  	  	  	









package ARDB ;

use strict ;
use warnings;

sub new{
	my ($class, %h) = @_;
	
	my $self = {
		aweserverurl	=> $ENV{'AWE_SERVER_URL'},
		shockurl		=> $ENV{'SHOCK_SERVER_URL'},
		clientgroup		=> $ENV{'AWE_CLIENT_GROUP'},
		shocktoken		=> $ENV{'KB_AUTH_TOKEN'}
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
