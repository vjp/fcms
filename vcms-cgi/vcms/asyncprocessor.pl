#!/usr/bin/perl
use strict;


use Data::Dumper;
use Time::HiRes qw (time);


use lib "../modules/";

use cmlmain;
use cmlcalc;
use vCMS;


start('..');
$cmlcalc::ENV->{USER}='%asyncprocessor';
$cmlcalc::CGIPARAM->{_MODE}='ASYNCPROCESSOR';
($cmlcalc::ENV->{SERVER}) = ($GLOBAL->{ABSFILEURL}=~m{http://(.+)/data});
for (1..20) {
	last unless vCMS::Queue::Job();
}

