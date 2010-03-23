package cmlajax;

# $Id: cmlajax.pm,v 1.15 2010-03-23 20:27:20 vano Exp $

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
       	$r->{value} = Encode::encode('cp1251',Encode::decode('utf8',$r->{value})) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=setvalue($r);
		return ({status=>enc($status?'Изменения сохранены':'Ошибка сохранения изменений')});
}



sub ajax_editmethod ($)
{
		my ($r)=@_;
       	$r->{value} = Encode::encode('cp1251',Encode::decode('utf8',$r->{value})) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=editmethod($r);
		return ({status=>enc($status?'Изменения сохранены':'Ошибка сохранения изменений')});

}


sub ajax_addobject ($;$$$$)
{
	my ($up,$link,$linkval,$name,$upobj)=@_;
	my $newid;
	$name ||= enc('Новый');
	if ($upobj) {   
			$newid=addlowobject({name=>$name,upobj=>$upobj,up=>$up});
	} else {   
			$newid=addlowobject({name=>$name,upobj=>$up});
	}
	if ($link) {    
		setvalue ({id=>$newid,prm=>$link,value=>$linkval});
	}
	return enc("Новый объект создан");

	
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