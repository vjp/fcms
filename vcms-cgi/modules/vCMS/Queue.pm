package vCMS::Queue;


sub Add ($;$) {
	my ($method,$exectime)=@_;
	$exectime ||= time();
	return vCMS::Proxy::CreateQueueEvent($method->GetObject()->GetID(),$method->GetName(),$exectime);
}

sub Job (;$){
	my ($processor_id)=@_;
	$processor_id ||= Time::HiRes::time();
	return vCMS::Proxy::GetQueueEvent($processor_id);
}

sub Reset () {
	vCMS::Proxy::ResetQueue();
}

1;