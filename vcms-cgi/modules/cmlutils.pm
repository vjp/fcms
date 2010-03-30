package cmlutils;

# $Id: cmlutils.pm,v 1.10 2010-03-30 22:35:51 vano Exp $

BEGIN	{
	use Exporter();
	use Data::Dumper;
	use Time::Local;
 	
 	use cmlmain;
 	eval {require Time::HiRes };
 	use Encode;
 	use	URI::Escape;

 	@ISA = 'Exporter';
 	@EXPORT = qw( &getpage &currency &xmlparse &email &yandexsearch &sitesearch &yandextic &googlepr &whois );
}

sub whois {
	require Net::Whois::Raw;
	my $d;
	my $domain=shift;
	$domain=~s/^.*\.(\S+?\.\S+?)$/$1/;
	for(grep {!/(^[%\s])|^$/} split /\n/,Net::Whois::Raw::whois($domain)) {
		if (/^(\S+?):\s*(.+)/) {
			if ($d->{$1}) {
				$d->{$1}.=" ; $2";
			} else {	
				$d->{$1}=$2
			}	
		}	 	
		$d->{update}=$1 if /Last updated on (.+)/;		
	}
	return $d;
}

sub sitesearch ($;$) 
{
	my ($query,$opts)=@_;
	my $site=$opts->{'site'} || $ENV{SERVER_NAME};
	my $page=$opts->{'page'} || 0;
	$site="www.$site";

	require LWP::UserAgent;
	require XML::Simple;	    
	my $ua = LWP::UserAgent->new;
	$ua->agent("vCMS Yandex Site Search");
	my $squery =
<<DOC;
<?xml version='1.0' encoding='windows-1251'?>
<request>    
	<query>$query site='$site'</query>
	<page>0</page>
</request>
DOC

	my $req = HTTP::Request -> new      ( POST => 'http://xmlsearch.yandex.ru/xmlsearch'); 
	$req -> content_type ('application/xml');    
	$req -> content ($squery);
	my $response = $ua -> request ($req);
	my $xs = XML::Simple->new();
	my $rf=$xs->XMLin($response->content);
	my $r;
	$r->{found}=0;
	if ($rf->{response}->{error}) {
		$r->{error}= Encode::encode('cp1251',$rf->{response}->{error}->{content});
		$r->{errorcode}=$rf->{response}->{error}->{code};
		return $r;
	}
	return $r unless $rf->{response}->{results}->{grouping}->{group};
	my @finded=ref ($rf->{response}->{results}->{grouping}->{group}) eq 'ARRAY'?
		@{$rf->{response}->{results}->{grouping}->{group}}:($rf->{response}->{results}->{grouping}->{group});
    

	for (@finded) {
		my $v;
		if (ref $_->{doc}->{passages}->{passage} eq 'ARRAY') {
			if (ref $_->{doc}->{passages}->{passage}->[0] eq 'HASH') {
      			my @w=ref $_->{doc}->{passages}->{passage}->[0]->{hlword} eq 'ARRAY'?@{$_->{doc}->{passages}->{passage}->[0]->{hlword}}:($_->{doc}->{passages}->{passage}->[0]->{hlword});
      			my @p=@{$_->{doc}->{passages}->{passage}->[0]->{content}};
      			if (scalar @p==scalar @w) {
      				$v='<b>'.shift(@w).'</b>';
      			}
      			my $v1=shift(@p);
      			my $ww=shift(@w);
      			while ($v1) {
         			$v.="$v1<b>$ww</b>";
         			$v1=shift(@p);
         			$ww=shift(@w)
      			}   
			} else {
				$v=$_->{doc}->{passages}->{passage}->[0];
			}	
		} else {
   			if ($_->{doc}->{passages}->{passage}->{content}) {
      			my @w=ref $_->{doc}->{passages}->{passage}->{hlword} eq 'ARRAY'?@{$_->{doc}->{passages}->{passage}->{hlword}}:($_->{doc}->{passages}->{passage}->{hlword});
      			my @p=@{$_->{doc}->{passages}->{passage}->{content}};
      			if (scalar @p==scalar @w) {
      				$v='<b>'.shift(@w).'</b>';
      			}
      			my $v1=shift(@p);
      			my $ww=shift(@w);
      			while ($v1) {
         			$v.="$v1<b>$ww</b>";
         			$v1=shift(@p);
         			$ww=shift(@w)
      			}   
   			}
		}
		
   		my $cr;
   		$cr->{string} = Encode::encode('cp1251',$v);
   		$cr->{url}=$_->{doc}->{url};
   		
   		
   		if (ref $_->{doc}->{title} eq 'HASH') {
   			if (ref $_->{doc}->{title}->{content} eq 'ARRAY') {
   				my $v;
   				my @w=ref $_->{doc}->{title}->{hlword} eq 'ARRAY'?@{$_->{doc}->{title}->{hlword}}:($_->{doc}->{title}->{hlword});
      			my @p=@{$_->{doc}->{title}->{content}};
      			if (scalar @p==scalar @w) {
      				$v=shift(@w);
      			}
      			my $v1=shift(@p);
      			my $ww=shift(@w);
      			while ($v1) {
         			$v.="$v1$ww";
         			$v1=shift(@p);
         			$ww=shift(@w)
      			}   
   				$cr->{title}=Encode::encode('cp1251',$v);;
   			} else {	
   				$cr->{title}=Encode::encode('cp1251',$_->{doc}->{title}->{hlword}.$_->{doc}->{title}->{content});
   			}	
   		} else {
   			$cr->{title}=Encode::encode('cp1251',$_->{doc}->{title});
   		}	
   		push(@{$r->{result}},$cr);	
   	}
   	for (@{$rf->{response}->{found}}) {
   		$r->{found}=$_->{content} if $_->{priority} eq 'all';	
   	}
   	
	$r->{wordstat}=Encode::encode('cp1251',$rf->{response}->{wordstat});
	return $r;	
}


