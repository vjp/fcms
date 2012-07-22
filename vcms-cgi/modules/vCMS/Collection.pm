package vCMS::Collection;
  


sub GetObjects ($) {
	my ($self)=shift;
	return $self->{_list}
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


sub Sync ($$) {
	my ($self,$data)=@_;
	$self->Fill();
	my $r;
	for (@$data) {
		my $key=$_->{KEY};
		my $o=$self->GetObject($key);
		if ($o) {
			for my $prm (keys %{$_->{VALUES}}) {
				if ($o->P($prm) ne $_->{VALUES}->{$prm}) {
					$o->Set($prm,$_->{VALUES}->{$prm});
					$r->{set}->{$key}->{$prm}=$_->{VALUES}->{$prm};
				}	
				
			}
 
		}
	}
	return $r;
}

1;