#!/usr/bin/perl

use strict;
use lib "../modules/";
use lib "../../../../perl/usr/lib/perl5/x86_64-linux-thread-multi";


use cmlview;
use cmlinstall;
use cmlmain;


use CGI  qw/:standard *Tr *table *td code/;
use CGI::Carp qw (fatalsToBrowser);

use Data::Dumper;
use Time::HiRes qw (time);
use POSIX qw(strftime);


use vars qw(%aliases);

my $ts_start=time();
warn "DBG: START: USER:$cmlcalc::ENV->{USER} URI:$ENV{'REQUEST_URI'}";

start('..');

$aliases{'root'}	= "$GLOBAL->{WWWPATH}/.htaccess";
$aliases{'vcms'}	= "$GLOBAL->{CGIPATH}/vcms/.htaccess";
$aliases{'admin'}	= "$GLOBAL->{CGIPATH}/admin/.htaccess";		
$aliases{'user'}	= "$GLOBAL->{CGIPATH}/user/.htaccess";
$aliases{'gate'}	= "$GLOBAL->{CGIPATH}/gate/.htaccess";



unlink ("$GLOBAL->{CGIPATH}/install.pl") if -e "$GLOBAL->{CGIPATH}/install.pl";

my $action=param('action');
my $need_exit;

if ($action) {
    if ($action eq 'remotesync') {
        print "Content-type: text/html\n\n";
        remote_sync(param('path'),param('type'),param('key'),param('value'));
        exit();
    }elsif ($action eq 'export') {
        my $dt=strftime ('%Y%m%d_%H%M',localtime());
        if (param('area') eq 'scripts') {
            print "Content-Disposition: attachment; filename=cgi-bin.$dt.tar.gz\n";
            print "Content-type: application/octet-stream\n\n";
            system("tar -cz -C $GLOBAL->{CGIPATH} -f - .");
        } elsif (param('area') eq 'docs'){
            print "Content-Disposition: attachment; filename=docs.$dt.tar.gz\n";
            print "Content-type: application/octet-stream\n\n";
            system(cmlmain::export_static_str('-'));
        } elsif (param('area') eq 'data'){
            print "Content-Disposition: attachment; filename=data.$dt.tar.gz\n";
            print "Content-type: application/octet-stream\n\n";
            system("tar -cz -C $GLOBAL->{FILEPATH} -f - . ");
        } elsif (param('area') eq 'db'){
            print "Content-Disposition: attachment; filename=db.$dt.gz\n";
            print "Content-type: application/octet-stream\n\n";
            my $str=cmlmain::export_db_str({charset=>param('charset')});
            system("$str | gzip -c");
        }
        exit;
    }
}

print header(-type=>'text/html', -charset=>$GLOBAL->{CODEPAGE});

$cmlcalc::ENV->{USER}=$ENV{REMOTE_USER} || '%vcms';
$cmlcalc::ENV->{USERID}=&cmlcalc::id("SU_$ENV{REMOTE_USER}");
$cmlcalc::ENV->{dev}=cookie('dev');
$cmlcalc::ENV->{SERVER}=$ENV{HTTP_HOST};
$cmlcalc::CGIPARAM->{_MODE}='CMLSRV';

if ($action) {
	if ($action eq 'installstruct') {
		install_structure();
	}
}	
	
unless (checkdatastruct()) {
	print "База данных пуста",br();
	print a({-href=>"?action=installstruct"},'Заполнить базу данных');
	viewlog();
	print "</body></html>";
	exit();
	
};

buildvparam();

my $id;
my $objid;

my $prm_id=param('objid') || '';
my $prm_key=param('objkey');
my $prm_uid=param('id');

if ($prm_id) { checkload({id=>$prm_id}) }
if ($prm_key) { 
	checkload({key=>$prm_key});
	$prm_id=cmlcalc::id(param('objkey')); 
}
if ($prm_id=~/^u(\d+)/) {
	undef $prm_id;
	$prm_uid=$1;
	$action='editform';
}


$id=$prm_uid;
$objid=$prm_id;

