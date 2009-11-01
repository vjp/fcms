package cmlcalc;

BEGIN
{
 use Exporter();
 use Data::Dumper;
 use Time::Local;
 eval {require Time::HiRes };


 @ISA = 'Exporter';
 @EXPORT = qw( &calculate  &initcalc %gtype $OBJID $PARID $PARTYPE $CGIPARAM $ENV $NOPARSE $DEBUG &execute &scripteval $TIMERS
               $SITEVARS $LANGUAGE $SCRIPTOUT);
}

sub initcalc
{

  $gtype{TEXT}={
                 retvalue   =>\&rettext
               };
  $gtype{FLAG}={
                 retvalue   =>\&rettext
               };
  $gtype{NUMBER}={
                 retvalue   =>\&rettext
               };
  $gtype{LONGTEXT}={
                 retvalue   =>\&retmemo
               };
  $gtype{DATE}={
                 retvalue   =>\&rettext
               };
  $gtype{LIST}={
                 retvalue   =>\&rettext
               };
  $gtype{MATRIX}={
                 retvalue   =>\&rettext
               };
  $gtype{PICTURE}={
                 retvalue   =>\&rettext
               };
  $gtype{FILE}={
                 retvalue   =>\&rettext
               };
  $gtype{VIDEO}={
                 retvalue   =>\&rettext
               };
  $gtype{SCRIPT}={
                 retvalue   =>\&retempty
               };
                 


}


sub scripteval {
		eval  "use cmlmain;\n$_[0]";
		return $@;
}	


sub set {
	my ($id,$prm,$val)=@_;
	setvalue({id=>$id,prm=>$prm,value=>$val});
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

		my $indx;
		$NOPARSE=$_[0]->{noparse};
		$PARID=$_[0]->{parent};
		$CALCLANG=$_[0]->{lang};
		$DEBUG=$_[0]->{debug};
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
 	}
 	
	my $value=eval "$expr";

	
	my $rf=ref($value);
        my $xvalue;	
	

	
 	unless ((ref $value) eq 'HASH') {
 		$xvalue->{value}=$value; $xvalue->{type}='TEXT';
 	}
 	else {$xvalue=$value}
 	

 	
 	if ($@) {print "Error in expr $_[0]->{expr}:$@"}
 	
 	return $xvalue;
}

sub execute 	{

 	my $method;
  	my @treeid;
 	undef $OBJID;	
 	my $low;
 	  	
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
 		}	
 		elsif ($_[0]->{id})  {
  			if ($_[0]->{id}=~s/^t_(.+)$/$1/)  {
    				(my $tid,my $tpkey,my $tabkey)=($indx=~/^(.+?)_(.+?)_(.+)$/);
    				$indx=$prm->{$tpkey}->{extra}->{cell};
    				@treeid=&cmlmain::treelist($indx);
    				
    				$indx=$_[0]->{id};
    				&cmlmain::checkload({id=>$tid,pkey=>$tpkey,tabkey=>$tabkey});
    				$OBJID=$cmlmain::tobj->{$tid}->{$tpkey}->{vals}->{$tabkey};
  			}
  			elsif ($_[0]->{id}=~s/^u(\d+)$/$1/) {
    				$indx=$_[0]->{id};
    				@treeid=&cmlmain::treelist($indx);
    				$OBJID=$cmlmain::obj->{$indx};    				
  			}
  			else  {		
   				&cmlmain::checkload({id=>$_[0]->{id}});
   				if ($cmlmain::lobj->{$_[0]->{id}}->{template}) {
   					push(@treeid,&cmlmain::treelist($cmlmain::lobj->{$_[0]->{id}}->{template}))
   				}
   				push (@treeid,&cmlmain::treelist($cmlmain::lobj->{$_[0]->{id}}->{upobj}));
   				$OBJID=$cmlmain::lobj->{$_[0]->{id}};   
   				$low=1;				
  			} 
  			
 		}
 		elsif ($_[0]->{key}) {
  			&cmlmain::checkload({key=>$_[0]->{key}});
  			return execute({method=>$method,id=>$cmlmain::nobj->{$_[0]->{key}}->{id}});
 		}
 	}
 	my $res=0;
 	
  if ($low) {
  	$METHODID=$cmlmain::lmethod->{$method};
  	#unless ($METHODID) {$METHODID=$cmlmain::method->{$method}}
	}	else {
  	$METHODID=$cmlmain::method->{$method};
  	#unless ($METHODID) {$METHODID=$cmlmain::lmethod->{$method}}
  }	
 	eval "use cmlmain; $METHODID->{script}";
 	if ($@) {&cmlmain::alert("Ошибка выполнения метода $method : $@") } else {$res=1}

 	
 	
 	#for (@treeid) {
 	#	if ($cmlmain::obj->{$_}->{method}->{$method}) {
 	#		eval "use cmlmain; $cmlmain::obj->{$_}->{method}->{$method}->{script}";
 	#		if ($@) {print "Error in expr $_[0]->{expr}:$@"} else {$res=1}
 	#		last;
 	#	}	
 	#}
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


sub id {
	&cmlmain::checkload({key=>$_[0]});
	return $cmlmain::nobj->{$_[0]}->{id};
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
	return split(/;/,$_[0]);
}
sub env {
	return $cmlcalc::ENV->{$_[0]};
}

