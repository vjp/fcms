package vCMS::Collection::LowList;
 
use base "vCMS::Collection";
use lib "../..";
use vCMS::Proxy;
  
sub new($) {
    my ($class,$pUpObj) = @_;
    my @l=map {new vCMS::Object::Low($_)} @{vCMS::Proxy::LowList($pUpObj->UID())};
    my $self = {
        _list => \@l,
        _upobj=> $pUpObj,
    };
    bless $self, $class;
    return $self;	
}


sub Fill ($) {
	my $self=shift;
	my $v=vCMS::Proxy::LowValues($self->{_upobj}->UID());
	$_->Fill($v->{$_->ID()}) for @{$self->GetObjects()};
	return $v;
}

sub Sync ($$) {
	my ($self,$data)=@_;
	$self->Fill();
	my $r;
	for (@$data) {
		my $key=$_->{KEY};
		$key="EXPORT".$_->{ID};
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