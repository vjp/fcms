package cmlajax;

# $Id: cmlajax.pm,v 1.11 2010-03-23 06:13:55 vano Exp $

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
		return enc($status?'��������� ���������':'������ ���������� ���������');
}


sub ajax_editmethod ($$$)
{
		my ($objid,$mname,$value)=@_;
       	$value = Encode::encode('cp1251',Encode::decode('utf8',$value))  unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=editmethod({id=>$objid,pkey=>$mname,script=>$value});
		return enc($status?'��������� ���������':'������ ���������� ���������');
}


sub ajax_editlmethod ($$$)
{
		my ($objid,$mname,$value)=@_;
       	$value = Encode::encode('cp1251',Encode::decode('utf8',$value)) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
		my $status=editmethod({id=>$objid,pkey=>$mname,script=>$value,nflag=>1});
		return enc($status?'��������� ���������':'������ ���������� ���������');
	
}


sub ajax_addobject ($;$$$$)
{
	my ($up,$link,$linkval,$name,$upobj)=@_;
	my $newid;
	$name ||= enc('�����');
	if ($upobj) {   
			$newid=addlowobject({name=>$name,upobj=>$upobj,up=>$up});
	} else {   
			$newid=addlowobject({name=>$name,upobj=>$up});
	}
	if ($link) {    
		setvalue ({id=>$newid,prm=>$link,value=>$linkval});
	}
	return enc("����� ������ ������");

	
}


sub ajax_deleteobject ($)
{
	my ($objid)=@_;
	my $status=deletelowobject($objid);
	return enc($status?"������ ������":"������ �������� �������");
}

sub ajax_console ($)
{
	my ($r)=@_;
	my $script=$r->{script};
	$script=Encode::encode('cp1251',$script) unless $GLOBAL->{CODEPAGE} eq 'utf-8';;
	my ($result,$error)=&cmlcalc::scripteval($script);
	if ($error) {
		return ({result=>$error,status=>enc('������'),source=>$script});
	} else {
		return ({result=>$result,status=>enc('�����'),source=>$script});
	}	
}


sub ajax_evalscript ($)
{
	my ($script)=@_;
	$script = Encode::encode('cp1251',Encode::decode('utf8',$script)) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
	my $error=&cmlcalc::scripteval($script);
	if ($error) {
		return ": <b>$error</b> <hr> <br> $script";
		#return enc("������ ���������� �������").": <b>$error</b> <hr> ".enc('�������� �����').": <br> $script";
	} else {
		return '<hr/> SUCCESS ��������� ��� ������' ;
	}	
}


return 1;

END {}