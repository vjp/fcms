#!/usr/bin/perl -w

# $Id: ajax-json.pl,v 1.6 2010-03-30 20:51:07 vano Exp $

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
	console=>1,
	setvalue=>1,
	editmethod=>1,
	
};   


start('..');
print "Content-Type: application/json; charset=$GLOBAL->{CODEPAGE}\n\n";

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

