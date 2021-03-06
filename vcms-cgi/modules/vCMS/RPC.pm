package vCMS::RPC;

use lib "..";
use JSON::PP;
use Encode;
use HTTP::Request::Common qw(POST);
use File::Copy;
use vCMS::Proxy;
use POSIX qw(strftime);
 
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
	$ua->timeout(900);
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


sub e ($$;$) {
	return Execute($_[0],$_[1],$_[2]);
}

sub Test ($) {
	my ($self)=@_;
	return $self->Execute('TESTGATE');
}


sub DBDump  ($$) {
	my ($self,$filename)=@_;
	my $test=$self->Test();
	return "Gate test error: ".$test->{error} if $test->{error};
	$filename ||= vCMS::Proxy::GetGlobal('WWWPATH').'/backup/db.gz';
	my $uri="http://$self->{_host}/cgi-bin/vcms/cmlsrv.pl?action=export&area=db";
	my $str="curl --user $self->{_username}:$self->{_password} \"$uri\" -o $filename";
	my $e=`$str`;
	return "str:$str e:$e s:".-s ($filename);
}



sub DBSync  ($;$) {
    my ($self,$opt)=@_;
    my $test=$self->Test();
    return "Gate test error: ".$test->{error} if $test->{error};
    vCMS::Proxy::DropPagesCache();
    my $backupname=vCMS::Proxy::BackupDB();
    return "cant backup ($backupname)" unless -s $backupname;
    my $uri="http://$self->{_host}/cgi-bin/vcms/cmlsrv.pl?action=export&area=db";
    $uri.="&charset=$opt->{charset}" if $opt->{charset};
    my $istr=vCMS::Proxy::ImportDBStr();
    my $str="curl --user $self->{_username}:$self->{_password} \"$uri\" | gzip -d | $istr";
    my $e=`$str`;
    $backupname=~s/.gz/.2.gz/;
    vCMS::Proxy::BackupDB($backupname);
    return "str:$str e:$e";
}

sub StaticSync ($) {
    my ($self)=@_;
    my $test=$self->Test();
    return "Gate test error: ".$test->{error} if $test->{error};

    my $wwwpath=vCMS::Proxy::GetGlobal('WWWPATH');
    my $cgipath=vCMS::Proxy::GetGlobal('CGIPATH');    
    copy("$wwwpath/.htaccess","$wwwpath/.htaccess.".strftime ('%Y%m%d_%H%M',localtime()).".backup");
    copy("$cgipath/conf","$cgipath/conf.".strftime ('%Y%m%d_%H%M',localtime()).".backup");

    my $uri="http://$self->{_host}/cgi-bin/vcms/cmlsrv.pl?action=export&area=docs";
    my $str="curl --user $self->{_username}:$self->{_password} \"$uri\" | tar -zxf - -C $wwwpath";
    my $output=`$str`;
    return("$str - $output");
}

sub DataSync ($) {
	my ($self)=@_;
	my $test=$self->Test();
	return "Gate test error: ".$test->{error} if $test->{error};	
	my $uri="http://$self->{_host}/cgi-bin/vcms/cmlsrv.pl?action=export&area=data";
	my $path=vCMS::Proxy::GetGlobal('FILEPATH');
	my $str="curl --user $self->{_username}:$self->{_password} \"$uri\" | tar -zxf - -C $path";
	my $output=`$str`;
	return("$str - $output");
}



1;