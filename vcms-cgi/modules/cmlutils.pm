package cmlutils;


BEGIN	{
	use Exporter();
	use Data::Dumper;
	use Time::Local;
 	
 	use cmlmain;
 	eval {require Time::HiRes };
 	use Encode;
 	use	URI::Escape;
  

  	use Unicode::Map8;
  	use Unicode::String;

 	@ISA = 'Exporter';
 	@EXPORT = qw( &xmlparse &yandexsearch &sitesearch &yandextic &googlepr &whois );
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
	my $url=$opts->{'url'} || 'http://xmlsearch.yandex.ru/xmlsearch';
	my $positions=$opts->{'positions'} || 10;
	$site="www.$site";

	require LWP::UserAgent;
	require XML::Simple;	    
	my $ua = LWP::UserAgent->new;
	$ua->agent("vCMS Yandex Site Search");
	$ua->local_address( $opts->{'localip'} ) if $opts->{'localip'};
	my $squery =
<<DOC;
<?xml version='1.0' encoding='$GLOBAL->{CODEPAGE}'?>
<request>    
	<query>$query host:$site</query>
	<page>0</page>
	<groupings>
        <groupby attr='' mode='flat' groups-on-page='$positions' docs-in-group='1'/>
    </groupings>
</request>
DOC

	my $req = HTTP::Request -> new      ( POST => $url); 
	$req -> content_type ('application/xml');    
	$req -> content ($squery);
	my $response = $ua -> request ($req);
	my $xs = XML::Simple->new();
	my $cnt=$response->content;
	
	$cnt=~s/<(\/?)hlword>/<$1b>/g;
	my $rf=$xs->XMLin($cnt);
	my $r;
	$r->{found}=0;
	$r->{foundhuman}=Encode::encode($GLOBAL->{ENCODING},$rf->{response}->{"found-human"});
	if ($rf->{response}->{error}) {
		$r->{error}=$rf->{response}->{error}->{content} || $rf->{response}->{error};
		$r->{error}= Encode::encode($GLOBAL->{ENCODING},$r->{error});
		$r->{errorcode}=$rf->{response}->{error}->{code};
		if ($rf->{response}->{error}->{code}!=15) {
			staterror ($r->{error},undef,undef,'SEARCHERRORS');
		}	
		return $opts->{raw}?"ERROR:$r->{errorcode} $r->{error}":$r;
	}
	return $r unless $rf->{response}->{results}->{grouping}->{group};

  	my $map = Unicode::Map8->new($GLOBAL->{ENCODING});
  	$cnt = $map->to8 (Unicode::String::utf8 ($cnt)->ucs2);    
   	my (@docs)=($cnt=~/<doc id="\S+">(.+?)<\/doc>/gs);
   	for my $doc (@docs) {
   		my $cr;
   		($cr->{title})=($doc=~/<title>(.+?)<\/title>/);
   		($cr->{url})=($doc=~/<url>(.+?)<\/url>/);
		my (@passages)=($doc=~/<passage>(.+?)<\/passage>/g);
   	    $cr->{string} = join(' ... ',@passages);   		
   		push(@{$r->{result}},$cr);
   }
   


   	for (@{$rf->{response}->{found}}) {
   		$r->{found}=$_->{content} if $_->{priority} eq 'all';	
   	}
   	
   	$r->{wordstat}=$rf->{response}->{wordstat};
	$r->{wordstat}=Encode::encode($GLOBAL->{ENCODING},$r->{wordstat});
	return $r;	
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
    ($r->{tic})=($resp->content=~/Цитируемость:&nbsp;(\d+)/i);	
	
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
		if ($resp->content=~/<b>Индекс цитирования \(тИЦ\) ресурса&nbsp;\&\#151;\&nbsp;(\d+)/s) {
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
