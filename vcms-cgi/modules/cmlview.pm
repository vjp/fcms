package cmlview;


BEGIN
{
 use Exporter();
 use Data::Dumper;
 use CGI  qw/:standard upload center *table/;
 use Time::Local;
 use POSIX qw(strftime);
 use cmlmain;
 use cmlcalc;
 use vCMS;
 @ISA = 'Exporter';
 @EXPORT = qw( 
 	&buildvparam &print_top &editmethodform &editprmform &console &config 
 	&viewhistoryform &viewallhistoryform
 );

}

sub print_top {
	my ($title)=@_;
   
	$title='VCMS' unless $title;
	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
	print "<html><head><title>$title</title><link rel='stylesheet' type='text/css' href='/css/vcms.css'>";
     print'<script language="javascript" type="text/javascript" src="/editarea/edit_area_full.js"></script>';
    print q(
    <script src='/js/prototype.js'> </script>
    <script src='/js/base.js'> </script>
	<script language="javascript" type="text/javascript" src="/js/flowplayer.js"></script>
	<script language="javascript" type="text/javascript" src="/js/swfobject.js"></script>
    
    ); 
    print q(<script>
    		function alert_callback(json){
					 alert(json.status); 	
            }    
    
    		function setvalue (id,uid,prm,lang,value) {
          		var dt={
          			id: id,
          			uid: uid,
          			prm: prm,
          			lang: lang,
          			value: value
          		};
          		ajax_call('setvalue', dt, alert_callback);
  			}
			
			function editmethod (id,pkey,nflag,script) {
          		var dt={
          			id: id,
          			pkey: pkey,
          			script: script,
          			nflag: nflag
          		};
          		ajax_call('editmethod', dt, alert_callback);
  			}
            </script>
    );    
	print"</head><body>";
	print br;
	return undef;
}

sub lmethod_list {
	
 	my $tl;	
 	my $tlbls;
 	my @tvals=('');
 	push (@tvals,sort keys %$lmethod);
 	for (@tvals) { $tlbls->{$_}="$lmethod->{$_}->{name} ($_)" } 
 	$tlbls->{''}=enc('Не определен');
 
 	$tl->{vals}=\@tvals;
 	$tl->{lbls}=$tlbls;
 
 	return $tl;
}	

sub config {
	print start_form(-method=>'post',-name=>'mfrm');
	print enc("Конфигурация");
	print start_table();
	print Tr(td(),td(),td());
	print end_table();
	print qq(
		<script language="javascript" type="text/javascript">
			editAreaLoader.init({
			id : "editarea"		
			,language: "ru"
			,syntax: "perl"			
			,start_highlight: true	
			,replace_tab_by_spaces : 4	
		});
		
		function sccallback(json){
    		if (json.status) {
        		alert(json.message); 
    		} else {
        		alert(json.message);
    		}    
		}   
		
		</script>
	);
    my $save_js="ajax_call('setconf',{conf:editAreaLoader.getValue('editarea')},sccallback)";
    my $fcontent;
	open (FC, "<$cmlmain::GLOBAL->{CGIPATH}/conf");
	read (FC,$fcontent,-s FC);
	close(FC); 

 	print button(-name=>'bt2',-value=>enc('Сохранить конфигурацию'),-onclick=>$save_js),br;
	print textarea(-id=>'editarea',-default=>$fcontent,-rows=>20,-cols=>100,-override=>1);	
 	print br;
	print button(-name=>'bt',-value=>enc('Сохранить конфигурацию'),-onclick=>$save_js);
	print hr;
	
	
	print start_form(-method=>'post',-name=>'mfrm2');
	print enc("HTACCESS");
	print start_table();
	print Tr(td(),td(),td());
	print end_table();
	print qq(
		<script language="javascript" type="text/javascript">
			editAreaLoader.init({
			id : "editarea2"		
			,language: "ru"
			,syntax: "htaccess"			
			,start_highlight: true	
			,replace_tab_by_spaces : 4	
		});
		</script>
	);
    my $save_js2="ajax_call('sethtaccess',{conf:editAreaLoader.getValue('editarea2')},sccallback)";
    my $fcontent2;
	open (FC2, "<$cmlmain::GLOBAL->{WWWPATH}/.htaccess");
	read (FC2,$fcontent2,-s FC2);
	close(FC2); 

 	print button(-name=>'b2bt2',-value=>enc('Сохранить htaccess'),-onclick=>$save_js2),br;
	print textarea(-id=>'editarea2',-default=>$fcontent2,-rows=>20,-cols=>100,-override=>1);	
 	print br;
	print button(-name=>'b2bt',-value=>enc('Сохранить htaccess'),-onclick=>$save_js2);

	
	
	
	print hr;
	print enc("Экспорт"),br;
	print endform();
	print a({-href=>"?action=export&area=scripts"},enc('скрипты')),br;
	print a({-href=>"?action=export&area=docs"},enc('статика')),br;
	print a({-href=>"?action=export&area=data"},enc('файлы и картинки')),br;
	print a({-href=>"?action=export&area=db"},enc('база данных')),br;
	
}


