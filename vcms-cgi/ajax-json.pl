#!/usr/bin/perl -w

# $Id: ajax-json.pl,v 1.11 2010-05-23 21:15:06 vano Exp $

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
$cmlcalc::CGIPARAM=$prms if ref $prms eq 'HASH';
$cmlcalc::CGIPARAM->{_MODE}='USERAJAX';
$cmlcalc::ENV->{SERVER}=$ENV{SERVER_NAME};
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

