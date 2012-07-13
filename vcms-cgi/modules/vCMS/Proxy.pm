package vCMS::Proxy;
 
use lib ".."; 
use cmlmain; 

sub GetIDByKey ($) {
	my $key=shift;
	return cmlmain::checkload({key=>$key});
}

sub GetUpID ($) {
	my $id=shift;
	if ($id=~/u(\d+)/) {
		return $cmlmain::obj->{$1}->{up};
	} elsif ($id=~/(\d+)/) {
		return $cmlmain::lobj->{$1}->{up};
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


sub CheckObj ($) {
	my $id=shift;
	if ($id=~/u(\d+)/) {
		return $cmlmain::obj->{$1}?1:0;
	} elsif ($id=~/(\d+)/) {
		return $cmlmain::lobj->{$1}?1:0;
	}	
}


sub LowList ($) {
	my $id=shift;
	cmlmain::checkload({uid=>$id}); 
    my @list= sort {$cmlmain::lobj->{$a}->{indx}<=>$cmlmain::lobj->{$b}->{indx}} @{$cmlmain::ltree->{$id}->{0}};
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
		if (IsMultilangParam($_->{pkey})) {
			$h->{$_->{objid}}->{$_->{pkey}}->{langvalue}->{$_->{lang}}=$_->{value}
		} else {
			$h->{$_->{objid}}->{$_->{pkey}}->{value}=$_->{value}
		}	
	}
	return $h;
	
}

1;