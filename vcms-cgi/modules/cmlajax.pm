package cmlajax;

# $Id: cmlajax.pm,v 1.23 2010-04-27 20:22:36 vano Exp $

BEGIN
{
 use Exporter();
 use cmlmain;
 use cmlcalc;
 @ISA = 'Exporter';
 @EXPORT = qw( );

}



sub ajax_setvalue ($)
{
		my ($r)=@_;
       	$r->{value} = Encode::encode('cp1251',$r->{value}) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
       	if ($cmlmain::prm->{$r->{prm}}->{type} eq 'FILELINK') {
       		my $val=calculate({id=>$r->{id},uid=>$r->{uid},expr=>"p($r->{prm})",noparse=>1,lang=>$r->{lang}});
       		my $fn=">$GLOBAL->{FILEPATH}/../$val->{value}";
       		my $status=(open (FH,$fn))&&(print FH $r->{value})&&(close FH); 
       		return ({status=>enc($status?"Содержимое файла изменено":'Ошибка сохранения изменений')});
       	} else {
			my $status=setvalue($r);
			return ({status=>enc($status?'Изменения сохранены':'Ошибка сохранения изменений')});
       	}	
}



sub ajax_editmethod ($)
{
		my ($r)=@_;
       	$r->{script} = Encode::encode('cp1251',$r->{script}) unless $GLOBAL->{CODEPAGE} eq 'utf-8';
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
	my $status;
	if ($r->{parseprm}) {
		my $id=$r->{deleteid} || $r->{id};
		my $prm=$r->{parseprm};
		my $val=$r->{parseid};
		my @oldval=split (';',&cmlcalc::p($prm,$id));
		my @newval;
		for (@oldval){
  			push(@newval,$_) if $_ ne $val; 	
		}
		$status=setvalue({id=>$id,prm=>$prm,value=>join(';',@newval)});
	} else {
		$status=deletelowobject($r->{parseid});
	}
	return ({status=>enc($status?'Объект удален ':'Ошибка удаления объекта')});
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

sub ajax_execute ($)
{
	my ($r)=@_;
	my $result=execute($r);
	if (ref $result ne 'HASH') {
		if ($r->{method}) {
			$result=({
				status=>0,
				message=>enc("Ошибка выполнения. Объект:$r->{id} Метод:$r->{method} : ").$result,
			});
		} elsif ($r->{lmethod}) {
			$result=({
				status=>0,
				message=>enc("Ошибка выполнения. Объект:$r->{id} Метод нижних объектов:$r->{lmethod} : ").$result,
			});
		} else {
			$result=({
				status=>0,
				message=>enc("Ошибка выполнения. Метод не определен"),
			});
		}
	}
	return $result;
}


return 1;

END {}