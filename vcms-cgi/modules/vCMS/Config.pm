package vCMS::Config;

use lib "..";
use cmlmain; 
use HTTP::BrowserDetect;

sub DEV_FLAG {0x001}
sub MOB_FLAG {0x002}


sub CacheFlags ($) {
	my ($dev)=@_;
	my $flags=0;
	$flags |= DEV_FLAG() if $dev;
	$flags |= MOB_FLAG() if IsMobile();
	return $flags;
}

sub Get ($;$) {
	my ($key,$default)=@_;
	my $v=$cmlmain::GLOBAL->{CONF}->{$key};
    return defined $v?$v:$default;	
}


sub IsMobile () {
    return $cmlcalc::ENV->{MOBILE_USER_AGENT} if defined $cmlcalc::ENV->{MOBILE_USER_AGENT};
    return 0 unless $cmlmain::GLOBAL->{CONF}->{'mobile'};
    return 0 unless $ENV{HTTP_USER_AGENT};
    my $ua=HTTP::BrowserDetect->new($ENV{HTTP_USER_AGENT});
	$cmlcalc::ENV->{MOBILE_USER_AGENT}=$ua->mobile?1:0;
    return $cmlcalc::ENV->{MOBILE_USER_AGENT};
}


1;