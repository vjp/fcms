package vCMS;

use vCMS::Object::Up;
use vCMS::Object::Low;
use vCMS::Proxy;

BEGIN
{ 
	use Exporter();
	@ISA = 'Exporter';
	@EXPORT = qw( &o);
}	 

sub o($); 
sub o($) {
	my $id=shift;
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


1;