if (defined $objid && $objid eq '0') {buildlowtree($id)}
my $cf;
if ($action) {
	if (param('createmethod')) {createcmsmethod($id,param('createmethod'))}
	if (param('rebuildmethod')) {rebuildcmsmethod($id,param('rebuildmethod'))}
	if (param('deletemethod')) {deletecmsmethod($id,param('deletemethod'))}
	if ($action eq 'sync') {
		my $syncresult=&cmlmain::sync(
			param('target'),
			param('path'),
			param('type'),
			param('key'),
			param('id')
		);
		$action='editform'
	}
	if ($action eq 'clearcache') {
		clearcache();
		alert(encu('Кеш очищен'));
		$action='viewleft';
	}

    if ($action eq 'updatescripts') {
        my $addr='https://github.com/vjp/fcms/raw/master/vcms-cgi/cgi.tar.gz';
        `wget --no-check-certificate $addr`;
        if (-s 'cgi.tar.gz') {
            `tar -xzf cgi.tar.gz -C $GLOBAL->{CGIPATH}`;
            unlink "cgi.tar.gz";
            alert(encu('Скрипты обновлены'));
        } else {
            alert(encu("Проблема скачивания архива скриптов по адресу $addr"));
        }
        $action='viewleft';
	}


	
	if ($action eq 'addnewuser') {
	    	$action='viewusers';$cf=0;
	    	if (!param('password')) {alert (encu('Пароль не задан'))}
	    	elsif (param('password') ne param('retpassword')) {alert(encu('Пароль не совпадает'))}
				else {
					my ($uid,$err)=adduser(param('nusername'),param('password'),param('group'));
					if ($uid) {
						alert(encu('Пользователь добавлен'));
						$cf=1;
					} else {
						alert(encu("Ошибка создания пользователя: $err"));
					}		
				}	    	
	    }
	    if ($action eq 'deluser') {
	    	$action='viewusers';
	    	deluser(param('username'));
	    }
	    if ($action eq 'edituser') {
	    	$action='viewusers';
	    	unless (param('password') ne '') {
	    		edituser(param('username'),undef,param('group'));
	    		alert(encu('Данные изменены'));
	    	}
	    	elsif (param('password') ne param('retpassword')) {alert(encu('Пароль не совпадает'))}
				else {
					edituser(param('username'),param('password'),param('group'));
					alert(encu('Данные изменены'));
				}
	    }
	    
	 
     	for (keys %aliases) {
     		if ($action eq "rewriteht$_") {
     			createhtaccess($aliases{$_},param('accessmode'));
     			$action='viewusers';	
     		}
     	}


     	if ($action eq 'edit')     {
        	my $id=param('id');
        	my $ltmp=param('lowtempl');
        	my $nh;
        	if (defined param('name')) {   $nh=param('name') } 
        	else {	for (@LANGS) {if (param("name_$_")) { $nh->{$_}=param("name_$_")} 	}		}
        	my $nolog=param('nolog')?1:0;
          	edit ({id=>$id,
          	       name=>$nh,
          	       key=>param('key'),
          	       nolog=>$nolog,
          	       indx=>param('indx'),
          	       template=>param('template'),
          	       ltemplate=>param('ltemplate'),
          	       lang=>param('lang'),
          	       lowtemplate=>param('lowtempl'),
  	       	});
    		if (param('addprmkey')) {
          		if (param('addprmself')==2) {
          			addmethod({id=>$id,name=>param('addprmname'),key=>param('addprmkey')});
          		} elsif (param('addprmself')==3) {
          			addmethod({id=>$id,name=>param('addprmname'),key=>param('addprmkey'),lflag=>1});
          		}	else {	
            			addprm ({id=>$id,name=>param('addprmname'),key=>param('addprmkey'),type=>param('addprmtype'),self=>param('addprmself')})
            	}	
          	}
          	if (param('copyprmname')) {copyprm({id=>$id,key=>param('copyprmname')})}
          	if (param('copymethodname')) {copymethod({id=>$id,key=>param('copymethodname')})}
          	for (grep {/^lprm/ && param($_)} param() ) {
            	(my $pkey)=/^lprm(.+)$/;
                my $upd=param("prmupd$pkey");
                my $evl=param("prmevl$pkey");
                my $def=param("prmdef$pkey");
                editprm({
                	id=>$id,
                    pkey=>$pkey,
                    newname=>param("prmname$pkey"),
                    defval=>$def,
                    mode=>param("prmmode$pkey"),
                    upd=>$upd,
                    evl=>$evl,
                });
                &{$ptype{$prm->{$pkey}->{type}}->{extraparse}}({pkey=>$pkey});
            }
          	for (grep {/^mprm/ && param($_)} param() ) {
            	(my $pkey)=/^mprm(.+)$/;
                editmethod({id=>$id,pkey=>$pkey,name=>param("prmname$pkey")});
            }
          	for (grep {/^lmprm/ && param($_)} param() ) {
           		(my $pkey)=/^lmprm(.+)$/;
                editmethod({id=>$id,pkey=>$pkey,name=>param("prmname$pkey"),nflag=>1});
            }
          	for (grep {/^lnk/ && param($_)} param() ) {
                (my $pkey)=/^lnk(.+)$/;
                eval { &{$ptype{$prm->{$pkey}->{type}}->{setvalue}}({uid=>$id,pkey=>$pkey}) };
                if ($@) {print "ERROR $@"}
            }
          	$action='editform'
     	}

     	if ($action eq 'editprm') {
     		my $pkey=param('pname');
     		my $upd=param('prmupd');
     		my $evl=param('prmevl');
     		editprm({
     			pkey=>$pkey,
     		        mode=>2,
     		        id=>param('id'),
     		        newname=>param('prmname'),
                	defval=>param('prmdef'),
                 	upd=>$upd,
                 	evl=>$evl
     		});
        	setprmextra  ({pkey=>$pkey,extra=>'onchange',value=>param('onchange')});        
            setprmextra  ({pkey=>$pkey,extra=>'hasaccess',value=>param('hasaccess')});     
			&{$ptype{$prm->{$pkey}->{type}}->{extraparse}}({pkey=>$pkey});                         
     		$action='editprmform';
		}	
     	
		if ($action eq 'editlow')  { 
			my $nh;
    		if (defined param('name')) {   $nh=param('name') } 
  	    	else {	for (@LANGS) {$nh->{$_}=param("name_$_")} 	}		
			editlow ({
				id=>param('id'),
				key=>param('key'),
            	name=>$nh,
            	objid=>param('objid'),
            	template=>param('template'),
            	indx=>param('indx')
        	});
        	for (grep {/^lnk/ && param($_)} param() ) {
        		(my $pkey)=/^lnk(.+)$/;
            	eval { & {$ptype{$prm->{$pkey}->{type}}->{setvalue}}({id=>param('objid'),pkey=>$pkey}) };
            	if ($@) {print "ERROR $@"}
        	}
        	$action='editlowform';
   		}



     	if ($action eq 'setmatrix' )  	{ &{$ptype{$prm->{param('pkey')}->{type}}->{extendset}}();  $action='editmatrix' }
		if ($action eq 'setmethod')   	{ editmethod({id=>param('id'),pkey=>param('pname'),script=>param('script')});  $action='editmethod'; }
     	if ($action eq 'add')          	{ $id=addobject(param('id')); $action='editform' }
     	if ($action eq 'execmethod')   	{ &cmlcalc::execute({id=>param('uid'),method=>param('method')}); $action='editform' }
     	if ($action eq 'execlmethod')   { &cmlcalc::execute({id=>param('objid'),lmethod=>param('method')}); $action='editlowform' }
     	if ($action eq 'copy')     		{ copyobject({from=>param('id'),to=>param('to')}); 		  $action='viewtree'; }
     	if ($action eq 'copylow')   	{ copyobject({from=>param('objid'),to=>param('to')}); $action='viewlow' }
     	if ($action eq 'addlow')   		{ $objid=addlowobject(param('objid'),param('id')); $action='editlowform'; }
     	if ($action eq 'clearlow')   	{ deletealllowobjects(param('id'));  			$action='editform';	}
     	if ($action eq 'delete')   		{ deleteobject(param('id')); $action='viewtree';}
     	if ($action eq 'deletelow')		{ deletelowobject(param('objid'));$action='viewlow'}
     	if ($action eq 'deleteprm')     { deleteprm(param('id'),param('pname')); 	$action='editform'; }
     	if ($action eq 'deletemethod')  { deletemethod(param('id'),param('pname')); $action='editform'; }
     	if ($action eq 'deletelmethod') { deletemethod(param('id'),param('pname'),1);$action='editform';}

     	if ($action eq 'setmemo'   )  { 
     		my $objid=param('objid');
     		my $objuid=param('objuid');
     		my $pkey=param('pkey');
     		my $tabkey=param('tabkey');
     		my $tabpkey=param('tabpkey');
     		my $lang=param('lang');
     		&{$ptype{$prm->{$pkey}->{type}}->{extendset}}();
			meta_redirect("?action=editmemo&objid=$objid&objuid=$objuid&pkey=$pkey&tabkey=$tabkey&tabpkey=$tabpkey&lang=$lang");
			$need_exit=1;
     	} elsif  ($action eq 'editmemo'|| $action eq 'editmatrix') {
     		my $nprm=param('pkey');
     		my $oid=param('objid');
     		my $name="$lobj->{$oid}->{key} $lobj->{$oid}->{name} ";
 	   		print_top("O: $name $oid $nprm"); 
     		&{$ptype{$prm->{$nprm}->{type}}->{extendedit}}();  
			$need_exit=1; 
     	} elsif ($action eq 'setlmethod')   {   
			editmethod({id=>param('id'),pkey=>param('pname'),script=>param('script'),nflag=>1});  
			my $id=param('id');
			my $pname=param('pname');
			meta_redirect("?action=editlmethod&id=$id&pname=$pname");
			$need_exit=1;
		} elsif ($action eq 'editmethod')  {
			print_top('M: '.param('pname'));   
			editmethodform(param('id'),param('pname'));
			$need_exit=1;
		} elsif ($action eq 'editlmethod')  {
      		print_top('ML: '.param('pname'));
      		editmethodform(param('id'),param('pname'),1);
      		$need_exit=1;
      	} elsif ($action eq 'viewhistory') {
			viewhistoryform(param('objid'),param('prm'));
			$need_exit=1;
		} elsif ($action eq 'viewallhistory') {
			viewallhistoryform(param('objid'));
			$need_exit;
		} elsif ($action eq 'viewprm') {
			my $k=param('pkey');
			if ($cmlmain::prm->{$k}) {
        		viewprmform($k);
			} elsif ($cmlmain::lmethod->{$k} || $cmlmain::method->{$k}) {
				viewmethodform($k)
			}	
          	$need_exit=1;
     	} elsif ($action eq 'editprmform') {
        	editprmform(param('id'),param('pname'));
          	$need_exit=1;
     	} elsif ($action eq 'console') {
     		print_top('VCMSCONS');
     		console();
     		$need_exit=1;   
     	}
     
}

