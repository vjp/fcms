package cmlcalc;
 


BEGIN
{
 use Exporter();
 use Data::Dumper;
 use Time::Local;
 use Time::HiRes qw (time);
 use JSON::PP;
 use POSIX;


 @ISA = 'Exporter';
 @EXPORT = qw( &calculate  &initcalc %gtype $OBJID $PARID $PARTYPE $CGIPARAM $ENV $NOPARSE $DEBUG &execute &scripteval $TIMERS
               $SITEVARS $LANGUAGE $SCRIPTOUT $STOPCACHE $VPARAM  @CSVCOLS  @CSVROWS $ROWID  $CSVMODE &rpcexec);
}

sub initcalc
{
  %gtype=(
  	TEXT	=>	{retvalue   =>\&rettext},
  	FLAG	=>	{retvalue   =>\&rettext},
  	NUMBER	=>	{retvalue   =>\&rettext},
  	LONGTEXT=>  {retvalue   =>\&retmemo},
  	DATE	=>	{retvalue   =>\&rettext},
  	LIST	=>	{retvalue   =>\&rettext},
  	MATRIX	=>	{retvalue   =>\&rettext},
  	PICTURE	=>	{retvalue   =>\&rettext},
  	FILE	=>	{retvalue   =>\&rettext},
  	VIDEO 	=>	{retvalue   =>\&rettext},
  	AUDIO	=>	{retvalue   =>\&rettext},
  	SCRIPT	=>	{retvalue   =>\&retempty},
  	FILELINK=>	{retvalue   =>\&rettext},
  );
}

sub jsoncookie ($) {
	my ($name)=@_;
	my $cval=CGI::cookie($name=~/^__CJ_/?$name:"__CJ_$name");
	return undef unless $cval;
	return decode_json($cval);
}


sub scripteval {
	$cmlcalc::CGIPARAM->{_MODE}='CONSOLE';
	my $r=eval "use cmlmain;use vCMS;$_[0]";
	return (@LOG?viewlog():$r,$@);
}	


sub set {
	my ($id,$prm,$val)=@_;
	if (ref $prm eq 'HASH') {
		&cmlmain::setvalue({id=>$id,prm=>$_,value=>$prm->{$_}}) for keys %$prm;
		return 1;	
	} else {
		return &cmlmain::setvalue({id=>$id,prm=>$prm,value=>$val});
	}	
}

sub app {
	my ($id,$prm,$val)=@_;
	if (ref $prm eq 'HASH') {
		&cmlmain::setvalue({id=>$id,prm=>$_,value=>$prm->{$_},append=>1}) for keys %$prm;
		return 1;	
	} else {
		return &cmlmain::setvalue({id=>$id,prm=>$prm,value=>$val,append=>1});
	}	
}



sub setv {
	my ($id,$prm,$val)=@_;
	$VPARAM->{$id}->{$prm}=$val;
}

sub fix ($$) {
	my ($id,$prm)=@_;
	cmlmain::checkload({id=>$id});
	my $v=defaultvalue({id=>$id,pkey=>$pkey});
	set ($id,$prm,$v->{value});
	return $v->{value};
}


sub setenv 
{
	if (ref $_[1] eq 'HASH') {
		setenvhash(@_);
	} else {
		my ($prm)=shift @_;
		$cmlcalc::ENV->{$prm}=join(';',@_);
	}	
}

sub setenvhash 
{
	my ($name)=shift @_;
	my ($key)=shift @_;
	if (ref $key eq 'HASH') {
		for my $hkey (keys %$key) {
			$cmlcalc::ENV->{$name}->{$hkey}=(ref $key->{$hkey} eq 'ARRAY')?join(';',@{$key->{$hkey}}):$key->{$hkey};
		}	
	} else {
		$cmlcalc::ENV->{$name}->{$key}=join(';',@_);
	}	
}

sub add ($;$){
	my ($up,$prms)=@_;
	return undef unless $up;
	my $newid=&cmlmain::addlowobject({upobj=>$up});
	if ($prms) {
		for my $prm (keys %$prms) {
			&cmlmain::setvalue({id=>$newid,prm=>$prm,value=>$prms->{$prm}});
		}
	}	
	return $newid;
}


sub clear {
	my ($prm,$id)=@_;
	$id=$OBJID->{id} unless $id;
	my @l=grep {p(_UP,$_)} l(p($prm,$id)); 
	set($id,$prm,join(';',@l));
}

sub fs {
	my $prm=$_[0];
	my $pattern=$_[1];
	my $up=$_[2];
	#$up=$OBJID->{id} unless $up;
	return join ';' , &cmlmain::fastsearch({prm=>$prm,pattern=>$pattern,up=>$up}); 
}	


