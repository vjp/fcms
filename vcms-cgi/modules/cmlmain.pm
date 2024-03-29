package cmlmain;


BEGIN
{
 use Exporter();
 use Data::Dumper;
 use DBI;
 use cmlcalc;
 use cmlparse;
 use cmlinstall;
 use Time::Local;
 use Time::HiRes qw (time);
 use JSON::PP;
 use MIME::Base64;
 use File::Copy; 
 use Encode;
 use Net::IDN::Punycode::PP qw(:all);
 use URI::Escape;
 use Cache::Memcached;
 use POSIX qw(locale_h strftime);
 use String::CRC::Cksum qw(cksum);
 use Lingua::EN::Numbers qw(num2en);
 use Lingua::RU::Number qw(num2words);



  
 @ISA    = 'Exporter';
 @EXPORT = qw(
              $lobj $nlobj $obj  $vobj $nobj $kobj $tobj $tree $ltree $prm  $method $lmethod %ptype @ptypes $dbh

              &checkload	&defaultvalue	&uparamlist &lparamlist
              
              &edit		&editlow	&update
              
              &returnvalue    &init
              &addobject	&addlowobject	&deleteobject   &deletelowobject &deletealllowobjects
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
              
              &alert &message &redir &viewlog
              
              &fastsearch &isupper &iscompiled &fsindexcreate
              
              $GLOBAL @LANGS %LANGS @SYNC %SYNC
              
              @LOG 
              
              &checkdatastruct &deletelowlist &sync &remote_sync
              
              &prminfo &enc &encu
              
              &get_sec_id &check_sec_id &get_sec_key &check_captcha
              
              &add_user &check_user &del_user &activate_user &check_auth &change_pass_user &check_password
              &deactivate_user &update_login &reset_user
              &add_external_user &check_external_auth
              
              &check_session &end_session &email 
              
              &statclick &staterror &copylinkfile
              
              &ajax_ok &ajax_error &rf_name &rf_enc_name &snapshot
              
              &import_db &import_static &export_db &recover_object &export_static &export_db_str &import_db_str 
              &restore_db &export_history &backup_db &export_static_str
              
              &compile_date  &set_hru &json_ok &json_error &clear_unused_data &tcalc  &stat_injection
             );

   @ptypes=( 'TEXT', 'NUMBER', 'LONGTEXT', 'FLAG', 'DATE', 'LIST', 'MATRIX' , 'PICTURE', 'FILE', 'FILELINK', 'VIDEO', 'AUDIO'  );
   
   $GLOBAL->{tm} = {
   		ic=>['ic','icc','tagparse cml:<prm>'],
   		tp=>['tp','tpc','tagparse all inlines'],
   		et=>['et','etc','method execute'],
   		cl=>['cl','clc','checkload'],
   }
}




sub tcalc ($$) {
	my ($tkey,$timestart)=@_;
	
	my $t=time()-$timestart;
   	$cmlmain::GLOBAL->{timers}->{$cmlmain::GLOBAL->{tm}->{$tkey}->[0]}+=$t;
	$cmlmain::GLOBAL->{timers}->{$cmlmain::GLOBAL->{tm}->{$tkey}->[1]}++;
		
}


