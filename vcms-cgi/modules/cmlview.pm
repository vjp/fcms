package cmlview;

# $Id: cmlview.pm,v 1.6 2010-02-11 10:14:05 vano Exp $

BEGIN
{
 use Exporter();
 use Data::Dumper;
 use CGI  qw/:standard upload center/;
 use CGI::Ajax;
 use Time::Local;
 use POSIX qw(strftime);
 use cmlmain;
 use cmlcalc;
 @ISA = 'Exporter';
 @EXPORT = qw( &buildvparam &print_top );

}

sub print_top {
	my ($title)=@_;
	my $pjx = new CGI::Ajax( 'setValue' => 'ajax.pl?func=setvalue' );
        print $pjx->show_javascript();
        print_ajax_callback_funcs();
        print'<script language="javascript" type="text/javascript" src="/editarea/edit_area_full.js"></script>';
	$title="<title>$title</title>" if $title;
	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
	print "<html><head>$title<link rel='stylesheet' type='text/css' href='/css/vcms.css'></head><body>";
	print br;
}

sub print_ajax_callback_funcs {
	print qq(
		<script>
   			function setValueCallback (result) {
        			alert(result);
        		} 
		</script>
	);
}

sub editlist	{
	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	my $pkey=$_[0]->{pkey};
 	my $outp;
 
 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 
 	my $val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)"});
 
 	buildlist($val->{value}); 
 	unless (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},pkey=>$_[0]->{pkey}})) {
 			return join (br(),map {
 				 my $robj=&returnobject($_);
 				 my $name=$robj->{name};
 				 my $hrf;
 				 if ($robj->{type} eq 'U') {	$hrf="?action=editform&id=$robj->{id}"} 
         else {	$hrf="?action=editlowform&objid=$robj->{id}&id=$robj->{up}"}
       	 $_=a({-href=>$hrf},$name);
 		 } split(/\s*;\s*/,$val->{value}));
 	}
 	
        if ($prm->{$pkey}->{extra}->{formula} ne '') {
        	my $formula=$prm->{$pkey}->{extra}->{formula};
        	my $lhash;
        	my $listval=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>$formula}); 

        	my @overall;
        	for (split(/\s*;\s*/,$listval->{value})) {
        		push (@overall,$_);
        		$lhash->{$_}=retname($_);
        	}	
        	if ($prm->{$pkey}->{extra}->{single} eq 'y') {
        		@overall=('',@overall);
        	  $lhash->{''}='������';
						$outp=popup_menu(-name=>$prmname,
                                     -values=>\@overall,
                                     -default=>$val->{value},
                                     -labels=>$lhash,
                                     -onChange=>"document.$formname.$flagname.value=1");  
            if ($val->{value}) {
            	if ($val->{value}=~/u\d+/) {	$hrf="?action=editform&id=$val->{value}"} 
            	else {	$up=checkload({id=>$val->{value}});	$hrf="?action=editlowform&objid=$val->{value}&id=$up"}
            	$outp.=' '.a({-href=>$hrf},'>>');
            }
					  
        	}
        	else {	
        		my @selected=split(/\s*;\s*/,$val->{value});
        		$outp=scrolling_list(-name=>$prmname,
                                     -values=>\@overall,
                                     -default=>\@selected,
                                     -size=>5,
                                     -multiple=>'true',
                                     -labels=>$lhash,
                                     -onChange=>"document.$formname.$flagname.value=1");
					}
					
	}         	
 	else {
 		$outp=textfield (
	 			-name=>$prmname,
	 			-default=>$val->{value},
	 			-onChange=>"document.$formname.$flagname.value=1",
	 			);
	} 		
 	return $outp;
}

