#!/usr/bin/perl

use strict;
use CGI  qw/:standard upload/;
use Data::Dumper;
use CGI::Carp qw /fatalsToBrowser/;

print "Content-Type: text/html; charset=windows-1251\n\n";
print qq(
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<body>
);

if (param('statfile')) {
	my $fh = upload('statfile');
	my @l;	
	if (param('statfile')=~/zip$/) {
		open FH,">/tmp/tmp.zip";
 		while (my $buffer=<$fh>) {
 			print FH $buffer;
 		}		
 		close FH;
 		@l=split(/\n/,`unzip -p /tmp/tmp.zip`);
	}
	my $stat;
 	while (my $buffer=shift @l || <$fh>) {
 		if ($buffer=~/\[\w+ (\w+ \d+) \d\d:\d\d:\d\d (\d{4})\]/) {
 			my $dt="$1 $2"; 
			if ($buffer=~/BODY GEN ([0-9\.]+)s DOM READY ([0-9\.]+)s FULL LOAD ([0-9\.]+)s.+referer: (\S+)/) {
 				$stat->{$dt}->{cnt}++;
 				$stat->{$dt}->{bg}+=$1;
 				$stat->{$dt}->{dr}+=$2;
 				$stat->{$dt}->{fl}+=$3;
 				
 				$stat->{$dt}->{refs}->{$4}->{cnt}++;
 				$stat->{$dt}->{refs}->{$4}->{bg}+=$1;
 				$stat->{$dt}->{refs}->{$4}->{dr}+=$2;
 				$stat->{$dt}->{refs}->{$4}->{fl}+=$3;	
 					
 			}	 
 		}
 	}
 	for my $dt (sort keys %$stat) {
		if ($stat->{$dt}->{cnt}) {
 			printf "DT $dt CNT: %d  BODY GEN: %.2f  DOM READY: %.2f FULL LOAD %.2f <br/> <br/>",
 				$stat->{$dt}->{cnt},
 				$stat->{$dt}->{bg}/$stat->{$dt}->{cnt},
 				$stat->{$dt}->{dr}/$stat->{$dt}->{cnt},
 				$stat->{$dt}->{fl}/$stat->{$dt}->{cnt};
 		}	
 		my $top;
 		for my $ref (sort {$stat->{$dt}->{refs}->{$b}->{cnt}<=>$stat->{$dt}->{refs}->{$a}->{cnt}} keys %{$stat->{$dt}->{refs}}) {
 			printf "DT $dt REF $ref CNT: %d  BODY GEN: %.2f  DOM READY: %.2f FULL LOAD %.2f <br/>",
 				$stat->{$dt}->{refs}->{$ref}->{cnt},
 				$stat->{$dt}->{refs}->{$ref}->{bg}/$stat->{$dt}->{refs}->{$ref}->{cnt},
 				$stat->{$dt}->{refs}->{$ref}->{dr}/$stat->{$dt}->{refs}->{$ref}->{cnt},
 				$stat->{$dt}->{refs}->{$ref}->{fl}/$stat->{$dt}->{refs}->{$ref}->{cnt};
 			last if $top++>10;	
 		}
 		print "<hr/>"
 		
 		
 	} 
}
print start_form();
print 'file <input type=file name="statfile"><input type="submit">';
print end_form();
print '</body></html>'

