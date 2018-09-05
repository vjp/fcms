#!/usr/bin/perl
use strict;

use Cwd;
use Data::Dumper;
use Time::HiRes qw (time);


use lib "../modules/";
use lib "../../../../perl/usr/lib/perl5/x86_64-linux-thread-multi";


use cmlmain;
use cmlcalc;






my $prm=shift;
my $path=cwd();
if ($prm) {
	warn "set crontab ($prm)";
	system ('crontab -r');
	system(qq(echo '$prm * * * * "cd $path && ./autorun.pl"'));
	system(qq(echo '$prm * * * * "cd $path && ./autorun.pl"' | crontab - ));
       	exit;
}

start('..');
$cmlcalc::ENV->{USER}='%autorun';
$cmlcalc::CGIPARAM->{_MODE}='AUTORUN';
($cmlcalc::ENV->{SERVER}) = ($GLOBAL->{ABSFILEURL}=~m{http://(.+)/data});

my $AL=&cmlcalc::p('AUTOLOCK',&cmlcalc::id('AUTOMATE'));
my $N=&cmlcalc::now();
my $ALT=0+&cmlcalc::p('AUTOLOCKTIME',&cmlcalc::id('AUTOMATE'));
my $ALP=0+&cmlcalc::p('AUTOLOCKPERIOD',&cmlcalc::id('AUTOMATE'));
message (sprintf("AUTOSCRIPT RUNNING: %d NOW: %s LAST RUN: %s DELTA: %d PERIOD %d",$AL,scalar localtime($N),scalar localtime($ALT),$N-$ALT,$ALP));
if ($AL && ($N-$ALT) < $ALP) {
	message('AUTOSCRIPT WAITING. BREAK');
} else {
	message("AUTOSCRIPT STARTED [path=$path] ".scalar localtime);
	setvalue({id=>cmlcalc::id('AUTOMATE'),prm=>'AUTOLOCK',value=>1});
	setvalue({id=>cmlcalc::id('AUTOMATE'),prm=>'AUTOLOCKTIME',value=>&cmlcalc::now()});
	&cmlcalc::execute({id=>cmlcalc::id('AUTOMATE'),method=>'AUTOSCRIPT'});
	setvalue({id=>cmlcalc::id('AUTOMATE'),prm=>'AUTOLOCK',value=>0});
	message("AUTOSCRIPT ENDED ".scalar localtime);
}	
viewlog();
