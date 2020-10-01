#! perl -w

# unit tests for JWT_Utils.pm
use 5.10.07;
use lib "/opt/webwork/webwork2/lib";
use WeBWorK::Utils::JWT_Utils qw(
	post_to_ADAPT
	jwt2hash
	hash2jwt
	json2hash
	hash2json
	pp_hash
);

my $json_text = qq+{"iss":"http:\/\/127.0.0.1:8000\/api\/assignments\/1\/questions\/view","iat":1597786774,"exp":61597786774,"nbf":1597786774,"jti":"MxS86tji1W6z2z7X","sub":13,"prv":"87e0af1ef9fd15812fdec97153a14e0b047546aa","adapt":{"assignment_id":1,"question_id":9,"technology":"webwork"},"webwork":{"problemSeed":"1234567","courseID":"daemon_course","userID":"daemon","course_password":"daemon","showSummary":1,"displayMode":"MathJax","language":"en","outputformat":"libretexts"}}+;
# my $json_text = qq+{"a": "foo", "b":"bar"}+;
say "\njson: ",$json_text;
say "now translate\n";

say decode_json($json_text);
say "\nhash: ", json2hash($json_text);
say "translate back to json";
say hash2json(json2hash($json_text));

my $my_key='foobar';
say "my key is $my_key";

say "translate to jwt";
say hash2jwt(payload=>json2hash($json_text) , key=>$my_key);

say "translate back";

my $ww_hash = jwt2hash(token=>hash2jwt(payload=>json2hash($json_text), key=>$my_key),key=>"$my_key");
say $ww_hash;

say pp_hash(  jwt2hash(token=>hash2jwt(payload=>json2hash($json_text), key=>$my_key),key=>"$my_key") );
$ww_hash->{webwork}->{answer}="foobar";

say pp_hash($ww_hash);
say "translate to jwt and back";
say pp_hash(jwt2hash(token=>hash2jwt(payload=>$ww_hash,key=>"$my_key"), key=>"$my_key")   );

1;