#!/usr/bin/perl

use strict;

my ($d,$v,$s)=($ENV{REQUEST_URI}=~/d=(\d+).+w=(\d+).+s=(\d+)/);
my ($cc,$cn)=($ENV{HTTP_COOKIE}=~/_cc=(\S+);.+_cn=(\S+);/s);
my $geo="$cc $cn";
warn sprintf("BODY GEN %.3fs DOM READY %.3fs FULL LOAD %.3fs ",$s/1000,$d/1000,$v/1000)."geo : $geo \n";
print "Status: 301 Moved Permanantly\n";
print "Location: http://$ENV{SERVER_NAME}/i/0.gif\n\n";