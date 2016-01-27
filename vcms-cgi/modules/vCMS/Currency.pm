package vCMS::Currency;

use lib "..";
use vCMS::Proxy;

sub Quandl ($) {
    my %h=(
        'AU'=>'LBMA/GOLD',
        'AG'=>'LBMA/SILVER',
        'PD'=>'LPPM/PALL',
        'PT'=>'LPPM/PLAT',
        'CU'=>'LME/PR_CU',
    );
    return $h{$_[0]} || undef;
}




sub Exchange ($) {
    my ($key)=@_;
    my $qkey=Quandl($key);
    if ($qkey) {
        my $r=vCMS::Proxy::GetURL("https://www.quandl.com/api/v3/datasets/$qkey/data.xml?rows=1&column_index=1");
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