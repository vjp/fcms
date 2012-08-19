package vCMS::Method;

use lib "..";
use vCMS::Proxy;
use vCMS::Queue;  
  
sub new($) {
    my ($class,$pObj,$name) = @_;
    my $self = {
        _name => $name,
        _pObj=> $pObj,
    };
    bless $self, $class;
    return $self;	
}


sub GetName ($) {
	return $_[0]->{_name};
}

sub GetObject($) {
	return $_[0]->{_pObj};
}

sub Execute($) {
	my ($self)=@_;
	return vCMS::Proxy::Execute($self->GetObject->ID(),$self->GetName());
}

sub ExecuteAsync ($) {
	my ($self)=@_;
	return vCMS::Queue::Add($self);
}


1;