#!/usr/bin/perl
use strict;
my ($d,$v)=($ENV{REQUEST_URI}=~/d=(\d+).+w=(\d+)/);
warn sprintf("DOM READY %.3f s FULL LOAD %.3f s\n",$d/1000,$v/1000);
print "Status: 301 Moved Permanantly\n";
print "Location: http://$ENV{SERVER_NAME}/i/0.gif\n\n";