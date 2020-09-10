
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

our $jwt_input =  "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC8xMjcuMC4wLjE6ODAwMFwvYXBpXC9hc3NpZ25tZW50c1wvMVwvcXVlc3Rpb25zXC92aWV3IiwiaWF0IjoxNTk3Nzg2Nzc0LCJleHAiOjYxNTk3Nzg2Nzc0LCJuYmYiOjE1OTc3ODY3NzQsImp0aSI6Ik14Uzg2dGppMVc2ejJ6N1giLCJzdWIiOjEzLCJwcnYiOiI4N2UwYWYxZWY5ZmQxNTgxMmZkZWM5NzE1M2ExNGUwYjA0NzU0NmFhIiwiYWRhcHQiOnsiYXNzaWdubWVudF9pZCI6MSwicXVlc3Rpb25faWQiOjksInRlY2hub2xvZ3kiOiJ3ZWJ3b3JrIn0sIndlYndvcmsiOnsicHJvYmxlbVNlZWQiOiIxMjM0NTY3IiwiY291cnNlSUQiOiJkYWVtb25fY291cnNlIiwidXNlcklEIjoiZGFlbW9uIiwiY291cnNlX3Bhc3N3b3JkIjoiZGFlbW9uIiwic2hvd1N1bW1hcnkiOjEsImRpc3BsYXlNb2RlIjoiTWF0aEpheCIsImxhbmd1YWdlIjoiZW4iLCJvdXRwdXRmb3JtYXQiOiJsaWJyZXRleHRzIn19.SFVspn_cOsBrpchZe_Is1btej_UePEkIJOqL3WNG400";

sub post_to_ADAPT {
	my $jwt_to_post = shift;
	my $ua = LWP::UserAgent->new( 'send_te' => '0' );
	my $r  = HTTP::Request->new(
		'POST' => 'https://dev.adapt.libretexts.org/api/jwt-test',
		[
			'Accept' => 'application/json',
			'Authorization' => "Bearer  $jwt_input",
			'Host'       => 'dev.adapt.libretexts.org:443',
			'User-Agent' => 'curl/7.55.1'
		],
	);
	 my $adapt_call_hash = eval{
								$ua->request( $r, )
	  };
	 if ($@) {
		warn "problem with curl call $@";
	 }
	 else {
		return $adapt_call_hash->{_content};
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
	my $token = $in{token};
	my $key = $in{key}//'s1r1rb1r1';
	decode_jwt(token=>$token, key=>$key);
	# FIXME -- make method? get key from $ce?
}

sub hash2jwt {
	my %in = @_;
	my $payload = $in{payload};
	my $key = $in{key}//'s1r1b1r1';
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