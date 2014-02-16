#!/usr/bin/perl
use strict;
my ($d,$v)=($ENV{REQUEST_URI}=~/d=(\d+).+w=(\d+)/);
warn sprintf("DOM READY %.3f s FULL LOAD %.3f s\n",$d/1000,$v/1000);
print "Content-type: image/gif\n\n";