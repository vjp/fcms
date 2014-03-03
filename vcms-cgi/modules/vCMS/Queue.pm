package vCMS::Queue;

use lib "..";
use vCMS;

sub Add ($;$) {
	my ($method,$exectime)=@_;
	$exectime ||= time();
	return vCMS::Proxy::CreateQueueEvent($method->GetObject()->GetID(),$method->GetName(),$exectime);
}

sub Job (;$){
	my ($processor_id)=@_;
	$processor_id ||= Time::HiRes::time();
	my $ev=vCMS::Proxy::GetQueueEvent($processor_id);
	if ($ev) {
		my $r=vCMS::o($ev->{objid})->e($ev->{method});
		vCMS::Proxy::DeleteQueueEvent($ev->{qid});
		return $r;
	} else {
		return undef;
	}	
}

sub Reset () {
	vCMS::Proxy::ResetQueue();
}

1;