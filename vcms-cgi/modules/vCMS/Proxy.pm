package vCMS::Proxy;
 
use lib "..";
use POSIX qw(strftime);
use LWP::UserAgent; 
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
		cmlmain::checkload({id=>$id}); 
		return $cmlmain::lobj->{$1}->{upobj}?1:0;
	}	
}


sub LowList ($;$) {
	my ($id,$filterexpr)=@_;
	my @list;
	if ($filterexpr) {
		@list=cmlmain::fastsearch({up=>"u$id",clause=>$filterexpr});	
	} else {
		cmlmain::checkload({uid=>$id}); 
    	@list= sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$id}->{0}};
	}	
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


sub GetValue ($$;$) {
	my ($id,$prm,$opts)=@_;
	my $csv=$opts->{csv}?1:0;
    my $v=&cmlcalc::calculate({
		id=>$id,
		expr=>"p($prm)",
		csv=>$csv,
	});
	my $value=$v->{value};
	if ($opts->{formatted}) {
		if ($cmlmain::prm->{$prm}->{type} eq 'DATE') {
			my $dfrmt=$cmlmain::prm->{$prm}->{extra}->{format};
			$value=&cmlmain::enc(strftime ($dfrmt,localtime($value))) if $dfrmt;
		} elsif ($cmlmain::prm->{$prm}->{type} eq 'LIST') {
			my @v=split(/;/,$value);
			$value=\@v;
		}		
		
	}
	return $value;
}


sub SetValue ($$;$) {
	my ($id,$prm,$value)=@_;
	return cmlcalc::set($id,$prm,$value);
}

sub DefaultValue ($$;$) {
	my ($id,$prm)=@_;
	cmlmain::checkload({id=>$id}); 
	my $v=cmlmain::defaultvalue({id=>$id,pkey=>$prm});
	return $v->{value};
}


sub AppendValue ($$;$) {
	my ($id,$prm,$value)=@_;
	return cmlcalc::app($id,$prm,$value);
}



sub SetName ($$) {
	my ($id,$value)=@_;
	return cmlcalc::set($id,'_NAME',$value);
}

sub MoveTo ($$) {
	my ($id,$upid)=@_;
	return cmlcalc::set($id,'_UP',$upid);
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

sub History ($$) {
	my ($objid,$prm)=@_;
	my $tname=GetTableName('vlshist');
	my $r=DBSelect("SELECT dt,value FROM $tname WHERE objid=? AND pkey=? ORDER BY dt DESC",$objid,$prm);
	return $r;
}


sub Execute($$) {
	my ($oid,$method)=@_;
	if ($oid=~/u\d+/) {
		return cmlcalc::execute({method=>$method,id=>$oid});
	} else {
		return cmlcalc::execute({lmethod=>$method,id=>$oid});
	}
}


sub DeleteObject($;$) {
	my ($oid,$forced)=@_;
	if ($oid=~/u(\d+)/) {
		return deleteobject($1,$forced);
	} else {
		return deletelowobject($oid);
	}
}

sub CurrentObjectID() {
	return cmlcalc::p(_ID);
}	
	
sub GetURL ($) {
	my ($url)=@_;
  	my $ua = LWP::UserAgent->new;
  	$ua->agent("VCMS/0.1");
  	my $res = $ua->request(HTTP::Request->new(GET => $url));
  	if ($res->is_success) {
  		return {content=>$res->content};
  	} else {
  	  	return {err=>1,status=>$res->status_line};
  	}			
}


sub IsSingleLink($) {
	my ($prm)=@_;
	return $cmlmain::prm->{$prm}->{extra}->{single} eq 'y'; 
}


sub UploadFile($$$) {
	my ($id,$prm,$cgiparam)=@_;
	if (ref $prm eq 'HASH') {
		&cmlparse::uploadprmfile({id=>$id,pkey=>$_,cgiparam=>$prm->{$_}}) for keys %$prm;
		return 1;	
	} else {
		return &cmlparse::uploadprmfile({id=>$id,pkey=>$prm,cgiparam=>$cgiparam});
	}	
}


1;