sub editdate	{
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	my $pkey=$_[0]->{pkey};
 	my $format=$prm->{$pkey}->{extra}->{format};
 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 
 	my $val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)"});
 	
 	unless (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},pkey=>$_[0]->{pkey}})) {
 		return strftime $format,gmtime($val->{value})
 	}
 	my @tm=gmtime($val->{value});

        




 	unless ($format) { 
	 	return textfield (
	 			-name=>$prmname,
	 			-default=>$val->{value},
	 			-onChange=>"document.$formname.$flagname.value=1",
	 			-override=>1
	 			);
	}
	else {
		### ����
		$format=~s{\%H}{
			my $val=$tm[2];
			if ($val<10) {$val="0$val"}
			textfield(	
				-name=>$prmname.'_H',
                            	-default=>$val,
                            	-size=>2,
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1
 				  );
		}ges; 	
		### ������ 
		$format=~s{\%M}{
			my $val=$tm[1];
			if ($val<10) {$val="0$val"}
			textfield(	
				-name=>$prmname.'_M',
                            	-default=>$val,
                            	-size=>2,
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1
 				  );
		}ges; 	
		### ����					
		$format=~s{\%Y}{
			my $val=$tm[5]+1900;
			textfield(	
				-name=>$prmname.'_Y',
                            	-default=>$val,
                            	-size=>4,
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1
 				  );
		}ges; 	
		### ������
		$format=~s{\%m}{
			my $val=$tm[4]+1;
			if ($val<10) {$val="0$val"}
			textfield(	
				-name=>$prmname.'_m',
                            	-default=>$val,
                            	-size=>2,
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1
 				  );
		}ges; 	
		### ���
		$format=~s{\%d}{
			my $val=$tm[3];
			if ($val<10) {$val="0$val"}
			textfield(	
				-name=>$prmname.'_d',
                            	-default=>$val,
                            	-size=>2,
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1
 				  );
		}ges; 	
		return $format;
 	}
}



sub editflag 	{
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	my $pkey=$_[0]->{pkey};
  my $checked;
 
 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 
 	my $val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)"}); 
  unless (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},tpkey=>$_[0]->{tabpkey},pkey=>$_[0]->{pkey}})) {
 		return $val->{value}
 	}
 	
 	if ($val->{value}) {$checked=1}
 	
 	
 	return checkbox (
 			-name=>$prmname,
 			-onChange=>"document.$formname.$flagname.value=1",
 			-checked=>$checked,
 			-override=>1,
 			-value=>1,
 			-label=>''
 			);
}

sub editnumber 	{
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	my $pkey=$_[0]->{pkey};
  my $checked;

 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 
 	my $val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)"}); 
  	unless (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},tpkey=>$_[0]->{tabpkey},pkey=>$_[0]->{pkey}})) {
 		return $val->{value}
 	}
 	
	return textfield (
 				-name=>$prmname,
 				-default=>$val->{value},
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1,
	);

}



sub edittext 	{
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	my $pkey=$_[0]->{pkey};
 	my $lang=$_[0]->{lang}; 
 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}

  my $val; 	
 	if ($lang ne 'mul') {
		$val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)"}); 
  	unless (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},tpkey=>$_[0]->{tabpkey},pkey=>$_[0]->{pkey}})) {
 			return $val->{value}
 		}
 	}	
 	
 	
 	
  if ($prm->{$pkey}->{extra}->{rows}) {
 		if ($lang eq 'mul') {
 	 		my @outp;
 	 		for (@LANGS) {
 	 			my $val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)",lang=>$_}); 
	 			push (@outp, "($_)".textarea (
 						-name=>"${prmname}_$_",
 						-default=>$val->{value},
 						-onChange=>"document.$formname.$flagname.value=1",
 						-override=>1,
 						-rows=>$prm->{$pkey}->{extra}->{rows},
 						-cols=>$prm->{$pkey}->{extra}->{cols},
 						));
 	 		}	
 	 		return join (br(),@outp);		
 	 	} else {
	 		return textarea (
 				-name=>$prmname,
 				-default=>$val->{value},
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1,
 				-rows=>$prm->{$pkey}->{extra}->{rows},
 				-cols=>$prm->{$pkey}->{extra}->{cols},
 			);
 		}	
 	}	else {
 		if ($lang eq 'mul') {
 			my @outp;
 			for (@LANGS) {
 				my $val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)",lang=>$_}); 
 				push (@outp,"($_)".textfield (
 					-name=>"${prmname}_$_",
 					-default=>$val->{value},
 					-onChange=>"document.$formname.$flagname.value=1",
 					-override=>1,
 					-size=>$prm->{$pkey}->{extra}->{cols},
 					)
				);
 			}
 			return join (br(),@outp);		
 		} else {
 			return textfield (
 				-name=>$prmname,
 				-default=>$val->{value},
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1,
 				-size=>$prm->{$pkey}->{extra}->{cols},
 				);
 		}		
 	}

}

sub editpicture
{
 my $id=$_[0]->{id};
 my $uid=$_[0]->{uid};
 my $tabkey=$_[0]->{tabkey};
 my $tabpkey=$_[0]->{tabpkey};
 my $flagname=$_[0]->{flag};
 my $formname=$_[0]->{form};
 my $pkey=$_[0]->{pkey};
 my $outp;

 my $prmname;
 if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}

 
 my $val=calculate({id=>$id,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,pkey=>$pkey,expr=>"p($pkey)"});
 if ($val->{value}) {$outp="<img src='$GLOBAL->{FILEURL}/$val->{value}'><br>"}
 if (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},pkey=>$_[0]->{pkey}})) {	 
 	$outp="$outp<input type='file' name='$prmname' value='$val->{value}' onchange='document.$formname.$flagname.value=1'>\n";
 } 	
 return $outp;
}

