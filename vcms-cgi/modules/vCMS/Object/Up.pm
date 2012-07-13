package vCMS::Object::Up;
 
 
use base "vCMS::Object";
use lib "../..";
use vCMS::Object::Low;
use vCMS::Proxy;

sub new($) {
    my ($class,$id) = @_;
    my $self = {
        _type => vCMS::Object::OBJ_TYPE_LOW(),
        _id  => "u$id",
        _index => $id,
    };
    bless $self, $class;
    return $self;	
}

sub UID ($) {
	my $self = shift;
	return $self->{_index};
}


sub Load($) {
	my $self = shift;
	return 1 if $self->{_is_loaded};
	if (vCMS::Proxy::CheckObj($self->ID())) {
		$self->{_up}=vCMS::Proxy::GetUpID($self->ID());
		$self->{_key}=vCMS::Proxy::GetKey($self->ID());
		$self->{_is_loaded}=1;
		return 1;
	} else {
		return undef;
	}	
	
}

sub LowList($) {
	my $self=shift;
	my $l=vCMS::Proxy::LowList($self->UID());
    my @list=map{ new vCMS::Object::Low($_) } @$l;
    return \@list;
}

sub LowObjects($) {
	my $self=shift;
	my $objs=$self->LowList();
	my $v=vCMS::Proxy::LowValues($self->UID());
	for my $lObj (@$objs) {
		$lObj->Fill($v->{$lObj->ID()});
	} 
	return $objs;
}

1;