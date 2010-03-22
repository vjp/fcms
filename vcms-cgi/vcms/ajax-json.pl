#!/usr/bin/perl -w

# $Id: ajax-json.pl,v 1.1 2010-03-22 22:25:19 vano Exp $

use strict;
no strict "refs";

use lib "../modules/";
use Data::Dumper;


use cmlmain;
use cmlcalc;
use cmlajax;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;
use Encode;
use JSON::PP;

use vars qw ($AJAX_FUNCS);
   
   
$AJAX_FUNCS={
	setvalue=>1,
	editmethod=>1,
	editlmethod=>1,
	addobject=>1,
	deleteobject=>1,
	evalscript=>1,
};   

start('..');


#!/usr/bin/perl -w

use strict;
no strict "refs";

use lib "./modules";
use Data::Dumper;
use JSON::PP;


use cmlmain;
use cmlcalc;
use cmlajax;
use CGI  qw/:standard/;     
use CGI::Carp qw /fatalsToBrowser/;
use Encode;

use vars qw ($AJAX_FUNCS);
   
   
$AJAX_FUNCS={
	console=>1,
};   


start('..');
print "Content-Type: application/json; charset=$GLOBAL->{CODEPAGE}\n\n";

my $data=param('data');
my $func=param('func');
my $json = new JSON::PP;
if ($AJAX_FUNCS->{$func}) {
	my $subname="cmlajax::ajax_$func";
	my $r=decode_json($data);
	my $result=&$subname($r);
	print $json->encode ({result=>$result});
} else {
	my $rstr="Íåïğàâèëüíàÿ ôóíêöèÿ $func";
	print $json->encode ({result=>$rstr});
}	

