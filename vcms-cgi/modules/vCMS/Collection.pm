package vCMS::Collection;

use lib "..";  
use vCMS::Method;
use vCMS::Object::Null;

sub new($$$) {
    my ($class,$list_ref) = @_;
    my $self = {
        _list => $list_ref,
    };
    bless $self, $class;
    return $self;	
}

sub Empty ($) {
	my ($self)=shift;
	return $self->{_list}->[0]?0:1;
}

sub First ($) {
	my ($self)=shift;
	return $self->Empty()?new vCMS::Object::Null():$self->{_list}->[0]; 
}

sub GetObjects ($) {
	my ($self)=shift;
	return $self->{_list}
}

sub GetObjectIDs ($) {
	my ($self)=shift;
	my @l = map{ $_->GetID() } @{$self->GetObjects()};
	return \@l;
}

sub p($$;$) {
	my($self,$prm,$opts)=@_;
	my @l = map{ $_->p($prm,$opts) } @{$self->GetObjects()};
	return \@l;
}

sub l($$) {
    my($self,$prm)=@_;
    
    my $ids;
    for  (map { $_->p($prm,{formatted=>1}) } @{$self->GetObjects()}) {
        $ids->{$_}=1 for @$_;
    }
    my @l = map {vCMS::o($_)} keys %$ids; 
    return new vCMS::Collection(\@l);
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

sub Set ($$;$) {
	my ($self,$prm,$value)=@_;
	$_->Set($prm,$value) for @{$self->GetObjects()};
}

sub MoveTo ($$) {
	my ($self,$to)=@_;
	$_->MoveTo($to) for @{$self->GetObjects()};
}


sub Inc ($$;$) {
	my ($self,$prm,$value)=@_;
	for my $pObj (@{$self->GetObjects}) {
		$pObj->Inc($prm,$value);
	}
}

sub Execute ($$) {
	my ($self,$method)=@_;
	for my $pObj (@{$self->GetObjects}) {
		my $m=new vCMS::Method($pObj,$method);
		$m->Execute();
	}	

}

sub e($$) {
	return Execute($_[0],$_[1]);
}


sub GetIDs($) {
	my ($self,$prm,$value)=@_;
	my $ids_ref;
	for my $pObj (@{$self->GetObjects}) {
		push (@$ids_ref,$pObj->GetID());
	}
	return $ids_ref
}
 
sub Str ($) {
	my ($self)=@_;
	return join(';',@{$self->GetObjectIDs()})
}

1;