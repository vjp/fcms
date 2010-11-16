#!/usr/bin/perl -w

# $Id: user.pl,v 1.15 2010-09-23 03:19:01 vano Exp $

use lib "../modules/";

use cmlmain;

use CGI  qw/param url header cookie/;
use Data::Dumper;
use CGI::Carp qw /fatalsToBrowser/;
use Time::HiRes qw (time);

open(STDERR, ">/dev/null"); 



start('..');

my $v;

for (param()) {	$cmlcalc::CGIPARAM->{$_}=join(';',(param($_))) }
$cmlmain::GLOBAL->{CACHE}=0;
$cmlcalc::CGIPARAM->{_MODE}='USER';
$cmlcalc::CGIPARAM->{_ROOT}='/user/';
$cmlcalc::ENV->{NOFRAMES}=&cmlcalc::p('NOFRAMES',&cmlcalc::id('CMSDESIGNUSER'));;
$cmlcalc::ENV->{BENCHMARK}=&cmlcalc::p(USERBENCHMARK,&cmlcalc::id(CMSDESIGN));
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%user';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};
$cmlcalc::ENV->{READONLY}=$cmlcalc::CGIPARAM->{readonly};

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
	$cstr=join('&',map {"$_=$cmlcalc::SITEVARS->{$_}"} keys %{$cmlcalc::SITEVARS} );
	my $cc=cookie(-name=>'env',-value=>$cstr);
	push (@cookies,$cc);
}	
if ($cmlcalc::SITEVARS->{lang}) {	$cmlcalc::LANGUAGE=$cmlcalc::SITEVARS->{lang} } else {$cmlcalc::LANGUAGE=$LANGS[0]}

if (param('csv')) {
	print header(
		-type=>'text/csv',
		-charset=>$GLOBAL->{CODEPAGE},
		-attachment=>'export.csv',
	);
} else {
	print header(-type=>'text/html',-cookie=>\@cookies, -charset=>$GLOBAL->{CODEPAGE});
}	


if ($cmlcalc::SCRIPTOUT) { print "<script>alert('$cmlcalc::SCRIPTOUT')</script>" }

my $key;

my $prm=param('prm') || 'PAGETEMPLATE';
if (param('menu')) {
	$v=&cmlcalc::calculate({key=>'USERMENU',expr=>"p($prm)"});
}	elsif (param('body') && param('body') ne 'NULL') {
	$v=&cmlcalc::calculate({key=>$cmlcalc::ENV->{NOFRAMES}?'USERCMSTEMPLNOFRAMES':'USERMAIN',expr=>"p($prm)"});
} elsif (param('view')) {
 	$v=&cmlcalc::calculate({
 		key=>param('view'),
 		expr=>"p($prm)",
 		csv=>param('csv'),
 	});
}else {
	$cmlcalc::CGIPARAM->{pagemenu}='USERMENU' unless param('pagemenu');
	$cmlcalc::CGIPARAM->{page}='USERMAIN' unless param('page');
	if (param('mbframe') && !param('framebody')) {
		$v=&cmlcalc::calculate({key=>'SPLASH',expr=>"p($prm)"});
	} else {	
		$cmlcalc::CGIPARAM->{body}='USERSTARTPAGE' if $cmlcalc::ENV->{NOFRAMES};
 		$v=&cmlcalc::calculate({key=>$cmlcalc::ENV->{NOFRAMES}?'USERCMSTEMPLNOFRAMES':'USERCMSTEMPL',expr=>"p($prm)"});
	}	
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


