package vCMS::Object::Low;
 
 
use base "vCMS::Object";
use lib "../..";
use vCMS::Proxy;
	 

sub new($) {
    my ($class,$id) = @_;
    my $self = {
        _type => vCMS::Object::OBJ_TYPE_LOW(),
        _id  => $id,
        _index => $id,
    };
    bless $self, $class;
    return $self;	
}

sub Load($) {
	my $self = shift;
	return 1 if $self->{_is_loaded};
	
	if (vCMS::Proxy::CheckObj($self->{_id})) {
		$self->{_up}=vCMS::Proxy::GetUpID($self->{_id});
		$self->{_key}=vCMS::Proxy::GetKey($self->{_id});
		$self->{_lang}=vCMS::Proxy::GetLang($self->{_id});
		$self->{_is_loaded}=1;
	} else {
		return undef;
	}	
	
}


1;