package vCMS::Collection::FastSearch;
 
use base "vCMS::Collection";
use lib "../..";
use vCMS::Proxy;
  
sub new($$$$) {
    my ($class,$pObj,$prm,$pattern) = @_;
    my @l=map {vCMS::o($_)} @{vCMS::Proxy::FastSearch($pObj->ID(),$prm,$pattern)};
    my $self = {
        _list => \@l,
        _obj  => $pObj,
        _pattern  => $pattern,
        _prm =>$prm,
    };
    bless $self, $class;
    return $self;	
}



1;