#!/usr/bin/perl



use strict;
#use URI::Escape;
#use Encode;

my ($d,$v,$s,$c)=($ENV{REQUEST_URI}=~/d=(\d+).+w=(\d+).+s=(\d+).+c=([01])/);
#my ($cc)=($ENV{HTTP_COOKIE}=~/_cc=(\S+?);/s);
#my ($cn)=($ENV{HTTP_COOKIE}=~/_cn=(\S+?);/s);
#my $geo=Encode::encode('cp1251',Encode::decode('utf8',uri_unescape($cc).' '.uri_unescape($cn)));
my $geo;

warn sprintf("BODY GEN %.3fs DOM READY %.3fs FULL LOAD %.3fs ",$s/1000,$d/1000,$v/1000)."geo : $geo cached : $c\n";
print "Status: 301 Moved Permanantly\n";
print "Location: http://$ENV{SERVER_NAME}/i/0.gif\n\n";