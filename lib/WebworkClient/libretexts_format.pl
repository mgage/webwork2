# put a command here?

# don't use my here?
#$lwpcurl= LWP::Curl->new(); I don't think this will do all the customization I want?
##!perl
use strict;
use warnings;

use LWP::UserAgent;


my $ua = LWP::UserAgent->new( 'send_te' => '0' );
my $r  = HTTP::Request->new(
    'POST' => 'https://dev.adapt.libretexts.org/api/jwt-test',
    [
        'Accept' => 'application/json',
        'Authorization' =>
'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC8xMjcuMC4wLjE6ODAwMFwvYXBpXC9sb2dpbiIsImlhdCI6MTU5NzQzNzQ3OCwiZXhwIjoxNTk3NTIzODc4LCJuYmYiOjE1OTc0Mzc0NzgsImp0aSI6InRyS3NITTR2emhtZVNwaG8iLCJzdWIiOjEzLCJwcnYiOiI4N2UwYWYxZWY5ZmQxNTgxMmZkZWM5NzE1M2ExNGUwYjA0NzU0NmFhIn0.ZOLMvwuNBY4RmQR_eiHIL7MtFUvLSKS9X9Z9HrwvDBweyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC8xMjcuMC4wLjE6ODAwMFwvYXBpXC9hc3NpZ25tZW50c1wvMVwvcXVlc3Rpb25zXC92aWV3IiwiaWF0IjoxNTk3Nzg2Nzc0LCJleHAiOjYxNTk3Nzg2Nzc0LCJuYmYiOjE1OTc3ODY3NzQsImp0aSI6Ik14Uzg2dGppMVc2ejJ6N1giLCJzdWIiOjEzLCJwcnYiOiI4N2UwYWYxZWY5ZmQxNTgxMmZkZWM5NzE1M2ExNGUwYjA0NzU0NmFhIiwiYWRhcHQiOnsiYXNzaWdubWVudF9pZCI6MSwicXVlc3Rpb25faWQiOjksInRlY2hub2xvZ3kiOiJ3ZWJ3b3JrIn0sIndlYndvcmsiOnsicHJvYmxlbVNlZWQiOiIxMjM0NTY3IiwiY291cnNlSUQiOiJkYWVtb25fY291cnNlIiwidXNlcklEIjoiZGFlbW9uIiwiY291cnNlX3Bhc3N3b3JkIjoiZGFlbW9uIiwic2hvd1N1bW1hcnkiOjEsImRpc3BsYXlNb2RlIjoiTWF0aEpheCIsImxhbmd1YWdlIjoiZW4iLCJvdXRwdXRmb3JtYXQiOiJsaWJyZXRleHRzIn19.SFVspn_cOsBrpchZe_Is1btej_UePEkIJOqL3WNG400',
        'Host'       => 'https://dev.adapt.libretexts.org/api/jwt-test',
        'User-Agent' => 'curl/7.55.1'
    ],

);
 my $adapt_call_return = eval{
  							$ua->request( $r, )
  };
 if ($@) {warn "problem with curl call $@"};
 $adapt_call_return = "return now from LWP::UserAgentadapt call: ".$adapt_call_return;


my $libretexts_format = <<'ENDPROBLEMTEMPLATE';

<!DOCTYPE html>
<html $COURSE_LANG_AND_DIR>
<head>
<meta charset='utf-8'>
<base href="$SITE_URL"> 
<link rel="shortcut icon" href="/webwork2_files/images/favicon.ico"/>