sub calculate 	{
 	undef $OBJID;
 	undef $CALCLANG;
 	undef $DEBUG;
 	my $expr;




 	if (ref $_[0] eq 'HASH')   {

		my $ts=time();
		
		my $indx;
		$NOPARSE=$_[0]->{noparse};
		$PARID=$_[0]->{parent};
		$CALCLANG=$_[0]->{lang};
		$DEBUG=$_[0]->{debug};
		$CSVMODE=1 if $_[0]->{csv};
 		if    ($_[0]->{tabpkey})  {
 			$indx=$_[0]->{tabkey};
 			$id=$_[0]->{id};
 			$pkey=$_[0]->{tabpkey};
 			&cmlmain::checkload({id=>$id,pkey=>$pkey,tabkey=>$indx});
 			$OBJID=$cmlmain::tobj->{$id}->{$pkey}->{vals}->{$indx};
 		}	
 		elsif ($_[0]->{id})  {
 			  if (ref $_[0]->{id} eq 'HASH') {
 			  	  $OBJID=$_[0]->{id};
 				}	elsif ($_[0]->{id}=~s/^t_(.+)$/$1/)  {
    				$indx=$_[0]->{id};
    				(my $tid,my $tpkey,my $tabkey)=($indx=~/^(.+?)_(.+?)_(.+)$/);
    				&cmlmain::checkload({id=>$tid,pkey=>$tpkey,tabkey=>$tabkey});
    				$OBJID=$cmlmain::tobj->{$tid}->{$tpkey}->{vals}->{$tabkey};
  			} elsif ($_[0]->{id}=~s/^u(\d+)$/$1/) {
    				$indx=$_[0]->{id};
    				$OBJID=$cmlmain::obj->{$indx};
  			} elsif ($_[0]->{id}=~s/^v(\d+)$/$1/) {
    				$indx=$_[0]->{id};
    				$cmlmain::vobj->{$indx}->{type}='V';
    				$cmlmain::vobj->{$indx}->{ind}=$indx;
    				$OBJID=$cmlmain::vobj->{$indx};
  			} elsif ($_[0]->{id}=~s/^p(.+)$/$1/) {
    				$indx=$_[0]->{id};
    				$OBJID=$cmlmain::prm->{$indx};
  			}	else  {		
   				&cmlmain::checkload({id=>$_[0]->{id}});
   				$indx=$_[0]->{id};
   				$OBJID=$cmlmain::lobj->{$indx};
  			} 
 		}
 		elsif ($_[0]->{key}) {
  			&cmlmain::checkload({key=>$_[0]->{key}});
  			$OBJID=$cmlmain::nobj->{$_[0]->{key}};
  			
 		}
 		elsif ($_[0]->{ukey}) {
  			$OBJID=$cmlmain::nobj->{$_[0]->{ukey}};
 		}
 		elsif ($_[0]->{uid}) {
  			$indx=$_[0]->{uid};
  			$OBJID=$cmlmain::obj->{$indx};
 		}
 		$expr=$_[0]->{expr};
 		
 		push (@CACHELINKS,$OBJID->{id}) if $CACHEING;
 		
 		
 		my $t=time()-$ts;	
   		$cmlmain::GLOBAL->{timers}->{cc}+=$t;
   		$cmlmain::GLOBAL->{timers}->{ccc}++;
 	}
 	my $xvalue;
	my $need_save;
	my $cache_key;
	if ($_[0]->{cache}) {
		$cache_key=$cmlmain::GLOBAL->{MULTIDOMAIN}?"$ENV{'SERVER_NAME'}$ENV{'REQUEST_URI'}":$ENV{'REQUEST_URI'};
		$cache_key=~s/^www\.// if $cmlmain::GLOBAL->{MULTIDOMAIN};
		$cache_key=~s/\?.+$//;
		my ($cached_value,$cached_time)=&cmlmain::fromcache($cache_key,$cmlcalc::ENV->{dev},$CALCLANG);
		if ($cached_value) {
			
			$xvalue->{value}=&cmlparse::cmlparser({
				data=>$cached_value,
				objid=>$OBJID,
				debug=>$DEBUG,
				inner=>{
					dyncalc=>1
				},
			});
			if ($cached_value eq $xvalue->{value}) {
				$xvalue->{lmtime}=$cached_time
			}
			$xvalue->{type}='TEXT';
			$xvalue->{cached}=1;
			return $xvalue;
		} else {
			$need_save=1;
			$CACHEING=1;
			$STOPCACHE=0;
			@CACHELINKS = ($OBJID->{id});
		}		 			
	}
	
	my $value=eval "use vCMS;$expr";
	if ($@) {print "Error in expr $_[0]->{expr}:$@"}
	if (ref $value eq 'HASH') {
		$xvalue=$value;
	} else {
 		$xvalue->{value}=$value; 
 		$xvalue->{type}='TEXT';
 	}

        if ($need_save) {
        	if ($STOPCACHE){
        	    &cmlmain::dropcache($cache_key,$cmlcalc::ENV->{dev},$CALCLANG);
        	} else {
        		&cmlmain::tocache($cache_key,$xvalue->{value},\@CACHELINKS,$cmlcalc::ENV->{dev},$CALCLANG);
        	}	
        	$CACHEING=0;
        	$xvalue->{value}=&cmlparse::cmlparser({
        		data=>$xvalue->{value},
        		objid=>$OBJID,
        		debug=>$DEBUG,
        		inner=>{
					dyncalc=>1
				},
        	});
        }   	

    if ($_[0]->{csv}) {
    	$xvalue->{value}=join("\r\n",@cmlcalc::CSVROWS);
    	$CSVMODE=0;
    }
    return $xvalue;	
  
 	
}