sub p	{
 	my $id=$OBJID;
 	my $noparse=$NOPARSE;
 	my $pkey=$_[0];
 	my $lang=$CALCLANG;

 	if (defined $_[1])  {

 		my $ind;
 		
 		if (ref $_[1] eq 'HASH') {$ind=$_[1]->{value}}
 		else 			 {
 			if ($_[1]=~/;/) {
 				return join(';',map {calc($_,"p($pkey)")} split(';',$_[1]) );
 			}	
 			return calc($_[1],"p($pkey)");
 		}	
 		
 		&cmlmain::checkload({id=>$ind});
 		$id=$cmlmain::lobj->{$ind}->{ind};
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
   		}
   		if ($skey eq 'index') { 	return $id->{indx} 	}
   		if ($skey eq 'key') 	{		return $id->{key} 	}
		if ($skey eq 'type')  {		return $id->{type}  }	   		
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
   			my @dl=gmtime(now());
   			if ($n eq 'year')  {return $dl[5]+1900}
   			if ($n eq 'month') {return $dl[4]+1}
   			if ($n eq 'day')   {return $dl[3]}
   			
   			
   	  }	
 	} 
 
 
 	if ($cmlmain::prm->{$pkey}->{type})  {
   		return &{$gtype{$cmlmain::prm->{$pkey}->{type}}->{retvalue}}({id=>$id,pkey=>$pkey,noparse=>$noparse,lang=>$CALCLANG})->{value};
 	}
 	else  {
 		  return undef;
   		# print "CALC ERROR $pkey NOT FOUND"; 	 
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



sub now {
	return timegm(localtime());
}	

sub today {
	return timegm(localtime());
}	



sub distlist {
	my %inh;
	my @rlist;
	for (split(';',$_[0])) {
		unless ($inh{$_}) { push (@rlist,$_); $inh{$_}=1}
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
 	}
 	elsif ($tobj->{type} eq 'L')  {
 		my $uobj=&cmlmain::checkload({id=>$ind,buildtree=>1});
  	@list=sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$uobj}->{$ind}};
 	} 
 	
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

	
  my $tOBJ=$OBJID;
  

  
	my @list;
	if (($uid)=($_[0]=~/u(\d+)/)) {
		$OBJID=$cmlmain::obj->{$uid};
		my $ind=$OBJID->{ind};
		@list=sort {$cmlmain::obj->{$a}->{indx}<=>$cmlmain::obj->{$b}->{indx}} @{$cmlmain::tree->{$ind}};
		map{$_="u$_"}@list;
		push (@list,sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}}@{$cmlmain::ltree->{$ind}->{0}});
		
		
		
	}
	elsif ($_[0]) 		      {
		$OBJID=$cmlmain::lobj->{$_[0]};
		my $ind=$OBJID->{ind};
		my $upobj=$OBJID->{upobj};
		@list=sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$upobj}->{$ind}};
	}
 	elsif ($OBJID->{type} eq 'U') {
		my $ind=$OBJID->{ind};
		&cmlmain::checkload({uid=>$ind}); 
		if ($cmlmain::tree->{$ind}) {
		    @list=sort {$cmlmain::obj->{$a}->{indx}<=>$cmlmain::obj->{$b}->{indx}} @{$cmlmain::tree->{$ind}};
     		map{$_="u$_"}@list;
    } 		
    push (@list,sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}}@{$cmlmain::ltree->{$ind}->{0}});
     
	}	
 	elsif ($OBJID->{type} eq 'L') {
		my $ind=$OBJID->{ind};
		my $upobj=$OBJID->{upobj};
		&cmlmain::checkload({uid=>$upobj}); 		
		@list=sort {$cmlmain::obj->{$a}->{indx}<=>$cmlmain::obj->{$b}->{indx}} @{$cmlmain::ltree->{$upobj}->{$ind}};
	}
	
	if ($_[1]) {@list=grep(calc($_,$_[1]),@list)}
	$OBJID=$tOBJ;
 	return join (';',@list);
}	

sub calc {
	my $id=$_[0];
	my $expr=$_[1];
	my $tOBJ=$OBJID;
	my $v=calculate({id=>$id,expr=>$expr})->{value};
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
 my $pkey;
 if ($_[0]->{pkey})  {$pkey=$_[0]->{pkey}}
 elsif ($_[0]->{param}) {$pkey=$_[0]->{param}}
 else {return 0}
 
 my $fh;
 my $fname;
 if ($_[0]->{cgiparam}) {
 	 $fh=$_[0]->{cgiparam};
 	 $fname=$_[0]->{cgiparam}; 
 } else {return 0}
 

 
 my $objid;
 my $objuid;
 
 if    ($_[0]->{id})    {$objid=$_[0]->{id}}
 elsif ($_[0]->{uid})   {$objuid=$objuid=$_[0]->{uid}}
 else  {return 0}
 
 
 my $tabkey=$_[0]->{tabkey};
 my $tabpkey=$_[0]->{tabpkey};

 
 if    ($objid)  { $fname=~s{^.+\\(.+?)$}{${objid}_${pkey}_$1}i }
 elsif ($objuid) { $fname=~s{^.+\\(.+?)$}{${objuid}_${pkey}_$1}i }
 

 
 open FILE,">$GLOBAL->{FILEPATH}/$fname" ||die $!;
 binmode FILE;  
 while (<$fh>) { 
 	print FILE; 
 }
 close  FILE || die $!;
 setvalue({id=>$objid,uid=>$objuid,pkey=>$pkey,value=>$fname,tabkey=>$tabkey,tabpkey=>$tabpkey});
}





return 1;


END {}
