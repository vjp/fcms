package cmlmain;

# $Id: cmlmain.pm,v 1.35 2010-03-19 05:50:12 vano Exp $

BEGIN
{
 use Exporter();
 use Data::Dumper;
 use DBI;
 use cmlcalc;
 use cmlparse;
 use Time::Local;
 use Time::HiRes qw /time/;
 use Encode;

 @ISA    = 'Exporter';
 @EXPORT = qw(
              $lobj $nlobj $obj  $vobj $nobj $tobj $tree $ltree $prm  $method $lmethod %ptype @ptypes $dbh

              &checkload	&defaultvalue	&uparamlist &lparamlist
              
              &edit		&editlow	&update
              
              &returnvalue    &init
              &addobject	&addlowobject	&deleteobject   &deletelowobject
              &buildtree	&buildlowtree	&buildparam     &treelist
              &addprm		&deleteprm	&paramlist      &dbconnect
              &setvalue     	&editprm	&setprmextra    &cmlparser
              &start        	&retname  	&copyobject	&returnobject
              &editmethod	&addmethod	&deletemethod	&checkupd
              &copyprm  &copymethod &umethodlist &methodlist
              &loadcmsmethod &createcmsmethod &rebuildcmsmethod &deletecmsmethod
              &uploadprmfile &loaduserlist &adduser &deluser &edituser
              &createhtaccess &fetchdate &fastsearch &fromcache &tocache
              &prefetch &prefetchlist &buildlist &clearcache
              
              &alert &message &viewlog
              
              &fastsearch &isupper &iscompiled &fsindexcreate
              
              $GLOBAL @LANGS %LANGS @SYNC %SYNC
              
              @LOG 
              
              &checkdatastruct &deletelowlist &sync &remote_sync
              
              &prminfo &enc
             );


}






sub returnobject {
	my $id=$_[0];

	if (($uid)=($id=~/u(\d+)/)) {return $obj->{$uid}}
	else			    {
		checkload({id=>$id});
		return $lobj->{$id}
	}
	return undef;
	
}	

sub copyvals {
	my $from=$_[0]->{from};
	my $to=$_[0]->{to};
	my $sthS=$dbh->prepare("REPLACE ${DBPREFIX}vls (objid,pkey,upobj,value) SELECT $to->{ind},pkey,upobj,value FROM vls WHERE objid=? AND pkey!='_NAME'");
	$sthS->execute($from->{ind}) || die $dbh->errstr;
}	
	
sub copyuvals {
	my $from=$_[0]->{from};
	my $to=$_[0]->{to};
	my $sthS=$dbh->prepare("REPLACE ${DBPREFIX}uvls (objid,pkey,value) SELECT $to->{ind},pkey,value FROM uvls WHERE objid=? AND pkey!='_NAME'");
	$sthS->execute($from->{ind}) || die $dbh->errstr;
}	



sub copyobject {
	my $from=returnobject($_[0]->{from});
	my $to=returnobject($_[0]->{to});

	if ($from->{type} eq 'U' && $to->{type} eq 'L') {
		  $to=returnobject("u$_[0]->{to}");
	}	

	
	unless ($from) {print "COPY ERROR >> target $_[0]->{from} not exist"; return}
	unless ($to)   {print "COPY ERROR >> source $_[0]->{to}   not exist"; return}
	
	

	
	if ($from->{type} eq 'L' && $to->{type} eq 'L') {
		my $newid=addlowobject({
				up=>$to->{ind},
				upobj=>$to->{upobj},
				template=>$from->{template},
				name=>$from->{name}
		});
		copyvals ({from=>$from,to=>$lobj->{$newid}});
		for (@{$ltree->{$from->{upobj}}->{$from->{ind}}}) {copyobject({from=>$_,to=>$newid})}
	}
	elsif ($from->{type} eq 'L' && $to->{type} eq 'U') {
		my $newid=addlowobject({
				up=>0,
				upobj=>$to->{ind},
				template=>$from->{template},
				name=>$from->{name}
		});
		copyvals ({from=>$from,to=>$lobj->{$newid}});
		for (@{$ltree->{$from->{upobj}}->{$from->{ind}}}) {copyobject({from=>$_,to=>$newid})}
	}	
	elsif ($from->{type} eq 'U' && $to->{type} eq 'U') {
		my $newid=addobject({
														up=>$to->{ind}, 
														name=>$from->{name},
														template=>$from->{template},
														ltemplate=>$from->{ltemplate},
														indx=>$from->{indx}
												});
		for (@{$obj->{$from->{ind}}->{prm}})						{   copyprm({id=>$newid,key=>$_}) } 												
		for (@{$obj->{$from->{ind}}->{sprm}})						{   copyprm({id=>$newid,key=>$_}) } 												
		for (keys %{$obj->{$from->{ind}}->{method}} ) {   copymethod({id=>$newid,key=>$_}) } 												
		copyuvals({from=>$from,to=>$obj->{$newid}});
		
    for (@{$tree->{$from->{ind}}})            { 	copyobject({from=>"u$_",to=>"u$newid"})   }
	}	
	
}	

sub start {
 	init($_[0]);
 	buildtree();
 	buildparam();
 	initcalc();
 	initparser();
}

sub retname {
	if ($_[0]=~/^u(\d+)$/) {return $obj->{$1}->{name}}
	elsif ($_[0]=~/^p(.+)$/)   {return $prm->{$1}->{name}}
	else			 	{checkload({id=>$_[0]}); return $lobj->{$_[0]}->{name}}
}	


sub setprmextra
{
  my $sth=$dbh->prepare("REPLACE ${DBPREFIX}extraprm (pkey,extra,value) VALUES (?,?,?)");
  $sth->execute($_[0]->{pkey},$_[0]->{extra},$_[0]->{value}) || die $dbh->errstr;
  $prm->{$_[0]->{pkey}}->{extra}->{$_[0]->{extra}}=$_[0]->{value};
}


sub editmethod  {
	
	if ($_[0]->{nflag}) {
		
		my $script=$obj->{$_[0]->{id}}->{lmethod}->{$_[0]->{pkey}}->{script};
		my $name=$obj->{$_[0]->{id}}->{lmethod}->{$_[0]->{pkey}}->{name};
		if (defined $_[0]->{script}) {$script=$_[0]->{script}}
		if (defined $_[0]->{name})   {$name=$_[0]->{name}}
		
		my $sth=$dbh->prepare("UPDATE ${DBPREFIX}lmethod SET script=?, pname=? WHERE objid=? AND pkey=?");
  		$sth->execute($script,$name,$_[0]->{id},$_[0]->{pkey}) || die $dbh->errstr;
  		$obj->{$_[0]->{id}}->{lmethod}->{$_[0]->{pkey}}->{script}=$script;
  		$obj->{$_[0]->{id}}->{lmethod}->{$_[0]->{pkey}}->{name}=$name;
  		return 1;
  	
	}	else {
		my $script=$obj->{$_[0]->{id}}->{method}->{$_[0]->{pkey}}->{script};
		my $name=$obj->{$_[0]->{id}}->{method}->{$_[0]->{pkey}}->{name};
		if (defined $_[0]->{script}) {$script=$_[0]->{script}}
		if (defined $_[0]->{name})   {$name=$_[0]->{name}}
		
		
  		my $sth=$dbh->prepare("UPDATE ${DBPREFIX}method SET script=?, pname=? WHERE objid=? AND pkey=?");
  		$sth->execute($script,$name,$_[0]->{id},$_[0]->{pkey}) || die $dbh->errstr;
  		$obj->{$_[0]->{id}}->{method}->{$_[0]->{pkey}}->{script}=$script;
  		$obj->{$_[0]->{id}}->{method}->{$_[0]->{pkey}}->{name}=$name;
  		return 1;
  	}	
}

sub updateprmname {
	 my $pkey=$_[0];
	 my $newname=$_[1];
	 my $sth2=$dbh->prepare("UPDATE ${DBPREFIX}prm SET pname=?  WHERE pkey=?");
   $sth2->execute($newname,$pkey) || die $dbh->errstr;
   setvalue({key=>"_PP_$pkey",prm=>'_NAME',value=>$newname});
   $prm->{$pkey}->{name}=$newname;
}	



sub editprm  {
 	my $upd;
	my $evl;
	my $mode;
  	if ($_[0]->{upd})  {$upd='y'} else {$upd='n'}
  	if ($_[0]->{evl})  {$evl='y'} else {$evl='n'}
  	if ($_[0]->{mode}) {$mode=$_[0]->{mode}} else {$mode=0}
  	if ($mode==0 || $mode==2) {
  		my $sth=$dbh->prepare("UPDATE ${DBPREFIX}prm SET defval=?, upd=? WHERE objid=? AND pkey=?");
  		$sth->execute($_[0]->{defval},$upd,$_[0]->{id},$_[0]->{pkey}) || die $dbh->errstr;
  	} elsif ($mode==1) {
  		my $sth=$dbh->prepare("UPDATE ${DBPREFIX}prm SET upd=? WHERE objid=? AND pkey=?");
  		$sth->execute($upd,$_[0]->{id},$_[0]->{pkey}) || die $dbh->errstr;
  	}	
  	my $sth2=$dbh->prepare("UPDATE ${DBPREFIX}prm SET pname=?, evaluate=?  WHERE pkey=?");
  	$sth2->execute($_[0]->{newname},$evl,$_[0]->{pkey}) || die $dbh->errstr;
    updateprmname($_[0]->{pkey},$_[0]->{newname}) ;
  	$prm->{$_[0]->{pkey}}->{name}=$_[0]->{newname};
  	$prm->{$_[0]->{pkey}}->{evaluate}=$evl;
  	$prm->{$_[0]->{pkey}}->{defval}->{$_[0]->{id}}=$_[0]->{defval};
  	$prm->{$_[0]->{pkey}}->{upd}->{$_[0]->{id}}=$upd;

}




sub dbconnect
{
 $dbh=DBI->connect("DBI:mysql:$_[0]->{dbname}:$_[0]->{dbhost}",$_[0]->{dbuser},$_[0]->{dbpassword}) || die $DBI::errstr;
}



sub update {
	if ($_[0]->{id}=~/u\d+/) {edit($_[0])} else {editlow($_[0])}
	
}	


sub edit {
	my $id=$_[0]->{id};
	my $nolog=$_[0]->{nolog};
	if ($id=~/u(\d+)/) {$id=$1}
	
	
	
	my $sthU=$dbh->prepare("UPDATE ${DBPREFIX}tree SET keyname=?, template=? ,ltemplate=?, indx=?,lang=?,nolog=? WHERE id=?");
	
	if (ref $_[0]->{name} eq 'HASH') {
	  my $nh=$_[0]->{name};	
	  for (keys %$nh) {
	  	my $lang=$_;
	  	my $lname=$nh->{$lang};
	  	setvalue({uid=>$id,param=>'_NAME',value=>$lname,lang=>$lang});
	  	$obj->{$id}->{"name_$lang"}=$lname;
	  	$obj->{$id}->{name}=$lname;
	  }	
	  if ($nh->{$LANGS[0]}) {$obj->{$id}->{name}=$nh->{$LANGS[0]}}
	} elsif ($_[0]->{name}) 			{
		setvalue({uid=>$id,param=>'_NAME',value=>$_[0]->{name}});
		$obj->{$id}->{name}=$_[0]->{name};
		if ($LANGUAGE) {$obj->{$id}->{"name_$LANGUAGE"}=$_[0]->{name}}
	}
	if (defined $_[0]->{key})       {$obj->{$id}->{key}=$_[0]->{key}}
	if (defined $_[0]->{indx})      {$obj->{$id}->{indx}=$_[0]->{indx}}
	if (defined $_[0]->{lang})      {$obj->{$id}->{lang}=$_[0]->{lang}}
	if ($_[0]->{template} ne '')  {$obj->{$id}->{template}=$_[0]->{template}}
	if ($_[0]->{ltemplate} ne '') {$obj->{$id}->{ltemplate}=$_[0]->{ltemplate}}
	$obj->{$id}->{nolog}=$nolog;
	
	
	
 	$sthU->execute(
 	   $obj->{$id}->{key},
 	   $obj->{$id}->{template},
 	   $obj->{$id}->{ltemplate},
 	   $obj->{$id}->{indx},
 	   $obj->{$id}->{lang},
 	   $obj->{$id}->{nolog},
 	   $id) || die $dbh->errstr;
 	   
 	   
  $nobj->{$obj->{$id}->{key}}=$obj->{$id};
 
 	if ($_[0]->{lowtemplate}) {
 		  for (@{$tree->{$id}}) {
 		  	edit({id=>$_,template=>$_[0]->{ltemplate},lang=>$_[0]->{lang}});
 		  }	
 		  checkload({uid=>$id});
 		  for (@{$ltree->{$id}->{0}}) {
 		  	editlow({objid=>$_,template=>$_[0]->{ltemplate}});
 		  }	
 		  
	}	
 
}