sub execute 	{

 		my $method;
  		my @treeid;
 		undef $OBJID;	
 		my $low;
 	  	my $xts=time();
 		if (ref $_[0] eq 'HASH')   {

    		if ($_[0]->{method}) {
				$method=$_[0]->{method};
			} elsif ($_[0]->{lmethod}) 	{
				$method=$_[0]->{lmethod};
				$low=1;
			}	
			my $indx;
 			if    ($_[0]->{tabpkey})  {
 				$indx=$prm->{$_[0]->{tabpkey}}->{extra}->{cell};
 				@treeid=&cmlmain::treelist($indx);
 				$indx=$_[0]->{tabkey};
 			
 				$id=$_[0]->{id};
 				$pkey=$_[0]->{tabpkey};
 				&cmlmain::checkload({id=>$id,pkey=>$pkey,tabkey=>$indx});
 				$OBJID=$cmlmain::tobj->{$id}->{$pkey}->{vals}->{$indx};
 			} elsif ($_[0]->{id})  {
  				if ($_[0]->{id}=~s/^t_(.+)$/$1/)  {
    				(my $tid,my $tpkey,my $tabkey)=($indx=~/^(.+?)_(.+?)_(.+)$/);
    				$indx=$prm->{$tpkey}->{extra}->{cell};
    				@treeid=&cmlmain::treelist($indx);
    				
    				$indx=$_[0]->{id};
    				&cmlmain::checkload({id=>$tid,pkey=>$tpkey,tabkey=>$tabkey});
    				$OBJID=$cmlmain::tobj->{$tid}->{$tpkey}->{vals}->{$tabkey};
  				}	elsif ($_[0]->{id}=~s/^u(\d+)$/$1/) {
    				$indx=$_[0]->{id};
    				@treeid=&cmlmain::treelist($indx);
    				$OBJID=$cmlmain::obj->{$indx};    				
  				}	else  {		
   					&cmlmain::checkload({id=>$_[0]->{id}});
   					if ($cmlmain::lobj->{$_[0]->{id}}->{template}) {
   						push(@treeid,&cmlmain::treelist($cmlmain::lobj->{$_[0]->{id}}->{template}))
   					}
   					push (@treeid,&cmlmain::treelist($cmlmain::lobj->{$_[0]->{id}}->{upobj}));
   					$OBJID=$cmlmain::lobj->{$_[0]->{id}};   
   				} 
  			
 			}	elsif ($_[0]->{key}) {
  				&cmlmain::checkload({key=>$_[0]->{key}});
  				return execute({method=>$method,id=>$cmlmain::nobj->{$_[0]->{key}}->{id}});
 			}
 		}
 		my $res=0;
 	
  		if ($low) {
  			$METHODID=$cmlmain::lmethod->{$method} || $cmlmain::method->{$method};
		}	else {
  			$METHODID=$cmlmain::method->{$method} || $cmlmain::lmethod->{$method};
  		}	
 		my $ev=eval "use cmlmain; $METHODID->{script}";
 		unless($METHODID->{script}) {
 		
 			$res=enc($low?"Метод нижних объектов $method не найден":"Метод $method не найден");
 			if (
 				$cmlcalc::CGIPARAM->{_MODE} eq 'USERAJAX' ||
 				$cmlcalc::CGIPARAM->{_MODE} eq 'ADMINAJAX' 
 			) {
 				return $res;	
 			}
			&cmlmain::alert($res);
 		}
 		if ($@) {
 			if (
 				$cmlcalc::CGIPARAM->{_MODE} eq 'USERAJAX' ||
 				$cmlcalc::CGIPARAM->{_MODE} eq 'ADMINAJAX'
 			) {
 				$res=$@;
 			} else {
 				&cmlmain::alert(enc("Ошибка выполнения метода $method : $@"));
 			}	 
 		} else {
 			$res=$ev
 		}

 	
 	
 		#for (@treeid) {
	 	#	if ($cmlmain::obj->{$_}->{method}->{$method}) {
 		#		eval "use cmlmain; $cmlmain::obj->{$_}->{method}->{$method}->{script}";
	 	#		if ($@) {print "Error in expr $_[0]->{expr}:$@"} else {$res=1}
 		#		last;
	 	#	}	
 		#}
 		
 		my $t=time()-$xts;
   		$cmlmain::GLOBAL->{timers}->{et}+=$t;
   		$cmlmain::GLOBAL->{timers}->{etc}++;
 		
        return $res;
}



sub retempty {
	return undef;
}	

sub rettext	{
 	my $objid=$_[0]->{id};
 	my $pkey=$_[0]->{pkey};
 	my $lang=$_[0]->{lang};
 	return &cmlmain::returnvalue({id=>$objid,pkey=>$pkey,lang=>$lang});
}


