package vCMS::Object;

use lib "..";
use vCMS::Proxy;
use vCMS::Method;
use vCMS::Collection::List;


  
sub OBJ_TYPE_UP  	{0} 
sub OBJ_TYPE_LOW 	{1} 
sub OBJ_TYPE_NULL	{2}
 

sub Key ($) {
	my $self=shift;
	$self->Load() unless $self->{_is_loaded};
	return $self->{_key};
}


sub ID ($) {
	my $self=shift;
	return $self->GetID();
}

sub GetIndex ($) {
	my $self=shift;
	return $self->{_index};
}


sub GetID ($) {
	my $self=shift;
	return $self->{_id};
}


sub Fill ($$) {
	my ($self,$vals)=@_;
	for my $prm (keys %$vals) {
		if ($vals->{$prm}->{value}) {
			$self->{vals}->{$prm}=$vals->{$prm}->{value} ;
		} elsif ($vals->{$prm}->{langvalue}->{$self->{_lang}}) {
			$self->{vals}->{$prm}=$vals->{$prm}->{langvalue}->{$self->{_lang}} ;
		}	
	}
}

=item P( $pObj, $prmname, $opts )
=item p( $pObj, $prmname, $opts )

Returns $pObj parameter value.

Examples:

o(OBJECTKEY)->P(PRMNAME);
o(OBJECTKEY)->p(PRMNAME,{formatted=>1});

Options hashref:

formatted - returns formatted value (useful for dates)
csv - returns csv template

=cut


sub P($$;$) {
	my($self,$prm,$opts)=@_;
	return (defined $self->{vals}->{$prm} && !$opts)?$self->{vals}->{$prm}:vCMS::Proxy::GetValue($self->ID,$prm,$opts);
}

sub p($$;$) {
	return P($_[0],$_[1],$_[2]);
}

=item l( $pObj, $prmname )

Returns vCMS::Collection or vCMS::Object for this $param

Examples:

o(OBJECTKEY)->l(LISTPRMNAME);

=cut

sub l($$) {
	my($self,$prm)=@_;
	if  (vCMS::Proxy::IsSingleLink($prm)) {
		my $v=$self->p($prm);
		return $v?vCMS::o($v):vCMS::null();
	} else { 	
		my @l=map {vCMS::o($_)} @{$self->p($prm,{formatted=>1})};
		return new vCMS::Collection(\@l);
	}
}



sub Set ($$;$) {
	my ($self,$prm,$value)=@_;

}


=item u( $pObj, {$prm1=>$value1,$prm2=>$value} );
=item u( $pObj, $prm1,$value1);

Updates objects param values

Examples:

o(OBJECTKEY)->u({FIRSTNAME=>'JOHN',LASTNAME=>'SMITH'});
o(OBJECTKEY)->u('NAME,'JOHN');

=cut


sub u ($$;$) {
	my ($self,$prm,$value)=@_;	
	return vCMS::Proxy::SetValue($self->ID,$prm,$value);	return 
}

sub Dump ($) {
	my ($self)=shift;
	$self->Load() unless $self->{_is_loaded};
	my $h= {
			'ID'=>$self->{_id},
			'TYPE'=>$self->{_type},
			'UP'=>$self->{_up},
			'NAME'=>$self->{_name},
			'KEY'=>$self->{_key},
	};
	$h->{VALUES}=$self->{vals} if $self->{vals};
	return $h;
}

sub M($$) {
	my ($self,$method)=@_;
	return new vCMS::Method($self,$method);
}

=item E( $pObj, $methodname )
=item Execute( $pObj, $methodname )

Executes $pObj method.

Examples:

o(OBJECTKEY)->e(METHODNAME);

$pObj=o(OBJECTKEY);
$pObj->Execute(METHODNAME);

=cut

sub Execute($$) {
	my ($self,$method)=@_;
	my $m=new vCMS::Method($self,$method);
	return $m->Execute();
}

sub e($$) {
	return Execute($_[0],$_[1]);
}

sub ExecuteAsync($$) {
	my ($self,$method)=@_;
	my $m=new vCMS::Method($self,$method);
	return $m->ExecuteAsync();
}



sub Delete($) {
	my $self = shift;
	vCMS::Proxy::DeleteObject($self->ID())
}	

sub Ready($) {
	my $self = shift;
	return 1 if $self->{_is_loaded};
}	



1;