sub viewhistoryform ($$) {
	my ($objid,$prm)=@_;
	my $pObj=o($objid);
	my $name=$pObj->p(_NAME);
	print_top("VH: $name($objid) $prm");
	my $r=$pObj->History({prm=>$prm});
    print start_table();
    for (@$r) {
		print Tr(
			td($_->{dt}),
			td($_->{value}),
			td($_->{user}),
		);    		
    }
	print end_table();    	
}


sub viewallhistoryform ($) {
	my ($objid)=@_;
	my $pObj=o($objid);
	my $name=$pObj->p(_NAME);
	print_top("VAH: $name($objid)");
	my $r=$pObj->History();
    print start_table();
	print Tr(
		th(enc('Время')),
		th(enc('Параметр')),
		th(enc('Значение')),
		th(enc('Пользователь')),
	);    
    for (@$r) {
		print Tr(
			td($_->{dt}),
			td($_->{pkey}),
			td(textarea(-default=>$_->{value},-rows=>10,-cols=>50)),
			td($_->{user}),
		);    		
    }
	print end_table();    	
}



sub editprmform {
	my $id=$_[0];
	my $pkey=$_[1];
	my $ss;
	
	my $extra=&{$ptype{$prm->{$pkey}->{type}}->{extra}}({pkey=>$pkey});
	print_top("P: $pkey"); 
	print q(
	 <script language="javascript" type="text/javascript">
			editAreaLoader.init({
				id : "editarea"		
				,language: "ru"
				,syntax: "perl"			
				,start_highlight: true		
			});
	 </script> 	
	);
	
	print start_form(-method=>'post');
	print hidden (-name=>'action',-default=>'editprm',-override=>1);
  	print hidden (-name=>'pname',-default=>$pkey);
  	print hidden (-name=>'id',-default=>$id);
	
	print start_table();
	print Tr(th(enc('Объект')),td(b($obj->{$id}->{name})));
	print Tr(th(enc('Наименование параметра')),td(b(textfield(-name=>'prmname',-default=>$prm->{$pkey}->{name},override=>1,size=>130))));
	print Tr(th(enc('Ключ')),td(b($pkey)));
	print Tr(th(enc('Тип')),td(b($ptype{$prm->{$pkey}->{type}}->{name})));
	
	my $tl=lmethod_list();
	print Tr(th(enc('Обработчик OnChange')),td(b(popup_menu(-name=>'onchange',-default=>$prm->{$pkey}->{extra}->{onchange},-values=>$tl->{vals},-labels=>$tl->{lbls},-override=>1))));
	if ($prm->{$pkey}->{upd}->{$id} eq 'y') {$ss=1} else {$ss=''}
	print Tr(th(enc('Исправляемый')),td(b(checkbox(-name=>'prmupd',-value=>1,-checked=>$ss,-label=>'',override=>1))));
	if ($prm->{$pkey}->{evaluate} eq 'y') {$ss=1} else {$ss=''}
	print Tr(th(enc('Выполняемый')),td(b(checkbox(-name=>'prmevl',-value=>1,-checked=>$ss,-label=>'',override=>1))));  
  	print Tr(th(enc('Умолчание')),td(textarea(-id=>'editarea',-name=>'prmdef',-default=>$prm->{$pkey}->{defval}->{$id},override=>1,rows=>15,cols=>130)));
	print Tr(th(enc('Условие доступа')),td(textarea(-name=>'hasaccess',-default=>$prm->{$pkey}->{extra}->{hasaccess},override=>1,rows=>15,cols=>130)));  
  	if (ref $extra eq 'ARRAY') {
    	print Tr(th({-colspan=>2},enc("Дополнительные атрибуты")));
    	for (@$extra) {
    		print Tr(th($_->[0]),td($_->[1]));
    	}	
  	}	
	print Tr(th(),td(submit(-value=>enc('Исправить'))));
	print end_table();
  	if (ref $extra ne 'ARRAY') {  
  		print $extra,br 
  	}
	print endform;
}

