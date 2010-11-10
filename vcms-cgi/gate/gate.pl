#!/usr/bin/perl -w

# $Id: gate.pl,v 1.2 2010-05-25 20:12:18 vano Exp $

use lib "../modules/";

use cmlmain;

use CGI  qw(param url header path_info);
use Data::Dumper;
use CGI::Carp qw (fatalsToBrowser);
use Time::HiRes qw (time);

open(STDERR, ">/dev/null"); 



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

print header(-type=>'text/html',-cookie=>\@cookies, -charset=>$GLOBAL->{CODEPAGE});


if ($method_name) {
	print &cmlcalc::execute({method=>$method_name,key=>'GATE'});
}else       {
	errorpage()
}



sub errorpage
{
 my $v=&cmlcalc::calculate({key=>'ERRORPAGE',expr=>"p('PAGETEMPLATE')"});
 my $body=$v->{value};
 if ($body) {print $body}
 else       {print "Ошибка вывода !!!!"}
}


