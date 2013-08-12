package vCMS::RPC;

use lib "..";
use JSON::PP; 
use Encode;
use HTTP::Request::Common qw(POST); 
use vCMS::Proxy;
 
=head1 NAME

vCMS::RPC - Execute methods on remote vCMS system

=head1 SYNOPSIS

my $rpc=new vCMS::RPC('rpchost.com','username','password');
my $response=$rpc->Execute('METHODONREMOTEHOST',$datahashref);
 
=cut 
 
 
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
	$data->{$_}=Encode::decode('cp1251',$data->{$_}) for keys %$data;
		
	my $uri="http://$self->{_host}/gate/_$method";
	$data=JSON::PP->new->utf8(0)->encode ($data);
	my $r = 	POST  ($uri, [data=> $data]) ;
	$r->authorization_basic( $self->{_username}, $self->{_password} );
	
	
	my $response = $self->{_ua}->request($r); 
    if ($response->is_success) {
    	my $cnt=$response->content;
    	my $rv;
    	eval {
    		$rv=decode_json(Encode::encode('utf8',$cnt));
    	};
    	if ($@) {
    		return {error=>$@,result=>$cnt,uri=>$uri} 
    	} else {
    		return $rv;
    	}
    } else {
    	return {error=>"HTTP error:".$response->status_line, uri=>$uri} ;
    }
	
}

sub Test ($) {
	my ($self)=@_;
	return $self->Execute('TESTGATE');
}


sub DBDump  ($$) {
	my ($self,$filename)=@_;
	my $test=$self->Test();
	return $test->{error} if $test->{error};
	$filename ||= vCMS::Proxy::GetGlobal('WWWPATH').'/backup/db.gz';
	my $uri="http://$self->{_host}/cgi-bin/vcms/cmlsrv.pl?action=export&area=db";
	my $str="curl --user $self->{_username}:$self->{_password} \"$uri\" -o $filename";
	my $e=`$str`;
	return "str:$str e:$e s:".-s ($filename);
}



sub DBSync  ($) {
	my ($self)=@_;
	my $test=$self->Test();
	return $test->{error} if $test->{error};
	vCMS::Proxy::DropPagesCache();
    my $uri="http://$self->{_host}/cgi-bin/vcms/cmlsrv.pl?action=export&area=db";
	my $istr=vCMS::Proxy::ImportDBStr();
	my $str="curl --user $self->{_username}:$self->{_password} \"$uri\" | gzip -d | $istr";
	my $e=`$str`;
	return "str:$str e:$e";
}

sub StaticSync ($) {
	my ($self)=@_;
	my $uri="http://$self->{_host}/cgi-bin/vcms/cmlsrv.pl?action=export&area=docs";
	my $str="curl --user $self->{_username}:$self->{_password} \"$uri\" | tar -zxf - -C $GLOBAL->{WWWPATH}";
	my $output=`$str`;
	return("$str - $output");
}


1;