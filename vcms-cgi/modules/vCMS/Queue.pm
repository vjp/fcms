package vCMS::Queue;

use lib "..";
use vCMS;

sub Add ($;$) {
	my ($method,$exectime)=@_;
	$exectime ||= time();
	return vCMS::Proxy::CreateQueueEvent($method->GetObject()->GetID(),$method->GetName(),$exectime);
}

sub Check ($) {
	my ($method)=@_;
	return vCMS::Proxy::CheckQueueEvent($method->GetObject()->GetID(),$method->GetName());
}


sub Job (;$){
	my ($processor_id)=@_;
	$processor_id ||= Time::HiRes::time();
	my $ev=vCMS::Proxy::GetQueueEvent($processor_id);
	if ($ev) {
		warn "[[QJOB]] ".scalar localtime()." Start processing event $ev->{objid} : $ev->{method}";
		my $r=vCMS::o($ev->{objid})->e($ev->{method});
		vCMS::Proxy::DeleteQueueEvent($ev->{qid});
		warn "[[QJOB]] ".scalar localtime()." Finish processing event $ev->{objid} : $ev->{method}";
		return 1;
	} else {
		return undef;
	}	
}


sub Reset () {
	vCMS::Proxy::ResetQueue();
}


sub Status () {
    vCMS::Proxy::QueueStatus();
}


sub ViewStat () {
    my $r=vCMS::Proxy::QueueStatus();
    return  vCMS::Proxy::SetEnv('QSTAT',"QSTAT=".$r);
}
1;