sub retmemo {
 	my $objid=$_[0]->{id};
 	my $pkey=$_[0]->{pkey};
 	my $lang=$_[0]->{lang};
 	
  
 	
 	my $v=&cmlmain::returnvalue({id=>$objid,pkey=>$pkey,lang=>$lang,noparse=>$_[0]->{noparse}});
 	if (($cmlmain::prm->{$pkey}->{extra}->{parse} eq 'y') && !($_[0]->{noparse}))  {
 		my $inner;
 	 	$inner->{parent}=$PARID;
 	  	$v->{value}=&cmlparse::cmlparser({data=>$v->{value},objid=>$objid->{id},pkey=>$pkey,inner=>$inner,debug=>$DEBUG})
	        
 	}
 	$v->{value}='' unless $v; 
 	return $v;
}

### FUNCTIONS

sub backref {
	my $upper=$_[0];
	my $pkey=$_[1];
	my $condition=$_[2];
	my $id=$_[3] || $OBJID;
	
  if ($cmlmain::prm->{$pkey}->{type} eq 'LIST')  {
   		return &cmlmain::retbackref({id=>$id,upper=>$upper,pkey=>$pkey,condition=>$condition})->{value}
 	}
 	else  {
   		print "BACKREF ERROR: incorrect param $pkey"; 	
   		return undef; 
 	}	  

}	

sub ubackref {
	my $upper=$_[0];
	my $pkey=$_[1];
	my $condition=$_[2];
	my $id=$_[3] || $OBJID;
	
  if ($cmlmain::prm->{$pkey}->{type} eq 'LIST')  {
   		return &cmlmain::retubackref({id=>$id,upper=>$upper,pkey=>$pkey,condition=>$condition})->{value}
 	}
 	else  {
   		print "BACKREF ERROR: incorrect param $pkey"; 	
   		return undef; 
 	}	  

}	



sub prm	{
	my $id;
	if ($_[0]) {
		if ($_[0]=~/;/) {
			return join(';',map {prm($_)} split (';',$_[0]) );
		}
		&cmlmain::checkload({id=>$_[0]});
		$id=$cmlmain::lobj->{$_[0]};
	} else {
		$id=$OBJID;
	}
 	my $pn=$id->{key};
 	$pn=~s/^_PP_//;
 	return $pn;
}

sub prmtype	{
	my $id;
	if ($_[0]) {
		&cmlmain::checkload({id=>$_[0]});
		$id=$cmlmain::lobj->{$_[0]};
	} else {
		$id=$OBJID;
	}
 	my $pn=$id->{key};
 	$pn=~s/^_PP_//;
 	return $cmlmain::prm->{$pn}->{type};
}


sub prmformula	{
 	return &cmlcalc::calculate({id=>$OBJID,expr=>$cmlmain::prm->{$_[0]}->{extra}->{formula}})->{value}
}



sub id {
	return &cmlmain::checkload({key=>$_[0]});
}	

sub position {
	my $i=1;
	my @r;
	for (split(';',$_[1])) {
		push (@r, $i) if $_ eq $_[0];
		$i++; 
	}	
	return join(';',@r);
}


sub count {
	my $lstr=$_[0];
	my @l=split(';',$lstr);
	return scalar @l;
}

sub distinct {
	my %r;
	for (split(';',$_[0])) {
		$r{$_}=1;
	}
	return join ';' , keys %r; 
}

sub days2sec {
	return $_[0]*86400;
}

sub days {
	return int($_[0]/86400);
}
sub l {
	my @l;
	push(@l,split(/;/,$_)) for @_;
	return @l;
}
sub env ($) {
	return $cmlcalc::ENV->{$_[0]};
}

sub envhash($;$) {
	my ($name,$key)=@_;

	$key ||=$OBJID->{id};
	return $cmlcalc::ENV->{$name}->{$key};
}

sub cgi {
	return $cmlcalc::CGIPARAM->{$_[0]} ne 'NULL'?$cmlcalc::CGIPARAM->{$_[0]}:'';
}

sub dev {
	return $cmlcalc::ENV->{dev}?1:0;
}

sub page {
	my ($tname,$cgiparamvalue)=@_;
	my $iscurpage=$cmlcalc::CGIPARAM->{'view'} eq $tname;
	if ($cgiparamvalue) {
		return $iscurpage && ($cmlcalc::CGIPARAM->{'1'} eq $cgiparamvalue);
	} else {
       		return $iscurpage;
	}    	
}

sub inlist {
	my ($list,$elm)=@_;
	return grep {$_ eq $elm} split (';',$list);
}

sub equal {
	return $_[0] eq $_[1];
}

sub calcgt {
	return $_[0] > $_[1];
}

sub calclt {
	return $_[0] < $_[1];
}

sub iscurrent {
	my ($prm,$cgiprmname)=@_;
	$prm = '_ID' unless $prm;
	$cgiprmname = '1' unless $cgiprmname;
	$cgiv=$cmlcalc::CGIPARAM->{$cgiprmname};
	return p($prm) && $cgiv && (p($prm,$cgiv) eq p(_ID));
}

sub splitprice {
	my ($number)=@_;
	$number=~s/(?<=\d)(?=(\d{3})+(?!\d))/ /g;
	return $number;
}


sub csv ($;$$)
{
	my ($oid,$prm,$objid)=@_;
	$prm ||= 'PAGETEMPLATE';
	if($objid) {
		undef @cmlcalc::CSVROWS;
		my $rtext=calc($oid,"p($prm)");
		&cmlparse::cmlparser({data=>$rtext,objid=>$objid}); 
	 	return join("\r\n",@cmlcalc::CSVROWS);
	} else {	
		return calc($oid,"p($prm)",'csv');
	}	
}

