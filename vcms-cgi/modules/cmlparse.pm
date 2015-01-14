package cmlparse;


BEGIN
{
 use Exporter();
 use Data::Dumper;
 use CGI  qw(param escapeHTML upload);
 use POSIX qw(strftime);
 use Time::HiRes qw (time);
 use URI::Escape; 
 use vCMS::Config;
 
 @ISA = 'Exporter';
 @EXPORT = qw( &cmlparser &initparser %CMLTAG %DYNTAG &uploadprmfile);
}

sub initparser
{
	%DYNTAG=(
    	'execute'=>1,
    	'captcha'=>1,
    	'auth'=>1,
    	'noauth'=>1,
 	);
	
	
 	%CMLTAG= (
    	'lowlevel'=>1,
    	'a'=>1,
    	'include'=>1,
    	'text'=>1,
    	'list'=>1,
    	'img'=>1,
    	'image'=>1,
    	'video'=>1,
    	'use'=>1,
    	'container'=>1,
    	'tree'=>1,
    	'repeat'=>1,
    	'form'=>1,
    	'if'=>1,
    	'execute'=>1,
    	'date'=>1,
    	'for'=>1,
    	'loop'=>1,
    	'var'=>1,
    	'setvar'=>1,
    	'option'=>1,
    	'inputtext'=>1,
    	'inputdate'=>1,
    	'inputfile'=>1,
    	'inputflag'=>1,
    	'inputpic'=>1,
    	'inputparam'=>1,
    	'checkbox'=>1,
    	'select'=>1,
    	'deletebutton'=>1,
    	'changebutton'=>1,
    	'radiobutton'=>1,
    	'radioselect'=>1,
    	'actionlink'=>1,
    	'menuitem'=>1,
    	'pagination'=>1,
    	'else'=>1,
    	'dev'=>1,
    	'dynamic'=>1,
    	'lightbox'=>1,
    	'captcha'=>1,
    	'captchaanswer'=>1,
    	'csvrow'=>1,
    	'csvcol'=>1,
    	'auth'=>1,
    	'noauth'=>1,
    	'savebutton'=>1,
    	'calendar'=>1,
    	'table'=>1,
    	'tr'=>1,
    	'td'=>1,
    	'th'=>1,
    	'groupheader'=>1,
    	'acc'=>1,
    	'button'=>1,
    	'flag'=>1,
    	'bold'=>1,
    	'audio'=>1,
    	'inputaudio'=>1,
    	'checkboxselect'=>1,
    	'menu'=>1,
    	'document'=>1,
 	);
}


sub cmlparser
{
 	my $text=$_[0]->{data};
 	my $pkey=$_[0]->{pkey};
 	my $objid=$_[0]->{objid};
 	my $debug=$_[0]->{debug};
 	my $inner; %{$inner}=%{$_[0]->{inner}};
 	if ($pkey)  {$inner->{pkey}=$pkey}
 	if ($objid) {$inner->{objid}=$objid}
 	if ($debug) {$inner->{debug}=$debug}
 	my $felm;  if ($_[0]->{firstelm}) {$felm=1}
 	my $lelm;  if ($_[0]->{lastelm})  {$lelm=1}
 
 	my $setreadonly=$_[0]->{readonly} && !$cmlcalc::ENV->{READONLY};
 	$cmlcalc::ENV->{READONLY}=1 if $setreadonly;
 
    $text=~s/\[\[cml:(.+?)\/\]\]/<cml:$1\/>/igs;
 	my @txt=split(/<cml:/si,$text);
 	my @stack=shift @txt;
 	my @pstack;

 	for (@txt){
 		my $tts=time();
  		(my $tag, my $tagdata)=/^(.+?>)(.*)$/s;
  		my @intxt=split(/<\/cml:/si,$tagdata);
		
  		my $firstsection=shift (@intxt);

  		push (@stack,$firstsection);
  		if ($tag=~/\/>/)	{
   			(my $tname, my $tparam)=($tag=~/(\w+)\s*(.*?)\/>/s);
   			my $rdata=pop(@stack) || '';
   			my $pstr;

	    	   			
   			if ($#stack==0)   {
      			$pstr=tagparse({name=>lc($tname),param=>" $tparam ",inner=>$inner}) || '';
   			}  else 	 {
   				$pstr="<cml:$tname $tparam/>"
   			}
   			push (@stack,(pop(@stack) || '')."$pstr$rdata" );
  		} else {
   			(my $tname, my $tparam)=($tag=~/(\w+)\s*(.*?)>/os);
   			push (@pstack,$tparam);
   			
  			
  		}
  		for (@intxt) {
  			
  			my $ttts=time();
  			
   			(my $ztag, my $ztagdata)=/^(.+?)>(.*)$/os;
   			my $rdata=pop(@stack);
   			my $xparam=pop(@pstack);
   			$rdata=~s/^\s*\n//s;
   			my $pstr;

   			my $xtra;
   			if ($#stack==0)   {
     			$xtra=pop(@stack) || '';
     			$pstr=tagparse({name=>lc($ztag),param=>" $xparam ",data=>$rdata,inner=>$inner}) || '';
     			if (lc($ztag) eq 'container' || lc($ztag) eq 'lowlevel') { 
    				unless ($felm) { $xtra=''} 
    				unless ($lelm) {$ztagdata=''}
     			}
   			}   else {
     			$xtra=pop(@stack) || '';	
     			$pstr="<cml:$ztag $xparam>$rdata</cml:$ztag>";	
   			}
   			push (@stack,"$xtra$pstr$ztagdata");
  		}
 	}
 	$cmlcalc::ENV->{READONLY}=0 if $setreadonly;
 	return pop (@stack);

}

sub tagparse {
  	my $inner; %{$inner}=%{$_[0]->{inner}};	
  	my $uinner=$_[0]->{inner};
  	
  	if ($DYNTAG{$_[0]->{name}} && $cmlmain::GLOBAL->{CACHE} && !$inner->{dyncalc}) {
		return "<cml:$_[0]->{name} $_[0]->{param}>$_[0]->{data}</cml:$_[0]->{name}>";
  	}	
  	
  	
	$_[0]->{param}=~s{_cml:(.+?)_} {
		my $xts=time();
		my $prmid=$1;
		
		#my $v=&cmlcalc::calculate({id=>$_[0]->{inner}->{objid},expr=>"p($prmid)"});
		my $v;
		$v->{value}=&cmlcalc::p($prmid,$_[0]->{inner}->{objid});
		
		if ($v->{value} eq '') {$v->{value}='NULL'}
		$v->{value}=~s/"/&quot/g;

 		my $t=time()-$xts;
   		$cmlmain::GLOBAL->{timers}->{ic}+=$t;
   		$cmlmain::GLOBAL->{timers}->{icc}++;
		
		"$v->{value}"; 		
	}iges;
    


  	$_[0]->{param}=~s{_id:(.+?)_} {
  		$v=&cmlcalc::id($1);
  		$v;
  	}iges;
  	
  	my $ts=time();	
	$_[0]->{param}=~s/_vcml:(.+?)_/$cmlcalc::VPARAM->{$_[0]->{inner}->{objid}}->{$1}/igs;
	
	
	$_[0]->{param}=~s{_(prm|cgi):(.+?)_} {
		my $cgiparam=$2;
		if ($cgiparam=~/^\!(.+)$/) {
			$v=$cmlcalc::CGIPARAM->{$1};
 			$v?0:1;
		} else {	
 			$v=$cmlcalc::CGIPARAM->{$cgiparam};
 			if ($v eq '') {$v='NULL'}
 			"$v";
		}	
	}iges;

	
	$_[0]->{param}=~s{_var:(.+?)_} {
 		$v=$_[0]->{inner}->{var}->{$1};
 		if ($v eq '') {$v='NULL'}
 		"$v";
	}iges;
	
	$_[0]->{param}=~s{_svar:(.+?)_} {
 		$v=$cmlcalc::SITEVARS->{$1};
 		if ($v eq '') {$v='NULL'}
 		"$v";
	}iges;

	$_[0]->{param}=~s{_vhost:(.+?)_} {
 		$v=$cmlcalc::SITEVARS->{VHOST}->{$1};
 		if ($v eq '') {$v='NULL'}
 		"$v";
	}iges;

	$_[0]->{param}=~s/_env:(.+?)_/$cmlcalc::ENV->{$1}/igs;


  $_[0]->{param}=~s{_envkey:(.+?)_} {
 		$v=join(';',keys %{$cmlcalc::ENV->{$1}});
 		if ($v eq '') {$v='NULL'}
 		"$v";
	}iges;


  $_[0]->{param}=~s{_envval:(.+?)_} {
 		$v=join(';',@{$cmlcalc::ENV->{$1}->{$inner->{objid}}});
 		if ($v eq '') {$v='NULL'}
 		"$v";
	}iges;

	$_[0]->{param}=~s{_global:(.+?)_} {
 		$v=$cmlmain::GLOBAL->{$1};
	}iges;


	$_[0]->{param}=~s{_mode:(.+?)_} {
 		lc($cmlcalc::CGIPARAM->{_MODE}) eq lc($1)?1:0;
	}iges;


	
	$_[0]->{param}=~s/_LISTINDEX/$_[0]->{inner}->{listindex}/igs;
	$_[0]->{param}=~s/_ITERATOR/$_[0]->{inner}->{iterator}/igs;
	$_[0]->{param}=~s/_CONTAINERINDEX/$_[0]->{inner}->{containerindex}/igs;
	$_[0]->{param}=~s/_PARENT/$_[0]->{inner}->{parent}/igs;
	$_[0]->{param}=~s/_SELF/$_[0]->{inner}->{objid}/igs;
	
	my $t=time()-$ts;
    $cmlmain::GLOBAL->{timers}->{tp}+=$t;
    $cmlmain::GLOBAL->{timers}->{tpc}++;
	
 	if ($CMLTAG{$_[0]->{name}})  	{
  		$subname="cmlparse::tag_$_[0]->{name}";
  		my $ptime=time();
  		my $v;
    		eval {$v=&$subname({param=>$_[0]->{param},data=>$_[0]->{data},inner=>$inner,uinner=>$uinner}) };
  		if ($@) { return "[<b>ERROR</b> Ошибка парсера <b>cml:$_[0]->{name}</b> $@]$_[0]->{data}" }
  		my $eptime=time()-$ptime;
  		if ($cmlcalc::ENV->{BENCHMARK} && $eptime>1) {
  			&cmlmain::message("BENCHMARK: TAG: $_[0]->{name} TIME: $eptime PARAM: $_[0]->{param}");
  		}	
  		return $v;
 	} else {
  		if ($_[0]->{data} ne '') {return "<$_[0]->{name} $_[0]->{param}>".cmlparser({data=>$_[0]->{data},inner=>$inner})."</$_[0]->{name}>";} 
  		else {return "<$_[0]->{name} $_[0]->{param} />";} 
	}
 
}

sub fetchparam {
	my ($pstr,$plist)=@_;
	my $rstr;
	
	my $ts=time();
	
	my $rplist=join('|',@$plist);

	if (ref $pstr eq 'SCALAR') {
		$$pstr=~s{(\s)($rplist)=(['"])(.*?)\3}{
			$rstr->{lc $2}=$4;
			$1;
		}ige;
	} else {
		$pstr=~s{(\s)($rplist)=(['"])(.*?)\3}{
			$rstr->{lc $2}=$4;
			$1
		}ige;    
	}	
	$$pstr=~s/(\W)html(\w+=)/$1$2/ig if ref $pstr eq 'SCALAR';
	
	my $t=time()-$ts;
    $cmlmain::GLOBAL->{timers}->{fp}+=$t;
    $cmlmain::GLOBAL->{timers}->{fpc}++;
	
	
	return $rstr;
}

sub process_csvcols () {
	push (@cmlcalc::CSVROWS,join(';',map {
		$_=~s/\r?\n/ /gs;
		$_=~s/^\s+//gs;
		$_=~s/\s+$//gs;		
		$_=~s/"/'/gs;
		$_='"'.$_.'"';
	}@cmlcalc::CSVCOLS));
	undef @cmlcalc::CSVCOLS;	
}


############################### Обработчики тегов

sub tag_flag {
	my $data=$_[0]->{data};
	my $param=$_[0]->{param};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['prm','param','expr','id','light','lightexpr']);
	my $prm=$pl->{param} || $pl->{prm};
	my $expr=$pl->{expr};
	$expr="p($prm)" if $prm;
	my $id=$pl->{id} || $inner->{objid};	
	my $iurl=$pl->{light}?$cmlmain::OKLTIMAGEURL:$cmlmain::OKIMAGEURL;
	$iurl=$cmlmain::OKLTIMAGEURL if $pl->{lightexpr} && &cmlcalc::calculate({id=>$id,expr=>$pl->{lightexpr}})->{value};
	my $value=$expr?&cmlcalc::calculate({id=>$id,expr=>$expr})->{value}:1;
	if ($cmlcalc::CSVMODE) {
		return $value?'+':'';
	} else {
    	return $value?"<image src='$iurl'/>":'';
	}	
}

sub tag_bold {
	my $data=$_[0]->{data};
	my $param=$_[0]->{param};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['prm','param','expr','id','csv']);
	my $prm=$pl->{param} || $pl->{prm};
	my $expr=$pl->{expr};
	my $bold=($prm || $expr)?0:1;
	$expr="p($prm)" if $prm;
	my $id=$pl->{id} || $inner->{objid};	
    my $result=cmlparser({data=>$data,inner=>$inner});
    $bold=1 if cmlcalc::calculate({id=>$id,expr=>$expr})->{value};
    push (@cmlcalc::CSVCOLS, $result ) if $pl->{csv}; 
    return $result if $cmlcalc::CSVMODE;
    return $bold?"<b>$result</b>":$result;
}

sub tag_csvcol {
	my $data=$_[0]->{data};
	my $param=$_[0]->{param};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['hidden']);
	my $value=cmlparser({data=>$data,inner=>$inner});
	push (@cmlcalc::CSVCOLS, $value);
	return $pl->{hidden}?undef:$value;
}

sub tag_csvrow {
	my $data=$_[0]->{data};
	my $param=$_[0]->{param};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['hidden']);
	my $value=cmlparser({data=>$data,inner=>$inner});
	process_csvcols();
	return $pl->{hidden}?undef:$value;
}

sub tag_table {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['scrollheight']);
	my $body=cmlparser({data=>$data,inner=>$inner});
	$cmlcalc::ROWID=0;
	my $ttext;
	$ttext.='<div id="scroller" class="scrollable_table">' if $pl->{scrollheight};
	$ttext.="<table $param>$body</table>";
	$ttext.="</div><script type='text/javascript'>render_scrollable_table('scroller', $pl->{scrollheight});</script>" if $pl->{scrollheight}; 
	return $ttext;
}


sub tag_tr {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['colorswitcher','csv','header','colorexpr','hidden']);
	my $id=$inner->{objid};
	if ($pl->{'colorswitcher'}) {
		my @colors=split(';',$pl->{'colorswitcher'});
		my $index=$cmlcalc::ROWID % scalar @colors;
		$param.=" bgcolor='$colors[$index]'";
	} elsif ($pl->{'colorexpr'}) {
		my $clr= &cmlcalc::calc($id,$pl->{colorexpr});
		$param.=" bgcolor='$clr'";
	}
	my $body=cmlparser({data=>$data,inner=>$inner});
	$cmlcalc::ROWID++;
	if ($pl->{csv}) {
		process_csvcols();
	}
	my $clstr=$pl->{hidden}?'style="display:none"':'';	
	my $trstr;
	$trstr.='<thead>' if $pl->{header};
	$trstr.="<tr $param $clstr>$body</tr>";
	$trstr.='</thead>' if $pl->{header};
	return $trstr;
}


sub tag_td {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['th','csv','csvmoney','hidden','hiddenexpr','colorexpr','color','fontcolorexpr']);
	my $id=$inner->{objid};	
	my $body=cmlparser({data=>$data,inner=>$inner});
	my $tg=($pl->{th} || $inner->{th})?'th':'td';
	if ($pl->{csv} || $pl->{csvmoney}) {
		if ($pl->{csvmoney}) {
			$body=sprintf('%.2f',$body); $body=~s/\./,/g;  
		}
		push (@cmlcalc::CSVCOLS, $body);
	}	
	my @styles;
	my $clstr;
	if ($pl->{hidden}) {
		push (@styles,'display:none');
	} elsif ($pl->{hiddenexpr}) {
		push (@styles,'display:none') if cmlcalc::calculate({id=>$id,expr=>$pl->{hiddenexpr}})->{value};
	} elsif ($pl->{colorexpr} || $pl->{color}) {
		my $clr= $pl->{color} || &cmlcalc::calc($id,$pl->{colorexpr});
		push (@styles,"background-color:$clr");
	}
	if ($pl->{fontcolorexpr}) {
		my $clr= &cmlcalc::calc($id,$pl->{fontcolorexpr});
		push (@styles,"color:$clr")
	}	
	$clstr='style="'.join(';',@styles).'"' if @styles; 
	return "<$tg $param $clstr>$body</$tg>";
}

sub tag_th {
	my $inner; %{$inner}=%{$_[0]->{inner}};
	$inner->{th}=1;
	return tag_td({data=>$_[0]->{data},inner=>$inner,param=>$_[0]->{param}})
}

=head
pagination tag - need for simple list splitting 


