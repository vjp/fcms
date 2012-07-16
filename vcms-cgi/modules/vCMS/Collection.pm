package vCMS::Collection;
  


sub GetObjects ($) {
	my ($self)=shift;
	return $self->{_list}
}



sub Dump ($) {
	my ($self)=shift;
	my @l=map {$_->Dump()} @{$self->GetObjects()};
	return \@l;
}

1;