unless ($need_exit) {
	if ($action)  {
		print_top();
		if ($action eq 'config') 	{config()}
    	if ($action eq 'parsequery') {evaluate(param('script'));console(param('script'))} 
		if ($action eq 'viewlow')  { print "<hr>"; viewlow(param('id'),param('all')) }
  		if ($action eq 'editform')    { editform ($id)}
  		if ($action eq 'editlowform') { editlowform ($objid,$id)}
  		if ($action eq 'viewtree') {viewleft()}
  		if ($action eq 'viewusers') {viewusers()}
  		if ($action eq 'viewleft') {viewleft()}
  		print "</body></html>";
	} else {
		defaultform();
	}
}		
viewlog();


my $ts=time()-$ts_start;
warn sprintf("DBG: END: USER:$cmlcalc::ENV->{USER}  TIME:%.3f QUERY:$ENV{REQUEST_URI} \n",$ts);


######################################################
#   INTERFACE SUB
######################################################

sub viewusers {
	 my $ul=loaduserlist();
	 print encu("Список пользователей");
	 print start_table();
	 print Tr(th,th(encu('Логин')),th(encu('Группа')),th(encu('Новый пароль')),th(encu('Повторить пароль')),th());
	 for (@$ul) {
	 	print start_form(-action=>'');
	 	print Tr(	td(a({-href=>"?action=deluser&username=$_->{login}"},'X')),
	 						td($_->{login}),
	 				td(popup_menu(	-name=>'group',
	 								-default=>$_->{group},
	 								-override=>1,
	 								-values=>['','admin','user'],
	 								-labels=>{
	 										''=>encu('Не определена'),
	 										'admin'=>encu('Администраторы'),
	 										'user'=>encu('Пользователи')
	 								}
	 				)),		
	 	         	td(password_field({-name=>'password',override=>1})), 
	 	         	td(password_field({-name=>'retpassword',override=>1})),
	 	         	td (submit(-value=>encu('Изменить'))), 
	 	);
	 	print hidden(-name=>'action',-value=>'edituser',override=>1);
	 	print hidden(-name=>'username',-value=>$_->{login},override=>1);
	 	print end_form();
	 }
	 print start_form(-action=>'');
	 print Tr(	td,
	 						td(textfield({-name=>'nusername',override=>$cf})),
	 						td(popup_menu(	-name=>'group',
	 								-override=>1,
	 								-values=>['','admin','user'],
	 								-labels=>{
	 									''=>encu('Не определена'),
	 									'admin'=>encu('Администраторы'),
	 									'user'=>encu('Пользователи')
	 								}
	 						)),	
	 						td(password_field({-name=>'password',override=>1})),
	 						td(password_field({-name=>'retpassword',override=>1})),
	 						td (submit(-value=>encu('Создать нового'))) 
	);
	print hidden({-name=>'action',-value=>'addnewuser',-override=>1});
	print end_form;
	print end_table;

	
	print hr;

	print encu("Ограничение доступа через .htaccess"),br;		
   	print start_table;
   	print Tr(th(encu('Интерфейс')),th(encu('Доступ')),th(encu('Действие')));
   
   	for my $alias (keys %aliases) {
   		print start_Tr;
   		print start_form(-action=>'');
   		print th($alias);
   		my $df='';
   		if (-e $aliases{$alias}) {
   			my $buf;
   			open(HTFILE,"<$aliases{$alias}");
   	 		read(HTFILE,$buf,-s HTFILE);
   	 		close (HTFILE);
   	 		if ($buf=~/Require valid-user/s) {
   	 			$df='user'
   	 		} elsif ($buf=~/Require group/) {
   	 			$df='admin'
   	 		}
   	 	}
   		print td(popup_menu(	-name=>'accessmode',
   						-default=>$df,
	 					-override=>1,
	 					-values=>['','admin','user'],
	 					-labels=>{
	 						''=>encu('Открыт'),
	 						'admin'=>encu('Администраторы'),
	 						'user'=>encu('Администраторы и пользователи')
	 					}
	 	));
   		print td(submit(-value=>encu('Сохранить уровень доступа')));
 	  	print hidden({-name=>'action',-value=>"rewriteht$alias",-override=>1});
   		print end_form();
   		print end_Tr;
 
   	}
  
			
   print end_table;
   

}	


