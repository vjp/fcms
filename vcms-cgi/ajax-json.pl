#!/usr/bin/perl -w

# $Id: ajax-json.pl,v 1.7 2010-05-04 20:01:46 vano Exp $

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
$cmlcalc::CGIPARAM=decode_json($data);
$cmlcalc::CGIPARAM->{_MODE}='USERAJAX';
my $result=execute({method=>$func});
if (ref $result ne 'HASH') {
	$result=({
		status=>0,
		message=>"execute error. method:$func error:$result",
	});
}
print $json->encode ($result);

