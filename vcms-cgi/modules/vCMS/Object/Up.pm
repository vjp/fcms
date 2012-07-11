package vCMS::Object::Up;
 
 
use base "vCMS::Object";
use lib "../..";
use cmlmain;	 
use vCMS::Object::Low;

sub new($) {
    my ($class,$id) = @_;
    my $self = {
        _type => vCMS::Object::OBJ_TYPE_LOW(),
        _id  => "u$id",
        _index => $id,
    };
    bless $self, $class;
    return $self;	
}


sub Load($) {
	my $self = shift;
	return 1 if $self->{_is_loaded};
	if ($cmlmain::obj->{$self->{_index}}->{id}) {
		$self->{_up}=$cmlmain::obj->{$self->{_index}}->{up};
		$self->{_key}=$cmlmain::obj->{$self->{_index}}->{key};
		$self->{_is_loaded}=1;
		return 1;
	} else {
		return undef;
	}	
	
}

sub LowList($) {
	my $self=shift;
	&cmlmain::checkload({uid=>$self->{_index}}); 
    my @list=map{ new vCMS::Object::Low($_)} sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$self->{_index}}->{0}};
    return \@list;
}

sub LowObjects($) {
	my $self=shift;
	&cmlmain::checkload({uid=>$self->{_index}});
	prefetchlist(join(';',@{$cmlmain::ltree->{$self->{_index}}->{0}}));
    my @list=map{ 
    	my $lObj=new vCMS::Object::Low($_);
    	$lObj->Fill();
    	$lObj;
    } @{$cmlmain::ltree->{$self->{_index}}->{0}};
    return \@list;
    
}

1;