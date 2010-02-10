#!/usr/bin/perl -w

use strict;
no strict "refs";

use lib "../modules/";
use Data::Dumper;


use cmlmain;
use cmlcalc;
use CGI  qw/:standard/;     


use vars qw ($AJAX_FUNCS);
   
   
$AJAX_FUNCS={
	setvalue=>1,
};   
start('..');
print "Content-type: text/plain\n\n";
my @input = param('args');
my $func= lc param('func');
if ($AJAX_FUNCS->{$func}) {
	my $subname="ajax_$func";
	my $result=&$subname(@input);
	print "success func : $func ($result)";
} else {
	print "incorrect func : $func";
}	


sub ajax_setvalue ($$$)
{
	my ($objid,$prm,$value)=@_;
	return setvalue({id=>$objid,prm=>$prm,value=>$value});
}