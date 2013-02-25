package vCMS;

use vCMS::Object::Up;
use vCMS::Object::Low;
use vCMS::Proxy;
use vCMS::Session;
use vCMS::Collection::LowList;

BEGIN
{ 
	use Exporter();
	@ISA = 'Exporter';
	@EXPORT = qw( &o &v &ll );
}	 

sub o(;$); 
sub v($;$);

sub o(;$) {
	my ($id)=@_;
	$id=vCMS::Proxy::CurrentObjectID() unless $id;
	my $pObj;
    if ($id=~/^(\d+)$/) {
    	$pObj=vCMS::Object::Low->new($1);
    	return $pObj->Load()?$pObj:undef;
    } elsif ($id=~/^u(\d+)/) {
    	$pObj=vCMS::Object::Up->new($1);
    	return $pObj->Load()?$pObj:undef;
    } elsif ($id) {
        my $oid=vCMS::Proxy::GetIDByKey($id);
        return  $oid=~/^u?(\d+)$/?o($oid):undef;
    } else {
    	return undef
    }
}

sub v($;$) {
	return vCMS::Session::GetVar($_[0],$_[1])
}

=head

ll($objkeyorid,$filteringexpression) - method for vCMS::Collection::LowList using
can filter reusltset if use expression with indexed parameter

examples

my $pCol=ll(TARCH);
my $pCol=ll(TARCH,'p(COST)<25');

=cut

sub ll($;$) {
	return new vCMS::Collection::LowList(o($_[0]),$_[1]);
}

1;