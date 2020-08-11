################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: webwork2/lib/WeBWorK/ContentGenerator/renderViaXMLRPC.pm,v 1.1 2010/05/11 15:27:08 gage Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

WeBWorK::ContentGenerator::ProblemRenderer - renderViaXMLRPC is an HTML 
front end for calls to the xmlrpc webservice

=cut

use strict;
use warnings;

package WeBWorK::ContentGenerator::renderViaXMLRPC;
use base qw(WeBWorK::ContentGenerator);


#use XMLRPC::Lite;
#use MIME::Base64 qw( encode_base64 decode_base64);


use strict;
use warnings;
use WebworkClient;
use WeBWorK::Debug;
use CGI;
use JSON;
use Crypt::JWT qw( decode_jwt encode_jwt);
=head1 Description


#################################################
  renderViaXMLRPC -- a front end for the Webservice that accepts HTML forms

  receives WeBWorK problems presented as HTML forms,
  packages the form variables into an XML_RPC request
 suitable for the Webservice/RenderProblem.pm
 takes the answer returned by the webservice (which has HTML format) and 
 returns it to the browser.
#################################################

=cut
 
# To configure the target webwork server two URLs are required
# 1.  The url  http://test.webwork.maa.org/mod_xmlrpc
#    points to the Webservice.pm and Webservice/RenderProblem modules
#    Is used by the client to send the original XML request to the webservice.
#    It is constructed in WebworkClient::xmlrpcCall() from the value of $webworkClient->site_url which does 
#    NOT have the mod_xmlrpc segment (it should be   http://test.webwork.maa.org) 
#    and the constant  REQUEST_URI defined in WebworkClient.pm to be mod_xmlrpc.  
#
# 2. $FORM_ACTION_URL      http:http://test.webwork.maa.org/webwork2/html2xml
#    points to the renderViaXMLRPC.pm module.
#
#     This url is placed as form action url when the rendered HTML from the original
#     request is returned to the client from Webservice/RenderProblem. The client
#     reorganizes the XML it receives into an HTML page (with a WeBWorK form) and 
#     pipes it through a local browser.
#
#     The browser uses this url to resubmit the problem (with answers) via the standard
#     HTML webform used by WeBWorK to the renderViaXMLRPC.pm handler.  
#
#     This renderViaXMLRPC.pm handler acts as an intermediary between the browser 
#     and the webservice.  It interprets the HTML form sent by the browser, 
#     rewrites the form data in XML format, submits it to the WebworkWebservice.pm 
#     which processes it and sends the the resulting HTML back to renderViaXMLRPC.pm
#     which in turn passes it back to the browser.
# 3.  The second time a problem is submitted renderViaXMLRPC.pm receives the WeBWorK form 
#     submitted directly by the browser.  
#     The renderViaXMLRPC.pm translates the WeBWorK form, has it processes by the webservice
#     and returns the result to the browser. 
#     The The client renderProblem.pl script is no longer involved.
# 4.  Summary: renderProblem.pl is only involved in the first round trip
#     of the submitted problem.  After that the communication is  between the browser and
#     renderViaXMLRPC using HTML forms and between renderViaXMLRPC and the WebworkWebservice.pm
#     module using XML_RPC.


# Determine the root directory for webwork on this machine (e.g. /opt/webwork/webwork2 )
# this is set in webwork.apache2-config
# it specifies the address of the webwork root directory

#my $webwork_dir  = $ENV{WEBWORK_ROOT};
my $webwork_dir  = $WeBWorK::Constants::WEBWORK_DIRECTORY;
unless ($webwork_dir) {
	die "renderViaXMLRPC.pm requires that the top WeBWorK directory be set in ".
	"\$WeBWorK::Constants::WEBWORK_DIRECTORY by webwork.apache-config or webwork.apache2-config\n";
}

# read the webwork2/conf/defaults.config file to determine other parameters
#
my $seed_ce = new WeBWorK::CourseEnvironment({ webwork_dir => $webwork_dir });
my $server_root_url = $seed_ce->{server_root_url};
unless ($server_root_url) {
	die "unable to determine apache server url using course environment |$seed_ce|.".
	    "check that the variable \$server_root_url has been properly set in conf/site.conf\n";
}

############################
# These variables are set when the child process is started
# and remain constant through all of the calls handled by the 
# child
############################

