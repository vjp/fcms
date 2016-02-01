package vCMS::Currency;

use lib "..";
use vCMS::Proxy;
use  Data::Dumper;

sub Quandl ($) {
    my %h=(
        'AU'=>'LBMA/GOLD',
        'AG'=>'LBMA/SILVER',
        'PD'=>'LPPM/PALL',
        'PT'=>'LPPM/PLAT',
        'CU'=>'LME/PR_CU',
        'EURUSD'=>'ECB/EURUSD',
    );
    return $h{$_[0]} || undef;
}




sub Exchange ($;$) {
    my ($key,$opts)=@_;
    my $debug;
    $debug=1 if $opts->{debug};
    my $apikey=$opts->{key};
    my $qkey=Quandl($key);
    if ($qkey) {
        my $url="https://www.quandl.com/api/v3/datasets/$qkey/data.xml?rows=1&column_index=1";
        $url.="&api_key=$apikey" if $apikey;
        my $r=vCMS::Proxy::GetURL($url);
        if ($r->{content}) {
            my ($rate)=($r->{content}=~m{<datum type="float">([\d\.]+)</datum>}si);
            return $rate;
        } else {
            return $debug?$r:undef;
        };
    }
    my $r=vCMS::Proxy::GetURL("http://www.cbr.ru/scripts/XML_daily.asp");
    if ($r->{content}) {
        my ($rate)=($r->{content}=~m{<CharCode>$key</CharCode>.+?<Value>([\d,]+)</Value>}si);
        $rate=~s/,/./;
        return $rate;
    } else {
        return $debug?$r:undef;
    }
}

1;