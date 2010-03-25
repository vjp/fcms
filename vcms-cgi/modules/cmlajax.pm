package cmlajax;

# $Id: cmlajax.pm,v 1.18 2010-03-25 22:44:42 vano Exp $

BEGIN
{
 use Exporter();
 use cmlmain;
 use cmlcalc;
 @ISA = 'Exporter';
 @EXPORT = qw( );

}



sub ajax_setvalue ($$$$$)
{
		my ($r)=@_;
       	$r->{value} = Encode::encode('cp1251',$r->{value}) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
       	if ($cmlmain::prm->{$r->{prm}}->{type} eq 'FILELINK') {
       		my $val=calculate({id=>$r->{id},uid=>$r->{uid},expr=>"p($r->{prm})",noparse=>1,lang=>$r->{lang}});
       		my $fn=">$GLOBAL->{FILEPATH}/../$val->{value}";
       		open (FH,$fn);
       		print FH $r->{value};
       		close FH; 
       		my $status=1;
       		return ({status=>enc($status?"Содержимое файла изменено $fn":'Ошибка сохранения изменений')});
       	} else {
			my $status=setvalue($r);
			return ({status=>enc($status?'Изменения сохранены':'Ошибка сохранения изменений')});
       	}	
}



sub ajax_editmethod ($)
{
		my ($r)=@_;
       	$r->{value} = Encode::encode('cp1251',$r->{value}) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=editmethod($r);
		return ({status=>enc($status?'Изменения сохранены':'Ошибка сохранения изменений')});

}


sub ajax_addobject ($)
{
		my ($r)=@_;
		my $newid;
		$r->{name} ||= enc('Новый');
		if ($r->{upobj}) {   
				$newid=addlowobject({name=>$r->{name},upobj=>$r->{upobj},up=>$r->{up}});
		} else {   
				$newid=addlowobject({name=>$r->{name},upobj=>$r->{up}});
		}
		if ($r->{link}) {    
			setvalue ({id=>$newid,prm=>$r->{link},value=>$r->{linkval}});
		}
		return ({status=>enc("Новый объект создан")});
}


sub ajax_deleteobject ($)
{
	my ($r)=@_;
	my $status=deletelowobject($r->{id});
	return ({status=>enc($status?'Объект удален':'Ошибка удаления объекта')});
}

sub ajax_console ($)
{
	my ($r)=@_;
	my $script=$r->{script};
	$script=Encode::encode('cp1251',$script) unless $GLOBAL->{CODEPAGE} eq 'utf-8';;
	my ($result,$error)=&cmlcalc::scripteval($script);
	if ($error) {
		return ({result=>$error,status=>'ERROR',source=>$script});
	} else {
		return ({result=>$result,status=>'SUCCESS',source=>$script});
	}	
}




return 1;

END {}