our ($SITE_URL,$FORM_ACTION_URL, $XML_PASSWORD, $XML_COURSE);

	$XML_PASSWORD     	 =  'xmlwebwork';
	$XML_COURSE          =  'daemon_course';



	$SITE_URL             =  "$server_root_url"; 
	$FORM_ACTION_URL     =  "$server_root_url/webwork2/html2xml";


our @COMMANDS = qw( listLibraries    renderProblem  ); #listLib  readFile tex2pdf 


##################################################
# end configuration section
##################################################


sub pre_header_initialize {
	my ($self) = @_;
	my $r = $self->r;
	# Note: Vars helps handle things like checkbox 'packed' data;
	my %input_hash =  WeBWorK::Form->new_from_paramable($r)->Vars ;
    # input_hash contains the GET parameters(and possibly POST parameters) from the call to html2xml
     
	# these parameters are required to set up the PG_renderer
	# rendering anonymously 
	#    userID = daemon
	#    courseID = daemon_course
	#    course_password = daemon   (actually the password for userID in courseID)
	#   (anonymous is sometimes used instead of daemon 
	#         -- depends on how the rendering course site is set up)
	#         -- the rendering course (daemon_course) is a standard WW course but for safety 
	#         -- it should not have many users enrolled besides "daemon"
	
	# When passing parameters via an LMS you get "custom_" put in front of them. So lets
	

	$input_hash{userID} = $input_hash{custom_userid} if $input_hash{custom_userid};
	$input_hash{courseID} = $input_hash{custom_courseid} if $input_hash{custom_courseid};
	$input_hash{displayMode} = $input_hash{custom_displaymode} if $input_hash{custom_displaymode};
	$input_hash{course_password} = $input_hash{custom_course_password} if $input_hash{custom_course_password};
	
	# the following parameters are destined for the pg_environment variable (envir)
	# and are not otherwise needed to set up the renderer 
	
	$input_hash{answersSubmitted} = $input_hash{custom_answerssubmitted} if $input_hash{custom_answerssubmitted};
	$input_hash{problemSeed} = $input_hash{custom_problemseed} if $input_hash{custom_problemseed};
	$input_hash{problemUUID} = $input_hash{problemUUID}//$input_hash{problemIdentifierPrefix}; # earlier version of problemUUID
	$input_hash{sourceFilePath} = $input_hash{custom_sourcefilepath} if $input_hash{custom_sourcefilepath};
	$input_hash{outputformat} = $input_hash{custom_outputformat} if $input_hash{custom_outputformat};
	
	# some additional operations are done if there is a JavaWebToken present
	# we first dereference it to simplify the code
	my $webwork_jwt  = $input_hash{webworkJWT}//'';

	#dereference these variables for the next two conditional statements 
	my $user_id      = $input_hash{userID};
	my $courseName   = $input_hash{courseID};
	my $displayMode  = $input_hash{displayMode};
	my $problemSeed  = $input_hash{problemSeed};

	# some additional override operations are done if there is a JSONWebToken (JWT) present
	my $webwork_jwt  = $input_hash{webworkJWT}//'';
	if ($webwork_jwt) {
		my $sourceFilePath = $input_hash{sourceFilePath}//'';
		my $payload = decode_jwt(token=>$webwork_jwt, key=>'s1r1b1r1', accepted_alg=>'HS256'); # TODO REMOVE INSECURE DEVELOPMENT KEY
		#TODO add validation of expiration (exp), issue time (iat), not before (nbf), issuer (iss), and audience (aud).
		# verify_exp=>1, verify_iat=>1, verify_nbf=>1, verify_exp=>1, verify_aud=>"webwork", verify_iss=>""
		#TODO switch to asymmetric keys and JWT encrpytion [JSON Web Encryption (JWE)].


		#override input_hash if keys are present
		$input_hash{userID} = $payload->{userID} if $payload->{userID};
		$input_hash{courseID} = $payload->{courseID} if $payload->{courseID};
		$input_hash{displayMode} = $payload->{displayMode} if $payload->{displayMode};
		$input_hash{course_password} = $payload->{course_password} if $payload->{course_password};
		$input_hash{answersSubmitted} = $payload->{answersSubmitted} if $payload->{answersSubmitted};
		$input_hash{problemSeed} = $payload->{problemSeed} if $payload->{problemSeed};
		$input_hash{problemUUID} = $payload->{problemUUID} if $payload->{problemSeed};
		$input_hash{sourceFilePath} = $payload->{sourceFilePath} if $payload->{sourceFilePath};
		$input_hash{outputformat} = $payload->{outputformat} if $payload->{outputformat};

		$input_hash{jwt_payload} = $payload; 

		# sanity check
		my $debug=0;
		if ($debug){ 
			#unit test of passing in variables
			#There is a bug here when trying to do sourceFilePath or displayMode????

			print CGI::ul( 
				  CGI::h1("JWT is present"),
				  CGI::li(CGI::escapeHTML([
					"webworkJWT: |$webwork_jwt|",
					"userID: |$input_hash{userID}|",
					"courseID: |$input_hash{courseID}|",
					"sourceFilePath: |$input_hash{sourceFilePath}|",
					"displayMode: |$input_hash{displayMode}|",
					"problemSeed: |$input_hash{problemSeed}|"
				  ])
				  )
			);
			#print (" | ", encode_json($payload), "<br/>");
			my $envir = $payload->{envir};
			if ($envir){
				print "envir: ", encode_json( $envir), "<br/>";
			}
		}

		# override protected input_hash values from the payload 
		for my $key (qw(sourceFilePath problemSeed)){
					$input_hash{$key} = $payload->{$key};
		}
		# $input_hash{jwt_payload} # passed on 
		# $input_hash{webworkJWT}  # encoded JWT passed on

	}

	# dereference some variables for sanity check and for error reporting
	my $user_id      = $input_hash{userID};
	my $courseName   = $input_hash{courseID};
	my $displayMode  = $input_hash{displayMode};
	my $problemSeed  = $input_hash{problemSeed};
	
	unless ( $user_id && $courseName && $displayMode && $problemSeed) {
		#sanity check for required variables
		print CGI::ul( 
		      CGI::h1("Missing essential data in web dataform:"),
			  CGI::li(CGI::escapeHTML([
		      	"userID: |$user_id|", 
		      	"courseID: |$courseName|",	
		        "displayMode: |$displayMode|", 
		        "problemSeed: |$problemSeed|",
		        "webworkJWT: |$webwork_jwt|",
		      ])));
		return;
	}
    #######################
    #  setup xmlrpc client
    #######################
    my $xmlrpc_client = new WebworkClient;

	# these are toplevel items in the WebworkClient object
	$xmlrpc_client->encoded_source($r->param('problemSource')) ; 
	     # this source, if it exists, has already been encoded in base64.
	$xmlrpc_client->site_url($SITE_URL);  # the url of the WebworkWebservice
	$xmlrpc_client->{form_action_url} = $FORM_ACTION_URL;  # the action to placed in the return HTML form
	$xmlrpc_client->{userID}          = $input_hash{userID};
	$xmlrpc_client->{courseID}        = $input_hash{courseID};
	$xmlrpc_client->{course_password} = $input_hash{course_password}; #(password for userID in courseID )
	$xmlrpc_client->{site_password}   = $XML_PASSWORD; # fixed for all courses in the site,
													   #  screens for spam -- not yet used much yet
	$xmlrpc_client->{session_key}     = $input_hash{session_key}; # can be used instead of password
	$xmlrpc_client->{outputformat}    = $input_hash{outputformat};
	$xmlrpc_client->{sourceFilePath}  = $input_hash{sourceFilePath}; #for fetching problemSource
	                                             # from files stored on the WebworkWebservice server (e.g. OPL) 
	# $xmlrpc_client->{webworkJWT}     = $input_hash{webworkJWT}//''; can be obtained from input_hash
	# in addition to the arguments above the input_hash contains parameters for the pg_environment
	$xmlrpc_client->{input_hash}      = \%input_hash;  # contains GET parameters from form


	##############################
	# xmlrpc_client calls webservice via
	# xmlrpcCall() to have problem rendered by WebworkWebservice::RenderProblem.pl
	# and stores the resulting HTML output in $self->return_object
	# from which it will eventually be returned to the browser
	#
	##############################
	if ( $xmlrpc_client->xmlrpcCall('renderProblem', $xmlrpc_client->{input_hash}) )    {
			$self->{output} = $xmlrpc_client->formatRenderedProblem ;
	} else {
		$self->{output}= $xmlrpc_client->return_object;  # error report
	}
	
	################################
 }

sub content {
   ###########################
   # Return content of rendered problem to the browser that requested it
   ###########################
	my $self = shift;
	print $self->{output};
}




1;
