package cmlparse;

# $Id: cmlparse.pm,v 1.4 2009-10-24 18:57:14 vano Exp $

BEGIN
{
 use Exporter();
 use Data::Dumper;
 use CGI  qw(param escapeHTML upload);
 use POSIX qw(strftime);
 use Time::HiRes qw (time);

 
 @ISA = 'Exporter';
 @EXPORT = qw( &cmlparser &initparser %CMLTAG &uploadprmfile);
}

sub initparser
{
 %CMLTAG=
 (
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
    'static'=>1,
    'menuitem'=>1,
    'pagination'=>1,
    'else'=>1,
 )
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
 #my $eelm;  if ($_[0]->{enableelm}){$eelm=1}
 


 

 my @txt=split(/<cml:/si,$text);

 my @stack=shift @txt;
 my @pstack;


 for (@txt)
 {
  (my $tag, my $tagdata)=/^(.+?>)(.*)$/s;
  my @intxt=split(/<\/cml:/si,$tagdata);

  my $firstsection=shift (@intxt);

  push (@stack,$firstsection);
  if ($tag=~/\/>/)
  {
   (my $tname, my $tparam)=($tag=~/(\w+)\s*(.*?)\/>/s);
   my $rdata=pop(@stack) || '';
   my $pstr;
   if ($#stack==0)   {
      $pstr=tagparse({name=>lc($tname),param=>" $tparam ",inner=>$inner}) || '';
   }
   else 	 {
   	$pstr="<cml:$tname $tparam/>"
   }
   push (@stack,(pop(@stack) || '')."$pstr$rdata" );
  }
  else
  {
   (my $tname, my $tparam)=($tag=~/(\w+)\s*(.*?)>/s);
   push (@pstack,$tparam);
  }
  for (@intxt)
  {
   (my $ztag, my $ztagdata)=/^(.+?)>(.*)$/s;
   my $rdata=pop(@stack);
   my $xparam=pop(@pstack);
  
   my $pstr;
   
   my $xtra;
   if ($#stack==0)   {
     $xtra=pop(@stack) || '';
     $pstr=tagparse({name=>lc($ztag),param=>" $xparam ",data=>$rdata,inner=>$inner}) || '';
     if (lc($ztag) eq 'container' || lc($ztag) eq 'lowlevel') 
     { 
    	unless ($felm) { $xtra=''} 
    	unless ($lelm) {$ztagdata=''}
     }
   }
   else {
     $xtra=pop(@stack) || '';	
     $pstr="<cml:$ztag $xparam>$rdata</cml:$ztag>";	
   }



   push (@stack,"$xtra$pstr$ztagdata");
   
  }
 }



 return pop (@stack);

}

sub tagparse {
  	my $inner; %{$inner}=%{$_[0]->{inner}};	
  	my $uinner=$_[0]->{inner};
  	
  	$_[0]->{param}=~s{_id:(.+?)_} {
  		$v=&cmlcalc::id($1);
  		$v;
  	}iges;
  	
	$_[0]->{param}=~s{_cml:(.+?)_} {
 		$v=&cmlmain::calculate({id=>$_[0]->{inner}->{objid},expr=>"p($1)"});
 		if ($v->{value} eq '') {$v->{value}='NULL'}
 		"$v->{value}";
	}iges;
	
	$_[0]->{param}=~s{_prm:(.+?)_} {
 		$v=$cmlcalc::CGIPARAM->{$1};
 		if ($v eq '') {$v='NULL'}
 		"$v";
	}iges;
	
	$_[0]->{param}=~s{_cgi:(.+?)_} {
 		$v=$cmlcalc::CGIPARAM->{$1};
 		if ($v eq '') {$v='NULL'}
 		"$v";
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




	
	$_[0]->{param}=~s/_LISTINDEX/$_[0]->{inner}->{listindex}/igs;
	$_[0]->{param}=~s/_CONTAINERINDEX/$_[0]->{inner}->{containerindex}/igs;
	$_[0]->{param}=~s/_PARENT/$_[0]->{inner}->{parent}/igs;
	$_[0]->{param}=~s/_SELF/$_[0]->{inner}->{objid}/igs;
	
	
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
  		if ($_[0]->{data}) {return "<$_[0]->{name} $_[0]->{param}>".cmlparser({data=>$_[0]->{data},inner=>$inner})."</$_[0]->{name}>";} 
  		else {return "<$_[0]->{name} $_[0]->{param} />";} 
	}
 
}

