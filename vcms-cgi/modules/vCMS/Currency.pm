package vCMS::Currency;

use vCMS::Proxy;


sub Exchange ($) {
	my ($key)=@_;
	my $r=vCMS::Proxy::GetURL("http://www.cbr.ru/scripts/XML_daily.asp");
	if ($r->{content}) {
		my ($rate)=($r->{content}=~m{<CharCode>$key</CharCode>.+?<Value>([\d,]+)</Value>}si);
		$rate=~s/,/./;
		return $rate;
	} else {
		return undef;
	}	
	
}


1;