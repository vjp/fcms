package cmlajax;

# $Id: cmlajax.pm,v 1.7 2010-03-18 07:07:06 vano Exp $

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
		return $status?name("��������� ���������"):name('������ ���������� ���������');
}


sub ajax_editmethod ($$$)
{
	my ($objid,$mname,$value)=@_;
       	my $evalue = Encode::encode('cp1251',Encode::decode('utf8',$value));
	my $status=editmethod({id=>$objid,pkey=>$mname,script=>$evalue});
	return $status?"��������� ���������":'������ ���������� ���������';
}


sub ajax_editlmethod ($$$)
{
	my ($objid,$mname,$value)=@_;
       	my $evalue = Encode::encode('cp1251',Encode::decode('utf8',$value));
	my $status=editmethod({id=>$objid,pkey=>$mname,script=>$evalue,nflag=>1});
	return $status?"��������� ���������":'������ ���������� ���������';
	
}


sub ajax_addobject ($;$$$$)
{
	my ($up,$link,$linkval,$name,$upobj)=@_;
	my $newid;
	$name ||= '�����';
	if ($upobj) {   
			$newid=addlowobject({name=>$name,upobj=>$upobj,up=>$up});
	} else {   
			$newid=addlowobject({name=>$name,upobj=>$up});
	}
	if ($link) {    
		setvalue ({id=>$newid,prm=>$link,value=>$linkval});
	}
	return "����� ������ ������";

	
}


sub ajax_deleteobject ($)
{
	my ($objid)=@_;
	my $status=deletelowobject($objid);
	return $status?"������ ������":"������ �������� �������";
}

sub ajax_evalscript ($)
{
	my ($script)=@_;
	$script = Encode::encode('cp1251',Encode::decode('utf8',$script)) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
	my $error=&cmlcalc::scripteval($script);
	if ($error) {
		return name("������ ���������� �������").": <b>$error</b> <hr> ".name('�������� �����').": <br> $script";
	} else {
		return name('<hr/>��������� ��� ������');
	}	
}


return 1;

END {}