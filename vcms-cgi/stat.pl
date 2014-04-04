#!/usr/bin/perl

use strict;

my ($d,$v,$s)=($ENV{REQUEST_URI}=~/d=(\d+).+w=(\d+).+s=(\d+)/);
warn sprintf("BODY GEN %.3fs DOM READY %.3fs FULL LOAD %.3fs\n",$s/1000,$d/1000,$v/1000);
print "Status: 301 Moved Permanantly\n";
print "Location: http://$ENV{SERVER_NAME}/i/0.gif\n\n";