sub viewleft {
	viewtree(0,0,1);
	print br,a({-href=>'?action=viewusers',-target=>'mainbody'},encu('Пользователи и .htaccess'));
	print br,a({-href=>'?action=console',-target=>'_blank'},encu('Консоль'));
	print br,a({-href=>'?action=config',-target=>'mainbody'},encu('Конфигурация'));
	
	print br,a({-href=>'?action=clearcache'},encu('Очистить кеш'));
	
	print br,a({-href=>'?action=viewleft'},encu('Обновить'));
    print br,a({-href=>'https://github.com/vjp/fcms/wiki',-target=>'_blank'},encu('Документация'));	
    print br,a({-href=>'?action=updatescripts'},encu('Обновить скрипты'));
    
    
    
	
	print br,start_form(-method=>'post',-name=>'gotobj',-target=>'mainbody');
	print br,encu('Перейти к объекту');
	print br,encu(' по ID '),textfield(-name=>"objid",-size=>5,-override=>1);
	print encu(' или ключу '),textfield(-name=>"objkey",-size=>10,-override=>1);
	print submit(-value=>'>'); 
	print hidden(-name=>'action',value=>'editlowform',-override=>1);
	print endform;
	
	print br,start_form(-method=>'post',-name=>'gotoprm',-target=>'mainbody');
	print br,encu('Перейти к параметру'),textfield(-name=>"pkey",-size=>15,-override=>1);
	print submit(-value=>'>'); 
	print hidden(-name=>'action',value=>'viewprm',-override=>1);
	print endform;
	
}	

sub defaultform {
	print qq(
<html>
<head>
<link rel=stylesheet type=text/css href="/css/vcms.css">
</head>

<frameset cols="30%,*">
<frame src="/cgi-bin/vcms/cmlsrv.pl?action=viewleft" name="leftmenu">
<frame src="/cgi-bin/admin/admin.pl?mbframe=1" name="mainbody">
</frameset>
</html>
	);
}


sub viewlow
{
 my $id=$_[0];
 my $all=$_[1];
 
 print encu('Дерево объекта '),a({-href=>"?action=editform&id=$id"},b($obj->{$id}->{name})),br;
 print a({-href=>"?action=addlow&id=$id&objid=0"},'(+)');
 print a({-href=>"?action=clearlow&id=$id&objid=0",-onclick=>encu("return confirm('Подтвердите удаление объекта')")},'(X)');
 print br;
 if ($all) {
 	checkload({uid=>$id});
 	viewlowtree($id,0,0,'no')
 } else { 
 	checkload({uid=>$id,limit=>20});
 	viewlowtree($id,0,0,20) 
 }

}


sub viewtree
{
 my $root=$_[0];
 my $level=$_[1];
 my $isupper=$_[2];
 my $sep='&nbsp;'x($level);
 return unless $cmlmain::tree->{$root};
 for (sort {$obj->{$a}->{indx}<=>$obj->{$b}->{indx}} @{$cmlmain::tree->{$root}})
 {
   if ($_)
   {
   	my $name=$obj->{$_}->{name};
   	if ($obj->{$_}->{indx}!=$_) {$name="$obj->{$_}->{indx}. $name"}
   	if ($obj->{$_}->{key}) {$name.=" ($obj->{$_}->{key})"}
   	
    print "<nobr>$sep";
  
    print a({-href=>"?action=delete&id=$_",-class=>'ldel',-onclick=>encu("return confirm('Подтвердите удаление объекта')")},'(X)')  unless $isupper;
    
    print "<a href='?action=add&id=$_' class=ladd target=mainbody>(+)</a>";
    unless ($isupper) {print encu("<a href='#' onClick='var target=prompt(\"Скопировать в\",\"\");location.href=\"?action=copy&id=u$_&to=\"+target' class=ladd>(C)</a>")}
    print "<a href='?action=editform&id=$_' class=lmenu target=mainbody>($_)$name</a><br></nobr>";
    viewtree($_,$level+1);
    
    if ($isupper) {print br}
    
   }
 }
}





sub viewlowtree
{
 my $upobj=$_[0];
 my $root=$_[1];
 my $level=$_[2];
 my $limit=$_[3];

 my $sep='&nbsp;'x($level*3);
 return unless $ltree->{$upobj}->{$root};
 for (sort {$lobj->{$a}->{indx}<=>$lobj->{$b}->{indx}}  @{$ltree->{$upobj}->{$root}})
 {
   if (($limit eq 'no' || $limit>0) && $_)
   {
   	my $name=$lobj->{$_}->{name};
   	if ($lobj->{$_}->{indx}!=$lobj->{$_}->{id}) {$name="$lobj->{$_}->{indx}. $name"}
   	if ($lobj->{$_}->{key}) {$name.=" ($lobj->{$_}->{key})"}
   	$name=~s/\</&lt;/g;
   	$name=~s/\>/&gt;/g;
    print $sep,a({-href=>"?action=deletelow&objid=$_&id=$upobj"},'(X)'),
          a({-href=>"?action=addlow&objid=$_&id=$upobj"},'(+)'),
          a({-href=>"#", -onclick=>encu("var target=prompt(\"Скопировать в\",\"\");location.href=\"$ENV{SCRIPT_NAME}?action=copylow&id=$upobj&objid=$_&to=\"+target"), -class=>'ladd'},'(C)'),
          a({-href=>"?action=editlowform&objid=$_&id=$upobj"},"($_) $name"),br;
    if ($limit>0) {$limit--}      
    if ($limit ne 'no' && $limit == 0) {print a({-href=>"?action=viewlow&id=$upobj&all=1"},encu("Просмотреть все ...")),br;}
    viewlowtree($upobj,$_,$level+1,$limit);
   }
 }
}



