package vCMS::Object;

use lib "..";
use vCMS::Proxy;
use vCMS::Method;
  
sub OBJ_TYPE_UP  {0} 
sub OBJ_TYPE_LOW {1} 
 

sub Key ($) {
	my $self=shift;
	$self->Load() unless $self->{_is_loaded};
	return $self->{_key};
}


sub ID ($) {
	my $self=shift;
	return $self->GetID();
}

sub GetID ($) {
	my $self=shift;
	return $self->{_id};
}


sub Fill ($$) {
	my ($self,$vals)=@_;
	for my $prm (keys %$vals) {
		if ($vals->{$prm}->{value}) {
			$self->{vals}->{$prm}=$vals->{$prm}->{value} ;
		} elsif ($vals->{$prm}->{langvalue}->{$self->{_lang}}) {
			$self->{vals}->{$prm}=$vals->{$prm}->{langvalue}->{$self->{_lang}} ;
		}	
	}
}

sub P($$) {
	my($self,$prm)=@_;
	return defined $self->{vals}->{$prm}?$self->{vals}->{$prm}:vCMS::Proxy::GetValue($self->ID,$prm);
}


sub Set ($$$) {
	my ($self,$prm,$value)=@_;
	return vCMS::Proxy::SetValue($self->ID,$prm,$value);
}


sub Dump ($) {
	my ($self)=shift;
	$self->Load() unless $self->{_is_loaded};
	my $h= {
			'ID'=>$self->{_id},
			'TYPE'=>$self->{_type},
			'UP'=>$self->{_up},
			'NAME'=>$self->{_name},
			'KEY'=>$self->{_key},
	};
	$h->{VALUES}=$self->{vals} if $self->{vals};
	return $h;
}

sub M($$) {
	my ($self,$method)=@_;
	return new vCMS::Method($self,$method);
}

sub Execute($$) {
	my ($self,$method)=@_;
	my $m=new vCMS::Method($self,$method);
	return $m->Execute();
	
}


sub Delete($) {
	my $self = shift;
	vCMS::Proxy::DeleteObject($self->ID())
}	


1;