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


sub GetOTKey ($) {
	my ($self)=@_;
	my $key=int(rand(1000000000));
	vCMS::Proxy::SetOTKey($self->GetLogin(),$key);
	return $key;
}


sub LoginByOTKey {
	my ($class,$login,$otkey)=@_;
	my $uid=vCMS::Proxy::CheckOTKey($login,$otkey);
	return undef unless $uid;
	return $class->new($uid,$login);
}

1;