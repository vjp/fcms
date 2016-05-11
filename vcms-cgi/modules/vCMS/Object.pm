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
	return $self->GetInternalFilename($prm) if vCMS::Proxy::IsDataFileParam($prm);
	my $path=vCMS::Proxy::GetGlobal('WWWPATH');
	$path=vCMS::Proxy::GetGlobal('CGIPATH') if vCMS::Proxy::GetPrmExtra($prm,'cgi');
	$path='' if vCMS::Proxy::GetPrmExtra($prm,'abs');
	return $path.$self->p($prm);
}

sub GetFileName ($$) {
	return $_[0]->GetFilename($_[1]);
}
        
sub GetInternalFilename ($$) {
	my ($self,$prm)=@_;
	return vCMS::Proxy::GetGlobal('FILEPATH').'/'.$self->p($prm);
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


sub url ($$) {
	my($self,$prm)=@_;
	return vCMS::Proxy::GetGlobal('ABSFILEURL').'/'.$self->p($prm);
}

=item l( $pObj, $prmname $opts)

Returns vCMS::Collection or vCMS::Object for this $param

Examples:

o(OBJECTKEY)->l(LISTPRMNAME);
o(OBJECTKEY)->l(LISTPRMNAME,{limit=>5});
o(OBJECTKEY)->l(LISTPRMNAME,{prm2=>LISTPRM2}); 



=cut

sub l($$;$) {
    my($self,$prm,$opts)=@_;

    my $prm2;
    if (ref $opts eq 'HASH') {
       $prm2=$opts->{prm2}
    } else {
        $prm2=$opts
    }

    if  (vCMS::Proxy::IsSingleLink($prm)) {
        my $v=$self->p($prm);
        return $v?vCMS::o($v):vCMS::null();
    } else {
        my $ids;
        my @l=map {$ids->{$_}=1; vCMS::o($_)} @{$self->p($prm,{formatted=>1,limit=>$opts->{limit}})};
        if ($prm2) {
            push (@l,map{$ids->{$_}=1;vCMS::o($_)} grep {!$ids->{$_}} @{$self->p($prm2,{formatted=>1})} ) 
        }
        return new vCMS::Collection(\@l);
    }
}


sub Clear($$) {
	my ($self,$prm)=@_;
	return vCMS::Proxy::ClearValue($self->ID,$prm); 
}


=item u( $pObj, {$prm1=>$value1,$prm2=>$value} );
=item u( $pObj, $prm1,$value1);

Updates objects param values

Examples:

o(OBJECTKEY)->u({FIRSTNAME=>'JOHN',LASTNAME=>'SMITH'});
o(OBJECTKEY)->u('NAME,'JOHN');

=cut


sub u ($$;$$) {
	my ($self,$prm,$value,$opts)=@_;	
	return vCMS::Proxy::SetValue($self->ID,$prm,$value,$opts); 
}

=item Set

synonym u() func
=cut

sub Set ($$;$$) {
	my ($self,$prm,$value,$opts)=@_;
	return u($self,$prm,$value,$opts);
}

sub SetValue ($$;$$) {
	my ($self,$prm,$value,$opts)=@_;
	return u($self,$prm,$value,$opts);
}

sub GetFileData ($$) {
	my ($self,$prm)=@_;
	my $filename=$self->p($prm);
	return undef unless $filename;
	my $fullname=$self->GetFilename($prm);
	return undef unless -s $fullname;
	
	my $fcontent;
	open (FC2, "<$fullname");
	read (FC2,$fcontent,-s FC2);
	close(FC2); 
	
	return $fcontent;
}

sub GetContent ($$) {
    return GetFileData($_[0],$_[1]);
}

sub GetFileContent ($$) {
    return GetFileData($_[0],$_[1]);
}


sub SetFile ($$$) {
	my ($self,$prm,$cgifileprm)=@_;
	return vCMS::Proxy::UploadFile($self->ID,$prm,$cgifileprm);
}

sub SetToFile ($$$) {
	my ($self,$prm,$value)=@_;
	my $path='>'.$self->GetFilename($prm);
    my $status=(open (FH,$path))&&(print FH $value)&&(close FH); 
    return $status?(1):(0,"$!:$path");
}


sub SendFile ($$$;$) {
	my ($self,$fileprm,$toprm,$opts)=@_;
	$opts->{subject} ||= $self->GetName();
	$opts->{filename}=$self->GetFilename($fileprm);
	$opts->{to}=$self->P($toprm);
	vCMS::Proxy::SendFile($opts);
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
	$self->Set('_UP',$toObj->GetID());
	return  $toObj->GetID();
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

sub Inc ($$;$) {
	my ($self,$prm,$value)=@_;
	return vCMS::Proxy::IncValue($self->ID,$prm,$value);
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
	$self->LoadPrmVals() unless $self->{_prms_loaded};
	$h->{VALUES}=$self->{vals} if $self->{vals};
	return $h;
}

sub M($$) {
	my ($self,$method)=@_;
	return new vCMS::Method($self,$method);
}

sub m($$) {
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

sub ExecuteAsync($$;$) {
	my ($self,$method,$exectime)=@_;
	my $m=new vCMS::Method($self,$method);
	return $m->ExecuteAsync($exectime);
}


sub CheckAsync($$) {
	my ($self,$method)=@_;
	my $m=new vCMS::Method($self,$method,$exectime);
	return $m->CheckAsync();
}


sub ea($$;$) {
	return ExecuteAsync($_[0],$_[1],$_[2]);
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



=item History( $pObj, $opts )

Returns params history 

Examples:


o(OBJECTKEY)->History(PRMNAME);
o(OBJECTKEY)->History({prm=>PRMNAME});

Options hashref:

prm - returns single param history

=cut




sub History($;$) {
	my ($self,$opts) = @_;
	return vCMS::Proxy::History($self->ID,$opts);
}

sub DelHistory($;$) {
	my ($self,$opts) = @_;
	return vCMS::Proxy::DelHistory($self->ID,$opts);
}



1;