sub editvideo
{
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	my $pkey=$_[0]->{pkey};
 	my $outp;

 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}

 
 	my $val=calculate({id=>$id,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,pkey=>$pkey,expr=>"p($pkey)"});
 	if ($val->{value}) {
 		$outp=qq(
 			<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" width="320" height="260" id="fp" align="middle">
				<param name="allowScriptAccess" value="sameDomain" />
				<param name="movie" value="/swf/fp.swf?video=$GLOBAL->{FILEURL}/$val->{value}&image=&title=FlashVideo" />
				<param name="quality" value="high" />
				<param name="bgcolor" value="#ffffff" />
				<embed src="/swf/fp.swf?video=$GLOBAL->{FILEURL}/$val->{value}&image=&title=FlashVideo" quality="high" bgcolor="#ffffff" width="320" height="260" name="fp" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
			</object>
			<br/>
 		);
 	}
 	if (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},pkey=>$_[0]->{pkey}})) {	 
 		$outp="$outp<input type='file' name='$prmname' value='$val->{value}' onchange='document.$formname.$flagname.value=1'>\n";
 	} 	
 	return $outp;
}



sub editfile
{
 my $id=$_[0]->{id};
 my $uid=$_[0]->{uid};
 my $tabkey=$_[0]->{tabkey};
 my $tabpkey=$_[0]->{tabpkey};
 my $flagname=$_[0]->{flag};
 my $formname=$_[0]->{form};
 my $pkey=$_[0]->{pkey};
 my $outp;

 my $prmname;
 if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}

 
 my $val=calculate({id=>$id,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,pkey=>$pkey,expr=>"p($pkey)"});
 if ($val->{value}) {$outp="<a href='$GLOBAL->{FILEURL}/$val->{value}'>�������</a><br>"}
 if (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},pkey=>$_[0]->{pkey}})) {	 
 	$outp="$outp <input type='file' name='$prmname' value='$val->{value}' onchange='document.$formname.$flagname.value=1'>\n";
 } 	
 return $outp;
}



sub editmemo {
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $pkey=$_[0]->{pkey};
 	my $lang=$_[0]->{lang};
 	my @outp;
 
 	if ($lang eq 'mul') {
 		for (@LANGS) {
 		   push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$_", -target=>'_blank'},"������������� ($LANGS{$_})"));			 
 		}	 
	} elsif ($lang) {
		  push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$lang", -target=>'_blank'},"������������� ($LANGS{$lang})"));			 
	}	else {	
		  push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey", -target=>'_blank'},"�������������"));			 
  } 	
  
  if ($prm->{$pkey}->{extra}->{script} eq 'y') {
  	push(@outp,a({-href=>"?action=execscript&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey", -target=>'_blank'},"���������"));			 
	}	
  
  return join('<br>',@outp);
}

sub editmatrix
{
 my $id=$_[0]->{id};
 my $uid=$_[0]->{uid};
 my $pkey=$_[0]->{pkey};
 my $outp=a({-href=>"$ENV{SCRIPT_NAME}?action=editmatrix&objid=$id&objuid=$uid&pkey=$pkey",-target=>'_blank'},'�������������');
 return $outp;
}


