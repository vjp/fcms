package vCMS::Queue;


sub Add ($) {
	my ($method)=@_;
	return vCMS::Proxy::CreateQueueEvent($method->GetObject()->GetID(),$method->GetName());
}

sub Process {
	my ($self)=@_;
}

1;