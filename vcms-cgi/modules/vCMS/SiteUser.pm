package vCMS::SiteUser;
 
 
use base "vCMS::Object::Low";
use lib "..";
use vCMS::Proxy;
	 
sub new($;$$) {
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


sub LoginByOTKey ($$$) {
	my ($class,$login,$otkey)=@_;
	my $uid=vCMS::Proxy::CheckOTKey($login,$otkey);
	return undef unless $uid;
	return $class->new($uid,$login);
}

sub GetSessionKey ($) {
	my ($self)=@_;
	my $key=int(rand(1000000000));
	vCMS::Proxy::SetSessionKey($self->GetLogin(),$key);
	return $key;
}

sub LoginBySessionKey ($$$) {
	my ($class,$login,$sessionkey)=@_;
	my $uid=vCMS::Proxy::CheckSessionKey($login,$sessionkey);
	return undef unless $uid;
	return $class->new($uid,$login);
}


sub Existed ($$) {
	my ($class,$login)=@_;
	return vCMS::Proxy::CheckUser($login);
}

sub Create ($$$;$) {
	my ($class,$login,$upperobj,$password)=@_;
	my $luObj=$upperobj->Create({_KEY=>"SU_$login",_NAME=>$login});
	my $uid=vCMS::Proxy::AddUser($luObj->GetID(),$login,$password);
	return $class->new($uid,$login);
}


sub Get($$) {
	my ($class,$login)=@_;
	my $uid=vCMS::Proxy::CheckUser($login);
	if ($uid) {
		return $class->new($uid,$login);
	} else {
		return undef;
	}
}


sub Activate ($) {
	my ($self)=@_;
	vCMS::Proxy::ActivateUser($self->GetID());
}

1;