sub editlow {
	
  

	my $objid;
	if    (defined $_[0]->{objid}) {$objid=$_[0]->{objid}}
	elsif (defined $_[0]->{id})    {$objid=$_[0]->{id}}
	else  {return 0}

  checkload({id=>$objid});

 
	
	
	if (ref $_[0]->{name} eq 'HASH') {
  my $nh=$_[0]->{name};	
	  for (keys %$nh) {
	  	my $lang=$_;
	  	my $lname=$nh->{$lang};
	  	setvalue({id=>$objid,param=>'_NAME',value=>$lname,lang=>$lang});
	  	$lobj->{$objid}->{"name_$lang"}=$lname;
	  	$lobj->{$objid}->{name}=$lname;
	  }	
	  if ($nh->{$LANGS[0]}) {$lobj->{$objid}->{name}=$nh->{$LANGS[0]}}
	} elsif ($_[0]->{name}) 			{
		setvalue({id=>$objid,param=>'_NAME',value=>$_[0]->{name}});
		$lobj->{$objid}->{name}=$_[0]->{name};
		if ($LANGUAGE) {$lobj->{$objid}->{"name_$LANGUAGE"}=$_[0]->{name}}
	}

	
	

	
	
	if (defined $_[0]->{key})       {$lobj->{$objid}->{key}=$_[0]->{key}}
	if (defined $_[0]->{indx})      {$lobj->{$objid}->{indx}=$_[0]->{indx}}
	if ($_[0]->{upobj})     {
		my $newupobj=$_[0]->{upobj};
		if ($newupobj=~/^u(\d+)$/)  {$newupobj=$1}
		my $oldupobj=$lobj->{$objid}->{upobj};
		my $up=$lobj->{$objid}->{up};
		
		$lobj->{$objid}->{upobj}=$newupobj;
		push (@{$ltree->{$newupobj}->{up}},$item->{id});
		@{$ltree->{$oldupobj}->{$up}}=grep{$_ ne $objid}@{$ltree->{$oldupobj}->{$up}};

		$sthUVU->execute($newupobj,$objid) || die $dbh->errstr;
	}
	
	if (defined $_[0]->{template} && $_[0]->{template} ne '')  {$lobj->{$objid}->{template}=$_[0]->{template}}
	
	
	
	
 	my $sthU=$dbh->prepare("UPDATE ${DBPREFIX}objects SET keyname=?,template=?,indx=?,upobj=? WHERE id=?");
 	$sthU->execute(
 	  $lobj->{$objid}->{key},
 	  $lobj->{$objid}->{template},
 	  $lobj->{$objid}->{indx},
 	  $lobj->{$objid}->{upobj},
 	  $objid) || die $dbh->errstr;
 	
}


sub checkupd {
	my $id=$_[0]->{id};
	my $pkey=$_[0]->{pkey};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
  	my $tpkey=$_[0]->{tpkey};	

	
	my @testlist;
	if (($id && $id=~s/^t_(.+)$/$1/) || $tabkey)  {
  		if ($tabkey) {$id=$tabkey}
  		push (@testlist,$prm->{$tpkey}->{extra}->{cell})
 	} elsif (($id && $id=~s/^u(\d+)$/$1/) || $uid) {
 		if ($uid) {$id=$uid}
		if ($obj->{$id}->{template}) {push(@testlist,"u$obj->{$id}->{template}") }
		push (@testlist,$id);
  }else  {
  	if ($lobj->{$id}->{template}) {push(@testlist,"u$lobj->{$id}->{template}") }
  	for (treelist($lobj->{$id}->{upobj})) { 
  			push (@testlist,$_);
  			if ($obj->{$_}->{template}) {push(@testlist,"u$obj->{$_}->{template}")}
  	}		
  }
	for (@testlist)	{if ($prm->{$pkey}->{upd}->{$_} eq 'y') {return 1}}
	return 0;
		
}	


sub defaultvalue
{
	my $id=$_[0]->{id};
	my $pkey=$_[0]->{pkey};
	my $uid=$_[0]->{uid};
	my $tid=$_[0]->{tid};
	my $tpkey=$_[0]->{tpkey};
	
	my @testlist;
	my $v;
	$v->{value}='';
	$v->{type}=$prm->{$pkey}->{type};
	
	if ($id) {
		if ($lobj->{$id}->{template}) {push(@testlist,$lobj->{$id}->{template}) }
		
  	for (treelist($lobj->{$id}->{upobj})) { 
  		push (@testlist,$_);
  		if ($obj->{$_}->{template}) {push(@testlist,"u$obj->{$_}->{template}")}
  	}		
        
                  
	}	
	elsif ($uid) { 
		if ($obj->{$uid}->{template}) {push(@testlist,$obj->{$uid}->{template}) }
		push (@testlist,$uid);
		push (@testlist,$_) for treelist($uid);
	}	
	elsif ($tpkey) {
		push (@testlist,$prm->{$tpkey}->{extra}->{cell});
	}
	for (@testlist) {
		if ($prm->{$pkey}->{defval}->{$_}) {
			$v->{value}=$prm->{$pkey}->{defval}->{$_};
			if ($prm->{$pkey}->{evaluate} eq 'y') {
				$v=calculate({id=>$id,uid=>$uid,expr=>$v->{value}});
			}
			return $v;
		}	
        }
        return $v;
}	

sub retbackref {
	my $objid=$_[0]->{id};
	my $pkey=$_[0]->{pkey};
	my $upper=$_[0]->{upper};
	my $condition=$_[0]->{condition};
	my $id;

	if ($objid->{type}) {
		if    ($objid->{type} eq 'U') {$ind='u'.$objid->{ind}}
		elsif ($objid->{type} eq 'L') {$ind=$objid->{ind}} 
		elsif ($objid->{type} eq 'T') {$ind='test'}
	} else  {$ind=$objid}
	
	my $t=time();
	$sthVL->execute($ind,$pkey) || die $dbh->errstr;
	my @rlist=();
	
	
	
	
	while (my $item=$sthVL->fetchrow_hashref) {
		if (($upper eq "u$item->{upobj}") || !$upper) {
		#if ($item && isupper({up=>$upper,low=>$item->{objid}})) {
			push(@rlist,$item->{objid})
		}	
	}	
	my $v;
	
	if ($condition) {
		 @rlist=grep(&cmlcalc::calc($_,$condition),@rlist);
  }	
	
	$v->{value}=join(';',@rlist);
	$v->{type}='LIST';
	return $v;
}


sub retrnd {
	my ($uid)=@_;
	$sthRND->execute($uid) || die $dbh->errstr;
	my $item=$sthRND->fetchrow_hashref();
	my $v;
	$v->{value}=$item->{id};
	$v->{type}='LIST';
	return $v;
	
}


sub returnd {
	my ($uid)=@_;
	$sthURND->execute($uid) || die $dbh->errstr;
	my $uitem=$sthURND->fetchrow_hashref();
	my $v;
	$v->{value}="u$uitem->{id}";
	$v->{type}='LIST';
	return $v;
	
}



sub retubackref {
	my $objid=$_[0]->{id};
	my $pkey=$_[0]->{pkey};
	my $upper=$_[0]->{upper};
	my $condition=$_[0]->{condition};
	my $id;
	
	
	
	if ($objid->{type}) {
		if    ($objid->{type} eq 'U') {$ind='u'.$objid->{ind}}
		elsif ($objid->{type} eq 'L') {$ind=$objid->{ind}} 
		elsif ($objid->{type} eq 'T') {$ind='test'}
	} else  {$ind=$objid}
	
	my $t=time();
	$sthUVL->execute($ind,$pkey) || die $dbh->errstr;
	my @rlist=();
	
	
	
	
	while (my $item=$sthUVL->fetchrow_hashref) {
		if ($item && isupper({up=>$upper,low=>$item->{objid}})) {
			push(@rlist,$item->{objid})
		}	
	}	
	my $v;
	
	if ($condition) {
		 @rlist=grep(&cmlcalc::calc($_,$condition),@rlist);
  }	
	
	$v->{value}=join(';',@rlist);
	$v->{type}='LIST';
	return $v;
}


sub isupper {
	my $up=$_[0]->{up};
	my $low=$_[0]->{low};
	my ($uid)=($up=~/u(\d+)/);
	if ($uid) {
		my $upper=checkload({id=>$low,onlyup=>1});
		if ($uid eq $upper) { return 1 }
	}
	
	if ($up=~/u(\d+)/ && $low=~/u(\d+)/) {
		if (grep('$up',treelist($low))) {return 1}
	}	
	return 0;
}

sub iscompiled  {
	my $id=$_[0]->{id};
	my $uid=$_[0]->{uid};
	my $pkey=$_[0]->{pkey};
	my $lang=$_[0]->{lang};
	
	return $lobj->{$id}->{langvals}->{$lang}->{"${pkey}__COMPILEDFLAG"}->{value} if $id;
	return $obj->{$uid}->{langvals}->{$lang}->{"${pkey}__COMPILEDFLAG"}->{value} if $uid;
}	

sub prefetch {
	my ($upobjid)=@_;
	$LsthAV->execute($upobjid,$lang) || die $dbh->errstr;
	while (my $item=$LsthAV->fetchrow_hashref) {
     	if ($prm->{$item->{pkey}}->{type} eq 'TEXT' || $prm->{$item->{pkey}}->{type} eq 'LONGTEXT') { 
        		$lobj->{$item->{objid}}->{langvals}->{$lang}->{$item->{pkey}}->{value}=$item->{value};
        } else {
        	  $lobj->{$item->{objid}}->{$item->{pkey}}->{value}=$item->{value};
        }			
        $lobj->{$item->{objid}}->{vals}->{$item->{pkey}}->{type}=$prm->{$item->{pkey}}->{type};
        $lobj->{$item->{objid}}->{langcached}->{$lang}=1;
	}     
}

sub prefetchlist {
	my $objlist=$_[0];
    my $t=time();
	return unless $objlist;
	
	my $vstr=join(',',split ';', $objlist);
	my $sth=$dbh->prepare("SELECT * FROM ${DBPREFIX}vls WHERE objid in ($vstr) AND lang=?")|| die $dbh->errstr;

	
	$sth->execute($lang) || die $dbh->errstr;
	while (my $item=$sth->fetchrow_hashref) {
     	if ($prm->{$item->{pkey}}->{type} eq 'TEXT' || $prm->{$item->{pkey}}->{type} eq 'LONGTEXT') { 
        		$lobj->{$item->{objid}}->{langvals}->{$lang}->{$item->{pkey}}->{value}=$item->{value};
        } else {
        	  $lobj->{$item->{objid}}->{$item->{pkey}}->{value}=$item->{value};
        }			
        $lobj->{$item->{objid}}->{vals}->{$item->{pkey}}->{type}=$prm->{$item->{pkey}}->{type};
        $lobj->{$item->{objid}}->{langcached}->{$lang}=1;
	}	
	my $xt=time()-$t;

}

