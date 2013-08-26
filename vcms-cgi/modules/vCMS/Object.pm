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

sub GetKey ($) {
	my $self=shift;
	return $self->Key();
}

sub ID ($) {
	my $self=shift;
	return $self->GetID();
}

sub Name ($) {
	my $self=shift;
	return $self->p(_NAME);
}

sub GetName ($) {
	my $self=shift;
	return $self->Name();
}

sub GetFilename ($$) {
	my ($self,$prm)=@_;
	return vCMS::Proxy::GetGlobal(vCMS::Proxy::GetPrmExtra($prm,'cgi')?'CGIPATH':'WWWPATH').$self->p($prm);
}
        

sub GetIndex ($) {
	my $self=shift;
	return $self->{_index};
}

sub Index ($) {
	my $self=shift;
	return $self->GetIndex();
}

sub GetSortIndex ($) {
	my $self=shift;
	return $self->p(_INDEX);
}

sub SortIndex ($) {
	my $self=shift;
	return $self->GetSortIndex();
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


=item u( $pObj, {$prm1=>$value1,$prm2=>$value} );
=item u( $pObj, $prm1,$value1);

Updates objects param values

Examples:

o(OBJECTKEY)->u({FIRSTNAME=>'JOHN',LASTNAME=>'SMITH'});
o(OBJECTKEY)->u('NAME,'JOHN');

=cut


sub u ($$;$) {
	my ($self,$prm,$value)=@_;	
	return vCMS::Proxy::SetValue($self->ID,$prm,$value); 
}

=item Set

synonym u() func
=cut

sub Set ($$;$) {
	my ($self,$prm,$value)=@_;
	return u($self,$prm,$value);
}

sub SetFile ($$$) {
	my ($self,$prm,$cgifileprm)=@_;
	return vCMS::Proxy::UploadFile($self->ID,$prm,$cgifileprm);
}

sub SetToFile ($$$) {
	my ($self,$prm,$value)=@_;
	my $path='>'.$self->GetFilename($prm);
    my $status=(open (FH,$path))&&(print FH $value)&&(close FH); 
    return $status?(1):(0,"$!");
}

=item MoveTo( $pObj, $objid || $objkey );


Moves object

Examples:

o(OBJECTKEY)->MoveTo(NEWUPOBJKEY);

=cut


sub MoveTo ($$) {
	my ($self,$to)=@_;
	my $toObj=vCMS::o($to);
	return 0 unless $toObj;
	return $self->Set('_UP',$toObj->GetID());
}


=item Fix( $pObj, $prmname )

Setting Fixed value, calculated by default expression

=cut

sub Fix ($$) {
	my ($self,$prm)=@_;
	my $value=$self->p($prm);
	return $self->Set($prm,vCMS::Proxy::DefaultValue($self->ID,$prm));
}



sub Append ($$;$) {
	my ($self,$prm,$value)=@_;
	return vCMS::Proxy::AppendValue($self->ID,$prm,$value);
}

sub SetName ($$) {
	my ($self,$value)=@_;
	return vCMS::Proxy::SetName($self->ID,$value);
}

=item SetNameFromP( $pObj, $prmname )

Set Object name from prm value

Examples:

o(OBJECTKEY)->SetNameFromP(PRMFORNAME);

=cut

sub SetNameFromP ($$) {
	my ($self,$prm)=@_;
	return vCMS::Proxy::SetName($self->ID,$self->p($prm));
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



sub Delete($;$) {
	my ($self,$forced) = @_;
	vCMS::Proxy::DeleteObject($self->ID(),$forced)
}	

sub Ready($) {
	my $self = shift;
	return $self->{_is_loaded}?1:0;
}	

sub IsReady($) {
	my $self = shift;
	return $self->Ready();
}	


sub History($$) {
	my ($self,$prm) = @_;
	return vCMS::Proxy::History($self->ID,$prm)
}


1;