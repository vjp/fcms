package vCMS::Proxy;
 
use lib ".."; 
use cmlmain; 

sub GetIDByKey ($) {
	my $key=shift;
	return cmlmain::checkload({key=>$key});
}

sub GetUpID ($) {
	my $id=shift;
	if ($id=~/u(\d+)/) {
		return $cmlmain::obj->{$1}->{up};
	} elsif ($id=~/(\d+)/) {
		return $cmlmain::lobj->{$1}->{upobj};
	}	
}

sub GetKey ($) {
	my $id=shift;
	if ($id=~/u(\d+)/) {
		return $cmlmain::obj->{$1}->{key};
	} elsif ($id=~/(\d+)/) {
		return $cmlmain::lobj->{$1}->{key};
	}	
}

sub GetLang ($) {
	my $id=shift;
	if ($id=~/u(\d+)/) {
		return $cmlmain::obj->{$1}->{lang};
	} elsif ($id=~/(\d+)/) {
		return $cmlmain::lobj->{$1}->{lang};
	}	
}

sub GetName ($) {
	my $id=shift;
	if ($id=~/u(\d+)/) {
		return $cmlmain::obj->{$1}->{name};
	} elsif ($id=~/(\d+)/) {
		return $cmlmain::lobj->{$1}->{name};
	}	
}



sub CheckObj ($) {
	my $id=shift;
	if ($id=~/u(\d+)/) {
		return $cmlmain::obj->{$1}?1:0;
	} elsif ($id=~/(\d+)/) {
		return $cmlmain::lobj->{$1}?1:0;
	}	
}


sub LowList ($) {
	my $id=shift;
	cmlmain::checkload({uid=>$id}); 
    my @list= sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$id}->{0}};
    return \@list;
}

sub DBSelect {
	my $query=shift;
	my @params=@_;
	my $sth=$dbh->prepare($query)|| die $dbh->errstr;
	$sth->execute(@params) || die $dbh->errstr;
	my $r;
	while (my $row=$sth->fetchrow_hashref) {
		push(@$r,$row);	
	}
	return $r;
}

sub GetTableName ($) {
	return $cmlmain::DBPREFIX.$_[0];
}

sub DBUpdate {
	my $query=shift;
	my @params=@_;
	my  $sth=$dbh->prepare($query) || die $dbh->errstr;
	$sth->execute(@params);
	return {sth=>$sth};
}

sub DBLastInsertID ($) {
	my ($Q)=@_;
	return $Q->{sth}->{mysql_insertid};
}

sub IsMultilangParam ($) {
	my $pkey=shift;
	return $cmlmain::prm->{$pkey}->{type} eq 'TEXT' || $cmlmain::prm->{$pkey}->{type} eq 'LONGTEXT';
}

sub LowValues($) {
	my $id=shift;
	my $l=LowList($id);
	my $idstr=join(',',@$l);
	my $vlstable=$cmlmain::DBPREFIX.'vls';
	my $r=DBSelect("SELECT * FROM $vlstable WHERE objid in ($idstr)");
	my $h;
	for (@$r) {
		next if $_->{pkey} eq '_NAME';
		if (IsMultilangParam($_->{pkey})) {
			$h->{$_->{objid}}->{$_->{pkey}}->{langvalue}->{$_->{lang}}=$_->{value}
		} else {
			$h->{$_->{objid}}->{$_->{pkey}}->{value}=$_->{value}
		}	
	}
	return $h;
	
}


sub GetValue ($$) {
	my ($id,$prm)=@_;
	return cmlcalc::p($prm,$id);
}

sub SetValue ($$$) {
	my ($id,$prm,$value)=@_;
	return cmlcalc::set($id,$prm,$value);
}

sub SetName ($$) {
	my ($id,$value)=@_;
	return cmlcalc::set($id,'_NAME',$value);
}

sub CreateLowObj ($) {
	my ($uid)=@_;
	return cmlcalc::add($uid);
}

sub CreateQueueEvent ($$) {
	my ($objid,$method)=@_;
	my $tname=GetTableName('queue');
	my $Q=DBUpdate("INSERT INTO $tname (objid,method,exectime) VALUES (?,?,NOW())",$objid,$method);
	return DBLastInsertID($Q);
}

sub GetQueueEvent() {
	my $tname=GetTableName('queue');
	my $r=DBSelect("SELECT * FROM $tname WHERE status=0 ORDER by exectime DESC limit=1");
}

sub Execute($$) {
	my ($oid,$method)=@_;
	if ($oid=~/u\d+/) {
		return cmlcalc::execute({method=>$method,id=>$oid});
	} else {
		return cmlcalc::execute({lmethod=>$method,id=>$oid});
	}
}


sub DeleteObject($) {
	my ($oid)=@_;
	if ($oid=~/u(\d+)/) {
		return deleteobject($1);
	} else {
		return deletelowobject($oid);
	}
}

sub CurrentObjectID() {
	return cmlcalc::p(_ID);
}	
	



1;