package cmlajax;

# $Id: cmlajax.pm,v 1.4 2010-02-22 09:03:00 vano Exp $

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
       	my $evalue = Encode::encode('cp1251',Encode::decode('utf8',$value));
	my $status=setvalue({id=>$objid,uid=>$objuid,prm=>$prm,lang=>$lang,value=>$evalue});
	return $status?"Изменения сохранены":'Ошибка сохранения изменений';
}


sub ajax_editmethod ($$$)
{
	my ($objid,$mname,$value)=@_;
       	my $evalue = Encode::encode('cp1251',Encode::decode('utf8',$value));
	my $status=editmethod({id=>$objid,pkey=>$mname,script=>$evalue});
	return $status?"Изменения сохранены":'Ошибка сохранения изменений';
}


sub ajax_editlmethod ($$$)
{
	my ($objid,$mname,$value)=@_;
       	my $evalue = Encode::encode('cp1251',Encode::decode('utf8',$value));
	my $status=editmethod({id=>$objid,pkey=>$mname,script=>$evalue,nflag=>1});
	return $status?"Изменения сохранены":'Ошибка сохранения изменений';
	
}


sub ajax_addobject ($;$$$$)
{
	my ($up,$link,$linkval,$name,$upobj)=@_;
	my $newid;
	$name ||= 'Новый';
	if ($upobj) {   
			$newid=addlowobject({name=>$name,upobj=>$upobj,up=>$up});
	} else {   
			$newid=addlowobject({name=>$name,upobj=>$up});
	}
	if ($link) {    
		setvalue ({id=>$newid,prm=>$link,value=>$linkval});
	}
	return "Новый объект создан";

	
}


sub ajax_deleteobject ($)
{
	my ($objid)=@_;
	my $status=deletelowobject($objid);
	return $status?"Объект удален":"Ошибка удаления объекта";
}

sub ajax_evalscript ($)
{
	my ($script)=@_;
	my $error=&cmlcalc::scripteval($script);
	if ($error) {
		return "Ошибка выполнения скрипта: <b>$error</b> <hr> Исходный текст: <br> $script";
	} else {
		return '<hr/>Выполнено без ошибок';
	}	
}


return 1;

END {}