#!/usr/bin/perl -w

# $Id: ajax.pl,v 1.9 2010-03-17 22:24:27 vano Exp $

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
print "Content-Type: text/html; charset: $GLOBAL->{CODEPAGE}\n\n";
my @input = param('args');
my $func= lc param('func');
if ($AJAX_FUNCS->{$func}) {
	my $subname="cmlajax::ajax_$func";
	print "---> $GLOBAL->{CODEPAGE} ".&$subname(@input);
} else {
	print "incorrect func : $func";
}	
