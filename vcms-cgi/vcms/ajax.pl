#!/usr/bin/perl -w

use strict;
no strict "refs";

use lib "../modules/";
use Data::Dumper;


use cmlmain;
use cmlcalc;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;
use Encode;

use vars qw ($AJAX_FUNCS);
   
   
$AJAX_FUNCS={
	setvalue=>1,
};   
start('..');
print "Content-Type: text/html; charset=windows-1251\n\n";
my @input = param('args');
my $func= lc param('func');
if ($AJAX_FUNCS->{$func}) {
	my $subname="ajax_$func";
	print &$subname(@input);
} else {
	print "incorrect func : $func";
}	


sub ajax_setvalue ($$$$$)
{
	my ($objid,$objuid,$prm,$lang,$value)=@_;
       	my $evalue = Encode::encode('cp1251',Encode::decode('utf8',$value));
	my $status=setvalue({id=>$objid,uid=>$objuid,prm=>$prm,lang=>$lang,value=>$evalue});
	return $status?"Изменения сохранены":'Ошибка сохранения изменений';
}