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
 	&viewhistoryform &viewallhistoryform &viewmethodform &viewprmform
 );

}

sub code_mirror_js {
	my ($opts)=@_;
	$opts->{mode}   ||= 'perl';
	$opts->{width}  ||= 1500;
	$opts->{height} ||= 800;
	my $add;
	if (lc $opts->{mode} eq 'html') {
		$opts->{mode}="xml";
		$add="htmlMode: true,\n";
	}
	my $js=qq(
	    <script> 
        var myCodeMirror = CodeMirror.fromTextArea(document.getElementById("editarea"),{
            	mode: "$opts->{mode}",
            	matchBrackets: true,
            	autoCloseBrackets: true,
            	$add
				lineNumbers: true
     	});
		myCodeMirror.setSize($opts->{width}, $opts->{height});
		</script> 
	); 
}


sub print_top {
	my ($title)=@_;
   
	$title='VCMS' unless $title;
	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
	print "<html><head><title>$title</title>";

    print q(

	<script src="/codemirror/lib/codemirror.js"></script>
	<link rel="stylesheet" href="/codemirror/lib/codemirror.css">
	<link rel="stylesheet" href="/codemirror/addon/dialog/dialog.css">
	<script src="/codemirror/mode/xml/xml.js"></script>
    <script src="/codemirror/mode/css/css.js"></script>
    <script src="/codemirror/mode/perl/perl.js"></script>
    <script src="/codemirror/mode/javascript/javascript.js"></script>
    <script src="/codemirror/mode/htmlmixed/htmlmixed.js"></script>
    <script src="/codemirror/addon/edit/matchbrackets.js"></script>
    <script src="/codemirror/addon/edit/closebrackets.js"></script>
	<script src="/codemirror/addon/dialog/dialog.js"></script>
	<script src="/codemirror/addon/search/searchcursor.js"></script>
	<script src="/codemirror/addon/search/search.js"></script>
    <script src="/codemirror/addon/scroll/annotatescrollbar.js"></script>
    <script src="/codemirror/addon/search/matchesonscrollbar.js"></script>
    

    <link rel='stylesheet' type='text/css' href='/css/vcms.css'>
    
    <style type="text/css">
      .CodeMirror {border: 1px solid black; font-size:13px}
    </style>
    
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
 	$tlbls->{''}=encu('Не определен');
 
 	$tl->{vals}=\@tvals;
 	$tl->{lbls}=$tlbls;
 
 	return $tl;
}	

sub config {
	print start_form(-method=>'post',-name=>'mfrm');
	print encu("Конфигурация");
	print start_table();
	print Tr(td(),td(),td());
	print end_table();
    my $save_js="ajax_call('setconf',{conf:myCodeMirror.getValue()},sccallback)";
    my $fcontent;
	open (FC, "<$cmlmain::GLOBAL->{CGIPATH}/conf");
	read (FC,$fcontent,-s FC);
	close(FC); 

 	print button(-name=>'bt2',-value=>encu('Сохранить конфигурацию'),-onclick=>$save_js),br;
	print textarea(-id=>'editarea',-default=>$fcontent,-rows=>20,-cols=>100,-override=>1);	
 	print br;
	print button(-name=>'bt',-value=>encu('Сохранить конфигурацию'),-onclick=>$save_js);
	print hr;
	print qq(
		<script language="javascript" type="text/javascript">
			var myCodeMirror = CodeMirror.fromTextArea(document.getElementById("editarea"),{
				lineNumbers: true,
				mode:"perl"
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
	
	
	
	print start_form(-method=>'post',-name=>'mfrm2');
	print encu("HTACCESS");
	print start_table();
	print Tr(td(),td(),td());
	print end_table();
    my $save_js2="ajax_call('sethtaccess',{conf:myCodeMirror2.getValue()},sccallback)";
    my $fcontent2;
	open (FC2, "<$cmlmain::GLOBAL->{WWWPATH}/.htaccess");
	read (FC2,$fcontent2,-s FC2);
	close(FC2); 

 	print button(-name=>'b2bt2',-value=>encu('Сохранить htaccess'),-onclick=>$save_js2),br;
	print textarea(-id=>'editarea2',-default=>$fcontent2,-rows=>20,-cols=>100,-override=>1);	
 	print br;
	print button(-name=>'b2bt',-value=>encu('Сохранить htaccess'),-onclick=>$save_js2);

	
	print qq(
		<script language="javascript" type="text/javascript">
			var myCodeMirror2 = CodeMirror.fromTextArea(document.getElementById("editarea2"),{
				lineNumbers: true
			});
		</script>
	);
	
	
	print hr;
	print encu("Экспорт"),br;
	print end_form();
	print a({-href=>"?action=export&area=scripts"},encu('скрипты')),br;
	print a({-href=>"?action=export&area=docs"},encu('статика')),br;
	print a({-href=>"?action=export&area=data"},encu('файлы и картинки')),br;
	print a({-href=>"?action=export&area=db"},encu('база данных')),br;
	
}

sub viewmethodform{
	my $mkey=$_[0];
	print_top();

	my $struct=$cmlmain::method->{$mkey}||$cmlmain::lmethod->{$mkey}; 
	print "METHOD $mkey",br;
	print "OBJID",a({-href=>"?action=editform&id=$struct->{ownerid}"},$struct->{ownerid}),br;
	print textarea(-default=>$struct->{script},-rows=>10,-cols=>50),br;

	
}

sub viewprmform{
	my $pkey=$_[0];
	print_top();
	
	
	my $prm_struct=prminfo($pkey);
	print "PRM $pkey";
	print start_table();
	print Tr(th(encu('Имя')),th(encu('Тип')),th(encu('Объект')),th(encu('Формула')),th(encu('Вып')),th(encu('Изм')),th(encu('Свой')));
	for my $p (@{$prm_struct->{prm}}) {
		print Tr(
			td($p->{pname}),
			td($p->{ptype}),
			td(a({-href=>"?action=editform&id=$p->{objid}"},$p->{objid})),
			td($p->{defval}),
			td($p->{evaluate}),
			td($p->{upd}),
			td($p->{self}),
		); 
	}
	print end_table();
	print br;
	print start_table();
	for my $k (keys %{$prm_struct->{extra}}) {
		print Tr(
			th($k),
			td($prm_struct->{extra}->{$k}),
		); 
	}
	print end_table();
	
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
		th(encu('Время')),
		th(encu('Параметр')),
		th(encu('Значение')),
		th(encu('Пользователь')),
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
	
	print start_form(-method=>'post');
	print hidden (-name=>'action',-default=>'editprm',-override=>1);
  	print hidden (-name=>'pname',-default=>$pkey);
  	print hidden (-name=>'id',-default=>$id);
	
	print start_table();
	print Tr(th(encu('Объект')),td(b($obj->{$id}->{name})));
	print Tr(th(encu('Наименование параметра')),td(b(textfield(-name=>'prmname',-default=>$prm->{$pkey}->{name},override=>1,size=>130))));
	print Tr(th(encu('Ключ')),td(b($pkey)));
	print Tr(th(encu('Тип')),td(b($ptype{$prm->{$pkey}->{type}}->{name})));
	
	my $tl=lmethod_list();
	print Tr(th(encu('Обработчик OnChange')),td(b(popup_menu(-name=>'onchange',-default=>$prm->{$pkey}->{extra}->{onchange},-values=>$tl->{vals},-labels=>$tl->{lbls},-override=>1))));
	if ($prm->{$pkey}->{upd}->{$id} eq 'y') {$ss=1} else {$ss=''}
	print Tr(th(encu('Исправляемый')),td(b(checkbox(-name=>'prmupd',-value=>1,-checked=>$ss,-label=>'',override=>1))));
	if ($prm->{$pkey}->{evaluate} eq 'y') {$ss=1} else {$ss=''}
	print Tr(th(encu('Выполняемый')),td(b(checkbox(-name=>'prmevl',-value=>1,-checked=>$ss,-label=>'',override=>1))));  
  	print Tr(th(encu('Умолчание')),td(textarea(-id=>'editarea',-name=>'prmdef',-default=>$prm->{$pkey}->{defval}->{$id},override=>1,rows=>15,cols=>130)));
	print Tr(th(encu('Условие доступа')),td(textarea(-name=>'hasaccess',-default=>$prm->{$pkey}->{extra}->{hasaccess},override=>1,rows=>15,cols=>130)));  
  	if (ref $extra eq 'ARRAY') {
    	print Tr(th({-colspan=>2},encu("Дополнительные атрибуты")));
    	for (@$extra) {
    		print Tr(th($_->[0]),td($_->[1]));
    	}	
  	}	
	print Tr(th(),td(submit(-value=>encu('Исправить'))));
	print end_table();
  	if (ref $extra ne 'ARRAY') {  
  		print $extra,br 
  	}
	print endform;
	
	print q(
	 <script language="javascript" type="text/javascript">
 		var myCodeMirror = CodeMirror.fromTextArea(document.getElementById("editarea"),{
            	mode: "text/x-perl",
				lineNumbers: true
    	});	 
	 </script> 	
	);
	
	
}

sub console {
	my $value=$_[0];
    my $save_js="vcms_console(myCodeMirror.getValue())";
	print textarea(-id=>'editarea',-default=>$value,-override=>1);
	print br;
	print button(-value=>encu('Выполнить'),-onclick=>$save_js);
	print hr,table(Tr(td(encu("Результат выполнения скрипта : ")),td("<div id='statusDiv'></div>")));
	print hr,"<textarea id='resultDiv' rows='30' cols='100'></textarea>";
	print encu(q(
	        <script language="javascript" type="text/javascript">
			function vcms_console (script) {
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
    print code_mirror_js({width=>1000,height=>300});
	
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
        	  $lhash->{''}=encu('Ничего');
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
			encu(strftime ("\%$1",localtime($val->{value})));
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
 my $label=encu('Скачать');
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
 		   push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$_", -target=>'_blank'},encu("Редактировать ")."($LANGS{$_})"));			 
 		}	 
	} elsif ($lang) {
		  push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$lang", -target=>'_blank'},encu("Редактировать ")."($LANGS{$lang})"));			 
	}	else {	
		  push(@outp,a({-href=>"?action=editmemo&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey", -target=>'_blank'},encu("Редактировать")));			 
  } 	
  
  if ($prm->{$pkey}->{extra}->{script} eq 'y') {
  	push(@outp,a({-href=>"?action=execscript&objid=$id&objuid=$uid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey", -target=>'_blank'},encu("Выполнить")));			 
	}	
  
  return join('<br>',@outp);
}

sub editmatrix
{
 my $id=$_[0]->{id};
 my $uid=$_[0]->{uid};
 my $pkey=$_[0]->{pkey};
 my $outp=a({-href=>"$ENV{SCRIPT_NAME}?action=editmatrix&objid=$id&objuid=$uid&pkey=$pkey",-target=>'_blank'},encu('Редактировать'));
 return $outp;
}


sub editmethodform ($$;$) 
{
	my ($id,$pkey,$lflag)=@_;

	my $r=encu($lflag?'Метод нижних объектов ':'Метод ');
	
	my $n=$lflag?'lmethod':'method';
	
	print encu("Объект "),b($obj->{$id}->{name})," ($obj->{$id}->{key})",br;
	print $r,b($obj->{$id}->{$n}->{$pkey}->{name})," ($pkey) ",br;
	
	my $save_js="editmethod('$id','$pkey','$lflag',myCodeMirror.getValue())";
	my $savenrun_js="vcms_console(myCodeMirror.getValue())";
	print textarea(-id=>'editarea',-default=>$obj->{$id}->{$n}->{$pkey}->{script},-rows=>25,-cols=>150,-override=>1);
	print br;
	print button(-value=>encu('Сохранить'),-onclick=>$save_js);
	print button(-value=>encu('Протестировать'),-onclick=>$savenrun_js);

	print hr,table(Tr(td(encu("Результат выполнения скрипта : ")),td("<div id='statusDiv'></div>")));
	print encu(q(
		<script language="javascript" type="text/javascript">
			function vcms_console (script) {
				$('resultDiv').update('...');
				$('statusDiv').update('ВЫПОЛНЕНИЕ');
          		var dt={script: script};
          		ajax_call('console', dt, console_callback);
  			}
			
			function console_callback(json){
					 if (json.result.message) {
				     	$('resultDiv').update(json.result.message);
					 } else {
					 	$('resultDiv').update(json.result);
					 }		
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
	print code_mirror_js({height=>400});
	print hr,"<textarea id='resultDiv' rows='15' cols='200'></textarea>";
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
    my $fullpath="$GLOBAL->{WWWPATH}/$filename";
    $fullpath="$GLOBAL->{CGIPATH}/$filename" if $prm->{$pkey}->{extra}->{cgi} eq 'y';
    $fullpath=$filename if $prm->{$pkey}->{extra}->{abs} eq 'y';
    open (FC, "<$fullpath");
	read (FC,$fcontent,-s FC);
	close(FC); 
	
 	my $name;
 	if    ($id)  {$name="$lobj->{$id}->{name} ($lobj->{$id}->{key})"}
 	elsif ($uid) {$name="$obj->{$uid}->{name} ($obj->{$uid}->{key})"}

	print encu("Объект "),b($name),encu(" Параметр "),b("$prm->{$pkey}->{name} ($pkey)"),encu(" Файл "),b($fullpath);
	print encu(" Язык "),b($LANGS{$lang}) if $lang;
	print br(),br();  
	my $save_js="setvalue('$id','$uid','$pkey','$lang',myCodeMirror.getValue())";
	
	
	my $mode='html';
	$mode='css' if $filename=~/css$/;
	$mode='javascript' if $filename=~/js$/;
	
 	print button(-name=>'bt2',-value=>encu('Сохранить'),-onclick=>$save_js),br;
	print textarea(-id=>'editarea',-default=>$fcontent,-override=>1);
	print code_mirror_js({mode=>$mode});
	
 	print br;
	print button(-name=>'bt',-value=>encu('Сохранить'),-onclick=>$save_js);
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
		print encu("Табличный объект "),b($name),encu(" Параметр "),b("$prm->{$tabpkey}->{name} ($tabpkey)"),br;
		my @tablist = map {
			if ($_=~/^u(\d+)$/) {$_=$obj->{$1}->{name}}
			else {checkload ({id=>$_}); $_=$lobj->{$_}->{name}}
		} split(/_/,$tabkey);
		print encu("Объект "),b(@tablist),encu(" Параметр "),b("$prm->{$pkey}->{name} ($pkey)"),br();
	}
	else {
		print encu("Объект "),b($name),encu(" Параметр "),b("$prm->{$pkey}->{name} ($pkey)");
		print encu(" Язык "),b($LANGS{$lang}) if $lang;
		print br(),br();  
	}
 
    my $save_js="setvalue('$id','$uid','$pkey','$lang',myCodeMirror.getValue())";
 	print button(-name=>'bt2',-value=>encu('Сохранить'),-onclick=>$save_js),br;
	print textarea(-id=>'editarea',-default=>$val->{value},-rows=>40,-cols=>150,-override=>1);	
 	print br;
	print button(-name=>'bt',-value=>encu('Сохранить'),-onclick=>$save_js);
	print code_mirror_js({mode=>"html"});
	print hr;
 	print a({-href=>"?action=editmemo&objid=$id&pkey=$pkey&lang=$lang&history=1"},encu('История')),br;
    if (param('history')) {
    	my $r=o($id)->History({prm=>$pkey});
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
 open FILE,">$GLOBAL->{FILEPATH}/$fname" || die "open file error (fname=$GLOBAL->{FILEPATH}/$fname) $!";
 while ($buffer=<$fh>) { 
 	print FILE $buffer; 
 }
 close  FILE || die "close file error (fname=$GLOBAL->{FILEPATH}/$fname) $!";
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
		push (@o,[encu('Формула'),textfield(-name=>"exformula$pkey", -default=>$extra->{formula}, -onchange=>$onc, -override=>1)]);
	} else {
		push (@o,[encu('Формула'),textarea(-name=>"exformula$pkey", -default=>$extra->{formula}, -onchange=>$onc, -override=>1, -cols=>130,-rows=>15)])
	}
  	push (@o,[encu('Одиночное'),checkbox(-name=>"exsingle$pkey", -value=>1, -checked=>$ss, -label=>'', -onchange=>"document.$formname.$flagname.value=1", -override=>1)]);
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
 		my $outp=encu('Формат ').textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -onchange=>"document.$formname.$flagname.value=1", -override=>1).br;
 		$outp.=encu('Фикс ').checkbox(-name=>"fix$pkey", -value=>1, -checked=>$fix, -onchange=>"document.$formname.$flagname.value=1", -override=>1, -label=>'');
 		$outp.=encu('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');
		return $outp;
	} else {
 		my $outp=encu('Формат ').textfield(-name=>"exformat$pkey", -default=>$extra->{format}, -override=>1).br;
 		$outp.=encu('Фикс ').checkbox(-name=>"fix$pkey", -value=>1, -checked=>$fix, -override=>1, -label=>'');
 		$outp.=encu('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -label=>'');
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
 		$outp=encu('Длина').textfield(-size=>1, -name=>"excols$pkey", -default=>$extra->{cols}, -onchange=>"document.$formname.$flagname.value=1", -override=>1);
 		$outp.=encu('Строк').textfield(-size=>1, -name=>"exrows$pkey", -default=>$extra->{rows}, -onchange=>"document.$formname.$flagname.value=1", -override=>1);
		$outp.=encu('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');		

	} else {
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
		$outp=encu('Длина').textfield(-size=>1, -name=>"excols$pkey", -default=>$extra->{cols}, -override=>1);
		$outp.=encu('Строк').textfield(-size=>1, -name=>"exrows$pkey", -default=>$extra->{rows}, -override=>1);
		$outp.=encu('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'');		
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
		$outp.=encu('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>"document.$formname.$flagname.value=1", -label=>'');		

	} else {
 		my $ss;
 		if ($extra->{srch} eq 'y') {$ss='checked'} else {$ss=''}
		$outp.=encu('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'');		
	}	
  return $outp;	
	
}

sub extrafilelink {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
	my $outp=encu('CGI').checkbox(
			-name=>"excgi$pkey", 
			-checked=>$extra->{cgi} eq 'y'?'checked':'', 
			-override=>1, 
			-value=>1, 
			-onchange=>$_[0]->{check}?"document.$_[0]->{form}.$_[0]->{flag}.value=1":'', 
			-label=>'',
	);	
	$outp.=encu('ABS').checkbox(
			-name=>"exabs$pkey", 
			-checked=>$extra->{abs} eq 'y'?'checked':'', 
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
	my $outp=encu('Формат ').textfield(-size=>2, -name=>"exformat$pkey", -default=>$extra->{format}, -onchange=>$oc, -override=>1);
	$outp.=encu('Поиск').checkbox(-name=>"exsrch$pkey", -checked=>$ss, -override=>1, -value=>1, -onchange=>$oc, -label=>'');
	$outp.=encu('Разбить').checkbox(-name=>"exsplt$pkey", -checked=>$sp, -override=>1, -value=>1, -onchange=>$oc, -label=>''); 		
	
	
}





sub extramemo {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	my $ss= $extra && $extra->{parse} eq 'y'?'checked':'';
 	my $sse=$extra && $extra->{script} eq 'y'?'checked':'';
 	my $ssv=$extra && $extra->{visual} eq 'y'?'checked':'';
 	
 	my $flagname=$_[0]->{flag};
 	my $formname=$_[0]->{form};
 	
 	my $outp=encu('Разбор').checkbox(-name=>"exparse$pkey", -checked=>$ss, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');		
	$outp.=encu('Вып').checkbox(-name=>"exscript$pkey", -checked=>$sse, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');
	$outp.=encu('Виз').checkbox(-name=>"exvisual$pkey", -checked=>$ssv, -override=>1, -value=>1, label=>'', onchange=>$_[0]->{check}?"document.$formname.$flagname.value=1":'');
			
	return $outp;
}



sub extramatrix {
 	my $pkey=$_[0]->{pkey};
 	my $extra=$prm->{$pkey}->{extra};
 	
 	if ($_[0]->{check}) {
		my $flagname=$_[0]->{flag};
 		my $formname=$_[0]->{form};
 	   	my $outp=encu('Параметры').  " <input name='exparam$pkey'  value='$extra->{param}' onchange='document.$formname.$flagname.value=1'><br>";
        $outp.=encu('Шаблон ячейки')." <input name='excell$pkey'   value='$extra->{cell}' onchange='document.$formname.$flagname.value=1'>";   
        return $outp;
    } else {
 	   	my $outp=encu('Параметры')." <input name='exparam$pkey'  value='$extra->{param}'><br>";
        $outp.=encu('Шаблон ячейки')." <input name='excell$pkey'   value='$extra->{cell}'>";   
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
    setprmextra({pkey=>$pkey,extra=>'cgi',value=>param("excgi$pkey")?'y':'n'}); 	
 	setprmextra({pkey=>$pkey,extra=>'abs',value=>param("exabs$pkey")?'y':'n'});
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
        	 name       =>encu('Строка'),
                 editview   =>\&cmlview::edittext,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extratext,
                 extraparse =>\&cmlview::extratextparse,
        };
 	$ptype{NUMBER}={
                 name       =>encu('Число'),
                 editview   =>\&cmlview::editnumber,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extranumber,
                 extraparse =>\&cmlview::extranumberparse,
        };
  	$ptype{LONGTEXT}={
                 name       =>encu('Текст'),
                 editview   =>\&cmlview::editmemo,
                 extra      =>\&cmlview::extramemo,
                 extraparse =>\&cmlview::extramemoparse,
                 extendedit =>\&cmlview::editmemofull,
                 extendset=>\&cmlview::setmemofull,
        };
  	$ptype{FLAG}={
                 name       =>encu('Флаг'),
                 editview   =>\&cmlview::editflag,
                 setvalue   =>\&cmlview::settext,
                 extra      =>\&cmlview::extraflag,
                 extraparse =>\&cmlview::extraflagparse,
        };
  	$ptype{DATE}={
                 name       =>encu('Дата'),
                 editview   =>\&cmlview::editdate,
                 setvalue   =>\&cmlview::setdate,
                 extra      =>\&cmlview::extradate,
                 extraparse =>\&cmlview::extradateparse,
        };
  	$ptype{LIST}={
                 name       =>encu('Список'),
                 editview   =>\&cmlview::editlist,
                 setvalue   =>\&cmlview::setlist,
                 extra      =>\&cmlview::extralist,
                 extraparse =>\&cmlview::extralistparse,
        };
  	$ptype{MATRIX}={
                 name       =>encu('Матрица'),
                 editview   =>\&cmlview::editmatrix,
                 extra      =>\&cmlview::extramatrix,
                 extraparse =>\&cmlview::extramatrixparse,
                 extendedit =>\&cmlview::editmatrixfull,
                 extendset=>\&cmlview::setmatrixfull,
        };
 	$ptype{PICTURE}={
                 name       =>encu('Картинка'),
                 editview   =>\&cmlview::editpicture,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };
        $ptype{VIDEO}={
                 name       =>encu('Видеоролик'),        	
                 editview   =>\&cmlview::editvideo,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };
        
        
 	$ptype{FILE}={
                 name       =>encu('Файл'),
                 editview   =>\&cmlview::editfile,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };

   $ptype{AUDIO}={
                 name       =>encu('Музыка'),
                 editview   =>\&cmlview::editfile,
                 setvalue   =>\&cmlview::setpicture,
                 extra      =>\&cmlview::emptysub,
                 extraparse =>\&cmlview::emptysub,
        };



	$ptype{FILELINK}={
                 name       =>encu('Ссылка на файл'),
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
