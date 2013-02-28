package vCMS::Object::Null;
 
 
use base "vCMS::Object";
use lib "../..";
use vCMS::Proxy;
	 

sub new($) {
    my ($class) = @_;
    my $self = {
        _type => vCMS::Object::OBJ_TYPE_NULL(),
    };
    bless $self, $class;
    return $self;	
}

sub Load($) {
	my $self = shift;
	return 1;
}


1;