sub yandexsearch {
	my ($qstr,$deep)=@_;
	$deep=10 unless $deep;
	require LWP::UserAgent;
	require XML::Simple;	    
	my $ua = LWP::UserAgent->new;
	$ua->agent("vCMS Yandex Search");
	my $dquery =
<<DOC;
<?xml version='1.0' encoding='windows-1251'?>
<request>    
	<query>$qstr</query>
	<page>0</page>
	<maxpassages>0</maxpassages>
	<groupings>
        <groupby attr='d' mode='deep' groups-on-page='$deep' docs-in-group='1' curcateg='-1'/>
    </groupings>

</request>
DOC
	my $req = HTTP::Request -> new      ( POST => 'http://xmlsearch.yandex.ru/xmlsearch'); 
	$req -> content_type ('application/xml');    
	$req -> content ($dquery);
	my $response = $ua -> request ($req);
	my $xs = XML::Simple->new();
	my $rf=$xs->XMLin($response->content);
	message("XML YANDEX ERROR: $rf->{response}->{error}") if $rf->{response}->{error};
	return undef unless $rf->{response}->{results}->{grouping}->{group};
		message($rf->{response}->{wordstat});
	return @{$rf->{response}->{results}->{grouping}->{group}} if ref ($rf->{response}->{results}->{grouping}->{group}) eq 'ARRAY';
	return ($rf->{response}->{results}->{grouping}->{group});
}




sub googlepr {
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new('Mozilla/4.0 (compatible; GoogleToolbar 2.0.111-big; Windows XP 5.1)');
	my $domain=shift;
	my $url="http://$domain";
	
	my $ch = '6' . _compute_ch_new('info:' . $url);
  	my $query = 'http://toolbarqueries.google.com/search?client=navclient-auto&ch=' . $ch .
    '&ie=UTF-8&oe=UTF-8&features=Rank&q=info:' . uri_escape($url);
  	my $resp = $ua->get($query);
  	if ($resp->is_success && $resp->content =~ /Rank_\d+:\d+:(\d+)/) {
  		return $1;
  	}	
  	else {return undef}		
	
}


