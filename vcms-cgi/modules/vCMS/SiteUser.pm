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


sub Dump ($) {
	my ($self)=shift;
	return {
		'ID'=>$self->{_id},
		'LOGIN'=>$self->{_login},
	}
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

sub CheckPassword ($$) {
	my ($self,$pswd)=@_;
	return vCMS::Proxy::CheckUserPassword($self->GetID(),$pswd);
}

sub SetPassword ($$) {
	my ($self,$pswd)=@_;
	return vCMS::Proxy::SetUserPassword($self->GetID(),$pswd);
}

sub Create ($$$;$$) {
	my ($class,$login,$upperobj,$password,$prmvals)=@_;
	return undef unless $login;
	return undef if $upperobj->IsNull;
	my $luObj=$upperobj->Create({_KEY=>"SU_$login",_NAME=>$login});
	return undef if $luObj->IsNull;
	my $uid=vCMS::Proxy::AddUser($luObj->GetID(),$login,$password);
	$luObj->Set($prmvals) if $prmvals;
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