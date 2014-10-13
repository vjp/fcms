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

sub Set ($$$) {
	return undef;
}

sub IsNull ($) {
	return 1;
}

sub UID ($) {
	return undef;	
}


sub LoadPrmVals($) {
	my $self = shift;
	return 1 if $self->{_prms_loaded};
	$self->{vals}=undef;
	$self->{_prms_loaded}=1;
}


1;