<!-- CSS Loads -->
<link rel="stylesheet" type="text/css" href="/webwork2_files/js/vendor/bootstrap/css/bootstrap.css"/>
<link rel="stylesheet" type="text/css" href="/webwork2_files/js/vendor/bootstrap/css/bootstrap-responsive.css"/>
<link rel="stylesheet" type="text/css" href="/webwork2_files/css/jquery-ui-1.8.18.custom.css"/>
<link rel="stylesheet" type="text/css" href="/webwork2_files/css/vendor/font-awesome/css/font-awesome.min.css"/>
<link rel="stylesheet" type="text/css" href="/webwork2_files/css/knowlstyle.css"/>
<!--  css overrides for libretexts -->
<link rel="stylesheet" type="text/css" href="/webwork2_files/themes/libretexts/libretexts.css"/> 
<link rel="stylesheet" type="text/css" href="/webwork2_files/themes/libretexts/libretexts-coloring.css"/>
<!-- JS Loads -->
<script type="text/javascript" src="/webwork2_files/js/vendor/jquery/jquery.js"></script>
<script type="text/javascript" src="/webwork2_files/mathjax/MathJax.js?config=TeX-MML-AM_HTMLorMML-full"></script>
<script type="text/javascript" src="/webwork2_files/js/jquery-ui-1.9.0.js"></script>
<script type="text/javascript" src="/webwork2_files/js/vendor/bootstrap/js/bootstrap.js"></script>
<script type="text/javascript" src="/webwork2_files/js/apps/AddOnLoad/addOnLoadEvent.js"></script>
<script type="text/javascript" src="/webwork2_files/js/legacy/java_init.js"></script>
<script type="text/javascript" src="/webwork2_files/js/apps/InputColor/color.js"></script>
<script type="text/javascript" src="/webwork2_files/js/apps/Base64/Base64.js"></script>
<script type="text/javascript" src="/webwork2_files/js/vendor/underscore/underscore.js"></script>
<script type="text/javascript" src="/webwork2_files/js/legacy/vendor/knowl.js"></script>
<script type="text/javascript" src="/webwork2_files/js/vendor/jquery/modules/jquery.json.min.js"></script>
<script type="text/javascript" src="/webwork2_files/js/vendor/jquery/modules/jstorage.js"></script>
<script type="text/javascript" src="/webwork2_files/js/apps/LocalStorage/localstorage.js"></script>
<script type="text/javascript" src="/webwork2_files/js/apps/Problem/problem.js"></script>
<script type="text/javascript" src="/webwork2_files/themes/libretexts/libretexts.js"></script>	
<script type="text/javascript" src="/webwork2_files/js/vendor/iframe-resizer/js/iframeResizer.contentWindow.min.js"></script>
$problemHeadText

<title>WeBWorK using host: $SITE_URL, format: libretexts</title>

</head>
<body>
<div class="container-fluid">
<div class="row-fluid">
<div class="span12 problem">
<div>
	<h3> Curl call </h3>
	<p>
	adapt: $adapt_call_return 
	</p>
	<p>
        answer json: $JSONanswerTemplate
        </p>
	<p>
	answer jwt: $JWTanswerTemplate
	</p>
</div>


<div class="answerTemplate">		
$answerTemplate
</div>



<form id="problemMainForm" class="problem-main-form" name="problemMainForm" action="$FORM_ACTION_URL" method="post" style="margin-bottom:-20px">
<div id="problem_body" class="problem-content" $PROBLEM_LANG_AND_DIR>
$problemText
</div>
<p>
$scoreSummary
</p>

<p>
$localStorageMessages
</p>

$LTIGradeMessage


<input type="hidden" name="answersSubmitted" value="1"> 
<input type="hidden" name="sourceFilePath" value = "$sourceFilePath">
<input type="hidden" name="problemSource" value="$encoded_source"> 
<input type="hidden" name="problemSeed" value="$problemSeed"> 
<input type="hidden" name="problemUUID" value="$problemUUID">
<input type="hidden" name="psvn" value="$psvn">
<input type="hidden" name="pathToProblemFile" value="$fileName">
<input type="hidden" name="courseName" value="$courseID">
<input type="hidden" name="courseID" value="$courseID">
<input type="hidden" name="userID" value="$userID">
<input type="hidden" name="course_password" value="$course_password">
<input type="hidden" name="displayMode" value="$displayMode">
<input type="hidden" name="session_key" value="$session_key">
<input type="hidden" name="outputformat" value="libretexts">
<input type="hidden" name="language" value="$formLanguage">
<input type="hidden" name="showSummary" value="$showSummary">
<input type="hidden" name="forcePortNumber" value="$forcePortNumber">


<p>
<input type="submit" name="preview"  value="$STRING_Preview" />
<input type="submit" name="WWsubmit" value="$STRING_Submit"/>
<input type="submit" name="WWcorrectAns" value="$STRING_ShowCorrect"/>
</p>
</form>
</div>
</div>
</div>

<!--  script for knowl-like object -->
<script>
	$(document).ready(function(){
		$( ".clickme" ).click(function() {
		  $( this).next().slideToggle( "slow", function() {
			// Animation complete.
		  });
		});

	   // jQuery methods go here...
	});
</script>
<div class="clickme" id="version">
<img height="16px" width="16px" src="https://demo.webwork.rochester.edu/webwork2_files/images/webwork_square.svg"/>
</div>
<div id="footer" style="display:none">
WeBWorK &copy; 1996-2020 | host: $SITE_URL | course: $courseID | format: libretexts | theme: math4
</div>

<!-- Activate local storage js -->
<script type="text/javascript">WWLocalStorage();</script>
</body>
</html>

ENDPROBLEMTEMPLATE

$libretexts_format;
