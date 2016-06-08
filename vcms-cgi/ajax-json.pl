#!/usr/bin/perl


use strict;
use lib "./modules/";
use JSON::PP;


use cmlmain;
#use cmlcalc;
use cmlajax;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;
use Time::HiRes qw (time);
use vCMS;

my $ts_start=time();
start('.');

my $json = new JSON::PP;
my $data=param('data') || $json->encode ({});
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
	$result=&cmlcalc::execute({method=>param('func')});
} elsif (param('lfunc')) {
	$result=&cmlcalc::execute({lmethod=>param('lfunc'),id=>param('objid')});
} else {
	$result=enc('Метод не задан')
}	
if (ref $result ne 'HASH') {
	$result=({
		status=>0,
		message=>enc("Ошибка выполнения. Метод: $func Ошибка: ").$result,
	});
}

my @cookies;

for my $cookiename (keys %$cmlcalc::COOKIE) {
	if (ref $cmlcalc::COOKIE->{$cookiename} eq 'HASH') {
		my $ck;
		$ck->{name}=$cookiename;
		$ck->{$_}=$cmlcalc::COOKIE->{$cookiename}->{$_} for keys %{$cmlcalc::COOKIE->{$cookiename}};
		push(@cookies,cookie($ck));	
	} else {
		push(@cookies,cookie(-name=>$cookiename,-value=>$cmlcalc::COOKIE->{$cookiename}));
	}	
}
print header(
	-type=>'application/json',
	-cookie=>\@cookies, 
	-charset=>$GLOBAL->{CODEPAGE},
);



print $json->encode ($result);
my $ts=time()-$ts_start;
warn "DBG: END: FUNC:$func OID:$oid TIME:$ts UA:$ENV{HTTP_USER_AGENT} COOKIE:$ENV{HTTP_COOKIE}";
