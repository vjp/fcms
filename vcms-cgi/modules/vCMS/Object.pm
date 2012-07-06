package vCMS::Object;
 
sub OBJ_TYPE_UP  {0} 
sub OBJ_TYPE_LOW {1} 
 


sub Key ($) {
	my $self=shift;
	$self->Load() unless $self->{_is_loaded};
	return $self->{_key};
}



1;