sub console {
	my $value=$_[0];
	print enc(q(
		<script language="javascript" type="text/javascript">
			editAreaLoader.init({
				id : "editarea"		
				,language: "ru"
				,syntax: "perl"			
				,start_highlight: true		
			});
		
			function console (script) {
				$('resultDiv').update('...');
				$('statusDiv').update('ВЫПОЛНЕНИЕ');
          		var dt={script: script};
          		ajax_call('console', dt, console_callback);
  			}
			
			function console_callback(json){
				     $('resultDiv').update(json.result);
				     var statusstr;
				     if (json.status=='SUCCESS') {
				     	statusstr='УСПЕХ';
				     } else {
				     	statusstr='ОШИБКА';
				     }		
				     $('statusDiv').update(statusstr);
				     
            }
		</script>
	));
    my $save_js="console(editAreaLoader.getValue('editarea'))";
	print textarea(-id=>'editarea',-default=>$value,-rows=>25,-cols=>100,-override=>1);
	print br;
	print button(-value=>enc('Выполнить'),-onclick=>$save_js);
	print hr,table(Tr(td(enc("Результат выполнения скрипта : ")),td("<div id='statusDiv'></div>")));
	print hr,"<div id='resultDiv'></div>";
	
	
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
        	  $lhash->{''}=enc('Ничего');
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
 		return strftime $format,localtime($val->{value})
 	}
 	my @tm=localtime($val->{value});

        




 	unless ($format) { 
	 	return textfield (
	 			-name=>$prmname,
	 			-default=>$val->{value},
	 			-onChange=>"document.$formname.$flagname.value=1",
	 			-override=>1
	 			);
	}
	else {
		### часы
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
		### минуты 
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
		### годы					
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
		### месяцы
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
		### дни
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
		
		$format=~s{\%(c|a)}{
			enc(strftime ("\%$1",localtime($val->{value})));
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
 	my $lang=$_[0]->{lang} || ''; 
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
 		
 		
 		<div style="width:320px; height:240px; align:center;" id="playerDiv_${id}_${uid}_${pkey}">
 
 	</div>
 	<script language="JavaScript">
         var player = flowplayer("playerDiv_${id}_${uid}_${pkey}",{
        	src		: "/swf/flowplayer.swf",
            version	: [9, 115],
            bgcolor	: "#FFFFF",
        },{
            clip: { 
            	scaling:'fit',
            	url:'$GLOBAL->{FILEURL}/$val->{value}',
            	autoPlay: false
            },  
            canvas: {
                backgroundColor: '#FFFFFF'
            }	
        });
     </script>
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
 my $label=enc('Скачать');
 if ($val->{value}) {$outp="<a href='$GLOBAL->{FILEURL}/$val->{value}'>$label</a><br>"}
 if (checkupd({id=>$_[0]->{id},uid=>$_[0]->{uid},tabkey=>$_[0]->{tabkey},pkey=>$_[0]->{pkey}})) {	 
 	$outp="$outp <input type='file' name='$prmname' value='$val->{value}' onchange='document.$formname.$flagname.value=1'>\n";
 } 	
 return $outp;
}


sub editfilelink {
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey};
 	my $tabpkey=$_[0]->{tabpkey};
 	my $pkey=$_[0]->{pkey};
 	my $lang=$_[0]->{lang};
 	my $formname=$_[0]->{form};
 	my $flagname=$_[0]->{flag};
  	my $checked;

 	my $prmname;
 	if ($tabkey) {$prmname='vk'.$tabkey.'v'.$pkey} else {$prmname="v$pkey"}
 
 	my $val=calculate({id=>$id,uid=>$uid,pkey=>$pkey,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)"});
 	my $viewstr;
 	if ($val->{value}=~/\.(jpe?g|png|gif)$/i){
 		$viewstr = "<img src='$val->{value}'/><br/>";
 	}
 	 
	return $viewstr.textfield (
 				-name=>$prmname,
 				-default=>$val->{value},
 				-onChange=>"document.$formname.$flagname.value=1",
 				-override=>1,
	).
	a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$_", -target=>'_blank'},">>");			 
}



sub editmemo {
 	my $id=$_[0]->{id};
 	my $uid=$_[0]->{uid};
 	my $tabkey=$_[0]->{tabkey} || '';
 	my $tabpkey=$_[0]->{tabpkey} || '';
 	my $pkey=$_[0]->{pkey};
 	my $lang=$_[0]->{lang};
 	my @outp;
 
 	if ($lang eq 'mul') {
 		for (@LANGS) {
 		   push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$_", -target=>'_blank'},enc("Редактировать ")."($LANGS{$_})"));			 
 		}	 
	} elsif ($lang) {
		  push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$lang", -target=>'_blank'},enc("Редактировать ")."($LANGS{$lang})"));			 
	}	else {	
		  push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey", -target=>'_blank'},enc("Редактировать")));			 
  } 	
  
  if ($prm->{$pkey}->{extra}->{script} eq 'y') {
  	push(@outp,a({-href=>"?action=execscript&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey", -target=>'_blank'},enc("Выполнить")));			 
	}	
  
  return join('<br>',@outp);
}

sub editmatrix
{
 my $id=$_[0]->{id};
 my $uid=$_[0]->{uid};
 my $pkey=$_[0]->{pkey};
 my $outp=a({-href=>"$ENV{SCRIPT_NAME}?action=editmatrix&objid=$id&objuid=$uid&pkey=$pkey",-target=>'_blank'},enc('Редактировать'));
 return $outp;
}


sub editmethodform ($$;$) 
{
	my ($id,$pkey,$lflag)=@_;

	my $r=enc($lflag?'Метод нижних объектов ':'Метод ');
	
	my $n=$lflag?'lmethod':'method';
	
	print enc("Объект "),b($obj->{$id}->{name})," ($obj->{$id}->{key})",br;
	print $r,b($obj->{$id}->{$n}->{$pkey}->{name})," ($pkey) ",br;
	
	print enc(q(
		<script language="javascript" type="text/javascript">
			editAreaLoader.init({
			id : "editarea"		
			,language: "ru"
			,syntax: "perl"			
			,start_highlight: true		
		});
		function console (script) {
				$('resultDiv').update('...');
				$('statusDiv').update('ВЫПОЛНЕНИЕ');
          		var dt={script: script};
          		ajax_call('console', dt, console_callback);
  			}
			
			function console_callback(json){
				     $('resultDiv').update(json.result);
				     var statusstr;
				     if (json.status=='SUCCESS') {
				     	statusstr='УСПЕХ';
				     } else {
				     	statusstr='ОШИБКА';
				     }		
				     $('statusDiv').update(statusstr);
				     
            }
		</script>		
	));
	


	
	my $save_js="editmethod('$id','$pkey','$lflag',editAreaLoader.getValue('editarea'))";
	my $savenrun_js="console(editAreaLoader.getValue('editarea'))";
	print textarea(-id=>'editarea',-default=>$obj->{$id}->{$n}->{$pkey}->{script},-rows=>40,-cols=>150,-override=>1);
	print br;
	print button(-value=>enc('Сохранить'),-onclick=>$save_js);
	print button(-value=>enc('Протестировать'),-onclick=>$savenrun_js);

	print hr,table(Tr(td(enc("Результат выполнения скрипта : ")),td("<div id='statusDiv'></div>")));
	print hr,"<div id='resultDiv'></div>";
	
}	

sub editfilelinkfull
{
 	my $id=0+param('objid');
 	my $pkey=param('pkey');
 	my $uid=0+param('objuid');
 	my $lang=param('lang');
 	
 	my $val=calculate({id=>$id,uid=>$uid,expr=>"p($pkey)",noparse=>1,lang=>$lang});
    my $filename=$val->{value};
    my $fcontent;
    my $fullpath=$prm->{$pkey}->{extra}->{cgi}?"$GLOBAL->{CGIPATH}/$filename":"$GLOBAL->{WWWPATH}/$filename";
    open (FC, "<$fullpath");
	read (FC,$fcontent,-s FC);
	close(FC); 
	
 	my $name;
 	if    ($id)  {$name="$lobj->{$id}->{name} ($lobj->{$id}->{key})"}
 	elsif ($uid) {$name="$obj->{$uid}->{name} ($obj->{$uid}->{key})"}

	print enc("Объект "),b($name),enc(" Параметр "),b("$prm->{$pkey}->{name} ($pkey)");
	print enc(" Язык "),b($LANGS{$lang}) if $lang;
	print br(),br();  

    my $syn;
 	$syn='css' if $filename=~/\.css/;
    $syn='js' if $filename=~/\.js/;
    
    my $h_on=$syn?'true':'false';
    
	print qq(
		<script language="javascript" type="text/javascript">
			editAreaLoader.init({
			id : "editarea"		
			,language: "ru"
			,syntax: "$syn"			
			,start_highlight: $h_on	
			,replace_tab_by_spaces : 4	
		});
		</script>
	);
    my $save_js="setvalue('$id','$uid','$pkey','$lang',editAreaLoader.getValue('editarea'))";


 	print button(-name=>'bt2',-value=>enc('Сохранить'),-onclick=>$save_js),br;
	print textarea(-id=>'editarea',-default=>$fcontent,-rows=>40,-cols=>150,-override=>1);	
 	print br;
	print button(-name=>'bt',-value=>enc('Сохранить'),-onclick=>$save_js);
 	

 	print "</body></html>";
 	
 	
 	
}




sub editmemofull
{
 	my $id=param('objid') || 0;
 	my $pkey=param('pkey');
 	my $uid=param('objuid') || 0;
 	my $tabkey=param('tabkey');
 	my $tabpkey=param('tabpkey');
 	my $lang=param('lang') || '';
 	
 	my $val=calculate({id=>$id,uid=>$uid,tabkey=>$tabkey,tabpkey=>$tabpkey,expr=>"p($pkey)",noparse=>1,lang=>$lang});

 	my $name;
 	if    ($id)  {$name="$lobj->{$id}->{name} ($lobj->{$id}->{key})"}
 	elsif ($uid) {$name="$obj->{$uid}->{name} ($obj->{$uid}->{key})"}

	if ($tabpkey) {
		print enc("Табличный объект "),b($name),enc(" Параметр "),b("$prm->{$tabpkey}->{name} ($tabpkey)"),br;
		my @tablist = map {
			if ($_=~/^u(\d+)$/) {$_=$obj->{$1}->{name}}
			else {checkload ({id=>$_}); $_=$lobj->{$_}->{name}}
		} split(/_/,$tabkey);
		print enc("Объект "),b(@tablist),enc(" Параметр "),b("$prm->{$pkey}->{name} ($pkey)"),br();
	}
	else {
		print enc("Объект "),b($name),enc(" Параметр "),b("$prm->{$pkey}->{name} ($pkey)");
		print enc(" Язык "),b($LANGS{$lang}) if $lang;
		print br(),br();  
	}
 
	print qq(
		<script language="javascript" type="text/javascript">
			editAreaLoader.init({
			id : "editarea"		
			,language: "ru"
			,syntax: "html"			
			,start_highlight: true	
			,replace_tab_by_spaces : 4	
		});
		</script>
	);
    my $save_js="setvalue('$id','$uid','$pkey','$lang',editAreaLoader.getValue('editarea'))";


 	print button(-name=>'bt2',-value=>enc('Сохранить'),-onclick=>$save_js),br;
	print textarea(-id=>'editarea',-default=>$val->{value},-rows=>40,-cols=>150,-override=>1);	
 	print br;
	print button(-name=>'bt',-value=>enc('Сохранить'),-onclick=>$save_js);
	print hr;
 	print a({-href=>"?action=editmemo&objid=$id&pkey=$pkey&lang=$lang&history=1"},enc('История')),br;
    if (param('history')) {
    	my $r=o($id)->History($pkey);
    	print start_table();
    	for (@$r) {
			print Tr(td($_->{dt}),td(textarea(-default=>$_->{value},-rows=>20,-cols=>150)));    		
    	}
		print end_table();    	
    }

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

 print "Объект <b> $name </b> Параметр <b>$prm->{$pkey}->{name} ($pkey) </b><hr>";
 
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
 		print "Параметр <b>$prm->{$vls->{$_}->{name}}->{name}</b> Объект  <b>$n</b> <br>";
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
 print "<input name='bt' value='Редактировать' type='submit'>";
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
    my $v=timelocal(@tlist);
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
		push (@o,[enc('Формула'),textfield(-name=>"exformula$pkey", -default=>$extra->{formula}, -onchange=>$onc, -override=>1)]);
	} else {
		push (@o,[enc('Формула'),textarea(-name=>"exformula$pkey", -default=>$extra->{formula}, -onchange=>$onc, -override=>1, -cols=>130,-rows=>15)])
	}
  	push (@o,[enc('Одиночное'),checkbox(-name=>"exsingle$pkey", -value=>1, -checked=>$ss, -label=>'', -onchange=>"document.$formname.$flagname.value=1", -override=>1)]);
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
 		my $outp=enc('Формат ').textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -onchange=>"document.$formname.$flagname.value=1", -override=>1).br;
 		$outp.=enc('Фикс ').checkbox(-name=>"fix$pkey", -value=>1, -checked=>$fix, -onchange=>"document.$formname.$flagname.value=1", -override=>1, -label=>'');
 		$outp.=enc('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');
		return $outp;
	} else {
 		my $outp=enc('Формат ').textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -override=>1).br;
 		$outp.=enc('Фикс ').checkbox(-name=>"fix$pkey", -value=>1, -checked=>$fix, -override=>1, -label=>'');
 		$outp.=enc('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -label=>'');
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
 		$outp=enc('Длина').textfield(-size=>1, -name=>"excols$pkey", -default=>$extra->{cols}, -onchange=>"document.$formname.$flagname.value=1", -override=>1);
 		$outp.=enc('Строк').textfield(-size=>1, -name=>"exrows$pkey", -default=>$extra->{rows}, -onchange=>"document.$formname.$flagname.value=1", -override=>1);
		$outp.=enc('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');		

	} else {
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
		$outp=enc('Длина').textfield(-size=>1, -name=>"excols$pkey", -default=>$extra->{cols}, -override=>1);
		$outp.=enc('Строк').textfield(-size=>1, -name=>"exrows$pkey", -default=>$extra->{rows}, -override=>1);
		$outp.=enc('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'');		
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
		$outp.=enc('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');		

	} else {
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
		$outp.=enc('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'');		
	}	
  return $outp;	
	
}

sub extrafilelink {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
	my $outp=enc('CGI');
	$outp.=checkbox(
			-name=>"excgi$pkey", 
			-checked=>$extra->{cgi} eq 'y'?'checked':'', 
			-override=>1, 
			-value=>1, 
			-onchange=>$_[0]->{check}?"document.$_[0]->{form}.$_[0]->{flag}.value=1":'', 
			-label=>'',
	);		
	return $outp;	
}



sub extranumber {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	my $ss=$extra && $extra->{srch} eq 'y'?'checked':'';
 	my $sp=$extra && $extra->{splt} eq 'y'?'checked':'';
 	my $flagname=$_[0]->{flag};
	my $formname=$_[0]->{form};
 	my $oc=$_[0]->{check}?"document.$formname.$flagname.value=1":'';
	my $outp=enc('Формат ').textfield(-size=>2, -name=>"exformat$pkey", -default=>$extra->{format}, -onchange=>$oc, -override=>1);
	$outp.=enc('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>$oc, -label=>'');
	$outp.=enc('Разбить').checkbox(-name=>"exsplt$pkey", -checked=>$sp, -override=>1, -value=>1, -onchange=>$oc, -label=>''); 		
	
	
}





sub extramemo {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	my $ss= $extra && $extra->{parse} eq 'y'?'checked':'';
 	my $sse=$extra && $extra->{script} eq 'y'?'checked':'';
 	my $ssv=$extra && $extra->{visual} eq 'y'?'checked':'';
 	
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	
 	my $outp=enc('Разбор').checkbox(-name=>"exparse$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');		
	$outp.=enc('Вып').checkbox(-name=>"exscript$pkey", -checked=>$sse, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');
	$outp.=enc('Виз').checkbox(-name=>"exvisual$pkey", -checked=>$ssv, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');
			
	return $outp;
}



sub extramatrix {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	
 	if ($_[0]->{check}) {
		my $flagname=$_[0]->{flag};
 		my $formname=$_[0]->{form};
 	   	my $outp=enc('Параметры').  " <input name='exparam$pkey'  value='$extra->{param}' onchange='document.$formname.$flagname.value=1'><br>";
        $outp.=enc('Шаблон ячейки')." <input name='excell$pkey'   value='$extra->{cell}' onchange='document.$formname.$flagname.value=1'>";   
        return $outp;
    } else {
 	   	my $outp=enc('Параметры')." <input name='exparam$pkey'  value='$extra->{param}'><br>";
        $outp.=enc('Шаблон ячейки')." <input name='excell$pkey'   value='$extra->{cell}'>";   
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
 	my $prs=param("exsrch$pkey")?'y':'n';
 	setprmextra({pkey=>$pkey,extra=>'srch',value=>$prs});
 	my $spl=param("exsplt$pkey")?'y':'n';
 	setprmextra({pkey=>$pkey,extra=>'splt',value=>$spl});
 	
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

sub extrafilelinkparse {
 	my $pkey=$_[0]->{pkey};
 	my $prs=param("excgi$pkey")?'y':'n';
 	setprmextra({pkey=>$pkey,extra=>'cgi',value=>$prs});
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
        	 name       =>enc('Строка'),
                 editview   =>\&cmlview::edittext,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extratext,
                 extraparse =>\&cmlview::extratextparse,
        };
 	$ptype{NUMBER}={
                 name       =>enc('Число'),
                 editview   =>\&cmlview::editnumber,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extranumber,
                 extraparse =>\&cmlview::extranumberparse,
        };
  	$ptype{LONGTEXT}={
                 name       =>enc('Текст'),
                 editview   =>\&cmlview::editmemo,
                 extra      =>\&cmlview::extramemo,
                 extraparse =>\&cmlview::extramemoparse,
                 extendedit =>\&cmlview::editmemofull,
                 extendset=>\&cmlview::setmemofull,
        };
  	$ptype{FLAG}={
                 name       =>enc('Флаг'),
                 editview   =>\&cmlview::editflag,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extraflag,
                 extraparse =>\&cmlview::extraflagparse,
        };
  	$ptype{DATE}={
                 name       =>enc('Дата'),
                 editview   =>\&cmlview::editdate,
                 setvalue   =>\&cmlview::setdate,
                 extra      =>\&cmlview::extradate,
                 extraparse =>\&cmlview::extradateparse,
        };
  	$ptype{LIST}={
                 name       =>enc('Список'),
                 editview   =>\&cmlview::editlist,
                 setvalue   =>\&cmlview::setlist,
                 extra      =>\&cmlview::extralist,
                 extraparse =>\&cmlview::extralistparse,
        };
  	$ptype{MATRIX}={
                 name       =>enc('Матрица'),
                 editview   =>\&cmlview::editmatrix,
                 extra      =>\&cmlview::extramatrix,
                 extraparse =>\&cmlview::extramatrixparse,
                 extendedit =>\&cmlview::editmatrixfull,
                 extendset=>\&cmlview::setmatrixfull,
        };
 	$ptype{PICTURE}={
                 name       =>enc('Картинка'),
                 editview   =>\&cmlview::editpicture,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };
        $ptype{VIDEO}={
                 name       =>enc('Видеоролик'),        	
                 editview   =>\&cmlview::editvideo,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };
        
        
 	$ptype{FILE}={
                 name       =>enc('Файл'),
                 editview   =>\&cmlview::editfile,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };

   $ptype{AUDIO}={
                 name       =>enc('Музыка'),
                 editview   =>\&cmlview::editfile,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };



	$ptype{FILELINK}={
                 name       =>enc('Ссылка на файл'),
                 editview   =>\&cmlview::editfilelink,
                 extra      =>\&cmlview::extrafilelink,
                 extraparse =>\&cmlview::extrafilelinkparse,
                 setvalue   =>\&cmlview::settext,
                 extendedit =>\&cmlview::editfilelinkfull,
                 extendset=>\&cmlview::setfilelinkfull,
        };
  
}


return 1;


END {}
