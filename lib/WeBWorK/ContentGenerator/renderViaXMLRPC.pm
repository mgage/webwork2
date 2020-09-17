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
#    It is constructed in WebworkClient::xmlrpcCall() from the value of $webworkclient->webservice_site_url which does 
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

our ($WEBSERVICE_SITE_URL,$FORM_ACTION_URL, $XML_PASSWORD, $XML_COURSE);

	$XML_PASSWORD     	 =  'xmlwebwork';
	$XML_COURSE          =  'daemon_course';



	$WEBSERVICE_SITE_URL =  "http://localhost"; #"$server_root_url"; #includes port (which is :80 within the container)
	$FORM_ACTION_URL     =  "http://localhost:8080/webwork2/html2xml"; #includes exterior port provided by the container


our @COMMANDS = qw( listLibraries    renderProblem  ); #listLib  readFile tex2pdf 


##################################################
# end configuration section
##################################################


sub pre_header_initialize {
	my ($self) = @_;
	my $r = $self->r;
	# Note: Vars helps handle things like checkbox 'packed' data;
	my %hash_from_web_form =  WeBWorK::Form->new_from_paramable($r)->Vars ;
    # hash_from_web_form contains the GET parameters(and possibly POST parameters) from the call to html2xml
     
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
	

	$hash_from_web_form{userID} = $hash_from_web_form{custom_userid} if $hash_from_web_form{custom_userid};
	$hash_from_web_form{courseID} = $hash_from_web_form{custom_courseid} if $hash_from_web_form{custom_courseid};
	$hash_from_web_form{displayMode} = $hash_from_web_form{custom_displaymode} if $hash_from_web_form{custom_displaymode};
	$hash_from_web_form{course_password} = $hash_from_web_form{custom_course_password} if $hash_from_web_form{custom_course_password};
	
	# the following parameters are destined for the pg_environment variable (envir)
	# and are not otherwise needed to set up the renderer 
	
	$hash_from_web_form{answersSubmitted} = $hash_from_web_form{custom_answerssubmitted} if $hash_from_web_form{custom_answerssubmitted};
	$hash_from_web_form{problemSeed} = $hash_from_web_form{custom_problemseed} if $hash_from_web_form{custom_problemseed};
	$hash_from_web_form{problemUUID} = $hash_from_web_form{problemUUID}//$hash_from_web_form{problemIdentifierPrefix}; # earlier version of problemUUID
	$hash_from_web_form{sourceFilePath} = $hash_from_web_form{custom_sourcefilepath} if $hash_from_web_form{custom_sourcefilepath};
	$hash_from_web_form{outputformat} = $hash_from_web_form{custom_outputformat} if $hash_from_web_form{custom_outputformat};
	


	# some additional override operations are done if there is a JSONWebToken (JWT) present
	my $problemJWT  = $hash_from_web_form{problemJWT}//'';
	if ($problemJWT) { #take all data from the problemJWT_payload
		my $problemJWT_payload = decode_jwt(token=>$problemJWT, key=>'webwork', accepted_alg=>'HS256'); # TODO REMOVE INSECURE DEVELOPMENT KEY
		unless ($problemJWT_payload->{webwork}) {
			croak("problemJWT does not contain 'webwork' field in problemJWT_payload");
		}
		#TODO add validation of expiration (exp),
		# issue time (iat), 
		# not before (nbf), 
		# issuer (iss), and 
		# audience (aud).
		# verify_exp=>1, 
		# verify_iat=>1, 
		# verify_nbf=>1, 
		# verify_exp=>1, 
		# verify_aud=>"webwork", 
		# verify_iss=>""
		#TODO switch to asymmetric keys and JWT encrpytion [JSON Web Encryption (JWE)].

	   # get sessionJWT (anything else you want preserved)
		
		my $sessionJWT  = $hash_from_web_form{sessionJWT}//'';
		
		# erase hash_from_web_form and reload
		#%hash_from_web_form=(); # overwrite instead of erasing
	
		$hash_from_web_form{problemJWT}= $problemJWT;
		
	
		warn "\nproblemJWT  $problemJWT\n\n"; 
		warn "problemJWT_payload $problemJWT_payload \n";
		foreach my $key (qw(course_password courseID displayMode 
		                language outputformat problemSeed problemSeed problemUUID 
		                showSummary sourceFilePath userID 
						)
		            ) {
					$hash_from_web_form{$key} = $problemJWT_payload->{webwork}{$key}; 
		}
		$hash_from_web_form{problemJWT}= $problemJWT;  # stable the original JWT to problemJWT_payload	
		$hash_from_web_form{problemJWT_payload}=$problemJWT_payload;
		# set state
		if ($sessionJWT)   {
		warn "\n\n\n sessionJWT  $sessionJWT\n\n"; 
	
			my $sessionJWT_payload = decode_jwt(token=>$sessionJWT, key=>'webwork', accepted_alg=>'HS256'); # TODO REMOVE INSECURE DEVELOPMENT KEY
			warn "sessionJWT_payload $sessionJWT_payload \n";
			#update hash variables from sessionState
			#  qw(answersSubmitted problemSource session_key )
			$hash_from_web_form{answersSubmitted}= 1; #$sessionJWT_payload->{answersSubmitted};
		}
		
		#dereference these variables for error reporting  
		my $user_id       = $hash_from_web_form{userID};
		my $courseID      = $hash_from_web_form{courseID};
		my $displayMode   = $hash_from_web_form{displayMode};
		my $problemSeed   = $hash_from_web_form{problemSeed};
        my $sourceFilePath = $hash_from_web_form{sourceFilePath};
		# sanity check
		if ($hash_from_web_form{jwt_debug}){ 
			#unit test of passing in variables
			#There is a bug here when trying to do sourceFilePath or displayMode????

			print CGI::ul( 
				  CGI::h1("JWT is present"),
				  CGI::li(CGI::escapeHTML([
					"problemJWT: |$problemJWT|",
					"userID: |$hash_from_web_form{userID}|",
					"courseID: |$hash_from_web_form{courseID}|",
					"course_password: |$hash_from_web_form{course_password}|",
					"sourceFilePath: |$hash_from_web_form{sourceFilePath}|",
					"displayMode: |$hash_from_web_form{displayMode}|",
					"problemSeed: |$hash_from_web_form{problemSeed}|",
					"problemJWT_payload: |",encode_json($hash_from_web_form{problemJWT_payload}),"|",
				  ])
				  )
			);
			return;
		}
		# emergency hacks   FIXME
	
	} # end jwt special case
	
	#dereference these variables for error reporting  
		my $user_id      = $hash_from_web_form{userID};
		my $courseID     = $hash_from_web_form{courseID};
		my $displayMode  = $hash_from_web_form{displayMode};
		my $problemSeed  = $hash_from_web_form{problemSeed};
		my $sourceFilePath =$hash_from_web_form{sourceFilePath};
 
	unless ( $user_id && $courseID && $displayMode && $problemSeed) {

		#sanity check for required variables
		print CGI::ul( 
		      CGI::h1("Missing essential data in web dataform:"),
			  CGI::li(CGI::escapeHTML([
		      	"userID: |$user_id|", 
		      	"courseID: |$courseID|",	
		        "displayMode: |$displayMode|", 
		        "problemSeed: |$problemSeed|",
		        "sourceFilePath: |sourceFilePath|",
		        "problemJWT: |$problemJWT|",
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
	$xmlrpc_client->webservice_site_url($WEBSERVICE_SITE_URL);  # the url of the WebworkWebservice
	$xmlrpc_client->{form_action_url} = $FORM_ACTION_URL;  # the action to placed in the return HTML form
	$xmlrpc_client->{userID}          = $hash_from_web_form{userID};
	$xmlrpc_client->{courseID}        = $hash_from_web_form{courseID};
	$xmlrpc_client->{course_password} = $hash_from_web_form{course_password}; #(password for userID in courseID )
	$xmlrpc_client->{site_password}   = $XML_PASSWORD; # fixed for all courses in the site,
													   #  screens for spam -- not yet used much yet
	$xmlrpc_client->{session_key}     = $hash_from_web_form{session_key}; # can be used instead of password
	$xmlrpc_client->{outputformat}    = $hash_from_web_form{outputformat};
	$xmlrpc_client->{sourceFilePath}  = $hash_from_web_form{sourceFilePath}; #for fetching problemSource
	                                             # from files stored on the WebworkWebservice server (e.g. OPL) 
	$xmlrpc_client->{problemJWT}     = $hash_from_web_form{problemJWT}//'not defined in webwork hash'; 
	# in addition to the arguments above the hash_from_web_form contains parameters for the pg_environment
	$xmlrpc_client->{inputs_ref}      = \%hash_from_web_form;  # contains GET parameters from form
    #FIXME need new name for inputs_ref

	##############################
	# xmlrpc_client calls webservice via
	# xmlrpcCall() to have problem rendered by WebworkWebservice::RenderProblem.pl
	# and stores the resulting HTML output in $self->return_object
	# from which it will eventually be returned to the browser
	#
	##############################
	if ( $xmlrpc_client->xmlrpcCall('renderProblem', $xmlrpc_client->{inputs_ref}) )    {
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