sub set_hru ($$)
{
	my ($hrukey,$redirectvalue)=@_;
	$hrukey=~s/^\///;
	$hrukey=~s/\/$//;
	$hrukey=~s/ //g;
	return unless $hrukey;
	open (FC, "<$GLOBAL->{WWWPATH}/.htaccess");
	read (FC,$fcontent,-s FC);
	close(FC); 
	

   ### RewriteRule ^news(/|/page/.*)?$ /_INFO/19795$1

	$fcontent=~s{(### VCMS START ###)(\n?.*?)(\n### VCMS END ###)}{
   		my $start=$1;
   		$start="$start\n" unless $2;
   		my @dyn=split(/\n/,$2);
   		my $end=$3;
   		my @rdyn;
   		for (@dyn) {
   			next if /RewriteRule (\S+?) $redirectvalue\s*/;
   			next if /RewriteRule \^${hrukey}\(\/\|\/page\/\.\*\)\?\$ (\S+)/;
   			push (@rdyn,$_);
   		}	 
   		push (@rdyn,"RewriteRule ^${hrukey}\(\/\|\/page\/\.\*\)\?\$ ${redirectvalue}\$1");
   		$start.join ("\n",@rdyn).$end;
	}es;
	open (FC, ">$GLOBAL->{WWWPATH}/.htaccess");
	print FC $fcontent;
	close(FC);	
	return $hrukey;
	
}
sub import_db_str ()
{
	my $hoststr=$GLOBAL->{DBHOST}=~/(.+):(\d+)/?"-h$1 -P$2":"-h".$GLOBAL->{DBHOST};
	return "mysql -f $hoststr -u$GLOBAL->{DBUSER} -p$GLOBAL->{DBPASSWORD} $GLOBAL->{DBNAME}";
}

sub restore_db ($) {
	my ($filename)=@_;
	import_db("$GLOBAL->{WWWPATH}/backup/$filename");
}


sub import_db (;$)
{
	my ($filename)=@_;
	$filename ||= 'db.gz';
	$istr=import_db_str();
	return ("error: no exportfile $filename") unless -s $filename; 
	my $str="gzip -d -c $filename | $istr";
	my $output=`$str`;
	return("$str - $output");
}

sub import_static (;$)
{
	my ($filename)=@_;
	$filename ||= 'docs.tar.gz';
    my $str="tar -xzf $filename -C $GLOBAL->{WWWPATH}";
	my $output=`$str`;
	return("$str - $output");
    
}
sub backup_dir_create ()
{
	my $dir="$GLOBAL->{WWWPATH}/backup/";	
	mkdir $dir unless -d $dir;
	return "cant create dir $dir" unless -d $dir; 
	createhtaccess ("$GLOBAL->{WWWPATH}/backup/.htaccess",'admin') unless -s  "$GLOBAL->{WWWPATH}/backup/.htaccess";
	return 1;
}

sub export_db_str (;$) {
    my ($opts)=@_;
    #optimization keys -Q --max_allowed_packet=16777216
    my $cache=$opts->{cache}?'':"--ignore-table=$GLOBAL->{DBNAME}.${DBPREFIX}pagescache --ignore-table=$GLOBAL->{DBNAME}.${DBPREFIX}linkscache";
    my $cset=$opts->{charset}?"--default-character-set=$opts->{charset}":'';
    my $estr="mysqldump -q -u$GLOBAL->{DBUSER} -p$GLOBAL->{DBPASSWORD} -h$GLOBAL->{DBHOST} $GLOBAL->{DBNAME} --ignore-table=$GLOBAL->{DBNAME}.${DBPREFIX}vlshist  $cache $cset";
    my $str=-e '/usr/local/bin/mysqldump'?"/usr/local/bin/$estr":$estr;
    return $str;		
}

sub export_history_str () 
{
	my $estr="mysqldump -q -u$GLOBAL->{DBUSER} -p$GLOBAL->{DBPASSWORD} -h$GLOBAL->{DBHOST} $GLOBAL->{DBNAME} ${DBPREFIX}vlshist";
	my $str=-e '/usr/local/bin/mysqldump'?"/usr/local/bin/$estr":$estr;
	return $str;		
}



sub export_history (;$)
{
	my ($filename)=@_;
	unless ($filename) {
		backup_dir_create();
		$filename = "$GLOBAL->{WWWPATH}/backup/history.gz";
	}
	$str=export_history_str();
	my $output=`$str | gzip -c >$filename`;
	return("$str - $output");
}

sub backup_db (;$$) {
	export_db(@_);
}

sub export_db (;$$)
{
	my ($filename,$opts)=@_;
	unless ($filename) {
		backup_dir_create();
		my $tm=strftime ('%Y%m%d_%H%M',localtime());
		$filename = "$GLOBAL->{WWWPATH}/backup/db${tm}.gz";
	}
	$str=export_db_str($opts);
	my $output=`$str | gzip -c >$filename`;
	return("$str ($filename) : $output");
}

sub export_static_str ($) 
{
	my ($filename)=@_;
	return "tar -cz -C $GLOBAL->{WWWPATH} --exclude='data/*' -f $filename --exclude='userdata/*' --exclude='backup/*' --exclude='.htaccess'  --exclude='cgi-bin/*' ."
}


sub export_static (;$)
{
	my ($filename)=@_;
	unless ($filename) {
		backup_dir_create();		
		$filename = "$GLOBAL->{WWWPATH}/backup/docs.tar.gz";
	}
	my $str=export_static_str($filename);
	my $output=`$str -f $filename`;
	return("$str - $output");
}

sub rf_enc_name ($)
{
	 return $_[0] if $_[0]!~/\.рф/i;
	 return join('.',map {'xn--'.encode_punycode(Encode::decode('cp1251',$_))} split(/\./,$_[0])); 
}


sub rf_name ()
{
	  my $servername=$ENV{'SERVER_NAME'};
  	  $servername=~s/xn--(\w+)/Encode::encode('cp1251',decode_punycode($1))/ige;
      return $servername;
}


sub ajax_ok(;$$) 
{
	my ($message,$data)=@_;
	$data->{'status'}=1;
	$data->{'message'}=$message || encu('Успешно');	
	$data->{'back'} ||=$CGIPARAM->{back};
	$data->{'elapsed'} ||=$CGIPARAM->{elapsed};
	
	$cmlcalc::ENV->{'LASTMESSAGE'}=$data->{'message'};
	return $data
}

sub ajax_error($) 
{
	my ($errormessage)=@_;
	$cmlcalc::ENV->{'LASTERROR'}=$errormessage;
	return {
		'status'=>0,
		'message'=>encu("Ошибка: ").$errormessage,	
	}
}


sub json_ok(;$$) 
{
	my ($message,$result)=@_;
	$cmlcalc::ENV->{'JSON'}=1;
	my $r={
		'status'=>1,
		'message'=>$message || 'SUCCESS',
	};
	$r->{result}=$result if $result;	
	return $GLOBAL->{CODEPAGE} eq 'utf-8'?JSON::PP->new->utf8(0)->encode($r):JSON::PP->new->latin1->encode($r);
}

sub json_error(;$$) 
{
	my ($message,$result)=@_;
	$cmlcalc::ENV->{'JSON'}=1;
	my $r={
		'status'=>0,
		'message'=>$message || 'ERROR',
	};
	$r->{result}=$result if $result;
	return $GLOBAL->{CODEPAGE} eq 'utf-8'?JSON::PP->new->utf8(0)->encode($r):JSON::PP->new->latin1->encode($r);
}




sub staterror ($;$$$)
{
	my ($message,$url,$ua,$key)=@_;
	$key ||= 'ERRORS';
	$url ||= $ENV{REQUEST_URI};
	$ua  ||= $ENV{HTTP_USER_AGENT};
	if (cmlcalc::id($key)) {
		return &cmlcalc::add (&cmlcalc::id($key),{
			_NAME=>scalar(localtime()).' - '.$url,
			ERRORURL=>$url,
			ERRORUA=>$ua,
			ERRORIP=>$ENV{REMOTE_ADDR},
			ERRORTIME=>&cmlcalc::now(),
			ERRORENV=>Dumper(\%ENV),
			ERRORMESSAGE=>$message,
			ERRORPAGE=>$ENV{HTTP_REFERER},
		},{nohistory=>1});
	}	
}


sub statclick ($;$$)
{
	my ($clid,$clobjid,$clurl)=@_;
	my $url=$clurl || $ENV{REQUEST_URI};
	$url=~s/_cl=\d+&?//;
	$url=~s/_clobjid=\d+&?//;
	$url=~s/\?$//;
	return &cmlcalc::add (&cmlcalc::id(CLICKS),{
			_NAME=>scalar(localtime()).' - '.$url,
			CLURL=>$url,
			CLIP=>$ENV{REMOTE_ADDR},
			CLTIME=>&cmlcalc::now(),
			CLLINK=>$clid,
			GEODATA=>CGI::cookie('_cn').' '.CGI::cookie('_cc'),
			CLOBJLINK=>$clobjid,
	});

}

sub change_pass_user ($$) 
{
	my ($password,$objid)=@_;
	my $sth1=$dbh->prepare("UPDATE  ${DBPREFIX}auth SET pwd=old_password(?), flag=flag|1, scookie=''  WHERE objid=?");
	$sth1->execute($password,$objid) || die $dbh->errstr();
	return 1;
}	



sub add_user ($$;$) 
{
	my ($login,$password,$objid)=@_;
	$objid ||= &cmlcalc::id("SU_$login");
	return 0 unless $objid;
	my $sth1=$dbh->prepare("INSERT ${DBPREFIX}auth (login,pwd,objid) VALUES (?,old_password(?),?)");
	$sth1->execute($login,$password,$objid) || die $dbh->errstr();
	return $objid;
}	

sub add_external_user ($$) 
{
	my ($login,$objid)=@_;
	return 0 unless $objid;
	my $sth1=$dbh->prepare("INSERT ${DBPREFIX}auth (login,pwd,objid) VALUES (?,'___EXTERNAL___',?)");
	$sth1->execute($login,$objid) || die $dbh->errstr();
	return $objid;
}	



sub reset_user ($$$;$)
{
	my ($objid,$loginprm,$password,$activate)=@_;
	return unless $password;
	my $login=&cmlcalc::p($loginprm,$objid);
	my $flag=$activate?1:0;
	return unless $login;
	my $sth1=$dbh->prepare("REPLACE ${DBPREFIX}auth (login,pwd,objid,flag) VALUES (?,old_password(?),?,?)");
	$sth1->execute($login,$password,$objid,$flag) || die $dbh->errstr();
	return $objid;
}

sub update_login ($$) 
{
	my ($objid,$login)=@_;
	my $sth1=$dbh->prepare("UPDATE ${DBPREFIX}auth SET login=? where objid=?");
	$sth1->execute($login,$objid) || die $dbh->errstr();
	
}

sub activate_user ($) 
{
	my ($objid)=@_;
	my $sth1=$dbh->prepare("UPDATE ${DBPREFIX}auth SET flag=flag|1 where objid=?");
	$sth1->execute($objid) || die $dbh->errstr();
}	

sub deactivate_user ($) 
{
	my ($objid)=@_;
	my $sth1=$dbh->prepare("UPDATE ${DBPREFIX}auth SET flag=flag&~1 where objid=?");
	$sth1->execute($objid) || die $dbh->errstr();
}	


sub del_user ($) 
{
	my ($login)=@_;
	my $sth1=$dbh->prepare("DELETE FROM ${DBPREFIX}auth where login=?");
	$sth1->execute($login) || die $dbh->errstr();
}	



sub check_user ($;$) 
{
	my ($login,$opts)=@_;
	my $q="SELECT objid FROM ${DBPREFIX}auth WHERE login=?";
	$q.="  AND flag&1" unless $opts->{all};
	my $sth2=$dbh->prepare($q);
	$sth2->execute($login) || die $dbh->errstr();
	my ($objid)=$sth2->fetchrow();
	return $objid;
}	

sub check_auth ($$;$$)
{
	my ($login,$password,$multisession,$opts)=@_;
	my $sth1=$dbh->prepare("SELECT id,flag,objid,scookie FROM ${DBPREFIX}auth WHERE login=? and pwd=old_password(?)");
	$sth1->execute($login,$password) || die $dbh->errstr();
	my ($sid,$flag,$objid,$scookie)=$sth1->fetchrow();
	if ($sid && ($flag & 1)) {
		if (!$scookie || !$multisession) {
			$scookie=int(rand(1000000000));
			my $sth2=$dbh->prepare("UPDATE ${DBPREFIX}auth SET scookie=?, authtime=NOW() WHERE id=?");
			$sth2->execute($scookie,$sid) || die $dbh->errstr();
		}	
		$cmlcalc::COOKIE->{'__CJ_auth'}->{value}=encode_json({login=>$login,scookie=>$scookie});
		$cmlcalc::COOKIE->{'__CJ_auth'}->{expires}=$opts->{expires} if $opts->{expires};

		$cmlcalc::ENV->{'LOGIN'}=$login;
		$cmlcalc::ENV->{'AUTHUSERID'}=$objid;
		return (1,$scookie);
	} elsif ($sid && ! ($flag & 1)) {
		undef $cmlcalc::ENV->{'LOGIN'};
		undef $cmlcalc::ENV->{'AUTHUSERID'};		
		return (0,1); 	
	} else {
		undef $cmlcalc::ENV->{'LOGIN'};
		undef $cmlcalc::ENV->{'AUTHUSERID'};		
		return (0,0);
	}
	
}

sub check_external_auth ($;$)
{
	my ($login,$opts)=@_;
	my $multisession;
	if (ref $opts eq 'HASH') {
		$multisession=$opts->{multisession};
	} else {
		$multisession=$opts;
		undef $opts;
	}
	
	my $sth1=$dbh->prepare("SELECT id,flag,objid,scookie FROM ${DBPREFIX}auth WHERE login=? and pwd='___EXTERNAL___'");
	$sth1->execute($login) || die $dbh->errstr();
	my ($sid,$flag,$objid,$scookie)=$sth1->fetchrow();
	if ($sid && ($flag & 1)) {
		if (!$scookie || !$multisession) {
			$scookie=int(rand(1000000000));
			my $sth2=$dbh->prepare("UPDATE ${DBPREFIX}auth SET scookie=?, authtime=NOW() WHERE id=?");
			$sth2->execute($scookie,$sid) || die $dbh->errstr();
		}	
		$cmlcalc::COOKIE->{'__CJ_auth'}->{value}=encode_json({login=>$login,scookie=>$scookie});
		$cmlcalc::COOKIE->{'__CJ_auth'}->{expires}=$opts->{expires} if $opts->{expires};
		$cmlcalc::ENV->{'LOGIN'}=$login;
		$cmlcalc::ENV->{'AUTHUSERID'}=$objid;
		return (1,$scookie);
	} elsif ($sid && ! ($flag & 1)) {
		undef $cmlcalc::ENV->{'LOGIN'};
		undef $cmlcalc::ENV->{'AUTHUSERID'};		
		return (0,1); 	
	} else {
		undef $cmlcalc::ENV->{'LOGIN'};
		undef $cmlcalc::ENV->{'AUTHUSERID'};		
		return (0,0);
	}
	
}



sub check_password ($;$)
{
	my ($password,$objid)=@_;
	$objid ||= $cmlcalc::ENV->{'AUTHUSERID'};
	return (0,0) unless $objid;
	my $sth1=$dbh->prepare("SELECT id,flag FROM ${DBPREFIX}auth WHERE objid=? and pwd=old_password(?)");
	$sth1->execute($objid,$password);
	my ($sid,$flag)=$sth1->fetchrow();
	if ($sid && ($flag & 1)) {
		return (1,0);
	}		
	return (0,1);
	
}

sub check_session ()
{ 
	return 0 unless CGI::cookie('__CJ_auth'); 
	my $auth_data;
	eval {
		$auth_data=decode_json(CGI::cookie('__CJ_auth'));
	};
	return 0 if $@;	
	my $sth1=$dbh->prepare("SELECT objid FROM ${DBPREFIX}auth WHERE login=? and scookie=? and flag&1");	
	$sth1->execute($auth_data->{'login'},$auth_data->{'scookie'}) || die $dbh->errstr();
	my ($sid)=$sth1->fetchrow();
	if ($sid) {
		$cmlcalc::ENV->{'LOGIN'}=$auth_data->{'login'};
		$cmlcalc::ENV->{'AUTHUSERID'}=$sid;
		return 1;
	} else {
		return 0;
	}	
}


sub end_session ()
{ 
	return 0 unless CGI::cookie('__CJ_auth'); 
	my $auth_data=decode_json(CGI::cookie('__CJ_auth'));
	my $sth1=$dbh->prepare("UPDATE ${DBPREFIX}auth SET scookie=NULL,authtime=NULL WHERE scookie=?");	
	$sth1->execute($auth_data->{'scookie'}) || die $dbh->errstr();
	return 1;
}



sub get_sec_id {
	my $ckey=int(rand(100000));
	my $sth1=$dbh->prepare("INSERT ${DBPREFIX}captcha (ckey) VALUES (?)");
	$sth1->execute($ckey) || die $dbh->errstr();
	my $sth2=$dbh->prepare("SELECT id FROM ${DBPREFIX}captcha WHERE ckey=?");
	$sth2->execute($ckey) || die $dbh->errstr();
	my ($sid)=$sth2->fetchrow();
	return $sid;
}	

sub check_captcha {
	return check_sec_id($cmlcalc::CGIPARAM->{'sec_id'},$cmlcalc::CGIPARAM->{'sec_key'})
}

sub check_sec_id {
	my ($id,$ckey)=@_;
	my $sth1=$dbh->prepare("SELECT tm>NOW()-INTERVAL 5 MINUTE FROM ${DBPREFIX}captcha WHERE id=? AND ckey=?");
	$sth1->execute($id,$ckey) || die $dbh->errstr();
	my ($sid)=$sth1->fetchrow();
	my $sth2=$dbh->prepare("DELETE FROM ${DBPREFIX}captcha WHERE id=? OR tm<NOW()-INTERVAL 15 MINUTE");
	$sth2->execute($id) || die $dbh->errstr();
	return $sid;
}

sub get_sec_key {
	my ($id)=@_;
	my $sth1=$dbh->prepare("SELECT ckey FROM ${DBPREFIX}captcha WHERE id=?");
	$sth1->execute($id) || die $dbh->errstr();
	my ($ckey)=$sth1->fetchrow();
	return $ckey;
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
	my $sthS=$dbh->prepare("REPLACE ${DBPREFIX}vls (objid,pkey,upobj,value) SELECT $to->{ind},pkey,upobj,value FROM ${DBPREFIX}vls WHERE objid=? AND pkey!='_NAME'");
	$sthS->execute($from->{ind}) || die $dbh->errstr;
}	
	
sub copyuvals {
	my $from=$_[0]->{from};
	my $to=$_[0]->{to};
	my $sthS=$dbh->prepare("REPLACE ${DBPREFIX}uvls (objid,pkey,value) SELECT $to->{ind},pkey,value FROM ${DBPREFIX}uvls WHERE objid=? AND pkey!='_NAME'");
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
	undef $cmlcalc::CGIPARAM;
	
	undef $lobj;
	undef $obj;
	undef $ltree;
	
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
  fsindexcreate($pkey) if ($_[0]->{extra} eq 'srch') && ($_[0]->{value} eq 'y') && ($prm->{$_[0]->{pkey}}->{extra}->{$_[0]->{extra}} ne 'y');
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




sub dbconnect	{
	$dbh=DBI->connect("DBI:mysql:$_[0]->{dbname}:$_[0]->{dbhost}",$_[0]->{dbuser},$_[0]->{dbpassword}) || die $DBI::errstr;
 	$dbh->{mysql_auto_reconnect} = 1;
}



sub update {
	if ($_[0]->{id}=~/u\d+/) {edit($_[0])} else {editlow($_[0])}
	
}	


sub edit {
	my $id=$_[0]->{id};
	my $nolog=$_[0]->{nolog};
	if ($id=~/u(\d+)/) {$id=$1}
	
	
	
	my $sthU=$dbh->prepare("UPDATE ${DBPREFIX}tree SET keyname=?, template=? ,ltemplate=?, indx=?,lang=?,nolog=?,up=? WHERE id=?");
	
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
	if (defined $_[0]->{up})        {$obj->{$id}->{up}=$_[0]->{up}}
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
 	   $obj->{$id}->{up},
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

	
	

	
	
	if (defined $_[0]->{key})       {
		$lobj->{$objid}->{key}=$_[0]->{key};
		$nobj->{$_[0]->{key}}=$lobj->{$objid};
	}
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
	my $ts=time();

	if ($objid->{type}) {
		if    ($objid->{type} eq 'U') {$ind='u'.$objid->{ind}}
		elsif ($objid->{type} eq 'L') {$ind=$objid->{ind}} 
		elsif ($objid->{type} eq 'T') {$ind='test'}
	} else  {$ind=$objid}

	$sthVL->execute($ind,$pkey) || die $dbh->errstr;
	my @rlist=();

	while (my $item=$sthVL->fetchrow_hashref) {
		if (($upper eq "u$item->{upobj}") || !$upper) {
			push(@rlist,$item->{objid})
		}	
	}	
	my $v;
	
	if ($condition) {
		 @rlist=grep(&cmlcalc::calc($_,$condition),@rlist);
  	}	
	
	$v->{value}=join(';',@rlist);
	$v->{type}='LIST';
	
	my $t=time()-$ts;
    $GLOBAL->{timers}->{br}+=$t;
    $GLOBAL->{timers}->{brc}++;
	
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
	
	my $ts=time();
	
	if ($objid->{type}) {
		if    ($objid->{type} eq 'U') {$ind='u'.$objid->{ind}}
		elsif ($objid->{type} eq 'L') {$ind=$objid->{ind}} 
		elsif ($objid->{type} eq 'T') {$ind='test'}
	} else  {$ind=$objid}

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
	
	my $t=time()-$ts;
    $GLOBAL->{timers}->{br}+=$t;
    $GLOBAL->{timers}->{brc}++;
  
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
	my $sth=$dbh->prepare("SELECT * FROM ${DBPREFIX}vls WHERE objid in ($vstr)")|| die $dbh->errstr;

	
	$sth->execute() || die $dbh->errstr;
	while (my $item=$sth->fetchrow_hashref) {
     	if ($prm->{$item->{pkey}}->{type} eq 'TEXT' || $prm->{$item->{pkey}}->{type} eq 'LONGTEXT') { 
        		$lobj->{$item->{objid}}->{langvals}->{$item->{lang}}->{$item->{pkey}}->{value}=$item->{value};
        } else {
        	  $lobj->{$item->{objid}}->{$item->{pkey}}->{value}=$item->{value};
        }			
        $lobj->{$item->{objid}}->{vals}->{$item->{pkey}}->{type}=$prm->{$item->{pkey}}->{type};
        $lobj->{$item->{objid}}->{langcached}->{$item->{lang}}=1;
	}	
	my $xt=time()-$t;

}

sub returnvalue {
 	my $objid=$_[0]->{id};
 	my $pkey=$_[0]->{pkey};
 	my $noparse=$_[0]->{noparse};
 	my $lang='';
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
   			my $h;
   			if ($GLOBAL->{USEMEMCACHED}) {
   				my $ts=time();
   				my $mcv=$GLOBAL->{MEMD}->get($objid);
   				if ($mcv) {
   					eval{
   						$h=decode_json($mcv)
   					};
   					my $t=time()-$ts;
   					$GLOBAL->{mt}+=$t;
   					$GLOBAL->{mtc}++;
   				}	 
   			}	
   			unless ($h) {
   				my $ts=time();
		  		$LsthV->execute($objid,$lang) || die $dbh->errstr;
		  		while (my $item=$LsthV->fetchrow_hashref) {
		  			$h->{$item->{pkey}}=$item->{value};
		  		}
     			if ($GLOBAL->{USEMEMCACHED} && $h) {
        			$GLOBAL->{MEMD}->set($objid,encode_json($h));
        		}
        		my $t=time()-$ts;
        		$GLOBAL->{ot}+=$t;
        		$GLOBAL->{otc}++;
   			}
   			for my $hpkey (keys %$h) {	
     			my $type=$prm->{$hpkey}->{type} || '';
     			if ($type eq 'TEXT' || $type eq 'LONGTEXT') { 
        			$lobj->{$objid}->{langvals}->{$lang}->{$hpkey}->{value}=$h->{$hpkey};
        		} else {
        		  	$lobj->{$objid}->{$hpkey}->{value}=$h->{$hpkey};
          		}			
        		$lobj->{$objid}->{vals}->{$hpkey}->{type}=$type;
        		if ($noparse && $pkey eq $hpkey) {$npv->{value}=$h->{$hpkey}; $npv->{type}=$type}
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
   	  my $ts=time();
      $sthUV->execute($objid) || die $dbh->errstr;
      while ($item=$sthUV->fetchrow_hashref) {
      	my $oupd=$prm->{$item->{pkey}}->{upd}->{$objid} || '';
      	my $otmp=$prm->{$item->{pkey}}->{upd}->{$tmp}   || '';
      	unless (($oupd eq 'n') || ($otmp eq 'n') ) {  
         	$obj->{$objid}->{vals}->{$item->{pkey}}->{value}=$item->{value};
         	$obj->{$objid}->{vals}->{$item->{pkey}}->{type}=$prm->{$item->{pkey}}->{type};
        }	
      }
      $obj->{$objid}->{cached}=1;
      my $t=time()-$ts;
      $GLOBAL->{ot}+=$t;
      $GLOBAL->{otc}++;
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

sub clearpagescache ($) {
	my ($obj)=@_;
	
	unless ($GLOBAL->{CACHE}) {
		warn "skip clear cache - cache switch off";
		return;
	}
	
	my $tt=time;
    my $sth=$dbh->prepare("SELECT cachekey FROM ${DBPREFIX}linkscache WHERE objlink=?") || die $dbh->errstr();
    $sth->execute($obj) || die $dbh->errstr();
    my @h;
	while (my ($key)=$sth->fetchrow()) {
		push(@h,"'$key'");
	}
	my $dstr=join(',',@h);
	my $cnt=scalar @h;
	warn sprintf "cache collecion obj=$obj cnt=$cnt time=%.3fs.",time()-$tt if $cnt;
	if ($cnt > 1000) {
		$dbh->do("DELETE FROM ${DBPREFIX}pagescache") || die $dbh->errstr();
		$dbh->do("DELETE FROM ${DBPREFIX}linkscache") || die $dbh->errstr();
	    warn sprintf "global clear time=%.3fs",time()-$tt;		
	}elsif (@h){
		unless ($dbh->do("DELETE FROM ${DBPREFIX}pagescache WHERE cachekey IN ($dstr)")) {
			warn "pagescache del problem - ".$dbh->errstr();
			$dbh->do("DELETE FROM ${DBPREFIX}pagescache") || die $dbh->errstr();
		}
		my $sthd=$dbh->prepare("DELETE FROM ${DBPREFIX}linkscache WHERE objlink=?") || die $dbh->errstr();
		$sthd->execute($obj)|| die $dbh->errstr();
	    warn sprintf "increment clear time=%.3fs.",time()-$tt;		
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
	my $remove=$_[0]->{remove};
	my $noonchange=$_[0]->{noonchange};
	my $nohistory=$_[0]->{nohistory};
	
	my $ind;
	if ($key) {
		 checkload({key=>$key});
		 $id=$nobj->{$key}->{id};
		 $ind=$nobj->{$key}->{ind};
		 return 0 unless $id;
  	}	
    $value=encu($value) if $_[0]->{convert}  && $cmlcalc::CGIPARAM->{_MODE} ne 'CONSOLE';
    undef $value if $prm->{$pkey}->{type} eq 'LIST' && $value eq '0';
    
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
 	my $old_value;
 	$old_value=&cmlcalc::p($pkey,$id) if 
 		(($append || $remove) && ($prm->{$pkey}->{type} eq 'LIST' || $prm->{$pkey}->{type} eq 'NUMBER')) || $prm->{$pkey}->{extra}->{onchange};
 		
 	
 	if (($append && $prm->{$pkey}->{type} eq 'LIST') && $old_value) {
 	    my @v=split(';',$old_value);
 	    my @av=split(';',$value);
 	    for my $add_v (@av) {
 	    	unless (grep{$_ eq $add_v}@v) {
 	    		push(@v,$add_v);
 	    	}	
 	    }	
 	    $value=join(';',@v);
	}

 	if ($append && $prm->{$pkey}->{type} eq 'NUMBER') {
 	    $value=$old_value+$value;
	}

    if (($remove && $prm->{$pkey}->{type} eq 'LIST') && $old_value) {
 	    my @v=split(';',$old_value);
 	    @v=grep{$_ ne $value} @v;
 	    $value=join(';',@v);
	}
 	
 	if ($prm->{$pkey}->{type} eq 'NUMBER' && vCMS::Config::Get('fix_decimal_splitter')) {
 		$value=~s/(\d+)\,(\d+)/$1\.$2/;
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
	}	elsif ($id && $id=~/^\d+$/)   {	
  		my $objid=$id;
		if ($pkey eq '_INDEX') {   
			update({id=>$objid , indx=>$value});
			clearpagescache($objid); 
			return 1;
		}	
		if ($pkey eq '_KEY') {   
			update({id=>$objid , key=>$value}) ; 
			clearpagescache($objid); 
			unless ($nohistory) {
				$sthH->execute("$objid",'_KEY',$value,'TEXT',$lang,$cmlcalc::ENV->{USER}) || die $dbh->errstr;
			}	
			return 1; 
		}	
		if ($pkey eq '_UP') {   
			if ($value=~/^u/) {
				update({id=>$objid , upobj=>$value}); 
				clearpagescache($objid); 
			}	
			return 1;
		}	
		checkload({id=>$objid});
		if ($pkey eq '_PRMNAME') {
			my $xk=$lobj->{$objid}->{key}; 
			$xk=~s/^_PP_//;
			updateprmname($xk,$value);
			clearpagescache($objid); 
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
 			
  		if ($GLOBAL->{USEMEMCACHED}) {
        		$GLOBAL->{MEMD}->delete($objid);
       	}

 		if (defined $value && ($value ne '')) {
 			my $l=length $value;
 			warn "try save large value: $l" if $l>1000000;
 			$sthI->execute($objid,$pkey,$value,$lobj->{$objid}->{upobj},$cl) || die $dbh->errstr;
 		} else {
 			$sthDD->execute($objid,$pkey,$cl) || die $dbh->errstr;	
 		}	
 		
 		unless ($obj->{$lobj->{$objid}->{upobj}}->{nolog}) {
 			if ($value ne '' && !$nohistory) {
 				$sthH->execute($objid,$pkey,$value,$prm->{$pkey}->{type},$cl,$cmlcalc::ENV->{USER}) || die $dbh->errstr;
 			}	
 		}	
 		
 		clearpagescache($objid); 

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
		if ($pkey eq '_UP') {   
			if ($value=~/^u(\d+)/) {
				update({id=>"u$objid" , up=>$1});
				clearpagescache("u$objid");  
			}	
			return 1;
		}	
				
		my $cl;
	 	
	 	if    ($_[0]->{lang})      {$cl=$_[0]->{lang}} 
  		elsif ($LANGUAGE) {
  			$cl=$LANGUAGE;
  			$obj->{$objid}->{vals}->{$pkey}->{value}=$value;
  		}	else  {$cl=$LANGS[0]}
  		$sthUDD->execute($objid,$pkey,$cl) || die $dbh->errstr;	
  		$sthUI->execute($objid,$pkey,$value,$cl) || die $dbh->errstr;
  		if ($value ne '' && !$nohistory) {
  			$sthH->execute("u$objid",$pkey,$value,$prm->{$pkey}->{type},$cl,$cmlcalc::ENV->{USER}) || die $dbh->errstr;
  		}		
  		clearpagescache("u$objid");
  		

		$obj->{$objid}->{vals}->{$pkey}->{"value_$cl"}=$value;
		if ($cl eq $LANGS[0] || $cl eq $lobj->{$objid}->{lang}) {
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
 		if ($append) {
 			my @oldvalue=split()
 		}
 		$sthDL->execute($ind,$pkey) || die $dbh->errstr;
 		for my $li (split(/\s*;\s*/,$value)) {
 			$sthIL->execute($ind,$pkey,$li) || die $dbh->errstr;
 			clearpagescache($li);
 			if ($lobj->{$li}) {
 				my $upobj=$lobj->{$li}->{upobj};
 				my $up=$lobj->{$li}->{up};
 				$ltree->{$upobj}->{$up}=[grep {!$li} @{$ltree->{$upobj}->{$up}}];
 				undef $lobj->{$li}  
 			}
 		}
	}

	if (($prm->{$pkey}->{extra}->{srch} && $prm->{$pkey}->{extra}->{srch} eq 'y') || $pkey eq '_NAME') {
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
				$sthIFS->execute($ind,$pkey,$cl,$value) || die "Index problem id=$ind pkey=$pkey - ".$dbh->errstr;
			} else {
				$sthDFS->execute($ind,$pkey) || die $dbh->errstr;	
			}	
		}
	} 
  	if ($prm->{$pkey}->{extra}->{onchange} && !$noonchange && ($value ne $old_value)) {
  		if ($id) {$OBJECT=$obj->{$id}}
  	 	if ($uid) {$OBJECT=$lobj->{$uid}}
  	 	cmlcalc::execute({lmethod=>$prm->{$pkey}->{extra}->{onchange},id=>$id});
	}	
	return 1;
}

sub checkdatastruct {
	my $sth =$dbh->prepare("SELECT count(*) FROM ${DBPREFIX}tree") || die $dbh->errstr;
	$sth->execute() || die $dbh->errstr();
	my ($r)=$sth->fetchrow;
	
}

sub init	{
	my $cf=($ENV{CGIPATH} || $_[0])."/conf";
	die "no conf file $cf" unless -s "$cf";
 	do "$cf";
    $GLOBAL->{CONF}=$CONF;
  	$GLOBAL->{CODEPAGE}=$UTF?'utf-8':'windows-1251';
  	$GLOBAL->{ENCODING}=$UTF?'utf8':'cp1251';
  	setlocale(LC_ALL, $UTF?"en_US.UTF-8":"ru_RU.CP1251");
  	setlocale(LC_NUMERIC,"C"); 
 	$DBHOST='localhost' unless $DBHOST;
 	$DBPREFIX=$DBPREFIX?"${DBPREFIX}_":'';
  
 	dbconnect({dbname=>$DBNAME,dbuser=>$DBUSER,dbpassword=>$DBPASSWORD,dbhost=>$DBHOST});
 	$dbh->do("SET NAMES $GLOBAL->{ENCODING}") if vCMS::Config::Get('forcenames');
 	#$dbh->do("SET NAMES $GLOBAL->{ENCODING}");
 	$sthDD=$dbh->prepare("DELETE FROM ${DBPREFIX}vls WHERE objid=? AND pkey=? AND lang=?");
 	$sthUDD=$dbh->prepare("DELETE FROM ${DBPREFIX}uvls WHERE objid=? AND pkey=? AND lang=?");
 	$sthI =$dbh->prepare("REPLACE ${DBPREFIX}vls (objid,pkey,value,upobj,lang) VALUES (?,?,?,?,?)") || die $dbh->errstr;
 	

 	
 	$sthH =$dbh->prepare("INSERT INTO ${DBPREFIX}vlshist (objid,pkey,value,ptype,dt,lang,user) VALUES (?,?,?,?,NOW(),?,?) ") || die $dbh->errstr;
 
 
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

 
 	$LANGS{mul}=encu('Мультиязычный');

 
 	$sthTV=$dbh->prepare("SELECT * FROM ${DBPREFIX}tvls WHERE id=? AND ptkey=?") || die $dbh->errstr;
 	$sthTI=$dbh->prepare("REPLACE ${DBPREFIX}tvls (id,ptkey,vkey,pkey,value) VALUES (?,?,?,?,?)") || die $dbh->errstr;
 
 	$sthDL=$dbh->prepare("DELETE FROM ${DBPREFIX}links WHERE objid=? AND pkey=?") || die $dbh->errstr;
 	$sthIL=$dbh->prepare("REPLACE INTO ${DBPREFIX}links (objid,pkey,vallink) VALUES (?,?,?)") || die $dbh->errstr;
 
 	$sthUVL=$dbh->prepare("SELECT * FROM ${DBPREFIX}links WHERE vallink=? AND pkey=?") || die $dbh->errstr;
 	$sthVL=$dbh->prepare("select ${DBPREFIX}objects.id as objid,${DBPREFIX}objects.upobj from ${DBPREFIX}links,${DBPREFIX}objects where vallink=? and pkey=? and ${DBPREFIX}objects.id=${DBPREFIX}links.objid") || die $dbh->errstr; 
 
 	$sthIFS=$dbh->prepare("REPLACE ${DBPREFIX}fs (id,prm,lang,val) VALUES (?,?,?,?)") || die $dbh->errstr;
 	$sthDFS=$dbh->prepare("DELETE FROM ${DBPREFIX}fs  WHERE id=? AND prm=?") || die $dbh->errstr;
 	$sthFS=$dbh->prepare("SELECT id FROM ${DBPREFIX}fs WHERE prm=? AND val=?") || die $dbh->errstr;
 
 	$sthIFS_I=$dbh->prepare("REPLACE ${DBPREFIX}fsint (id,prm,lang,val) VALUES (?,?,?,?)") || die $dbh->errstr;
 	$sthDFS_I=$dbh->prepare("DELETE FROM ${DBPREFIX}fs WHERE id=? AND prm=?") || die $dbh->errstr;
 
 
 	$sthFSL=$dbh->prepare("SELECT id FROM ${DBPREFIX}fs WHERE prm=? AND val LIKE ?") || die $dbh->errstr;
 
 	$sthSC=$dbh->prepare("SELECT pagetext,unix_timestamp(ts) FROM ${DBPREFIX}pagescache WHERE cachekey=? AND dev=? AND lang=?");
 	$sthIC=$dbh->prepare("REPLACE ${DBPREFIX}pagescache (cachekey,pagetext,ts,dev,lang) VALUES (?,?,NOW(),?,?)");
 	$sthDDC=$dbh->prepare("DELETE FROM ${DBPREFIX}pagescache WHERE cachekey=? AND dev=? AND lang=?");
 	$sthDC=$dbh->prepare("DELETE FROM ${DBPREFIX}linkscache WHERE cachekey=? AND dev=? AND lang=?");
 	
 	
 	#$sthCH=$dbh->prepare("DELETE FROM ${DBPREFIX}pagescache WHERE cachekey IN (SELECT cachekey FROM ${DBPREFIX}linkscache WHERE objlink=?)");

 	

 	
 	$GLOBAL->{FILEPATH}=$FILEPATH;
 	$GLOBAL->{WWWPATH}=$WWWPATH;
 	$GLOBAL->{CGIPATH}=$CGIPATH;
 	$GLOBAL->{FILEURL}=$FILEURL;
 	$GLOBAL->{ABSFILEURL}=$ABSFILEURL;
 	$GLOBAL->{DBNAME}=$DBNAME;
 	$GLOBAL->{DBHOST}=$DBHOST;
 	$GLOBAL->{DBPASSWORD}=$DBPASSWORD;
 	$GLOBAL->{DBUSER}=$DBUSER;

  	$GLOBAL->{SYNC}=\%SYNC;
  	$GLOBAL->{DOUBLECONFIRM}=$DOUBLECONFIRM;
  	$GLOBAL->{NEWSTYLE}=$NEWSTYLE;  	
  	$GLOBAL->{CACHE}=$CACHE;
  	$GLOBAL->{MULTIDOMAIN}=$MULTIDOMAIN;


    if ($MEMCACHEDSERVER) {
    	$GLOBAL->{USEMEMCACHED}=1;
    	$GLOBAL->{MEMD} = new Cache::Memcached {
    			'servers' => [ $MEMCACHEDSERVER ],
    			'debug' => 0,
    			'compress_threshold' => 10_000,
  		}; 
    }
 	undef @LOG;
 	undef $XCACHE;
}

sub compile_date($)
{
	my @tlist;
 	if ($_[0]->{Y}) {$tlist[5]=$_[0]->{Y}}     else {$tlist[5]=1970}
 	if ($_[0]->{m}) {$tlist[4]=$_[0]->{m}-1}   else {$tlist[4]=0}
 	if ($_[0]->{d}) {$tlist[3]=$_[0]->{d}}     else {$tlist[3]=1}
	$tlist[2]=0;
	$tlist[1]=0;
    $tlist[0]=0;
    return    timelocal(@tlist)
}


sub enc 
{
	my ($val)=@_;
	if ($GLOBAL->{CODEPAGE} eq 'utf-8') {
		$val=Encode::encode('utf-8',Encode::decode('windows-1251',$val));
	}
	return $val;
}

sub encu 
{
	my ($val)=@_;
	return $val;
}

sub clear_history  () {
  	$dbh->do("TRUNCATE TABLE ${DBPREFIX}vlshist");
	return 1;
}

sub clearcache 
{
    $dbh->do("DROP TABLE IF EXISTS ${DBPREFIX}pagescache") || die $dbh->errstr;
    $dbh->do("DROP TABLE IF EXISTS ${DBPREFIX}linkscache") || die $dbh->errstr;
    cmlinstall::create_cache_tables($dbh,$DBPREFIX);
}

sub recover_object ($$)
{
	my ($id,$up)=@_;
	my $sth=$dbh->prepare("SELECT distinct pkey FROM vlshist  WHERE objid=?");
	my $sth2=$dbh->prepare("SELECT value FROM vlshist  WHERE objid=? AND pkey=? ORDER BY dt desc LIMIT 1");
	$sth->execute($id);
	my $l;
	while (my ($pkey)=$sth->fetchrow()) {
		$sth2->execute($id,$pkey);
		my ($value)=$sth2->fetchrow();
		$l->{$pkey}=$value;
	}
	my $newid=&cmlcalc::add($up,$l); 
	return $newid;
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

sub redir {
	 my $mes;
	 $mes->{type}='redirect';
	 $mes->{message}=$_[0];
	 push (@LOG,$mes);
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
	
	if ($cmlcalc::CGIPARAM->{_MODE} eq 'CONSOLE') {
		my $logstr;
		for my $mes (@LOG) {
			if ($mes->{type} eq 'alert') {
				$logstr.="<b>$mes->{message}</b><br/>\n";
			} elsif ($mes->{type} eq 'message') {
				$logstr.="$mes->{message}<br/>\n";
			}		
		}
		return $logstr;
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
			} elsif ($mes->{type} eq 'redirect' && !$cmlcalc::CGIPARAM->{iframe}) {
				chomp $mes->{message};
				$mes->{message}=~s/\\/\\\\/gs;
				$mes->{message}=~s/'/\\'/g;
				$mes->{message}=~s/\r/ /gs; 
				$mes->{message}=~s/\n/ /gs;
				$mes->{message}=~s/"/\\"/gs;
				print "<script>location.href='$mes->{message}'</script>";
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
		$name=encu($name) if $_[0]->{convertname}  && $cmlcalc::CGIPARAM->{_MODE} ne 'CONSOLE';
	
	}
	else { $up=$_[0] }
	
	
	return 0 if !$up && !$forced;
	
	$up=~s/u(\d+)/$1/;
	
 	unless ($name) {$name=encu('Новый объект')}
 	
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


   $sthH->execute("u$newid",'_UP',$up,'NUMBER',$LANGS[0],$cmlcalc::ENV->{USER}) || die $dbh->errstr;
   if ($key) {
   		$sthH->execute("u$newid",'_KEY',$key,'TEXT',$lang,$cmlcalc::ENV->{USER}) || die $dbh->errstr;
   }	
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
	my $nohistory;

	if (ref $_[0] eq 'HASH') {
		$up=$_[0]->{up};
		$upobj=$_[0]->{upobj};
		$template=$_[0]->{template};
		$name=$_[0]->{name};
		$key=$_[0]->{key};
		$indx=$_[0]->{indx};
		$nohistory=$_[0]->{nohistory};
				
		if ($_[0]->{upobjkey}) {
				checkload({key=>$_[0]->{upobjkey}});
				$upobj=$nobj->{$_[0]->{upobjkey}}->{id};
		}		
			
		if ($_[0]->{upkey}) {
				checkload({key=>$_[0]->{upkey}});
				$upobj=$nobj->{$_[0]->{upkey}}->{id};
		}		
		$name=encu($name) if $_[0]->{convertname} && $cmlcalc::CGIPARAM->{_MODE} ne 'CONSOLE';
		
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
 	
	#unless ($name) {$name=encu('Новый объект')}
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

	clearpagescache("u$upobj"); 

 	
 	
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
	
	unless ($nohistory) {
    	$sthH->execute($newid,'_UPOBJ',$upobj,'NUMBER',$obj->{$upobj}->{lang},$cmlcalc::ENV->{USER}) || die $dbh->errstr;
    	if ($key) {
   			$sthH->execute("$newid",'_KEY',$key,'TEXT',$lang,$cmlcalc::ENV->{USER}) || die $dbh->errstr;
    	}	
	}
 	setvalue({id=>$newid,param=>'_NAME',value=>$name,nohistory=>$nohistory}) if $name ne '';
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
 clearpagescache("u$id");
 my @dellist=@{$cmlmain::ltree->{$id}->{0}};
 for (@dellist) {
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
 $sthH->execute("u$id",'_DEL',"u$obj->{$id}->{up}",'TEXT','',$cmlcalc::ENV->{USER}) || die $dbh->errstr;
 	
 

 map
 {
  deleteobject($_);
 }(@{$tree->{$id}});
}

sub deletealllowobjects
{
	my ($id)=@_;
	$id=~s/^u//;
	buildlowtree($id);
	my @dellist=@{$cmlmain::ltree->{$id}->{0}};
	for my $oid (@dellist) {
 		deletelowobject($oid);
 	}
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
 	
 	my $sthSL=$dbh->prepare("SELECT objid,pkey FROM ${DBPREFIX}links WHERE vallink=?");
  	$sthSL->execute($id) || die $dbh->errstr;
    while ($lnk=$sthSL->fetchrow_hashref) {
    	&cmlmain::setvalue({id=>$lnk->{objid},prm=>$lnk->{pkey},value=>$id,remove=>1})
    }
 	#my $sthXDL=$dbh->prepare("DELETE FROM ${DBPREFIX}links WHERE vallink=?");  $sthXDL->execute($id) || die $dbh->errstr;
 	
 	my $sthFSDL=$dbh->prepare("DELETE FROM ${DBPREFIX}fs WHERE id=?");  $sthFSDL->execute($id) || die $dbh->errstr;
 	my $sthFSIDL=$dbh->prepare("DELETE FROM ${DBPREFIX}fsint WHERE id=?");  $sthFSIDL->execute($id) || die $dbh->errstr;
 	$sthD->execute($id) || die $dbh->errstr;
 	clearpagescache($id);
 	checkload({id=>$id});
 	my $upobj=$lobj->{$id}->{upobj};
 	@{$ltree->{$upobj}->{$lobj->{$id}->{up}}}=grep{$_ ne $id}@{$ltree->{$upobj}->{$lobj->{$id}->{up}}};
 	undef $nobj->{$lobj->{$id}->{key}} if $lobj->{$id}->{key}; 
 	map {
  		deletelowobject($_);
 	}(@{$ltree->{$upobj}->{$id}});
 	if (@dlist) {deletelowobject(\@dlist)}	
 	
 	$sthH->execute("$id",'_DEL',"u$upobj",'TEXT','',$cmlcalc::ENV->{USER}) || die $dbh->errstr;
 	return 1;
}


sub buildtree
{
  my $sth=$dbh->prepare("SELECT * FROM ${DBPREFIX}tree ORDER BY id");
  $sth->execute() || die $dbh->errstr;
  undef $tree;
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
  	undef $prm;
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
  		$method->{$item->{pkey}}->{ownerid}=$item->{objid};
  		$method->{$item->{pkey}}->{type}='u';
	}
  	
  	
  	my $sth4=$dbh->prepare("SELECT * FROM ${DBPREFIX}lmethod ORDER BY id");
  	$sth4->execute() || die $dbh->errstr;
  	while ($item=$sth4->fetchrow_hashref)   {
  		$obj->{$item->{objid}}->{lmethod}->{$item->{pkey}}->{script}=$item->{script};
  		$obj->{$item->{objid}}->{lmethod}->{$item->{pkey}}->{name}=$item->{pname};
  		$lmethod->{$item->{pkey}}->{name}=$item->{pname};
  		$lmethod->{$item->{pkey}}->{script}=$item->{script};
  		$lmethod->{$item->{pkey}}->{ownerid}=$item->{objid};
  		$lmethod->{$item->{pkey}}->{type}='u';
	}
  	
  	
  	
  	$prm->{_NAME}->{type}='TEXT';
  	$prm->{_UP}->{extra}->{formula}='lowlevel(uobj(uobj()))';
  	$prm->{_UP}->{extra}->{single}='y';

  	
  	

	
}

sub addmethod {
	my $id=$_[0]->{id};
	my $name=$_[0]->{name};
	my $key=$_[0]->{key};
	my $script=$_[0]->{script};
	my $lflag=$_[0]->{lflag};
	$name=encu($name) if $_[0]->{convertname}  && $cmlcalc::CGIPARAM->{_MODE} ne 'CONSOLE';
	$script=encu($script) if $_[0]->{convertscript}  && $cmlcalc::CGIPARAM->{_MODE} ne 'CONSOLE';
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
 		$name=encu($name) if $_[0]->{convertname}  && $cmlcalc::CGIPARAM->{_MODE} ne 'CONSOLE';
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
	my $ts=time();
	my $lstr=join(',',map {"'$_'"} grep {!$lobj->{$_}->{id}} grep {/^\d+$/} split (';', $list) );
	unless ($lstr) {
		my $t=time()-$ts;
    	$GLOBAL->{timers}->{bl}+=$t;
    	$GLOBAL->{timers}->{blc}++;
    	return;
	}
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
   			$nobj->{$item->{keyname}}=$lobj->{$item->{id}} if $item->{keyname};
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
  	my $t=time()-$ts;
    $GLOBAL->{timers}->{bl}+=$t;
    $GLOBAL->{timers}->{blc}++;
  
}

sub snapshot ($)
{
	my ($id)=@_;
	my $sthN=$dbh->prepare("SELECT * FROM ${DBPREFIX}vls WHERE objid=?");
    $sthN->execute($id) || die $dbh->errstr();
    my $vhash={}; 
	while ($val=$sthN->fetchrow_hashref) {
		$vhash->{$val->{pkey}}=$val->{value};
	}
	return 0 unless scalar keys %$vhash; 	
	
	my $snapshottext=Dumper($vhash);

	my $sid=&cmlcalc::add(&cmlcalc::id('SNAPSHOTS'),
	{
		_NAME=>'Слепок объекта '.&cmlcalc::p(_NAME,$id).' от '.scalar localtime(),
		SNAPSHOT=>$snapshottext,
		SNAPSHOTOBJ=>$id,
		SNAPSHOTOBJNAME=>$vhash->{_NAME},
		SNAPSHOTTIME=>cmlcalc::now(),
		SNAPSHOTUSER=>cmlcalc::env(USERID),	
	});
	for (keys %$vhash) {
		if ($_ ne '_NAME') {
			&cmlmain::setvalue({id=>$sid,prm=>$_,value=>$vhash->{$_},noonchange=>1});
		}	
	}
	return  $sid;
}

sub buildlowtree    {

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
    my $lang=$upobj?$obj->{$upobj}->{lang}:'';
    my @idlist;	 
    while ($item=$sthL->fetchrow_hashref) {
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
            if ($item->{keyname}) {
                $nobj->{$item->{keyname}}=$lobj->{$item->{id}};
                $kobj->{$upobj}->{$item->{keyname}}=$lobj->{$item->{id}};
            }
        }
    }
    my $jstr=join(',', map {"'$_'"} @idlist); 
    my $sthN;
    my $ff=1;
    my $tt=time();
    if ($objid) {
        $sthN=$dbh->prepare("SELECT * FROM ${DBPREFIX}fs WHERE prm='_NAME' AND id=?")|| die $dbh->errstr;
        $sthN->execute("$objid") || die $dbh->errstr;
    } elsif ($jstr) {
        $sthN=$dbh->prepare("SELECT * FROM ${DBPREFIX}fs WHERE prm='_NAME' AND id in ($jstr)") || die $dbh->errstr; 
        $sthN->execute() || die $dbh->errstr;
    }   else {
        $ff=0
    }

    if($ff) {
        while ($item=$sthN->fetchrow_hashref) {
            if (  ($lang eq 'mul' && ($item->{lang} eq $LANGS[0])) || ($lang eq $item->{lang})	|| (!$item->{lang})	) {
                $lobj->{$item->{id}}->{name}=$item->{val};
            }
            $lobj->{$item->{id}}->{"name_$item->{lang}"}=$item->{val}
        }
    }
    $GLOBAL->{timers}->{ltc}++;
    $GLOBAL->{timers}->{lt}+=(time-$t);      
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
	my $upobj;
  	if ($_[0]->{tabkey})   {
  		unless ($tobj->{$_[0]->{id}}->{$_[0]->{pkey}}->{vals}->{$_[0]->{tabkey}})  {
  			buildtabtree({id=>$_[0]->{id},pkey=>$_[0]->{pkey},tabkey=>$_[0]->{tabkey}})
  		}	
  	}  elsif ($_[0]->{id})   {
   		if ($_[0]->{buildtree}) {
      		my $sthO=$dbh->prepare("SELECT upobj FROM ${DBPREFIX}objects WHERE id=?");
      		$sthO->execute($_[0]->{id}) || die $dbh->errstr;
      		$upobj=$sthO->fetchrow();
   	  		buildlowtree($upobj)
   		}   elsif (!$lobj->{$_[0]->{id}}->{id})   {
    		my $sthO=$dbh->prepare("SELECT upobj FROM ${DBPREFIX}objects WHERE id=?");
    		$sthO->execute($_[0]->{id}) || die $dbh->errstr;
    		$upobj=$sthO->fetchrow();
    		return $upobj if $_[0]->{onlyup};
    		buildlowtree($upobj,$_[0]->{id});
   		}
   		&cmlmain::tcalc('cl',$t);
   		return $lobj->{$_[0]->{id}}->{upobj};
  	} elsif ($_[0]->{key})   {
  		if ($_[0]->{key}=~/(.+)\/(.+)/) {
  			my $uid=$nobj->{$1}->{ind};
  			my $key=$2;
  			unless ($kobj->{$uid}->{$key}) {
   				my $sthK=$dbh->prepare("SELECT id FROM ${DBPREFIX}objects WHERE upobj=? AND keyname=?");
    			$sthK->execute($uid,$key) || die $dbh->errstr;
    			(my $oid)=$sthK->fetchrow();
    			buildlowtree($uid,$oid);
  			}
  			&cmlmain::tcalc('cl',$t);
  			return $kobj->{$uid}->{$key}->{id};
  				
  		} else {
   			unless ($nobj->{$_[0]->{key}})    {
    			my $sthK=$dbh->prepare("SELECT upobj,id FROM ${DBPREFIX}objects WHERE keyname=?");
    			$sthK->execute($_[0]->{key}) || die $dbh->errstr;
    			($upobj,$oid)=$sthK->fetchrow();
    			buildlowtree($upobj,$oid);
   			}
   			&cmlmain::tcalc('cl',$t);
   			return $nobj->{$_[0]->{key}}->{id};
   			
  		}	
  	}   elsif ($_[0]->{uid})   {
    	buildlowtree($_[0]->{uid},undef,$_[0]->{limit});
  	}
	&cmlmain::tcalc('cl',$t);


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
  push(@tlist,'u1') if $id && $obj->{$id}->{up} == 1;
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
	 
	 
	 my $mkey ="LISTMENU_".$obj->{$id}->{key};
	 checkload({key=>$mkey});
	 $mlist->{listmenutemplate}=$mkey if $nobj->{$mkey}->{id};
	 
	 
	 return $mlist;
}	

sub createcmsmethod {
	my $id;
	if (ref $_[0] eq 'HASH') {
		$id=$nobj->{$_[0]->{key}}->{id};
	} else {
		$id=$_[0];
	}
	
	my $prm=$_[1];
	my $key=$obj->{$id}->{key};
	my $name=$obj->{$id}->{name};
	my $method;
    my $template=createtemplate($id,$prm);

	
	if ($prm eq 'listedittemplate') {
		$method="LISTEDIT_$key";
		my $newid=addlowobject({upobj=>$nobj->{CMSDESIGN}->{id},key=>$method,name=>encu("Шаблон редактирования списка")." '$name'"});
		setvalue({id=>$newid,param=>'PAGETEMPLATE',value=>$template});
	}	elsif ($prm eq 'edittemplate') {
		$method="EDIT_$key";
		my $newid=addlowobject({upobj=>$nobj->{CMSDESIGN}->{id},key=>$method,name=>encu("Шаблон объекта")." '$name'"});
		setvalue({id=>$newid,param=>'PAGETEMPLATE',value=>$template});
	}	elsif ($prm eq 'listmenutemplate') {
		$method="LISTMENU_$key";
		my $newid=addlowobject({upobj=>$nobj->{CMSDESIGN}->{id},key=>$method,name=>encu("Шаблон меню списка объекта")." '$name'"});
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
	} elsif ($prm eq 'listmenutemplate') {
		setvalue({key=>"LISTMENU_$key",param=>'PAGETEMPLATE',value=>$template});
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
	}	elsif ($prm eq 'listmenutemplate') {
		my $k="LISTMENU_$key";
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
  	if ($prm eq 'listmenutemplate') {
	  	my $tmpl=calculate({key=>'BASEMENULIST',expr=>'p(PAGETEMPLATE)',noparse=>1})->{value};
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
	my ($login,$password,$group,$fio,$opts)=@_;
	if ($login!~/^[a-zA-Z][a-zA-Z0-9_]+$/) {
		return (undef,'Неправильные символы в логине');
	}
	if (&cmlcalc::id("SU_$login")) {
		return (undef,'Пользователь с таким логином существует');
	}
	my $upkey='SYSTEMUSERS';
	$upkey.="_$group" if $group;
	my $oid=&cmlcalc::add($opts->{up} || &cmlcalc::id($upkey),{
		_NAME=>$fio || $login,
		_KEY=>"SU_$login",
		SULOGIN=>$login,
	});
	
	my $sth=$dbh->prepare("INSERT INTO ${DBPREFIX}users (login,password,`group`,objid) VALUES (?,ENCRYPT(?),?,?)");
	$sth->execute ($login,$password,$group,$oid) || die $dbh->errstr;
	if ($PASSFILE) {writepassfile()}
	return ($oid,undef);
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
	my $ugrp='SYSTEMUSERS';
	$ugrp.="_$group" if $group;
	&cmlcalc::set(&cmlcalc::id("SU_$login"),'_UP',&cmlcalc::id($ugrp));
}	



sub deluser ($;$){
	my ($login,$nodelobj)=@_;
	my $sth=$dbh->prepare("DELETE FROM ${DBPREFIX}users WHERE login=?");
	$sth->execute ($login) || die $dbh->errstr;
	if ($PASSFILE) {writepassfile()}
	deletelowobject(&cmlcalc::id("SU_$login")) unless $nodelobj;
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
	
	my ($fn,$grp)=@_;
	my $fcontent;
	
	open (HTF, "<$fn");
	read (HTF,$fcontent,-s $fn);
	close(HTF); 
	my $htdata;
	if ($grp eq 'admin') {
		$htdata="
				AuthType Basic
				AuthName \"vCMS $grp Login\"
				AuthUserFile \"$PASSFILE\"
 	 			AuthGroupFile \"$GRPFILE\"
 	 			Require group $grp
		";
	}	
	if ($grp eq 'user') {
		$htdata="
				AuthType Basic
				AuthName \"vCMS Login\"
				AuthUserFile \"$PASSFILE\"
 				Require valid-user
		";
	}
	if ($fcontent=~/RESTRICT START/s) {
		$fcontent=~s{(### RESTRICT START ###)(\n?.*?)(\n### RESTRICT END ###)}{$1$htdata$3}s		
	} else {
		$fcontent=$htdata;
	}	
	open (HTFILE, ">$fn");
	print HTFILE $fcontent;
    close HTFILE;
	chmod (0644, $fn); 	
}	

sub fromcache {
	my ($key,$dev,$lang)=@_;
    my $flags=vCMS::Config::CacheFlags($dev);
	$sthSC->execute($key,$flags,"$lang") || die $dbh->errstr;
	return $sthSC->fetchrow();
}	

sub dropcache {
	my ($key,$dev,$lang)=@_;
	my $flags=vCMS::Config::CacheFlags($dev);
	$sthDDC->execute($key,$flags,"$lang") || die $dbh->errstr;
}

sub tocache {
	my ($key,$value,$links,$dev,$lang)=@_;
	my $flags=vCMS::Config::CacheFlags($dev);
	$lang = '' unless $lang;
	my $ts=time();
	$sthDC->execute($key,$flags,$lang) ||  die $dbh->errstr;
	my %inserted;
	my @il;
	for (@$links) {
		if ($_ && !$inserted{$_}) {
			if ($_=~/^u?\d+$/) {
				push (@il,"('$key','$_','$flags','$lang')");
			} else {
				warn "linkcache bad element key=$key element=$_";
			} 	
			$inserted{$_}=1;
   			$GLOBAL->{timers}->{tcc}++;			
		}	
	}
	if (@il) {
		my $istr=join(',',@il);
		my $q="REPLACE ${DBPREFIX}linkscache (cachekey,objlink,dev,lang) VALUES $istr";
		$dbh->do($q) || die $dbh->errstr()." q=$q";
	}
	$sthIC->execute($key,$value,$flags,$lang) || die $dbh->errstr;
    $GLOBAL->{timers}->{tc}+=time()-$ts;
	
}	




sub fastsearch {
	my $pkey=$_[0]->{prm};
	my $pattern=$_[0]->{pattern};
	my $like=$_[0]->{like};
	my $up=$_[0]->{up};
	my $clause=$_[0]->{clause};
	my $filterlist=$_[0]->{filterlist};
	my $skiplist=$_[0]->{skiplist};
	my $sthSRC;
	my $ts=time();
	
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
	if ($_[0]->{filterlist}) {
		for my $currfilter (@{$_[0]->{filterlist}}) {
			my $h;
			$h->{$_}=1 for @$currfilter;
			@rlist=grep {$h->{$_}} @rlist;
		}	 
	}
	
	if ($_[0]->{skiplist}) {
		my $h;
		$h->{$_}=1 for @{$_[0]->{skiplist}};
		@rlist=grep {!$h->{$_}} @rlist;
	}
	@rlist=sort {$lobj->{$a}->{indx}<=>$lobj->{$b}->{indx}} @rlist;
	
	$GLOBAL->{timers}->{fs}+=time()-$ts;
   	$GLOBAL->{timers}->{fsc}++;	
	
	return @rlist;
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


sub email {
  	my $to		=$_[0]->{to};
  	my $from	=$_[0]->{from};
  	my $message	=$_[0]->{message};
  	my $subject	=$_[0]->{subject};	
  	my $html	=$_[0]->{html};
  	
  	my $charset=$_[0]->{charset};
  	my $lid=$_[0]->{letterid};
  	
  	if ($lid) {
  		$from	=&cmlcalc::p(LETTERFROM,$lid) unless $from;
  		$to		=&cmlcalc::p(LETTERTO,$lid) unless $to;
  		$message=&cmlcalc::p(LETTERTEXT,$lid) unless $message;
  		$subject=&cmlcalc::p(LETTERSUBJECT,$lid) unless $subject;	
  		$html	=&cmlcalc::p(LETTERHTML,$lid) unless $html;
  		
  	}
  	if ($_[0]->{objid}) {
  		$message=&cmlparse::cmlparser({data=>$message,objid=>$_[0]->{objid}});
  		$subject=&cmlparse::cmlparser({data=>$subject,objid=>$_[0]->{objid}});
  	}
  	
  	my $contenttype;
  	my $att_filename;
  	die "send mail : no recepient"	if $to!~/\@/;

  	if ($html) {
  		$contenttype='text/html';
  	} elsif ($_[0]->{csv}) {
  		$contenttype='text/csv';
  		$att_filename='export.csv';
  	} else {
  		$contenttype='text/plain';	
  	}
  	
  	my $lmessage=$message;
  	my $lsubject=$subject;
  	
  	my $defcharset=$GLOBAL->{CODEPAGE} eq 'utf-8'?'utf-8':'windows-1251';
  	my $echarset=$charset || $defcharset;
        $subject = encode('utf-8',$subject) if $GLOBAL->{CODEPAGE} eq 'utf-8';
	$subject = '=?'.$echarset.'?b?'.encode_base64($subject,'').'?=';
  	Encode::from_to( $message, $defcharset, $charset) if $charset;
  
	unless(open (MAIL, "|/usr/sbin/sendmail -r $from $to")) {
		print "no sendmail $!";
		return undef;
	}	else{
		print MAIL "To: $to\n";
		print MAIL "From: $from\n";
		print MAIL "Subject: $subject\n";
		print MAIL "Content-Type: $contenttype; charset=$echarset\n";
		print MAIL "Content-Disposition: attachment; filename=$att_filename\n" if $att_filename;
		print MAIL "\n";
		print MAIL $message;
		close(MAIL) || die "Error closing mail: $!";
		if ($_[0]->{log}) {
			my $id=addlowobject({upobj=>&cmlcalc::id(EMAILARC),name=>scalar localtime().' '.$lsubject});
			setvalue({id=>$id,param=>EMAILMESSAGE,value=>$lmessage});
			setvalue({id=>$id,param=>EMAILSUBJECT,value=>$lsubject});
			setvalue({id=>$id,param=>EMAILADDRESS,value=>$to});
			setvalue({id=>$id,param=>EMAILFROM,value=>$from});
			setvalue({id=>$id,param=>EMAILDATE,value=>&cmlcalc::now()});
		}
		
		return $message;
	}
	
}	

sub copylinkfile ($$$;$)
{
	my ($id,$sp,$dp,$force)=@_;
	my $sname=&cmlcalc::p($sp,$id);
	my $dname=&cmlcalc::p($dp,$id);
	if ($sname && ($force || !$dname)) {
   		my $spath="$GLOBAL->{FILEPATH}/..$sname";
   		$sname=~s/\//_/g;
   		$dname=$sname;
   		copy("$spath","$GLOBAL->{FILEPATH}/$dname") || message ("Copy failed: $! file : $spath user : ".getlogin());
   		return unless -s "$GLOBAL->{FILEPATH}/$dname";
   		&cmlcalc::set($id,$dp,$dname);
   		return $dname;
	}
	return undef;
	
}

sub clear_unused_data (;$)
{
	my ($path)=@_;
	my %needed = (
		'.'=>1,
		'..'=>1,
		'.htaccess'=>1,
	); 
	my $sth1=$dbh->prepare("SELECT vls.value FROM prm,vls WHERE (prm.ptype='FILE' OR prm.ptype='PICTURE' OR prm.ptype='VIDEO') AND prm.pkey=vls.pkey");
	$sth1->execute() || die $dbh->errstr();
	$needed{$_[0]}=1 while (@_=$sth1->fetchrow());
	
	my $sth2=$dbh->prepare("SELECT uvls.value FROM prm,uvls WHERE (prm.ptype='FILE' OR prm.ptype='PICTURE' OR prm.ptype='VIDEO') AND prm.pkey=uvls.pkey");
	$sth2->execute() || die $dbh->errstr();
	$needed{$_[0]}=1 while (@_=$sth2->fetchrow());
	
	opendir(my $dh, $GLOBAL->{FILEPATH}) || die;
	my @str=readdir $dh;
	closedir $dh;
	my @need_clear=grep {!$needed{$_}} @str;
	if ($path) {
		move ("$GLOBAL->{FILEPATH}/$_","$GLOBAL->{WWWPATH}/$path/$_") for @need_clear;
	}	
	return \@need_clear;  
}


sub stat_injection 
{
    my ($mtime,$bodyref,$cached)=@_;
    $mtime=int(1000*$mtime);
    my $cv=$cached?1:0;
    my $stat_script=qq(
    
     <script type="text/javascript">
             var drt;
             var wlt;
             var mt=$mtime;
             jQuery(document).ready(function() {
                 drt=Date.now()-timerStart+mt;
             });
             jQuery(window).load(function() {
                 wlt=Date.now()-timerStart+mt;
                 var newImg = new Image;
                 newImg.src = '/cgi-bin/stat.pl?d='+drt+'&w='+wlt+'&s='+mt+'&c=$cv';
             });
             
        </script>       
    
    
    );
    my $init_script=qq(<script type="text/javascript">var timerStart = Date.now();</script>);


    ${$bodyref}=~s/<!-- INIT INJECTION -->/$init_script/i;
    ${$bodyref}=~s/<!-- STAT INJECTION -->/$stat_script/i;

}


return 1;


END {}
