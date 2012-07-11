package vCMS::Object::Low;
 
 
use base "vCMS::Object";
use lib "../..";
use cmlmain;	 

sub new($) {
    my ($class,$id) = @_;
    my $self = {
        _type => vCMS::Object::OBJ_TYPE_LOW(),
        _id  => $id,
        _index => $id,
    };
    bless $self, $class;
    return $self;	
}

sub Load($) {
	my $self = shift;
	return 1 if $self->{_is_loaded};
	
	if ($cmlmain::obj->{$self->{_index}}->{id}) {
		$self->{_up}=$cmlmain::lobj->{$self->{_index}}->{up};
		$self->{_key}=$cmlmain::lobj->{$self->{_index}}->{key};
		$self->{_is_loaded}=1;
		return 1;
	} else {
		return undef;
	}	
	
}

sub Fill($) {
	my $self = shift;
	$self->Load();
	for my $k (keys %{$cmlmain::lobj->{$self->{_index}}}) {
		if ($k eq 'langvals') {
			for my $lang (keys %{$cmlmain::lobj->{$self->{_index}}->{langvals}}) {
				 for my $p (keys %{$cmlmain::lobj->{$self->{_index}}->{langvals}->{$lang}}) {
				 	$self->{_vals}->{$p}->{_langvalue}->{$lang}->{$p}=$cmlmain::lobj->{$self->{_index}}->{langvals}->{$lang}->{$p}->{value}
				 }	
			}
		} else {
			$self->{_vals}->{$k}->{_value}=$cmlmain::lobj->{$self->{_index}}->{$k}->{value}
		}
	}
}

1;