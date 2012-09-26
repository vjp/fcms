#!/usr/bin/perl -w



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
use vCMS;

use vars qw ($AJAX_FUNCS);
   
   
$AJAX_FUNCS={
	console=>1,
	setvalue=>1,
	editmethod=>1,
	
};   


start('..');
print "Content-Type: application/json; charset=$GLOBAL->{CODEPAGE}\n\n";
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%vmcs';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");
$cmlcalc::ENV->{dev}=cookie('dev');
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};

my $data=param('data');
my $func=param('func');
my $json = new JSON::PP;
if ($AJAX_FUNCS->{$func}) {
	my $subname="cmlajax::ajax_$func";
	my $r=decode_json($data);
	my $result=&$subname($r);
	print $json->encode ($result);
} else {
	my $rstr="Íåïğàâèëüíàÿ ôóíêöèÿ $func";
	print $json->encode ({result=>$rstr});
}	

