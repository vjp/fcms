package vCMS::Session;

use JSON::PP; 

sub GetVar ($;$) {
	my ($var,$key)=@_;
	my $str=decode_json('['.CGI::cookie('__CJ_'.$var).']')->[0];
	return $key?$str->{$key}:$str;
}


1;