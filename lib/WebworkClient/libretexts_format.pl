

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
<div id="debug-display" style="$displayDebugDiv">
	<h3> Curl call </h3>

<p>
	problemJWT is  $problemJWT
</p>

<p>
	answerJWT  is  $answerJWT
</p>

<p>
	problemJWT_payload $problemJWT_payload
</p>

<p>
	decode problemJWT:    |$decode_problemJWT| 
</p>

<p>
	decode answerJWT:    |$decode_answerJWT| 
</p>

<p>
	decode sessionJWT:    |$decode_sessionJWT| 
</p>

	
<p>
	adapt_call_return_answerJWT:  |$adapt_call_return_answerJWT| --- $adapt_json_response_obj <br/>

     adapt_response_hash_rh:   |$adapt_response_hash_rh|

	</p>
	<p> 
        JSONanswerTemplate: $JSONanswerTemplate<br/>
    </p>
        
   <p>URLS<BR/>
    site_url (for images and other auxiliary files) is: |$SITE_URL| <BR/>
    FORM_ACTION_URL (to submit for scoring) is |$FORM_ACTION_URL|<BR/>
    docker container: WEBWORK2_HTTP_PORT_ON_HOST: $ENV{WEBWORK2_HTTP_PORT_ON_HOST}<BR/>

   </p>
   
   <p>
     problemResult = $pp_problemResult
   </p>
   <p>
     problemState = $pp_problemState
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
<input type="hidden" name="courseName" value="$courseID">
<input type="hidden" name="courseID" value="$courseID">
<input type="hidden" name="userID" value="$userID">
<input type="hidden" name="course_password" value="$course_password">
<input type="hidden" name="displayMode" value="$displayMode">
<input type="hidden" name="session_key" value="$session_key">
<input type="hidden" name="outputformat" value="libretexts">
<input type="hidden" name="language" value="$formLanguage">
<input type="hidden" name="showSummary" value="$showSummary">
<input type="hidden" name="showHints" value="$showHints">
<input type="hidden" name="showSolutions" value="$showSolutions">
<input type="hidden" name="showDebug" value="$showDebug">
<input type="hidden" name="forcePortNumber" value="$forcePortNumber">
<input type="hidden" name="problemJWT" value="$problemJWT">
<input type="hidden" name="sessionJWT" value="$sessionJWT">
<p>

$previewButtonHTML  $submitButtonHTML  $showCorrectButtonHTML

</p>
</form>
</div>
</div>
</div>

<!--  script for knowl-like object 
-->

<script type="text/javascript">
	$(document).ready(function(){
		$(".clickme").click(function() {
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

<script type="text/javascript">
if ($adapt_call_return_answerJWT !== false) {
	var response =$adapt_call_return_answerJWT;
	var returnobj = {subject: "webwork.result", message: response.message,type: response.type};
	console.log("response message " + JSON.stringify(returnobj));
	window.parent.postMessage(JSON.stringify(returnobj), '*');
}
</script>



</body>
</html>

ENDPROBLEMTEMPLATE

$libretexts_format;