sub yandextic {
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new('vCMS Yandex Search');
	my $domain=shift;
	my $r;
	my $resp = $ua->get(sprintf('http://search.yaca.yandex.ru/yandsearch?rpt=rs2&text=%s',$domain));
    ($r->{tic})=($resp->content=~/������������:&nbsp;(\d+)/i);	
	
	#(my @xl)=($resp->content =~ /"http:\/\/www.yandex.ru\/yandsearch\/\?text=&Link=[^"]*&ci=\d+[^"]*"/gi);
	#(my @xl)=($resp->content =~ m!<td width="\*"><A target=_blank onclick="r\(this, 'ctya'\)" href="\S+?" target=_blank>.+?</A></td><td align="right">\d+</td>!gi);
	#my @slist;
	#my $r;
	#for (@xl) {
	#	if ($_=~ m!<td width="\*"><A target=_blank onclick="r\(this, 'ctya'\)" href="(\S+?)" target=_blank>.+?</A></td><td align="right">(\d+)</td>!gi) {
	#	#if (/"http:\/\/www.yandex.ru\/yandsearch\/\?text=&Link=http:\/\/([^"]*?),[^"]*&ci=(\d+)[^"]*"/gi)  	{
	#		my $d=$1;		
	#		my $ic=$2;		
	#		$r->{tic}=$ic if $d=~/$domain/ && !$r->{tic};	
	#		push (@{$r->{list}},{domain=>$d,tic=>$ic});
	#	}
	#}
	
	unless ($r->{tic}) {
		$resp = $ua->get(sprintf('http://search.yaca.yandex.ru/yca/cy/ch/%s/',$domain ));
		if ($resp->content=~/<b>������ ����������� \(���\) �������&nbsp;\&\#151;\&nbsp;(\d+)/s) {
			$r->{tic}=$1;
		}
		$r->{notcatalog}=1;
	}
	
	
	return ($r->{tic},!$r->{notcatalog},$resp->content);
}
sub xmlparse {
	require XML::Simple;
	my $fn=shift;
    my $xs = XML::Simple->new();	   
    my $rf = $xs->XMLin("$GLOBAL->{FILEPATH}/$fn");
	return $rf;
}	

sub email {
  	my $to=$_[0]->{to};
  	my $from=$_[0]->{from};
  	my $message=$_[0]->{message};
  	my $subject=$_[0]->{subject};	
  	my $charset=$_[0]->{charset};
  	my $lmessage=$message;
  	my $echarset=$charset || 'windows-1251';
 	
  	Encode::from_to( $message, 'windows-1251', $charset) if $charset;
  
	unless(open (MAIL, "|/usr/sbin/sendmail $to")) {
		print "no sendmail $!";
		return undef;
	}	else{
		print MAIL "To: $to\n";
		print MAIL "From: $from\n";
		print MAIL "Subject: $subject\n";
		print MAIL "Content-Type: text/plain; charset=$echarset\n";
		print MAIN "\n";
		print MAIL $message;
		close(MAIL) || print "Error closing mail: $!";
		if ($_[0]->{log}) {
			my $id=addlowobject({upobj=>&cmlcalc::id(EMAILARC),name=>scalar localtime()});
			setvalue({id=>$id,param=>EMAILMESSAGE,value=>$lmessage});
			setvalue({id=>$id,param=>EMAILSUBJECT,value=>$subject});
			setvalue({id=>$id,param=>EMAILADDRESS,value=>$to});
			setvalue({id=>$id,param=>EMAILFROM,value=>$from});
			setvalue({id=>$id,param=>EMAILDATE,value=>&cmlcalc::now()});
		}
		
		return 1;
	}
	
	}	


