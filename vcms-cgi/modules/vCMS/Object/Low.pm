package vCMS::Object::Low;
 
 
use base "vCMS::Object";
use lib "../..";
use vCMS::Proxy;
	 

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
	
	if (vCMS::Proxy::CheckObj($self->ID())) {
		$self->{_up}=vCMS::Proxy::GetUpID($self->ID());
		$self->{_key}=vCMS::Proxy::GetKey($self->ID());
		$self->{_lang}=vCMS::Proxy::GetLang($self->ID());
		$self->{_name}=vCMS::Proxy::GetName($self->ID());
		$self->{_is_loaded}=1;
		return 1;
	} else {
		return undef;
	}	
	
}

sub LoadPrmVals($) {
	my $self = shift;
	return 1 if $self->{_prms_loaded};
	$self->{vals}=vCMS::Proxy::DumpLower($self->ID());
	$self->{_prms_loaded}=1;
}



sub IsNull ($) {
	return 0;
}


sub Copy ($$) {
	my ($self,$opts)=@_;
	my $pUpObj=vCMS::o($self->p('_UP'));
	my $h;
	$h->{_NAME}=$self->p(_NAME);
	$self->LoadPrmVals();
	my $v=$self->{vals};
	for (keys %{$v}) {
		next if $opts->{skipprms}->{$_};
  		$h->{$_}=$v->{$_}->{langvalue}?$v->{$_}->{langvalue}->{rus}:$v->{$_}->{value}
	}
	my $pNewObj=$pUpObj->Create($h); 
	my $nid=$pNewObj->GetID();
	if ($opts->{copylinks}) {
		for my $sprm (keys %{$opts->{copylinks}}) {
			my $dprm=$opts->{copylinks}->{$sprm};
			for my $iObj (@{$self->l($sprm)->GetObjects()}) {
				my $icObj=$iObj->Copy();
    			$icObj->Set($dprm,$nid);
			}
		}
	}
	return $pNewObj;
}


sub GetObjects ($) {
	my ($self)=shift;
	return [$self]
}


1;