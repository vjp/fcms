package vCMS;

use vCMS::Object::Up;
use vCMS::Object::Low;

BEGIN
{ 
	use Exporter();
	use lib "..";
	@ISA = 'Exporter';
	@EXPORT = qw( &o);
	use cmlmain;
}	 

sub o($); 
sub o($) {
	my $id=shift;
	my $pObj;
    if ($id=~/^(\d+)$/) {
    	$pObj=vCMS::Object::Low->new($1);
    	return $pObj;
    } elsif ($id=~/^u(\d+)/) {
    	$pObj=vCMS::Object::Up->new($1);
    	return $pObj->Load()?$pObj:undef;
    } else {
        my $oid=cmlmain::checkload({key=>$id});
        return  $oid=~/^u?(\d+)$/?o($oid):undef;
    }
}




package vCMS::RPC;
 
 
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

sub Execute {
	my ($self,$method)=@_;
	require JSON::PP;
	my $r = HTTP::Request -> new      ( POST => "http://$self->{_host}/gate/_$method");
	$r->authorization_basic( $self->{_username}, $self->{_password} );
	my $response = $self->{_ua}->request($r); 
    my $cnt=$response->content;
    if ($cnt) {
    	my $rv;
    	eval {
    		$rv=decode_json($cnt);
    	};
    	if ($@) {
    		return {error=>$cnt} 
    	} else {
    		return $rv;
    	}
    } else {
    	return undef;
    }
	
}

1;