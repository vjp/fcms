#!/usr/bin/perl

use lib "./modules/";

use cmlmain;
use strict;
use CGI  qw/param url header cookie redirect/;
use Data::Dumper;
use CGI::Carp qw /fatalsToBrowser/;
use Time::HiRes qw (time);
use vCMS;
 


my $st=time;
start('.');
my $its=time-$st;
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%viewer';
$cmlcalc::ENV->{dev}=cookie('dev');
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};
$cmlcalc::ENV->{'HTTPSTATUS'}=200;

check_session();



my $v;



my $subdomain;
if ($ENV{HTTP_HOST}=~/(.+)\..+\..+$/) {
	$subdomain=$1;
	$subdomain=~s/^www\.?//;
}
if ($subdomain) {
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
		
		$cmlcalc::ENV->{HOSTID}=$vid;
	}	
}

my $pathinfostr=&CGI::path_info();
my @pi=split('/',$pathinfostr);
shift @pi;
my %pathinfo=@pi;
$cmlcalc::CGIPARAM->{pathinfo}=$pathinfostr;

my $xmlmode;
my $csvmode;
my $mswordmode;
unless ($pathinfo{view}) {
	 my $firstparam=shift @pi;
	 if ($firstparam) {
	 	if ($firstparam=~/^(.+)\.xml$/i) {
	 		$xmlmode=1;
	 		$firstparam=$1;
	 	} elsif ($firstparam=~/^(.+)\.csv$/i) {
	 		$csvmode=1;
	 		$firstparam=$1;
	 	} elsif ($firstparam=~/^(.+)\.mswordhtml$/i) {
	 		$mswordmode=1;
	 		$firstparam=$1;
	 	}
	 	 
	 	if ($firstparam=~/^__(.+)$/) {
	 		$cmlcalc::CGIPARAM->{tview}=$1
	 	} elsif ($firstparam=~/^_(.+)$/) {
	 		$cmlcalc::CGIPARAM->{view}=$1
	 	}
	 }	
	 %pathinfo=@pi;
}	
for (my $i=0;$i<=$#pi;$i++) {
	$cmlcalc::CGIPARAM->{$i+1}=$pi[$i];
	$cmlcalc::CGIPARAM->{page}=$pi[$i+1] if $pi[$i] eq 'page';
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

$cmlcalc::ENV->{prevpage}=$cmlcalc::CGIPARAM->{page}-1 if $cmlcalc::CGIPARAM->{page};
$cmlcalc::ENV->{MOBILE_USER_AGENT}=1 if $cmlcalc::CGIPARAM->{forcemobile};


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
$qs ||=$ENV{'REQUEST_URI'};
$cmlcalc::QUERYSTRING=$ENV{'REQUEST_URI'} || $qs;
$cmlcalc::ENV->{'QUERYSTRING'}=$cmlcalc::QUERYSTRING;

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

my $view=$cgiparam->{view} || $cgiparam->{tview};
warn "DBG: START: VIEW:$view URI:$qs";
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
$ENV{SERVER_NAME}=~s/^www\.//;
$cmlcalc::ENV->{'SITEURI'}="http://$ENV{SERVER_NAME}";
my $dom_objid=$GLOBAL->{MULTIDOMAIN}?cmlcalc::id("DOMAIN_$ENV{SERVER_NAME}"):0;
my $dom_vhost=$dom_objid?cmlcalc::p('DOMAINSTARTPAGE',$dom_objid) eq &cmlcalc::id('VHOSTSDESIGN'):0;
$cmlcalc::SITEVARS->{VHOST}->{ID}=&cmlcalc::p('DOMAINPRMVALUE',$dom_objid) if $dom_vhost;
$cmlcalc::ENV->{HOSTID}=$cmlcalc::SITEVARS->{VHOST}->{ID} if $dom_vhost;
my $stime=Time::HiRes::time();
my $HTTPSTATUS=$cmlcalc::ENV->{'HTTPSTATUS'};
my $CACHEFLAG=$HTTPSTATUS==200?$GLOBAL->{CACHE}:0;
if (!$opensite && !cookie('dev')) {
	$v=&cmlcalc::calculate({key=>'UNDERCONSTRUCT',expr=>"p('TMPL')"});
} elsif ($cgiparam->{redir}) {	
	o($cgiparam->{rid})->Inc($cgiparam->{rprm}) if $cgiparam->{rid} && $cgiparam->{rprm};
	o($cgiparam->{rid})->e($cgiparam->{rmtd}) if $cgiparam->{rid} && $cgiparam->{rmtd};
	print redirect($cgiparam->{redir});
	exit();
}elsif ($cgiparam->{view}) {
	if ($dom_vhost || ($cmlcalc::SITEVARS->{subdomain} && $vh == 1)) {
 		$v=&cmlcalc::calculate({id=>$cmlcalc::SITEVARS->{VHOST}->{ID},expr=>"p(VHDTEMPLATE,p(DESIGNVER))"});
		unless ($v) {
			$v=&cmlcalc::calculate({key=>'VHOSTSTARTPAGE',expr=>"p(TMPL)"});
	 	} 	 
 	} else {
 		$v=&cmlcalc::calculate({key=>'MAINTEMPLATE',expr=>"p(TMPL)", cache=>$CACHEFLAG});
 	}	
}elsif ($cgiparam->{tview}) { 	
 		 		$v=&cmlcalc::calculate({key=>$cgiparam->{tview},expr=>"p(TMPL)", cache=>$CACHEFLAG});
}elsif ($cgiparam->{fview}) { 	
 		 		$v=&cmlcalc::calculate({id=>$cgiparam->{id},expr=>"p($cgiparam->{fview})"});
 		 		if ($v->{value}) {
					print header(
						-type=>'application/octet-stream',
						-attachment=>$v->{value},
					);
					my $buf;
					open (FH,"<$GLOBAL->{WWWPATH}/data/$v->{value}");
					read (FH,$buf,-s FH);
					close(FH); 
					print $buf;
					exit;
 		 		} else {
 		 			$v=&cmlcalc::calculate({key=>'ERROR404',expr=>"p('TMPL')"});
 		 		}	
} else {
	 	if ($dom_vhost || ($cmlcalc::SITEVARS->{subdomain} && $vh == 1)) {
	 		$cmlcalc::CGIPARAM->{view}='PAGE1'; 
	 		$v=&cmlcalc::calculate({id=>$cmlcalc::SITEVARS->{VHOST}->{ID},expr=>"p(VHDTEMPLATE,p(DESIGNVER))"});
	   		unless ($v) {
	 			$v=&cmlcalc::calculate({key=>'VHOSTSTARTPAGE',expr=>"p('TMPL')"});
	 		} 	 
	 	} else {	
	 		$v=&cmlcalc::calculate({key=>'UNDERCONSTRUCTION',expr=>"p(TMPL)"});
	 		unless ($v->{value}) {
	 			if (vCMS::Config::Get('separate_startpage')) {
	 				$v=&cmlcalc::calculate({key=>'STARTPAGE',expr=>"p(TMPL)", cache=>$CACHEFLAG });
	 			} else {
	 				$cmlcalc::CGIPARAM->{view}='STARTPAGE';
	 				if ($dom_objid) {
	 					my $t_key=&cmlcalc::p('_KEY',&cmlcalc::p('DOMAINSTARTPAGE',$dom_objid));
	 					my $t_prm=&cmlcalc::p('DOMAINPRMNAME',$dom_objid);
	 					my $t_val=&cmlcalc::p('DOMAINPRMVALUE',$dom_objid);
	 					$cmlcalc::CGIPARAM->{$t_prm}=$t_val;
	 					$cmlcalc::CGIPARAM->{view}=$t_key;
	 				}
     				$v=&cmlcalc::calculate({key=>'MAINTEMPLATE',expr=>"p(TMPL)", cache=>$CACHEFLAG });
	 			}	
     		}		
   		}  
}
my $mtime=Time::HiRes::time()-$stime;
my $lmtime=scalar gmtime($v->{lmtime} || time()).' GMT';




my $charset=$xmlmode?'utf-8':$GLOBAL->{CODEPAGE};

for my $cookiename (keys %$cmlcalc::COOKIE) {
	if (ref $cmlcalc::COOKIE->{$cookiename} eq 'HASH') {
		my $ck;
		$ck->{name}=$cookiename;
		$ck->{$_}=$cmlcalc::COOKIE->{$cookiename}->{$_} for keys %{$cmlcalc::COOKIE->{$cookiename}};
		push(@cookies,cookie($ck));	
	} else {
		push(@cookies,cookie(-name=>$cookiename,-value=>$cmlcalc::COOKIE->{$cookiename}));
	}	
}

$HTTPSTATUS=$cmlcalc::ENV->{'HTTPSTATUS'};
warn "status ---".$HTTPSTATUS if $ENV{MOD_PERL};

if ($csvmode) {
	print header(
		-type=>'text/csv',
		-charset=>$GLOBAL->{CODEPAGE},
		-attachment=>'export.csv',
	);
} elsif ($mswordmode) {
	print header(
		-type=>'application/octet-stream',
		-attachment=>'export.mswordhtml',
	);	
} else {
	if ($ENV{MOD_PERL} && $HTTPSTATUS ne '200') {
		
		#use Apache2::RequestUtil;
		#print Apache2::RequestUtil::get_status_line($HTTPSTATUS);
		#print header(
		#	-type=>$xmlmode?'text/xml':'text/html',
		#	-cookie=>\@cookies, 
		#	-charset=>$charset,
		#);
		#my $r = $main::cgi->r;
		#print Apache2::RequestUtil::get_status_line($HTTPSTATUS);
    	#$r->err_headers_out();
   		
    	#return  Apache2::Const::NOT_FOUND;    	
		warn "mod perl $HTTPSTATUS";
 		print <<____END;
Status: 404 Not Found
Content-Length: 0

____END
    	ModPerl::Util::exit();
		 
          
	} else { 
	
	
		print header(
			-status=>$HTTPSTATUS,
			-type=>$xmlmode?'text/xml':'text/html',
			-cookie=>\@cookies, 
			-charset=>$charset,
		);
	}

}

if ($cmlcalc::SCRIPTOUT) { print "<script>alert('$cmlcalc::SCRIPTOUT')</script>" }
statclick($cgiparam->{_cl},$cgiparam->{_clobjid},$cgiparam->{_clurl}) if $cgiparam->{_cl};
my $body=$v->{value};
if ($xmlmode && $GLOBAL->{CODEPAGE} ne 'utf-8') {
		$body=Encode::encode('utf-8',Encode::decode($GLOBAL->{CODEPAGE},$body));
}
stat_injection (time-$st,\$body,$v->{cached});

if ($body) {
	print $body;
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
my $cached_stat=$v->{cached}?1:0;
my $cstr=$cached_stat?"(CACHED)":"(NOT CACHED $GLOBAL->{timers}->{tcc}L)";
warn "DBG: END:  VIEW:$view URI:$qs TIME:$cmlcalc::TIMERS->{MAIN}->{sec} UA:$ENV{HTTP_USER_AGENT} $cstr";
warn sprintf("DBG: QUERY:%s TIME:%.3f  INIT:%.3f DBRV:(%.3f:%d) DBLT (%.3f:%d) DBBL (%.3f:%d) CL (%.3f:%d) DBBR (%.3f:%d) FP (%.3f:%d) TP (%.3f:%d) IC (%.3f:%d) CC (%.3f:%d) ET (%.3f:%d) FS (%.3f:%d)\n",
    $qs,
	$cmlcalc::TIMERS->{MAIN}->{sec},$its,
	$GLOBAL->{ot},$GLOBAL->{otc},
	$cmlcalc::TIMERS->{LOWTREE}->{sec},$cmlcalc::TIMERS->{LOWTREE}->{count},
	$GLOBAL->{timers}->{bl},$GLOBAL->{timers}->{blc},
	$GLOBAL->{timers}->{cl},$GLOBAL->{timers}->{clc},
	$GLOBAL->{timers}->{br},$GLOBAL->{timers}->{brc},
	$GLOBAL->{timers}->{fp},$GLOBAL->{timers}->{fpc},
	$GLOBAL->{timers}->{tp},$GLOBAL->{timers}->{tpc},	
	$GLOBAL->{timers}->{ic},$GLOBAL->{timers}->{icc},	
	$GLOBAL->{timers}->{cc},$GLOBAL->{timers}->{ccc},
    $GLOBAL->{timers}->{et},$GLOBAL->{timers}->{etc},
    $GLOBAL->{timers}->{fs},$GLOBAL->{timers}->{fsc},			
) unless $cached_stat;



sub errorpage
{
 my $v=&cmlcalc::calculate({key=>'ERRORPAGE',expr=>"p('TMPL')"});
 my $body=$v->{value};
 if ($body) {print $body}
 else       {print "Ошибка вывода !!!!"}
}

sub stat_injection 
{
	my ($mtime,$bodyref,$cached)=@_;
	$mtime=int(1000*$mtime);
	my $cv=$cached?1:0;
	my $stat_script=qq(
	
	 <script type="text/javascript">
             var drt;
             var wlt;
             var mt=$mtime;
             jQuery(document).ready(function() {
                 drt=Date.now()-timerStart+mt;
             });
             jQuery(window).load(function() {
                 wlt=Date.now()-timerStart+mt;
                 var newImg = new Image;
                 newImg.src = '/cgi-bin/stat.pl?d='+drt+'&w='+wlt+'&s='+mt+'&c=$cv';
             });
             
        </script>       
	
	
	);
	my $init_script=qq(<script type="text/javascript">var timerStart = Date.now();</script>);


	${$bodyref}=~s/<!-- INIT INJECTION -->/$init_script/i;
	${$bodyref}=~s/<!-- STAT INJECTION -->/$stat_script/i;

}

