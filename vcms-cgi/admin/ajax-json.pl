#!/usr/bin/perl -w


use strict;
no strict "refs";

use lib "../modules/";
use lib "../../../../perl/usr/lib/perl5/x86_64-linux-thread-multi";

use Data::Dumper;
use JSON::PP;
use Time::HiRes qw (time);

use cmlmain;
use cmlcalc;
use cmlajax;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;
use Encode;

use vars qw ($AJAX_FUNCS);
   
   
$AJAX_FUNCS={
	setvalue=>1,
	addobject=>1,
	deleteobject=>1,
	execute=>1,
	deletealllow=>1,
	resort=>1,
};   

my $ts_start=time();
start('..');
print "Content-Type: application/json; charset=$GLOBAL->{CODEPAGE}\n\n";

my $data=param('data');
my $func=param('func');
my $oid=param('objid');

my $json = new JSON::PP;
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%admin';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");
if (param('lfunc')) {
    $func=param('lfunc');
    my $data=param('data') || $json->encode ([]);
    $cmlcalc::CGIPARAM=data_prepare($data,$GLOBAL->{CODEPAGE});
    my $result=execute({lmethod=>$func,id=>param('objid')});
    $result->{output}=$cmlcalc::CGIPARAM->{output} if $cmlcalc::CGIPARAM->{output};
    if (ref $result ne 'HASH') {
        my $rstr=enc("������ ����������. �����: $func ������: ").$result;
        print $json->encode ({status=>1,message=>$rstr});
    } else {
    	$result->{objid}=param('objid');
        print $json->encode ($result);
	}
} elsif ($AJAX_FUNCS->{$func}) {
	my $subname="cmlajax::ajax_$func";
	my $r=decode_json($data);
	if (ref $r eq 'HASH') {
		unless ($GLOBAL->{CODEPAGE} eq 'utf-8') {
			$r->{$_} = Encode::encode('cp1251',$r->{$_}) for keys %$r;
		}
		$cmlcalc::CGIPARAM=$r;
	}		
	$cmlcalc::CGIPARAM->{_MODE}='ADMINAJAX';
	my $result=&$subname($r);
	print $json->encode ($result);
} else {
	my $data=param('data') || $json->encode ([]);
	$cmlcalc::CGIPARAM=data_prepare($data,$GLOBAL->{CODEPAGE});
	my $result=execute({method=>$func});
	if (ref $result ne 'HASH') {
		my $rstr=enc("������ ����������. �����: $func ������: ").$result;
		print $json->encode ({status=>1,message=>$rstr});
	} else {	
    	print $json->encode ($result);
	}	
	#my $rstr=enc("������������ ������� $func");
	#print $json->encode ({result=>$rstr});
}	
my $ts=time()-$ts_start;
warn "DBG: END: FUNC:$func OID:$oid TIME:$ts UA:$ENV{HTTP_USER_AGENT} COOKIE:$ENV{HTTP_COOKIE}";

