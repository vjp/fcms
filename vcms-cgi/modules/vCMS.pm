package vCMS;

use vCMS::Object::Up;
use vCMS::Object::Low;
use vCMS::Proxy;
use vCMS::Session;

BEGIN
{ 
	use Exporter();
	@ISA = 'Exporter';
	@EXPORT = qw( &o &v );
}	 

sub o(;$); 
sub v($;$);

sub o(;$) {
	my ($id)=@_;
	$id=vCMS::Proxy::CurrentObjectID() unless $id;
	my $pObj;
    if ($id=~/^(\d+)$/) {
    	$pObj=vCMS::Object::Low->new($1);
    	return $pObj;
    } elsif ($id=~/^u(\d+)/) {
    	$pObj=vCMS::Object::Up->new($1);
    	return $pObj->Load()?$pObj:undef;
    } else {
        my $oid=vCMS::Proxy::GetIDByKey($id);
        return  $oid=~/^u?(\d+)$/?o($oid):undef;
    }
}

sub v($;$) {
	return vCMS::Session::GetVar($_[0],$_[1])
}

1;