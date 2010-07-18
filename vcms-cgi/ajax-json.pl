#!/usr/bin/perl -w

# $Id: ajax-json.pl,v 1.13 2010-07-18 23:13:10 vano Exp $

use strict;
use lib "./modules/";
use JSON::PP;


use cmlmain;
use cmlcalc;
use cmlajax;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;

start('.');

my $json = new JSON::PP;
print "Content-Type: application/json; charset=$GLOBAL->{CODEPAGE}\n\n";
my $data=param('data') || $json->encode ([]);
my $func=param('func');
check_session();


my $prms=decode_json($data);
if (ref $prms eq 'HASH') {
	unless ($GLOBAL->{CODEPAGE} eq 'utf-8') {
		$prms->{$_} = Encode::encode('cp1251',$prms->{$_}) for keys %$prms;
	}	
	$cmlcalc::CGIPARAM=$prms;
}	



$cmlcalc::CGIPARAM->{_MODE}='USERAJAX';
$cmlcalc::ENV->{SERVER}=$ENV{SERVER_NAME};
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%user';
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

