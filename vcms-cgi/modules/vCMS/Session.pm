package vCMS::Session;

use JSON::PP; 

sub GetVar ($) {
	my ($var)=@_;
	return decode_json('['.CGI::cookie("__CJ_$var").']')->[0];
}


1;