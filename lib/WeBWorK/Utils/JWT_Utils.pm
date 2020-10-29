
package WeBWorK::Utils::JWT_Utils;
use base qw(Class::Accessor);

use 5.10.0;
use strict;
use warnings;
use JSON qw(encode_json decode_json);
use LWP::UserAgent;
use Crypt::JWT qw(decode_jwt encode_jwt);
use WeBWorK::Utils qw(readFile);
use Exporter;
use Carp;

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
	my $ce = shift;  # grab a course environment variable
	my %options = @_;  #FIXME figure out how options should be passed in
	my $self = {
		ce  => $ce,
		path_to_JWT_config_file => $ce->{path_to_JWT_config_file}//'',
 		secret_key => '', # the keyword for signing and the key word for encryption
		content_alg =>'', # 'A256CBCHS512'  , # the algorithm for encrypting the content_alg
		signing_alg =>'HS256'   , # or A256KW  the algorithm for signing (encrypting the signature)
		elapsed_time=>0,    # iat to exp
		%options,
	};
	bless $self, $class;
	# create accessors/mutators
    $self->mk_ro_accessors (qw( ce path_to_config_file secret_key content_alg signing_alg elapsed_time));
	_init($self, %options);  #go grab data from the configuration file
	return $self;
}

# this is a subroutine not a method
# perhaps it should be placed in a separate utils file
sub _init {
	my $self = shift;
	my $string =readFile($self->{path_to_JWT_config_file});
	#carp "path to file is ", $self->{path_to_JWT_config_file};
	# make sure file exists
	#carp "string is $string";
	#carp "hash test is ", ref($string) =~/HASH/;
	if ($string) {
		# trim string
		$string =~ s/^\s+|\s+$//; 
		$self->{secret_key}=$string;
		# procedure to use if file contains a JSON object
		# including secret_key and algorithms
		#my $rh_JWT_config =json2hash($string);
		#$self->{secret_key}=$rh_JWT_config->{secret_key};
		#$self->{content_alg}=$rh_JWT_config->{content_alg}//'';
		#$self->{signing_alg}=$rh_JWT_config->{signing_alg}||'HS256';
		#$self->{elapsed_time}=$rh_JWT_config->{elapsed_time}//0;
		#warn "signing_alg is |".($self->signing_alg)."|";
	}
	else {  # #error code  this can be refined. 
		croak("for some reason the JWT key has not been set");
	}
}
sub post_to_ADAPT {
	my $adapt_post_address = shift;   #'https://dev.adapt.libretexts.org/api/jwt/process-answer-jwt'
#	my $problemJWT_to_post = shift;   #base64 code
	my $answerJWT_to_post =  shift;   #base64 code
	my $ua = LWP::UserAgent->new( 'send_te' => '0' );
	my $r  = HTTP::Request->new(
		'POST' => $adapt_post_address,
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
	 # model success response
	 # {"type":"success","message":"Your question submission was saved.",
	 # "last_submitted":"October 03, 2020 5:54:10pm","student_response":"N\/A"}
	 if ($@) {
		return qq{ {"type":"error","message": "unable to contact server-- $@" }};
	 }
	 else { 
	 	if ($adapt_call_hash->{_rc}==200){
	 		return $adapt_call_hash->{_content}
	 	}
	 	else { #catch errors reported by the server
			my $error_code = $adapt_call_hash->{_rc};
			my $error_msg  = $adapt_call_hash->{_msg};
			return qq{ {"type":"error","message": "server error-- $error_code: $error_msg"}};
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