sub returnvalue {
 	my $objid=$_[0]->{id};
 	my $pkey=$_[0]->{pkey};
 	my $noparse=$_[0]->{noparse};
 	my $lang;
 	my $npv;
	if ($objid->{lang}) {
 		if ($objid->{lang} ne 'mul') {$lang=$objid->{lang}}
 		elsif ($cmlcalc::LANGUAGE) {$lang=$cmlcalc::LANGUAGE}
 		elsif ($_[0]->{lang}) 		 {$lang=$_[0]->{lang}}
 	}
 	
 	
 	my %cf;
 	my %cv;
 	
 	if ($objid->{type} eq 'L')  {
   	$objid=$objid->{ind};
   		if (!$lobj->{$objid}->{langcached}->{$lang} || $noparse) {
		  	$LsthV->execute($objid,$lang) || die $dbh->errstr;
     		while (my $item=$LsthV->fetchrow_hashref) {
     			my $type=$prm->{$item->{pkey}}->{type} || '';
     			if ($type eq 'TEXT' || $type eq 'LONGTEXT') { 
        			$lobj->{$objid}->{langvals}->{$lang}->{$item->{pkey}}->{value}=$item->{value};
        		} else {
        		  $lobj->{$objid}->{$item->{pkey}}->{value}=$item->{value};
          		}			
        		$lobj->{$objid}->{vals}->{$item->{pkey}}->{type}=$prm->{$item->{pkey}}->{type};
        		if ($noparse && $pkey eq $item->{pkey}) {$npv->{value}=$item->{value}; $npv->{type}=$item->{type}}
        		if ($item->{value} eq '1' && $item->{pkey}=~/^(.+)__COMPILEDFLAG$/) {$cf{$1}=1}
        		if ($item->{pkey}=~/^(.+)__COMPILED$/) {$cv{$1}=$item->{value}}
     		}
     		for (keys %cf) {
     			$lobj->{$objid}->{langvals}->{$lang}->{$_}->{value}=$cv{$_};
     			$lobj->{$objid}->{langvals}->{$lang}->{$_}->{compiled}=1;
     		}
     		$lobj->{$objid}->{langcached}->{$lang}=1;
   		}
   		
   		if ($prm->{$pkey}->{type} eq 'TEXT' || $prm->{$pkey}->{type} eq 'LONGTEXT') {
   			if (
   			  !$lobj->{$objid}->{langvals}->{$lang}->{$pkey}->{value} ||  
   			  $lobj->{$objid}->{langvals}->{$lang}->{$pkey}->{value} eq ''
   			)  {
      				$lobj->{$objid}->{langvals}->{$lang}->{$pkey}=defaultvalue({pkey=>$pkey,id=>$objid});
   			}
   		} else {
   			#unless ($lobj->{$objid}->{$pkey}->{value} ne '')  {
   			if ((not defined $lobj->{$objid}->{$pkey}->{value}) || $lobj->{$objid}->{$pkey}->{value} eq '')  {
      				$lobj->{$objid}->{$pkey}=defaultvalue({pkey=>$pkey,id=>$objid});
   			}
   		}		
   		
   		
   		if ($noparse) {return $npv } else {	
   			if ($prm->{$pkey}->{type} eq 'TEXT' || $prm->{$pkey}->{type} eq 'LONGTEXT') { 
   				return $lobj->{$objid}->{langvals}->{$lang}->{$pkey} 
   			} else {
   				return $lobj->{$objid}->{$pkey} 
   		  }  		
   		}
 	}	
 
 
 elsif ($objid->{type} eq 'U') 
 {
 
   $tmp=$objid->{template};	
   $objid=$objid->{ind};
   
   if (!$obj->{$objid}->{cached} || $_[0]->{noparse})  {
      $sthUV->execute($objid) || die $dbh->errstr;
      while ($item=$sthUV->fetchrow_hashref) {
      	unless (($prm->{$item->{pkey}}->{upd}->{$objid} eq 'n') ||
      		($prm->{$item->{pkey}}->{upd}->{$tmp} eq 'n') ) {  
      			
         	$obj->{$objid}->{vals}->{$item->{pkey}}->{value}=$item->{value};
         	$obj->{$objid}->{vals}->{$item->{pkey}}->{type}=$prm->{$item->{pkey}}->{type};
        }	
      }
      $obj->{$objid}->{cached}=1;
   }
   unless ($obj->{$objid}->{vals}->{$pkey}->{value} ne '')  {
      $obj->{$objid}->{vals}->{$pkey}=defaultvalue({pkey=>$pkey,uid=>$objid});
   }
   return $obj->{$objid}->{vals}->{$pkey};
 }
 
 elsif ($objid->{type} eq 'T') {
 	my $tabkey=$objid->{ind};
 	my $tid=$objid->{tid};
 	my $tpkey=$objid->{tpkey};
 	unless ($tobj->{$tid}->{$tpkey}->{cached})  {
 		$sthTV->execute($tid,$tpkey)	|| die $dbh->errstr;
 		while ($item=$sthTV->fetchrow_hashref) {
 			checkload({id=>$tid,pkey=>$tpkey,tabkey=>$item->{vkey}});
 			$tobj->{$tid}->{$tpkey}->{vals}->{$item->{vkey}}->{vals}->{$item->{pkey}}->{value}=$item->{value};
 			$tobj->{$tid}->{$tpkey}->{vals}->{$item->{vkey}}->{vals}->{$item->{pkey}}->{type}=$prm->{$item->{pkey}}->{type};
 		}
 		$tobj->{$tid}->{$tpkey}->{cached}=1;
 	}	
 	unless ($objid->{vals}->{$pkey}->{value} ne '') {
 		$objid->{vals}->{$pkey}=defaultvalue({pkey=>$pkey,tpkey=>$tpkey})
 	}
        return $objid->{vals}->{$pkey}; 
  }
 	
 

}


sub setvalue  {
	my $pkey;
	

	
	if   (defined $_[0]->{pkey})  {$pkey=$_[0]->{pkey}}
	elsif(defined $_[0]->{param}) {$pkey=$_[0]->{param}}
	elsif(defined $_[0]->{prm})   {$pkey=$_[0]->{prm}}	
	else {return 0}
	
	my $value=$_[0]->{value};
	my $id=$_[0]->{id};
	my $uid=$_[0]->{uid};
	my $key=$_[0]->{key};
	my $lang=$_[0]->{lang};
	my $append=$_[0]->{append};
	my $ind;
	if ($key) {
		 checkload({key=>$key});
		 $id=$nobj->{$key}->{id};
		 $ind=$nobj->{$key}->{ind};
		 return 0 unless $id;
  	}	
    $value=enc($value) if $_[0]->{convert};
	if (defined $prm->{$pkey}->{type} && $prm->{$pkey}->{type} eq 'FILE' && $append) {
		my $objid;
		if ($uid) {$objid="u$uid"}	else {$objid=$id} 
		my $fname="${objid}_${pkey}";
		open FILE,">>$GLOBAL->{FILEPATH}/$fname" ||die $!;
		print FILE $value;
		close  FILE || die $!;
		setvalue({id=>$id,uid=>$uid,pkey=>$pkey,value=>$fname});
		return 1;
 	}
 	
 	if ($_[0]->{tabkey})  {	
 		my $objid;
                if ($id) {$objid=$id} else {$objid="u$uid"}
                my $tabpkey=$_[0]->{tabpkey};
                my $tabkey=$_[0]->{tabkey};
                $sthTI->execute($objid,$tabpkey,$tabkey,$pkey,$value) || die $dbh->errstr;
                checkload({id=>$objid,pkey=>$tabpkey,tabkey=>$tabkey});
                $tobj->{$objid}->{$tabpkey}->{vals}->{$tabkey}->{vals}->{$pkey}->{value}=$value;
                $tobj->{$objid}->{$tabpkey}->{vals}->{$tabkey}->{vals}->{$pkey}->{type}=$prm->{$pkey}->{type};
                $ind=join('_',($objid,$tabpkey,$tabkey));
	}	elsif ($id=~/^\d+$/)   {	
  		my $objid=$id;
		if ($pkey eq '_INDEX') {   
			update({id=>$objid , indx=>$value});
			$sthCH->execute($objid) || die $dbh->errstr; 
			return 1;
		}	
		if ($pkey eq '_KEY') {   
			update({id=>$objid , key=>$value}) ; 
			$sthCH->execute($objid) || die $dbh->errstr;
			return 1; 
		}	
		if ($pkey eq '_UP') {   
			if ($value=~/^u/) {
				update({id=>$objid , upobj=>$value}); 
				$sthCH->execute($objid) || die $dbh->errstr;
			}	
			return 1;
		}	
		checkload({id=>$objid});
		if ($pkey eq '_PRMNAME') {
			my $xk=$lobj->{$objid}->{key}; 
			$xk=~s/^_PP_//;
			updateprmname($xk,$value);
			$sthCH->execute($objid) || die $dbh->errstr;
			return 1; 
   	 	}	
  		my $cl;	
  		if    ($_[0]->{lang})      {$cl=$_[0]->{lang}} 
  		elsif ($LANGUAGE) {
  			$cl=$LANGUAGE;
  			$lobj->{$objid}->{vals}->{$pkey}->{value}=$value;
  		} else  {
  			$cl=$LANGS[0]
  		}
 			
 		$sthDD->execute($objid,$pkey,$cl) || die $dbh->errstr;
 		if (defined $value && ($value ne '')) {
 			$sthI->execute($objid,$pkey,$value,$lobj->{$objid}->{upobj},$cl) || die $dbh->errstr;
 		}	
 		unless ($obj->{$lobj->{$objid}->{upobj}}->{nolog}) {
 			$sthH->execute($objid,$pkey,$value,$prm->{$pkey}->{type},$cl) || die $dbh->errstr;
 		}	
 		

 		
 		$sthCH->execute("$objid") || die $dbh->errstr;

 		
  		#$lobj->{$objid}->{vals}->{$pkey}->{"value_$cl"}=$value;
		$lobj->{$objid}->{langvals}->{$cl}->{$pkey}->{value}=$value;
  		$lobj->{$objid}->{$pkey}->{value}=$value;
		#$lobj->{$objid}->{langcached}->{$cl}=1;
  			 
		if ($cl eq $LANGS[0] || $cl eq $lobj->{$objid}->{lang}) {
 			#$sthI->execute($objid,$pkey,$value,$lobj->{$objid}->{upobj},'') || die $dbh->errstr;
			$lobj->{$objid}->{vals}->{$pkey}->{value}=$value;
 		}
  	  		
  		if ($pkey eq '_NAME') {
  			$lobj->{$objid}->{name}=$value;
  			$lobj->{$objid}->{"name_$cl"}=$value;
  		}
  		$lobj->{$objid}->{vals}->{$pkey}->{type}=$prm->{$pkey}->{type};
  		
  		$ind=$objid;
  		
 	}	elsif   ($uid || $id=~/^u(\d+)$/)	{	
 		
  		my $objid;
  		if ($uid) {$objid=$uid}	else {$objid=$1}
  		if ($pkey eq '_INDEX') {   update({id=>"u$objid" , indx=>$value}) ; return }	
		if ($pkey eq '_KEY')   {   update({id=>"u$objid" , key=>$value}) ; return }	  		
		my $cl;
	 	
	 	if    ($_[0]->{lang})      {$cl=$_[0]->{lang}} 
  		elsif ($LANGUAGE) {
  			$cl=$LANGUAGE;
  			$obj->{$objid}->{vals}->{$pkey}->{value}=$value;
  		}	else  {$cl=$LANGS[0]}
  		$sthUDD->execute($objid,$pkey,$cl) || die $dbh->errstr;	
  		$sthUI->execute($objid,$pkey,$value,$cl) || die $dbh->errstr;
  		$sthH->execute("u$objid",$pkey,$value,$prm->{$pkey}->{type},$cl) || die $dbh->errstr;	
  		$sthCH->execute("u$objid") || die $dbh->errstr;

		$obj->{$objid}->{vals}->{$pkey}->{"value_$cl"}=$value;
		if ($cl eq $LANGS[0] || $cl eq $lobj->{$objid}->{lang}) {
			#$sthUI->execute($objid,$pkey,$value,'') || die $dbh->errstr;
  	  		#$sthH->execute("u$objid",$pkey,$value,$prm->{$pkey}->{type},undef) || die $dbh->errstr;
  			$obj->{$objid}->{vals}->{$pkey}->{value}=$value;
		}	
  			
  			
  		if ($pkey eq '_NAME') {
  			$obj->{$objid}->{name}=$value;
  			$obj->{$objid}->{"name_$cl"}=$value;
  		}
		$obj->{$objid}->{vals}->{$pkey}->{type}=$prm->{$pkey}->{type};
		$ind="u$objid";

 	} 
 	
 	
 	if ($prm->{$pkey}->{type} eq 'LIST') {
 		$sthDL->execute($ind,$pkey) || die $dbh->errstr;
 		for (split(/\s*;\s*/,$value)) {
 			$sthIL->execute($ind,$pkey,$_) || die $dbh->errstr;
 			$sthCH->execute($_) || die $dbh->errstr;
 		}
	}

	if ($prm->{$pkey}->{extra}->{srch} || $pkey eq '_NAME') {
 		my $cl;
 		if    ($_[0]->{lang})      {$cl=$_[0]->{lang}} 
 		elsif ($LANGUAGE) {		$cl=$LANGUAGE	 	}	
 		else  {$cl=$LANGS[0]}
	  	
	  	if ($prm->{$pkey}->{type} eq 'NUMBER' || $prm->{$pkey}->{type} eq 'DATE') {
	  		if ($value ne '') {
	  			$sthIFS_I->execute($ind,$pkey,$cl,$value) || die $dbh->errstr;
	  		} else {
	  			$sthDFS_I->execute($ind,$pkey) || die $dbh->errstr;
	  		}
	  	} else {
			if ($value ne '') {
				$sthIFS->execute($ind,$pkey,$cl,$value) || die $dbh->errstr;
			} else {
				$sthDFS->execute($ind,$pkey) || die $dbh->errstr;	
			}	
		}
	} 
  	if ($prm->{$pkey}->{extra}->{onchange}) {
  		if ($id) {$OBJECT=$obj->{$id}}
  	 	if ($uid) {$OBJECT=$lobj->{$uid}}
     		eval "$prm->{$pkey}->{extra}->{onchange}";   	
	}	
	return 1;
}