sub editmemofull
{
 	my $id=param('objid');
 	my $pkey=param('pkey');
 	my $uid=param('objuid');
 	my $tabkey=param('tabkey');
 	my $tabpkey=param('tabpkey');
 	my $lang=param('lang');
 	
 	my $val=calculate({id=>$id,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)",noparse=>1,lang=>$lang});

 	my $name;
 	if    ($id)  {$name="$lobj->{$id}->{name} ($lobj->{$id}->{key})"}
 	elsif ($uid) {$name="$obj->{$uid}->{name} ($obj->{$uid}->{key})"}

	if ($tabpkey) {
		print "��������� ������ <b> $name </b> �������� <b> $prm->{$tabpkey}->{name} ($tabpkey) </b> <br>";
		my @tablist = map {
			if ($_=~/^u(\d+)$/) {$_=$obj->{$1}->{name}}
			else {checkload ({id=>$_}); $_=$lobj->{$_}->{name}}
		} split(/_/,$tabkey);
		print "������ <b>@tablist</b> �������� <b>$prm->{$pkey}->{name} ($pkey) </b> <br>";
	}
	elsif ($lang) { print "������ <b>$name</b> �������� <b>$prm->{$pkey}->{name} ($pkey)</b> ���� <b>$LANGS{$lang}</b>",br,br; }	
	else          { print "������ <b>$name</b> �������� <b>$prm->{$pkey}->{name} ($pkey)</b> ",br,br; }
 
 
  
 
	print qq(
		<script language="javascript" type="text/javascript">
			editAreaLoader.init({
			id : "editarea"		
			,language: "ru"
			,syntax: "html"			
			,start_highlight: true		
		});
		</script>
	);
	
	print start_form(-name=>'mfrm',-method=>'post');
 	print button(-name=>'bt2',-value=>'���������',-onclick=>"document.mfrm.mvls.value = editAreaLoader.getValue('editarea');setValue( ['objid','objuid','pkey','mvls'], [setValueCallback],'POST' )"),br;
	print textarea(-id=>'editarea',-default=>$val->{value},-rows=>40,-cols=>150,-override=>1);	
	
	
	
	print hidden(-name=>'mvls',-id=>'mvls',-default=>'', -override=>1);
	
 	print br;


 	print button(-name=>'bt',-value=>'���������',-onclick=>"document.mfrm.mvls.value = editAreaLoader.getValue('editarea');setValue( ['objid','objuid','pkey','mvls'], [setValueCallback],'POST' )");
 	
 	print hidden(-name=>'objid',-id=>'objid',-default=>$id);
 	print hidden(-name=>'objuid',-id=>'objuid',-default=>$uid);
 	print hidden(-name=>'pkey',-id=>'pkey',-default=>$pkey);
 	print hidden(-name=>'tabkey',-default=>$tabkey);
 	print hidden(-name=>'tabpkey',-default=>$tabpkey);
 	print hidden(-name=>'action',-default=>'setmemo', -override=>1);
 	if ($lang) {
 		print hidden(-name=>'lang',-default=>$lang);
	}	
 	print endform;

 	print "</body></html>";
 	
 	
 	
}

sub editmatrixfull
{
 my $id=param('objid');
 my $pkey=param('pkey');
 my $uid=param('objuid');

 my $name;
 if    ($id)  {$name="$lobj->{$id}->{name} ($lobj->{$id}->{key})"}
 elsif ($uid) {$name="$obj->{$uid}->{name} ($obj->{$uid}->{key})"}

 print "������ <b> $name </b> �������� <b>$prm->{$pkey}->{name} ($pkey) </b><hr>";
 
 my @dim=split(/;/,$prm->{$pkey}->{extra}->{param});
 
 
 my $row=pop @dim;
 my $rv=calculate({id=>$id,uid=>$uid,expr=>"p($row)"});
 my @rows=split(/;/,$rv->{value});
 
 my $col=pop @dim;
 my $cv=calculate({id=>$id,uid=>$uid,expr=>"p($col)"});
 my $vl=$cv->{value}?$cv->{value}:'DUMMY';
 my @cols=split(/;/,$vl);
 
 my @plist=uparamlist($prm->{$pkey}->{extra}->{cell});


 
 my $vls;
 for (my $i=0;$i<=$#dim;$i++)  {
 	my $ind=$dim[$i];
 	my $v=calculate({id=>$id,uid=>$uid,expr=>"p($ind)"});
 	for(split(/;/,$v->{value})) {push (@{$vls->{$i}->{data}},$_)  }
 	$vls->{$i}->{ind}=0;
 	$vls->{$i}->{name}=$ind;
 }	
 
 my @comb;
 push (@comb,[combget($vls)]);
 while (tonext($vls)) {  push (@comb,[combget($vls)]) } 	

 print "<form name='frm' method='post'>";
 
 my @cellkey;
 for (@comb) {
 	
 	my @curcomb=@$_;
 	undef @cellkey;
 	for (sort keys %$vls) {
 		my $n=retname($curcomb[$_]);
 		push (@cellkey,$curcomb[$_]);
 		print "�������� <b>$prm->{$vls->{$_}->{name}}->{name}</b> ������  <b>$n</b> <br>";
 	}	
	print "<table border=1>";
 		
 	print "<tr>";
 	
 	
 	      if ($vl eq 'DUMMY') {
 	      	 print th($prm->{$row}->{name},br,"($row)");
 	      	 for (@plist) {print th($prm->{$_}->{name},br,"($_)")}
 	      } else {
 	      	print th($prm->{$col}->{name},br,$prm->{$row}->{name});
 	        for (@cols)  {my $n=retname($_); print th($n)}		
 	        
 	      }  
        print "</tr>";
        my $currow;
        for (@rows) {
        	$currow=$_;
        	$n=retname($_);
        	unless ($n) {$n='&nbsp;'}
        	print "<tr><th>$n</th>";
        	
        	if ($vl eq 'DUMMY') {
        		my $cn=join('_',(@cellkey,$currow)); 
        		for (@plist) {
        		 my $hn='key'.$cn.'lnk'.$_;
             eval { $vstr=&{$ptype{$prm->{$_}->{type}}->{editview}}({id=>$id,uid=>$uid,tabkey=>$cn,tabpkey=>$pkey,pkey=>$_,flag=>$hn,form=>'frm'}) };
    				 if ($@) {$vstr="ERROR: $@"}
    		     print "<input type=hidden name='$hn' value=0>\n";
    		     print td($vstr);
            }
          } else {	
        		for (@cols)  {
        			my $cn=join('_',(@cellkey,$currow,$_)); 
        			print td(editcell({key=>$cn,plist=>\@plist,id=>$id,uid=>$uid,tabpkey=>$pkey})); 
        		}		
          }		
        	print "</tr>";
        }
 	print "</table>";

 	print "<hr>";
  }

 
 print "<br>";
 print "<input name='bt' value='�������������' type='submit'>";
 print "<input type='hidden' name='objid' value='$id'>";
 print "<input type='hidden' name='objuid' value='$uid'>";
 print "<input type='hidden' name='pkey'  value='$pkey'>";
 print "<input type='hidden' name='action' value='setmatrix'>";
 print "</form>";
 
 sub editcell {
 	my $key=$_[0]->{key};
 	my @plist=@{$_[0]->{plist}};
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabpkey=$_[0]->{tabpkey};
 	
 	
 	
 	print "<table>";
 	for (@plist) {
 		my $vstr='';
 		my $hn='key'.$key.'lnk'.$_;
        eval { $vstr=&{$ptype{$prm->{$_}->{type}}->{editview}}({id=>$id,uid=>$uid,tabkey=>$key,tabpkey=>$tabpkey,pkey=>$_,flag=>$hn,form=>'frm'}) };
    		if ($@) {$vstr="ERROR: $@"}
    		print "<input type=hidden name='$hn' value=0>\n";
    		print "<tr><td>$prm->{$_}->{name}</td><td>$vstr</td></tr>";

 	}
 	print "</table>";
 }
  
 sub combget {
   	my $vls=$_[0];
   	my @res;
   	for (sort keys %$vls) {push(@res,${$vls->{$_}->{data}}[$vls->{$_}->{ind}]) }
   	return @res;
 }
 
 sub tonext  {
 	my $vls=$_[0];
 	my @res;
 	for (reverse sort keys %$vls) {
 		my @dt=@{$vls->{$_}->{data}};
 		if ($vls->{$_}->{ind}<$#dt) {$vls->{$_}->{ind}++; return 1} else {$vls->{$_}->{ind}=0}
 	}
 	return 0;
 }	
 
}


sub setlist {
 	my $pkey=$_[0]->{pkey};
 	my $objid=$_[0]->{id};
 	my $objuid=$_[0]->{uid};
  	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $prmname;
	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
	
	my $value;
	if ($prm->{$pkey}->{extra}->{formula} ne '') { $value=join(';',param($prmname)) }
	else { $value=param($prmname) }

 	setvalue({id=>$objid,uid=>$objuid,pkey=>$pkey,value=>$value,tabkey=>$tabkey,tabpkey=>$tabpkey});
}

sub setdate 	{
 	my $pkey=$_[0]->{pkey};
 	my $objid=$_[0]->{id};
 	my $objuid=$_[0]->{uid};
 
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 
 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 	
 	my @tlist;
 	
 	
 	if (param($prmname.'_Y')) {$tlist[5]=param($prmname.'_Y')}   else {$tlist[5]=1970}
 	if (param($prmname.'_m')) {$tlist[4]=param($prmname.'_m')-1} else {$tlist[4]=0}
 	if (param($prmname.'_d')) {$tlist[3]=param($prmname.'_d')}   else {$tlist[3]=1}
 	if (param($prmname.'_H')) {$tlist[2]=param($prmname.'_H')}   else {$tlist[2]=0}
 	if (param($prmname.'_M')) {$tlist[1]=param($prmname.'_M')}   else {$tlist[1]=0}
        $tlist[0]=0;

        my $v=timegm(@tlist);
      

 	setvalue({id=>$objid,uid=>$objuid,pkey=>$pkey,value=>$v,tabkey=>$tabkey,tabpkey=>$tabpkey});
}



sub settext
{
 my $pkey=$_[0]->{pkey};
 my $objid=$_[0]->{id};
 my $objuid=$_[0]->{uid};
 
 my $tabkey=$_[0]->{tabkey};
 my $tabpkey=$_[0]->{tabpkey};
 
 my $prmname;
 if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 my $value=param($prmname);
 
 
 setvalue({id=>$objid,uid=>$objuid,pkey=>$pkey,value=>$value,tabkey=>$tabkey,tabpkey=>$tabpkey});
 
 for (@LANGS) {
 		if (defined param("${prmname}_$_")) {
	 			 my $value=param("${prmname}_$_");
  			 setvalue({id=>$objid,uid=>$objuid,pkey=>$pkey,value=>$value,tabkey=>$tabkey,tabpkey=>$tabpkey,lang=>$_});
 		}	
 }	
 
}


sub setpicture
{
 	

	
 my $pkey=$_[0]->{pkey};
 my $objid=$_[0]->{id};
 my $objuid=$_[0]->{uid};


 
 my $tabkey=$_[0]->{tabkey};
 my $tabpkey=$_[0]->{tabpkey};
 
 my $prmname;
 if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 my $fname=param($prmname);
 
 if    ($objid)  { $fname=~s{^.+\\(.+?)$}{${objid}_${pkey}_$1}i }
 elsif ($objuid) { $fname=~s{^.+\\(.+?)$}{${objuid}_${pkey}_$1}i }
 
 
 $fh = upload("v$pkey");
 open FILE,">$GLOBAL->{FILEPATH}/$fname" || die $!;
 while ($buffer=<$fh>) { 
 	print FILE $buffer; 
 }
 close  FILE || die $!;
 setvalue({id=>$objid,uid=>$objuid,pkey=>$pkey,value=>$fname,tabkey=>$tabkey,tabpkey=>$tabpkey});
}



sub setmemofull   {
	my $id=param('objid');
 	my $uid=param('objuid');
	my $pkey=param('pkey');
 	my $value=param('mvls');
 	my $tabkey=param('tabkey');
 	my $tabpkey=param('tabpkey');
 	my $lang=param('lang');
 	my $cf=param('compile');
  	setvalue({id=>$id,pkey=>$pkey,value=>$value,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,lang=>$lang});
 	setvalue({id=>$id,pkey=>"${pkey}__COMPILEDFLAG",value=>0,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,lang=>$lang});
 	if ($cf) {
 		my $cdata=calculate({id=>$id,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)",lang=>$lang});
 		setvalue({id=>$id,pkey=>"${pkey}__COMPILED",value=>$cdata->{value},uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,lang=>$lang});
 		setvalue({id=>$id,pkey=>"${pkey}__COMPILEDFLAG",value=>1,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,lang=>$lang});
 	}	
 	
}

sub setmatrixfull  {
 	my $id=param('objid');
 	my $uid=param('objuid');
 	my $tabpkey=param('pkey');
 
 	for (grep {/^key/ && param($_)} param() )  {
 		(my $tabkey, my $pkey)=/^key(.+)lnk(.+)$/;
		eval { &{$ptype{$prm->{$pkey}->{type}}->{setvalue}}({pkey=>$pkey,tabkey=>$tabkey,id=>$id,uid=>$uid,tabpkey=>$tabpkey}) };
		if ($@) {print "ERROR $@"}
 	}	
}



sub emptysub {
 	return undef;
}


sub extralist {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	my $ss;
 	my $onc;
 	if ($extra->{single} eq 'y') {$ss='1'} else {$ss=''}
 	my $flagname=$_[0]->{flag};
	my $formname=$_[0]->{form};
 	if ($_[0]->{check}) { $onc="document.$formname.$flagname.value=1" } 
	my @o;
	if ($_[0]->{check}) {
		push (@o,['�������',textfield(-name=>"exformula$pkey", -default=>$extra->{formula}, -onchange=>$onc, -override=>1)]);
	} else {
		push (@o,['�������',textarea(-name=>"exformula$pkey", -default=>$extra->{formula}, -onchange=>$onc, -override=>1, -cols=>130,-rows=>15)])
	}
  push (@o,['���������',checkbox(-name=>"exsingle$pkey", -value=>1, -checked=>$ss, -label=>'', -onchange=>"document.$formname.$flagname.value=1", -override=>1)]);
 	return \@o;
}

sub extradate {
 	my $pkey=$_[0]->{pkey};
 	
 	my $extra=$prm->{$pkey}->{extra};
 	
 	my $fix;
 	if ($extra->{fix} eq 'y') {$fix=1}
 	my $ss;
 	if ($extra->{srch} eq 'y') {$ss=1}
 	
 	
 	if ($_[0]->{check}) {
	 	my $flagname=$_[0]->{flag};
 		my $formname=$_[0]->{form};
 		my $outp='������ '.textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -onchange=>"document.$formname.$flagname.value=1", -override=>1).br;
 		$outp.='���� '.checkbox(-name=>"fix$pkey", -value=>1, -checked=>$fix, -onchange=>"document.$formname.$flagname.value=1", -override=>1, -label=>'');
 		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');
		return $outp;
	} else {
 		my $outp='������ '.textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -override=>1).br;
 		$outp.='���� '.checkbox(-name=>"fix$pkey", -value=>1, -checked=>$fix, -override=>1, -label=>'');
 		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -label=>'');
		return $outp;
	}			
}