EXAMPLE:
<cml:pagination limit='20' expr='lowlist()'/>
...
<cml:list  expr='lowlist()'  pagination='1'>
...
</cml:list>

=cut
sub tag_pagination {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};	
	my $pl=fetchparam(\$param,[
		'page','limit','container',
	]);
	delete $pl->{page} if $pl->{page} eq 'NULL';
	my $container=$pl->{container} || $pl->{limit};
	my $pid=$cmlcalc::CGIPARAM->{pagenum} || $cmlcalc::CGIPARAM->{page} || $pl->{page} || 1;
	my $rtext = qq(
		<cml:list container='$container' $param>
			<cml:if expr='_CONTAINERINDEX eq $pid'> <cml:text expr='_CONTAINERINDEX'/> </cml:if>
			<cml:else>
				<cml:a pagenum='_CONTAINERINDEX'><cml:text expr='_CONTAINERINDEX'/></cml:a>
			</cml:else>
			<cml:container/>
		</cml:list>
	);
	$_[0]->{uinner}->{page}=$pid;
	$_[0]->{uinner}->{pagelimit}=$container;
	return cmlparser({data=>$rtext,inner=>$inner});
	
	
}

sub tag_dynamic {
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	if ($inner->{dyncalc} || !$cmlmain::GLOBAL->{CACHE}) {
		return cmlparser({data=>$data,inner=>$inner});
	} else {
		return $data;
	}
}

sub tag_groupheader {
	return $_[0]->{inner}->{needheader}?cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}}):'';
}


sub tag_menu	{
	
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	
	my $pl=fetchparam($param,['vertical','horisontal','border']);
    $inner->{horisontal}=1 if $pl->{horisontal};
    my $bstr=$pl->{border}?" border='$pl->{border}'":'';
    return "<table $bstr>".cmlparser({data=>$_[0]->{data},inner=>$inner})."</table>";
}

sub tag_menuitem	{
	
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	
	my $pl=fetchparam($param,[
		'action','key','href','icohref','id','prm','param',
		'piclist','filelist','delete','head','listprm',
		'childlistprm','childukey', 'ukey', 'childlink', 'link',
		'orderby','ordertype','readonly','delmethod','templatekey',
		'addupkey','addlink','deleteexpr','addmethod','csv','value',
		'template','deleteid','notdel','icon'
	]);
	my $id=$pl->{id} || $inner->{objid};
	
	my $targetstr="target='adminmb'";
	my $targetstr_ico=$targetstr;
	my $forced_href;
	my $forced_target;
	
	unless ($pl->{action}) {
		$pl->{action}=$pl->{head}?'LISTEDIT':'EDIT';
	}	   
	
	if ($pl->{'key'}) {
		&cmlmain::checkload({key=>$pl->{'key'}});
		$id=$cmlmain::nobj->{$pl->{'key'}}->{id};
	}
	
	if ($pl->{action} eq 'EDITARTICLE' ) {
   	 	&cmlmain::checkload({id=>$id});
		my $tid=$cmlmain::lobj->{$id}->{upobj};
		my $prm=$pl->{prm} || $pl->{param} || 'PAGETEMPLATE';
		my $piclistprm=$pl->{'piclist'} || 'PICLINKS';
		my $filelistprm=$pl->{'filelist'} || 'FILELINKS';
		my $body=$pl->{'template'} || 'BASEARTICLE';
		$pl->{href}="body=$body&editprm=$prm&piclistprm=$piclistprm&filelistprm=$filelistprm";
	} elsif ($pl->{action} eq 'MENULIST') {
		my $ukey=$pl->{ukey} || &cmlcalc::p(_KEY,$id);
		my $upkey=$pl->{upkey} || &cmlcalc::p(_KEY,&cmlcalc::uobj($id));
		if ($ukey && $ukey ne 'NULL') {
			my $menutemplate=&cmlcalc::id("LISTMENU_$ukey")?"LISTMENU_$ukey":'BASEMENULIST';
			$pl->{href}="menu=$menutemplate&ukey=$ukey";
			for (qw (listprm childlistprm childukey childlink link orderby ordertype readonly delmethod templatekey notdel)) {
				$pl->{href}.="&$_=$pl->{$_}" if $pl->{$_};
			}
			$targetstr='';
			unless ($pl->{icohref}) {
				if ($pl->{'childukey'} && $pl->{'key'}) {
					$pl->{icohref}="body=LISTEDIT_$pl->{key}";
				} else {
					$pl->{icohref}=$pl->{listprm}?"body=EDIT_$upkey":"body=LISTEDIT_$ukey"
				}
				for (qw (orderby ordertype)) {
					$pl->{icohref}.="&$_=$pl->{$_}" if $pl->{$_};
				}
			}		
		} else {
			my $bodykey=$pl->{templatekey} && $pl->{templatekey} ne 'NULL'?$pl->{templatekey}:'EDIT_'.&cmlcalc::p(_KEY,&cmlcalc::uobj($id));
			$pl->{href}="body=$bodykey";
			$pl->{icohref}="body=$bodykey" unless $pl->{icohref};

		}
			
	} elsif ($pl->{action} eq 'LISTEDIT' || $pl->{action} eq 'LISTVIEW') {
		my $ukey=$pl->{ukey} || &cmlcalc::p(_KEY,$id);
		$pl->{href}.='&' if $pl->{href};
		$pl->{href}.="body=LISTEDIT_${ukey}&ukey=$ukey";
		$pl->{href}.="&readonly=1" if $pl->{action} eq 'LISTVIEW';
		$pl->{href}.="&csv=1" if $pl->{csv};		
		for (qw (orderby ordertype listprm link)) {
			$pl->{href}.="&$_=$pl->{$_}" if $pl->{$_};
		}
	} elsif ($pl->{action} eq 'EDIT' || $pl->{action} eq 'VIEW') {
		my $ukey=$pl->{ukey} || &cmlcalc::p(_KEY,$id);
		$pl->{href}.='&' if $pl->{href};
		$pl->{href}.="body=EDIT_${ukey}" if $ukey;
		$pl->{href}.="&readonly=1" if $pl->{action} eq 'VIEW';
	} elsif ($pl->{action} eq 'LOGOUT') {
		return undef if $ENV{HTTP_USER_AGENT}=~/MSIE/;
		$forced_href=CGI::url(-path_info=>1)."?httplogout=1";
		$forced_href=~s/(http:\/\/)/${1}logout\@/;
	}elsif ($pl->{action} eq 'HISTORY') {
		$forced_href="/cgi-bin/vcms/cmlsrv.pl?action=viewallhistory&objid=$id";
		$forced_target=' target="_blank" ';
	} elsif ($pl->{action} eq 'DBBACKUP') {
		$forced_href="/cgi-bin/vcms/cmlsrv.pl?action=export&area=db";
	}
	
	
	my $key=$pl->{key} || &cmlcalc::p(_KEY,$pl->{head}?$id:&cmlcalc::uobj($id));
    
    if ($cmlmain::nobj->{$key}->{type} eq 'L') {
    	my $upper=$cmlmain::nobj->{$key}->{upobj};
    	$key=$cmlmain::obj->{$upper}->{key};
    }


	my $href='?'. ($pl->{href} || "body=$pl->{action}_$key");
	my $icohref='?'. ($pl->{icohref} || $pl->{href} || "body=$pl->{action}_$key");
	$inner->{objid}=$id;	
	
	my $itext=cmlparser({data=>$data,inner=>$inner});
	unless ($itext) {
		$itext=&cmlcalc::p(_NAME,$id);
	}
	$href.="&id=$id";	 
	$icohref.="&id=$id";	 
	$itext='пустой' unless $itext;
	$itext="<b>$itext</b>" if $pl->{head};
	my $hcol=$pl->{head}?'#FFFFFF':'#dedede';
	my $mstr=$pl->{delmethod}?"method='$pl->{delmethod}'":'';
	$mstr.=" deleteid='$pl->{id}" if $pl->{id};
	my $dtxt=($pl->{delete} || ($pl->{deleteexpr} && &cmlcalc::calc($id,$pl->{deleteexpr})))?
		"<cml:deletebutton $mstr/>":'<img src="/cmsimg/0.gif" width="16" height="16" alt="" border="0">';
	my $estr=&cmlmain::enc('Редактировать');
	my $addlink;
	if ($pl->{addupkey}) {
		$addlink=qq(<td bgcolor="$hcol" width="16"><cml:actionlink action='add' upkey='$pl->{addupkey}' link='$pl->{addlink}' method='$pl->{addmethod}'><img src='$cmlmain::PLUSBUTTONURL' border='0'></cml:actionlink></td>);
	}else {
		$addlink=qq(<td bgcolor="$hcol"></td>);
	}
	
	undef $targetstr if $cmlcalc::ENV->{NOFRAMES};
	undef $targetstr_ico if $cmlcalc::ENV->{NOFRAMES};
	$targetstr=$forced_target if $forced_target;
	$targetstr_ico=$forced_target if $forced_target;
	
	$href=$pl->{value} if $pl->{value};
	
	if ($forced_href) {
		$href=$forced_href;
		$icohref=$forced_href;
	}
	
	my $mtext;
	
	if ($cmlmain::GLOBAL->{NEWSTYLE}) {
		my $icon=$pl->{icon} || 'icon-edit';
		$mtext=qq(<li><a href="$href"><span class="ico"><i class="$icon"></i></span><span class="text">$itext</span></a></li>)
	} else {
		$mtext=$pl->{action} eq 'NO'?
		qq(
			<tr>
			<td bgcolor="#FFFFFF" width="16">&nbsp;</td>
			<td bgcolor="#FFFFFF" width="100%" colspan="2">$itext</td>
			<td bgcolor="#FFFFFF" width="16">&nbsp;</td>
			</tr>
		):qq(
			<tr>
			<td bgcolor="#FFFFFF" width="16"><a href="$icohref" $targetstr_ico><img src="/cmsimg/edit.png" alt="$estr" border="0"/></a></td>
			<td bgcolor="$hcol" width="100%" colspan="2"><a href="$href" $targetstr>$itext</a></td>
			$addlink
			<td bgcolor="$hcol" width="16">$dtxt</td>
			</tr>
		);
		$mtext="<td><table>$mtext</table></td>" if $inner->{horisontal};
	}	
	return cmlparser({data=>$mtext,inner=>$inner});
}


