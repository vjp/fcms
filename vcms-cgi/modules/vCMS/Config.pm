package vCMS::Config;

use lib "..";
use cmlmain; 

sub Get ($;$) {
	my ($key,$default)=@_;
	my $v=$cmlmain::GLOBAL->{CONF}->{$key};
    return defined $v?$v:$default;	
}


1;