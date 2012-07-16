package vCMS::Object;


use JSON::PP;
use lib "..";
use vCMS::Proxy;
  
sub OBJ_TYPE_UP  {0} 
sub OBJ_TYPE_LOW {1} 
 


sub Key ($) {
	my $self=shift;
	$self->Load() unless $self->{_is_loaded};
	return $self->{_key};
}


sub ID ($) {
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

sub Dump ($) {
	my ($self)=shift;
	
	if (ref $self eq 'ARRAY') {
		return join('---------',map {$_->Dump()} @$self)
	}
	
	$self->Load() unless $self->{_is_loaded};
	my $j={
			'ID'=>$self->{_id},
			'TYPE'=>$self->{_type},
			'UP'=>$self->{_up},
			'NAME'=>$self->{_name},
	};
    $j->{'VALUES'}=$self->{vals} if $self->{vals};
	if (vCMS::Proxy::IsUTF8()) { 
		return JSON::PP->new->encode($j);
	} else {
		return JSON::PP->new->latin1->encode($j);
	}	
}

1;