sub html ($;$$)
{
	my ($oid,$prm,$objid)=@_;
	$prm ||= 'PAGETEMPLATE';
	if ($objid) {
		&cmlparse::cmlparser({data=>calc($oid,"p($prm)"),objid=>$objid}); 
	} else {
		return calc($oid,"p($prm)");	
	}
}


sub inc (;$$$) {
	my ($pkey,$oid,$icount)=@_;
	return ++$cmlcalc::INCREMENT unless $pkey;
	$icount ||= 1;
	my $val=p($pkey,$oid)+$icount;
	set($oid || p(_ID),$pkey,$val);
	return $val;
}


sub p	{
	
	my ($pkey,$oid)=@_;
 	my $id=$OBJID;
 	my $noparse=$NOPARSE;
 	my $lang=$CALCLANG;
 	
 	if ($pkey=~/;/) {
 		my @r;
 		return join(';',grep {$_ && $_ ne 'NULL'} map {p($_,$oid)} split(';',$pkey));
 	}

 	if (defined $oid)  {

 		my $ind;
 		
 		if (ref $oid eq 'HASH') {
 			$ind=$oid->{value};
 			&cmlmain::checkload({id=>$ind});
 			$id=$cmlmain::lobj->{$ind}->{ind};
 		} else 			 {
 			if ($oid=~/;/) {
 				return join(';', grep {$_} map {calc($_,"p($pkey)")} split(';',$oid) );
 			}
 			return $oid if uc($pkey) eq '_ID';
 			#return calc($oid,"p($pkey)");
 			if ($oid=~/^u(\d+)/) {
 				$id=$cmlmain::obj->{$1};
 			} else {
 				&cmlmain::checkload({id=>$oid});
 				$id=$cmlmain::lobj->{$oid};	
 			}
 			push (@CACHELINKS,$oid) if $CACHEING;	
 			
 		}	
 		
 	}
 	
 	if (($skey)=($pkey=~/^_(.+)$/))  {
   		$skey=lc $skey;	
   		
   		
   		
   		if ($skey eq 'name' || $skey eq 'prmname') {
   			my $name;
   			if ($LANGUAGE)    {$name=$id->{"name_$LANGUAGE"}}
   			if ((not defined $name) || ($name eq ''))  {$name=$id->{name}}
   			return $name;
   			
   		}
   		if ($skey eq 'id')	 {
    			if   ($id->{type} eq 'U') {  return "u$id->{ind}" }
    			elsif($id->{type} eq 'L') {  return "$id->{ind}" }
    			elsif($id->{type} eq 'V') {  return "v$id->{ind}" }
   		}
   		if ($skey eq 'index') 	{ 	return $id->{indx} 	}
   		if ($skey eq 'key') 	{		return $id->{key} 	}
   		if ($skey eq 'upkey') 	{
				if   ($id->{type} eq 'U') {  return p('_KEY',"u$id->{up}") }
    			elsif($id->{type} eq 'L') {  return p('_KEY',"u$id->{upobj}") }
   		}
		if ($skey eq 'type')  	{		return $id->{type}  }	   		
		if ($skey eq 'up')  {
			if   ($id->{type} eq 'U') {  return "u$id->{up}" }
    			elsif($id->{type} eq 'L') {  return "u$id->{upobj}" }
		}
		if ($skey eq 'lang') {
			
			return $id->{lang}
		} 	
   		if ($skey eq 'delimg')	 {  return $cmlmain::DELIMAGEURL }
   		if ($skey eq 'editimg')	 {  return $cmlmain::EDTIMAGEURL }
   		if ($skey eq 'insimg')	 {  return $cmlmain::INSIMAGEURL }
   		if ($skey eq 'imgpath')	 {  return $cmlmain::CMSIMGURL }
   		
   		if ($skey=~/^now(.*)$/) {
   			my $n=$1;
   			if ($n eq '') {return now()}
   			my @dl=localtime(now());
   			if ($n eq 'year')  {return $dl[5]+1900}
   			if ($n eq 'month') {return $dl[4]+1}
   			if ($n eq 'day')   {return $dl[3]}
   			
   			
   	  }	
 	} 
 
 
 	if ($cmlmain::prm->{$pkey}->{type})  {
		my $v=&{$gtype{$cmlmain::prm->{$pkey}->{type}}->{retvalue}}({id=>$id,pkey=>$pkey,noparse=>$noparse,lang=>$CALCLANG})->{value};
		$OBJID=$id unless defined $oid; 
   		return $v; 
 	}
 	else  {
 		  return undef;
 	 
 	}	  
}

sub uobj {
	  if ($_[0]) {
	  	if ($_[0]=~/^u/) {return 'u'.$cmlmain::obj->{$_[0]}->{up}}
	  	else {
	  		cmlmain::checkload({id=>$_[0]});
	  		return 'u'.$cmlmain::lobj->{$_[0]}->{upobj};
	  	}
		}	
   	if    ($OBJID->{type} eq 'U') {  return 'u'.$OBJID->{up} }
   	elsif ($OBJID->{type} eq 'L') {  return 'u'.$OBJID->{upobj} }	
}	