sub editform
{
 	my $id=$_[0];
	print "<form method='post' name='mfrm' enctype='multipart/form-data'>";
 	print "<hr>";
 	print "<table>";
 	print Tr(th({-colspan=>7},encu('Изменение объекта ').b($obj->{$id}->{name})." ($id)"));
	my $tl=template_list();
 	my %lhash=%LANGS;
 	my @llist=('mul',@LANGS);

 
 
 
	if ($obj->{$id}->{lang} eq 'mul') { 
		for (@LANGS) {
			my $lang=$_;
			my $name=$obj->{$id}->{"name_$lang"};
			if ($name eq '') {$name=$name=$obj->{$id}->{name}}
		 	print Tr(td(),
		 			td(encu("Имя")."($LANGS{$lang})"),
		 			td({-colspan=>2},textfield(-name=>"name_$lang",-default=>$name,-override=>1,-size=>40)));
		}	
	} elsif ($obj->{$id}->{lang}) {
			my $lang=$obj->{$id}->{lang};
			my $name=$obj->{$id}->{"name_$lang"};
			if ($name eq '') {$name=$name=$obj->{$id}->{name}}
		 	print Tr(td(),
		 			td(encu("Имя ").$LANGS{$lang}),
		 			td({-colspan=>2},textfield(-name=>"name_$lang",-default=>$name,-override=>1,-size=>40)));
	} else {	
 			print Tr(td(),
 					td(encu("Имя")),td({-colspan=>2},textfield(-name=>'name',-default=>$obj->{$id}->{name},-override=>1,-size=>40)));
 	}				
 print Tr(td(),
          td(encu('Номер/Ключ')),
          td({-colspan=>2},
             textfield(-name=>'indx',-default=>$obj->{$id}->{indx},-override=>1,-size=>5),
             textfield(-name=>'key',-default=>$obj->{$id}->{key},-override=>1,-size=>20)
          ),
        );
 print Tr(td(),
 					td(encu('Язык')),td({-colspan=>2},
 					           popup_menu(-name=>'lang',-default=>$obj->{$id}->{lang},-override=>1,-values=>\@llist,-labels=>\%lhash))
 				);
        
 print Tr(td(),td(encu('Шаблон')),td({-colspan=>2},popup_menu(-name=>'template',-default=>$obj->{$id}->{template},-values=>$tl->{vals},-labels=>$tl->{lbls},-override=>1)));
 print Tr(td(),td(encu('Шаблон наследования')),td({-colspan=>2},popup_menu(-name=>'ltemplate',-default=>$obj->{$id}->{ltemplate},-values=>$tl->{vals},-labels=>$tl->{lbls},-override=>1)));
 print Tr(td(),td(encu('Установить у нижних объектов')),td({-colspan=>2},checkbox(-name=>'lowtempl',-value=>1,-checked=>0,-override=>1,-label=>'')));
 print Tr(td(),td(encu('Не хранить историю значений')),td({-colspan=>2},checkbox(-name=>'nolog',-value=>1,-checked=>$obj->{$id}->{nolog},-override=>1,-label=>'')));
 
               

#if ($obj->{$obj->{$id}->{up}}->{key} eq 'CONTENT' && $obj->{$id}->{key}) {
 	print start_Tr();
 	print start_td({-colspan=>4});
 	cmsmethod($id);
 	print end_td;
 	print end_Tr;
#}	
 
 #if ($obj->{$obj->{$id}->{up}}->{key} eq 'TEMPLATES' && $obj->{$id}->{key}) {
 #	print start_Tr();
 #	print start_td({-colspan=>4});
 #	cmsmethod($id);
 #	print end_td;
 #	print end_Tr;
 #}	
 
 

 print "<input type='hidden' name='id' value='$id'>";
 print "<input type='hidden' name='action' value='edit'>";
 my %oplist;
 if ($#{$obj->{$id}->{sprm}}>-1) {
 	print Tr(th({-colspan=>8},encu('Свои параметры'))); 
 	print encu(Tr(th(),th(' Имя '),th(' Ключ '),th(' Тип '),th(' Умолчание '),th(' Обн '),th(' Вып '),th(' Экстра ')));
 }
 buildlowtree($nobj->{MAINPRM}->{ind});
 
 for (@{$obj->{$id}->{sprm}})
 {

  if ($_)
  {
  	$oplist{$_}=1;
   print "<input type=hidden name='lprm$_' value=0>";
   print start_Tr();
   print td(
            a({-href=>"?action=deleteprm&id=$id&pname=$_"},'X'),
           );   
   print td(textfield(-name=>"prmname$_",-default=>$prm->{$_}->{name},-onchange=>"document.mfrm.lprm$_.value=1"));
   my $oid=$nobj->{"_PP_$_"}->{id};
   print td(a({-href=>"$ENV{SCRIPT_NAME}?action=editprmform&id=$id&pname=$_",-target=>'_blank'},$_),
            a({-href=>"$ENV{SCRIPT_NAME}?action=editlowform&id=$nobj->{MAINPRM}->{ind}&objid=$oid",-target=>'_blank'},'>>')
           );
   print td($ptype{$prm->{$_}->{type}}->{name});
   
   print start_td();
   my $defval=$prm->{$_}->{defval}->{$id} || '';
   if ($defval=~/\n/s) {
		print hidden(-name=>"prmmode$_",-default=>1,-override=>1);
   }	else {
   		print hidden(-name=>"prmmode$_",-default=>0,-override=>1);
		print textfield(-name=>"prmdef$_",
                   -default=>$prm->{$_}->{defval}->{$id},
                   -override=>1,
                   -maxlength=>255,
                   -onChange=>"document.mfrm.lprm$_.value=1");
   }                
   print "</td>";
   my $ss;
   if ($prm->{$_}->{upd}->{$id} eq 'y') {$ss='checked'} else {$ss=''}
   print "<td><input type='checkbox' name='prmupd$_' value='1' onclick='document.mfrm.lprm$_.value=1' $ss></td>";
   if ($prm->{$_}->{evaluate} eq 'y') {$ss='checked'} else {$ss=''}
   print "<td><input type='checkbox' name='prmevl$_' value='1' onclick='document.mfrm.lprm$_.value=1' $ss></td>";


   my $extra=&{$ptype{$prm->{$_}->{type}}->{extra}}({pkey=>$_,flag=>"lprm$_",form=>'mfrm',check=>1});
   
   if (ref $extra eq 'ARRAY') {
   	 print start_td(); 
   	 for (@$extra) {print "$_->[0] $_->[1]",br}
   	 print end_td();
   }else{ print td($extra)}	
   
   
   print"</tr>";
  }
 }
 if ($#{$obj->{$id}->{prm}}>-1) {
 	print Tr(th({-colspan=>8},encu('Параметры нижних объектов'))); 
  	print encu(Tr(th(),th(' Имя '),th(' Ключ '),th(' Тип '),th(' Умолчание '),th(' Обн '),th(' Вып '),th(' Экстра ')));
 }
 for (@{$obj->{$id}->{prm}})
 {
  if ($_)
  {
  	$oplist{$_}=1;
  	my $oid=$nobj->{"_PP_$_"}->{id};
   print "<input type=hidden name='lprm$_' value=0>";
   print "<tr>";
             
   print td(
      a({-href=>"?action=deleteprm&id=$id&pname=$_"},'X'),
   );  
   print td(textfield(-name=>"prmname$_",-default=>$prm->{$_}->{name},-onchange=>"document.mfrm.lprm$_.value=1"));
   print td(a({-href=>"$ENV{SCRIPT_NAME}?action=editprmform&id=$id&pname=$_",-target=>'_blank'},$_),
            a({-href=>"$ENV{SCRIPT_NAME}?action=editlowform&id=$nobj->{MAINPRM}->{ind}&objid=$oid",-target=>'_blank'},'>>')  
         );
   print "<td>$ptype{$prm->{$_}->{type}}->{name}</td>";
   print "<td>";
   
   if ($prm->{$_}->{defval}->{$id}=~/\n/s) {
	print hidden(-name=>"prmmode$_",-default=>1,override=>1);
   }	else {
   	print hidden(-name=>"prmmode$_",-default=>0,override=>1);
	print textfield(-name=>"prmdef$_",
                   -default=>$prm->{$_}->{defval}->{$id},
                   -override=>1,
                   -maxlength=>255,
                   -onChange=>"document.mfrm.lprm$_.value=1");
   }                
   print "</td>";
	my $ss;
   if ($prm->{$_}->{upd}->{$id} eq 'y') {$ss='checked'} else {$ss=''}
   print "<td><input type='checkbox' name='prmupd$_' value='1' onclick='document.mfrm.lprm$_.value=1' $ss></td>";
   if ($prm->{$_}->{evaluate} eq 'y') {$ss='checked'} else {$ss=''}
   print "<td><input type='checkbox' name='prmevl$_' value='1' onclick='document.mfrm.lprm$_.value=1' $ss></td>";


   my $extra=&{$ptype{$prm->{$_}->{type}}->{extra}}({pkey=>$_,flag=>"lprm$_",form=>'mfrm',check=>1});
   if (ref $extra eq 'ARRAY') {
   	 print start_td(); 
   	 for (@$extra) {print "$_->[0] $_->[1]",br}
   	 print end_td();
   }else{ print td($extra)}	

   
   print"</tr>";
  }
 }
 
 for (paramlist($objid))
 {
   if ($_)
   { 	
    my $vstr;
    eval { $vstr=&{$ptype{$prm->{$_}->{type}}->{editview}}({id=>$objid,pkey=>$_,flag=>"lnk$_",form=>'frm'}) };
    if ($@) {$vstr="ERROR: $@"}
    print "<input type=hidden name='lnk$_' value=0>\n";
    print "<tr><td>$prm->{$_}->{name}</td><td>$_ ($ptype{$prm->{$_}->{type}}->{name})</td><td>$vstr</td></tr>\n";
   } 
 }
 
 
 
 if ($obj->{$id}->{method}) {
 	print Tr(th({-colspan=>7},encu('Методы')));
  	print encu(Tr(th(),th('Имя'),th('Ключ'),th('Экстра'),th('Экспорт')));
 }
 
 my %mtlist;
 
 for my $mname (sort keys %{$obj->{$id}->{method}})  {
 	$mtlist{$mname}=1;
   	print "<input type=hidden name='mprm$mname' value=0>";
   	print start_Tr();
   	print td(a({-href=>"$ENV{SCRIPT_NAME}?action=deletemethod&id=$id&pname=$mname"},'X'));
   	print td("<input name='prmname$mname' value='$obj->{$id}->{method}->{$mname}->{name}' onchange='document.mfrm.mprm$mname.value=1'>");
   	print td($mname);
   	print td(a({-href=>"$ENV{SCRIPT_NAME}?action=editmethod&id=$id&pname=$mname",-target=>'_blank'},encu('Редактировать')));
   	print start_td();
	my $path=join('/',map {$_=$obj->{$_}->{key}} reverse treelist($id));
   	print a({-href=>"?action=sync&type=method&key=$mname&id=$id&path=$path&target=$_"},$_),'&nbsp;' for @SYNC;
   	print end_td();
   	print end_Tr();

 }
 

	if ($obj->{$id}->{lmethod}) {
		print Tr(th({-colspan=>7},encu('Методы нижних объектов')));
  		print encu(Tr(th(),th('Имя'),th('Ключ'),th('Экстра')));
	}
 
 my %lmtlist;
 
 	for (sort keys %{$obj->{$id}->{lmethod}})  {
 		$lmtlist{$_}=1;
   		print "<input type=hidden name='lmprm$_' value=0>";
   		print "<tr><td><a href='$ENV{SCRIPT_NAME}?action=deletelmethod&id=$id&pname=$_'>X</a></td>";
   		print td("<input name='prmname$_' value='$obj->{$id}->{lmethod}->{$_}->{name}' onchange='document.mfrm.lmprm$_.value=1'>");
   		print td($_);
   		print td(a({-href=>"$ENV{SCRIPT_NAME}?action=editlmethod&id=$id&pname=$_",-target=>'_blank'},encu('Редактировать')));
   		print"</tr>";
 	}

	print Tr(th({-colspan=>7},encu('Добавить параметр')));
	print encu(Tr(th(),th('Имя'),th('Ключ'),th('Тип')));
 
	print "<tr><td></td><td><input name=addprmname></td><td><input name=addprmkey></td>";
 	print "<td><select name=addprmtype>";
 	for (@ptypes) {print "<option value='$_'>$ptype{$_}->{name}</option>"}
 	print "</select></td>\n";
 
 	print start_td({-colspan=>5});


 	print radio_group(-name=>'addprmself',
                   -values=>[0,1,2,3],
                   -default=>0,
                   -labels=>{0=>encu('Для нижних'),1=>encu('Свой'),2=>encu('Метод'),3=>encu('Н.метод')}
                   );
 	print end_td();
 	print end_Tr();

 	print start_Tr();
  	print td(),td(encu('Копировать параметр')),start_td({-colspan=>7});
 	my @plist;
 	push(@plist,grep { !$oplist{$_} && $_!~/^_/} sort keys %$prm);
 	my %nlist;
 	$nlist{0}=encu('Выберите параметр');
 	for (@plist) {$nlist{$_}="$prm->{$_}->{name} ($_)"}
 	@plist=(0,@plist);
 	print popup_menu(-name=>'copyprmname',-values=>\@plist, -labels=>\%nlist, -override=>1);
 	print end_td();
 	print end_Tr();

 
 
 	my @mlist;
 	print start_Tr();
  	print td(),td(encu('Копировать метод')),start_td({-colspan=>7});
 	push(@mlist,grep { !$mtlist{$_} } sort keys %$method);
 	my %mnlist;
 	$mnlist{0}=encu('Выберите метод');
 	for (@mlist) {$mnlist{$_}="$method->{$_}->{name} ($_)"}
 	@mlist=(0,@mlist);
 	print popup_menu(-name=>'copymethodname',-values=>\@mlist, -labels=>\%mnlist, -override=>1);
 	print end_td();
 	print end_Tr();

 
 	print end_table();
  	print hr;
  	
  	print start_table();
 	print Tr(th({-colspan=>3},encu('Исправить значения ')."$obj->{$id}->{name} ($id)"));
    print encu(Tr(th('Имя'),th('Параметр'),th('Значение')));
 	for (uparamlist($id)){
   		if ($_){ 	 
    		my $vstr;
    		eval { $vstr=&{$ptype{$prm->{$_}->{type}}->{editview}}({uid=>$id,pkey=>$_,flag=>"lnk$_",form=>'mfrm'}) };
    		if ($@) {$vstr="ERROR: $@"}
    		print "<input type=hidden name='lnk$_' value=0>\n";
    		print "<tr><td>$prm->{$_}->{name}</td><td>$_ ($ptype{$prm->{$_}->{type}}->{name})</td><td>$vstr</td></tr>\n";
   		} 
 	}
 
 	for (umethodlist($id)) {
 		print start_Tr;
 	  	print td($method->{$_}->{name});
 	  	print td($_);
 	  	print td(a({-href=>"?action=execmethod&id=$id&method=$_&uid=u$id"},encu('Выполнить')));
 	  	print end_Tr();
 	}
 
 	print end_table();
 	print submit(-value=>encu('Зафиксировать изменения'));
 	print end_form();
 	viewlow($id);

}




