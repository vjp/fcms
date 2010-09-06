#!/usr/bin/perl -w

# $Id: viewer.pl,v 1.22 2010-09-06 19:24:39 vano Exp $

use lib "./modules/";

use cmlmain;
use strict;
use CGI  qw/param url header cookie redirect/;
use Data::Dumper;
use CGI::Carp qw /fatalsToBrowser/;
use Time::HiRes;

 


my $st=time;
start('.');
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%viewer';
$cmlcalc::ENV->{dev}=cookie('dev');
$cmlcalc::ENV->{SERVER}=$ENV{SERVER_NAME};


check_session();



my $v;
my $subdomain;
my $pathinfostr=&CGI::path_info();
if ($ENV{HTTP_HOST}=~/(.+)\..+\..+$/) {$subdomain=$1}
if ($subdomain) {
	$subdomain=~s/^www\.?//;
	(my $vid)=fastsearch ({prm=>'HOSTNAME',pattern=>$subdomain});
	my $redirectpath=&cmlcalc::p('REDIRECTPATH',$vid);
	if ($redirectpath) {
		print redirect($redirectpath);
		exit();
	} else {
		$cmlcalc::SITEVARS->{subdomain}=$subdomain;
		$cmlcalc::SITEVARS->{VHOST}->{ID}=$vid;
		$cmlcalc::SITEVARS->{VHOST}->{NAME}=$subdomain;
		$cmlcalc::SITEVARS->{VHOST}->{FULLNAME}=$ENV{HTTP_HOST};
	}	
}

my @pi=split('/',$pathinfostr);
shift @pi;
my %pathinfo=@pi;
$cmlcalc::CGIPARAM->{pathinfo}=$pathinfostr;

my $xmlmode;

unless ($pathinfo{view}) {
	 my $firstparam=shift @pi;
	 if ($firstparam=~/^(.+)\.xml$/i) {
	 	$xmlmode=1;
	 	$firstparam=$1;
	 } 
	 if ($firstparam=~/^__(.+)$/) {
	 	$cmlcalc::CGIPARAM->{tview}=$1
	 } elsif ($firstparam=~/^_(.+)$/) {
	 	$cmlcalc::CGIPARAM->{view}=$1
	 }
	 %pathinfo=@pi;
}	
for (my $i=0;$i<=$#pi;$i++) {
	$cmlcalc::CGIPARAM->{$i+1}=$pi[$i]
}
for (keys %pathinfo) {
	unless($_=~/^\d+$/) {	$
		cmlcalc::CGIPARAM->{$_} =$pathinfo{$_} 
	}
}	


