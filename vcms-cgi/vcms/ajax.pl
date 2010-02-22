#!/usr/bin/perl -w

use strict;
no strict "refs";

use lib "../modules/";
use Data::Dumper;


use cmlmain;
use cmlcalc;
use cmlajax;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;
use Encode;

use vars qw ($AJAX_FUNCS);
   
   
$AJAX_FUNCS={
	setvalue=>1,
	editmethod=>1,
	editlmethod=>1,
	addobject=>1,
	deleteobject=>1,
	evalscript=>1,
};   

start('..');
print "Content-Type: text/html; charset=windows-1251\n\n";
my @input = param('args');
my $func= lc param('func');
if ($AJAX_FUNCS->{$func}) {
	my $subname="cmlajax::ajax_$func";
	print &$subname(@input);
} else {
	print "incorrect func : $func";
}	
