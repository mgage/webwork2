
use base qw(Exporter);
use JSON;
use Crypt::JWT qw( decode_jwt encode_jwt);
use LWP::UserAgent;
use HTTP::Request;

our @EXPORT    = ();
our @EXPORT_OK = qw(
	post_to_ADAPT
	jwt2hash
	hash2jwt
	json2hash
	hash2json
	pp_hash
);


# this is a subroutine not a method


sub post_to_ADAPT {
	my $jwt_to_post = shift;
	my $ua = LWP::UserAgent->new( 'send_te' => '0' );
	my $r  = HTTP::Request->new(
		'POST' => 'https://dev.adapt.libretexts.org/api/jwt-test',
		[
			'Accept' => 'application/json',
			'Authorization' => "Bearer  $jwt_to_post",
			'Host'       => 'dev.adapt.libretexts.org:443',
			'User-Agent' => 'curl/7.55.1'
		],
	);
	 my $adapt_call_hash = eval{
								$ua->request( $r, )
	  };
	 if ($@) {
		warn "problem with curl call $@";
		return $@;
	 }
	 else {
	 	if ($adapt_call_hash->{_rc}==200){
	 		return "ok".$adapt_call_hash->{_content}
	 	}
	 	else {
	 		return "not_ok".$adapt_call_hash->{_rc}
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
	my %in = @_;
	my $token = $in{token}//'0';
	my $key = $in{key}//'webwork';
	decode_jwt(token=>$token, key=>$key);
	# FIXME -- make method? get key from $ce?
}

sub hash2jwt {
	my %in = @_;
	my $payload = $in{payload};
	my $key = $in{key}//'webwork';
	encode_jwt(payload=>$payload, alg=>'HS256',key=>$key);
}

sub json2hash {
	decode_json(shift);
}

sub hash2json {
	encode_json(shift);
}

sub pp_hash {
	$perl_hash_ref = shift;
	to_json($perl_hash_ref, {utf8=>1, pretty=>1});
}

1;