sub editlowform
{
 	my $objid=$_[0];
 	my $id=$lobj->{$objid}->{upobj};
 	print hr;
	my $tl=template_list();
 
 	print "\n<form method='post' name='frm' enctype='multipart/form-data'>\n";
 	print start_table();
 	print Tr(
 		th({-colspan=>2},encu('Объект:')." $lobj->{$objid}->{name} ($objid)"),
 		th(a({-href=>"?action=deletelow&objid=$objid&id=$id",-onclick=>encu("confirm('Подтвердите удаление объекта')")},encu('Удалить')))
 	);


	if ($obj->{$id}->{lang} eq 'mul') { 
		for (@LANGS) {
			my $lang=$_;
			my $name=$lobj->{$objid}->{"name_$lang"};
			if ($name eq '') {$name=$name=$lobj->{$objid}->{name}}
		 	print Tr(
		 			td(encu("Имя")."($LANGS{$lang})"),
		 			td(textfield(-name=>"name_$lang",-default=>$name,-override=>1,-size=>40))
		 	);
		}	
	} else {	
 			print Tr(th(encu('Имя')),
 				td(textfield(-name=>'name',-default=>$lobj->{$objid}->{name},-override=>1,-size=>60)),
 				td(a({-href=>"?action=viewallhistory&objid=$objid",-target=>'_blank'},encu('История')))
 			); 	
 	}				




 	print Tr(th(encu('Номер/Ключ')),
          td({-colspan=>2},
          		textfield(-name=>'indx',-default=>$lobj->{$objid}->{indx},-override=>1,-size=>5),
              textfield(-name=>'key',-default=>$lobj->{$objid}->{key},-override=>1),
              ));
 	print Tr(th(encu('Шаблон')),td({-colspan=>2},popup_menu(-name=>'template',-default=>$lobj->{$objid}->{template},-values=>$tl->{vals},-labels=>$tl->{lbls},-override=>1)));
 	print Tr(th(encu('Язык')),td({-colspan=>2},$LANGS{$lobj->{$objid}->{lang}}));

 	print "<input type='hidden' name='id' value='$id'>\n";
 	print "<input type='hidden' name='objid' value='$objid'>\n";
 	print "<input type='hidden' name='action' value='editlow'>\n";
 	print Tr(th({-colspan=>3},encu('Значения')));
 	print encu(Tr(th('Имя'),th('Ключ'),th('Значение'),th('Время')));
 	for (paramlist($objid)) {
   		if ($_) { 	
    		my $vstr;
    		my $tstr=time();
    		eval { $vstr=&{$ptype{$prm->{$_}->{type}}->{editview}}({id=>$objid,pkey=>$_,flag=>"lnk$_",form=>'frm',lang=>$lobj->{$objid}->{lang}}) };
    		if ($@) {$vstr="ERROR: $@"}
       		my $fixv=0;
    		if ($prm->{$_}->{extra}->{fix} eq 'y') {$fixv=1}
    		print "<input type=hidden name='lnk$_' value='$fixv'>\n";
    		print Tr(td($prm->{$_}->{name}),td("$_ ($ptype{$prm->{$_}->{type}}->{name})"),td($vstr),td(sprintf("%.3f",time()-$tstr)))."\n";
   		} 
 	}
 
  	for (methodlist($objid)) {
 		print start_Tr;
 	  	print td($lmethod->{$_}->{name});
 	  	print td($_);
 	  	print td(a({-href=>"?action=execlmethod&objid=$objid&id=$id&method=$_"},encu('Выполнить')));
 	  	print end_Tr();
 	}

 
 	print Tr(td({-colspan=>3},submit(-value=>encu('Редактировать'))));

 	print "</table>\n";
 	print "</form>\n";
 	print hr;
 	viewlow($id);
}






