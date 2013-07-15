package vCMS::Object::Up;
 
 
use base "vCMS::Object";
use lib "../..";
use vCMS::Object::Low;
use vCMS::Proxy;
use vCMS::Collection::LowList;

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

sub UID ($) {
	my $self = shift;
	return $self->{_index};
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

=item ll( $pObj,$FilterExpr )

Returns vCMS::Collection::LowList for this object

Examples:

o(OBJECTKEY)->ll();
o(OBJECTKEY)->ll("p(FILTERPARAM)>$filtervalue");

=cut


sub ll($;$) {
	my($self,$FilterExpr)=@_;
	return new vCMS::Collection::LowList($self,$FilterExpr);
}

sub LowList($;$) {
	my ($self,$FilterExpr)=@_;
	return new vCMS::Collection::LowList($self,$FilterExpr);
}



sub LowObjects($) {
	my $self=shift;
	my $pColl=$self->LowList();
	$pColl->Fill();
	return $pColl;
}

=item Create( $pObj,$ParamsHash,$FileParamsHash )

Returns ref to created object

Example:

$pNewObject=$pUpObject->Create({
		_NAME=>'NEW OBJECT NAME',
		_KEY=>'NEWOBJKEY',
		OBJPRM=>'VALUE',
},{
		PIC1=>'cgipic1paramname',
		FILE1=>'cgifile1paramname',
});


=cut


sub Create($;$$) {
	my ($self,$prms,$fileprms)=@_;
	my $lid=vCMS::Proxy::CreateLowObj($self->ID());
	my $o=vCMS::Object::Low->new($lid);
	$o->Load();
	$o->Set($prms) if $prms;
	$o->SetFile($fileprms) if $fileprms;
	return $o;
}

sub IsNull ($) {
	return 0;
}


1;