package vCMS::Collection::LowList;
 
use base "vCMS::Collection";
use lib "../..";
use vCMS::Proxy;
  
sub new($) {
    my ($class,$pUpObj) = @_;
    my @l=map {new vCMS::Object::Low($_)} @{vCMS::Proxy::LowList($pUpObj->UID())};
    my $self = {
        _list => \@l,
        _upobj=> $pUpObj,
    };
    bless $self, $class;
    return $self;	
}


sub Fill ($) {
	my $self=shift;
	my $v=vCMS::Proxy::LowValues($self->{_upobj}->UID());
	$_->Fill($v->{$_->ID()}) for @{$self->GetObjects()};
	return $v;
}

1;