sub cmsmethod {
	my $id=$_[0];
	my $key=$obj->{$id}->{key};
	my $cmsmtd=loadcmsmethod($id);
	

	
	print start_table();
	
	print start_Tr();
   	print td(encu('Шаблон формы ввода параметров объекта'));
	unless($cmsmtd->{edittemplate}) {print td(a({-href=>"?action=editform&id=$id&createmethod=edittemplate"},encu('Создать шаблон')))}
	else {
			checkload({key=>$cmsmtd->{edittemplate}});
			my $objid=$nobj->{$cmsmtd->{edittemplate}}->{id};
			print td(a({-href=>"?action=editmemo&objid=$objid&pkey=PAGETEMPLATE",-target=>'_blank'},encu('Исправить шаблон'))),
			td(a({-href=>"?action=editform&id=$id&rebuildmethod=edittemplate"},encu('Пересоздать шаблон'))),
			td(a({-href=>"?action=editform&id=$id&deletemethod=edittemplate"},encu('Удалить шаблон')))
	}
	print end_Tr();

  	print start_Tr();
   	print td(encu('Шаблон формы ввода параметров списка объектов'));
	unless($cmsmtd->{listedittemplate}) {print td(a({-href=>"?action=editform&id=$id&createmethod=listedittemplate"},encu('Создать шаблон')))}
	else {
			checkload({key=>$cmsmtd->{listedittemplate}});
			my $objid=$nobj->{$cmsmtd->{listedittemplate}}->{id};
			print td(a({-href=>"?action=editmemo&objid=$objid&pkey=PAGETEMPLATE",-target=>'_blank'},encu('Исправить шаблон'))),
			td(a({-href=>"?action=editform&id=$id&rebuildmethod=listedittemplate"},encu('Пересоздать шаблон'))),
			td(a({-href=>"?action=editform&id=$id&deletemethod=listedittemplate"},encu('Удалить шаблон')))
	}
	print end_Tr();


  	print start_Tr();
   	print td(encu('Шаблон меню списка объектов'));
	unless($cmsmtd->{listmenutemplate}) {print td(a({-href=>"?action=editform&id=$id&createmethod=listmenutemplate"},encu('Создать шаблон')))}
	else {
			checkload({key=>$cmsmtd->{listmenuttemplate}});
			my $objid=$nobj->{$cmsmtd->{listmenutemplate}}->{id};
			print td(a({-href=>"?action=editmemo&objid=$objid&pkey=PAGETEMPLATE",-target=>'_blank'},encu('Исправить шаблон'))),
			td(a({-href=>"?action=editform&id=$id&rebuildmethod=listmenutemplate"},encu('Пересоздать шаблон'))),
			td(a({-href=>"?action=editform&id=$id&deletemethod=listmenutemplate"},encu('Удалить шаблон')))
	}
	print end_Tr();


	print end_table();
}



