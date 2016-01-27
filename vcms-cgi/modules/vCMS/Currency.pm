package vCMS::Currency;

use lib "..";
use vCMS::Proxy;

sub IsLBMA ($) {
    my %h=(
        'GOLD'=>1,
        'SILVER'=>1,
        'PALL'=>1,
        'PLAT'=>1,
        'PR_CU'=>1,
    );
    return $h{$_[0]}?1:0;
}

sub Exchange ($) {
    my ($key)=@_;
    if (IsLBMA($key)) {
        my $r=vCMS::Proxy::GetURL("https://www.quandl.com/api/v3/datasets/LBMA/$key/data.xml?rows=1&column_index=1");
        if ($r->{content}) {
            my ($rate)=($r->{content}=~m{<datum type="float">([\d\.]+)</datum>}si);
            return $rate;
        } else {
            return undef;
        };
    }
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