sub extratext {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	my $outp;
 	if ($_[0]->{check}) {
	 	my $flagname=$_[0]->{flag};
 		my $formname=$_[0]->{form};
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
 		$outp='�����'.textfield(-size=>1, -name=>"excols$pkey", -default=>$extra->{cols}, -onchange=>"document.$formname.$flagname.value=1", -override=>1);
 		$outp.='�����'.textfield(-size=>1, -name=>"exrows$pkey", -default=>$extra->{rows}, -onchange=>"document.$formname.$flagname.value=1", -override=>1);
		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');		

	} else {
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
	
		$outp='�����'.textfield(-size=>1, -name=>"excols$pkey", -default=>$extra->{cols}, -override=>1);
		$outp.='�����'.textfield(-size=>1, -name=>"exrows$pkey", -default=>$extra->{rows}, -override=>1);

		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'');		
	}	
  return $outp;	
	
}

sub extraflag {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	my $outp;
 	if ($_[0]->{check}) {
	 	my $flagname=$_[0]->{flag};
 		my $formname=$_[0]->{form};
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');		

	} else {
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'');		
	}	
  return $outp;	
	
}



sub extranumber {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	if ($_[0]->{check}) {
	 	my $flagname=$_[0]->{flag};
 		my $formname=$_[0]->{form};
 		my $outp='������ '.textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -onchange=>"document.$formname.$flagname.value=1", -override=>1);
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
 		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');
		return $outp;
	} else {
		my $outp='������ '.textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -override=>1);
		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
		$outp.='�����'.checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'');
		return $outp;
	}			
	
	
}





