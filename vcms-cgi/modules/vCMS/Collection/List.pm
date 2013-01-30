package vCMS::Collection::List;
 
use base "vCMS::Collection";
use lib "../..";
use vCMS::Proxy;
  
sub new($$$) {
    my ($class,$pObj,$prm) = @_;
    my @l=map {vCMS::o($_)} @{$pObj->p($prm,{formatted=>1})};
    my $self = {
        _list => \@l,
        _obj  => $pObj,
        _prm  => $prm,
    };
    bless $self, $class;
    return $self;	
}



1;