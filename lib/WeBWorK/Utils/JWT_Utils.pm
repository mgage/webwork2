
package WeBWorK::Utils::JWT_Utils;
use base qw(Class::Accessor);

use 5.10.0;
use strict;
use warnings;
use JSON qw(encode_json decode_json);
use LWP::UserAgent;
use Crypt::JWT qw(decode_jwt encode_jwt);
use Exporter;

use HTTP::Request;
use lib "/opt/webwork/webwork2/lib";


# redo this by exporting an object
our @EXPORT    = ();
our @EXPORT_OK = qw(
	post_to_ADAPT
	jwt2hash
	hash2jwt
	json2hash
	hash2json
	pp_hash
);

sub new {
	my $class = shift;
	$class = (ref($class))? ref($class) : $class; # create a new object of the same class

	my @options = @_;  #FIXME figure out how options should be passed in
	$class = (ref($class))? ref($class) : $class; # create a new object of the same class
	my $ce = shift;  # grab a course environment variable
	my $self = {
		ce  => $ce,
		path_to_config_file => '',
 		secret_key => 'webwork', # the keyword for signing and the key word for encryption
		content_alg =>''  , # the algorithm for encrypting the content_alg
		signing_alg =>'HS256'   , # the algorithm for signing (encrypting the signature)
		elapsed_time=>0,    # iat to exp
		@options,
	};
	bless $self, $class;
	# create accessors/mutators
    $self->mk_ro_accessors (qw( ce path_to_config_file secret_key content_alg signing_alg elapsed_time));
	_init($self, @options);  #go grab data from the configuration file
	return $self;
}

