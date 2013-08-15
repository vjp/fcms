package vCMS::SiteUser;
 
 
use base "vCMS::Object::Low";
use lib "..";
use vCMS::Proxy;
	 
sub new($) {
    my ($class,$id,$login) = @_;
    my $self = {
        _type => vCMS::Object::OBJ_TYPE_LOW(),
        _id  => $id,
        _index => $id,
        _login => $login,
    };
    bless $self, $class;
    return $self;	
}

sub GetLogin ($) {
	my ($self)=@_;
	return $self->{_login};
}

1;