sub checkdatastruct {
	my $sth =$dbh->prepare("SELECT count(*) FROM ${DBPREFIX}tree") || die $dbh->errstr;
	$sth->execute() || die $dbh->errstr();
	my ($r)=$sth->fetchrow;
	
}

sub init	{
 	do "$_[0]/conf" || die $!;
  	$GLOBAL->{CODEPAGE}=$UTF?'utf-8':'windows-1251';
 	$DBHOST='localhost' unless $DBHOST;
 	$DBPREFIX=$DBPREFIX?"${DBPREFIX}_":'';
  
 	dbconnect({dbname=>$DBNAME,dbuser=>$DBUSER,dbpassword=>$DBPASSWORD,dbhost=>$DBHOST});
 	
	 
 	$sthDD=$dbh->prepare("DELETE FROM ${DBPREFIX}vls WHERE objid=? AND pkey=? AND lang=?");
 	$sthUDD=$dbh->prepare("DELETE FROM ${DBPREFIX}uvls WHERE objid=? AND pkey=? AND lang=?");
 	$sthI =$dbh->prepare("REPLACE ${DBPREFIX}vls (objid,pkey,value,upobj,lang) VALUES (?,?,?,?,?)") || die $dbh->errstr;
 	

 	
 	$sthH =$dbh->prepare("INSERT INTO ${DBPREFIX}vlshist (objid,pkey,value,ptype,dt,lang) VALUES (?,?,?,?,NOW(),?) ") || die $dbh->errstr;
 
 
 	$sthUV=$dbh->prepare("SELECT * FROM ${DBPREFIX}uvls WHERE objid=?") || die $dbh->errstr;
 	$sthUI=$dbh->prepare("REPLACE ${DBPREFIX}uvls (objid,pkey,value,lang) VALUES (?,?,?,?)") || die $dbh->errstr;
 	$sthUVU=$dbh->prepare("UPDATE ${DBPREFIX}vls SET upobj=? WHERE objid=?") || die $dbh->errstr;
 
 	$sthLTT=$dbh->prepare("SELECT * FROM ${DBPREFIX}objects WHERE upobj=? ORDER BY id") || die $dbh->errstr;
 	
 	$sthRND=$dbh->prepare("SELECT * FROM ${DBPREFIX}objects WHERE upobj=? ORDER BY RAND() LIMIT 1") || die $dbh->errstr;
 	$sthURND=$dbh->prepare("SELECT * FROM ${DBPREFIX}tree WHERE up=? ORDER BY RAND() LIMIT 1") || die $dbh->errstr;
 	
 	$sthLTTL=$dbh->prepare("SELECT * FROM ${DBPREFIX}objects WHERE upobj=? ORDER BY indx LIMIT ?") || die $dbh->errstr;
 	$sthLTT1=$dbh->prepare("SELECT * FROM ${DBPREFIX}objects WHERE upobj=? AND id=?") || die $dbh->errstr;
 
 
 	$LsthV=$dbh->prepare("SELECT * FROM ${DBPREFIX}vls WHERE objid=? AND lang=?")|| die $dbh->errstr;
 	
 
 	$LsthAV=$dbh->prepare("SELECT * FROM ${DBPREFIX}vls WHERE upobj=? AND lang=?")|| die $dbh->errstr;

 
 	$LANGS{mul}='Мультиязычный';
	for my $lang (keys %LANGS) {
		$LANGS{$lang}=enc($LANGS{$lang});
	}	  

 
 	$sthTV=$dbh->prepare("SELECT * FROM ${DBPREFIX}tvls WHERE id=? AND ptkey=?") || die $dbh->errstr;
 	$sthTI=$dbh->prepare("REPLACE ${DBPREFIX}tvls (id,ptkey,vkey,pkey,value) VALUES (?,?,?,?,?)") || die $dbh->errstr;
 
 	$sthDL=$dbh->prepare("DELETE FROM ${DBPREFIX}links WHERE objid=? AND pkey=?") || die $dbh->errstr;
 	$sthIL=$dbh->prepare("REPLACE INTO ${DBPREFIX}links (objid,pkey,vallink) VALUES (?,?,?)") || die $dbh->errstr;
 
 	$sthUVL=$dbh->prepare("SELECT * FROM ${DBPREFIX}links WHERE vallink=? AND pkey=?") || die $dbh->errstr;
 	$sthVL=$dbh->prepare("select ${DBPREFIX}links.objid,${DBPREFIX}objects.upobj from ${DBPREFIX}links,${DBPREFIX}objects where vallink=? and pkey=? and ${DBPREFIX}objects.id=${DBPREFIX}links.objid") || die $dbh->errstr; 
 
 	$sthIFS=$dbh->prepare("REPLACE ${DBPREFIX}fs (id,prm,lang,val) VALUES (?,?,?,?)") || die $dbh->errstr;
 	$sthDFS=$dbh->prepare("DELETE FROM ${DBPREFIX}fs  WHERE id=? AND prm=?") || die $dbh->errstr;
 	$sthFS=$dbh->prepare("SELECT id FROM ${DBPREFIX}fs WHERE prm=? AND val=?") || die $dbh->errstr;
 
 	$sthIFS_I=$dbh->prepare("REPLACE ${DBPREFIX}fsint (id,prm,lang,val) VALUES (?,?,?,?)") || die $dbh->errstr;
 	$sthDFS_I=$dbh->prepare("DELETE FROM ${DBPREFIX}fs WHERE id=? AND prm=?") || die $dbh->errstr;
 
 
 	$sthFSL=$dbh->prepare("SELECT id FROM ${DBPREFIX}fs WHERE prm=? AND val LIKE ?") || die $dbh->errstr;
 
 	$sthSC=$dbh->prepare("SELECT pagetext FROM ${DBPREFIX}pagescache WHERE cachekey=? AND dev=? AND lang=?");
 	$sthIC=$dbh->prepare("REPLACE ${DBPREFIX}pagescache (cachekey,pagetext,ts,dev,lang) VALUES (?,?,NOW(),?,?)");
 	$sthLC=$dbh->prepare("INSERT INTO ${DBPREFIX}linkscache (cachekey,objlink,dev,lang) VALUES (?,?,?,?)");
 	$sthDC=$dbh->prepare("DELETE FROM ${DBPREFIX}linkscache WHERE cachekey=? AND dev=? AND lang=?");
 	
 	
 	$sthCH=$dbh->prepare("DELETE FROM pagescache WHERE cachekey IN (SELECT cachekey FROM linkscache WHERE objlink=?)");

 	
 	$sthCCP=$dbh->prepare("DELETE FROM pagescache");
 	$sthCCL=$dbh->prepare("DELETE FROM linkscache");
 	
 	$GLOBAL->{FILEPATH}=$FILEPATH;
 	$GLOBAL->{DOCUMENTROOT}=$DOCUMENTROOT;
 	$GLOBAL->{FILEURL}=$FILEURL;
 	$GLOBAL->{ABSFILEURL}=$ABSFILEURL;
 	$GLOBAL->{DBNAME}=$DBNAME;
 	$GLOBAL->{DBHOST}=$DBHOST;
 	$GLOBAL->{DBPASSWORD}=$DBPASSWORD;
 	$GLOBAL->{DBUSER}=$DBUSER;

  	$GLOBAL->{SYNC}=\%SYNC;
  	$GLOBAL->{DOUBLECONFIRM}=$DOUBLECONFIRM;
  	$GLOBAL->{CACHE}=$CACHE;

 	
 	undef @LOG;
}

sub enc 
{
	my ($val)=@_;
	if ($GLOBAL->{CODEPAGE} eq 'utf-8') {
		$val=Encode::encode('utf-8',Encode::decode('windows-1251',$val));
	}
	return $val;
}


sub clearcache 
{
	$sthCCP->execute || die $dbh->errstr();
	$sthCCL->execute || die $dbh->errstr();
}



sub sync ($$$$$) {
	my ($server,$path, $type,$key,$id)=@_;
	my $surl=$GLOBAL->{SYNC}->{$server}->{url};
	require LWP::UserAgent;
	require HTTP::Request::Common; 
	my $ua = LWP::UserAgent->new;
	$ua->agent("vCMS Sync agent");
	my $query = qq(	<SYNC></SYNC>	);
	my $value;
	if ($type eq 'method') {
		$value=$obj->{$id}->{method}->{$key}->{script}
	} elsif ($type eq 'lmethod'){ 
		$value=$obj->{$id}->{lmethod}->{$key}->{script}
	}
 	my $req = &HTTP::Request::Common::POST ($surl,[ action => 'remotesync', path => $path, type => $type, key => $key, value=>$value ]);
 	$req->authorization_basic($GLOBAL->{SYNC}->{$server}->{login}, $GLOBAL->{SYNC}->{$server}->{password});
	my $response = $ua -> request ($req);
	my $result=$response->content();
	alert ($result);
	return $result;
}

sub remote_sync ($$$$) {
	my ($path,$type,$key,$value)=@_;
	print "ID:$path TYPE:$type KEY:$key VALUE:$value";
}