sub fetchparam {
	my ($pstr,$plist)=@_;
	my $rstr;
	for (@$plist) {
		if (ref $pstr eq 'SCALAR') {
			if ($$pstr=~s/(\W)$_=(['"])(.+?)\2/$1/i)      {$rstr->{$_}=$3 }
		} else {
			if ($pstr=~s/(\W)$_=(['"])(.+?)\2/$1/i)      {$rstr->{$_}=$3 }
		}	
	}
	return $rstr;
}


############################### Обработчики тегов

sub tag_pagination {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	my $pid=$cmlcalc::CGIPARAM->{pagenum} || 1;
	my $rtext = <<PITEM;
	<cml:list $param>
		<cml:if expr='_LISTINDEX eq $pid'> <cml:text expr='_CONTAINERINDEX+1'/> </cml:if>
		<cml:if expr='_LISTINDEX ne $pid'>
			<cml:a pagenum='_LISTINDEX'><cml:text expr='_CONTAINERINDEX+1'/></cml:a>
		</cml:if>
		<cml:container/>
	</cml:list>
PITEM
	return cmlparser({data=>$rtext,inner=>$inner});
	
	
}


sub tag_menuitem	{
	
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	
	my $pl=fetchparam($param,['action','key','href','id','prm','param','piclist','filelist','delete']);
	my $id=$pl->{id} || $inner->{objid};
	$pl->{action}='EDIT' unless $pl->{action};  
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
		$pl->{href}="body=BASEARTICLE&editprm=$prm&piclistprm=$piclistprm&filelistprm=$filelistprm";
	}	
	
	unless ($pl->{key}) {
		$pl->{key}=&cmlcalc::p(_KEY,&cmlcalc::uobj($id));
	}
	my $href='?'. ($pl->{href} || "body=$pl->{action}_$pl->{key}");
	
	my $itext=cmlparser({data=>$data,inner=>$inner});
	unless ($itext) {
		$itext=&cmlcalc::p(_NAME,$id);
	}
	$href.="&id=$id";	 
	$itext='пустой' unless $itext;
	my $dtxt=$pl->{delete}?'<cml:deletebutton/>':'<img src="/cmsimg/0.gif" width="16" height="16" alt="" border="0">';
	my $mtext=<<MENUITEM;
		<tr>
		<td bgcolor="#FFFFFF" width="16"><a href="$href" target="adminmb"><img src="/cmsimg/edit.png" alt="Редактировать" border="0"/></a></td>
		<td bgcolor="#dedede" width="100%" colspan="2"><a href="$href" target="adminmb">$itext</a></td>
		<td bgcolor="#dedede" width="16">$dtxt</td>
		</tr>
MENUITEM
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
  		'param','prm','prmexpr',
  		'optionid','name','optionparam',
  		'defoptvalue','defoptname',
  		
  	]);
  	my $multiple='multiple' if $pl->{'multiple'};
  	my $id=$pl->{'id'} || $inner->{objid};
	if ($pl->{'selexpr'}) {
		$sexpr=$pl->{'selexpr'}
	} elsif ($pl->{'selected'}) {
		$sexpr="p($pl->{'selected'})";
	}
  	my $prm=$pl->{'param'} || $pl->{'prm'};
  	if ($pl->{'prmexpr'}) {
    		$prm=&cmlcalc::calculate({id=>$id,expr=>$pl->{'prmexpr'}})->{value};
  	}   
	if ($prm) {  
	  	$sexpr="p($prm)";
	  	$expr=$cmlmain::prm->{$prm}->{extra}->{formula};
	  	$inner->{expr}=$expr;
	  	$multiple='multiple' if $cmlmain::prm->{$prm}->{extra}->{single} ne 'y';
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
	if ($pl->{'defoptname'}) {
		$defopt="<option value='$defoptvalue'>$pl->{'defoptname'}</option>"
	}  elsif (!$multiple)  {
		$defopt="<option value=''>Не задан</option>"
	}
  	if (defined $sexpr) {
  		undef $inner->{selectedlist};
  		for (split(';',&cmlcalc::calculate({id=>$id,expr=>$sexpr})->{value})) {$inner->{selectedlist}->{$_}=1}
  	}	
  
  	if ($cmlcalc::CGIPARAM->{$name}) {
  		undef $inner->{selectedlist};
  	 	$inner->{selectedlist}->{$cmlcalc::CGIPARAM->{$name}}=1
  	}	
  
  	unless ($data) {
  		$data="<cml:option param='$optionid'><cml:text param='$optionparam'/></cml:option>";
  	}
  	return "<select name='$name' $param $multiple>$defopt".
  		tag_list({data=>$data,inner=>$inner,param=>$param}).
  		cmlparser({data=>$_[0]->{data},inner=>$inner}).
  		"</select>";
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
  else {$name="_p$prm"}
  $inner->{name}=$name;
  if (defined $sexpr) {
  	$inner->{selected}=&cmlcalc::calculate({id=>$id,expr=>$sexpr})->{value};
  }	
  unless ($data) {$data="<cml:radiobutton param='$optionid'><cml:text param='_NAME'/></cml:radiobutton><br>"}
  return tag_list({data=>$data,inner=>$inner,param=>$param});
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
		my $orderby='_INDEX';
		my $ordertype;
		my $limit;
		my $start;
		my $notop;
		my $filter;
		my $filterexpr;
		my @filarray;
		my @filexparray;
	
  	if ($param=~s/(\W)container=(['"])(.+?)\2/$1/i)      {$container=$3 } else {$container=1}
  	if ($param=~s/(\W)orderby=(['"])(.+?)\2/$1/i)        {$orderby=$3 } 
  	if ($param=~s/(\W)ordertype=(['"])(.+?)\2/$1/i)      {$ordertype=$3 } 
  	if ($param=~s/(\W)limit=(['"])(.+?)\2/$1/i)          {$limit=$3 } 
	if ($param=~s/(\W)start=(['"])(.+?)\2/$1/i)          {$start=$3 }  else {$start=0} 	
  	my $pl=fetchparam($param,['selected','selexpr']);
  	

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
		
		unless ($orderby eq '_MANUAL') {
  			if ($orderby) {
  				my $ordertype=$cmlmain::prm->{$orderby}->{type} || '';
  				if ( $ordertype eq 'DATE' || $ordertype eq 'NUMBER' || $orderby eq '_INDEX') {
  					@splist=sort {
  						&cmlcalc::calculate({id=>$a,expr=>"p($orderby)"})->{value} <=> &cmlcalc::calculate({id=>$b,expr=>"p($orderby)"})->{value}; 
  					} @splist;
  				} else {
  					@splist=sort {
  						&cmlcalc::calculate({id=>$a,expr=>"p($orderby)"})->{value} cmp &cmlcalc::calculate({id=>$b,expr=>"p($orderby)"})->{value}; 
  					} @splist;
  				}		
  			}
		}		
  		

  		
		if (lc $ordertype eq 'desc') {
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
		
		my $contid=1;
  		for (my $i=$start;$i<$limit+$start;$i++) {
  			next if $splist[$i] eq 'NULL';
  			if ($i>$#splist) {last}
 			$inner->{objid}=$splist[$i];
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
  				$body.=cmlparser({data=>$data,inner=>$inner})
  			}	
		}	  
	}
  	return  $body;
  
  	 
}	

sub tag_setvar {
	my $param=$_[0]->{param};
  my $inner; %{$inner}=%{$_[0]->{inner}};
	my $varname;
	my $varvalue;
	
	my $id=$inner->{objid};
	
	if      ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)        {	$varname=$3    }
	
	if      ($param=~s/(\W)value=(['"])(.+?)\2/$1/i)          {	$varvalue=$3    }
	elsif      ($param=~s/(\W)param=(['"])(.+?)\2/$1/i)       {	  $varvalue=&cmlcalc::calculate({id=>$id,expr=>"p($3)"})->{value}	}
	
	$inner->{var}->{$varname}=$varvalue;
	return cmlparser({data=>$_[0]->{data},inner=>$inner});
}	

sub tag_var {
	my $param=$_[0]->{param};
	
	my $varname;
	if      ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)        {	$varname=$3    }
	
	return $_[0]->{inner}->{var}->{$varname};
}	




sub tag_use
{
	my $param=$_[0]->{param};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
	
	my $id;
	my $key;
	my $paramname;

	my $matrix;
	if      ($param=~s/(\W)id=(['"])(.+?)\2/$1/i)       {
		$id=$3;     
		
		if (lc $id eq 'matrix') {$id=$inner->{matrix}->{tabkey} }
	}
	elsif    ($param=~s/(\W)idcgi=(['"])(.+?)\2/$1/i)    {
		$id=$cmlcalc::CGIPARAM->{$3};
	}
	elsif    ($param=~s/(\W)namecgi=(['"])(.+?)\2/$1/i)  {
		$key=param($3);
	  	&cmlmain::checkload({key=>$key});
          	$id=$cmlmain::nobj->{$key}->{ind};
          	unless ($id)  {return "[ Use ERROR! $key NOT FOUND ]"}
          	
	}
	elsif 	($param=~s/(\W)uname=(['"])(.+?)\2/$1/i)  {
		$key=$3;
          	$id='u'.$cmlmain::nobj->{$key}->{ind};
          	
	}
	elsif ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)  {
		$key=$3;
		&cmlmain::checkload({key=>$key});
    		$id=$cmlmain::nobj->{$key}->{id};
	}
	
	else     {$id=$inner->{objid}}
	

	if       ($param=~s/(\W)pa?ra?m=(['"])(.+?)\2/$1/i)       {
		$paramname=$3;
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
			
	}
	else {$matrix=$inner->{matrix}}


        if   ($param=~s/(\W)paramtab=(['"])(.+?)\2/$1/i)       { 
		my $tabparam=$3;
		my $tabvalue;
		if       ($param=~s/(\W)valuetab=(['"])(.+?)\2/$1/i)       { $tabvalue=$3 }
		elsif    ($param=~s/(\W)valuetabcgi=(['"])(.+?)\2/$1/i)       { $tabvalue=param($3) }
		$id=$tabvalue;
 	        $matrix->{dim}->{$tabparam}->{current}=$tabvalue;
 	        $matrix->{tabkey}="t_$matrix->{id}_$matrix->{param}_".join('_',map {$_=$matrix->{dim}->{$_}->{current}} split(/\s*;\s*/,$cmlmain::prm->{$matrix->{param}}->{extra}->{param}));
	}
        
	
	$inner->{objid}=$id;
	$inner->{matrix}=$matrix;
	$inner->{parent}=$id;
        return cmlparser({data=>$_[0]->{data},inner=>$inner});
}


sub tag_actionlink {
	use strict;
	my $param=$_[0]->{param};
	my $inner=$_[0]->{inner};
	
	my $method;
	my $title;
	
	my $pl=fetchparam($param,[
		'action','id','upobj','up','upkey','link','linkval',
		'setflag','name','value','prm','param',
		'piclist','filelist','vidlist',
		'template', 'editprm'
	]);
	
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
	
	
	$title=cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}});
	$title=$pl->{action} unless $title;
	
	if ($pl->{action} eq 'EDIT') {
		&cmlmain::checkload({id=>$pl->{id}});
		my $tid=$cmlmain::lobj->{$pl->{id}}->{upobj};
		my $kn=$cmlmain::obj->{$tid}->{key};
		if ($cmlcalc::ENV->{NOFRAMES}) {
		 	return "<a href='?page=EDIT_$kn&id=$pl->{id}' $param>$title</a>";
		} else {
			return "<a href='?body=EDIT_$kn&id=$pl->{id}' $param>$title</a>";
		} 		 
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
	}	
	
	$method="BASE$pl->{action}METHOD";	
	my @hlist;
	push(@hlist,"parsemethod=$method");
	my @plist=('view','menu','body','ukey','editprm','piclistprm','filelistprm');
	for (@plist) {
		push(@hlist,"$_=$cmlcalc::CGIPARAM->{$_}") if $cmlcalc::CGIPARAM->{$_};
	}	
		
	for (qw (id up upobj parseid link linkval setflag name value)) {
		push(@hlist,"$_=$pl->{$_}") if $pl->{$_};	
	}

	my $hstr=join('&',@hlist);
	if ($pl->{action} eq 'DEL') {
		if ($cmlmain::GLOBAL->{DOUBLECONFIRM}) {
			$param.=qq(onclick='return confirm("Вы уверены что хотите удалить объект") && confirm("Продолжить?")');
		} else {
			$param.=qq(onclick='return confirm("Вы уверены что хотите удалить объект")');
		}	
	}
	
	return "<a href='?$hstr' $param>$title</a>";
	
}	

sub tag_a	{
	my $param=$_[0]->{param};

	my $pl=fetchparam(\$param,[
		'mode','name','href','pagenum',
		'parser','adminparser',
		'extraprm','adminextraprm',
		'param','prm','expr','id',
		'ifprm','ifparam','ifexpr',
	]);
	
	my $ql;
	my @qls;
	my $mode=$pl->{'mode'} || ''; 
	if ($pl->{'name'}) {
		$ql="/view/$pl->{'name'}" 	
	} elsif ($pl->{'href'}) {	
		$ql=$pl->{'href'};
		if ($ql!~/^(http|\/|\?)/ && $ql ne '#') {$ql="http://$ql"}
	} elsif ($pl->{'pagenum'}) {	
		my $pid=$pl->{'pagenum'};
		$ql=$cmlcalc::QUERYSTRING;
		$ql=~s/pagenum=\d+/pagenum=$pid/;
		$ql.="&pagenum=$pid" if $ql!~/pagenum=\d+/;
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
  	if ($pl->{'param'} || $pl->{'prm'}) {
    		my $prm=$pl->{'param'}||$pl->{'prm'};
    		$expr="p($prm)";
  	} elsif ($pl->{'expr'}) {
  		$expr=$pl->{'expr'};
  	}	
  
  	if ($expr) {
  		my $id=$pl->{'id'} || $_[0]->{inner}->{objid};
 		my $v=&cmlcalc::calculate({id=>$id,expr=>$expr});
 		if ($v->{type} eq 'FILE') { $ql="$cmlmain::GLOBAL->{FILEURL}/$v->{value}" }
 		else {
 			$ql=$v->{value};
 			if ($ql!~/^(http|\/|\?)/) {$ql="http://$ql"}
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
  		my $id=$pl->{'id'} || $_[0]->{inner}->{objid};
 		my $v=&cmlcalc::calculate({id=>$id,expr=>$ifexpr});
 		unless ($v->{'value'}) {
 			$ifval=0;
 		}
  	}
	
		
  	$ql='/' if $ql eq '//';

	my $bstr;
	my $estr=$ifval?'</a>':'';
	if ($ifval) {
  		if ($mode eq 'openwindow') {
  			$bstr="<a href=\"javascript:openwindow('$ql')\" $param>";
  		}	else {
 			$bstr="<a href='$ql' $param>";
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
	my $pl=fetchparam(\$param,['value','param','sel','selexpr']);
	
	if (defined $pl->{'value'}) { 
	  	$value=&cmlcalc::calculate({id=>$id,expr=>$pl->{'value'}})->{value};
	  	$valuestr="value='$value'"
	}
	if ($pl->{'param'}) {
	  	$value=&cmlcalc::calculate({id=>$id,expr=>"p($pl->{param})"})->{value};
	  	$valuestr="value='$value'"
	}
	$valuestr="value='$id'" unless $valuestr;
	
	
	if ($pl->{'sel'}) {
	  	my $v=&cmlcalc::calculate({id=>$id,expr=>$pl->{'sel'}})->{value};
	  	if ($v eq $value) {$selexpr='selected'}
	} elsif ($pl->{'selexpr'}) { 
	  	my $v=&cmlcalc::calculate({id=>$id,expr=>$pl->{'selexpr'}})->{value};
	  	if ($v) {$selexpr='selected'}
	}  elsif (defined $_[0]->{inner}->{selected}) {
	  	#if ($_[0]->{inner}->{selected}->{$value} || $_[0]->{inner}->{selected}->{"p$value"}) 
	  	$selexpr='selected'
	}	
	my $dt=$_[0]->{data}?cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}}):&cmlcalc::calculate({id=>$id,expr=>"p(_NAME)"})->{value};
	return "<option $selexpr $valuestr $param>$dt</option>";
	
	
}	

sub tag_radiobutton {
	my $param=$_[0]->{param};
	my $selexpr;
	my $sel;
	my $value;
	my $valuestr;
	my $id=$_[0]->{inner}->{objid};
	my $name;
	
	if ($param=~s/(\W)value=(['"])(.+?)\2/$1/i) { 
	  $value=&cmlcalc::calculate({id=>$id,expr=>$3})->{value};
	  $valuestr="value='$value'"
	}
  if ($param=~s/(\W)param=(['"])(.+?)\2/$1/i) { 
	  $value=&cmlcalc::calculate({id=>$id,expr=>"p($3)"})->{value};
	  $valuestr="value='$value'"
	}
  unless ($valuestr) {
  	$value=$id;
  	$valuestr="value='$id'"
  }

	
	if ($param=~s/(\W)sel=(['"])(.+?)\2/$1/i) { 
	  my $v=&cmlcalc::calculate({id=>$id,expr=>$3})->{value};
	  if ($v eq $value) {$selexpr='checked'}
	}
	elsif ($param=~s/(\W)selexpr=(['"])(.+?)\2/$1/i) { 
	  my $v=&cmlcalc::calculate({id=>$id,expr=>$3})->{value};
	  if ($v) {$selexpr='checked'}
	}
	elsif (defined $_[0]->{inner}->{selected}) {
	  if ($_[0]->{inner}->{selected} eq $value) {$selexpr='checked'}
		
	}	

  if ($param=~s/(\W)name=(['"])(.+?)\2/$1/i) { 
			$name=$3;
	}
 	elsif (defined $_[0]->{inner}->{name}) {
	  $name="name='$_[0]->{inner}->{name}'"
	}	

	return "<input type='radio' $selexpr $valuestr $param $name>".cmlparser({data=>$_[0]->{data},inner=>$_[0]->{inner}});
	
	
}	



sub tag_container {
	return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}});
}	

sub tag_image {
	return tag_img(@_);
}	

sub tag_img 	{
	my $param=$_[0]->{param};
	my $id;
	my $key;
	my $src;
	my $alt;
  	my $expr;
  	my $path='relative';
	
	
	
	if       ($param=~s/(\W)id=(['"])(.+?)\2/$1/i)    {$id=$3    }
	elsif    ($param=~s/(\W)idcgi=(['"])(.+?)\2/$1/i) {$id=param($3)}
	else     {$id=$_[0]->{inner}->{objid}}

	if ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)  {$key=$3   }
	if ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)  {$key=$3; undef $id   }
	
 	if ($param=~s/(\W)pa?ra?m=(['"])(.+?)\2/$1/i) {$pkey=$3; $expr="p('$pkey')" }		 
	if ($param=~s/(\W)expr=(['"])(.+?)\2/$1/i) {$expr=$3; }		 
	
	if       ($param=~s/(\W)alt=(['"])(.+?)\2/$1/i)    {$alt=$3}
	elsif    ($param=~s/(\W)altpa?ra?m=(['"])(.+?)\2/$1/i)    {
			my $av=&cmlcalc::calculate({key=>$key,id=>$id,expr=>"p($3)"});
			$alt=$av->{value};
	}
	
	if       ($param=~s/(\W)path=(['"])(.+?)\2/$1/i)    {$path=$3}
	$path='absolute' if $path=~/abs/i;
	
	
	
	if       ($param=~s/(\W)src=(['"])(.+?)\2/$1/i)    {$src=$3    }
	else {
		undef $alt if $alt eq 'NULL'; 
		unless ($expr) {$expr="p(PIC)"}
		my $v=&cmlcalc::calculate({key=>$key,id=>$id,expr=>$expr});
		unless ($v->{value}) {
			if ($alt) {return $alt}
			return undef
		}
		my $pstr=$path eq 'absolute'?$cmlmain::GLOBAL->{ABSFILEURL}:$cmlmain::GLOBAL->{FILEURL};
		$src="$pstr/$v->{value}";
	}
 	return "<img src='$src' $param alt='$alt'>";
}	


sub tag_video 	{
	my $param=$_[0]->{param};

	my $key;
	my $src;
	my $psrc;
  	my $path='relative';
	
	
	my $pl=fetchparam($param,[
		'id','name','key', 'param' ,'prm','expr', 
		'previewprm','previewparam','path', 'width', 
		'height'
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

	my $width=$pl->{'width'} || 320;
	my $height=$pl->{'height'} || 260;

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



 	return qq(	
                <script type="text/javascript">
		swfobject.embedSWF("/swf/fp.swf?video=$src&image=$psrc", "playerDiv", "$width", "$height", "8.0.0", "/swf/expressInstall.swf");
		</script>		
 		<div id="playerDiv">
			<h1>Для проигрывания роликов необходим Flash Player версии 8 или выше</h1>
			<p><a href="http://www.adobe.com/go/getflashplayer"><img border='0' src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Получить Adobe Flash player" /></a></p>
		</div>
			);

}	



sub tag_execute {
	my $param=$_[0]->{param};
	my $id;
	my $method;
	my $key;
	
	if    	($param=~s/(\W)id=(['"])(.+?)\2/$1/i)        {$id=$3    }
	if    	($param=~s/(\W)key=(['"])(.+?)\2/$1/i)       {$key=$3    }
	else    {$id=$_[0]->{inner}->{objid}}
	
	if    	($param=~s/(\W)method=(['"])(.+?)\2/$1/i)    {$method=$3    }
	my $res=&cmlcalc::execute({key=>$key,id=>$id,method=>$method});
	if ($res) {return undef} 
	else { return "[ Execute ERROR! (id:$id key:$key) ]" }
}


sub tag_include {
  	my $param=$_[0]->{param};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
  	my $key;
  	my $pkey;
  	my $expr;
  	my $id;

  	if    	($param=~s/(\W)id=(['"])(.+?)\2/$1/i)       {$id=$3    }
  	elsif ($param=~s/(\W)idexpr=(['"])(.+?)\2/$1/i)    {
  	    $id=&cmlcalc::calculate({id=>$_[0]->{inner}->{objid},expr=>$3})->{value}
  	}

  	
  	elsif   ($param=~s/(\W)idcgi=(['"])(.+?)\2/$1/i)    {$id=param($3)}
  	elsif      ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)     {$key=$3   }
  	elsif      ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)     {$key=$3   }
  	elsif   ($param=~s/(\W)namecgi=(['"])(.+?)\2/$1/i)  {$key=param($3)}
  	else    {$id=$inner->{objid}}
  	
  	if ($param=~s/(\W)param=(['"])(.+?)\2/$1/i) {$pkey=$3; $expr="p('$pkey')" }
  	if ($param=~s/(\W)prm=(['"])(.+?)\2/$1/i) {$pkey=$3; $expr="p('$pkey')" }
  	
    	unless ($expr) {$expr='p(PAGETEMPLATE)'} 
  	

  	#my $v=&cmlcalc::calculate({key=>$key,expr=>$expr,id=>$id,parent=>$inner->{objid}});
  	my $v=&cmlcalc::calculate({key=>$key,expr=>$expr,id=>$id,noparse=>1});
  	my $body=$v->{value};
	if ($body) {
		return  cmlparser({data=>$body, inner=>$inner}); 
	}	else       {
		return "[ Include ERROR! (id:$id key:$key expr:$expr) ]"
	}
}

sub tag_text {
  	my $param=$_[0]->{param};
  	my $key;
  	my $ukey;
  	my $uid;
  	my $pkey;
  	my $expr;
  	my $id;
    my $frmt;
    my $ptype;
    
    if 			($param=~s/(\W)value=(['"])(.+?)\2/$1/i)     {return $3}
    elsif   ($param=~s/(\W)formparam=(['"])(.+?)\2/$1/i)     {return $cmlcalc::CGIPARAM->{"_p$3"}}
    
    if ($param=~s/(\W)format=(['"])(.+?)\2/$1/i)     {$frmt=$3}
  	if ($param=~s/(\W)param=(['"])(.+?)\2/$1/i)     {$pkey=$3; $expr="p('$pkey')" }
    if ($param=~s/(\W)prm=(['"])(.+?)\2/$1/i)       {$pkey=$3; $expr="p('$pkey')" }
  
  
  	if    ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)      {$key=$3   }
  	elsif ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)       {$key=$3   }
  	elsif ($param=~s/(\W)ukey=(['"])(.+?)\2/$1/i)      {$ukey=$3  }
  	elsif ($param=~s/(\W)uid=(['"])(.+?)\2/$1/i)       {$uid=$3   }
  	elsif ($param=~s/(\W)namecgi=(['"])(.+?)\2/$1/i)   {$key=param($3)}
  	elsif ($param=~s/(\W)idexpr=(['"])(.+?)\2/$1/i)    {
  	    $id=&cmlcalc::calculate({id=>$_[0]->{inner}->{objid},expr=>$3})->{value}
  	    	
  	}
  	elsif ($param=~s/(\W)idcgi=(['"])(.+?)\2/$1/i)     {$id=param($3)}
  	elsif ($param=~s/(\W)id=(['"])(.+?)\2/$1/i)        {$id=$3; 
  		if (lc ($id) eq '_matrix') {$id=$_[0]->{matrix}->{tabkey}} 
  		if (lc ($id) eq '_parent') {$id=$_[0]->{inner}->{parent}} 
  	}
  	else  {$id=$_[0]->{inner}->{objid}} 

        my $rs;
        if (lc ($id) eq '_iterator')        {$result=$_[0]->{inner}->{iterator}}
        elsif (lc ($id) eq '_iteratornext') {$result=$_[0]->{inner}->{iteratornext}}
        elsif (lc ($id) eq '_iteratordelta') {$result=$_[0]->{inner}->{iteratornext}}
        elsif ($param=~s/(\W)expr=(['"])(.+?)\2/$1/i)     {
        	$expr=$3;
        	$expr=~s/_iterator(\W)/$_[0]->{inner}->{iterator}$1/ig;
        	$expr=~s/_iteratordelta(\W)/$_[0]->{inner}->{delta}$1/ig;
        	$expr=~s/_iteratornext(\W)/$_[0]->{inner}->{iteratornext}$1/ig;
        	$rs=&cmlcalc::calculate({id=>$id,expr=>$expr});
        } else { 
        	unless ($expr) {$expr='p(TXT)'}
        	$rs=&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$expr,uid=>$uid});
        }
        
        if ($param=~s/(\W)typeexpr=(['"])(.+?)\2/$1/i)     {
        	$ptype=&cmlcalc::calculate({id=>$id,expr=>$3});
        }	
        
        if (	($pkey && $cmlmain::prm->{$pkey}->{type} eq 'LIST') || ($ptype->{value} && $ptype->{value} eq 'LIST' ) ) {
        	$rs=&cmlcalc::calculate({id=>$rs->{value},expr=>'p(_NAME)'});
      	}	
        my $result=$rs->{value};
  			$result=sprintf ($frmt,$result) if $frmt;
        $result="[[ $expr ]]" if !$result && $_[0]->{inner}->{debug};
			return $result;
	return $result;
}


sub tag_loop {
	my $param=$_[0]->{param};
 	my $data=$_[0]->{data};
	my $inner; %{$inner}=%{$_[0]->{inner}};

	
	my $counter;
	my $retval;
	if    ($param=~s/(\W)counter=(['"])(.+?)\2/$1/i)      {$counter=$3   }
	for(my $i=1;$i<=$counter;$i++) {$retval.=cmlparser({data=>$data,inner=>$inner})}
	return $retval;
		
	
}	

sub tag_for {
  	my $param=$_[0]->{param};
  	my $key;
  	my $sexpr;
  	my $eexpr;
  	my $start;
  	my $end;
  	my $delta;
  	my $expr;
  	my $id;
       	my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};


  	if ($param=~s/(\W)startparam=(['"])(.+?)\2/$1/i)     {$sexpr="p($3)" }
  	if ($param=~s/(\W)endparam=(['"])(.+?)\2/$1/i)       {$eexpr="p($3)" }
	if ($param=~s/(\W)delta=(['"])(.+?)\2/$1/i)          {$delta=$3}
  
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
  	for (my $it=$start;$it<$end;$it+=$delta ){
  		$inner->{iterator}=$it;
  		if ($it+$delta<=$end) {$inner->{iteratornext}=$it+$delta} else {$inner->{iteratornext}=$end;}
  		$retval.=cmlparser({data=>$data,inner=>$inner});
	}	
	return $retval;
}



sub tag_date {
  	my $param=$_[0]->{param};
  	my $key;
  	my $pkey;
  	my $expr;
  	my $id;
  	my $frmt;

  	if    ($param=~s/(\W)param=(['"])(.+?)\2/$1/i)     {$pkey=$3; $expr="p('$pkey')" }
  	if    ($param=~s/(\W)expr=(['"])(.+?)\2/$1/i)     {$expr=$3 }
  	if    ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)      {$key=$3   }
  	elsif ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)       {$key=$3   }
  	elsif ($param=~s/(\W)ukey=(['"])(.+?)\2/$1/i)      {$ukey=$3  }
  	elsif ($param=~s/(\W)uid=(['"])(.+?)\2/$1/i)       {$uid=$3   }
  	elsif ($param=~s/(\W)namecgi=(['"])(.+?)\2/$1/i)   {$key=param($3)}
  	elsif ($param=~s/(\W)idcgi=(['"])(.+?)\2/$1/i)     {$id=param($3)}
  	elsif ($param=~s/(\W)id=(['"])(.+?)\2/$1/i)        {$id=$3; if (lc ($id) eq '_matrix') {$id=$_[0]->{matrix}->{tabkey}} }
  	else  {$id=$_[0]->{inner}->{objid}} 
  	 

        if (lc ($id) eq '_iterator')        {$result=$_[0]->{inner}->{iterator}}
        elsif (lc ($id) eq '_iteratornext') {$result=$_[0]->{inner}->{iteratornext}}
        elsif ($param=~s/(\W)expr=(['"])(.+?)\2/$1/i)     {
        	$expr=$3;
        	$expr=$pl->{'expr'};
        	$expr=~s/_iterator(\W)/$_[0]->{inner}->{iterator}$1/ig;
        	$expr=~s/_iteratordelta(\W)/$_[0]->{inner}->{delta}$1/ig;
        	#$result=eval "$expr";
        	$expr=~s/_iteratornext(\W)/$_[0]->{inner}->{iteratornext}$1/ig;
        #else { 
        	$result=&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$expr,uid=>$uid});
        	$result=$result->{value} if ref $result eq 'HASH';
        #};
 	
        

  	
  	if ($param=~s/(\W)format=(['"])(.+?)\2/$1/i)     {$frmt=$3} else {$frmt='%d.%m.%y %H:%M'}

  	return undef unless $result;
	return strftime $frmt,gmtime($result);
	
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
  		'renameparam','renameprm', 'matrix'  		
  		'renameparam','renameprm', 'matrix','ukey','listprm'  		
  		]);
	$param=$pl->{'str'};
	
	if    	($pl->{'id'})    {
	    	$id=$pl->{'id'};
	} elsif ($pl->{'key'})    {
	  	&cmlmain::checkload({key=>$pl->{'key'}});
  		$id=$cmlmain::nobj->{$pl->{'key'}}->{id};
  		$inner->{objid}=$id;
	}	else   {
		$id=$inner->{objid}
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
	} elsif ($id ne $inner->{objid}) {
		$parserid=$inner->{objid}
	}

	if   ($pl->{'parser'}) {
		$parser=$pl->{'parser'}
	} elsif ($parserid=~/^u/) {
		$parser='BASEPARSER'
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
		$action=$pl->{'action'}	
	} elsif ($view  && $cmlcalc::CGIPARAM->{_MODE} eq 'SITE') {
		$action="/_$view" 	
	} elsif ($tview && $cmlcalc::CGIPARAM->{_MODE} eq 'SITE') {
			$action="/__$tview" 	
	}
  	$actionstr="action='$action'" if $action;
	
	my $data="<form $param method='$method' enctype='multipart/form-data' $actionstr>";
	

	if ($view) {$data.="<input type='hidden' name='view' value='$view'>"}
	elsif ($tview) {$data.="<input type='hidden' name='tview' value='$tview'>"}
	elsif ($body) {$data.="<input type='hidden' name='body' value='$body'>"}
	elsif ($menu) {$data.="<input type='hidden' name='menu' value='$menu'>"}
	elsif ($page) {$data.="<input type='hidden' name='page' value='$page'>"}
	else {$data.="<input type='hidden' name='action' value='go'>"}
	
	$data.="<input type='hidden' name='id' value='$id'>";
	$data.="<input type='hidden' name='param' value='$pkey'>";
	$data.="<input type='hidden' name='parsemethod' value='$parser'>";
	$data.="<input type='hidden' name='parseid' value='$parserid'>" if $parserid;
	$data.="<input type='hidden' name='listprm' value='$pl->{listprm}'>" if $pl->{'listprm'};
	
	if ($pl->{'postparser'}) {$data.="<input type='hidden' name='postparser' value='$pl->{postparser}'>";}
	if ($pl->{'preparser'}) {$data.="<input type='hidden' name='preparser' value='$pl->{preparser}'>";}
	if ($pl->{'insertinto'}) {$data.="<input type='hidden' name='insertinto' value='$pl->{insertinto}'>";}
	if ($pl->{'link'}) {$data.="<input type='hidden' name='link' value='$pl->{link}'>";}
	if ($pl->{'alert'}) {$data.="<input type='hidden' name='alerttext' value='$pl->{alert}>"}
	if ($pl->{'ukey'}) {$data.="<input type='hidden' name='ukey' value='$pl->{ukey}'>"}
	if ($renameprm) {$data.="<input type='hidden' name='renameprm' value='$renameprm'>"}
	
	for my $p qw( editprm piclistprm filelistprm ) {
		my $pv=$pl->{$p} || $cmlcalc::CGIPARAM->{$p};
		$data.="<input type='hidden' name='$p' value='$pv'>" if $pv;
	}
	$inner->{matrix}=$pl->{matrix};
	
	$data.=cmlparser({data=>$_[0]->{data},inner=>$inner});
	$data.="</form>";
	return $data;
}	

sub tag_inputpic {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
  	my $inner; %{$inner}=%{$_[0]->{inner}};
	
		'param','prm','name'
		'param','prm','name','id'
  	my $id=$pl->{id} || $_[0]->{inner}->{objid};
	my $name=$pl->{name}||"_f$prm";
	
  	return tag_img({data=>$data,inner=>$inner,param=>$_[0]->{param}})."<input type='file' $param name='$name'>";
}

sub tag_inputparam {
	my $param=$_[0]->{param};
	my $data=$_[0]->{data};
  my $inner; %{$inner}=%{$_[0]->{inner}};

  
	my $prm;
	my $name;
	my $id;
	my $key;	
  if ($param=~/(\W)key=(['"])(.+?)\2/i)       {$key=$3   }
 	elsif ($param=~/(\W)id=(['"])(.+?)\2/i)     {$id=$3   }
  else {$id=$_[0]->{inner}->{objid}}
	
	
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

  	my $pl=fetchparam($param,[
  		'key','id','textareaid','value','expr','type',
  		'param','prm','prmexpr','name','rows','cols',
  	]);
  
  	my $id=$pl->{id} || $_[0]->{inner}->{objid};


	my $value;  	  
  	if ($pl->{value})   { 	
  		$value=$pl->{value}      	
	} elsif ($pl->{expr})   { 	
  		$value=&cmlcalc::calculate({id=>$id,key=>$pl->{key},expr=>$pl->{expr}})->{value}      	
  	}

	my $rows;
	my $cols;
	my $mode='input';
	my $prm=$pl->{param} || $pl->{prm};
	if ($prm)      {	
 		if ($cmlmain::prm->{$prm}->{type} eq 'LONGTEXT') {$mode='textarea', $rows=20, $cols=75}
		if ($cmlmain::prm->{$prm}->{type} eq 'NUMBER') {$cols=5}
	}
  	if ($pl->{prmexpr})      { 
    		$prm=&cmlcalc::calculate({id=>$id,key=>$pl->{key},expr=>$pl->{prmexpr}})->{value};
  	}   
  

  	my $name;
	if ($pl->{name}) {
		$name=$pl->{name}
	} elsif ($_[0]->{inner}->{matrix}) {
		$name="_o${id}_p${prm}";
	} else {
		$name="_p$prm";
	}

    	if ($prm && !(defined $value)) {
  		$value=&cmlcalc::calculate({id=>$id,key=>$pl->{key},expr=>"p($prm)",noparse=>1})->{value};
	} elsif ($cmlcalc::CGIPARAM->{$name} && !defined($value)) { 
		$value = $cmlcalc::CGIPARAM->{$name}
	}
	
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

  	my $typestr;
  	if ($pl->{type}) {
  		$typestr="type='$pl->{type}"; 
  		$mode='input';
  	}	
	if ($mode eq 'input') {
		 my $sizestr;
		 if ($cols) {$sizestr="size='$cols'"}
		 return "<input value='$value' $param $sizestr name='$name' $typestr>";
		my $cls=$cmlmain::prm->{$prm}->{extra}->{visual}?'class="mceEditor"':'';
	    	my $tidstr;
	    	$tidstr="id='$pl->{textareaid}'" if $pl->{textareaid};
		return "<textarea rows='$rows' cols='$cols' $param name='$name' $tidstr>$ev</textarea>";
		return "<textarea rows='$rows' cols='$cols' $param name='$name' $tidstr $cls>$ev</textarea>";
	}	
}	



sub tag_inputdate {
	my $param=$_[0]->{param};
	my $id=$_[0]->{inner}->{objid};
	
	
	my $value;
	my $frmt;
	my $prm;
	my $name;
	my $frmtstr;
	
	if ($param=~s/(\W)param=(['"])(.+?)\2/$1/i)      {	
			$prm=$3; 
			$value=&cmlcalc::calculate({id=>$id,expr=>"p($prm)"})->{value}; 
	}
	if ($param=~s/(\W)format=(['"])(.+?)\2/$1/i)      {	
	  $frmt=$3; 
  } elsif ($cmlmain::prm->{$prm}->{extra}->{format}) {
	  $frmt=$cmlmain::prm->{$prm}->{extra}->{format};
	}	

  if ($frmt) { 
  	$value=strftime($frmt,gmtime($value)) ;
  	$frmtstr="<input type=hidden name='_d$prm' value='$frmt'>";
 	} 
		
	
	if ($param=~s/(\W)name=(['"])(.+?)\2/$1/i)       {$name=$3   }
  else {$name="_p$prm"}

	
	return "<input value='$value' $param name='$name'>$frmtstr";
}	


sub tag_checkbox {
	my $param=$_[0]->{param};
	my $checked;

	
	
	my $id=$_[0]->{inner}->{objid};
	
	my $pl=fetchparam($param,['param','prm','name','value','nohidden']);
	my $prm=$pl->{prm} || $pl->{param};
	if (&cmlcalc::calculate({id=>$id,expr=>"p($prm)"})->{value}==1 ) {$checked='checked'}
	my $checked=&cmlcalc::calculate({id=>$id,expr=>"p($prm)"})->{value}==1?'checked':'';

	my $name;
	if ($pl->{name}) {
		$name=$pl->{name}
	} elsif ($_[0]->{inner}->{matrix}) {
		$name="_o${id}_p${prm}";
	} else {
		$name="_p$prm";
	}
	  
	$param=$pl->{str};
	my $hstr=$pl->{'nohidden'}?'':"<input type='hidden' value='0' name='$name'>";
	return "<input type='checkbox' value='$value' $checked name='$name' $param>$hstr";
}	

sub tag_deletebutton {
	my $param=$_[0]->{param};
  	my $pl=fetchparam($param,['link','param','prm','method','parser','parseprm','parseid','deleteid']);
  	$pl->{prm}=$pl->{param} if $pl->{param};
    	$pl->{method}=$pl->{parser} if $pl->{parser};
    	my $parseid=$pl->{parseid} || $_[0]->{inner}->{objid};
    	my @hlist;
	push(@hlist,"parseid=$parseid");
	if ($pl->{prm}) {
		return undef unless &cmlcalc::p($pl->{prm},$_[0]->{inner}->{objid});
		push(@hlist,"parsemethod=BASECLEARPARAMMETHOD");
		push(@hlist,"prm=$pl->{prm}");
	} elsif ($pl->{method})	{
		push(@hlist,"parsemethod=$pl->{method}");
	} else {
		push(@hlist,"parsemethod=BASEDELMETHOD");
	my @plist=('view','menu','body','ukey','id','page','orderby','ordertype');
	my @plist=('view','menu','body','ukey','id','page','orderby','ordertype','editprm','piclistprm','filelistprm','childlistprm','childukey','listprm','link');
	for (@plist) {
		push(@hlist,"$_=$cmlcalc::CGIPARAM->{$_}") if $cmlcalc::CGIPARAM->{$_};
	}	
	push (@hlist,"link=$pl->{link}") if $pl->{link};
	push (@hlist,"parseprm=$pl->{parseprm}") if $pl->{parseprm};
	push (@hlist,"deleteid=$pl->{deleteid}") if $pl->{deleteid};
	
  	my $hstr=join('&',@hlist);
  	
	if ($cmlmain::GLOBAL->{DOUBLECONFIRM}) {
		return qq(<a href='?$hstr' onclick='return confirm("Вы уверены что хотите удалить объект") && confirm("Продолжить?")'><img border=0 src='$imgsrc' alt='Удалить'></a>);
	} else {
		return qq(<a href='?$hstr' onclick='return confirm("Вы уверены что хотите удалить объект")'><img border=0 src='$imgsrc' alt='Удалить'></a>);		
	}	
	
}	


sub tag_changebutton {
	my $imgsrc=$cmlmain::POSTBUTTONURL;
	return "<input type=image src='$imgsrc' width='119' height='24' value='ОК'>";
}	

sub tag_if {
	
	my $param=$_[0]->{param};
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
		undef $_[0]->{uinner}->{cond};
		if ($cond) {
			$_[0]->{uinner}->{cond}=$cond; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}	
	} elsif ($param=~s/(\W)cgiparamexist=(['"])(.+?)\2/$1/i)      {
		my $cond=$cmlcalc::CGIPARAM->{$3} ne '';
		$cond=!$cond if $not;
		undef $_[0]->{uinner}->{cond};
		if ($cond) {
			$_[0]->{uinner}->{cond}=1; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
	} elsif ($param=~s/(\W)view=(['"])(.+?)\2/$1/i)      {
		my $cond=$cmlcalc::CGIPARAM->{view} eq $3;
		$cond=!$cond if $not;
		undef $_[0]->{uinner}->{cond};
		if ($cond) {
			$_[0]->{uinner}->{cond}=1; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
  	} elsif ($param=~s/(\W)param=(['"])(.+?)\2/$1/i ||
        $param=~s/(\W)prm=(['"])(.+?)\2/$1/i   )  {
		my $cond="p($3)";
		$cond="!$cond" if $not;
		undef $_[0]->{uinner}->{cond};
		if (&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$cond,uid=>$uid})->{value}){
			$_[0]->{uinner}->{cond}=1; 
			return cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}}) 
		}  	
	} elsif ($param=~s/(\W)expr=(['"])(.+?)\2/$1/i)      {
		my $cond=$3;
		$cond="!$cond" if $not;
		undef $_[0]->{uinner}->{cond};
		if (&cmlcalc::calculate({key=>$key,id=>$id,ukey=>$ukey,expr=>$cond,uid=>$uid})->{value})	{
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

sub tag_static {
	my $key;
	my $param=$_[0]->{param};
	if ($param=~s/(\W)key=(['"])(.+?)\2/$1/i)  {
		$key=$3;   
	} else {
		$key=$cmlcalc::CGIPARAM->{pathinfo};
  }	
  my $value=&cmlmain::fromcache($key);
  if ($value) {return $value	} else {
  	$value=cmlparser ({data=>$_[0]->{data},inner=>$_[0]->{inner}});
  	&cmlmain::tocache($key,$value);
  	return $value;
	}	

}	



sub uploadprmfile
{
 my $prm;	
 if ($_[0]->{pkey}) {$prm=$_[0]->{pkey}}
 if ($_[0]->{param}) {$prm=$_[0]->{param}}
 
 my $id=$_[0]->{id};
 my $prmname=$_[0]->{cgiparam};
 
 
 $fname=~s{^.+\\(.+?)$}{${id}_${prm}_$1}i;
 $fname=~s{[а-яА-Я]}{}g;

 $fh = upload($prmname);
 open FILE,">$cmlmain::GLOBAL->{FILEPATH}/$fname" || die $!;
 while ($buffer=<$fh>) { 
  	print FILE $buffer; 
 }
 close  FILE;
 &cmlmain::setvalue({id=>$id,pkey=>$prm,value=>$fname});
}



return 1;


END {}
