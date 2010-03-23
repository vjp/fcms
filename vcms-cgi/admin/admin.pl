#!/usr/bin/perl -w


use lib "../modules/";

use cmlmain;

use CGI  qw/param url header cookie/;
use Data::Dumper;
use CGI::Carp qw (fatalsToBrowser);
use Time::HiRes qw (time);
use strict;
 



start('..');

my $v;




for (param()) {
	my @pl=param($_);
	if ($#pl>0) { $cmlcalc::CGIPARAM->{$_}=join(';',grep {$_ ne '0'} @pl) }
	else 		    { $cmlcalc::CGIPARAM->{$_}=$pl[0] }
}

$cmlcalc::CGIPARAM->{_MODE}='ADMIN';
$cmlcalc::ENV->{NOFRAMES}=&cmlcalc::p('NOFRAMES',&cmlcalc::id('CMSDESIGN'));
$cmlcalc::ENV->{BENCHMARK}=&cmlcalc::p('BENCHMARK',&cmlcalc::id('CMSDESIGN'));
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%admin';
$cmlcalc::ENV->{dev}=cookie('dev');

message("ENABLE TAG BENCHMARKING") if $cmlcalc::ENV->{BENCHMARK}; 

if (cookie('env')) {
	for (split('&',cookie('env'))) {
		(my $vn, my $vv)=split('=',$_);
		$cmlcalc::SITEVARS->{$vn}=$vv;
	}		
}	
if ($cmlcalc::SITEVARS->{lang}) {	$cmlcalc::LANGUAGE=$cmlcalc::SITEVARS->{lang} } else {$cmlcalc::LANGUAGE=$LANGS[0]}



my $qs=url(-relative=>1,-path_info=>1,-query=>1,);

my $xs= $qs;

$qs=~s/;/&/g;
$qs =~ s/\&parsemethod=.+$//;
$cmlcalc::QUERYSTRING=$qs;


if(param('parsemethod')) {
	my $id;
	
	if (param('parseid')) {$id=param('parseid')}
	elsif (param('id')) {$id=param('id')}
	
	my $method=param('parsemethod');
	&cmlcalc::execute({id=>$id,method=>$method})
}	

my @cookies;

if ($cmlcalc::SETSITEVARS) {
	for (keys %{$cmlcalc::SETSITEVARS}) {$cmlcalc::SITEVARS->{$_}=$cmlcalc::SETSITEVARS->{$_}} 
	my $cstr=join('&',map {"$_=$cmlcalc::SITEVARS->{$_}"} keys %{$cmlcalc::SITEVARS} );
	my $cc=cookie(-name=>'env',-value=>$cstr);
	push (@cookies,$cc);
}	
if ($cmlcalc::SITEVARS->{lang}) {	$cmlcalc::LANGUAGE=$cmlcalc::SITEVARS->{lang} } else {$cmlcalc::LANGUAGE=$LANGS[0]}

print header(-type=>'text/html',-cookie=>\@cookies, -charset=>$GLOBAL->{CODEPAGE});
if ($cmlcalc::SCRIPTOUT) { print "<script>alert('$cmlcalc::SCRIPTOUT')</script>" }

my $key;

if (param('page') && $cmlmain::lmethod->{param('page').'PARSER'}->{script}){
	my $id=param('id');
	unless ($id) {$id=1}
	my $tt=time();
	&cmlcalc::execute({id=>$id,lmethod=>param('page').'PARSER'});
	my $etime=time()-$tt;
	message ("PREPARSER EVAL TIME $etime") if $cmlcalc::ENV->{BENCHMARK};
}



if (param('menu')) {
	$v=&cmlcalc::calculate({key=>'BASEMENU',expr=>'p(PAGETEMPLATE)'});
}	elsif (param('body')) {
	$v=&cmlcalc::calculate({key=>'BASEMAIN',expr=>'p(PAGETEMPLATE)'});
} elsif (param('view')) {
 	$v=&cmlcalc::calculate({key=>param('view'),expr=>'p(PAGETEMPLATE)'});
}else {
	$cmlcalc::CGIPARAM->{pagemenu}='BASEMENU' unless param('pagemenu');
	$cmlcalc::CGIPARAM->{page}='BASEMAIN' unless param('page');	
 	$v=&cmlcalc::calculate({key=>'MAINCMSTEMPL',expr=>"p('PAGETEMPLATE')"});
}

viewlog();

my $body=$v->{value};
if ($body) {print $body}
else       {errorpage()}



sub errorpage
{
 my $v=&cmlcalc::calculate({key=>'ERRORPAGE',expr=>"p('PAGETEMPLATE')"});
 my $body=$v->{value};
 if ($body) {print $body}
 else       {print "Ошибка вывода !!!!"}
}



