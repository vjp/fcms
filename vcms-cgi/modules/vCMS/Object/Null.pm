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
	return 1;
}

sub l($$) {
	my($self,$prm)=@_;
	return $self;
}

sub p($$;$) {
	return undef;
}

1;