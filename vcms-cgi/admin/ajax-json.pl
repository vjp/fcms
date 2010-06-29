#!/usr/bin/perl -w

# $Id: ajax-json.pl,v 1.7 2010-06-29 05:59:28 vano Exp $

use strict;
no strict "refs";

use lib "../modules/";
use Data::Dumper;
use JSON::PP;


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
};   


start('..');
print "Content-Type: application/json; charset=$GLOBAL->{CODEPAGE}\n\n";

my $data=param('data');
my $func=param('func');
my $json = new JSON::PP;
$cmlcalc::ENV->{SERVER}=$ENV{SERVER_NAME};
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%admin';
if ($AJAX_FUNCS->{$func}) {
	my $subname="cmlajax::ajax_$func";
	my $r=decode_json($data);
	$cmlcalc::CGIPARAM=decode_json($data);
	$cmlcalc::CGIPARAM->{_MODE}='ADMINAJAX';
	my $result=&$subname($r);
	print $json->encode ($result);
} else {
	my $rstr="Íåïğàâèëüíàÿ ôóíêöèÿ $func";
	print $json->encode ({result=>$rstr});
}	