for (param()) {
	next if $cmlcalc::CGIPARAM->{$_};
	my @pl=param($_);
	if ($#pl>0) { $cmlcalc::CGIPARAM->{$_}=join(';',grep {$_ ne '0'} @pl) }
	else 		    { $cmlcalc::CGIPARAM->{$_}=$pl[0] }
}
$cmlcalc::CGIPARAM->{view}=uc $cmlcalc::CGIPARAM->{view};
$cmlcalc::CGIPARAM->{tview}=uc $cmlcalc::CGIPARAM->{tview};

if (cookie('env')) {
	for (split('&',cookie('env'))) {
		(my $vn, my $vv)=split('=',$_);
		$cmlcalc::SITEVARS->{$vn}=$vv;
	}		
}	


   
$cmlcalc::SITEVARS->{BASEURL}=url(-base=>1);
$cmlcalc::SITEVARS->{FILEURL}=$cmlcalc::SITEVARS->{BASEURL}.$GLOBAL->{FILEURL};


if ($cmlcalc::SITEVARS->{lang}) {	$cmlcalc::LANGUAGE=$cmlcalc::SITEVARS->{lang} } else {$cmlcalc::LANGUAGE=$LANGS[0]}

my $qs=url(-path_info=>1,-query=>1,-relative=>1);
$qs =~ s/\?.*$//;
$qs =~ s/\/parsemethod\/.+$//;
$cmlcalc::QUERYSTRING=$ENV{'REDIRECT_URL'} || $qs;

my $cgiparam=$cmlcalc::CGIPARAM;


$cgiparam->{_MODE}='SITE';

if($cgiparam->{preparser}) {
	my $id=$cgiparam->{id};
	unless ($id) {$id=1}
	&cmlcalc::execute({id=>$id,method=>$cgiparam->{preparser}});
}	

if($cgiparam->{parsemethod}) {
	my $id=$cgiparam->{id};
	unless ($id) {$id=1}
	my $method=$cgiparam->{parsemethod};
	&cmlcalc::execute({id=>$id,method=>$method});
}	


if ($cgiparam->{tview} && $cmlmain::lmethod->{$cgiparam->{tview}.'PARSER'}->{script}){
	my $id=$cgiparam->{id};
	unless ($id) {$id=1}
	&cmlcalc::execute({id=>$id,lmethod=>$cgiparam->{tview}.'PARSER'});
}	
if ($cgiparam->{view} && $cmlmain::lmethod->{$cgiparam->{view}.'PARSER'}->{script}){
	my $id=$cgiparam->{id};
	unless ($id) {$id=1}
	&cmlcalc::execute({id=>$id,lmethod=>$cgiparam->{view}.'PARSER'});
}	




if($cgiparam->{postparser}) {
	my $id=$cgiparam->{id};
	unless ($id) {$id=1}
	&cmlcalc::execute({id=>$id,method=>$cgiparam->{postparser}});
}	




my @cookies;


my $cstr;



if ($cmlcalc::SETSITEVARS || cookie('setlang')) {
	if (cookie('setlang')) {
		$cmlcalc::SITEVARS->{lang}=cookie('setlang');
	} else {
		for (keys %{$cmlcalc::SETSITEVARS}) {
			$cmlcalc::SITEVARS->{$_}=$cmlcalc::SETSITEVARS->{$_}
		}
	}	 
	$cstr=join('&',map {"$_=$cmlcalc::SITEVARS->{$_}"} keys %{$cmlcalc::SITEVARS} );
	my $cc=cookie(-name=>'env',-value=>$cstr);
	push (@cookies,$cc);
	my $slc=cookie(-name=>'setlang',-value=>0);
	push (@cookies,$slc);
	
	
}	

if ($cmlcalc::SITEVARS->{BENCHMARK}) {
	message('ENABLE SESSION BENCHMARK');
	$cmlcalc::ENV->{BENCHMARK}=1;
}	


if ($cmlcalc::SITEVARS->{lang}) {	$cmlcalc::LANGUAGE=$cmlcalc::SITEVARS->{lang} } else {$cmlcalc::LANGUAGE=$LANGS[0]}



my $opensite=&cmlcalc::calculate({key=>'CONTENT',expr=>"p('OPENSITE')"})->{value};
my $vh=&cmlcalc::calculate({key=>'CONTENT',expr=>"p('VHOST')"})->{value};

my $stime=Time::HiRes::time();
if (!$opensite && !cookie('dev')) {
	$v=&cmlcalc::calculate({key=>'UNDERCONSTRUCT',expr=>"p('PAGETEMPLATE')"});
}elsif ($cgiparam->{view}) {
	if ($cmlcalc::SITEVARS->{subdomain} && $vh == 1) {
 		$v=&cmlcalc::calculate({id=>$cmlcalc::SITEVARS->{VHOST}->{ID},expr=>"p(VHDTEMPLATE,p(DESIGNVER))"});
		unless ($v) {
			$v=&cmlcalc::calculate({key=>'VHOSTSTARTPAGE',expr=>"p(PAGETEMPLATE)"});
	 	} 	 
 	} else {
 		$v=&cmlcalc::calculate({key=>'MAINTEMPLATE',expr=>"p(PAGETEMPLATE)", cache=>$GLOBAL->{CACHE}});
 	}	
}elsif ($cgiparam->{tview}) { 	
	
		
 		 		$v=&cmlcalc::calculate({key=>$cgiparam->{tview},expr=>"p(PAGETEMPLATE)", cache=>$GLOBAL->{CACHE}});
} else {
	 if ($cmlcalc::SITEVARS->{subdomain} && $vh == 1) {
	 	$cmlcalc::CGIPARAM->{view}='PAGE1'; 
	 	$v=&cmlcalc::calculate({id=>$cmlcalc::SITEVARS->{VHOST}->{ID},expr=>"p(VHDTEMPLATE,p(DESIGNVER))"});
	   	unless ($v) {
	 		$v=&cmlcalc::calculate({key=>'VHOSTSTARTPAGE',expr=>"p('PAGETEMPLATE')"});
	 	} 	 
	 } else {	
	 	$v=&cmlcalc::calculate({key=>'UNDERCONSTRUCTION',expr=>"p(PAGETEMPLATE)"});
	 	unless ($v->{value}) {
	 		$cmlcalc::CGIPARAM->{view}='STARTPAGE'; 
     			$v=&cmlcalc::calculate({key=>'MAINTEMPLATE',expr=>"p(PAGETEMPLATE)", cache=>$GLOBAL->{CACHE} });
     		}		
   	}  
}
my $mtime=Time::HiRes::time()-$stime;
my $lmtime=scalar gmtime($v->{lmtime} || time()).' GMT';
print header(
	-status=>$cmlcalc::ENV->{'HTTPSTATUS'} || 200,
	-type=>$xmlmode?'text/xml':'text/html',
	-cookie=>\@cookies, 
	-charset=>$GLOBAL->{CODEPAGE},
	###  incorrect-last_modified=>$lmtime,
);


if ($cmlcalc::SCRIPTOUT) { print "<script>alert('$cmlcalc::SCRIPTOUT')</script>" }
statclick($cgiparam->{_cl}) if $cgiparam->{_cl};
my $body=$v->{value};
if ($body) {
	print $body;
	benchmark($mtime) if cookie('dev');
} else       {
	errorpage()
}
viewlog();
$cmlcalc::TIMERS->{MAIN}->{sec}=time-$st;




if ($cmlcalc::SITEVARS->{TIMER}) {
	 print "<HR>";
	 print "<CENTER>TIMER</CENTER>";
	 print "OVERALL: $cmlcalc::TIMERS->{MAIN}->{sec} sec <br>";
	 print "LOW TREE: $cmlcalc::TIMERS->{LOWTREE}->{sec} sec $cmlcalc::TIMERS->{LOWTREE}->{count} times <br>";
	 print "CHECK LOAD: $cmlcalc::TIMERS->{CHECKLOAD}->{sec} sec $cmlcalc::TIMERS->{CHECKLOAD}->{count} times <br>";
	 print "<HR>";
}	





sub errorpage
{
 my $v=&cmlcalc::calculate({key=>'ERRORPAGE',expr=>"p('PAGETEMPLATE')"});
 my $body=$v->{value};
 if ($body) {print $body}
 else       {print "Ошибка вывода !!!!"}
}


sub benchmark
{
	my ($mtime)=@_;
	print "<br/>TIME : $mtime";
}
