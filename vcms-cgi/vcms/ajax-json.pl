#!/usr/bin/perl

use strict;
no strict "refs";

use lib "../modules/";
use lib "../../../../perl/usr/lib/perl5/x86_64-linux-thread-multi";


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
	setconf=>1,
	sethtaccess=>1,
};   


start('..');


$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%vmcs';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");
$cmlcalc::ENV->{dev}=cookie('dev');
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};

my $data=param('data');
my $func=param('func');
my $json = new JSON::PP;
my $response_text;
if ($AJAX_FUNCS->{$func}) {
	my $subname="cmlajax::ajax_$func";
	my $r=decode_json($data);
	my $result=&$subname($r);
	$response_text=$json->encode ($result);
} else {
	my $rstr="Неправильная функция $func";
	$response_text=$json->encode ({result=>$rstr});
}	

my @cookies;
push(@cookies,cookie(-name=>$_,-value=>$cmlcalc::COOKIE->{$_})) for keys %$cmlcalc::COOKIE;
print header(
	-type=>'application/json',
	-cookie=>\@cookies, 
	-charset=>$GLOBAL->{CODEPAGE},
);
print $response_text;
