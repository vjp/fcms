#!/usr/bin/perl


use strict;
use lib "./modules/";
use JSON::PP;


use cmlmain;
use cmlcalc;
use cmlajax;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;
use Time::HiRes qw (time);

my $ts_start=time();
start('.');

my $json = new JSON::PP;
print "Content-Type: application/json; charset=$GLOBAL->{CODEPAGE}\n\n";
my $data=param('data') || $json->encode ([]);
my $func=param('func') || param('lfunc');
my $oid=param('objid');

check_session();




$cmlcalc::CGIPARAM=data_prepare($data,$GLOBAL->{CODEPAGE});

$cmlcalc::CGIPARAM->{_MODE}='USERAJAX';
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%user';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");

warn "DBG: START: FUNC:$func OID:$oid";
my $result;
if (param('func')) {
	$result=execute({method=>param('func')});
} elsif (param('lfunc')) {
	$result=execute({lmethod=>param('lfunc'),id=>param('objid')});
} else {
	$result=enc('Метод не задан')
}	
if (ref $result ne 'HASH') {
	$result=({
		status=>0,
		message=>enc("Ошибка выполнения. Метод: $func Ошибка: ").$result,
	});
}
print $json->encode ($result);
my $ts=time()-$ts_start;
warn "DBG: END: FUNC:$func OID:$oid TIME:$ts UA:$ENV{HTTP_USER_AGENT} COOKIE:$ENV{HTTP_COOKIE}";