sub up {

	my $level=1;
	my $curid=$OBJID;
	if ($_[0]) {$level=$_[0]}
	
	while ($level--) {
	   	if    ($curid->{type} eq 'L') {  $curid=$cmlmain::lobj->{$curid->{up}} }
	}
	return $curid->{id};
}	

=head

SYNOPSYS

trimstr($verylongstring,$trimsize);

need for trim long strings


=cut
sub trimstr ($$) {
	my ($str,$len)=@_;
	$str=substr($str,1,$len-3).'...' if (length($str)>$len-3);
	return $str;
}

sub now {
	return time();
}	

sub today {
	return time();
}	

sub month {
	my @tm=localtime();
	return mktime(0,0,0,1,$tm[4],$tm[5]);
}

sub day (;$) {
	my ($datestamp)=@_;
	my @tm=$datestamp?localtime($datestamp):localtime();
	return mktime(0,0,0,$tm[3],$tm[4],$tm[5]);
}


sub weekday {
	return strftime('%u',localtime(time()))
} 

sub curyear (;$){
	
	return strftime('%Y',localtime($_[0] || time()))
}

sub curmonth (;$) {
	return strftime('%m',localtime($_[0] || time()))
}

sub curday (;$) {
	return strftime('%d',localtime($_[0] || time()))
}


sub distlist {
	my %inh;
	my @rlist;
	for my $prm (@_) {
		for (split(';',$prm)) {
			unless ($inh{$_}) { push (@rlist,$_); $inh{$_}=1}
  		}
	}		
  	return join (';',@rlist);
}	

sub lowlist {

	my $tobj;
	my @list;
	if (($uid)=($_[0]=~/u(\d+)/)) {$tobj=$cmlmain::obj->{$uid}}
	elsif ($_[0]) 		      {$tobj=$cmlmain::lobj->{$_[0]}}
	else			      {$tobj=$OBJID}
	my $ind=$tobj->{ind};
  	if ($tobj->{type} eq 'U')  {
 		&cmlmain::checkload({uid=>$ind}); 
 		@list=sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$ind}->{0}} ;
 	}	elsif ($tobj->{type} eq 'L')  {
 		my $uobj=&cmlmain::checkload({id=>$ind,buildtree=>1});
  		@list=sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$uobj}->{$ind}};
 	} 
 	push (@CACHELINKS,$tobj->{id}) if $CACHEING; 	
 	if ($_[1]) {
 		 @list=grep(calc($_,$_[1]),@list);
 	}
 	return join(';',@list);
}	

sub plist {
	my $tobj;
	my @list;
	if (($uid)=($_[0]=~/u(\d+)/)) {
		$tobj=$cmlmain::obj->{$uid};
	}
	elsif ($_[0]) 		      {$tobj=$cmlmain::lobj->{$_[0]}}
	else			      {$tobj=$OBJID}
	my $ind=$tobj->{ind};
	
	
	#my $uobj=&cmlmain::checkload({id=>$ind,buildtree=>1});
	&cmlmain::buildlowtree($cmlmain::nobj->{'MAINPRM'}->{ind});
	
	
	if ($tobj->{type} eq 'L') {
	 	@list=&cmlmain::paramlist($ind);
	} elsif ($tobj->{type} eq 'U') {	
    @list=&cmlmain::lparamlist($ind);
  }	
	return join(';',map {$_=$cmlmain::nobj->{"_PP_$_"}->{ind} } @list);
}	


sub lowelms {
	my $ind;
	my @retlist;
	my $uid;
	if (($uid)=($_[0]=~/u(\d+)/)) {$ind=$uid} 
	else {$ind=$OBJID->{ind}}
	&cmlmain::checkload({uid=>$ind}); 
	push (@retlist,sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$ind}->{0}});
 	for (sort {$cmlmain::obj->{$a}->{indx}<=>$cmlmain::obj->{$b}->{indx}} @{$cmlmain::tree->{$ind}}) { push (@retlist,lowelms("u$_")) } 
 	my @xlist;
 	
 	for (@retlist) {push(@xlist,lowlevel($_))}
 	return join(';',(@retlist,@xlist));
}

sub try ($$$) {
	my ($expr,$condition,$count)=@_;
	for (my $i=1;$i<=$count;$i++) {
		my $v=&calculate({id=>$OBJID->{ind},expr=>$expr})->{value};
		my $cv=&calculate({id=>$v,expr=>$condition})->{value};
		return $v if $cv;
	}
	return $undef;
	
}


sub lrnd {
	my $ind;
	my $uid;
	if (($uid)=($_[0]=~/u(\d+)/)) {$ind=$uid} 
	else {$ind=$OBJID->{ind}}
	my $v=&cmlmain::retrnd($ind);
	return $v->{value};
	
	
}

sub urnd {
	my $ind;
	my $uid;
	if (($uid)=($_[0]=~/u(\d+)/)) {$ind=$uid} 
	else {$ind=$OBJID->{ind}}
	my $v=&cmlmain::returnd($ind);
	return $v->{value};
	
}