# this is a subroutine not a method
# perhaps it should be placed in a separate utils file
sub _init {
	my $self = shift;
	$self->{path_to_config_file} = '';

}
sub post_to_ADAPT {
	my $problemJWT_to_post = shift;
	my $answerJWT_to_post =shift;
	# my $answerJWT= problemJWT_to_post;
	# "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjI0NjM3NDUzOTQsInByb2JsZW1KV1QiOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcGMzTWlPaUpvZEhSd09sd3ZYQzh4TWpjdU1DNHdMakU2T0RBd01Gd3ZZWEJwWEM5amIzVnljMlZ6SWl3aWFXRjBJam94TlRrNU56UTFNemswTENKbGVIQWlPakkwTmpNM05EVXpPVFFzSW01aVppSTZNVFU1T1RjME5UTTVOQ3dpYW5ScElqb2lOVVp1VUZSNWQwOU1UR3RzVUVsTGF5SXNJbk4xWWlJNk1Td2ljSEoySWpvaU9EZGxNR0ZtTVdWbU9XWmtNVFU0TVRKbVpHVmpPVGN4TlROaE1UUmxNR0l3TkRjMU5EWmhZU0lzSW1Ga1lYQjBJanA3SW1GemMybG5ibTFsYm5SZmFXUWlPakVzSW5GMVpYTjBhVzl1WDJsa0lqb3hMQ0owWldOb2JtOXNiMmQ1SWpvaWQyVmlkMjl5YXlKOUxDSjNaV0ozYjNKcklqcDdJbkJ5YjJKc1pXMVRaV1ZrSWpvaU1USXpORFUyTnlJc0ltTnZkWEp6WlVsRUlqb2laR0ZsYlc5dVgyTnZkWEp6WlNJc0luVnpaWEpKUkNJNkltUmhaVzF2YmlJc0ltTnZkWEp6WlY5d1lYTnpkMjl5WkNJNkltUmhaVzF2YmlJc0luTm9iM2RUZFcxdFlYSjVJam94TENKa2FYTndiR0Y1VFc5a1pTSTZJazFoZEdoS1lYZ2lMQ0pzWVc1bmRXRm5aU0k2SW1WdUlpd2liM1YwY0hWMFptOXliV0YwSWpvaWJHbGljbVYwWlhoMGN5SXNJbk52ZFhKalpVWnBiR1ZRWVhSb0lqb2lUR2xpY21GeWVWd3ZWbUZzWkc5emRHRmNMMEZRUlZoZlEyRnNZM1ZzZFhOY0x6RXVObHd2UVZCRldGOHhMalpmTVRJdWNHY2lMQ0poYm5OM1pYSlRkV0p0YVhSMFpXUWlPaUl3SWl3aWNISnZZbXhsYlZWVlNVUWlPamt5TkgxOS5PYVhjYU9POFBDZm9Yd3dzVUdwSW1BODZMd3JBWWNjejhkUnlHbUROMmNNIiwic2Vzc2lvbkpXVCI6ImV5SmhiR2NpT2lKSVV6STFOaUo5LmV5Smhibk4zWlhKelUzVmliV2wwZEdWa0lqb3hMQ0poYm5OM1pYSlVaVzF3YkdGMFpTSTZiblZzYkgwLmk0N2ZueEpCY1hrSnJXcGRublJjN1FwRVo5eGoxcWZyNnM1UlJtdFJxWEkiLCJwcnYiOiI4N2UwYWYxZWY5ZmQxNTgxMmZkZWM5NzE1M2ExNGUwYjA0NzU0NmFhIiwibmJmIjoxNTk5NzQ1Mzk0LCJuYW1lIjoiIiwiaXNzIjoiaHR0cDovLzEyNy4wLjAuMTo4MDAwL2FwaS9jb3Vyc2VzIiwic2NvcmUiOnsibXNnIjoiWW91IGNhbiBlYXJuIHBhcnRpYWwgY3JlZGl0IG9uIHRoaXMgcHJvYmxlbS4iLCJlcnJvcnMiOiIiLCJzY29yZSI6IjAiLCJ0eXBlIjoiYXZnX3Byb2JsZW1fZ3JhZGVyIn0sInN1YiI6MSwiaWF0IjoxNTk5NzQ1Mzk0LCJqdGkiOiI1Rm5QVHl3T0xMa2xQSUtrIn0.alMXMJic1l7RpzJnbMdBoOQq7Pe5z2GDXepx0CY6pkQ";
	my $ua = LWP::UserAgent->new( 'send_te' => '0' );
	my $r  = HTTP::Request->new(
		'POST' => 'https://dev.adapt.libretexts.org/api/jwt/process-answer-jwt',
		['Content-Type' => 'application/json; charset=UTF-8'],
# 		[
# 			'Accept' => 'application/json',
# 			'Authorization' => "Bearer  $problemJWT_to_post",
# 			'Host'       => 'dev.adapt.libretexts.org:443',
# 			'User-Agent' => 'curl/7.55.1'
# 		],

		$answerJWT_to_post
	);
	 my $adapt_call_hash = eval{
						$ua->request( $r, )
	 };
	 if ($@) {
		warn "problem with curl call $@";
		return $@;
	 }
	 else { #FIXME make catching error more robust
	 	if ($adapt_call_hash->{_rc}==200){
	 		return $adapt_call_hash->{_content}
	 	}
	 	else {
	 		return $adapt_call_hash->{_rc}
	 	}
	 }
# other fields returned in this hash -- possibly useful for debugging
# _headers
# _rc (200, 400, etc)
# _protocol
# _ msg (OK, Bad Request) 
# _request
}

sub jwt2hash {
	my $self = shift;
	my $token = shift;
	$token = $token//'0'; #set default for undefined or give warnings
	decode_jwt(token=>$token, key=> $self->secret_key );
}

sub hash2jwt {
	my $self = shift;
	my $payload = shift;
	$payload = $payload//{};  #set default or give warnings
	encode_jwt(payload=>$payload, alg=> $self->signing_alg ,key => $self->secret_key );
}

# subroutines not methods
sub json2hash {
	decode_json(shift);
}

sub hash2json {
	encode_json(shift);
}

sub pp_hash {
	my $perl_hash_ref = shift;
	to_json($perl_hash_ref, {utf8=>1, pretty=>1});
}

# sub encrypt_jwt_for_ADAPT {
# 	my $token shift;
# 	#fetch key and algorithm (needs $ce)
# 	$key = 
# 	$alg = 
# 
# }
# 
# sub decrypt_jwt_for_ADAPT {
# 	my $payload = shift;
# 	#fetch key and algorithm (needs $ce)
# 	$key = 
# 	$alg = 
# 
# 
# 
# }
1;