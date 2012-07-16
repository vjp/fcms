package vCMS::Collection;
  




sub Dump ($) {
	my ($self)=shift;
	my @l=map {$_->Dump()} @{$self->{_list}};
	return \@l;
}

1;