sub extramemo {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	my $ss= $extra->{parse} eq 'y'?'checked':'';
 	my $sse=$extra->{script} eq 'y'?'checked':'';
 	my $ssv=$extra->{visual} eq 'y'?'checked':'';
 	
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	
 	my $outp='������'.checkbox(-name=>"exparse$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');		
	$outp.='���'.checkbox(-name=>"exscript$pkey", -checked=>$sse, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');
	$outp.='���'.checkbox(-name=>"exvisual$pkey", -checked=>$ssv, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');
			
	return $outp;
}



sub extramatrix {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	
 	if ($_[0]->{check}) {
	 	my $flagname=$_[0]->{flag};
 		my $formname=$_[0]->{form};
 	   	my $outp="���������     <input name='exparam$pkey'  value='$extra->{param}' onchange='document.$formname.$flagname.value=1'><br>";
           	$outp.="������ ������ <input name='excell$pkey'   value='$extra->{cell}' onchange='document.$formname.$flagname.value=1'>";   
           	return $outp;
        }   
	else {
 	   	my $outp="���������    <input name='exparam$pkey'  value='$extra->{param}'><br>";
           	$outp.="������ ������  <input name='excell$pkey'   value='$extra->{cell}'>";   
           	return $outp;
	}	
}

sub extralistparse {
 	my $pkey=$_[0]->{pkey};
 	my $sing;
 	if (param("exsingle$pkey")) {$sing='y'} else {$sing='n'}
 	setprmextra({pkey=>$pkey,extra=>'single',value=>$sing});
 	setprmextra({pkey=>$pkey,extra=>'formula',value=>param("exformula$pkey")});
}


sub extradateparse {
 	my $pkey=$_[0]->{pkey};
 	
 	my $fix;
  	if (param("fix$pkey")) {$fix='y'} else {$fix='n'}
 	setprmextra({pkey=>$pkey,extra=>'fix',value=>$fix});
 	setprmextra({pkey=>$pkey,extra=>'format',value=>param("exformat$pkey")});
 	if (param("exsrch$pkey")) {$prs='y'} else {$prs='n'}
 	setprmextra({pkey=>$pkey,extra=>'srch',value=>$prs});
}

sub extranumberparse {
 	my $pkey=$_[0]->{pkey};
 	setprmextra({pkey=>$pkey,extra=>'format',value=>param("exformat$pkey")});
 	my $prs;
 	if (param("exsrch$pkey")) {$prs='y'} else {$prs='n'}
 	setprmextra({pkey=>$pkey,extra=>'srch',value=>$prs});
}


sub extratextparse {
 	my $pkey=$_[0]->{pkey};
 	setprmextra({pkey=>$pkey,extra=>'cols',value=>param("excols$pkey")});
 	setprmextra({pkey=>$pkey,extra=>'rows',value=>param("exrows$pkey")});
 	my $prs;
 	if (param("exsrch$pkey")) {$prs='y'} else {$prs='n'}
 	setprmextra({pkey=>$pkey,extra=>'srch',value=>$prs});
}


sub extraflagparse {
 	my $pkey=$_[0]->{pkey};
 	my $prs;
 	if (param("exsrch$pkey")) {$prs='y'} else {$prs='n'}
 	setprmextra({pkey=>$pkey,extra=>'srch',value=>$prs});
}




sub extramemoparse {
 	my $pkey=$_[0]->{pkey};
 	setprmextra({pkey=>$pkey,extra=>'parse',value=>param("exparse$pkey")?'y':'n'});
 	setprmextra({pkey=>$pkey,extra=>'script',value=>param("exscript$pkey")?'y':'n'});
 	setprmextra({pkey=>$pkey,extra=>'visual',value=>param("exvisual$pkey")?'y':'n'});
}


sub extramatrixparse {
 	my $pkey=$_[0]->{pkey};
 	setprmextra({pkey=>$pkey,extra=>'param',value=>param("exparam$pkey")});
 	setprmextra({pkey=>$pkey,extra=>'cell',value=>param("excell$pkey")});
}


sub buildvparam {
  	$ptype{TEXT}={
        	 name       =>'������',
                 editview   =>\&cmlview::edittext,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extratext,
                 extraparse =>\&cmlview::extratextparse,
        };
 	$ptype{NUMBER}={
                 name       =>'�����',
                 editview   =>\&cmlview::editnumber,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extranumber,
                 extraparse =>\&cmlview::extranumberparse,
        };
  	$ptype{LONGTEXT}={
                 name       =>'�����',
                 editview   =>\&cmlview::editmemo,
                 extra      =>\&cmlview::extramemo,
                 extraparse =>\&cmlview::extramemoparse,
                 extendedit =>\&cmlview::editmemofull,
                 extendset=>\&cmlview::setmemofull,
        };
  	$ptype{FLAG}={
                 name       =>'����',
                 editview   =>\&cmlview::editflag,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extraflag,
                 extraparse =>\&cmlview::extraflagparse,
        };
  	$ptype{DATE}={
                 name       =>'����',
                 editview   =>\&cmlview::editdate,
                 setvalue   =>\&cmlview::setdate,
                 extra      =>\&cmlview::extradate,
                 extraparse =>\&cmlview::extradateparse,
        };
  	$ptype{LIST}={
                 name       =>'������',
                 editview   =>\&cmlview::editlist,
                 setvalue   =>\&cmlview::setlist,
                 extra      =>\&cmlview::extralist,
                 extraparse =>\&cmlview::extralistparse,
        };
  	$ptype{MATRIX}={
                 name       =>'�������',
                 editview   =>\&cmlview::editmatrix,
                 extra      =>\&cmlview::extramatrix,
                 extraparse =>\&cmlview::extramatrixparse,
                 extendedit =>\&cmlview::editmatrixfull,
                 extendset=>\&cmlview::setmatrixfull,
        };
 	$ptype{PICTURE}={
                 name       =>'��������',
                 editview   =>\&cmlview::editpicture,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };
        $ptype{VIDEO}={
                 name       =>'����������',        	
                 editview   =>\&cmlview::editvideo,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };
        
        
 	$ptype{FILE}={
                 name       =>'����',
                 editview   =>\&cmlview::editfile,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };

}


return 1;


END {}
