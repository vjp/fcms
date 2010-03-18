package cmlajax;

# $Id: cmlajax.pm,v 1.8 2010-03-18 19:22:18 vano Exp $

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
		my ($objid,$objuid,$prm,$lang,$value)=@_;
       	$value = Encode::encode('cp1251',Encode::decode('utf8',$value)) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=setvalue({id=>$objid,uid=>$objuid,prm=>$prm,lang=>$lang,value=>$value});
		return enc($status?'Изменения сохранены':'Ошибка сохранения изменений');
}


sub ajax_editmethod ($$$)
{
		my ($objid,$mname,$value)=@_;
       	$value = Encode::encode('cp1251',Encode::decode('utf8',$value))  unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=editmethod({id=>$objid,pkey=>$mname,script=>$value});
		return enc($status?'Изменения сохранены':'Ошибка сохранения изменений');
}


sub ajax_editlmethod ($$$)
{
		my ($objid,$mname,$value)=@_;
       	$value = Encode::encode('cp1251',Encode::decode('utf8',$value)) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=editmethod({id=>$objid,pkey=>$mname,script=>$value,nflag=>1});
		return enc($status?'Изменения сохранены':'Ошибка сохранения изменений');
	
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
	my ($objid)=@_;
	my $status=deletelowobject($objid);
	return enc($status?"Объект удален":"Ошибка удаления объекта");
}

sub ajax_evalscript ($)
{
	my ($script)=@_;
	$script = Encode::encode('cp1251',Encode::decode('utf8',$script)) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
	my $error=&cmlcalc::scripteval($script);
	if ($error) {
		return enc("Ошибка выполнения скрипта").": <b>$error</b> <hr> ".enc('Исходный текст').": <br> $script";
	} else {
		return enc('<hr/>Выполнено без ошибок');
	}	
}


return 1;

END {}