sub getpage {
	
	my $url=shift;
	my $erralert=shift;
	
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  $ua->agent("MyApp/0.1 ");
  my $res = $ua->request(HTTP::Request->new(GET => $url));
  if ($res->is_success) {
  		return $res->content;
  } else {
  	  alert("getpage error:".$res->status_line); 
  	  return 0;
  }			

	
}	


sub currency {

my $val=$_[0]; 
my $time=timegm(localtime())*1000;

my $text=getpage("http://www.prime-tass.ru/results/export.asp?funcNum=4&format=xml&divider=&sDate=$time");

(my @rows)=($text=~m/<row>(.*?)<\/row>/igs);

my $vpr;
for (@rows) {
  (my $curs)=($_=~m/<cell.*?"Last".*?>(.+?)<\/cell>/igs);
  (my $ticker)=($_=~m/<cell.*?"Ticker".*?>(.+?)<\/cell>/igs);
  $vpr->{$ticker}=$curs;
}


return $vpr->{$val};

}


sub _compute_ch_new {
  my $url = shift;

  my $ch = _compute_ch($url);
  $ch = (($ch % 0x0d) & 7) | (($ch / 7) << 2);

  return _compute_ch(pack("V20", map {my $t = $ch; _wsub($t, $_*9); $t} 0..19));
}

sub _compute_ch {
  my $url = shift;

  my @url = unpack("C*", $url);
  my ($a, $b, $c, $k) = (0x9e3779b9, 0x9e3779b9, 0xe6359a60, 0);
  my $len = scalar @url;

  while ($len >= 12) {
    _wadd($a, $url[$k+0] | ($url[$k+1] << 8) | ($url[$k+2] << 16) | ($url[$k+3] << 24));
    _wadd($b, $url[$k+4] | ($url[$k+5] << 8) | ($url[$k+6] << 16) | ($url[$k+7] << 24));
    _wadd($c, $url[$k+8] | ($url[$k+9] << 8) | ($url[$k+10] << 16) | ($url[$k+11] << 24));

    _mix($a, $b, $c);

    $k += 12;
    $len -= 12;
  }

  _wadd($c, scalar @url);

  _wadd($c, $url[$k+10] << 24) if $len > 10;
  _wadd($c, $url[$k+9] << 16) if $len > 9;
  _wadd($c, $url[$k+8] << 8) if $len > 8;
  _wadd($b, $url[$k+7] << 24) if $len > 7;
  _wadd($b, $url[$k+6] << 16) if $len > 6;
  _wadd($b, $url[$k+5] << 8) if $len > 5;
  _wadd($b, $url[$k+4]) if $len > 4;
  _wadd($a, $url[$k+3] << 24) if $len > 3;
  _wadd($a, $url[$k+2] << 16) if $len > 2;
  _wadd($a, $url[$k+1] << 8) if $len > 1;
  _wadd($a, $url[$k]) if $len > 0;

  _mix($a, $b, $c);

  return $c; # integer is positive always
}

sub _mix {
  my ($a, $b, $c) = @_;

  _wsub($a, $b); _wsub($a, $c); $a ^= $c >> 13;
  _wsub($b, $c); _wsub($b, $a); $b ^= ($a << 8) % 4294967296;
  _wsub($c, $a); _wsub($c, $b); $c ^= $b >>13;
  _wsub($a, $b); _wsub($a, $c); $a ^= $c >> 12;
  _wsub($b, $c); _wsub($b, $a); $b ^= ($a << 16) % 4294967296;
  _wsub($c, $a); _wsub($c, $b); $c ^= $b >> 5;
  _wsub($a, $b); _wsub($a, $c); $a ^= $c >> 3;
  _wsub($b, $c); _wsub($b, $a); $b ^= ($a << 10) % 4294967296;
  _wsub($c, $a); _wsub($c, $b); $c ^= $b >> 15;

  @_[0 .. $#_] = ($a, $b, $c);
}

sub _wadd { $_[0] = int(($_[0] + $_[1]) % 4294967296);}
sub _wsub { $_[0] = int(($_[0] - $_[1]) % 4294967296);}




1;


END {}
