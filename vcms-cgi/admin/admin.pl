#!/usr/bin/perl
use strict;
use lib "../modules/";

use cmlmain;

use CGI  qw/param url header cookie/;
use Data::Dumper;
use CGI::Carp qw (fatalsToBrowser);
use Time::HiRes qw (time);

 
my $ts_start=time();
start('..');

my $v;


for (param()) {
	my @pl=param($_);
	if ($#pl>0) { $cmlcalc::CGIPARAM->{$_}=join(';',grep {$_ ne '0'} @pl) }
	else 		    { $cmlcalc::CGIPARAM->{$_}=$pl[0] }
}
$cmlmain::GLOBAL->{CACHE}=0;
$cmlcalc::CGIPARAM->{_MODE}='ADMIN';
$cmlcalc::CGIPARAM->{_ROOT}='/admin/';
$cmlcalc::ENV->{NOFRAMES}=&cmlcalc::p('NOFRAMES',&cmlcalc::id('CMSDESIGNADMIN'));
$cmlcalc::ENV->{BENCHMARK}=&cmlcalc::p('BENCHMARK',&cmlcalc::id('CMSDESIGN'));
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%admin';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");
$cmlcalc::ENV->{dev}=cookie('dev');
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



my $qs=url(-relative=>1,-path_info=>1,-query=>1);

my $xs= $qs;

$qs=~s/;/&/g;
$qs =~ s/\&parsemethod=.+$//;
$cmlcalc::QUERYSTRING=$qs;
$cmlcalc::ENV->{QUERYSTRING}=$qs;
$cmlcalc::ENV->{URL}=$ENV{REQUEST_URI};
warn "DBG: START: USER:$cmlcalc::ENV->{USER}  QUERY:$qs";
my $its=time()-$ts_start;

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

if (param('page') && $cmlmain::lmethod->{param('page').'PARSER'}->{script}){
	my $id=param('id');
	unless ($id) {$id=1}
	my $tt=time();
	&cmlcalc::execute({id=>$id,lmethod=>param('page').'PARSER'});
	my $etime=time()-$tt;
	message ("PREPARSER EVAL TIME $etime") if $cmlcalc::ENV->{BENCHMARK};
}


my $prm=param('prm') || 'PAGETEMPLATE';
if (param('menu')) {
	$v=&cmlcalc::calculate({key=>'BASEMENU',expr=>"p($prm)"});
}	elsif (param('body') && param('body') ne 'NULL') {
	$v=&cmlcalc::calculate({
		key=>'BASEMAIN',
		expr=>"p($prm)",
		csv=>param('csv'),
	});
} elsif (param('view')) {
	
 	$v=&cmlcalc::calculate({
 		key=>param('view'),
 		expr=>"p($prm)",
 		csv=>param('csv'),
 	});
}else {
	$cmlcalc::CGIPARAM->{pagemenu}='BASEMENU' unless param('pagemenu');
	$cmlcalc::CGIPARAM->{page}='BASEMAIN' unless param('page');	
	if (param('mbframe') && !param('framebody')) {
		$v=&cmlcalc::calculate({key=>'SPLASH',expr=>"p($prm)"});
	} elsif ($cmlcalc::ENV->{NOFRAMES}) {	
		$v=&cmlcalc::calculate({key=>'MAINCMSTEMPLNOFRAMES',expr=>"p($prm)"});
	} else {
	 	$v=&cmlcalc::calculate({key=>'MAINCMSTEMPL',expr=>"p($prm)"});
	}	
}

viewlog();

my $body=$v->{value};
if ($body) {print $body}
else       {errorpage()}

my $ts=time()-$ts_start;
warn sprintf("DBG: END: USER:$cmlcalc::ENV->{USER}  QUERY:$qs TIME:%.3f  INIT:%.3f DBRV:(%.3f:%d) DBLT (%.3f:%d) DBBL (%.3f:%d) CL (%.3f:%d) DBBR (%.3f:%d) FP (%.3f:%d) TP (%.3f:%d) IC (%.3f:%d)\n",
	$ts,$its,
	$GLOBAL->{ot},$GLOBAL->{otc},
	$cmlcalc::TIMERS->{LOWTREE}->{sec},$cmlcalc::TIMERS->{LOWTREE}->{count},
	$GLOBAL->{timers}->{bl},$GLOBAL->{timers}->{blc},
	$cmlcalc::TIMERS->{CHECKLOAD}->{sec},$cmlcalc::TIMERS->{CHECKLOAD}->{count},
	$GLOBAL->{timers}->{br},$GLOBAL->{timers}->{brc},
	$GLOBAL->{timers}->{fp},$GLOBAL->{timers}->{fpc},
	$GLOBAL->{timers}->{tp},$GLOBAL->{timers}->{tpc},	
	$GLOBAL->{timers}->{ic},$GLOBAL->{timers}->{icc},	
);


sub errorpage
{
 my $v=&cmlcalc::calculate({key=>'ERRORPAGE',expr=>"p('PAGETEMPLATE')"});
 my $body=$v->{value};
 if ($body) {print $body}
 else       {print "Ошибка вывода !!!!"}
}



