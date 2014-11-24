#!/usr/bin/perl
use strict;
use lib "../modules/";

use cmlmain;

use CGI  qw/param url header cookie redirect/;
use Data::Dumper;
use CGI::Carp qw /fatalsToBrowser/;
use Time::HiRes qw (time);

my $ts_start=time();

start('..');

my $v;

if (param('httplogout')) {
	print redirect("http://$ENV{HTTP_HOST}/user");
	exit();
}

for (param()) {	$cmlcalc::CGIPARAM->{$_}=join(';',(param($_))) }
$cmlmain::GLOBAL->{CACHE}=0;
$cmlcalc::CGIPARAM->{_MODE}='USER';
$cmlcalc::CGIPARAM->{_ROOT}='/user/';
$cmlcalc::ENV->{NOFRAMES}=&cmlcalc::p('NOFRAMES',&cmlcalc::id('CMSDESIGNUSER'));;
$cmlcalc::ENV->{BENCHMARK}=&cmlcalc::p('USERBENCHMARK',&cmlcalc::id('CMSDESIGN'));
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%user';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};
$cmlcalc::ENV->{READONLY}=$cmlcalc::CGIPARAM->{readonly};
$cmlcalc::ENV->{AJAXURL}='/cgi-bin/user/ajax-json.pl';
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
warn "DBG: START: USER:$cmlcalc::ENV->{USER}  QUERY:$qs";
$cmlcalc::QUERYSTRING=$qs;
$cmlcalc::ENV->{QUERYSTRING}=$qs;
$cmlcalc::ENV->{URL}=$ENV{REQUEST_URI};

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

if (param('csv')||param('csvcontent')) {
	print header(
		-type=>'text/csv',
		-charset=>$GLOBAL->{CODEPAGE},
		-attachment=>'export.csv',
	);
} else {
	push(@cookies,cookie(-name=>$_,-value=>$cmlcalc::COOKIE->{$_})) for keys %$cmlcalc::COOKIE;
	print header(-type=>'text/html',-cookie=>\@cookies, -charset=>$GLOBAL->{CODEPAGE});
}	


if ($cmlcalc::SCRIPTOUT) { print "<script>alert('$cmlcalc::SCRIPTOUT')</script>" }

my $key;
my $its=time()-$ts_start;

my $prm=param('prm') || 'PAGETEMPLATE';
if (param('menu')) {
	$v=&cmlcalc::calculate({key=>'USERMENU',expr=>"p($prm)"});
}	elsif (param('body') && param('body') ne 'NULL') {
	$v=&cmlcalc::calculate({
		key=>$cmlcalc::ENV->{NOFRAMES}?'USERCMSTEMPLNOFRAMES':'USERMAIN',
		expr=>"p($prm)",
		csv=>param('csv'),
	});
} elsif (param('view')) {
 	$v=&cmlcalc::calculate({
 		key=>param('view'),
 		expr=>"p($prm)",
 		csv=>param('csv'),
 	});
} elsif (param('popupview')) {
	$v=&cmlcalc::calculate({
		key=>$cmlmain::GLOBAL->{NEWSTYLE}?'BSPOPUP':'BASEPOPUP',
		expr=>"p($prm)",
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

my $ts=time()-$ts_start;
warn sprintf("DBG: END: USER:$cmlcalc::ENV->{USER}  QUERY:$qs TIME:%.3f  INIT:%.3f DBRV:(%.3f:%d) DBLT (%.3f:%d) DBBL (%.3f:%d) CL (%.3f:%d) DBBR (%.3f:%d) FP (%.3f:%d) TP (%.3f:%d) IC (%.3f:%d) CC (%.3f:%d) ET (%.3f:%d) FS (%.3f:%d)\n",
	$ts,$its,
	$GLOBAL->{ot},$GLOBAL->{otc},
	$cmlcalc::TIMERS->{LOWTREE}->{sec},$cmlcalc::TIMERS->{LOWTREE}->{count},
	$GLOBAL->{timers}->{bl},$GLOBAL->{timers}->{blc},
	$cmlcalc::TIMERS->{CHECKLOAD}->{sec},$cmlcalc::TIMERS->{CHECKLOAD}->{count},
	$GLOBAL->{timers}->{br},$GLOBAL->{timers}->{brc},
	$GLOBAL->{timers}->{fp},$GLOBAL->{timers}->{fpc},
	$GLOBAL->{timers}->{tp},$GLOBAL->{timers}->{tpc},	
	$GLOBAL->{timers}->{ic},$GLOBAL->{timers}->{icc},	
	$GLOBAL->{timers}->{cc},$GLOBAL->{timers}->{ccc},
    $GLOBAL->{timers}->{et},$GLOBAL->{timers}->{etc},
    $GLOBAL->{timers}->{fs},$GLOBAL->{timers}->{fsc},			
);

sub errorpage
{
 my $v=&cmlcalc::calculate({key=>'ERRORPAGE',expr=>"p('PAGETEMPLATE')"});
 my $body=$v->{value};
 if ($body) {print $body}
 else       {print "Ошибка вывода !!!!"}
}


