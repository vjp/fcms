package vCMS;

use vCMS::Object::Up;
use vCMS::Object::Low;
use vCMS::Object::Null;
use vCMS::Proxy;
use vCMS::Session;
use vCMS::Collection::LowList;
use vCMS::RPC;
use vCMS::SiteUser;

BEGIN
{ 
	use Exporter();
	@ISA = 'Exporter';
	@EXPORT = qw( &o &v &ll &r &u &nn &db &gr);
}	 

sub o(;$); 
sub v($;$);

sub u(;$) {
	my ($user)=@_;
	if ($user) {
		if ($user=~/^\d+$/) {
			my $objid=$user;
			my $login = vCMS::Proxy::GetLoginByObjID($objid);
			return undef unless $login;
			return vCMS::SiteUser->new($objid,$login);
		} else {
			my $login=$user;
			my $objid=vCMS::Proxy::CheckUser($login);
			return undef unless $objid;
			return vCMS::SiteUser->new($objid,$login);
		}	
	} else {
		(my $id, my $login)=vCMS::Proxy::CheckSession();
		return undef unless $id;
		return vCMS::SiteUser->new($id,$login);
	}	
}	


sub nn($) {
	return !o($_[0])->IsNull();
}

sub o(;$) {
	my ($id)=@_;
	$id=vCMS::Proxy::CurrentObjectID() unless $id;
	my $pObj;
    if ($id=~/^(\d+)$/) {
    	$pObj=vCMS::Object::Low->new($1);
    	return $pObj->Load()?$pObj:new vCMS::Object::Null();
    } elsif ($id=~/^u(\d+)/) {
    	$pObj=vCMS::Object::Up->new($1);
    	return $pObj->Load()?$pObj:new vCMS::Object::Null();
    } elsif ($id) {
        my $oid=vCMS::Proxy::GetIDByKey($id);
        return  $oid=~/^u?(\d+)$/?o($oid):new vCMS::Object::Null();
    } else {
    	return new vCMS::Object::Null()
    }
}

sub v($;$) {
	return vCMS::Session::GetVar($_[0],$_[1])
}

=head

ll($objkeyorid,$filteringexpression) - method for vCMS::Collection::LowList using
can filter reusltset if use expression with indexed parameter

examples

my $pCol=ll();
my $pCol=ll(TARCH);
my $pCol=ll(TARCH,'p(COST)<25');

=cut

sub ll(;$$) {
	return new vCMS::Collection::LowList(o($_[0]),$_[1]);
}

sub null () {
	return new vCMS::Object::Null();
}

sub r ($) {
	my ($connectstr)=@_;
	my ($user,$password,$host)=($connectstr=~/^(.+?)\:(.+)\@(.+?)$/);
	return new vCMS::RPC($host,$user,$password)
}


sub db {
    return vCMS::Proxy::DBSelect(@_);
}


sub gr ($$$;$) {
    my ($pkey,$pattern,$rpattern,$limit)=@_;
    $limit ||=1;
    my $tname=vCMS::Proxy::GetTableName('vls');
    my $list=db("SELECT objid,pkey FROM $tname WHERE pkey=? and VALUE LIKE ? LIMIT $limit",$pkey,'%'.$pattern.'%');

    my $r;
    for (@$list) {
        my $pObj=o($_->{'objid'});
        my $v=$pObj->p($pkey,{noparse=>1});
        $v=~s/$pattern/$rpattern/ig;
        $pObj->Set($pkey,$v);
        push (@$r,$pObj);
    }
    
    return new vCMS::Collection($r);
}


1;