sub evaluate {
	print "Выполнение скрипта <hr>"; 
	my ($output,$error)=&cmlcalc::scripteval($_[0]);
	if ($error) {print "Ошибка выполнения скрипта: <b>$error</b> <hr> Исходный текст: <br> $_[0]"}
	else {print $output,hr,encu('Выполнено без ошибок')}
	print hr;
}


sub template_list 
{
	my $tl;	
 	my $v=&cmlcalc::calc($nobj->{TEMPLATES},'lowlevel()');	
 	my @tkeys=('0',split(';',$v));
 	my @tvals=map { $obj->{$_}->{ind} } @tkeys;
 	$tvals[0]=0;
 	my $tlbls;
 	for (@tvals) { $tlbls->{$_}=$_?"$obj->{$_}->{name} ($obj->{$_}->{key})":encu('Не определен') } 

 
 	$tl->{vals}=\@tvals;
 	$tl->{lbls}=$tlbls;
 
 	return $tl;
}	


sub method_list {
	
 my $tl;	

 my $tlbls;
 my @tvals=('');
 push (@tvals,sort keys %$method);
 for (@tvals) { $tlbls->{$_}="$method->{$_}->{name} ($_)" } 
 $tlbls->{''}=encu('Не определен');
 
 $tl->{vals}=\@tvals;
 $tl->{lbls}=$tlbls;
 
 return $tl;
}	





sub meta_redirect {
		print "<META HTTP-EQUIV='Refresh' CONTENT='2; URL=$_[0]'/>Подождите, сохраняем...";
}				