sub tag_tree	{
	
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $id=$inner->{objid};
	my $body;
	my $orderby;
	my $ordertype;
	my $ltype='lowlist';
	my $lowexpr;
	my $nobottom;
	

	
	
     $inner->{udata}=$data;
        

        
    if ($param=~s/(\W)type=(['"])(.+?)\2/$1/i)      {$ltype=$3 }     
  	if ($param=~s/(\W)orderby=(['"])(.+?)\2/$1/i)   {$orderby=$3 } 
  	if ($param=~s/(\W)ordertype=(['"])(.+?)\2/$1/i) {$ordertype=$3 } 
  	if ($param=~s/(\W)nobottom=(['"])(.+?)\2/$1/i)  {$nobottom=1 } 
  	

  if ($ltype eq 'lowlist') {$lowexpr='lowlist()'}
  elsif ($ltype eq 'lowlevel') {$lowexpr='lowlevel()'}

           

	my $list=&cmlcalc::calculate({id=>$id,expr=>$lowexpr});
	
	  
	
	my @splist=split(/\s*;\s*/,$list->{value});

  if ($nobottom) {  	@splist=grep { /^u\d+$/ } @splist	}	


 		if ($orderby) {
  			if ($cmlmain::prm->{$orderby}->{type} eq 'DATE' || $cmlmain::prm->{$orderby}->{type} eq 'NUMBER' || $orderby eq '_INDEX') {
  				@splist=sort {
  					&cmlcalc::calculate({id=>$a,expr=>"p($orderby)"})->{value} <=> &cmlcalc::calculate({id=>$b,expr=>"p($orderby)"})->{value}; 
  				} @splist;
  			} else {
  				@splist=sort {
  					&cmlcalc::calculate({id=>$a,expr=>"p($orderby)"})->{value} cmp &cmlcalc::calculate({id=>$b,expr=>"p($orderby)"})->{value}; 
  				} @splist;
  			}		
  		}	
  		
	if (lc $ordertype eq 'desc') {		@splist=reverse @splist 	}

  
      
	$inner->{level}++;
	for (my $i=0;$i<=$#splist;$i++) {
			
  			if ($i==0) 	   {$felm=1} else {$felm=0}
  			if ($i==$#splist)  {$lelm=1} else {$lelm=0}
  			$inner->{objid}=$splist[$i];
  			$body.=cmlparser({data=>$data,inner=>$inner,firstelm=>$felm,lastelm=>$lelm}).tag_tree({data=>$data,inner=>$inner,param=>$_[0]->{param}});
        }
        return $body;

}

sub tag_lowlevel  {
	
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
        return cmlparser({data=>$data,inner=>$inner});

}	


sub tag_select {
	my $param=$_[0]->{param};
  	my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
  	my $sexpr;
    
  	my $expr;
  	my $defopt;
  
  	my $listparam=$param;
  	my $pl=fetchparam(\$param,[
  		'multiple','single','id',
  		'selexpr','selected',
  		'param','prm','prmexpr','expr',
  		'optionid','name','optionparam',
  		'defoptvalue','defoptname','nodefopt',
  		'elementid','csv','notnull','popup','template','lowlist','title'
  	]);
  	my $multiple=$pl->{'multiple'}?'multiple':'';
  	my $id=$pl->{'id'} || $inner->{objid};
  	my $access_denied=$cmlcalc::ENV->{READONLY};
	if ($pl->{'selexpr'}) {
		$sexpr=$pl->{'selexpr'}
	} elsif ($pl->{'selected'}) {
		$sexpr="p($pl->{'selected'})";
	}
  	my $prm=$pl->{'param'} || $pl->{'prm'};
  	my $prmname;
  	if ($pl->{'prmexpr'}) {
    		$prm=&cmlcalc::calculate({id=>$id,expr=>$pl->{'prmexpr'}})->{value};
  	}   
	if ($prm) {  
		if ($cmlmain::prm->{$prm}->{extra}->{hasaccess}) {
			$access_denied=1  if !(&cmlcalc::calculate({id=>$id,expr=>$cmlmain::prm->{$prm}->{extra}->{hasaccess}})->{value}); 
		}
		
	  	$sexpr||="p($prm)";
	  	$expr=$cmlmain::prm->{$prm}->{extra}->{formula};
	  	$inner->{expr}=$expr;
	  	$multiple='multiple' if $cmlmain::prm->{$prm}->{extra}->{single} ne 'y';
	  	$prmname=$cmlmain::prm->{$prm}->{name};
	} 
	if ($pl->{expr}) {
		$inner->{expr}=$pl->{expr};
	}
	undef $multiple if $pl->{'single'};
	
	my $optionid=$pl->{'optionid'} || '_ID';
	my $optionparam=$pl->{'optionparam'} || '_NAME';
	
	
  	my $name;
	if ($pl->{name}) {
		$name=$pl->{name}
	} elsif ($inner->{matrix}) {
		$name="_o${id}_p${prm}";
	} else {
		$name="_p$prm";
	}

	my $defoptvalue=$pl->{'defoptvalue'};
	if ($pl->{'defoptname'} ne '') {
		$defopt="<option value='$defoptvalue'>$pl->{'defoptname'}</option>"
	}  elsif (!$multiple && !$pl->{'nodefopt'})  {
		$defopt=&cmlmain::enc("<option value='0'>Не задан</option>")
}
	
	undef $inner->{selectedlist};
  	if (defined $sexpr) {
  		my $v=&cmlcalc::calculate({id=>$id,expr=>$sexpr})->{value} || '';
  		push (@cmlcalc::CSVCOLS, &cmlcalc::p(_NAME,$v) ) if $pl->{csv};
  		for (split(';',$v)) {$inner->{selectedlist}->{$_}=1}

  	} elsif ($cmlcalc::CGIPARAM->{$name}) {
  	 	$inner->{selectedlist}->{$cmlcalc::CGIPARAM->{$name}}=1
  	} else {
  		$inner->{selectedlist}->{$id}=1;
  	}	
        
  	unless ($data) {
  		$data="<cml:option param='$optionid'><cml:text param='$optionparam'/></cml:option>";
  	}
  	
  	if ($pl->{popup}) {
  		my $template=$pl->{template} || ($cmlmain::GLOBAL->{NEWSTYLE}?'NSPOPUPSELECTOR':'POPUPSELECTOR');
  		my $singlestr=$cmlmain::prm->{$prm}->{extra}->{single} eq 'y'?'&single=1':'';
  		my $lowliststr=$pl->{lowlist}?"&lowlist=$pl->{lowlist}":'';
  		my $ch_str=&cmlmain::enc('Изменить');
  		my $title=$pl->{title} || $ch_str;
  		if ($cmlmain::GLOBAL->{NEWSTYLE}) {
  			my $svalue=$v=&cmlcalc::calculate({id=>$id,expr=>"p(_NAME,p($prm))"})->{value}; 
  			$fn_name=vCMS::Config::Get('jquery')?'openBootstrapPopupJq':'openBootstrapPopup';
  			return qq(
  				<div id='selDiv${id}${prm}'>$svalue</div>
  				<a href='#' onclick="${fn_name}('?popupview=$template&id=$id&selectorprm=${prm}${lowliststr}${singlestr}',{title:'$title'});return false">$ch_str</a>
  			)
  		} else {
			return qq(<a href='#' onclick="openPopup('?popupview=$template&id=$id&selectorprm=${prm}${lowliststr}${singlestr}',{title:'$title',width:600,height:400});return false">$ch_str</a>)
  		}		
  	}
  	
  	
  	my $hd=$multiple?"<input type='hidden' value='0' name='$name'>":'';
  	my $idtxt=$pl->{elementid}?"id='$pl->{elementid}'":"";
  	my $nnstr=$pl->{notnull}?"notnull='1'":'';
  	my $pnstr=$prmname?"prmname='$prmname'":'';
  	my $itext=$_[0]->{data}?
  		cmlparser({data=>$_[0]->{data},inner=>$inner}):
  		tag_list({data=>$data,inner=>$inner,param=>$param});
  	return $access_denied?&cmlcalc::p(_NAME,&cmlcalc::p($prm,$id)) :"$hd<select name='$name' $param $multiple $idtxt $nnstr $pnstr>$defopt\n$itext</select>";

}	



sub tag_radioselect {
	my $param=$_[0]->{param};
  	my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
  	my $sexpr;
  	my $id=$inner->{objid};
  	
  	my $prm;
  	my $name;  
  	my $expr;
  	my $optionid;
  	if ($param=~s/(\W)selected=(['"])(.+?)\2/$1/i)          {$sexpr="p($3)"}
  	if ($param=~s/(\W)(param|prm)=(['"])(.+?)\3/$1/i)      {	
  		$prm=$4; 
	  	$sexpr="p($prm)";
	  	$expr=$cmlmain::prm->{$prm}->{extra}->{formula};
	  	$param.=" expr='$expr'";
	}
	if ($param=~s/(\W)optionid=(['"])(.+?)\2/$1/i)          {$optionid=$3} 
	else {$optionid='_ID'} 
	if ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)       {$name=$3   }
  	else {$name="_o${id}_p{$prm}"}
  	$inner->{name}=$name;
  	if (defined $sexpr) {
  		$inner->{selected}=&cmlcalc::calculate({id=>$id,expr=>$sexpr})->{value};
  	}	
  	unless ($data) {$data="<cml:radiobutton param='$optionid'><cml:text param='_NAME'/></cml:radiobutton><br>"}
  	return tag_list({data=>$data,inner=>$inner,param=>$param});
}	



sub tag_checkboxselect {
	my $param=$_[0]->{param};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
  	my $sexpr;
  	my $id=$inner->{objid};
  	my $expr;
  	my $pl=fetchparam(\$param,['checked','param','prm','optionid','name']);
  	$sexpr="p($pl->{checked})" if $pl->{checked};
    my $prm=$pl->{prm}||$pl->{param};
    if ($prm) {   	
	  $sexpr="p($prm)";
	  $expr=$cmlmain::prm->{$prm}->{extra}->{formula};
	  $param.=" expr='$expr'";
	}
    my $data="<cml:checkbox id='$id' param='$prm' value='_cml:_ID_'><cml:text param='_NAME'/></cml:checkbox><br/>";
    return "<input type='hidden' value='0' name='_o${id}_p${prm}'>".tag_list({data=>$data,inner=>$inner,param=>$param});
}	




sub tag_list  	{
		my $param=$_[0]->{param};
  		my $data=$_[0]->{data};
  		my $inner; %{$inner}=%{$_[0]->{inner}};
  	

  
  		my $pkey;
  		my $id; 
  		my $expr;
  		my $uid;
  		my $ukey;
  		my $key;
  		my $container;
		my $body;  	
		my $limit;
		my $start;
		my $notop;
		my $filter;
		my $filterexpr;
		my @filarray;
		my @filexparray;
  		 
 	
  		my $pl=fetchparam($param,[
  			'selected','selexpr',
  			'orderby','ordertype','orderexpr',
  			'limit','start','page','container',
  			'headerprm','headerexpr','var','tbody','pagination',
  			'switcher'
  		]);
  		$container=$pl->{'container'}||1;
  		
  		$body.='<tbody>' if $pl->{tbody};
  		
  		$limit=$pl->{pagination}?$_[0]->{uinner}->{pagelimit}:$pl->{limit};
  		if ($pl->{start}) {
  			$start=$pl->{start}
  		} elsif ($pl->{page} && $pl->{page} ne 'NULL') {
  			$start=($pl->{page}-1)*$limit
  		} elsif ($pl->{pagination}) {
  			$start=($_[0]->{uinner}->{page}-1)*$_[0]->{uinner}->{pagelimit}
  		} else {
  			$start=0;
  		}
  		
		my $orderexpr;
		if ($pl->{orderexpr}) {
			$orderexpr=$pl->{orderexpr}
		} elsif ($pl->{orderby} && $pl->{orderby} ne 'NULL') {
			$orderexpr="p($pl->{orderby})";
		} else {
			$orderexpr="p(_INDEX)"
		}	
  	

		$param=~s {(\W)filter(\d*)=(['"])(.*?)\3} {
			$filarray[0+$2]=$4;
			"$1";
		}iges;
    

		$param=~s {(\W)filterexpr(\d*)=(['"])(.*?)\3} {
			$filexparray[0+$2]=$4;
			"$1";
		}iges;

    $filarray[0]=1 if !defined $filarray[0] && defined $filexparray[0];



  	
  	if ($param=~s/(\W)paramtab=(['"])(.+?)\2/$1/i)          {
  				my $tabparam=$3;
  		 		my @splist=@{$inner->{matrix}->{dim}->{$tabparam}->{vals}};
 		
 					unless ($limit) {$limit=$#splist+1}
  				for (my $i=0;$i<$limit;$i++) {
  						my $matrix=$inner->{matrix};
  						$matrix->{dim}->{$tabparam}->{current}=$splist[$i];
  						$matrix->{tabkey}="t_$matrix->{id}_$matrix->{param}_".join('_',map {$_=$matrix->{dim}->{$_}->{current}} split(/\s*;\s*/,$cmlmain::prm->{$matrix->{param}}->{extra}->{param}));
  						if (($i%$container)==0) {$felm=1} else {$felm=0}
  						if ((($i%$container)==($container-1)) || ($i==$limit) ) {$lelm=1} else {$lelm=0}
  						$inner->{objid}=$splist[$i];
  						$body.=cmlparser({data=>$data,inner=>$inner,firstelm=>$felm,lastelm=>$lelm});
					}  

		} else {  	
  	
  		if ($param=~s/(\W)param=(['"])(.+?)\2/$1/i)          {$pkey=$3; $expr="p('$pkey')" }
  		elsif ($param=~s/(\W)prm=(['"])(.+?)\2/$1/i)            {$pkey=$3; $expr="p('$pkey')" }
  		elsif ($param=~s/(\W)expr=(['"])(.+?)\2/$1/i)        {$expr=$3}
  		elsif (defined $inner->{expr})                       {$expr=$inner->{expr}}
  	
  	
  		if ($param=~s/(\W)uid=(['"])(.+?)\2/$1/i)      {$uid=$3}
  		elsif ($param=~s/(\W)id=(['"])(.+?)\2/$1/i)    {$id=$3}
  		elsif ($param=~s/(\W)ukey=(['"])(.+?)\2/$1/i)  {$ukey=$3}
  		elsif ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)   {$key=$3}
  		else     {$id=$inner->{objid}}
  	
  	  $inner->{parent}=$id; 
  	
  		if ($param=~s/(\W)notop=(['"])(.+?)\2/$1/i)      {$notop=1}
  		
  		
			my $listval;
			if ($param=~s/(\W)value=(['"])(.+?)\2/$1/i)      {
				$listval=$3;
			} else {
				my $v=&cmlcalc::calculate({id=>$id,expr=>$expr,uid=>$uid,ukey=>$ukey,key=>$key});
				$listval=$v->{value};
				&cmlmain::buildlist($v->{value}); 
			}

  		
  		
			my $felm;
			my $lelm;
			
			$listval='___DUMMY___' if $inner->{debug} && !$listval; 
			my @splist=split(/\s*;\s*/,$listval);
		  if ($notop)  {  	@splist=grep { /^\d+$/ } @splist	}	
		  
	  
	  
	  	for (@filarray) {
	  		my $filter=$_;
	  		my $filterexpr=shift(@filexparray);
		  	if ($filter && $filter ne 'NULL') { 	
		  		@splist=grep { 	&cmlcalc::calculate({id=>$_,expr=>$filterexpr})->{value}  } @splist	
		  	}	
		}
			
		if ($filterexpr) {
		  	@splist=grep { 	&cmlcalc::calculate({id=>$_,expr=>$filterexpr})->{value}  } @splist	
		}	
		my $orderby=$pl->{orderby} || '';
		unless ($orderby eq '_MANUAL') {
			my $ordertype=$cmlmain::prm->{$orderby}->{type} || '';
			my %oh;
			my %oi;
			
			for (@splist) {
				$oh{$_}=&cmlcalc::calculate({id=>$_,expr=>$orderexpr})->{value};
				$oi{$_}=$orderexpr eq 'p(_INDEX)'?$oh{$_}:&cmlcalc::calculate({id=>$_,expr=>'p(_INDEX)'})->{value};
			}	
			
			
			if ( $orderexpr eq 'p(_INDEX)' || $ordertype eq 'DATE' || $ordertype eq 'NUMBER') {
  				@splist=sort {
  					$oh{$a}==$oh{$b}?$oi{$a}<=>$oi{$b}:$oh{$a}<=>$oh{$b};
  				} @splist;
  			} else {
  				@splist=sort {
  					$oh{$a} eq $oh{$b}?$oi{$a}<=>$oi{$b}:$oh{$a} cmp $oh{$b}; 
  				} @splist;
  			}		
		}		
  		
		if (lc $pl->{ordertype} eq 'desc') {
			@splist=reverse @splist; 
		}
		
		unless ($limit) {$limit=$#splist+1}
		my $sdata; my $cdata; my $edata; my $iscont;
		if ($container>1) {
			if ($data=~/^(.+?)<cml:container.+?>(.+)<\/cml:container>(.+?)$/is) {
  					$sdata=$1;
  					$cdata=$2;
  					$edata=$3;
  					$iscont=1;
			} elsif ($data=~/^(.+)<cml:container.+?\/>(.+)$/is) {
  					$sdata=$1;
  					$edata=$2;
  					$iscont=1;
			}				
		}
		
		my $conid=1;
		my $groupval;
  		for (my $i=$start;$i<$limit+$start;$i++) {
  			
  			
  			next if $splist[$i] eq 'NULL';
  			last if $i>$#splist;

  			
 			$inner->{objid}=$splist[$i];
 			$cmlcalc::ENV->{$pl->{var}}=$splist[$i] if $pl->{var};
 			if ($pl->{switcher}) {
 				my @colors=split(';',$pl->{'switcher'});
 				$cmlcalc::ENV->{LISTSWITCHER}=$colors[$i % scalar @colors];
 			} 			

 			undef $inner->{needheader};
 			if ($pl->{headerprm} || $pl->{headerexpr}) {
 				my $hexpr=$pl->{headerprm}?"p($pl->{headerprm})":$pl->{headerexpr};
 				my $nval=&cmlcalc::calculate({id=>$inner->{objid},expr=>$hexpr})->{value};
 				if ($nval ne $groupval) {
 					$inner->{needheader}=$nval;
 					$groupval=$nval;
 				}
 			}

 			
  			$inner->{listindex}=$i+1;
  			if ($pl->{selected} && $splist[$i] eq $pl->{selected}) {
  				$inner->{selected}=1 ;
  			} elsif ($pl->{selexpr} && &cmlcalc::p($pl->{selexpr},$splist[$i]))	{
  				
  				$inner->{selected}=1 ;
  			} elsif ($inner->{selectedlist}->{$splist[$i]})	{
  				$inner->{selected}=1 ;	
  			} else {
  				undef $inner->{selected}
  			}	
  			if ($iscont) {
  				$inner->{containerindex}=$conid;
  				my $xdata=$cdata;
  				if (($i%$container)==0) {$xdata="$sdata$xdata"}
  				if ((($i%$container)==($container-1)) || ($i==$limit-1) ) {$xdata="$xdata$edata";$conid++}
  				$body.=cmlparser({data=>$xdata,inner=>$inner});
  			}else {
  				$cmlcalc::ENV->{LASTINDEX}=($i==$#splist)?1:0;
  				$body.=cmlparser({data=>$data,inner=>$inner});
  			}	
		}	  
	}
	$body.='</tbody>' if $pl->{tbody};
  	return  $body;
  
  	 
}	

sub tag_setvar {
	my $param=$_[0]->{param};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $varvalue;
	my $id=$inner->{objid};
	my $pl=fetchparam(\$param,['value','param','name','expr']);
	$varvalue=$pl->{value} if defined $pl->{value};
	$varvalue=&cmlcalc::calculate({id=>$id,expr=>"p($pl->{param})"})->{value} if $pl->{param};	
	$varvalue=&cmlcalc::calculate({id=>$id,expr=>$pl->{expr}})->{value} if $pl->{expr};
	
	$inner->{var}->{$pl->{name}}=$varvalue;
	$cmlcalc::ENV->{$pl->{name}}=$varvalue;
	return cmlparser({data=>$_[0]->{data},inner=>$inner});
}	

sub tag_var {
	my $param=$_[0]->{param};
	
	my $varname;
	if      ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)        {	$varname=$3    }
	
	return $_[0]->{inner}->{var}->{$varname};
}	

sub tag_auth
{
	my $param=$_[0]->{param};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
  	my $pl=fetchparam($param,['prm','id','authframe']);
  	my $id=$pl->{id} || $inner->{objid};
	if (!$cmlcalc::ENV->{'AUTHUSERID'}) {
			return $pl->{'authframe'}?cmlparser({data=>"<cml:include key='AUTH'/>",inner=>$inner}):'';
	} elsif ($pl->{'prm'}) {
		my $uid=&cmlcalc::calculate({id=>$id,expr=>"p($pl->{'prm'})"})->{value};
		if ($uid ne $cmlcalc::ENV->{'AUTHUSERID'}) {
			return cmlparser({data=>"<cml:include key='FORBIDDEN'/>",inner=>$inner});
		}
	} else {
		$id=$cmlcalc::ENV->{'AUTHUSERID'};
	}	
	$inner->{objid}=$id;
    return cmlparser({data=>$_[0]->{data},inner=>$inner})
}

sub tag_noauth
{
	my $inner; %{$inner}=%{$_[0]->{inner}};
	return !$cmlcalc::ENV->{'AUTHUSERID'}?cmlparser({data=>$_[0]->{data},inner=>$inner}):'';
}


sub tag_acc
{
		my $param=$_[0]->{param};
		my $inner; %{$inner}=%{$_[0]->{inner}};
		my $pl=fetchparam($param,[
			'var','id','prm','param','expr','value'
		]);	
		my $id=$pl->{id} || $inner->{objid};
		my $value;
		my $expr;
		$expr=$pl->{expr} if $pl->{expr};
		$expr="p($pl->{prm})" if $pl->{prm};
		$expr="p($pl->{param})" if $pl->{param};
		
		$value=$pl->{value} if $pl->{value};
		$value=&cmlcalc::calculate({id=>$id,expr=>$expr})->{value} if $expr;
		
		$cmlcalc::ENV->{$pl->{var}}.=';' if $cmlcalc::ENV->{$pl->{var}};
		$cmlcalc::ENV->{$pl->{var}}.=$value;
	    return undef;
}

sub tag_document
{
	return cmlparser({data=>$_[0]->{data}});	
}


sub tag_use
{
	my $param=$_[0]->{param};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	my $id;
	my $key;
	my $paramname;

	my $matrix;
	
	
	my $pl=fetchparam($param,[
		'id','idcgi','namecgi',
		'uname','key','param','prm',
		'paramtab','idexpr',
		'validupkey','validupexpr','validexpr','var','env',
		'readonly','readonlyexpr','value','expr'
	]);
	
	if      ($pl->{id} && $pl->{id} ne 'NULL')       {
		$id=$pl->{id};     
		if (lc $id eq 'matrix') {$id=$inner->{matrix}->{tabkey} }
	} elsif    ($pl->{idcgi})    {
		$id=$cmlcalc::CGIPARAM->{$pl->{idcgi}};
	} elsif    ($pl->{namecgi})  {
		$key=param($pl->{namecgi});
	  	&cmlmain::checkload({key=>$key});
          	$id=$cmlmain::nobj->{$key}->{ind};
          	unless ($id)  {return "[ Use ERROR! $key NOT FOUND ]"}
	} elsif  ($pl->{uname})  {
		$key=$pl->{uname};
          	$id='u'.$cmlmain::nobj->{$key}->{ind};
	} elsif ($pl->{key})  {
		$key=$pl->{key};
		&cmlmain::checkload({key=>$key});
    		$id=$cmlmain::nobj->{$key}->{id};
	} elsif ($pl->{idexpr}) {
		$id=$inner->{objid} unless $id;
		my $v=&cmlcalc::calculate({id=>$id,expr=>$pl->{idexpr}});
		$id=$v->{value};
	} else     {
		$id=$inner->{objid}
	}
	
	
	if       ($pl->{param} || $pl->{prm})       {
		$paramname=$pl->{param} || $pl->{prm};
		if ($cmlmain::prm->{$paramname}->{type} eq 'MATRIX')  {
			undef $matrix;
		   	$matrix->{id}=$id;
		   	$matrix->{param}=$paramname;
                        for (split(/\s*;\s*/,$cmlmain::prm->{$paramname}->{extra}->{param})) {
                            my $v=&cmlcalc::calculate({id=>$id,expr=>"p($_)"});
                            push (@{$matrix->{dim}->{$_}->{vals}},split(/\s*;\s*/,$v->{value}));
                	}
		}
		elsif ($cmlmain::prm->{$paramname}->{type} eq 'LIST') {
			$v=&cmlcalc::calculate({id=>$id,expr=>"p($paramname)"});
			$id=$v->{value};
		}
			
	} else {
		$matrix=$inner->{matrix}
	}

        if   ($pl->{paramtab})       { 
		my $tabparam=$pl->{paramtab};
		my $tabvalue;
		if       ($param=~s/(\W)valuetab=(['"])(.+?)\2/$1/i)       { $tabvalue=$3 }
		elsif    ($param=~s/(\W)valuetabcgi=(['"])(.+?)\2/$1/i)       { $tabvalue=param($3) }
		$id=$tabvalue;
 	        $matrix->{dim}->{$tabparam}->{current}=$tabvalue;
 	        $matrix->{tabkey}="t_$matrix->{id}_$matrix->{param}_".join('_',map {$_=$matrix->{dim}->{$_}->{current}} split(/\s*;\s*/,$cmlmain::prm->{$matrix->{param}}->{extra}->{param}));
	}
	
	my $oldvar;
	my $setvar;
	my $varname;
	if ($varname=($pl->{var} || $pl->{env})) {
		$oldvar=$cmlcalc::ENV->{$varname};
		$setvar=1;
        if ($pl->{expr}) {
        	$cmlcalc::ENV->{$varname}=&cmlcalc::calculate({id=>$id,expr=>$pl->{expr}})->{value}
        } elsif ($pl->{value}) {
        	$cmlcalc::ENV->{$varname}=$pl->{value}
        } else {
        	$cmlcalc::ENV->{$varname}=$id
        }
	}	
	      
	$inner->{objid}=$id;
	$inner->{matrix}=$matrix;
	$inner->{parent}=$id;
	
	
	
	my $e404;
	if ($pl->{'validupkey'}) {
		$e404=1 if &cmlcalc::calculate({id=>$id,expr=>"p(_KEY,p(_UP))"})->{value} ne $pl->{'validupkey'};
	} 	elsif ($pl->{'validupexpr'}) {
		$e404=1 if &cmlcalc::calculate({id=>&cmlcalc::p(_UP,$id),expr=>$pl->{'validupexpr'}})->{value} ne 1;
	} 	elsif ($pl->{'validexpr'}) {
		$e404=1 if &cmlcalc::calculate({id=>$id,expr=>$pl->{'validexpr'}})->{value} ne 1;
	}	 	 

	if ($e404) {
		$cmlcalc::ENV->{'HTTPSTATUS'}='404 Not Found';
		$cmlcalc::STOPCACHE=1;
		return cmlparser({data=>"<cml:include key='NOTFOUND'/>",inner=>$inner});		
	}
	my $setreadonly=$pl->{readonly} && ($pl->{readonly} ne 'NULL') && !$cmlcalc::ENV->{READONLY};
	if ($pl->{readonlyexpr}) {
		my $v=&cmlcalc::calculate({id=>$id,expr=>$pl->{'readonlyexpr'}})->{value};
		$setreadonly=1 if $v && ($v ne 'NULL');
	} 
	
		
	$cmlcalc::ENV->{READONLY}=1 if $setreadonly;
    my $body=cmlparser({data=>$_[0]->{data},inner=>$inner});	
	$cmlcalc::ENV->{READONLY}=0 if $setreadonly;
	$cmlcalc::ENV->{$varname}=$oldvar if $setvar;
    return $body;
}

sub tag_button {
	return tag_actionlink({data=>$_[0]->{data},inner=>$_[0]->{inner},param=>"$_[0]->{param} button='1'"})
}

sub tag_actionlink {
	my $param=$_[0]->{param};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	my $method;
	my $title;
	
	my $pl=fetchparam(\$param,[
		'action','id','upobj','up','upkey','link','linkval',
		'setflag','name','value','prm','param',
		'piclist','filelist','vidlist',
		'template', 'editprm', 'ukey', 'listprm', 
		'orderby','ordertype','method','lmethod',
		'alert','redir','back', 'callback','redirvar', 'button','title',
		'filter','filterexpr','filterprm','collectdata', 'key', 'href',
		'forcereadonly','jsdata','type','setname','confirm', 'hidden',
		'width','height','popup','csv'

	]);
	my $access_denied=$cmlcalc::ENV->{READONLY};
	$pl->{button}=1 if $pl->{type} eq 'button';  	
	$pl->{action}='del' if lc($pl->{action}) eq 'delete';
	$pl->{action}=uc($pl->{action});
	
	if ($cmlcalc::CGIPARAM->{id} && $pl->{action} eq 'DEL')	{ 
		$pl->{id}=$cmlcalc::CGIPARAM->{id};
		$pl->{parseid}=$inner->{objid};
	} elsif (!$pl->{id}) {
		$pl->{id}=$inner->{objid}
	}
	
	if ($pl->{upobj}) { 
		$pl->{id}=$pl->{upobj} if $pl->{action} eq 'ADDUPRM'; 		
	}
	
	unless ($pl->{up}) {	
		if ($pl->{upkey}) { 
   			&cmlmain::checkload({key=>$pl->{upkey}});
   			$pl->{up}=$cmlmain::nobj->{$pl->{upkey}}->{id};
		} elsif ($pl->{upobj}) { 	
			$pl->{up}=$inner->{objid};
		}	else {
			$pl->{up}=$inner->{parent}
		}
	}	
	
	my $iid;
	if ($pl->{prm} || $pl->{param}) {
		my $prm=$pl->{prm} || $pl->{param};
		$iid=&cmlcalc::p($prm,$pl->{id});
	} else {
			$iid=$pl->{id};
	}
	$inner->{objid}=$iid;
	$title=$pl->{title};
	$title="<image src='$cmlmain::UNDOIMAGEURL' border='0'/>" if !$title && $pl->{action} eq 'UNDO';
	$title=cmlparser({data=>$_[0]->{data},inner=>$inner}) unless $title;
    $title="<image src='$cmlmain::PLUSBUTTONURL' border='0'/>" if !$title && $pl->{action} eq 'ADD';
    	
	my $succ_mes=$pl->{'alert'} || &cmlmain::enc('Успех');
	my $err_mes=&cmlmain::enc('Ошибка');
	
	my $rd='reloadPage()';
	$rd="location.href='$pl->{redir}';" if $pl->{redir};
	$rd="location.href=json.$pl->{redirvar};" if $pl->{redirvar};
	
    my $clstr=$pl->{hidden}?'style="display:none"':'';
		
	my $defajaxcallback=qq(
		function(json) {
			    var url=document.location.href;
		   	    if (json.status) {
        				alert(json.message || '$succ_mes');
        				$rd
    			} else {
        				alert(json.message);
    			}   
     	 }
    );
    return undef if $access_denied && $pl->{action} eq 'ADD'; 	
    
    
    
	if ($pl->{action} eq 'EDIT' || $pl->{action} eq 'VIEW' || $pl->{action} eq 'EDITVIEW') {
		my $tstr=$cmlcalc::ENV->{NOFRAMES}?'':"target='adminmb'";
		if ($pl->{action} eq 'EDITVIEW') {
			$pl->{action}=$access_denied?'VIEW':'EDIT';	
		}
		return undef if $access_denied && $pl->{action} eq 'EDIT'; 
		if ($pl->{key}) {
			&cmlmain::checkload({key=>$pl->{key}});
   			$iid=$cmlmain::nobj->{$pl->{key}}->{id};
		}	
		&cmlmain::checkload({id=>$iid});
		my $tid=$cmlmain::lobj->{$iid}->{upobj};
		my $kn=$pl->{upkey} || $pl->{ukey} || $cmlmain::obj->{$tid}->{key};
		if (!$kn && $cmlmain::obj->{$iid}->{template}) {
			$kn=$cmlmain::obj->{$cmlmain::obj->{$iid}->{template}}->{key}
		}	
		my $href=$pl->{popup}?"?popupview=EDIT_$kn&id=$iid":"?body=EDIT_$kn&id=$iid";
		$href.="&readonly=1" if $pl->{action} eq 'VIEW';
		$href.="&csv=1" if $pl->{csv};
		$href.="&back=".uri_escape($ENV{REQUEST_URI}) if $pl->{back};
		$href.='&'.$pl->{href} if $pl->{href};
		my $header_title=$title || &cmlmain::enc('Параметры');
		unless ($title) {
			if ($cmlmain::GLOBAL->{NEWSTYLE}) {
				$title="<i class='icon-edit'></i>"
			} else {
				my $imgurl=$pl->{action} eq 'EDIT'?$cmlmain::EDITIMAGEURL:$cmlmain::VIEWIMAGEURL;
				$title="<img src='$imgurl' border='0'/>";
			}	
		} 
		if ($pl->{popup}) {
 		    my $width=$pl->{width} || 600;
		    my $height=$pl->{height} || 400;
		    return qq(<a href='#' onclick="openPopup('$href',{title:'$header_title',width:$width,height:$height})">$title</a>)
		}
		
		
	 	return $pl->{button}?qq(<input type='button' onclick='location.href="$href"' value='$title' $param/>):"<a href='$href' $param $tstr>$title</a>"
	}	elsif ($pl->{action} eq 'LISTEDIT' || $pl->{action} eq 'LISTVIEW' ) {
		my $ukey=$pl->{ukey} || $pl->{key} || $cmlmain::obj->{$pl->{id}}->{key};
		my $tstr=$cmlcalc::ENV->{NOFRAMES}?'':"target='adminmb'";
		my $hrf="?body=LISTEDIT_$ukey&ukey=$ukey";
		for (qw (id listprm link orderby ordertype filter filterexpr filterprm)) {
				$hrf.="&$_=$pl->{$_}" if $pl->{$_};
		}
		$hrf.="&readonly=1" if $pl->{action} eq 'LISTVIEW' || $access_denied;
		$hrf.="&csv=1" if $pl->{csv};		
		$hrf.='&'.$pl->{href} if $pl->{href};
		$title=&cmlcalc::p('_NAME',&cmlcalc::id($ukey)) unless $title;	
		return $pl->{button}?qq(<input type='button' onclick='location.href="$hrf"' value='$title' $param/>):"<a href='$hrf' $param $tstr>$title</a>";

  	}	elsif ($pl->{action} eq 'EDITARTICLE' ) {
   	 	&cmlmain::checkload({id=>$pl->{id}});
   	 	$pl->{template}='BASEARTICLE' unless $pl->{template};
		my $tid=$cmlmain::lobj->{$pl->{id}}->{upobj};
		my $kn=$cmlmain::obj->{$tid}->{key};
		my $prm=$pl->{prm} || $pl->{param} || $pl->{editprm} ||'PAGETEMPLATE';
		my $piclistprm=$pl->{'piclist'} || 'PICLINKS';
		my $filelistprm=$pl->{'filelist'} || 'FILELINKS';
		my $vidlistprm=$pl->{'vidlist'} || 'VIDEOLINKS';
		return "<a href='?body=$pl->{template}&id=$pl->{id}&editprm=$prm&piclistprm=$piclistprm&filelistprm=$filelistprm&vidlistprm=$vidlistprm' $param>$title</a>";
	} 	elsif ($pl->{action} eq 'DEBUG') {
		return "<a href='/cgi-bin/vcms/cmlsrv.pl?action=editlowform&objid=$pl->{id}' $param>$title</a>";
	} 	elsif ($pl->{action} eq 'ADD') {
		my $prf="$pl->{up}_$pl->{id}";
		my $linkval=$pl->{linkval} || $pl->{id};
		if ($cmlcalc::CGIPARAM->{_MODE} eq 'USER') {
			my $onclick=qq(onclick="execute('BASEADDMETHOD',{up:'$pl->{up}',upobj:'$pl->{upobj}',link:'$pl->{link}',linkval:'$linkval'}, $defajaxcallback)");
			return "<a href='#' $onclick >$title</a>";
		} else {
			return qq(
		        <a href='#' onclick='return addobject("$pl->{up}","$pl->{link}","$linkval","$pl->{setname}","","$pl->{method}")'>$title</a>
			);
		}	
	} 	elsif ($pl->{action} eq 'CLEAR') {
		return qq(
		        <a href='#' onclick='return deletealllow("$pl->{id}")'>$title</a>
		);
	} 	elsif ($pl->{action} eq 'HISTORY') {
		return qq(
		        <a href='/cgi-bin/vcms/cmlsrv.pl?action=viewallhistory&objid=$pl->{id}' target='_blank'>$title</a>
		);
	} 	elsif ($pl->{action} eq 'DBBACKUP') {
		return qq(
		        <a href='/cgi-bin/vcms/cmlsrv.pl?action=export&area=db' target='_blank'>$title</a>
		);
	} 	elsif ($pl->{action} eq 'RESORT') {
		$title=&cmlmain::enc('Пересортировать') unless $title;
		my $onclick=qq(onclick="execute('BASERESORT',{up:'$pl->{id}'}, $defajaxcallback)");
		return $pl->{button}?"<input type='button' $onclick value='$title' $clstr $param/>":"<a href='#' $onclick >$title</a>";
	} 	elsif ($pl->{action} eq 'RESORTPOPUP') {
		    my $width=$pl->{width} || 400;
		    my $height=$pl->{height} || 700;
		    my $title=&cmlmain::enc('Сортировка');
		    return qq(<a href='#' onclick="openPopup('?view=RESORTPOPUP&id=$pl->{id}',{title:'$title',width:$width,height:$height})">$title</a>)
	} 	elsif ($pl->{action} eq 'SAVE') {
		    $title ||= &cmlmain::enc('Сохранить изменения');
		    return qq(<a href='#' $param onclick="multiset(this,undefined,'silent',undefined,undefined)">$title</a>)
	} elsif ($pl->{method}) {
		    return undef if $cmlcalc::ENV->{READONLY} && !$pl->{forcereadonly};
		    $title=$cmlmain::method->{$pl->{method}}->{name} unless $title;
 	    	my $dtstr='{}';
 	    	
 	    	
 	    	if ($pl->{collectdata}) {
 	    		$dtstr=vCMS::Config::Get('jquery')?
 	    			q(jQuery(this).parents('form').serializeForm()):
 	    			q($(this).up('form').serialize(true));
 	    	}
 	    	$dtstr="{$pl->{jsdata}}" if $pl->{jsdata}; 
 	    	$confirmstr=$pl->{confirm}?"confirm('$pl->{confirm}') && ":'this.disabled=true;';	 
 	    	my $onclick;   	 	    	
 	    	if (vCMS::Config::Get('jquery')) {
	    		my $callback=$pl->{callback} || 'defcallbackjq';
 	    		$onclick=qq(onclick="${confirmstr}executejq('$pl->{method}',$dtstr, $callback);return false;");
 
			} else {		    
 	    		my $callback=$pl->{callback} || 'defcallback';
 	    		$onclick=qq(onclick="${confirmstr}execute('$pl->{method}',$dtstr, $callback);return false;");
			}    
			return $pl->{button}?"<input type='button' $onclick value='$title' $clstr $param/>":"<a href='#' $onclick $clstr>$title</a>";
	} elsif ($pl->{lmethod}) {
		    return undef if $cmlcalc::ENV->{READONLY} && !$pl->{forcereadonly};
		    $title=$cmlmain::lmethod->{$pl->{lmethod}}->{name} unless $title;
			my $oid=$pl->{id} || $_[0]->{inner}->{objid};
			my $callback=$pl->{callback} || $defajaxcallback;
 	    	my $dtstr='{}';
 	    	$dtstr=q($(this).up('form').serialize(true)) if $pl->{collectdata};
 	    	$dtstr="{$pl->{jsdata}}" if $pl->{jsdata}; 
 	    	$confirmstr=$pl->{confirm}?"confirm('$pl->{confirm}') && ":'this.disabled=true;';	 	    	 	    	
			my $onclick=qq(onclick="${confirmstr}lexecute('$pl->{lmethod}',$oid,$dtstr, $callback);return false;");
			return $pl->{button}?"<input type='button' $onclick value='$title' $param/>":"<a href='#' $onclick>$title</a>";
	} elsif ($pl->{action} eq 'CSVEXPORT' || $pl->{action} eq 'EXPORTCSV') {
		    $title='CSV' unless $title;
		    return "<a href='$cmlcalc::QUERYSTRING&csv=1' target='_blank'>$title</a>"
	} elsif ($pl->{action} eq 'OPENWINDOW' || $pl->{action} eq 'POPUP') {
		    my $width=$pl->{width} || 600;
		    my $height=$pl->{height} || 400;
		    my $href="?popupview=$pl->{template}&id=$pl->{id}";
		    $href.='&'.$pl->{href} if $pl->{href};
		    return qq(<a href='#' onclick="openPopup('$href',{title:'$title',width:$width,height:$height})">$title</a>)
	}				
	
	
	
	$title=&cmlcalc::p('_NAME',$iid) unless $title;	 
	$title=$pl->{action} unless $title;
	
	
	$method="BASE$pl->{action}METHOD";	
	my @hlist;
	push(@hlist,"parsemethod=$method");
	my @plist=('view','menu','body','ukey','editprm','piclistprm','filelistprm','childlistprm','childukey','listprm');
	for (@plist) {
		push(@hlist,"$_=$cmlcalc::CGIPARAM->{$_}") if $cmlcalc::CGIPARAM->{$_};
	}	
		
	for (qw (id up upobj parseid link linkval setflag name value)) {
		push(@hlist,"$_=$pl->{$_}") if $pl->{$_};	
	}

	my $hstr=join('&',@hlist);
	if ($pl->{action} eq 'DEL') {
		if ($cmlmain::GLOBAL->{DOUBLECONFIRM}) {
			$param.=&cmlmain::enc(qq(onclick='return confirm("Вы уверены что хотите удалить объект") && confirm("Продолжить?")'));
		} else {
			$param.=&cmlmain::enc(qq(onclick='return confirm("Вы уверены что хотите удалить объект")'));
		}	
	}
	
	return $pl->{button}?"<input type='button' value='$title' $param/>":"<a href='?$hstr' $param>$title</a>";
	
}	
sub tag_captchaanswer 
{
	my $param=$_[0]->{param};
	return "<input type='text' id='sec_key' name='sec_key' value='' $param>";
}

sub tag_captcha {
	my $sec_id=&cmlmain::get_sec_id();
	return qq(
	    <div id='sec_code'> 
	    <img src='/cgi-bin/captcha.pl?id=$sec_id'/>
	    <input type='hidden' name='sec_id' id='sec_id' value='$sec_id'/>
	    </div>
	)
}


sub tag_a	{
	my $param=$_[0]->{param};

	my $pl=fetchparam(\$param,[
		'mode','href','pagenum',
		'parser','adminparser',
		'extraprm','adminextraprm',
		'param','prm','expr','id',
		'ifprm','ifparam','ifexpr',
		'blank','elementid',
	]);
	
	my $ql;
	my @qls;
	my $mode=$pl->{'mode'} || ''; 
    if ($pl->{'href'}) {	
		$ql=$pl->{'href'};
		if ($ql!~/^(http|mailto|\/|\?)/ && $ql!~/^\#/) {$ql="http://$ql"}
	} elsif ($pl->{'pagenum'}) {
		my $pid=$pl->{'pagenum'};
		$ql=$cmlcalc::QUERYSTRING;		
		if ($cmlcalc::CGIPARAM->{_MODE} eq 'ADMIN') {
			if ($ql=~/page=\d+/) {
				$ql=~s/page=\d+/page=$pid/;
			} else {	
				$ql.="&page=$pl->{'pagenum'}";
			}
		} else {
			if ($ql=~/page\/\d+/) {
				$ql=~s/page\/\d+/page\/$pid/;
			} else {	
				$ql.='/' if $ql!~/\/$/;
				$ql.="page/$pl->{'pagenum'}";
			}
		}	
	} elsif ($pl->{'parser'}) {	
	    	my $parser=$pl->{'parser'};
		$ql=$cmlcalc::QUERYSTRING;
		unless ($ql) {$ql='/view/STARTPAGE'}
		$ql.="/parsemethod/$parser";
		if ($ql!~/\/id\//) {$ql.="/id/".$_[0]->{inner}->{objid}}
	} elsif ($pl->{'adminparser'}) {
	    	my $parser=$pl->{'adminparser'};
		$ql=$cmlcalc::QUERYSTRING;
		unless ($ql) {$ql='?view=/STARTPAGE'}
		$ql.="&parsemethod=$parser";
	}


	if ($pl->{'extraprm'}) {
	    	my $extr=$pl->{'extraprm'};
	    	$extr=~s/=/\//g;
		$ql="$ql/$extr";   
	} elsif ($pl->{'adminextraprm'}) { 
	    	my $extr=$pl->{'adminextraprm'};
		$ql.='&'.$extr;   
	}

  	my $expr;
  	my $prm;
  	if ($pl->{'param'} || $pl->{'prm'}) {
    		$prm=$pl->{'param'}||$pl->{'prm'};
    		$expr="p($prm)";
  	} elsif ($pl->{'expr'}) {
  			$expr=$pl->{'expr'};
  	}	
  	my $id=$pl->{'id'} || $_[0]->{inner}->{objid};
  	if ($expr) {
 		my $v=&cmlcalc::calculate({id=>$id,expr=>$expr});
 		if ($v->{type} eq 'FILE' || $cmlmain::prm->{$prm}->{type} eq 'FILE') { 
 			if ($prm) {
 				$ql="/cgi-bin/viewer.pl?fview=${prm}&id=${id}"
 			} else {
 				$ql="$cmlmain::GLOBAL->{FILEURL}/$v->{value}"
 			}	 
 		} else {
 			return cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}}) unless $v->{value};
 			$ql=$v->{value};
 			if ($ql!~/^(http|\/|\?)/ && $ql!~/^\#/) { 
 				if ($ql=~/\@/) {
 					$ql="mailto:$ql"
 				} else {
 					$ql="http://$ql"
 				}	
 			}
 		}	
  	}

	my $ifexpr;
  	if ($pl->{'ifparam'} || $pl->{'ifprm'}) {
    		my $prm=$pl->{'ifparam'}||$pl->{'ifprm'};
    		$ifexpr="p($prm)";
  	} elsif ($pl->{'ifexpr'}) {
  			$ifexpr=$pl->{'ifexpr'};
  	}	
  	$ifval=1;
  	if ($ifexpr) {
 		my $v=&cmlcalc::calculate({id=>$id,expr=>$ifexpr});
 		unless ($v->{'value'}) {
 			$ifval=0;
 		}
  	}
	
		
  	$ql='/' if $ql eq '//';

	my $bstr;
	my $estr=$ifval?'</a>':'';
	
	my $idstr=$pl->{elementid}?"id='$pl->{elementid}'":'';
	if ($ifval) {
  		if ($mode eq 'openwindow') {
  			$bstr=qq(<a href="javascript:openwindow('$ql')" $param $idstr>);
  		}	else {
  			my $blstr=$pl->{'blank'} && $pl->{'blank'} ne 'NULL'?"target='_blank'":'';
 			$bstr=qq(<a href='$ql' $blstr $param $idstr>);
 		}
	}	
 	return $bstr.cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}}).$estr;	
}


sub tag_option {
	my $param=$_[0]->{param};
	my $selexpr='';
	my $sel;
	my $value;
	my $valuestr='';
	my $id=$_[0]->{inner}->{objid};
	my $pl=fetchparam(\$param,['value','param','sel','selexpr','selected']);
	
	if (defined $pl->{'value'}) { 
	  	$value=&cmlcalc::calculate({id=>$id,expr=>$pl->{'value'}})->{value};
	  	$valuestr="value='$value'"
	}
	if ($pl->{'param'}) {
	  	$value=&cmlcalc::calculate({id=>$id,expr=>"p($pl->{param})"})->{value};
	  	$valuestr="value='$value'"
	}
	$valuestr="value='$id'" unless $valuestr;
	$value=$id unless $value;
	
	if ($pl->{'sel'} || $pl->{'selected'} || $pl->{'selexpr'}) {
		my $expr=$pl->{'sel'} || $pl->{'selected'} || $pl->{'selexpr'};
	  	my $v=&cmlcalc::calculate({id=>$id,expr=>$expr})->{value};
	  	if ($v eq $value) {$selexpr="selected='selected'"}
	}  elsif (defined $_[0]->{inner}->{selected}) {
	  	#if ($_[0]->{inner}->{selected}->{$value} || $_[0]->{inner}->{selected}->{"p$value"}) 
	  	$selexpr="selected='selected'"
	}	
	my $dt=$_[0]->{data}?cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}}):&cmlcalc::calculate({id=>$id,expr=>"p(_NAME)"})->{value};
	return "<option $selexpr $valuestr $param>$dt</option>";
	
	
}	

sub tag_radiobutton {
	my $param=$_[0]->{param};
	my $pl=fetchparam(\$param,['id','param','prm','value','name']);	
	my $id=$pl->{id} || $_[0]->{inner}->{objid};

	my $selexpr;
	my $sel;
	my $value;
	my $valuestr;
	my $name;
	
	if ($pl->{value}) { 
	  $valuestr="value='$pl->{value}'";
	}
	my $prm=$pl->{param} || $pl->{prm};
  	if ($prm) { 
	  $v=&cmlcalc::calculate({id=>$id,expr=>"p($prm)"})->{value};
	  $valuestr="value='$value'" unless $valuestr;
	  $selexpr='checked' if ($pl->{value} && $v eq $pl->{value}) || $v==1;
	}
  	unless ($valuestr) {
  		$value=$id;
  		$valuestr="value='$id'"
  	}
  	
  	my $name=$pl->{name} || $_[0]->{inner}->{name} || "_o${id}_p${prm}"; 
  	
  	
	if ($param=~s/(\W)sel=(['"])(.+?)\2/$1/i) { 
	  	my $v=&cmlcalc::calculate({id=>$id,expr=>$3})->{value};
	  	if ($v eq $value) {$selexpr='checked'}
	}elsif ($param=~s/(\W)selexpr=(['"])(.+?)\2/$1/i) { 
	  	my $v=&cmlcalc::calculate({id=>$id,expr=>$3})->{value};
	  	if ($v) {$selexpr='checked'}
	}elsif (defined $_[0]->{inner}->{selected}) {
	 	 if ($_[0]->{inner}->{selected} eq $value) {$selexpr='checked'}
	}	

	return "<input type='radio' $selexpr $valuestr $param name='$name'>".cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}});
	
	
}	



sub tag_container {
	return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}});
}	

sub tag_image {
	return tag_img(@_);
}	

sub tag_lightbox {
	my $param=$_[0]->{param};
	my $pl=fetchparam(\$param,[
		'id','param' ,'prm','expr', 'href', 'key', 'single' 
	]);
	my $id;
	my $key;
	if       ($pl->{id})    {$id=$pl->{id}    }
	elsif 	 ($pl->{key})  {$key=$pl->{key}  }
	else     {$id=$_[0]->{inner}->{objid}}
	
	my $rel=$pl->{'single'}?'lightbox':'lightbox[1]';
	my $pkey=$pl->{param} || $pl->{prm};
	my $expr="p('$pkey')" if $pkey;
	$expr=$pl->{'expr'} if $pl->{'expr'};
	
	my $href=$pl->{href};
	
	unless ($href) {
		my $v=&cmlcalc::calculate({key=>$key,id=>$id,expr=>$expr});
		if ($cmlmain::prm->{$pkey}->{type} eq 'FILELINK') {
			$href=$v->{value};
		} else {
			my $pstr=$cmlmain::GLOBAL->{FILEURL};
			$href="$pstr/$v->{value}" if $v->{value};
		}	
		
		
		
	}	
	if ($href) {
		return "<a href='$href' rel='$rel'>".cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}})."</a>"
	} else {
		return cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}})
	}	 
	
}

sub tag_img 	{
	my $param=$_[0]->{param};

	my $id;
	my $key;
	my $src;
	my $alt='';
  	my $expr;
	
	my $pl=fetchparam(\$param,[
		'id','idcgi','name','key', 'param' ,'prm','expr', 
		'alt','altparam','altprm', 'path', 'src', 
		'elementid','onmouseoverparam','blink' 
	]);
	

	if       ($pl->{id})    {$id=$pl->{id}    }
	elsif    ($pl->{idcgi}) {$id=param($pl->{idcgi})}
	else     {$id=$_[0]->{inner}->{objid}}

	if ($pl->{name}) {$key=$pl->{name}   }
	if ($pl->{key})  {$key=$pl->{key}; undef $id   }
	
	$pkey=$pl->{param} || $pl->{prm};
	$expr="p('$pkey')" if $pkey;
	$expr=$pl->{'expr'} if $pl->{'expr'};

	
	if       ($pl->{alt})    {$alt=$pl->{alt}}
	elsif    ($pl->{altparam} || $pl->{altprm})    {
		my $ap=$pl->{altparam} || $pl->{altprm};
		my $av=&cmlcalc::calculate({key=>$key,id=>$id,expr=>"p($ap)"});
		$alt=$av->{value};
	}
	my $path = $pl->{'path'} || 'relative';
	$path='absolute' if $path=~/abs/i;
	
	
	
	if     ($pl->{src})    {$src=$pl->{src}}
	else {
		undef $alt if $alt eq 'NULL'; 
		unless ($expr) {$expr="p(PIC)"}
		my $v=&cmlcalc::calculate({key=>$key,id=>$id,expr=>$expr});
		unless ($v->{value}) {
			#if ($alt) {return $alt}
			return undef
		}
		if ($pkey && $cmlmain::prm->{$pkey}->{type} eq 'FILELINK') {
			$src=$v->{value};
		} else {
			my $pstr=$path eq 'absolute' ? $cmlmain::GLOBAL->{ABSFILEURL}:$cmlmain::GLOBAL->{FILEURL};
			$src="$pstr/$v->{value}";
		}	
	}
	
	
	my $omestr;
	if ($pl->{onmouseoverparam}) {
		my $v=&cmlcalc::calculate({key=>$key,id=>$id,expr=>"p($pl->{onmouseoverparam})"});
		if ($v->{value}) {
			my $pstr=$path eq 'absolute' ? $cmlmain::GLOBAL->{ABSFILEURL}:$cmlmain::GLOBAL->{FILEURL};
			my $omesrc="$pstr/$v->{value}";
			$omestr="onmouseover='this.src=\"$omesrc\"' onmouseout='this.src=\"$src\"'";
		}	
	}
	$pl->{elementid}="img$_[0]->{inner}->{objid}" if $pl->{blink} && !$pl->{elementid};
	my $idstr=$pl->{elementid}?"id='$pl->{elementid}'":'';
    my $blstr=($pl->{blink} && $pl->{elementid})?"<script>blink('$pl->{elementid}')</script>":'';
    
    my $astr=$alt?"alt='$alt' title='$alt'":'';
    
	return "<img src='$src' $param $astr $idstr $omestr />$blstr";	
	
 	
}	


sub tag_video 	{
	my $param=$_[0]->{param};

	my $key;
	my $src;
	my $psrc;
  	my $path='relative';
	
	
	my $pl=fetchparam(\$param,[
		'id','name','key', 'param' ,'prm','expr', 
		'previewprm','previewparam','path', 'width', 
		'height', 'counterkey', 
	]);
	
	my $id=$pl->{'id'} || $_[0]->{inner}->{objid};
	$key= $pl->{'name'} if $pl->{'name'};
	if ($pl->{'key'}) {
		$key=$pl->{'key'};
		undef $id;
	}
	my $pkey=$pl->{'prm'} || $pl->{'param'};
	my $expr;
	$expr=$pl->{'expr'} if $pl->{'expr'};
	$expr="p('$pkey')" if $pkey;
	$expr="p(MOVIE)" unless $expr;

	my $width=$pl->{'width'} || 480;
	my $height=$pl->{'height'} || 360;

	my $prevkey=$pl->{'prevprm'} || $pl->{'previewprm'};
	my $prevexpr;
	$prevexpr=$pl->{'prevexpr'} if $pl->{'prevexpr'};
	$prevexpr="p('$prevkey')" if $prevkey;
	$prevexpr="p(PIC)" unless $prevexpr;
	



	$path=$pl->{'path'} if $pl->{'path'};	
	$path='absolute' if $path=~/abs/i;
	
		

	my $v=&cmlcalc::calculate({key=>$key,id=>$id,expr=>$expr});
	unless ($v->{value}) {
		return undef
	}
	my $pstr=$path eq 'absolute'?$cmlmain::GLOBAL->{ABSFILEURL}:$cmlmain::GLOBAL->{FILEURL};
	$src="$pstr/$v->{value}";

	my $pv=&cmlcalc::calculate({key=>$key,id=>$id,expr=>$prevexpr});
	if ($pv->{value}) {
		my $pstr=$path eq 'absolute'?$cmlmain::GLOBAL->{ABSFILEURL}:$cmlmain::GLOBAL->{FILEURL};
		$psrc="$pstr/$pv->{value}";
	}
    my $divname=$v->{value};
    $divname=~s/\./_/g;
    
    my $clcode;
    my $clid=0;
    my $clobjid=0;
    if ($pl->{counterkey})  {
    	$clid=0+&cmlcalc::id($pl->{counterkey});
   		$clobjid=0+($id || &cmlcalc::p(_ID,$key));
    }

 	return qq(
 		
 	<div style="width:${width}px; height:${height}px; align:center;  background-image:url($psrc); background-repeat:no-repeat; background-position:center; " id="playerDiv_$divname">
 
 	</div>
 	<script language="JavaScript">
 	     var clid=$clid;
 	     var clobjid=$clobjid;
 	     var psrc='$psrc';
 	     var src='$src';
 	     var divname="playerDiv_$divname";

 	     
 	     function html5player () {
 	     	\$(divname).innerHTML ='<video width="$width" height="$height" controls poster="'+psrc+'" src="'+src+'"></video>'
 	     }	
 	     
         var player = flowplayer("playerDiv_$divname",{
        	src		: "/swf/flowplayer.swf",
            version	: [9, 115],
            bgcolor	: "#FFFFF",
            onFail	: html5player

        },{
            clip: { 
            	scaling:'fit'
            },  
            canvas: {
                backgroundColor: '#FFFFFF'
            },
            playlist: [
                {url: psrc, autoPlay: true},
                {url: src, autoPlay: false},
                {url: psrc, autoPlay: true}
            ],
            onStart: function(clip){
            	        if (clid) {
              				clip.url.scan(/(flv|mp4)\$/, function(match){ 
                      			new Ajax.Request('/__STATPAGE?_cl='+clid+'&_clobjid='+clobjid+'&_clurl='+encodeURIComponent(location.href),{method:'get'});
              				});
      					}
            }	
        });
     </script>
	);

}	


sub tag_audio 	{
	my $param=$_[0]->{param};

	my $key;
	my $src;
	
	my $path='relative';
	my $pl=fetchparam(\$param,[
		'id','name','key', 'param' ,'prm','expr','path' 
	]);
	
	my $id=$pl->{'id'} || $_[0]->{inner}->{objid};
	$key= $pl->{'name'} if $pl->{'name'};
	if ($pl->{'key'}) {
		$key=$pl->{'key'};
		undef $id;
	}
	my $pkey=$pl->{'prm'} || $pl->{'param'};
	my $expr;
	$expr=$pl->{'expr'} if $pl->{'expr'};
	$expr="p('$pkey')" if $pkey;
	$expr="p(AUDIO)" unless $expr;

	my $v=&cmlcalc::calculate({key=>$key,id=>$id,expr=>$expr});
	unless ($v->{value}) {
		return undef
	}
	my $pstr=$path eq 'absolute'?$cmlmain::GLOBAL->{ABSFILEURL}:$cmlmain::GLOBAL->{FILEURL};
	$src="$pstr/$v->{value}";

	
    my $divname=$v->{value};
    $divname=~s/\./_/g;
    
    return qq(
        <div id="aplayerDiv_$divname"></div>
    	<script type="text/javascript">
			var flashvars = {
			  mp3: "$src"
			};
			var params = {
			  wmode: "transparent"
			};
			var attributes = {
			  id: "dewplayer"
			};
			swfobject.embedSWF("/swf/dewplayer-vol.swf", "aplayerDiv_$divname", "240", "20", "9.0.0", false, flashvars, params, attributes);
		</script>
    );
}	



sub tag_execute {
	my $param=$_[0]->{param};
    my $inner; %{$inner}=%{$_[0]->{inner}};
	my $key;
	my $pl=fetchparam(\$param,[
		'id','method','key','lmethod',
	]);
	
	my $id=$pl->{id} || $_[0]->{inner}->{objid};
	my $res=&cmlcalc::execute({
		key=>$pl->{key},
		id=>$pl->{key}?0:$id,
		method=>$pl->{method},
		lmethod=>$pl->{lmethod}
	});
	if ($res) {
		$inner->{objid}=$id;
		return  cmlparser({data=>$_[0]->{data},inner=>$inner}); 
	}	else { 
		return "[ Execute ERROR! (id:$id key:$key) ]" 
	}
}


sub tag_include {
  	my $param=$_[0]->{param};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
  	my $key;
  	my $expr;
  	my $id;
  	
	my $pl=fetchparam(\$param,[
		'id','idexpr','notfound','idcgi','name',
		'key','namecgi','param','prm','readonly','set404',
		'validupkey','validexpr','validupexpr','validkey',
		'validempty',
	]);
	
  	if  ($pl->{id})       {
  		$id=$pl->{id}    
  	} 	elsif ($pl->{idexpr})    {
  	    $id=&cmlcalc::calculate({id=>$_[0]->{inner}->{objid},expr=>$pl->{idexpr}})->{value}
  	}  	elsif   ($pl->{idcgi})    {
  		$id=param($pl->{idcgi})
  	}  	elsif      ($pl->{name})     {
  		$key=$pl->{name}   
  	}  	elsif      ($pl->{key})     {
  		$key=$pl->{key}   
  	}  	elsif   ($pl->{namecgi})  {
  		$key=param($pl->{namecgi})
  	}  	else    {
  		$id=$inner->{objid}
  	}
  	
  	
  	if ($pl->{param}) {
  		$expr="p('$pl->{param}')" 
  	} elsif ($pl->{prm}) {
  		$expr="p('$pl->{prm}')"
  	} else {
  		$expr='p(PAGETEMPLATE)';
  	}
  
    my $e404;
	if ($pl->{'validupkey'}) {
		$e404=1 if &cmlcalc::calculate({id=>$id,expr=>"p(_KEY,p(_UP))"})->{value} ne $pl->{'validupkey'};
	} 	elsif ($pl->{'validupexpr'}) {
		$e404=1 if &cmlcalc::calculate({id=>&cmlcalc::p(_UP,$id),expr=>$pl->{'validupexpr'}})->{value} ne 1;
	} 	elsif ($pl->{'validexpr'}) {
		$e404=1 if &cmlcalc::calculate({id=>$id,key=>$key,expr=>$pl->{'validexpr'}})->{value} ne 1;
	} 	elsif ($pl->{'validkey'}) {
		$e404=1 unless &cmlcalc::id($key);	 	 
	}
  
   if ($pl->{'set404'} || $e404)       {
		$cmlcalc::ENV->{'HTTPSTATUS'}='404 Not Found';
		$cmlcalc::STOPCACHE=1;
		if ($expr eq 'p(PAGETEMPLATE)' || $e404) {
			return cmlparser({data=>"<cml:include key='NOTFOUND'/>",inner=>$inner,readonly=>$pl->{readonly}});
		} else {
			return undef;
		}
   }
  
  	my $v=&cmlcalc::calculate({key=>$key,expr=>$expr,id=>$id,noparse=>1});
  	my $body=$v->{value};
	if ($body) {
		if ($pl->{notfound}) {
			$cmlcalc::ENV->{'HTTPSTATUS'}='404 Not Found';
			$cmlcalc::STOPCACHE=1;
		}	
		return  cmlparser({data=>$body, inner=>$inner, readonly=>$pl->{readonly}});
	} elsif ($pl->{validempty}) {
		$cmlcalc::ENV->{'HTTPSTATUS'}='404 Not Found';
		$cmlcalc::STOPCACHE=1;
		return cmlparser({data=>"<cml:include key='NOTFOUND'/>",inner=>$inner,readonly=>$pl->{readonly}});
	}	else {
		return undef
	}
}

sub tag_text {
  	
  		my $param=$_[0]->{param};
  		my $data=$_[0]->{data};
  		my $key;
  		my $ukey;
  		my $uid;
  		my $pkey;
  		my $expr;
  		my $id;
    	my $frmt;
    	my $ptype;

        
        my $pl=fetchparam(\$param,[	
        	'prm','param','br','csv','color', 'default', 'bold',
        	'value','formparam', 
        	'format',
        	'name','key','ukey','uid','namecgi','idexpr','idcgi','id',
        	'expr','typeexpr','listseparator'
        ]);
        
    	if 		($pl->{value})      {return $pl->{value}}
    	elsif   ($pl->{formparam})  {return $cmlcalc::CGIPARAM->{"_p$pl->{formparam}"}}
    
    	my $dfrmt;
    	my $spl;
        if ($pl->{prm} || $pl->{param}) {
        	$pkey=$pl->{prm} || $pl->{param}; 
        	$dfrmt=$cmlmain::prm->{$pkey}->{extra}->{format} if $cmlmain::prm->{$pkey}->{type} eq 'DATE';
            $spl=1 if  $cmlmain::prm->{$pkey}->{type} eq 'NUMBER' && $cmlmain::prm->{$pkey}->{extra}->{splt} eq 'y';        	
        	$expr="p('$pkey')";
        }
        
 

  
    	if ($pl->{format})     {$frmt=$pl->{format}}
  
  		if    ($pl->{name})      {$key=$pl->{name}  }
  		elsif ($pl->{key})       {$key=$pl->{key}   }
  		elsif ($pl->{ukey})      {$ukey=$pl->{ukey} }
  		elsif ($pl->{uid})       {$uid=$pl->{uid}   }
  		elsif ($pl->{namecgi})   {$key=param($pl->{namecgi})}
  		elsif ($pl->{idexpr})    {
  	    	$id=&cmlcalc::calculate({id=>$_[0]->{inner}->{objid},expr=>$pl->{idexpr}})->{value}
  		} elsif ($pl->{idcgi})     {
  			$id=param($pl->{idcgi})
  		}  elsif ($pl->{id})        {
  			$id=$pl->{id}; 
  			if (lc ($id) eq '_matrix') {$id=$_[0]->{matrix}->{tabkey}} 
  			if (lc ($id) eq '_parent') {$id=$_[0]->{inner}->{parent}} 
  		}  	else  {$id=$_[0]->{inner}->{objid}} 

        my $rs;
        if (lc ($id) eq '_iterator')        {$result=$_[0]->{inner}->{iterator}}
        elsif (lc ($id) eq '_iteratornext') {$result=$_[0]->{inner}->{iteratornext}}
        elsif (lc ($id) eq '_iteratordelta') {$result=$_[0]->{inner}->{iteratornext}}
        elsif ($pl->{expr})     {
        	$expr=$pl->{expr};
        	$expr=~s/_iterator(\W)/$_[0]->{inner}->{iterator}$1/ig;
        	$expr=~s/_iteratordelta(\W)/$_[0]->{inner}->{delta}$1/ig;
        	$expr=~s/_iteratornext(\W)/$_[0]->{inner}->{iteratornext}$1/ig;
        	$rs=&cmlcalc::calculate({id=>$id,key=>$key,expr=>$expr});
        } else { 
        	unless ($expr) {$expr='p(TXT)'}
        	$rs=&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$expr,uid=>$uid});
        }
        
        if ($pl->{typeexpr})     {
        	$ptype=&cmlcalc::calculate({id=>$id,expr=>$pl->{typeexpr}});
        }	
        
      	
      	if ( !$frmt && $pkey && $cmlmain::prm->{$pkey}->{type} eq 'NUMBER' ) {
      		    $frmt=$cmlmain::prm->{$pkey}->{extra}->{format};   
      	}	
        my $result=$rs->{value};
        if ($frmt) {
  			$result=sprintf ($frmt,$result)
        } elsif ($dfrmt && $result) {
        	$result = &cmlmain::enc(strftime ($dfrmt,localtime($result)));
        }	elsif ($spl && $result) {
        	$result = &cmlcalc::splitprice($result);
        }	 
        if (	($pkey && $cmlmain::prm->{$pkey}->{type} eq 'LIST') || ($ptype->{value} && $ptype->{value} eq 'LIST' ) ) {
        	$result=&cmlcalc::p('_NAME',$result);
      	}

  	
  		$result=~s/\n/<br>/g if $pl->{'br'};
        $result="[[ $expr ]]" if !$result && $_[0]->{inner}->{debug};
        $result=$pl->{default} if !$result && $pl->{default};
        push (@cmlcalc::CSVCOLS, $result ) if $pl->{csv};
        $result="<b>$result</b>" if $pl->{bold} && !$cmlcalc::CSVMODE;
        $result="<font color='$pl->{color}'>$result</font>" if $pl->{color};
        $result=~s/(\S);(\S)/$1$pl->{'listseparator'}$2/g if $pl->{'listseparator'};
        
        if ($data) {
        	$data=~s/\*/$result/;
        	return $data;	
        }else { 
			return $result;
        }	
}


sub tag_loop {
	my $param=$_[0]->{param};
 	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,['counter','var','value','delta']);
	my $oldvar;
	my $retval;
	if ($pl->{var}) {
		$oldvar=$cmlcalc::ENV->{$pl->{var}};
       	$cmlcalc::ENV->{$pl->{var}}=$pl->{value}
	}	
	for(my $i=1;$i<=$pl->{counter};$i++) {
		$retval.=cmlparser({data=>$data,inner=>$inner});
		$cmlcalc::ENV->{$pl->{var}}+=$pl->{delta} || 1  if $pl->{var};		
	}
	$cmlcalc::ENV->{$pl->{var}}=$oldvar if $pl->{var};
	return $retval;
	
}	

sub tag_for {
  	my $param=$_[0]->{param};
  	my $retval;
  	
  	my $key;
  	my $sexpr;
  	my $eexpr;
  	my $start;
  	my $end;
  	my $expr;
  	my $id;
    my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pl=fetchparam(\$param,[
		'startparam','endparam',
		'startexpr','endexpr',
		'delta','var'
	]);

  	if ($pl->{startparam})     {$sexpr="p($pl->{startparam})" }
  	if ($pl->{endparam})       {$eexpr="p($pl->{endparam})" }
  	if ($pl->{startexpr})     {$sexpr=$pl->{startexpr}}
  	if ($pl->{endexpr})       {$eexpr=$pl->{endexpr} }

  	
  	my $delta=$pl->{delta} || 1;

  
  	if    ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)      {$key=$3   }
  	elsif ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)       {$key=$3   }
  	elsif ($param=~s/(\W)ukey=(['"])(.+?)\2/$1/i)      {$ukey=$3  }
  	elsif ($param=~s/(\W)uid=(['"])(.+?)\2/$1/i)       {$uid=$3   }
  	elsif ($param=~s/(\W)namecgi=(['"])(.+?)\2/$1/i)   {$key=param($3)}
  	elsif ($param=~s/(\W)idcgi=(['"])(.+?)\2/$1/i)     {$id=param($3)}
  	elsif ($param=~s/(\W)id=(['"])(.+?)\2/$1/i)        {$id=$3; if (lc ($id) eq '_matrix') {$id=$_[0]->{matrix}->{tabkey}} }
  	else  {$id=$_[0]->{inner}->{objid}} 

	if ($sexpr) { 
  		$start=&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$sexpr,uid=>$uid})->{value};
  	} 
    if ($eexpr) { 
  		$end=&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$eexpr,uid=>$uid})->{value};
  	} 
  	my $retval;
  	$inner->{delta}=$delta;
  	
	my $oldvar;
	if ($pl->{var}) {
		$oldvar=$cmlcalc::ENV->{$pl->{var}};
       	$cmlcalc::ENV->{$pl->{var}}=$start;
	}	
	  	
  	
  	for (my $it=$start;$it<$end;$it+=$delta ){
  		$inner->{iterator}=$it;
  		if ($it+$delta<=$end) {$inner->{iteratornext}=$it+$delta} else {$inner->{iteratornext}=$end;}
  		$retval.=cmlparser({data=>$data,inner=>$inner});
  		$cmlcalc::ENV->{$pl->{var}}+=$delta if $pl->{var};  		
	}	
	$cmlcalc::ENV->{$pl->{var}}=$oldvar if $pl->{var};
	return $retval;
}



sub tag_date {
  	my $param=$_[0]->{param};
  	my $data=$_[0]->{data};
  	my $key;
  	my $expr;
  	my $id;
  	my $frmt;

	my $pl=fetchparam(\$param,[
		'param','prm','expr','name','key',
		'ukey','uid','namecgi','idcgi','id',
		'format','value','csv'
	]);
	
    my   $pkey=$pl->{param} || $pl->{prm};


  	if    ($pkey)     {
  		$expr="p('$pkey')";
  		$frmt=$cmlmain::prm->{$pkey}->{extra}->{format}; 
  	}
  	
  	if    ($pl->{'name'})		{
  		$key=$pl->{'name'}   
  	} elsif ($pl->{'key'})       	{
  		$key=$pl->{'key'}   
  	} elsif ($pl->{'ukey'})     	{
  		$ukey=$pl->{'ukey'}  
  	} elsif ($pl->{'uid'})       	{
  		$uid=$pl->{'uid'}   
  	}elsif ($pl->{'namecgi'}) 	{
  		$key=param($pl->{'namecgi'})
  	} elsif ($pl->{'idcgi'})     	{
  		$id=param($pl->{'idcgi'})
  	} elsif ($pl->{'id'})        	{
  		$id=$pl->{'id'}; 
  		if (lc ($id) eq '_matrix') {$id=$_[0]->{matrix}->{tabkey}} 
  	} else  {
  		$id=$_[0]->{inner}->{objid}
  	}
  	
  	if ($pl->{'format'})     {
  		$frmt=$pl->{'format'}
  	} 
  	
  	$frmt='%d.%m.%y %H:%M' unless $frmt;
  	
  	 
    if ($pl->{value}) {
	    $result=$pl->{value};    	
    } else {
        if (lc ($id) eq '_iterator')        {$result=$_[0]->{inner}->{iterator}}
        elsif (lc ($id) eq '_iteratornext') {$result=$_[0]->{inner}->{iteratornext}}
        elsif (lc ($id) eq '_iteratordelta') {$result=$_[0]->{inner}->{iteratornext}}
        elsif ($pl->{'expr'})     {
        	$expr=$pl->{'expr'};
        	$expr=~s/_iterator(\W)/$_[0]->{inner}->{iterator}$1/ig;
        	$expr=~s/_iteratordelta(\W)/$_[0]->{inner}->{delta}$1/ig;
        	$expr=~s/_iteratornext(\W)/$_[0]->{inner}->{iteratornext}$1/ig;
        } 
        $result=&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$expr,uid=>$uid});
        $result=$result->{value} if ref $result eq 'HASH';
    }
    $result=&cmlmain::enc(strftime $frmt,localtime($result)) if $result;
    push (@cmlcalc::CSVCOLS, $result ) if $pl->{csv};
    if ($data) {
    	$data=~s/\*/$result/;
        return $data;	
    }else { 
		return $result;
    }	
}


sub tag_repeat {
	my $param=$_[0]->{param};
        my $inner; %{$inner}=%{$_[0]->{inner}};
        my $data;
        my $level=$inner->{level};
        while($level--) { $data.=$_[0]->{data} }
        return cmlparser ({data=>$data,inner=>$inner});
}	

sub tag_form {
	my $param=$_[0]->{param};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $id;
	my $pkey;
	my $view;
	my $tview;
	my $parser;
	my $parserid;
	my $method;
  	my $body;
  	my $menu;
  	my $action;
  	my $page;
  	my $actionstr;
  	
  	my $pl=fetchparam(\$param,[
  		'id','key','pkey','parseid','parser',
  		'postparser','preparser','method','view',
  		'tview','body','page','menu','insertinto',
  		'link','alert','action','prm','param','editprm',
  		'piclistprm','filelistprm','parseprm',
  		'renameparam','renameprm', 'matrix','ukey','listprm',
  		'actionexpr','elementid','iframe','readonlyexpr'  		
  	]);
	#$param=$pl->{'str'};
	
	if    	($pl->{'id'})    {
	    	$id=$pl->{'id'};
	} elsif ($pl->{'key'})    {
	  	&cmlmain::checkload({key=>$pl->{'key'}});
  		$id=$cmlmain::nobj->{$pl->{'key'}}->{id};
  		$inner->{objid}=$id;
	}	else   {
		$id=ref $inner->{objid} eq 'HASH'?$inner->{objid}->{id}:$inner->{objid};
	}
	
	if ($pl->{readonlyexpr} && &cmlcalc::calculate({id=>$id,key=>$pl->{'key'},expr=>$pl->{'readonlyexpr'}})->{value}) {
		my $setreadonly=$cmlcalc::ENV->{READONLY}?0:1;
		$cmlcalc::ENV->{READONLY}=1 if $setreadonly; 
		$data=cmlparser({data=>$_[0]->{data},inner=>$inner});
		$cmlcalc::ENV->{READONLY}=0 if $setreadonly;
		return $data;
	}
	
	if   ($pl->{'pkey'})	{
		$pkey=$pl->{'pkey'};
	}elsif   ($pl->{'prm'})	{
		$pkey=$pl->{'prm'};
	}elsif   ($pl->{'param'})	{
		$pkey=$pl->{'param'};
	} else {
		$pkey=$inner->{'pkey'};
	}
	
	if   ($pl->{'parseid'})  {
		$parserid=$pl->{'parseid'}
	} elsif ($id ne $inner->{objid}->{id}) {
		$parserid=ref $inner->{objid} eq 'HASH'?$inner->{objid}->{id}:$inner->{objid};
	}

	if   ($pl->{'parser'}) {
		$parser=$pl->{'parser'}
	} elsif ($cmlcalc::CGIPARAM->{_MODE} eq 'SITE')   {
		$parser='SAFEBASELPARSER'
	} else {
		$parser='BASELPARSER'
	}
	
	$method=$pl->{'method'} || 'POST';

	if     	($pl->{'view'})  {
		$view=$pl->{'view'}
	} elsif  ($pl->{'tview'})  {
		$tview=$pl->{'tview'}
	} else {
		$view=$cmlcalc::CGIPARAM->{view}
	}
	
	
	if ($pl->{'body'})  {
		$body=$pl->{'body'}
	} elsif ($pl->{'iframe'} && !$pl->{'action'}){
		$body='IFRAMEPARSER' 	
	} else {
		$body=$cmlcalc::CGIPARAM->{body}
	}
	
	if ($pl->{'page'})  {
		$page=$pl->{'page'}
	} else {
		$page=$cmlcalc::CGIPARAM->{page}
	}
	if ($pl->{'menu'})  {
		$menu=$pl->{'menu'}
	} else {
		$menu=$cmlcalc::CGIPARAM->{menu}
	}
	
	my $renameprm=$pl->{'renameparam'} || $pl->{'renameprm'} ;


	if ($pl->{'action'})  {	
		$action=$pl->{'action'};
		undef $view;	
	} elsif ($pl->{'actionexpr'})  {
		$action=&cmlcalc::calculate({id=>$id,key=>$pl->{'key'},expr=>$pl->{'actionexpr'}})->{value};	
	} elsif ($view  && $cmlcalc::CGIPARAM->{_MODE} eq 'SITE') {
		$action="/_$view" 	
	} elsif ($tview && $cmlcalc::CGIPARAM->{_MODE} eq 'SITE') {
			$action="/__$tview" 	
	}
  	$actionstr="action='$action'" if $action;
  	my $frmid=$pl->{elementid} || ($parserid?"frm$parserid":"frm$id");
	my $estr=$action!~/^http/?"enctype='multipart/form-data'":"";
	my $ifrstr=$pl->{iframe}?"target='iframe$id'":'';
	
	
	my $data="<form $param method='$method' $estr $actionstr id='$frmid' $ifrstr>";
	
    unless ($action=~/^http/) {
		if ($view) {$data.="<input type='hidden' name='view' value='$view'>"}
		elsif ($tview) {$data.="<input type='hidden' name='tview' value='$tview'>"}
		elsif ($body) {$data.="<input type='hidden' name='body' value='$body'>"}
		elsif ($menu) {$data.="<input type='hidden' name='menu' value='$menu'>"}
		elsif ($page) {$data.="<input type='hidden' name='page' value='$page'>"}
		else {$data.="<input type='hidden' name='action' value='go'>"}
	
		$data.="<input type='hidden' name='id' value='$id'>";
		$data.="<input type='hidden' name='param' value='$pkey'>";
		$data.="<input type='hidden' name='parsemethod' value='$parser'>" unless $pl->{iframe};
		$data.="<input type='hidden' name='parseid' value='$parserid'>" if $parserid;
		$data.="<input type='hidden' name='parseprm' value='$pl->{parseprm}'>" if $pl->{'parseprm'};
		$data.="<input type='hidden' name='listprm' value='$pl->{listprm}'>" if $pl->{'listprm'};
	
		if ($pl->{'postparser'}) {$data.="<input type='hidden' name='postparser' value='$pl->{postparser}'>";}
		if ($pl->{'preparser'}) {$data.="<input type='hidden' name='preparser' value='$pl->{preparser}'>";}
		if ($pl->{'alert'}) {$data.="<input type='hidden' name='alerttext' value='$pl->{alert}>"}
		if ($renameprm) {$data.="<input type='hidden' name='renameprm' value='$renameprm'>"}
		
		$data.="<input type='hidden' name='$_' value='$pl->{$_}'>" for grep {$pl->{$_}} ('insertinto','link');
		
		
    }
    
	for my $p (qw(editprm piclistprm filelistprm ukey back iframe)) {
		my $pv=$pl->{$p} || $cmlcalc::CGIPARAM->{$p};
		$data.="<input type='hidden' name='$p' value='$pv' id='frm$p'>" if $pv;
	}
	
	
	$inner->{matrix}=$pl->{matrix};
	$inner->{formid}=$frmid;
	
	$data.=cmlparser({data=>$_[0]->{data},inner=>$inner});
	$data.="</form>";
	$data.="<iframe id='iframe$id' width='0' height='0' name='iframe$id' src='' frameborder='0'></iframe>" if $pl->{iframe};
	return $data;
}	

sub tag_inputpic {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	my $pl=fetchparam(\$param,[
		'param','prm','name','id','delbutton','deletebutton'
  	]);

  	my $id=$pl->{id} || $_[0]->{inner}->{objid};
	my $prm=$pl->{param}||$pl->{prm}||'PIC';
	
	if ($pl->{name}) {
		$name=$pl->{name}
	} elsif ($_[0]->{inner}->{matrix}) {
		$name="_o${id}_f${prm}";
	} else {
		$name="_f$prm";
	}
	tag_list({data=>$data,inner=>$inner,param=>$param});
    my $delstr=($pl->{delbutton} || $pl->{deletebutton})?tag_deletebutton({param=>" prm='$prm' id='$id' ",inner=>$inner}):'';
  	return tag_img({data=>$data,inner=>$inner,param=>$_[0]->{param}}).
  		   "$delstr<input type='file' $param name='$name'>";
}

sub tag_inputaudio {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	my $pl=fetchparam(\$param,[
		'param','prm','name','id','delbutton','deletebutton'
  	]);

  	my $id=$pl->{id} || $_[0]->{inner}->{objid};
	my $prm=$pl->{param}||$pl->{prm}||'PIC';
	
	if ($pl->{name}) {
		$name=$pl->{name}
	} elsif ($_[0]->{inner}->{matrix}) {
		$name="_o${id}_f${prm}";
	} else {
		$name="_f$prm";
	}
	tag_list({data=>$data,inner=>$inner,param=>$param});
    my $delstr=($pl->{delbutton} || $pl->{deletebutton})?tag_deletebutton({param=>" prm='$prm' id='$id' ",inner=>$inner}):'';
  	return tag_audio({data=>$data,inner=>$inner,param=>$_[0]->{param}}).
  		   "$delstr<input type='file' $param name='$name'>";
}


sub tag_inputparam {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};

  
	my $prm;
	my $name;
	my $id;
	my $key;	
	
	my $pl=fetchparam(\$param,['prmid']);
	
  	if ($param=~/(\W)key=(['"])(.+?)\2/i)       {$key=$3   }
 	elsif ($param=~/(\W)id=(['"])(.+?)\2/i)     {
 		$id=$3;   
 		$inner->{objid}=$id;
 	}  else {$id=$_[0]->{inner}->{objid}}
	
	
	if ($param=~/(\W)param=(['"])(.+?)\2/i)    { $prm=$3 } 
	elsif ($param=~/(\W)prm=(['"])(.+?)\2/i)      { $prm=$3 } 
	
	if ($param=~/(\W)prmexpr=(['"])(.+?)\2/i)      { 
    	my $pexpr=$3;
    	$prm=&cmlcalc::calculate({id=>$id,key=>$key,expr=>$pexpr})->{value};
    	$param=~s/(\W)prmexpr=(['"])(.+?)\2/$1prm='$prm'/i;
    	$inner->{objid}=$inner->{parent};
  	} 
	

	if ($param=~/(\W)expr=(['"])(.+?)\2/i)      { 
    	my $expr=$3;
  		my $value=&cmlcalc::calculate({id=>$id,key=>$key,expr=>$expr})->{value};      	
    	$param=~s/(\W)expr=(['"])(.*?)\2/$1/i;
    	$inner->{objid}=$inner->{parent};
  	}

	
	if ($param=~/(\W)name=(['"])(.+?)\2/i)     {$name=$3   } 
	else {$name="_f$prm"}
	
	if ($pl->{prmid})     {
 		$inner->{objid}=$pl->{prmid};
	}
		
	if ($cmlmain::prm->{$prm}->{type} eq 'LIST') {
		return tag_select({data=>$data,inner=>$inner,param=>$param});
  	} elsif ( $cmlmain::prm->{$prm}->{type} eq 'PICTURE'  ) {		
  		return tag_img({data=>$data,inner=>$inner,param=>$param}).tag_inputfile({data=>$data,inner=>$inner,param=>$param});       	
	}	 else {
		return tag_inputtext({data=>$data,inner=>$inner,param=>$param});
  	}	
	
  
}	

sub tag_inputfile {
	my $param=$_[0]->{param};
	my $prm;
	my $name;
	if ($param=~s/(\W)param=(['"])(.+?)\2/$1/i)      { $prm=$3 } 
	if ($param=~s/(\W)prm=(['"])(.+?)\2/$1/i)      { $prm=$3 } 
	

	
	if ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)       {$name=$3   } 
	else {$name="_f$prm"}
  return "<input type='file' $param name='$name'>";
	
}	

sub tag_inputflag {
	return tag_checkbox(@_);
}	


sub tag_inputtext {
	
	my $param=$_[0]->{param};

	
  	my $pl=fetchparam(\$param,[
  		'key','id','textareaid','value','expr','type',
  		'param','prm','prmexpr','name','rows','cols',
  		'elementid','visual','csv','color','textcolor',
  		'notnull','isnumber','up'
  	]);
  
  	my $access_denied=$cmlcalc::ENV->{READONLY};
  	my $id=$pl->{id} || $_[0]->{inner}->{objid};
    if ($pl->{'key'}) {
		&cmlmain::checkload({key=>$pl->{'key'}});
		$id=$cmlmain::nobj->{$pl->{'key'}}->{id};
	}
    


	my $value;  
	my $valueset;	  
  	if (defined $pl->{value})   { 	
  		$value=$pl->{value};
  		$valueset=1;      	
	} elsif ($pl->{expr})   { 	
  		$value=&cmlcalc::calculate({id=>$id,expr=>$pl->{expr}})->{value};
  		$valueset=1;      	
  	}

	my $rows;
	my $cols;
	my $mode='input';
	my $prm=$pl->{param} || $pl->{prm} || '';
  	if ($pl->{prmexpr})      { 
    		$prm=&cmlcalc::calculate({id=>$id,expr=>$pl->{prmexpr}})->{value};
  	}   
	if ($prm)      {	
 		if ($cmlmain::prm->{$prm}->{type} eq 'LONGTEXT') {
 			$mode='textarea'; 
 			$rows=$pl->{rows} || vCMS::Config::Get('mcerows',30); 
 			$cols=$pl->{cols} || vCMS::Config::Get('mcecols',100);
 		}
		if ($cmlmain::prm->{$prm}->{type} eq 'NUMBER') {$cols=5}
	}
  

  	my $name;
	if ($pl->{name}) {
		$name=$pl->{name}
	} else{
		if ($pl->{key}) {
			$name="_k$pl->{key}_p${prm}";	
		} elsif ($_[0]->{inner}->{matrix}) {
			$name="_o${id}_p${prm}";
		} else {
			$name="_p$prm";
		}
		$name.="_$pl->{up}" if $pl->{up};
	}	

	
	unless ($valueset) {
    	if ($prm &&  $id) {
  			$value=&cmlcalc::calculate({id=>$id,expr=>"p($prm)",noparse=>1})->{value};
		} elsif ($cmlcalc::CGIPARAM->{$name}) { 
			$value = $cmlcalc::CGIPARAM->{$name}
		}
	}	
	push (@cmlcalc::CSVCOLS, $value ) if $pl->{csv};
	
	return $value if $access_denied;
	
	
	if ($pl->{cols}) {
		$cols=$pl->{cols}
	} elsif ($prm eq '_INDEX') {
		$cols=5	
	} elsif ($cmlmain::prm->{$prm}->{extra}->{cols}) {
		$cols=$cmlmain::prm->{$prm}->{extra}->{cols}
	}
	
	if ($pl->{rows}) {
		$rows=$pl->{rows}; 
		$mode='textarea'	
	} elsif ($cmlmain::prm->{$prm}->{extra}->{rows}) {
		$mode='textarea', 
		$rows=$cmlmain::prm->{$prm}->{extra}->{rows}
	}

  	my $typestr='';
  	if ($pl->{type}) {
  		$typestr="type='$pl->{type}'"; 
  		$mode='input';
  	}
  	my $tidstr=$pl->{elementid}?"id='$pl->{elementid}'":"id='$name'";	
  	
  	my $clrstr;
  	
  	$clrstr="class='color'" if $pl->{color};
  	$clrstr="class='input-mini'" if $cmlmain::GLOBAL->{NEWSTYLE} && $cols && $cols<=5;
  	
  	
  	my $fcstr=$pl->{textcolor}?"style='color:$pl->{textcolor}'":'';
  	my $prmname=$cmlmain::prm->{$prm}->{name};
  	my $nnstr=$pl->{notnull}?"notnull='1'":'';
  	my $dstr=$pl->{isnumber}?"checkdigit='1'":''; 
	if ($mode eq 'input') {
		 my $sizestr=$cols?"size='$cols'":'';
		 $value=~s/"/&quot;/g;
 		 return qq(<input hasdata="1" type="text" value="$value" $param $sizestr name="$name" $typestr $tidstr $clrstr $fcstr prmname="$prmname" $nnstr $dstr/>);
	} elsif ($mode eq 'textarea') {
		my $cls=$pl->{visual} || $cmlmain::prm->{$prm}->{extra}->{visual} eq 'y'?'class="mceEditor"':'';
	    my $ev=escapeHTML($value);
	    $tidstr="id='$pl->{textareaid}'" if $pl->{textareaid};
		return qq(<textarea hasdata="1" rows="$rows" cols="$cols" $param name="$name" $tidstr $cls  prmname="$prmname" $nnstr $dstr  $fcstr>$ev</textarea>);
	}	
}	



sub tag_inputdate {
	my $param=$_[0]->{param};
	my $id=$_[0]->{inner}->{objid};
	
	
	my $value;
	my $frmt;

	my $name;
	my $frmtstr;
	my $prm;
	my $pl=fetchparam(\$param,['param','prm','name','format','split','value']);
	if ($pl->{prm} || $pl->{param})      {
		    $prm=$pl->{prm} || $pl->{param};	
	}
	if ($pl->{value}) {
		$value=$pl->{value}
	} elsif ($prm) {
		$value=&cmlcalc::calculate({id=>$id,expr=>"p($prm)"})->{value};
	}	
	
	
	if ($pl->{format})      {	
	  		$frmt=$pl->{format}; 
  	} elsif ($prm && $cmlmain::prm->{$prm}->{extra}->{format}) {
	  		$frmt=$cmlmain::prm->{$prm}->{extra}->{format};
	}	
	
	$name=$pl->{name} || "_p$prm"; 
	$frmtstr="<input type=hidden name='_d$prm' value='$frmt'>";
	if ($pl->{split} && $frmt) {
		$frmt=~s{\%Y}{
			my $ret="<select name='${name}_dY'>";
			my $curv=&cmlcalc::curyear($value);
			for my $y (2010..2012){
				my $sel=$curv==$y?"selected='selected'":'';
				$ret.="<option $sel>$y</option>";
			}
			$ret.="</select>";
			"$ret";
		}es;	

		$frmt=~s{\%m}{
			my $ret="<select name='${name}_dm'>";
			my $curm=&cmlcalc::curmonth($value);
			for my $m (1..12){
				my $sel=$curm==$m?"selected='selected'":'';
				$ret.=sprintf("<option $sel>%02s</option>",$m);
			}
			$ret.="</select>";
			"$ret";
		}es;	
		
		$frmt=~s{\%d}{
			my $ret="<select name='${name}_dd'>";
			my $curd=&cmlcalc::curday($value);
			for my $d (1..31){
				my $sel=$curd==$d?"selected='selected'":'';
				$ret.=sprintf("<option $sel>%02s</option>",$d);
			}
			$ret.="</select>";
			"$ret";
		}es;	
		
		return $frmt.$frmtstr;
	} else {
  		if ($frmt) { 
  			$value=strftime($frmt,localtime($value)) ;
 		} 
		return "<input value='$value' $param name='$name'>$frmtstr";
	}	
}	

sub tag_calendar {
	my $param=$_[0]->{param};
	my $id=$_[0]->{inner}->{objid};
	
	
	my $value;
	my $fvalue;
	
	my $name;
	my $frmtstr;
	my $pl=fetchparam(\$param,['param','prm','name','elementid','onchange','interfaceid','value','notnull']);
	my $readonly=$cmlcalc::ENV->{READONLY};
	my $prm=$pl->{param} || $pl->{prm};
	if (defined $pl->{value}) {
			$value=$pl->{value};
			undef ($value) if $value eq 'NULL';
	} elsif ($prm) {
			$value=&cmlcalc::calculate({id=>$id,expr=>"p($prm)"})->{value}; 
	}
	my $need_time=$cmlmain::prm->{$prm}->{extra}->{format}=~/\%[cH]/?1:0;
	
	if ($readonly) {
		if ($value && $cmlmain::prm->{$prm}->{extra}->{format}) {
			$value=strftime($cmlmain::prm->{$prm}->{extra}->{format},localtime($value));
		}
		return $value;	 
	}
	
	my $fvformat=$need_time?"%d.%m.%Y %H:%M":"%d.%m.%Y";
	my $size=$need_time?15:10;
	my $calopts=$need_time?"{time:'mixed', year_range:2 }":"{year_range:2 }";
	$fvalue=strftime($fvformat,localtime($value)) if $value;
	
	if ($pl->{name}) {
		$name=$pl->{name}
	} elsif ($_[0]->{inner}->{matrix}) {
		$name="_o${id}_p${prm}";
	} else {
		$name="_p$prm";
	}
	my $idstr=$pl->{'elementid'}?"id='$pl->{elementid}'":"id='$name'";
	my $iidstr=$pl->{'interfaceid'}?"id='$pl->{interfaceid}'":'';
	my $nnstr=$pl->{'notnull'}?"notnull='1'":''; 
	my $prmname=$cmlmain::prm->{$prm}->{name};
	my $clsstr=$cmlmain::GLOBAL->{NEWSTYLE}?"class='uneditable-input input-small'":'';
	
	 if (vCMS::Config::Get('jquery')) {
		return qq(
			 <input type="hidden" value="$value" name="$name" $idstr $nnstr prmname='$prmname'/>
	         <input type="text"   class='input-small' $param value="$fvalue" data-provide="datepicker" $iidstr/>
 	 	);
	 	
	 } else {
		return qq(
			 <input type="hidden" value="$value" name="$name" $idstr $nnstr prmname='$prmname'/>
	         <input type="text" $clsstr $param value="$fvalue" size='$size' $iidstr onchange="\$(this).previous().value=this.calendar_date_select.target_element.value?parseInt(this.calendar_date_select.selected_date.getTime()/1000):0;$pl->{onchange}">
             <img onclick="new CalendarDateSelect( \$(this).previous(), $calopts );" src="/cmsimg/calendar.gif" style="border: 0px none; cursor: pointer;" />
 	 	);
	 }
	
}	




sub tag_checkbox {
	my $param=$_[0]->{param};
	my $pl=fetchparam(\$param,['id','param','prm','name','value','nohidden','csv','forcehidden']);	
	my $id=$pl->{id} || $_[0]->{inner}->{objid};
	my $prm=$pl->{prm} || $pl->{param};
	my $value=$pl->{value} || 1;	
	my $checked;
	if ($prm) {
		my $v=&cmlcalc::calculate({id=>$id,expr=>"p($prm)"})->{value};
		$checked='checked' if ($pl->{value} && &cmlcalc::inlist($v,$pl->{value})) || $v==1;
	}
	
	push (@cmlcalc::CSVCOLS, $checked?'+':'-') if $pl->{csv};
	
    if ($cmlcalc::ENV->{READONLY}) {
    	return $checked?"<img src='$cmlmain::OKIMAGEURL'>":"-";
    }
	my $name;
	if ($pl->{name}) {
		$name=$pl->{name}
	} elsif ($_[0]->{inner}->{matrix}) {
		$name="_o${id}_p${prm}";
	} else {
		$name="_p$prm";
	}
	  
	$param=$pl->{str};
	my $hstr=(!$pl->{forcehidden} && ($pl->{'nohidden'}))?'':"<input type='hidden' value='0' name='$name'>";
	return "<input type='checkbox' value='$value' $checked name='$name' $param>$hstr".cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}});

	
}	

sub tag_deletebutton {
	
	return undef if $cmlcalc::ENV->{READONLY};
	my $param=$_[0]->{param};
	my $id=$_[0]->{inner}->{objid};
  	my $pl=fetchparam($param,['link','param','prm','method','parser','parseprm','parseid','deleteid','alert','moveto']);
  	$pl->{prm}=$pl->{param} if $pl->{param};
    $pl->{method}=$pl->{parser} if $pl->{parser};
    my $parseid=$pl->{parseid} || $_[0]->{inner}->{objid};

    return undef if $pl->{prm} && !&cmlcalc::p($pl->{prm},$_[0]->{inner}->{objid});

  	my $hstr=join('&',@hlist);
  	
	my $imgsrc=$cmlmain::DELIMAGEURL;
	my $deltext=&cmlmain::enc('Удалить');
	my $alert1=$pl->{'alert'} || &cmlmain::enc('Вы уверены, что хотите удалить объект?');
	my $alert2=&cmlmain::enc('Продолжить?');
	my $confjs=$cmlmain::GLOBAL->{DOUBLECONFIRM}?qq(confirm("$alert1") && confirm("$alert2")):qq(confirm("$alert1"));
	my $scriptjs;
	if ($pl->{method}) {
		$scriptjs=qq(lexecute("$pl->{method}","$id",{parseprm : "$pl->{parseprm}", deleteid : "$pl->{deleteid}", parseid : "$parseid" },defcallback));
	}elsif ($pl->{prm}) {	
		$scriptjs=qq(setvalue("$id","$pl->{prm}",""));
	} elsif ($pl->{moveto}) {
		if (vCMS::Config::Get('jquery')) {
			$scriptjs=qq(lexecutejq("BASEMOVEMETHOD","$id",{moveto : "$pl->{moveto}",parseid : "$parseid"}));
		} else {
			$scriptjs=qq(lexecute("BASEMOVEMETHOD","$id",{moveto : "$pl->{moveto}",parseid : "$parseid"},defcallback));
		}
	} elsif ($cmlcalc::CGIPARAM->{_MODE} eq 'USER') {
		$scriptjs=qq(lexecute("BASEDELMETHOD","$id",{parseprm : "$pl->{parseprm}", deleteid : "$pl->{deleteid}", parseid : "$parseid" },defcallback));
	} else {
		$scriptjs=qq(deleteobject("$parseid","$cmlcalc::CGIPARAM->{id}","$pl->{parseprm}","$pl->{deleteid}"));
	}
	my $istr=$cmlmain::GLOBAL->{NEWSTYLE}?qq(<i class="icon-remove" alt='$deltext'></i>):qq(<img border=0 src='$imgsrc' alt='$deltext'>);
	return qq(<a href='#' onclick='$confjs && $scriptjs;return false'>${istr}$_[0]->{data}</a>);		
}	


sub tag_changebutton {
	my $param=$_[0]->{param};
  	my $pl=fetchparam(\$param,[
  		'ajax','callback','title',
  		'redir','method','hidden',
  		'elementid','sortid','imgsrc',
  		'noreload'
  	]);
	my $imgsrc=$pl->{imgsrc} || $cmlmain::POSTBUTTONURL;  	
  	my $access_denied=$cmlcalc::ENV->{READONLY};
  	return undef if $access_denied;
  	my $cstr=$pl->{callback}?$pl->{callback}:'undefined';
  	my $rstr=$pl->{redir}?"'$pl->{redir}'":'undefined';
  	$rstr="'silent'" if $pl->{noreload};
  	my $mstr=$pl->{method}?"'$pl->{method}'":'undefined';
  	my $sstr=$pl->{sortid}?"'$pl->{sortid}'":'undefined';
  	my $elementid=$pl->{elementid}?"id='$pl->{elementid}'":'';
  	my $funcname=$_[0]->{inner}->{matrix}?'multisetmatrix':'multiset';

	my @stl;
	my $onclickstr;
	my $retstr;
	
	if ($pl->{'ajax'} || $pl->{'callback'}){
		if ($_[0]->{inner}->{matrix}) {
			my $funcname=vCMS::Config::Get('jquery')?'multisetjq':'multiset';
			$onclickstr=qq(onclick="this.disabled=true;if(typeof tinyMCE!='undefined') tinyMCE.triggerSave();$funcname(this,$cstr,$rstr,$mstr,$sstr);return false;");	
		}else {
			my $funcname=vCMS::Config::Get('jquery')?'multisetsingleobjjq':'multisetsingleobj';
			my $id=ref $_[0]->{inner}->{objid} eq 'HASH'?$_[0]->{inner}->{objid}->{id}:$_[0]->{inner}->{objid};
			$onclickstr=qq(onclick="this.disabled=true;if(typeof tinyMCE!='undefined') tinyMCE.triggerSave();$funcname(this,$id,$cstr,$rstr,$mstr);return false;");
		}	
	} elsif ($pl->{method}) {
		$retstr.="<input type='hidden' name='overrideparsemethod' value='$pl->{method}'>";
	}
	$retstr.="<input type='hidden' name='redirto' value='$pl->{redir}'>" if $pl->{'redir'} && !$onclickstr;
	
	my $classstr;
	if ($cmlmain::GLOBAL->{NEWSTYLE}) {
		$pl->{title} ||='Сохранить изменения';
		$classstr='class="btn btn-primary"'
	}
	
		
	if ($pl->{title}) {
		my $clstr=@stl?'style="'.join(';',@stl).'"':'';
		if ($onclickstr) {
			$retstr.="<input type='button' value='$pl->{title}' $onclickstr $param $clstr $elementid $classstr/>";
		} else {
			$retstr.="<input type='submit' value='$pl->{title}' $param $clstr $elementid $classstr/>";
		}	
	} else {	
		push (@stl,"cursor:pointer");
		my $clstr='style="'.join(';',@stl).'"';
		my $whstr=$pl->{imgsrc}?'':"width='119' height='24'";
		if ($onclickstr) {
			$retstr.="<img src='$imgsrc' $whstr value='OK' $onclickstr $param $clstr $elementid/>";
		} else {
			$retstr.="<input type='image' src='$imgsrc' $whstr value='OK' $param $clstr $elementid/>";
		}	
	}	
	return $retstr;
	
}	

sub tag_savebutton {
	my $param=$_[0]->{param};
  	my $pl=fetchparam($param,['prm','id','callback','label','title','reload']);
  	my $id=$pl->{'id'} || $_[0]->{inner}->{objid};
  	my $imgsrc=$pl->{'label'}?$cmlmain::POSTBUTTONURL:$cmlmain::SAVEBUTTONURL;
  	my $clbstr=$pl->{'callback'}?"$pl->{callback}":'undefined';
  	my $needreload=$pl->{'reload'}?1:0;
  	if ($pl->{title}) {
			return qq(<input type="button" value="$pl->{title}" onclick="set('$id','$pl->{prm}',$clbstr,$needreload);return false"/>);
  	} else {
  		    return qq(<input type="image" src="$imgsrc" value="+" onclick="set('$id','$pl->{prm}',$clbstr,$needreload);return false"/>);
  	}
}


sub tag_dev {
	return $cmlcalc::ENV->{dev}?cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}}):'';
}


sub tag_if {
	
	my $param=$_[0]->{param};
	undef $_[0]->{uinner}->{cond};
	
	my $pl=fetchparam(\$param,['readonly']);
	if ($pl->{readonly}) {
		if ($cmlcalc::CGIPARAM->{readonly}) {
			$_[0]->{uinner}->{cond}=1; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}})
		} else {
			return undef;
		}	 
	}
	
	my $key;
	my $ukey;
	my $uid;
	my $id;
	my $not;
	
  	if    ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)      {$key=$3   }
  	elsif ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)       {$key=$3   }
  	elsif ($param=~s/(\W)ukey=(['"])(.+?)\2/$1/i)      {$ukey=$3  }
  	elsif ($param=~s/(\W)uid=(['"])(.+?)\2/$1/i)       {$uid=$3   }
  	elsif ($param=~s/(\W)namecgi=(['"])(.+?)\2/$1/i)   {$key=param($3)}
  	elsif ($param=~s/(\W)idcgi=(['"])(.+?)\2/$1/i)     {$id=param($3)}
  	elsif ($param=~s/(\W)id=(['"])(.+?)\2/$1/i)        {$id=$3; if (lc ($id) eq '_matrix') {$id=$_[0]->{matrix}->{tabkey}} }
  	else  {$id=$_[0]->{inner}->{objid}} 
	
	if    ($param=~s/(\W)not=(['"])(.+?)\2/$1/i)      {$not=1   }
	
	if ($param=~s/(\W)selected=(['"])(.+?)\2/$1/i)      {
		my $cond=$_[0]->{inner}->{selected};
		$cond=!$cond if $not;
		
		if ($cond) {
			$_[0]->{uinner}->{cond}=$cond; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}	
	} elsif ($param=~s/(\W)cgiparamexist=(['"])(.+?)\2/$1/i)      {
		my $cond=$cmlcalc::CGIPARAM->{$3} ne '';
		$cond=!$cond if $not;
		
		if ($cond) {
			$_[0]->{uinner}->{cond}=1; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
	} elsif ($param=~s/(\W)view=(['"])(.+?)\2/$1/i)      {
		my $cond=$cmlcalc::CGIPARAM->{view} eq $3;
		$cond=!$cond if $not;
		
		if ($cond) {
			$_[0]->{uinner}->{cond}=1; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
  	} elsif ($param=~s/(\W)param=(['"])(.+?)\2/$1/i ||
        $param=~s/(\W)prm=(['"])(.+?)\2/$1/i   )  {
		my $cond="p($3)";
		$cond="!$cond" if $not;
		
		if (&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$cond,uid=>$uid})->{value}){
			$_[0]->{uinner}->{cond}=1; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
	} elsif ($param=~s/(\W)expr=(['"])(.+?)\2/$1/i)      {
		my $cond=$3;
		$cond="!$cond" if $not;
		
		if (&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$cond,uid=>$uid})->{value})	{
			$_[0]->{uinner}->{cond}=1;
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
	} elsif ($param=~s/(\W)value=(['"])(.+?)\2/$1/i)      {
		my $cond=$3;
		undef $cond if $cond eq 'NULL';
		$cond="!$cond" if $not;
		
		if ($cond)	{
			$_[0]->{uinner}->{cond}=1;
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
	}    

 	return undef;  	
}	

sub tag_else {
	unless ($_[0]->{uinner}->{cond}) {
		return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}})
	} else {
		return undef;	
	}	 
}





sub uploadprmfile
{
 my $prm;	
 if ($_[0]->{pkey}) {$prm=$_[0]->{pkey}}
 if ($_[0]->{param}) {$prm=$_[0]->{param}}
 
 my $id=$_[0]->{id};
 my $prmname=$_[0]->{cgiparam};
 
 my $fname=param($prmname);
 $fname =lc $fname; 
 
 if ($cmlmain::GLOBAL->{CODEPAGE} eq 'utf-8') {
 		$fname = Encode::encode('windows-1251',Encode::decode('utf-8',$fname));
 }	
  
 $fname =~s{^.+\\(.+?)$}{${id}_${prm}_$1}i;
 $fname =~s{[а-яА-Я\"\s\'\#\+]}{}g;

 $fname="o_${id}_p_${prm}_${fname}" if length $fname<7;

 my $fh = upload($prmname);
 open FILE,">$cmlmain::GLOBAL->{FILEPATH}/$fname" || die $!;
 while ($buffer=<$fh>) { 
  	print FILE $buffer; 
 }
 close  FILE;
 &cmlmain::setvalue({id=>$id,pkey=>$prm,value=>$fname}) if -s "$cmlmain::GLOBAL->{FILEPATH}/$fname";
}



return 1;


END {}
