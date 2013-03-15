#!/usr/bin/perl



use lib "../modules/";

use cmlmain;

use CGI  qw(param url header path_info);
use Data::Dumper;
use CGI::Carp qw (fatalsToBrowser);
use Time::HiRes qw (time);
use JSON::PP;
use Encode;

start('..');

my $v;

for (param()) {	$cmlcalc::CGIPARAM->{$_}=join(';',(param($_))) }
$cmlcalc::CGIPARAM->{_MODE}='GATE';
$cmlcalc::ENV->{BENCHMARK}=&cmlcalc::p(USERBENCHMARK,&cmlcalc::id(CMSDESIGN));
$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%user';
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};

message("ENABLE TAG BENCHMARKING") if $cmlcalc::ENV->{BENCHMARK}; 

if ($cmlcalc::SITEVARS->{lang}) {	$cmlcalc::LANGUAGE=$cmlcalc::SITEVARS->{lang} } else {$cmlcalc::LANGUAGE=$LANGS[0]}

my $pathinfostr=path_info();
my @pi=split('/',$pathinfostr);
shift @pi;
my %pathinfo=@pi;
$cmlcalc::CGIPARAM->{pathinfo}=$pathinfostr;


my $method_name;
my $firstparam=shift @pi;
if ($firstparam=~/^_(.+)$/) {
	 	$method_name=$1
}
$method_name='TESTGATE' unless $method_name;
my $data=param('data');
if ($data) {
	my $r=JSON::PP->new->utf8->decode($data);
	if (ref $r eq 'HASH') {
		unless ($GLOBAL->{CODEPAGE} eq 'utf-8') {
			for (keys %$r) {
				$r->{$_} = Encode::encode('cp1251',$r->{$_});
			}	
		}
		$cmlcalc::CGIPARAM=$r;
	}
}			
my $json=new JSON::PP;
my $result=&cmlcalc::execute({method=>$method_name,key=>'GATE'});
print header(-type=>$cmlcalc::ENV->{'JSON'} || !$result?'application/json':'text/html', -charset=>$GLOBAL->{CODEPAGE});
print $result ||  $json->encode ({status=>0,error=>"METHOD:$method_name EMPTY OUTPUT"});


sub errorpage
{
 my $v=&cmlcalc::calculate({key=>'ERRORPAGE',expr=>"p('PAGETEMPLATE')"});
 my $body=$v->{value};
 if ($body) {print $body}
 else       {print "Ошибка вывода !!!!"}
}