sub lowlevel {
	my ($low_id,$low_expr)=@_;
	$low_id ||= '';
 	my $tOBJ=$OBJID;
	my @list;
	if (($uid)=($low_id=~/u(\d+)/)) {
		$OBJID=$cmlmain::obj->{$uid};
		my $ind=$OBJID->{ind};
		@list=sort {$cmlmain::obj->{$a}->{indx}<=>$cmlmain::obj->{$b}->{indx}} @{$cmlmain::tree->{$ind}};
		map{$_="u$_"}@list;
		push (@list,sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}}@{$cmlmain::ltree->{$ind}->{0}});
	} elsif ($low_id) 		      {
		$OBJID=$cmlmain::lobj->{$low_id};
		my $ind=$OBJID->{ind};
		my $upobj=$OBJID->{upobj};
		@list=sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$upobj}->{$ind}};
	}	elsif ($OBJID->{type} eq 'U') {
		my $ind=$OBJID->{ind};
		&cmlmain::checkload({uid=>$ind}); 
		if ($cmlmain::tree->{$ind}) {
		    @list=sort {$cmlmain::obj->{$a}->{indx}<=>$cmlmain::obj->{$b}->{indx}} @{$cmlmain::tree->{$ind}};
     		map{$_="u$_"}@list;
    	} 		
    	push (@list,sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}}@{$cmlmain::ltree->{$ind}->{0}});
	} 	elsif ($OBJID->{type} eq 'L') {
		my $ind=$OBJID->{ind};
		my $upobj=$OBJID->{upobj};
		&cmlmain::checkload({uid=>$upobj}); 		
		@list=sort {$cmlmain::obj->{$a}->{indx}<=>$cmlmain::obj->{$b}->{indx}} @{$cmlmain::ltree->{$upobj}->{$ind}} if ref $cmlmain::ltree->{$upobj}->{$ind} eq 'ARRAY';
	}
	
	if ($low_expr) {@list=grep(calc($_,$low_expr),@list)}
	$OBJID=$tOBJ;
 	return join (';',@list);
}	

sub calc {
	my ($id,$expr,$format)=@_;
	my $tOBJ=$OBJID;
	my $v=calculate({
		id=>$id,
		expr=>$expr,
		csv=>$format && ($format eq 'csv')?1:0
	})->{value};
	$OBJID=$tOBJ;
	return $v;
}	

sub min {
	my @list=split(/\s*;\s*/,$_[0]);
	my $expr=$_[1];
	
	my $min='';
	for (@list) {
		my $v=&calculate({id=>$_,expr=>$expr})->{value};
		if ($min eq '' || $v<$min) {$min=$v}
	}
	return $min;	
}	

sub minobj {
	my @list=split(/\s*;\s*/,$_[0]);
	my $expr=$_[1];
	
	my $min='';
	my $minobj;
	for (@list) {
		my $v=&calculate({id=>$_,expr=>$expr})->{value};
		if ($min eq '' || $v<$min) {$min=$v;$minobj=$_}
	}
	return $minobj;	
}	


sub max {
	my @list=split(/\s*;\s*/,$_[0]);
	my $expr=$_[1];

	my $max='';
	for (@list) {
		my $v=&calculate({id=>$_,expr=>$expr})->{value};
		if ($max eq '' || $v>$max) {$max=$v}
	}
	return $max;	
}	

sub sum {
	my @list=split(/\s*;\s*/,$_[0]);
	my $expr=$_[1];

	my $sum=0;
	for (@list) {
		if ($expr) {
			my $v=&calculate({id=>$_,expr=>$expr})->{value};
			$sum+=$v;
		} else {
			$sum+=$_;
		}	
	}
	return $sum;	
}	



sub maxobj {
	my @list=split(/\s*;\s*/,$_[0]);
	my $expr=$_[1];
	
	my $max='';
	my $maxobj;	
	for (@list) {
		my $v=&calculate({id=>$_,expr=>$expr})->{value};
		if ($max eq '' || $v>$max) {$max=$v;$maxobj=$_}
	}
	return $maxobj;	
}	

sub saveformdata {
	my $id=$_[0];
	for (grep (/^_p/,keys %$CGIPARAM)) {   
		(my $prm)=($_=~/_p(.+)/);   
		my $value=$CGIPARAM->{$_};    
		if ($CGIPARAM->{"_d$prm"}) {
			$value=fetchdate($value,$CGIPARAM->{"_d$prm"});   
		}   
		if ($cmlmain::prm->{$prm}->{'type'} eq 'FLAG' && $value) {    	
			$value=1;   
		}   
		setvalue({id=>$id,prm=>$prm,value=>$value});  
	}
	for (grep (/^_f/,keys %$CGIPARAM)) {   
		if ($CGIPARAM->{$_}) {      
			(my $prm)=($_=~/_f(.+)/);      
			uploadprmfile({id=>$id,pkey=>$prm,cgiparam=>$_});   
		}   
	}
	
}
	
sub uploadfile 
{
	my ($objid,$prm,$cgiparamname)=@_;
	uploadprmfile({param=>$prm,id=>$objid,cgiparam=>$cgiparamname});
}


