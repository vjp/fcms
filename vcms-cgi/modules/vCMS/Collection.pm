package vCMS::Collection;
  


sub GetObjects ($) {
	my ($self)=shift;
	return $self->{_list}
}

sub GetObjectIDs ($) {
	my ($self)=shift;
	my @l = map{ $_->GetID() } @{$self->GetObjects()};
	return \@l;
}


sub GetObject ($$) {
	my ($self,$key)=@_;

	my @l=grep {
    	if ($key=~/^u?\d+$/) {
        	$_->ID() eq $key
        } else {
        	$_->Key() eq $key
        }		
	} @{$self->GetObjects()};
	return $l[0];
	
}

sub Dump ($) {
	my ($self)=shift;
	my @l=map {$_->Dump()} @{$self->GetObjects()};
	return \@l;
}


sub Delete ($) {
	my ($self)=shift;
	$_->Delete() for @{$self->GetObjects()};
	$self->{_list}=[];
}


1;