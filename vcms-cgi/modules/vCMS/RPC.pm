package vCMS::RPC;

use JSON::PP; 
use Encode;
 
sub new {
    my $class = shift;
    my $self = {
        _host => shift,
        _username  => shift,
        _password       => shift,
    };
    require  LWP::UserAgent;
	my $ua = LWP::UserAgent->new;
	$ua->agent("vCMS rpc agent");
    $self->{_ua}=$ua;
    bless $self, $class;
    return $self;
}

sub Execute ($$;$) {
	my ($self,$method,$data)=@_;
	my $json = new JSON::PP;
	
	my $r = HTTP::Request -> new  (	POST => "http://$self->{_host}/gate/_$method");
	$r->content_type('application/x-www-form-urlencoded');
	$r->content("data=".$json->encode ($data));	
	$r->authorization_basic( $self->{_username}, $self->{_password} );
	my $response = $self->{_ua}->request($r); 
    if ($response->is_success) {
    	my $cnt=$response->content;
    	my $rv;
    	eval {
    		$rv=decode_json(Encode::encode('utf8',$cnt));
    	};
    	if ($@) {
    		return {error=>$@,result=>$cnt} 
    	} else {
    		return $rv;
    	}
    } else {
    	return {error=>$response->status_line} ;
    }
	
}

1;