sub alert {
	 my $mes;
	 $mes->{type}='alert';
	 $mes->{message}=$_[0];
	 push (@LOG,$mes);
	 print "ALERT:: $_[0] \n" if $cmlcalc::CGIPARAM->{_MODE} eq 'AUTORUN';
}	

sub message {
	 my $mes;
	 $mes->{type}='message';
	 $mes->{message}=$_[0];
	 push (@LOG,$mes);
	 print "MESSAGE:: $_[0] \n" if $cmlcalc::CGIPARAM->{_MODE} eq 'AUTORUN';
	 	
}	



sub viewlog {
	my @mlist;
	
	if ($cmlcalc::CGIPARAM->{_MODE} eq 'AUTORUN') {
		my $logstr;
		if ($ENV{HTTP_USER_AGENT}) {
			print "Content-Type: text/plain; charset=windows-1251\n\n";	
		}
		print "AUTOSCRIPT LOG\n";
		for my $mes (@LOG) {
			if ($mes->{type} eq 'alert') {
				$logstr.="ALERT:: $mes->{message} \n";
			} elsif ($mes->{type} eq 'message') {
				$logstr.="MESSAGE:: $mes->{message} \n";
			}		
		}
		my $lid=addlowobject({up=>&cmlcalc::id(AUTOLOGS),name=>scalar localtime()});	
		setvalue({id=>$lid,prm=>'EXECDATE',value=>cmlcalc::now()});
		setvalue({id=>$lid,prm=>'LOGBODY',value=>$logstr});
		if ($ENV{HTTP_USER_AGENT}) {
			print $logstr;	
		}	
		return;
	}
	
	
	if (@LOG) {	
		for (@LOG) {
			my $mes=$_;
			if ($mes->{type} eq 'alert') {
				chomp $mes->{message};
				$mes->{message}=~s/'/\\'/g; 
				$mes->{message}=~s/\r/ /gs; 
				$mes->{message}=~s/\n/ /gs;
				print "<script>alert('$mes->{message}')</script>";
			} elsif ($mes->{type} eq 'message') {
				chomp $mes->{message};
				$mes->{message}=~s/\\/\\\\/gs;
				$mes->{message}=~s/'/\\'/g;
				$mes->{message}=~s/\r/ /gs; 
				$mes->{message}=~s/\n/ /gs;
				$mes->{message}=~s/"/\\"/gs;
				push (@mlist,$mes->{message});
			}
		}
		
		if (@mlist) {
			print " <script>
             	function openlog()
             	{
              		var sWnd;
              		var pWnd = window.open('',sWnd,'scrollbars=yes,toolbar=no,location=no,status=no,menubar=no,fullscreen=no, resizable=yes,centered=yes,width=800,height=150');
              		pWnd.document.open();
              		pWnd.document.write(\"<html><head><title>Окно сообщений</title>\");
              		pWnd.document.write(\"<style type='text/css'> td {font-family : Verdana, Tahoma;   font-size   : 10px;} </style>\");
              		pWnd.document.write(\"</head><body>\");
           	";
           	for (@mlist) {
           		print "pWnd.document.write(\"$_<br>\");\n";
           	} 
			print "	pWnd.document.write('</body></html>');
               		pWnd.document.close();
              		}
              		openlog();
              		</script>
          	";
				
		}
		
	}		
}	


sub addobject {

	my $sthI=$dbh->prepare("INSERT INTO ${DBPREFIX}tree (up,keyname,template,ltemplate,lang) VALUES (?,?,?,?,?)");
	my $sthU=$dbh->prepare("UPDATE ${DBPREFIX}tree SET indx=? WHERE id=?");
	my $up;
	my $name;
	my $key;
	my $template;
	my $ltemplate;
	my $indx;
	my $forced;
	if (ref $_[0] eq 'HASH') {
		$up=$_[0]->{up};
		$name=$_[0]->{name};
		$key=$_[0]->{key};
		$template=$_[0]->{template};
		$ltemplate=$_[0]->{ltemplate};
		$indx=$_[0]->{indx};
		$forced=$_[0]->{forced};
		if ($_[0]->{upkey}) {	$up=$nobj->{$_[0]->{upkey}}->{ind} }
		$name=enc($name) if $_[0]->{convertname};
	
	}
	else { $up=$_[0] }
	
	
	return 0 if !$up && !$forced;
	
	$up=~s/u(\d+)/$1/;
	
 	unless ($name) {$name=enc('Новый объект')}
 	
 	unless ($template) {

 		if     ($obj->{$up}->{ltemplate}) { $template=$obj->{$up}->{ltemplate} }
 		elsif ($obj->{$obj->{$up}->{template}}->{ltemplate}) { $template=$obj->{$obj->{$up}->{template}}->{ltemplate} }
 	}	
 	
 	$sthI->execute($up,$key,$template,$ltemplate,$LANGS[0]) || die $dbh->errstr;
 	my $newid=$sthI->{mysql_insertid};
 	
 	
 	unless ($indx) {$indx=$newid}
 	$sthU->execute($indx,$newid) || die $dbh->errstr;
 	
 	push (@{$tree->{$up}},$newid);
 	$obj->{$newid}->{name}=$name;
 	$obj->{$newid}->{up}=$up;
 	$obj->{$newid}->{key}=$key; 	
 	$obj->{$newid}->{template}=$template;
 	$obj->{$newid}->{ltemplate}=$ltemplate; 	
 	$obj->{$newid}->{type}='U'; 	
 	$obj->{$newid}->{ind}=$newid; 	
 	$obj->{$newid}->{id}='u'.$newid; 	
 	$obj->{$newid}->{indx}=$indx;
 	$obj->{$newid}->{lang}=$LANGS[0]; 	
 	$obj->{"u$newid"}=$obj->{$newid};
	if ($key) { $nobj->{$key}=$obj->{$newid} }


  setvalue({uid=>$newid,param=>'_NAME',value=>$name});

 	return $newid;
}

sub addlowobject {

	
	
	
	my $up;
	my $upobj;
 	my $template;
	my $name;
	my $key;
	my $indx;
	
	
	
	if (ref $_[0] eq 'HASH') {
		$up=$_[0]->{up};
		$upobj=$_[0]->{upobj};
		$template=$_[0]->{template};
		$name=$_[0]->{name};
		$key=$_[0]->{key};
		$indx=$_[0]->{indx};
		
		if ($_[0]->{upobjkey}) {
				checkload({key=>$_[0]->{upobjkey}});
				$upobj=$nobj->{$_[0]->{upobjkey}}->{id};
		}		
			
		if ($_[0]->{upkey}) {
				checkload({key=>$_[0]->{upkey}});
				$upobj=$nobj->{$_[0]->{upkey}}->{id};
		}		
		$name=enc($name) if $_[0]->{convertname};
		
		
	}	 
	else {
 		$up=$_[0];
 		$upobj=$_[1];
 	}	
 	
 	
 	unless($up) {$up=0}
 	
 	unless ($upobj) {
 		$upobj=$up;
 		$up=0;
 	}
 	if ($upobj=~/u(\d+)/) {$upobj=$1}
  	#checkload({uid=>$upobj});
 	
	unless ($name) {$name=enc('Новый объект')}
 	unless ($template) {
 		if    ( $lobj->{$up} && $lobj->{$up}->{template} && $obj->{$lobj->{$up}->{template}}->{ltemplate})   {$template=$obj->{$lobj->{$up}->{template}}->{ltemplate}}
 		elsif ($obj->{$obj->{$upobj}->{template}}->{ltemplate}) {$template=$obj->{$obj->{$upobj}->{template}}->{ltemplate}}
 		elsif ($obj->{$upobj}->{ltemplate}) {$template=$obj->{$upobj}->{ltemplate}}
 		
 	}	
  	my $sthIX=$dbh->prepare("INSERT INTO ${DBPREFIX}objects (up,upobj,template,keyname) VALUES (?,?,?,?)");
 	$sthIX->execute($up,$upobj,$template,$key) || die $dbh->errstr;
 	my $newid=$sthIX->{mysql_insertid};
 	
 	 	
 	unless ($indx) {$indx=$newid}
 	my $sthUX=$dbh->prepare("UPDATE ${DBPREFIX}objects SET indx=? WHERE id=?");
 	$sthUX->execute($indx,$newid) || die $dbh->errstr;

 	
 	push (@{$ltree->{$upobj}->{$up}},$newid);
 	$lobj->{$newid}->{name}=$name;
 	$lobj->{$newid}->{up}=$up;
 	$lobj->{$newid}->{upobj}=$upobj;
 	$lobj->{$newid}->{template}=$template;
 	$lobj->{$newid}->{key}=$key;
 	$lobj->{$newid}->{type}='L'; 	
	$lobj->{$newid}->{ind}=$newid;  
	$lobj->{$newid}->{id}=$newid; 
	$lobj->{$newid}->{indx}=$indx; 
	$lobj->{$newid}->{lang}=$obj->{$upobj}->{lang}; 
	if ($key) { $nobj->{$key}=$lobj->{$newid}  }
	


 	setvalue({id=>$newid,param=>'_NAME',value=>$name});
 	
 	return $newid;
}

sub deletelowlist
{
	my $uid=$_[0];
	my $limit=$_[1];
	checkload({uid=>$uid,limit=>$limit});
	my @dlist=@{$cmlmain::ltree->{$uid}->{0}};
	deletelowobject(\@dlist);
	return join(';',@dlist);
}

sub deleteobject
{
 my $id=$_[0];
 my $force=$_[1];
 if ($_[0]=~/u(\d+)/) {$id=$1}
 if ($obj->{$id}->{up}==0 && !$force) {print "cant delete root object"; return}
 
 for (@{$cmlmain::ltree->{$id}->{0}}) {
 	deletelowobject($_);
 }
 
 
 my $sthD=$dbh->prepare("DELETE FROM ${DBPREFIX}tree WHERE id=?");
 $sthD->execute($id) || die $dbh->errstr;
 
 @{$tree->{$obj->{$id}->{up}}}=grep{$_ ne $id}@{$tree->{$obj->{$id}->{up}}};
 
 #my $sthDL=$dbh->prepare("DELETE FROM ${DBPREFIX}objects WHERE upobj=?"); $sthDL->execute($id) || die $dbh->errstr;
 
 my $sthDP=$dbh->prepare("DELETE FROM ${DBPREFIX}prm WHERE objid=?");  $sthDP->execute($id) || die $dbh->errstr;
 my $sthDM=$dbh->prepare("DELETE FROM ${DBPREFIX}method WHERE objid=?");  $sthDM->execute($id) || die $dbh->errstr;
 my $sthDM2=$dbh->prepare("DELETE FROM ${DBPREFIX}uvls WHERE objid=?");  $sthDM2->execute($id) || die $dbh->errstr;
 my $sthDDL=$dbh->prepare("DELETE FROM ${DBPREFIX}links WHERE objid=?");  $sthDDL->execute("u$id") || die $dbh->errstr;
 my $sthXDL=$dbh->prepare("DELETE FROM ${DBPREFIX}links WHERE vallink=?");  $sthXDL->execute("u$id") || die $dbh->errstr;
 
 undef $ltree->{$id};

 map
 {
  deleteobject($_);
 }(@{$tree->{$id}});
}

sub deletelowobject
{
 	if (ref $_[0] eq 'ARRAY') {
 			for (@{$_[0]}) {deletelowobject($_)}
 			return;
 	}	
 
 	my @dlist=split(';',$_[0]);
 	my $id=shift @dlist;
 
 	my $sthD=$dbh->prepare("DELETE FROM ${DBPREFIX}objects WHERE id=?");
 	my $sthDM=$dbh->prepare("DELETE FROM ${DBPREFIX}vls WHERE objid=?");  $sthDM->execute($id) || die $dbh->errstr;
 	my $sthDDL=$dbh->prepare("DELETE FROM ${DBPREFIX}links WHERE objid=?");  $sthDDL->execute($id) || die $dbh->errstr;
 	my $sthXDL=$dbh->prepare("DELETE FROM ${DBPREFIX}links WHERE vallink=?");  $sthXDL->execute($id) || die $dbh->errstr;
 	my $sthFSDL=$dbh->prepare("DELETE FROM ${DBPREFIX}fs WHERE id=?");  $sthFSDL->execute($id) || die $dbh->errstr;
 	my $sthFSIDL=$dbh->prepare("DELETE FROM ${DBPREFIX}fsint WHERE id=?");  $sthFSIDL->execute($id) || die $dbh->errstr;
 	$sthD->execute($id) || die $dbh->errstr;
 	checkload({id=>$id});
 	my $upobj=$lobj->{$id}->{upobj};
 	@{$ltree->{$upobj}->{$lobj->{$id}->{up}}}=grep{$_ ne $id}@{$ltree->{$upobj}->{$lobj->{$id}->{up}}};
 	undef $nobj->{$lobj->{$id}->{key}} if $lobj->{$id}->{key}; 
 	map {
  		deletelowobject($_);
 	}(@{$ltree->{$upobj}->{$id}});
 	if (@dlist) {deletelowobject(\@dlist)}	
 	return 1;
}


sub buildtree
{
  my $sth=$dbh->prepare("SELECT * FROM ${DBPREFIX}tree ORDER BY id");
  $sth->execute() || die $dbh->errstr;
  while ($item=$sth->fetchrow_hashref)
  {
   push (@{$tree->{$item->{up}}},$item->{id});
   $obj->{$item->{id}}->{key}=$item->{keyname};
   $obj->{$item->{id}}->{up}=$item->{up};
   $obj->{$item->{id}}->{type}='U';
   $obj->{$item->{id}}->{ind}=$item->{id};
   $obj->{$item->{id}}->{id}='u'.$item->{id};
   $obj->{$item->{id}}->{template}=$item->{template};
   $obj->{$item->{id}}->{ltemplate}=$item->{ltemplate};
   $obj->{$item->{id}}->{indx}=$item->{indx};
   $obj->{$item->{id}}->{lang}=$item->{lang};
   $obj->{$item->{id}}->{nolog}=$item->{nolog};
   $nobj->{$item->{keyname}}=$obj->{$item->{id}} if $item->{keyname};
   $obj->{"u$item->{id}"}=$obj->{$item->{id}};
  }
 
	
	my $sthv=$dbh->prepare("SELECT * FROM ${DBPREFIX}uvls WHERE pkey='_NAME'");
	$sthv->execute() || die $dbh->errstr;
  	while ($item=$sthv->fetchrow_hashref) {
  		if ($item->{lang} eq $LANGS[0]) {$obj->{$item->{objid}}->{name}=$item->{value}}
  		$obj->{$item->{objid}}->{"name_$item->{lang}"}=$item->{value};
		}	

	
  
}

sub fetchdate {
	(my $value, my $frmt)=@_; 
	my @tlist;
	(my @flist)=($frmt=~/(%\w[^%]*)/g);
	for (@flist) {
		 (my $f, my $sep)=($_=~/^%(\w)(.*)$/);
		 if ($f eq 'Y') {
		 	  $value=~s/^(\d\d\d\d)$sep//;
		 	  $tlist[5]=$1;
		 }	
 		 elsif ($f eq 'm') {
		 	  $value=~s/^(\d\d)$sep//;
		 	  $tlist[4]=$1-1;
		 }	
		 elsif ($f eq 'd') {
		 	  $value=~s/^(\d\d)$sep//;
		 	  $tlist[3]=$1;
		 }	
  }
	return timegm(@tlist);
}	
	
sub prminfo {
	my ($pkey) = @_;
	my $r;
	 
	my $sth1=$dbh->prepare("SELECT * FROM ${DBPREFIX}prm WHERE pkey=?");
	$sth1->execute($pkey) || die $dbh->errstr;
	while (my $st=$sth1->fetchrow_hashref()) {
		push (@{$r->{prm}},$st)
	}
	
	my $sth2=$dbh->prepare("SELECT * FROM ${DBPREFIX}extraprm WHERE pkey=?");
	$sth2->execute($pkey) || die $dbh->errstr;
	while (my $st=$sth2->fetchrow_hashref()) {
		$r->{extra}->{$st->{extra}}=$st->{value};
	}	 
	return $r;
	
}

sub buildparam 	{
  	my $sth1=$dbh->prepare("SELECT * FROM ${DBPREFIX}prm ORDER BY id");
  	$sth1->execute() || die $dbh->errstr;
  	while (my $item=$sth1->fetchrow_hashref)   {
  		$prm->{$item->{pkey}}->{pkey}=$item->{pkey};
   		$prm->{$item->{pkey}}->{name}=$item->{pname};
   		$prm->{$item->{pkey}}->{type}=$item->{ptype};
   		$prm->{$item->{pkey}}->{self}=$item->{self};   
   		$prm->{$item->{pkey}}->{evaluate}=$item->{evaluate};
   		$prm->{$item->{pkey}}->{orderid}=$item->{orderid} if $item->{orderid};
   		
   		$prm->{$item->{pkey}}->{defval}->{$item->{objid}}=$item->{defval};
   		$prm->{$item->{pkey}}->{upd}->{$item->{objid}}=$item->{upd};
   		
   		$prm->{$item->{pkey}}->{defval}->{"u$item->{objid}"}=$item->{defval};
   		$prm->{$item->{pkey}}->{upd}->{"u$item->{objid}"}=$item->{upd};
   		
   		
   		if   ($item->{self} eq 'n') { push (@{$obj->{$item->{objid}}->{prm}},$item->{pkey}) }
   		else                        { push (@{$obj->{$item->{objid}}->{sprm}},$item->{pkey}) } 
   		
   		push (@{$prm->{$item->{pkey}}->{idlist}},$item->{objid});
  	}
   		

  	my $sth2=$dbh->prepare("SELECT * FROM ${DBPREFIX}extraprm");
  	$sth2->execute() || die $dbh->errstr;
  	while (my $item=$sth2->fetchrow_hashref)   {
     		$prm->{$item->{pkey}}->{extra}->{$item->{extra}}=$item->{value} if $prm->{$item->{pkey}};
  	}
  	
  	my $sth3=$dbh->prepare("SELECT * FROM ${DBPREFIX}method ORDER BY id");
  	$sth3->execute() || die $dbh->errstr;
  	while ($item=$sth3->fetchrow_hashref)   {
  		$obj->{$item->{objid}}->{method}->{$item->{pkey}}->{script}=$item->{script};
  		$obj->{$item->{objid}}->{method}->{$item->{pkey}}->{name}=$item->{pname};
  		$method->{$item->{pkey}}->{name}=$item->{pname};
  		$method->{$item->{pkey}}->{script}=$item->{script};
		}
  	
  	
  	my $sth4=$dbh->prepare("SELECT * FROM ${DBPREFIX}lmethod ORDER BY id");
  	$sth4->execute() || die $dbh->errstr;
  	while ($item=$sth4->fetchrow_hashref)   {
  		$obj->{$item->{objid}}->{lmethod}->{$item->{pkey}}->{script}=$item->{script};
  		$obj->{$item->{objid}}->{lmethod}->{$item->{pkey}}->{name}=$item->{pname};
  		$lmethod->{$item->{pkey}}->{name}=$item->{pname};
  		$lmethod->{$item->{pkey}}->{script}=$item->{script};
		}
  	
  	
  	
  	$prm->{_NAME}->{type}='TEXT';
  	$prm->{_UP}->{extra}->{formula}='lowlevel(uobj(uobj()))';
  	$prm->{_UP}->{extra}->{single}='y';

  	
  	
	@ptypes=( 'TEXT', 'NUMBER', 'LONGTEXT', 'FLAG', 'DATE', 'LIST', 'MATRIX' , 'PICTURE', 'FILE', 'FILELINK'  );
	
}

sub addmethod {
	my $id=$_[0]->{id};
	my $name=$_[0]->{name};
	my $key=$_[0]->{key};
	my $script=$_[0]->{script};
	my $lflag=$_[0]->{lflag};
	$name=enc($name) if $_[0]->{convertname};
	$script=enc($script) if $_[0]->{convertscript};
	if ($_[0]->{objkey}) { $id=$nobj->{$_[0]->{objkey}}->{ind} }
	
	
	if ($lflag) {
		my $sth=$dbh->prepare("INSERT INTO ${DBPREFIX}lmethod (objid,pname,pkey,script) VALUES (?,?,?,?)");
 		$sth->execute($id,$name,$key,$script) || die $dbh->errstr;
 		$obj->{$id}->{lmethod}->{$key}->{name}=$name;
 		$obj->{$id}->{lmethod}->{$key}->{script}=$script;
 		$lmethod->{$key}->{name}=$name;
 		$lmethod->{$key}->{script}=$script;
 	} else {
		my $sth=$dbh->prepare("INSERT INTO ${DBPREFIX}method (objid,pname,pkey,script) VALUES (?,?,?,?)");
 		$sth->execute($id,$name,$key,$script) || die $dbh->errstr;
 		$obj->{$id}->{method}->{$key}->{name}=$name;
 		$obj->{$id}->{method}->{$key}->{script}=$script;
 		$method->{$key}->{name}=$name;
 		$method->{$key}->{script}=$script;
	}
	
}	

sub addprm {
 		my $id=$_[0]->{id};
 		my $name=$_[0]->{name};
 		my $type=$_[0]->{type};
 		my $key=$_[0]->{key};
 		my $defval=$_[0]->{defval};
 		my $upd=$_[0]->{upd} || 'y';
 		$name=enc($name) if $_[0]->{convertname};
 		my $self;
 		my $evl;
 		if ($id=~/u(\d+)/) {$id=$1}
 		if ($_[0]->{objkey}) { $id=$nobj->{$_[0]->{objkey}}->{ind} }
 		
		if ($_[0]->{self}==1) {$self='y'; $evl='n'} else {$self='n'; $evl='y'}
		if ($_[0]->{evl}) {$evl=$_[0]->{evl}}
	
	
		my $sth=$dbh->prepare("INSERT INTO ${DBPREFIX}prm (objid,pname,ptype,pkey,self,evaluate,upd,defval) VALUES (?,?,?,?,?,?,?,?)");
 		$sth->execute($id,$name,$type,$key,$self,$evl,$upd,$defval) || die $dbh->errstr;

 		$prm->{$key}->{name}=$name;
 		$prm->{$key}->{type}=$type;
 		$prm->{$key}->{self}=$self;
 		$prm->{$key}->{evaluate}=$evl;
 		$prm->{$key}->{upd}->{$id}=$upd;
 		$prm->{$key}->{defval}->{$id}=$defval;
 
 		if ($self eq 'n')  { push (@{$obj->{$id}->{prm}},$key) }
 		else  		   { push (@{$obj->{$id}->{sprm}},$key) } 	
	

 		if ($nobj->{'MAINPRM'}) {
 			 addlowobject({upobj=>$nobj->{MAINPRM}->{ind},name=>$name,key=>"_PP_$key"});
 		}	
 		
}


sub copyprm {
		my $id=$_[0]->{id};
		my $key=$_[0]->{key};
		if ($_[0]->{objkey}) { $id=$nobj->{$_[0]->{objkey}}->{ind} }
		
		my $sth1=$dbh->prepare("select pname,ptype,pkey,self,evaluate FROM ${DBPREFIX}prm WHERE pkey=?");
		$sth1->execute($key) || die $dbh->errstr;
		my @row=$sth1->fetchrow;
		my $sth=$dbh->prepare("INSERT INTO ${DBPREFIX}prm (objid,pname,ptype,pkey,self,evaluate) VALUES (?,?,?,?,?,?)"); 
    $sth->execute($id,@row) || die $dbh->errstr;				 		                   

 		if ($prm->{$key}->{self} eq 'n')  { push (@{$obj->{$id}->{prm}},$key) }
 		else  		   { push (@{$obj->{$id}->{sprm}},$key) } 	
}	


sub copymethod {
		my $id=$_[0]->{id};
		my $key=$_[0]->{key};
		
		my $sth1=$dbh->prepare("select pname,pkey,script FROM ${DBPREFIX}method WHERE pkey=?");
		$sth1->execute($key) || die $dbh->errstr;
		my @row=$sth1->fetchrow;
		my $sth=$dbh->prepare("INSERT INTO ${DBPREFIX}method (objid,pname,pkey,script) VALUES (?,?,?,?)"); 
    $sth->execute($id,@row) || die $dbh->errstr;				 		                   


 		$obj->{$id}->{method}->{$key}->{script}=$row[2];
 		$obj->{$id}->{method}->{$key}->{name}=$row[0];
}	



sub deletemethod {
 	my $id=$_[0];
 	my $key=$_[1];
 	my $lflag=$_[2];
 	my $sthD;
 	if ($lflag) {
 		$sthD=$dbh->prepare("DELETE FROM ${DBPREFIX}lmethod WHERE objid=? AND pkey=?");
 		delete $obj->{$id}->{lmethod}->{$key};
 	}
 	else 	      {
 		$sthD=$dbh->prepare("DELETE FROM ${DBPREFIX}method WHERE objid=? AND pkey=?");
 		delete $obj->{$id}->{method}->{$key};
 	}
 	$sthD->execute($id,$key)||die $dbh->errstr;
 	
}




sub deleteprm {
 	my $id=$_[0];
 	my $key=$_[1];
 	$id=~s/^u//;
 	my $sthD=$dbh->prepare("DELETE FROM ${DBPREFIX}prm WHERE objid=? AND pkey=?");
 	$sthD->execute($id,$key)||die $dbh->errstr;
 	for (@{$obj->{$id}->{prm}}) {if ($_ eq $key) {undef $_}}
 	for (@{$obj->{$id}->{sprm}}) {if ($_ eq $key) {undef $_}}
 	unless ($#{$prm->{$key}->{idlist}}>0)  	{
 	#unless ($#{$obj->{$id}->{prm}}+$#{$obj->{$id}->{sprm}}>=0)  	{
   		my $sthDEX=$dbh->prepare("DELETE FROM ${DBPREFIX}extraprm WHERE pkey=?");
   		$sthDEX->execute($key)||die $dbh->errstr;
   		checkload({key=>"_PP_$key"});
  		deletelowobject($nobj->{"_PP_$key"}->{ind});
 	}
	
}

sub buildlist {
	my $list=$_[0];
	my $lstr=join (',',map {"'$_'"} grep {!/^u/} split (';', $list) );
	return unless $lstr;
	my $sth=$dbh->prepare("SELECT * FROM ${DBPREFIX}objects WHERE id in ($lstr) ORDER BY id");
	$sth->execute() || die $dbh->errstr();
	while ($item=$sth->fetchrow_hashref)   {
   		unless ($lobj->{$item->{id}}->{id}) {
    		push (@{$ltree->{$item->{upobj}}->{$item->{up}}},$item->{id});
   			$lobj->{$item->{id}}->{key}=$item->{keyname};
   			$lobj->{$item->{id}}->{up}=$item->{up};
   			$lobj->{$item->{id}}->{upobj}=$item->{upobj};
   			$lobj->{$item->{id}}->{type}='L';
   			$lobj->{$item->{id}}->{ind}=$item->{id};
   			$lobj->{$item->{id}}->{id}=$item->{id};
   			$lobj->{$item->{id}}->{template}=$item->{template};
   			$lobj->{$item->{id}}->{indx}=$item->{indx};
   			$lobj->{$item->{id}}->{lang}=$obj->{$item->{upobj}}->{lang};
   			$nobj->{$item->{keyname}}=$lobj->{$item->{id}};
    	}	
   	}
   	
   	
    my $sthN=$dbh->prepare("SELECT * FROM ${DBPREFIX}fs WHERE prm='_NAME' AND id in ($lstr)");
    $sthN->execute() || die $dbh->errstr(); 
	while ($item=$sthN->fetchrow_hashref) {
		my $lang=$obj->{$lobj->{$item->{id}}->{upobj}}->{lang};
		if (  ($lang eq 'mul' && ($item->{lang} eq $LANGS[0])) || ($lang eq $item->{lang})	|| (!$item->{lang})	) {
  			$lobj->{$item->{id}}->{name}=$item->{val};
  		}	
  		$lobj->{$item->{id}}->{"name_$item->{lang}"}=$item->{val}
  	}	
  
}


sub buildlowtree
{
 my $upobj=$_[0];
 my $objid=$_[1];
 my $limit=$_[2];

 

	 my $t=time; 	
	 
	 my $sthL;
	 if ($objid) {
	 	$sthL=$sthLTT1;
	 	$sthL->execute($upobj,$objid) || die $dbh->errstr
	 } elsif ($limit){
	 	$sthL=$sthLTTL;
	 	$sthL->execute($upobj,$limit) || die $dbh->errstr	
	 } else {
	 	 $sthL=$sthLTT;
	 	 $sthL->execute($upobj) || die $dbh->errstr
	 }
	 
	 my $lang=$obj->{$upobj}->{lang};
	
	my @idlist;	 
   while ($item=$sthL->fetchrow_hashref)
   {
   	unless ($lobj->{$item->{id}}->{id}) {
    	push (@{$ltree->{$upobj}->{$item->{up}}},$item->{id});
    	push (@idlist,$item->{id});
    	$lobj->{$item->{id}}->{key}=$item->{keyname};
    	$lobj->{$item->{id}}->{up}=$item->{up};
    	$lobj->{$item->{id}}->{upobj}=$upobj;
    	$lobj->{$item->{id}}->{type}='L';
    	$lobj->{$item->{id}}->{ind}=$item->{id};
    	$lobj->{$item->{id}}->{id}=$item->{id};
    	$lobj->{$item->{id}}->{template}=$item->{template};
    	$lobj->{$item->{id}}->{indx}=$item->{indx};
    	$lobj->{$item->{id}}->{lang}=$obj->{$upobj}->{lang};
    	$nobj->{$item->{keyname}}=$lobj->{$item->{id}} if $item->{keyname};
    }	
   }
   
   
      my $jstr=join(',',@idlist); 
      my $sthN;
      my $ff=1;
      if ($objid) {
 		 $sthN=$dbh->prepare("SELECT * FROM ${DBPREFIX}fs WHERE prm='_NAME' AND id=?")|| die $dbh->errstr;
      	 $sthN->execute($objid) || die $dbh->errstr;
      }elsif ($limit && $jstr) {
      	 $sthN=$dbh->prepare("SELECT * FROM ${DBPREFIX}fs WHERE prm='_NAME' AND id in ($jstr)");
      	 $sthN->execute() || die $dbh->errstr(); 
      } elsif ($jstr) {
      	 $sthN=$dbh->prepare("SELECT * FROM ${DBPREFIX}fs WHERE prm='_NAME' AND id in ($jstr)") || die $dbh->errstr; 
      	 $sthN->execute() || die $dbh->errstr;
      }else {$ff=0}	
		
  	  if($ff) {	
  		while ($item=$sthN->fetchrow_hashref) {
  			if (  ($lang eq 'mul' && ($item->{lang} eq $LANGS[0])) || ($lang eq $item->{lang})	|| (!$item->{lang})	) {
  					$lobj->{$item->{id}}->{name}=$item->{val};
  			}	
  			$lobj->{$item->{id}}->{"name_$item->{lang}"}=$item->{val}
		}	
  	  }

#	if ($obj->{$upobj}->{lang}) {
#			 my $sthVL;
#	  
#      
#		  
#       if ($objid) {
#      	 $sthVL=$sthVLN1; 
#  			 $sthVLN1->execute($upobj,$objid) || die $dbh->errstr;
#  		 } else {
#  		 	 $sthVL=$sthVLN; 
#  		 	 $sthVL->execute($upobj) || die $dbh->errstr;
#  		 }	
#  			while ($item=$sthVL->fetchrow_hashref) {
#  				$lobj->{$item->{objid}}->{"name_$item->{lang}"}=$item->{value};
#				}	
#	}	
	$cmlcalc::TIMERS->{LOWTREE}->{sec}+=(time-$t);
  $cmlcalc::TIMERS->{LOWTREE}->{count}++;

}

sub buildtabtree {
	my $id=$_[0]->{id};
	my $pkey=$_[0]->{pkey};
	my $tabkey=$_[0]->{tabkey};
	$tobj->{$id}->{$pkey}->{vals}->{$tabkey}->{type} ='T';
	$tobj->{$id}->{$pkey}->{vals}->{$tabkey}->{ind}  =$tabkey;
	$tobj->{$id}->{$pkey}->{vals}->{$tabkey}->{id}   ='t'.$tabkey;
	$tobj->{$id}->{$pkey}->{vals}->{$tabkey}->{tid}  =$id;
	$tobj->{$id}->{$pkey}->{vals}->{$tabkey}->{tpkey}=$pkey;
}
	



sub checkload
{
	

	my $t=time;
  if ($_[0]->{tabkey})   {
  	unless ($tobj->{$_[0]->{id}}->{$_[0]->{pkey}}->{vals}->{$_[0]->{tabkey}})  {
  		buildtabtree({id=>$_[0]->{id},pkey=>$_[0]->{pkey},tabkey=>$_[0]->{tabkey}})
  	}	
  }
  
  
  elsif ($_[0]->{id})
  {
   if ($_[0]->{buildtree}) {
      my $sthO=$dbh->prepare("SELECT upobj FROM ${DBPREFIX}objects WHERE id=?");
      $sthO->execute($_[0]->{id}) || die $dbh->errstr;
      $upobj=$sthO->fetchrow();
   	  buildlowtree($upobj)
   }
  
   	
   elsif (!$lobj->{$_[0]->{id}}->{id})
   {
   
   	
   	
    my $sthO=$dbh->prepare("SELECT upobj FROM ${DBPREFIX}objects WHERE id=?");
    $sthO->execute($_[0]->{id}) || die $dbh->errstr;
    $upobj=$sthO->fetchrow();
    return $upobj if $_[0]->{onlyup};
    buildlowtree($upobj,$_[0]->{id});
   }
   return $lobj->{$_[0]->{id}}->{upobj};
  }
  elsif ($_[0]->{key})
  {
   unless ($nobj->{$_[0]->{key}})
   {
    my $sthK=$dbh->prepare("SELECT upobj,id FROM ${DBPREFIX}objects WHERE keyname=?");
    $sthK->execute($_[0]->{key}) || die $dbh->errstr;
    ($upobj,$oid)=$sthK->fetchrow();
    buildlowtree($upobj,$oid);
   }
   return $nobj->{$_[0]->{key}}->{ind};
  }
  elsif ($_[0]->{uid})
  {
   #unless ($ltree->{$_[0]->{uid}})
   #{
    buildlowtree($_[0]->{uid},undef,$_[0]->{limit});
   #}
  }
	$cmlcalc::TIMERS->{CHECKLOAD}->{sec}+=(time-$t);
  $cmlcalc::TIMERS->{CHECKLOAD}->{count}++;


}


sub treelist
{
  my $id=$_[0];
  my @tlist=($id);
  while ($obj->{$id}->{up}>1)
  {
   $id=$obj->{$id}->{up};
   push(@tlist,"u$id");
  }
  push(@tlist,'u1') if $obj->{$id}->{up} == 1;
  return @tlist;
}


sub lparamlist {
  	my $objid=$_[0];
  	my @plist;
  	for (treelist($objid)) { 
  		push(@plist,@{$obj->{$_}->{prm}});
  		if ($obj->{$_}->{template}) {push(@plist,@{$obj->{$obj->{$_}->{template}}->{prm}});}
  	}
    if ($obj->{$objid}->{template})  {
        my $template=$obj->{$objid}->{template};  	
    		for (treelist($template)) { push(@plist,@{$obj->{$_}->{prm}}) } 
    		push(@plist,@{$obj->{$template}->{sprm}});
  	}	
  	return @plist;
}



sub paramlist {
  	my $objid=$_[0];
  	my @plist;
  	for (treelist($lobj->{$objid}->{upobj})) { 
  		push(@plist,@{$obj->{$_}->{prm}});
  		
  		if ($obj->{$_}->{template}) {push(@plist,@{$obj->{$obj->{$_}->{template}}->{prm}});}
  		 
  	}
    if ($lobj->{$objid}->{template})  {
                my $template=$lobj->{$objid}->{template};  	
    		for (treelist($template)) { push(@plist,@{$obj->{$_}->{prm}}) } 
    		push(@plist,@{$obj->{$template}->{sprm}});
  	}	
  	return @plist;
}

sub uparamlist {
  my $objid=$_[0];
  my @plist;
  push(@plist,@{$obj->{$objid}->{sprm}});
  if ($obj->{$objid}->{template}) 
  {
    for (treelist($obj->{$objid}->{template})) { push(@plist,@{$obj->{$_}->{sprm}}) }  	
  }	
  return @plist;
}


sub umethodlist {
  my $objid=$_[0];
  my @mlist;
  if  ($obj->{$objid}->{method}) { push(@mlist,keys %{$obj->{$objid}->{method}}) }
  if ($obj->{$objid}->{template}) 
  {
    for (treelist($obj->{$objid}->{template})) { 
    	if ($obj->{$_}->{method}) {
    		push(@mlist,keys %{$obj->{$_}->{method}}) 
    	} 
    }  	
  }	
  return @mlist;
}


sub methodlist {
  my $objid=$_[0];
  my @mlist;
  
  	for (treelist($lobj->{$objid}->{upobj})) { 
  		push(@mlist,keys %{$obj->{$_}->{lmethod}}) ;
  		if ($obj->{$_}->{template}) {push(@mlist, keys %{$obj->{$obj->{$_}->{template}}->{lmethod}});}
  	}
   if ($lobj->{$objid}->{template}) {
   	  my $t=$lobj->{$objid}->{template};
   	  push(@mlist,keys %{$obj->{$t}->{lmethod}}) ;
   }
  return @mlist;
}






sub loadcmsmethod {
	 my $mlist;
	 my $id=$_[0];
	 
	 
	 my $lekey="LISTEDIT_".$obj->{$id}->{key};
	 checkload({key=>$lekey});
	 $mlist->{listedittemplate}=$lekey if $nobj->{$lekey}->{id};
	 
	 my $ekey ="EDIT_".$obj->{$id}->{key};
	 checkload({key=>$ekey});
	 $mlist->{edittemplate}=$ekey if $nobj->{$ekey}->{id};
	 
	 return $mlist;
}	

sub createcmsmethod {
	my $id=$_[0];
	my $prm=$_[1];
	my $key=$obj->{$id}->{key};
	my $name=$obj->{$id}->{name};
	my $method;
    my $template=createtemplate($id,$prm);

	
	if ($prm eq 'listedittemplate') {
		$method="LISTEDIT_$key";
		my $newid=addlowobject({upobj=>$nobj->{CMSDESIGN}->{id},key=>$method,name=>enc("Шаблон редактирования списка")." '$name'"});
		setvalue({id=>$newid,param=>'PAGETEMPLATE',value=>$template});
	}	elsif ($prm eq 'edittemplate') {
		$method="EDIT_$key";
		my $newid=addlowobject({upobj=>$nobj->{CMSDESIGN}->{id},key=>$method,name=>enc("Шаблон объекта")." '$name'"});
		setvalue({id=>$newid,param=>'PAGETEMPLATE',value=>$template});
	}

}	


sub rebuildcmsmethod {
	my $id=$_[0];
	my $prm=$_[1];
	my $key=$obj->{$id}->{key};

	my $template=createtemplate($id,$prm);
	if ($prm eq 'edittemplate') {
		setvalue({key=>"EDIT_$key",param=>'PAGETEMPLATE',value=>$template});
	} elsif ($prm eq 'listedittemplate') {
		setvalue({key=>"LISTEDIT_$key",param=>'PAGETEMPLATE',value=>$template});
	}
}	


sub deletecmsmethod {
	my $id=$_[0];
	my $prm=$_[1];
	my $key=$obj->{$id}->{key};
	if ($prm eq 'edittemplate') {
		my $k="EDIT_$key";
		checkload({key=>$k});
		deletelowobject($nobj->{$k}->{id});
	}	elsif ($prm eq 'listedittemplate') {
		my $k="LISTEDIT_$key";
		checkload({key=>$k});
		deletelowobject($nobj->{$k}->{id});
	}
	
}	


sub createtemplate {
	my $id=$_[0];
	my $prm=$_[1];
	my $key=$obj->{$id}->{key};	
    if ($prm eq 'edittemplate') {
  		my $tmpl=calculate({key=>'BASEEDIT',expr=>'p(PAGETEMPLATE)',noparse=>1})->{value};
  	 	$tmpl=~s/\$key/$key/igs;
  	 	return $tmpl;
  	}	
  	if ($prm eq 'listedittemplate') {
	  	my $tmpl=calculate({key=>'BASELISTEDIT',expr=>'p(PAGETEMPLATE)',noparse=>1})->{value};
  	 	$tmpl=~s/\$key/$key/igs;
  	 	return $tmpl;
  	}	
}	



sub loaduserlist {
	my $sth=$dbh->prepare("SELECT * FROM ${DBPREFIX}users");
	my $rt;
	$sth->execute || die $dbh->errstr;
	while ($item=$sth->fetchrow_hashref) {
		push (@$rt,$item)
	}
	return $rt;
}	


sub adduser {
	my $login=$_[0];
	my $password=$_[1];
	my $group=$_[2];
	if ($login!~/^[a-zA-Z][a-zA-Z0-9_]+$/) {
		message('Неправильные символы в логине');
		return undef;
	}
	my $sth=$dbh->prepare("INSERT INTO ${DBPREFIX}users (login,password,`group`) VALUES (?,ENCRYPT(?),?)");
	$sth->execute ($login,$password,$group) || die $dbh->errstr;
	if ($PASSFILE) {writepassfile()}
}	


sub edituser {
	my $login=$_[0];
	my $password=$_[1];
	my $group=$_[2];
	if ($password) {
		my $sth=$dbh->prepare("UPDATE ${DBPREFIX}users SET password=ENCRYPT(?),`group`=? WHERE login=?");
		$sth->execute ($password,$group,$login) || die $dbh->errstr;
		if ($PASSFILE) {writepassfile()}
	} else {
		my $sth=$dbh->prepare("UPDATE ${DBPREFIX}users SET `group`=? WHERE login=?");
		$sth->execute ($group,$login) || die $dbh->errstr;
	}	
}	



sub deluser {
	my $login=$_[0];
	my $sth=$dbh->prepare("DELETE FROM ${DBPREFIX}users WHERE login=?");
	$sth->execute ($login) || die $dbh->errstr;
	if ($PASSFILE) {writepassfile()}
}	

sub writepassfile {
	unlink $PASSFILE;
	my $ul=loaduserlist();
	my $gl; 
 	open (PSFILE,">$PASSFILE") || die " PASSFILE write error (filename:$PASSFILE) error:$! ";;
   	for (@$ul) {	
   		print PSFILE "$_->{login}:$_->{password}\n";
   		push (@{$gl->{$_->{group}}},$_->{login}) if $_->{group}; 
   	}
  	close PSFILE;
  	chmod (0644, $PASSFILE);
  	
  	open (GRPFILE,">$GRPFILE") || die " GRPFILE write error (filename:$GRPFILE) error:$! ";
   	for ( keys %$gl ) {	
   		my $gstr=join(' ',@{$gl->{$_}});
   		print GRPFILE "$_: $gstr \n"; 
   	}
  	close GRPFILE;
  	chmod (0644, $GRPFILE);
}	


sub createhtaccess {
	
	my $grp=$_[1];
	if ($grp) {
		open (HTFILE, ">$_[0]");
		if ($grp eq 'admin') {
			print HTFILE "
				AuthType Basic
				AuthName \"vCMS $grp Login\"
				AuthUserFile \"$PASSFILE\"
 	 			AuthGroupFile \"$GRPFILE\"
 	 			Require group $grp
 	 		";
		} elsif ($grp eq 'user') {
 	 		print HTFILE "
				AuthType Basic
				AuthName \"vCMS Login\"
				AuthUserFile \"$PASSFILE\"
 				Require valid-user
			";		
 	 	}	
 		close HTFILE;
		chmod (0644, $_[0]); 	
	} 
}	

sub fromcache {
	my ($key,$dev,$lang)=@_;
	$sthSC->execute($key,0+$dev,"$lang") || die $dbh->errstr;
	return $sthSC->fetchrow();
}	

sub tocache {
	my ($key,$value,$links,$dev,$lang)=@_;
	
	$sthIC->execute($key,$value,0+$dev,"$lang") || die $dbh->errstr;
	$sthDC->execute($key,0+$dev,"$lang") ||  die $dbh->errstr;
	my %inserted;
	for (@$links) {
		if ($_ && !$inserted{$_}) {
			$sthLC->execute($key,$_,0+$dev,"$lang") || die $dbh->errstr;
			$inserted{$_}=1;
		}	
	}
}	




sub fastsearch {
	my $pkey=$_[0]->{prm};
	my $pattern=$_[0]->{pattern};
	my $like=$_[0]->{like};
	my $up=$_[0]->{up};
	my $clause=$_[0]->{clause};
	my $sthSRC;
	
	if ($clause) {
		my $tname;
		$clause=~s/p\((.+?)\)/prm='$1' AND val/g;
		
		if ($prm->{$1}->{type} eq 'NUMBER' || $prm->{$1}->{type} eq 'DATE') {
			$tname="${DBPREFIX}fsint";
		} else {
			$tname="${DBPREFIX}fs";
		}
	
		$sthSRC=$dbh->prepare("SELECT id FROM $tname WHERE $clause");
		$sthSRC->execute() || die $dbh->errstr;
	} elsif ($like) {
		$sthSRC=$sthFSL;
		$sthSRC->execute($pkey,$like) || die $dbh->errstr;
	}	else    {
		$sthSRC=$sthFS;
		$sthSRC->execute($pkey,$pattern) || die $dbh->errstr;
	}
	
	
	my @rlist;
	while ($id=$sthSRC->fetchrow) {
		 push(@rlist,$id);
	}	
	
	if ($up) {
		 @rlist = grep {isupper({up=>$up,low=>$_})} @rlist;
	}
	return sort {$lobj->{$a}->{indx}<=>$lobj->{$b}->{indx}} @rlist;
}	


sub fsindexcreate {
	my $pkey=$_[0];
	my $qt;
	if ($prm->{$pkey}->{type} eq 'NUMBER' || $prm->{$pkey}->{type} eq 'DATE') {
		$qt="${DBPREFIX}fsint"
	} else {
		$qt="${DBPREFIX}fs"
	}
	my $sthIND=$dbh->prepare("REPLACE INTO $qt (id,prm,val,lang) SELECT objid,pkey,value,lang FROM ${DBPREFIX}vls WHERE pkey=?");
	$sthIND->execute($pkey) || die $dbh->errstr;
	
}	

return 1;


END {}