sub resort ($)
{
	use locale;
	my ($ids)=@_;
	my $index=0;
	return map {set($_,'_INDEX',++$index)} sort{ uc(p('_NAME',$a)) cmp uc(p('_NAME',$b)) } split (/;/,$ids);
}


sub baselparser (;$)
{
	my ($opts)=@_;
	my $id;
	if ($CGIPARAM->{insertinto}) {	
		my $lid=$CGIPARAM->{parseid}?$CGIPARAM->{parseid}:$CGIPARAM->{id};	
		$id=addlowobject({upobj=>$CGIPARAM->{insertinto}});	
		if ($CGIPARAM->{link}) {		
			setvalue({id=>$id,prm=>$CGIPARAM->{link},value=>$lid}); 	
		}
	} elsif ( $opts && $opts->{id}) {
	    $id=$opts->{id};
	} elsif ($CGIPARAM->{parseid}) {	
		$id=$CGIPARAM->{parseid};
		
	} else {
		$id=$CGIPARAM->{id}
	}
	my $changed;
    my $ov;
    my $nv;
	my $dt_collector;
	for my $cgiprm (keys %$CGIPARAM) {
		my $value=$CGIPARAM->{$cgiprm};
		
		if (ref $value eq 'ARRAY' && ref $value->[1] eq 'ARRAY') {
		    $value=join(';',grep {$_ ne '0'} @{$value->[1]})	
		}
		
		
		if ($cgiprm=~/^_o(.+?)_p(.+)/) {
			$id=$1;
			my $prm=$2;
			if ($cmlmain::prm->{$prm}->{'type'} eq 'FLAG' && $value) {
				$value=1;
			}
			my $oldval=p($prm,$id);
			$ov->{$id}->{$prm}=$oldval;
			$nv->{$id}->{$prm}=$value;			
			if ($oldval ne $value) {
				#setvalue({id=>$id,prm=>$prm,value=>$value});
				push (@{$changed->{$id}},$prm);
			}
		} if ($cgiprm=~/^_k(.+?)_p(.+)_(u\d+)$/) {
			my $key=$1;
			my $prm=$2;
			my $upper=$3;
			if ($cmlmain::prm->{$prm}->{'type'} eq 'FLAG' && $value) {
				$value=1;
			}
			&cmlmain::checkload({key=>$key});
		    $id=$cmlmain::nobj->{$key}->{id};
		    $id=addlowobject({upobj=>$upper,key=>$key}) unless $id;
			my $oldval=p($prm,$id);
			$ov->{$id}->{$prm}=$oldval;
			$nv->{$id}->{$prm}=$value;			
			if ($oldval ne $value) {
				#setvalue({id=>$id,prm=>$prm,value=>$value});
				push (@{$changed->{$id}},$prm);
			}
	    } elsif ($cgiprm=~/^_p(.+)_d(.)$/) {		
			$dt_collector->{$1}->{$2}=$value;
		} elsif ($cgiprm=~/^_p(.+)/) {
			my $prm=$1;
			if ($CGIPARAM->{"_d$prm"}) {		
				$value=fetchdate($value,$CGIPARAM->{"_d$prm"});	
			}	
			if ($cmlmain::prm->{$prm}->{'type'} eq 'FLAG' && $value) {
				$value=1;
			}
			$nv->{$id}->{$prm}=$value;
			#setvalue({id=>$id,prm=>$prm,value=>$value});
			push (@{$changed->{$id}},$prm);
			if ($CGIPARAM->{renameprm} eq $prm) {
				#setvalue({id=>$id,prm=>'_NAME',value=>$value});
				$nv->{$id}->{_NAME}=$value;
				push (@{$changed->{$id}},'_NAME');
			}
		} elsif ($cgiprm=~/^_f(.+)/ && $value) {
			uploadprmfile({id=>$id,pkey=>$1,cgiparam=>$cgiprm});
			push (@{$changed->{$id}},$1);
		} elsif ($cgiprm=~/^_o(.+?)_f(.+)/ && $value) {
			$id=$1;
			uploadprmfile({id=>$id,pkey=>$2,cgiparam=>$cgiprm});
			push (@{$changed->{$id}},$2);
		}
	}

	for my $oid (keys %$changed) {
		for my $prm (@{$changed->{$oid}}) {
			setvalue({id=>$oid,prm=>$prm,value=>$nv->{$oid}->{$prm}}) if defined $nv->{$oid}->{$prm}
		}
	}
	 
	for my $dtprm (keys %$dt_collector) {
        setvalue({id=>$id,prm=>$dtprm,value=>&cmlmain::compile_date($dt_collector->{$dtprm})});
		push (@{$changed->{$id}},$dtprm);		
	}

	unless ($opts->{silent}) {
		my $alerttext=$CGIPARAM->{alerttext};
		$alerttext=enc('Значения изменены') unless $alerttext;
		alert($alerttext);
	}	
	redir($CGIPARAM->{back}) if $CGIPARAM->{back}; 
	return ({
		status=>1,
		objid=>$id,
		back=>$CGIPARAM->{back},
		changed=>$changed,
		oldval=>$ov,
		newval=>$nv,
	});
}




return 1;


END {}
