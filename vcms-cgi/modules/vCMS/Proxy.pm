package vCMS::Proxy;
 
use lib "..";
use POSIX qw(strftime);
use LWP::UserAgent;
use JSON::PP; 
use Mail::Sender;
use MIME::Base64;
use cmlmain; 


sub SendFile ($) {
	my $opts=shift;
	$Mail::Sender::Error = '';
	my  $sender = new Mail::Sender  {smtp => 'localhost', from => $opts->{from}};
	$sender->MailFile({
  		to => $opts->{to},         
  		subject => '=?'.'windows-1251'.'?b?'.encode_base64($opts->{subject},'').'?=',
  		msg => $opts->{msg},          
  		file => $opts->{filename},
		b_ctype=>"text/plain; charset=windows-1251",      
		b_encoding => "8bit",      		
	});
	if( $Mail::Sender::Error ne '' ) {
		return (0,$Mail::Sender::Error);
	}  else {
		return 1;
	}
}

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

sub DBQuery {
	return DBUpdate(@_);
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


sub DumpUpper($) {
	my $id=shift;
	$id=~s/^u//;
	my $vlstable=$cmlmain::DBPREFIX.'uvls';
	my $r=DBSelect("SELECT * FROM $vlstable WHERE objid=?",$id);
	my $h;
	for (@$r) {
		next if $_->{pkey} eq '_NAME';
		if (IsMultilangParam($_->{pkey})) {
			$h->{$_->{pkey}}->{langvalue}->{$_->{lang}}=$_->{value}
		} else {
			$h->{$_->{pkey}}->{value}=$_->{value}
		}	
	}
	return $h;
}


sub DumpLower($) {
	my $id=shift;
	my $vlstable=$cmlmain::DBPREFIX.'vls';
	my $r=DBSelect("SELECT * FROM $vlstable WHERE objid=?",$id);
	my $h;
	for (@$r) {
		next if $_->{pkey} eq '_NAME';
		if (IsMultilangParam($_->{pkey})) {
			$h->{$_->{pkey}}->{langvalue}->{$_->{lang}}=$_->{value}
		} else {
			$h->{$_->{pkey}}->{value}=$_->{value}
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


sub SetValue ($$;$$) {
	my ($id,$prm,$value,$opts)=@_;
	return cmlcalc::set($id,$prm,$value,$opts);
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

sub IncValue ($$;$) {
	my ($id,$prm,$value)=@_;
	return cmlcalc::inc($prm,$id,$value);
}



sub SetName ($$) {
	my ($id,$value)=@_;
	return cmlcalc::set($id,'_NAME',$value);
}


sub CreateLowObj ($) {
	my ($uid)=@_;
	return cmlcalc::add($uid);
}

sub CreateQueueEvent ($$;$) {
	my ($objid,$method,$time)=@_;
	my $tname=GetTableName('queue');
	my $Q=DBUpdate("INSERT INTO $tname (objid,method,exectime) VALUES (?,?,FROM_UNIXTIME(?))",$objid,$method,$time);
	return DBLastInsertID($Q);
}


sub CheckQueueEvent ($$) {
	my ($objid,$method)=@_;
	my $tname=GetTableName('queue');
	my $r=DBSelect("SELECT * FROM $tname WHERE objid=? AND method=?",$objid,$method);
	return $r->[0];
}


sub GetQueueEvent($) {
	my ($uniqid)=@_;
	my $tname=GetTableName('queue');
	DBUpdate("UPDATE $tname SET processorid=?,status=1 WHERE status=0 AND exectime<NOW() LIMIT 1",$uniqid);
	my $r=DBSelect("SELECT * FROM $tname WHERE processorid=?",$uniqid);
	return $r->[0];
}

sub ResetQueue() {
	my $tname=GetTableName('queue');
	DBUpdate("UPDATE $tname SET status=0");
	return 1;
}

sub DeleteQueueEvent($) {
	my ($qid)=@_;
	my $tname=GetTableName('queue');
	DBUpdate("DELETE FROM $tname WHERE qid=?",$qid);
	return 1;
}



sub History ($;$) {
	my ($objid,$opts)=@_;
	my $tname=GetTableName('vlshist');
	my $r;
	if ($opts->{prm}) {
		$r=DBSelect("SELECT dt,value,user FROM $tname WHERE objid=? AND pkey=? ORDER BY dt DESC",$objid,$opts->{prm});
	} else {
		$r=DBSelect("SELECT dt,pkey,value,user FROM $tname WHERE objid=? ORDER BY dt DESC",$objid);
	}	
	return $r;
}


sub DelHistory ($;$) {
	my ($objid,$opts)=@_;
	my $tname=GetTableName('vlshist');
	if ($opts->{prm}) {
		DBUpdate("DELETE FROM $tname WHERE objid=? AND pkey=?",$objid,$opts->{prm});
	} else {
		DBUpdate("DELETE FROM $tname WHERE objid=?",$objid);
	}	
	return 1;
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

sub ExportDBStr() {
	return cmlmain::export_db_str();
}

sub ImportDBStr () {
	return cmlmain::import_db_str();
}	

sub GetGlobal ($) {
	my ($var) = @_;
	return $cmlmain::GLOBAL->{$var};	
}	

sub GetPrmExtra ($$) {
	my ($prm,$extra)=@_;
	return $cmlmain::prm->{$prm}->{extra}->{$extra}
}

sub DropPagesCache() {
	my $tname=GetTableName('pagescache');
	DBQuery("DELETE FROM $tname");	
}	

sub CheckSession () {
	return cmlmain::check_session()?($cmlcalc::ENV->{'AUTHUSERID'},$cmlcalc::ENV->{'LOGIN'}):undef;
}

sub SetOTKey ($$) {
	my ($login,$key)=@_;
	my $tname=GetTableName('auth');
	DBQuery("UPDATE $tname SET otkey=? WHERE login=?",$key,$login);
}

sub SetSessionKey ($$) {
	my ($login,$key)=@_;
	my $tname=GetTableName('auth');
	DBQuery("UPDATE $tname SET scookie=?, authtime=NOW() WHERE login=?",$key,$login);
}


sub CheckOTKey ($$) {
	my ($login,$key)=@_;
	my $taname=GetTableName('auth');
	my $r2=$key?DBSelect("SELECT id,flag,objid,scookie FROM $taname WHERE login=? AND otkey=?",$login,$key):undef;
	if ($r2 && $r2->[0]->{id} && ($r2->[0]->{flag} & 1)) {
		my $scookie=int(rand(1000000000));
		DBQuery("UPDATE $taname SET otkey='', scookie=?, authtime=NOW() WHERE id=?",$scookie,$r2->[0]->{id});
		$cmlcalc::COOKIE->{'__CJ_auth'}=encode_json({login=>$login,scookie=>$scookie});
		$cmlcalc::ENV->{'LOGIN'}=$login;
		$cmlcalc::ENV->{'AUTHUSERID'}=$r2->[0]->{objid};
		return $r2->[0]->{objid};
	}
	undef $cmlcalc::ENV->{'LOGIN'};
	undef $cmlcalc::ENV->{'AUTHUSERID'};		
	return undef;
}

sub CheckSessionKey ($$) {
	my ($login,$key)=@_;
	my $taname=GetTableName('auth');
	my $r2=DBSelect("SELECT objid FROM $taname WHERE login=? and scookie=? and flag&1",$login,$key);
	if ($r2 && $r2->[0]->{objid}) {
		return $r2->[0]->{objid};
	}
	return undef;
}

sub CheckUser ($) {
	my ($login)=@_;
	my $taname=GetTableName('auth');
	my $r2=DBSelect("SELECT objid FROM $taname WHERE login=?",$login);
	return  ($r2 && $r2->[0]->{objid})?$r2->[0]->{objid}:0;
}

sub AddUser ($$;$) {
	my ($objid,$login,$password)=@_;
	my $uid;
	if ($password) {
		$uid=&cmlmain::add_user($login,$password,$objid);
	} else {
		$uid=&cmlmain::add_external_user($login,$objid);
	}
	return $uid;
}


sub ActivateUser ($) {
	my ($objid)=@_;
	my $taname=GetTableName('auth');
	DBQuery("UPDATE $taname SET flag=flag|1 where objid=?",$objid);
}	


sub GetLoginByObjID ($) {
	my ($objid)=@_;
	my $taname=GetTableName('auth');
	my $r=DBSelect("SELECT login FROM $taname WHERE objid=?",$objid);
	return $r?$r->[0]->{login}:undef;
}

sub BackupDB() {
	cmlmain::backup_dir_create();
	my $str=vCMS::Proxy::ExportDBStr();
	my $backupname=vCMS::Proxy::GetGlobal('WWWPATH').'/backup/db'.strftime ('%Y%m%d_%H%M',localtime()).'.gz';
	system("$str | gzip -c >$backupname");
	return $backupname;
}	


1;