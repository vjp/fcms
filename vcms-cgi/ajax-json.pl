#!/usr/bin/perl -w


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
my $r=decode_json($data);
my $result=execute({method=>$func});
if (ref $result ne 'HASH') {
	$result=({status=>"execute error. method:$func"});
}
print $json->encode ($result);

