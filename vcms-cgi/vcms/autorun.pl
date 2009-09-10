#!/usr/bin/perl -w


use lib "../modules/";
use cmlmain;
use cmlcalc;
use strict;



use Data::Dumper;
use Time::HiRes qw (time);
use Cwd;

my $prm=shift;
if ($prm) {
	warn "set crontab ($prm)";
	my $path=cwd();
	system ('crontab -r');
	system("echo '$prm * * * * $path/autorun.pl'");
	system("echo '$prm * * * * $path/autorun.pl' | crontab - ");
       	exit;
}

start('..');
$cmlcalc::ENV->{USER}='%autorun';
$cmlcalc::CGIPARAM->{_MODE}='AUTORUN';
if (
		&cmlcalc::p('AUTOLOCK',cmlcalc::id('AUTOMATE')) && 
		(&cmlcalc::now() - (0+&cmlcalc::p('AUTOLOCKTIME',&cmlcalc::id('AUTOMATE')))) < 0+&cmlcalc::p('AUTOLOCKPERIOD',&cmlcalc::id('AUTOMATE')) 
    ) {
	message('AUTOSCRIPT RUNNING. BREAK');
} else {
	setvalue({id=>cmlcalc::id('AUTOMATE'),prm=>'AUTOLOCK',value=>1});
	setvalue({id=>cmlcalc::id('AUTOMATE'),prm=>'AUTOLOCKTIME',value=>&cmlcalc::now()});
	&cmlcalc::execute({id=>cmlcalc::id('AUTOMATE'),method=>'AUTOSCRIPT'});
	setvalue({id=>cmlcalc::id('AUTOMATE'),prm=>'AUTOLOCK',value=>0});
}	
viewlog();