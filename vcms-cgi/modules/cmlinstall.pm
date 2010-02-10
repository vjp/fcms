package cmlinstall;

# $Id: cmlinstall.pm,v 1.20 2010-02-10 06:58:50 vano Exp $

BEGIN
{
 use Exporter();
 use cmlmain;
 use Cwd;
 @ISA    = 'Exporter';
 @EXPORT = qw(&install_structure &install_mce &install_db);
}
sub install_cron ($){
	my $period= shift || 15;
	my $path=cwd();
	system('crontab -r');
	system("echo '$period * * * * $path/autorun.pl' | crontab -");
}

sub install_structure {
	
addobject({forced=>1,up=>0,key=>'CONTENT',name=>'Содержимое сайта'});
addprm({objkey=>'CONTENT',name=>'Сайт открыт',type=>'FLAG',key=>'OPENSITE',evl=>'n',self=>1});
addprm({objkey=>'CONTENT',name=>'Картинки',type=>'LIST',key=>'PICLINKS',upd=>'n',defval=>'backref(id(GALLERY),PICLINK)'});
addprm({objkey=>'CONTENT',name=>'Первая картинка',type=>'LIST',key=>'FIRSTPIC',upd=>'n',defval=>'my @v=split(/;/,p(PICLINKS));$v[0]'});
addprm({objkey=>'CONTENT',name=>'Картинки для верхних объектов',type=>'LIST',key=>'UPICLINKS',upd=>'n',defval=>'ubackref(id(GALLERY),PICLINK)'});
addprm({objkey=>'CONTENT',name=>'Файлы',type=>'LIST',key=>'FILELINKS',upd=>'n',defval=>'backref(id(FILEARCHIVE),FILELINK)'});
addprm({objkey=>'CONTENT',name=>'Файлы для верхних объектов',type=>'LIST',key=>'UFILELINKS',upd=>'n',defval=>'ubackref(id(FILEARCHIVE),FILELINK)'});
addprm({objkey=>'CONTENT',name=>'Ролики',type=>'LIST',key=>'VIDLINKS',upd=>'n',defval=>'backref(id(VIDEOGALLERY),VIDLINK)'});
addprm({objkey=>'CONTENT',name=>'Первый ролик',type=>'LIST',key=>'FIRSTVIDEO',upd=>'n',defval=>'my @v=split(/;/,p(VIDLINKS));$v[0]'});
addprm({objkey=>'CONTENT',name=>'Ролики для верхних объектов',type=>'LIST',key=>'UVIDLINKS',upd=>'n',defval=>'ubackref(id(VIDEOGALLERY),VIDLINK)'});



addobject({upkey=>'CONTENT',key=>'GALLERY',name=>'Фотогалерея'});
addprm({objkey=>'GALLERY',name=>'Картинка',type=>'PICTURE',key=>'PIC',evl=>'n'});
addprm({objkey=>'GALLERY',name=>'Ссылка на раздел',type=>'LIST',key=>'PICLINK',evl=>'n'});
addprm({objkey=>'GALLERY',name=>'Следующая картинка',type=>'LIST',key=>'NEXTPIC',upd=>'n',defval=>qq(
my @v=reverse split(/;/,p(PICLINKS,p(PICLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});
addprm({objkey=>'GALLERY',name=>'Предыдущая картинка',type=>'LIST',key=>'PREVPIC',upd=>'n',defval=>qq(
my @v=split(/;/,p(PICLINKS,p(PICLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});




addobject({upkey=>'CONTENT',key=>'VIDEOGALLERY',name=>'Видеогалерея'});
addprm({objkey=>'VIDEOGALLERY',name=>'Ролик',type=>'VIDEO',key=>'MOVIE',evl=>'n'});
addprm({objkey=>'VIDEOGALLERY',name=>'Ссылка на раздел',type=>'LIST',key=>'VIDLINK',evl=>'n'});
addprm({objkey=>'VIDEOGALLERY',name=>'Картинка',type=>'PICTURE',key=>'PIC',evl=>'n'});
addprm({objkey=>'VIDEOGALLERY',name=>'Следующий ролик',type=>'LIST',key=>'NEXTVIDEO',upd=>'n',defval=>qq(
my @v=reverse split(/;/,p(VIDLINKS,p(VIDLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});
addprm({objkey=>'VIDEOGALLERY',name=>'Предыдущий ролик',type=>'LIST',key=>'PREVVIDEO',upd=>'n',defval=>qq(
my @v=split(/;/,p(VIDLINKS,p(VIDLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});




addobject({upkey=>'CONTENT',key=>'FILEARCHIVE',name=>'Файловый архив'});
addprm({objkey=>'FILEARCHIVE',name=>'Файл',type=>'FILE',key=>'ARCHIVEFILE',evl=>'n'});
addprm({objkey=>'FILEARCHIVE',name=>'Ссылка на раздел',type=>'LIST',key=>'FILELINK',evl=>'n'});
addprm({objkey=>'FILEARCHIVE',name=>'Описание файла',type=>'TEXT',key=>'ARCHIVEFILEDESCR',evl=>'n'});
setprmextra({pkey=>'ARCHIVEFILEDESCR',extra=>'rows',value=>'3'});
setprmextra({pkey=>'ARCHIVEFILEDESCR',extra=>'cols',value=>'50'});



addobject({forced=>1,up=>0,key=>'DESIGN',name=>'Дизайн сайта'});
addprm({objkey=>'DESIGN',name=>'Картинки',type=>'LIST',key=>'PICLINKS',upd=>'n',defval=>'backref(id(GALLERY),PICLINK)'});
addprm({objkey=>'DESIGN',name=>'Файлы',type=>'LIST',key=>'FILELINKS',upd=>'n',defval=>'backref(id(FILEARCHIVE),FILELINK)'});
addprm({objkey=>'DESIGN',name=>'Заголовок',type=>'TEXT',key=>'TITLE',defval=>'$CGIPARAM->{1}?p(_NAME,$CGIPARAM->{1}):p(_NAME)'});



addprm({objkey=>'DESIGN',name=>'Шаблон',type=>'LONGTEXT',key=>'PAGETEMPLATE',evl=>'n'});
addprm({objkey=>'DESIGN',name=>'Заголовок',type=>'TEXT',key=>'TITLE'});
setprmextra({pkey=>'PAGETEMPLATE',extra=>'parse',value=>'y'});

addobject({forced=>1,upkey=>'DESIGN',key=>'INCLUDES',name=>'Вставки'});
addlowobject({upobjkey=>'INCLUDES',key=>'SITEHEADER',name=>'Шапка'});
addlowobject({upobjkey=>'INCLUDES',key=>'SITEFOOTER',name=>'Подвал'});
setvalue({key=>'SITEHEADER',pkey=>'PAGETEMPLATE',value=>qq(
<html>
<head>

<title>
</title>

<link rel="stylesheet" href="/css/mce.css" type="text/css" />

<script type="text/javascript" src="/js/base.js"></script>
<script type="text/javascript" src="/js/swfobject.js"></script>

</head>
<body>
DEFAULT HEADER
<hr/>
)});
setvalue({key=>'SITEFOOTER',pkey=>'PAGETEMPLATE',value=>qq(
<hr/>DEFAULT FOOTER
</body>
</html>
)});

addlowobject({upobjkey=>'DESIGN',key=>'MAINTEMPLATE',name=>'Базовый шаблон'});
setvalue({key=>'MAINTEMPLATE',pkey=>'PAGETEMPLATE',value=>qq(
	<cml:include key="SITEHEADER"/> <cml:include name="_prm:view_"/> <cml:include key="SITEFOOTER"/>
)});
addlowobject({upobjkey=>'DESIGN',key=>'UNDERCONSTRUCT',name=>'Заглушка'});
setvalue({key=>'UNDERCONSTRUCT',pkey=>'PAGETEMPLATE',value=>'Under construction...'});




addobject({forced=>1,up=>0,key=>'CMSDESIGN',name=>'Дизайн интерфейса администрирования'});
addobject({forced=>1,up=>0,key=>'TEMPLATES',name=>'Шаблоны'});
addobject({forced=>1,up=>0,key=>'RESTRICTIONS',name=>'Ограничения доступа'});
addobject({forced=>1,up=>0,key=>'MAINPRM',name=>'Параметры'});

addobject({forced=>1,up=>0,key=>'AUTOMATE',name=>'Автозапуск'});
addprm({objkey=>'AUTOMATE',name=>'Флаг активности',type=>'FLAG',key=>'AUTOLOCK',evl=>'n',self=>1});
addprm({objkey=>'AUTOMATE',name=>'Время последнего запуска',type=>'DATE',key=>'AUTOLOCKTIME',evl=>'n',self=>1});
setprmextra({pkey=>'AUTOLOCKTIME',extra=>'format',value=>'%d.%m.%Y %H:%M'});
addprm({objkey=>'AUTOMATE',name=>'Максимальный период',type=>'NUMBER',key=>'AUTOLOCKPERIOD',evl=>'n',self=>1});
addmethod ({objkey=>'AUTOMATE',key=>'AUTOSCRIPT',name=>'Скрипт автозапуска',script=>qq(message ("AUTOSCRIPT STARTED : ".scalar localtime);)});



addobject({forced=>1,upkey=>'AUTOMATE',key=>'AUTOLOGS',name=>'Логи автозапуска'});
addprm({objkey=>'AUTOLOGS',name=>'Время запуска',type=>'DATE',key=>'EXECDATE',evl=>'n',upd=>'n'});
addprm({objkey=>'AUTOLOGS',name=>'Лог',type=>'LONGTEXT',key=>'LOGBODY',evl=>'n',upd=>'n'});



addobject({upkey=>'RESTRICTIONS',key=>'SYSTEMUSERS',name=>'Пользователи системы'});







addlowobject({upobjkey=>'DESIGN',key=>'STARTPAGE',name=>'Стартовая страница'});
setvalue({key=>'STARTPAGE',pkey=>'PAGETEMPLATE',value=>'Here is startpage'});
addlowobject({upobjkey=>'DESIGN',key=>'ERRORPAGE',name=>'Cтраница ошибки'});
setvalue({key=>'ERRORPAGE',pkey=>'PAGETEMPLATE',value=>'Here is errorpage'});

copyprm({objkey=>'CMSDESIGN',key=>'PAGETEMPLATE'});
copyprm({objkey=>'CMSDESIGN',key=>'TITLE'});


addobject({upkey=>'CMSDESIGN',key=>'CMSMENU',name=>'Шаблоны меню'});
addobject({upkey=>'CMSDESIGN',key=>'CMSFORM',name=>'Шаблоны форм'});
addobject({upkey=>'CMSDESIGN',key=>'BASECMS',name=>'Базовые шаблоны'});




addlowobject({upobjkey=>'CMSFORM', key=>'MAINCMSTEMPL', name=>'Главный шаблон интерфейса'});
setvalue({key=>'MAINCMSTEMPL',pkey=>'PAGETEMPLATE',value=>qq(

<html>
<head>

<TITLE>VCMS</TITLE>


<link rel=stylesheet type=text/css href="/css/admin.css">
</head>

<frameset cols="30%,*" SCROLLING=YES BORDERCOLOR="#770000">
<frame src="/cgi-bin/admin/admin.pl?menu=CMSMAINMENU" name='adminlm' SCROLLING=YES BORDERCOLOR="#770000">
<frame src="/admin/splash.htm" name='adminmb' SCROLLING=YES BORDERCOLOR="#770000">
</frameset>

</html>


)});


addlowobject({upobjkey=>'CMSFORM', key=>'USERCMSTEMPL', name=>'Главный шаблон дополнительного интерфейса'});
setvalue({key=>'USERCMSTEMPL',pkey=>'PAGETEMPLATE',value=>qq(

<html>
<head>

<TITLE>VCMS</TITLE>


<link rel=stylesheet type=text/css href="/css/admin.css">
</head>

<frameset cols="30%,*" SCROLLING=YES BORDERCOLOR="#770000">
<frame src="/cgi-bin/user/user.pl?menu=USERMAINMENU" name='adminlm' SCROLLING=YES BORDERCOLOR="#770000">
<frame src="/user/splash.htm" name='adminmb' SCROLLING=YES BORDERCOLOR="#770000">
</frameset>

</html>


)});


addlowobject({upobjkey=>'BASECMS',key=>'BASELIST',name=>'Базовый шаблон списка'});
setvalue({key=>'BASELIST',pkey=>'PAGETEMPLATE',value=>"
	<cml:list ukey='_prm:ukey_' expr='lowlist()'>
  <cml:a href='?view=BASELIST&ukey=_prm:ukey_&parsemethod=BASEDELMETHOD&id=_cml:_ID_'><cml:img src='_cml:_delimg_' alt=DELETE border='0'/></cml:a>
  <cml:a href='?view=EDIT__prm:ukey_&id=_cml:_ID_' target='adminmb'><cml:text param='_NAME'/></cml:a><br>
  </cml:list>
  <hr/>
  <cml:actionlink action='add'>Добавить новый</cml:actionlink>
  <hr/>
  <cml:a href='?menu=BASELIST&ukey=_CML:_KEY_'>Обновить</cml:a>		
"});


addlowobject({upobjkey=>'BASECMS',key=>'BASEEDIT',name=>'Базовый шаблон объекта'});
setvalue({key=>'BASEEDIT',pkey=>'PAGETEMPLATE',value=>"
  <cml:use id='_prm:id_'>
  <cml:form parser='BASELPARSER'>
      <table>
          <tr><td>Наименование: </td><td><cml:inputtext param='_NAME'/></td></tr>
          <tr><td>Номер: </td><td><cml:inputtext param='_INDEX'/></td></tr>
          <tr><td colspan=2><input type=submit value='Зафиксировать изменения'></td></tr>
      </table>
  </cml:form>
  </cml:use>
"});

addlowobject({upobjkey=>'BASECMS',key=>'BASEMENU',name=>'Базовый шаблон меню'});
setvalue({key=>'BASEMENU',pkey=>'PAGETEMPLATE',value=>"
<CML:INCLUDE name='BASEMENUHEADER'/>
<CML:INCLUDE name='_prm:menu_'/>
<CML:INCLUDE name='BASEMENUFOOTER'/>
"});



addlowobject({upobjkey=>'CMSMENU',key=>'USERMENU',name=>'Шаблон меню'});
setvalue({key=>'USERMENU',pkey=>'PAGETEMPLATE',value=>"<CML:INCLUDE name='BASEMENU'/>"});

addlowobject({upobjkey=>'CMSMENU',key=>'USERMAINMENU',name=>'Главное меню пользовательсокго интерфейса'});
setvalue({key=>'USERMAINMENU',pkey=>'PAGETEMPLATE',value=>"... главное меню здесь ..."});



addlowobject({upobjkey=>'BASECMS',key=>'BASEMENUHEADER',name=>'Базовый шаблон заголовка меню'});
setvalue({key=>'BASEMENUHEADER',pkey=>'PAGETEMPLATE',value=>qq(
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">
<style type=text/css>
<!--
td, body				{font-family: Tahoma,  Arial; font-size: 11px; color: #000000;}
body					{scrollbar-base-color: #000066; scrollbar-arrow-color: #ffffff; scrollbar-highlight-color: #FFFFFF; scrollbar-shadow-color: #FFFFFF; scrollbar-face-color: #909090; scrollbar-track-color: #f0f0f0; }
a:,a:link, a:visited			{font-family: Tahoma, sans-serif; font-size: 11px; color: #1E609C; text-decoration: underline;}
a:active, a:hover			{font-family: Tahoma, sans-serif; font-size: 11px; color: #9C1E1E; text-decoration: none;}
hr			{border: 0; width: 100%; color: #770000; background-color: #D96926; height: 2px;}
li			{font-family: "Lucida Console", monospace; font-size: 11px; font-weight : bold; list-style : square;}
ul			{font-family: Verdana, Arial, Helvetica, sans-serif; list-style: square; margin-bottom : 0; margin-top : 0;}
input, select		{font-family: Verdana, Arial, sans-serif; font-size: 12px; font-weight : bold;}
small, .small				{font-family: Tahoma, sans-serif; font-size: 9px; color: #565B64; font-weight : normal;}
h1, h2, h3, h4, h5, h6			{font-family: Trebuchet MS, Tahoma, sans-serif; font-size: 18px; color: #00458B; font-weight : bold;}
-->
</style>

<script language="javascript" type="text/javascript" src="/js/base.js"></script>

</head>
<body bgcolor="#FFFFFF" text="#000000" link="#1E609C"  leftmargin="0" rightmargin="0" marginwidth="0" topmargin="0" marginheight="0">
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>

<center><a href="/admin/" target="_top"><img src="/cmsimg/design/topic_110x50.jpg" width="110" height="50" alt="VCMS" border="0"></a></center>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>


<cml:if expr='dev()'>
DEV ON <a href="/" target="_top">>></a> <a href="#" onclick="setCookie('dev','0');window.location.reload();return false">OFF</a>
</cml:if>
<cml:else>
DEV OFF <a href="/" target="_top">>></a> <a href="#" onclick="setCookie('dev','1');window.location.reload();return false">ON</a>
</cml:else>


<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=5 alt="" border=0></td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>
)});


addlowobject({upobjkey=>'BASECMS',key=>'BASEMENUFOOTER',name=>'Базовый шаблон подвала меню'});
setvalue({key=>'BASEMENUFOOTER',pkey=>'PAGETEMPLATE',value=>'
</td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
</body>
</html>
'});



my $bm="
<CML:INCLUDE name='BASEMAINHEADER'/>
<CML:INCLUDE name='_prm:body_'/>
<CML:INCLUDE name='BASEMAINFOOTER'/>
";

addlowobject({upobjkey=>'BASECMS',key=>'BASEMAIN',name=>'Базовый шаблон правого фрейма'});
setvalue({key=>'BASEMAIN',pkey=>'PAGETEMPLATE',value=>$bm});

addlowobject({upobjkey=>'CMSFORM',key=>'USERMAIN',name=>'Шаблон страницы'});
setvalue({key=>'USERMAIN',pkey=>'PAGETEMPLATE',value=>"<CML:INCLUDE name='BASEMAIN'/>"});

my $bmv=qq(<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">
<style type=text/css>
<!--
td, body {font-family: Tahoma, Arial; font-size: 11px; color: #000000;}
body {scrollbar-base-color: #000066; scrollbar-arrow-color: #ffffff; scrollbar-highlight-color: #FFFFFF; scrollbar-shadow-color: #FFFFFF; scrollbar-face-color: #909090; scrollbar-track-color: #f0f0f0; }
a:,a:link, a:visited {font-family: Tahoma, sans-serif; font-size: 11px; color: #1E609C; text-decoration: underline;}
a:active, a:hover {font-family: Tahoma, sans-serif; font-size: 11px; color: #9C1E1E; text-decoration: none;}
hr {border: 0; width: 100%; color: #770000; background-color: #D96926; height: 2px;}
li {font-family: "Lucida Console", monospace; font-size: 11px; font-weight : bold; list-style : square;}
ul {font-family: Verdana, Arial, Helvetica, sans-serif; list-style: square; margin-bottom : 0; margin-top : 0;}
input, select {font-family: Verdana, Arial, sans-serif; font-size: 12px; font-weight : bold;}
small, .small {font-family: Tahoma, sans-serif; font-size: 9px; color: #565B64; font-weight : normal;}
h1, h2, h3, h4, h5, h6 {font-family: Trebuchet MS, Tahoma, sans-serif; font-size: 18px; color: #00458B; font-weight : bold;}
-->
</style>
</head>
<body bgcolor="#FFFFFF" text="#000000" link="#1E609C" leftmargin="0" rightmargin="0" marginwidth="0" topmargin="0" marginheight="0">

<script language="javascript" type="text/javascript" src="/js/base.js"></script>

<script language="javascript" type="text/javascript" src="/tiny_mce/tiny_mce.js"></script>
<script language="javascript" type="text/javascript">
tinyMCE.init({ mode : "specific_textareas",
editor_selector : "mceEditor",
convert_urls : false,
theme : "advanced",
theme_advanced_styles : "Заголовок 1=mcheader1;Заголовок 2=mcheader2;Заголовок 3=mcheader3",
theme_advanced_disable : "image",
theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect",
theme_advanced_buttons3 : "",
content_css : "/css/mce.css",
apply_source_formatting: true,
language : "ru"
});
function insertimage (text){
tinyMCE.execCommand('mceInsertContent', false, ' <img src="'+text+'"/> ');
tinyMCE.execCommand('mceInsertContent', false, '');
};
function insertlink (src,name){
tinyMCE.execCommand('mceInsertContent', false, ' <a href="'+src+'"/>'+name+'</a> ');
tinyMCE.execCommand('mceInsertContent', false, '');
};


function toggleEditor(id) {
var elm = document.getElementById(id);

if (tinyMCE.getInstanceById(id) == null)
tinyMCE.execCommand('mceAddControl', false, id);
else
tinyMCE.execCommand('mceRemoveControl', false, id);
}

</script>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>

<center><a href="/admin/" target="_top"><img src="/cmsimg/design/topic_110x50.jpg" width="110" height="50" alt="VCMS" border="0"></a></center>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=5 alt="" border=0></td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>);
addlowobject({upobjkey=>'BASECMS',key=>'BASEMAINHEADER',name=>'Базовый шаблон заголовка правого фрейма'});
setvalue({key=>'BASEMAINHEADER',pkey=>'PAGETEMPLATE',value=>$bmv});



my $bmf=qq(
</td></tr></table>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
</body>
</html>
);
addlowobject({upobjkey=>'BASECMS',key=>'BASEMAINFOOTER',name=>'Базовый шаблон подвала правого фрейма'});
setvalue({key=>'BASEMAINFOOTER',pkey=>'PAGETEMPLATE',value=>$bmf});


$bm=qq(
<cml:use key='_prm:ukey_'>
<cml:text param='_NAME'/><br>
<cml:form matrix='1'>
<table>
<tr><th></th><th>Наименование</th><th>Номер</th></tr>
<cml:list expr='lowlist()'>
<tr>
<td><cml:deletebutton/></td>
<td><cml:inputtext param='_NAME'/></td>
<td><cml:inputtext param='_INDEX'/></td>
</tr>
</cml:list>
<tr><td/><td><cml:changebutton/></td></tr>
</table>
</cml:form>
<hr>
<cml:actionlink action='add'>Добавить новый</cml:actionlink>
</cml:use>
);
addlowobject({upobjkey=>'BASECMS',key=>'BASELISTEDIT',name=>'Базовый шаблон редактирвания списка'});
setvalue({key=>'BASELISTEDIT',pkey=>'PAGETEMPLATE',value=>$bm});


$ble=qq(
<cml:use id='\$key'>
<cml:form parser='BASELPARSER'>
<table>
<tr><td>Наименование: </td><td><cml:text param='_NAME'/></b><br></td></tr>
<tr><td>Текст: </td><td><cml:inputtext prm='_prm:editprm_' class='mceEditor' textareaid='MCEDITOR'/></b><br>
WYSIWIG<input type='checkbox' checked onClick="javascript:toggleEditor('MCEDITOR');"></a>
</td></tr>

<tr><td colspan=2><cml:changebutton/></td></tr>

</table>

</cml:form>
<hr>
<table><tr>
<cml:list prm='_prm:piclistprm_'>
<td>
<cml:a href='#' alt='_cml:_NAME_' onclick="javascript:insertimage('_global:FILEURL_/_cml:PIC_')"><cml:image param='PIC' width=100/></cml:a> <br>
<cml:actionlink action='delete'>Удалить</cml:actionlink>
</td>
</cml:list>
</tr>
</table>





<cml:form insertinto='_id:GALLERY_' link='PICLINK'>
Наименование <cml:inputtext param='_NAME' value=''/>
<cml:inputfile param='PIC'/>

<input type='submit' value='Новая картинка'>
</cml:form>



<hr>
<table><tr>
<cml:list prm='_prm:filelistprm_'>
<td>
<cml:a href='#' alt='_cml:_NAME_' onclick="javascript:insertlink('_global:FILEURL_/_cml:ARCHIVEFILE_','_CML:_NAME_')"><cml:text param='_NAME'/></cml:a> <br>
<cml:text param='ARCHIVEFILEDESCR'/><br>
<cml:actionlink action='delete'>Удалить</cml:actionlink>
</td>
</cml:list>
</tr>
</table>



<cml:form insertinto='_id:FILEARCHIVE_' link='FILELINK'>
Наименование <cml:inputtext param='_NAME' value=''/> <br>
Описание <cml:inputtext param='ARCHIVEFILEDESCR' value=''/> <br>
<cml:inputfile param='ARCHIVEFILE'/>

<input type='submit' value='Новый файл'>
</cml:form>

</cml:use>




);
addlowobject({upobjkey=>'BASECMS',key=>'BASEARTICLE',name=>'Базовый шаблон редактирвания статьи с фотографиями'});
setvalue({key=>'BASEARTICLE',pkey=>'PAGETEMPLATE',value=>$ble});






addlowobject({upobjkey=>'CMSMENU',key=>'CMSMAINMENU',name=>'Шаблон главного меню'});
setvalue({key=>'CMSMAINMENU',pkey=>'PAGETEMPLATE',value=>'
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<tr><td bgcolor="#FFFFFF" width="16">
	<a href="#" target="adminmb"><cml:img src="/cmsimg/edit.png" alt="EDIT" border="0"/></a>
</td>
<td bgcolor="#dedede" width="100%" colspan="2">
	<a href="#" target="adminmb">пустой</a>
</td>
<td bgcolor="#dedede" width="16"><img src="/cmsimg/0.gif" width="16" height="16" alt="" border="0"></td>
</td></tr></table>
'});

my $addscript=qq(
	
	my $newid;
	my $name=$CGIPARAM->{name} || 'Новый';
	if ($CGIPARAM->{upobj}) {   
			$newid=addlowobject({name=>$name,upobj=>$CGIPARAM->{upobj},up=>$CGIPARAM->{up}});
	} else {   
			$newid=addlowobject({name=>$name,upobj=>$CGIPARAM->{up}});
	}
	if ($CGIPARAM->{link}) {    
		my $lv=$CGIPARAM->{linkval}?$CGIPARAM->{linkval}:$CGIPARAM->{id};    
		setvalue ({id=>$newid,prm=>$CGIPARAM->{link},value=>$lv});
	}alert("Новый объект создан");
	
);
addmethod ({objkey=>'BASECMS',key=>'BASEADDMETHOD',name=>'Базовый метод добавления',lflag=>1,script=>$addscript});
addmethod ({objkey=>'BASECMS',key=>'BASEADDMETHOD',name=>'Базовый метод добавления',script=>$addscript});


addmethod ({objkey=>'BASECMS',key=>'BASEDELMETHOD',name=>'Базовый метод удаления',script=>'
	my $id=$CGIPARAM->{parseid} || $CGIPARAM->{id};
	deletelowobject($id);
	alert(\'Объект удален\');
'});
addmethod ({objkey=>'BASECMS',key=>'BASEDELMETHOD',name=>'Базовый метод удаления',lflag=>1,script=>'
	my $id=$CGIPARAM->{parseid} || $CGIPARAM->{id};
	deletelowobject($id);
	alert(\'Объект удален\');
'});

addmethod ({objkey=>'BASECMS',key=>'BASEDELPARAMMETHOD',name=>'Базовый метод очистки параметра',lflag=>1,script=>'
my $id=$CGIPARAM->{parseid}?$CGIPARAM->{parseid}:$CGIPARAM->{id};
setvalue({id=>$id,param=>$CGIPARAM->{prm},value=>\'\'});
alert(\'Удален\');
'});



addmethod ({objkey=>'BASECMS',key=>'BASEPARSER',name=>'Шаблон метода обработки',script=>'
	my $id=$CGIPARAM->{id};
	update({id=>$id,name=>$CGIPARAM->{name},indx=>$CGIPARAM->{indx}});
	alert(\'Информация изменена\');
'});


addmethod ({objkey=>'BASECMS',key=>'BASELPARSER',name=>'обработчик',lflag=>1,script=>'baselparser()'});
addmethod ({objkey=>'BASECMS',key=>'BASELPARSER',name=>'обработчик',script=>'baselparser()'});


my $sscript='
my $name=$CGIPARAM->{name};
my $value=$CGIPARAM->{value};
$SETSITEVARS->{$name}=$value;
';
addmethod ({objkey=>'BASECMS',key=>'BASESETVARMETHOD',name=>'Установка сессионной переменной',lflag=>1,script=>$sscript});


alert('Структура создана успешно');

	
}

sub install_mce {
	`tar -xzvf $GLOBAL->{FILEPATH}/install/tiny_mce.tgz -C $GLOBAL->{FILEPATH}/install && cd $GLOBAL->{FILEPATH}/install/tinymce/jscripts/ && mv tiny_mce ../../../..`;
	`rm -rf $GLOBAL->{FILEPATH}/install/tinymce`;
	alert('tiny_mce установлен успешно');
}


sub install_db ($$) {
	my ($dbh,$DBPREFIX)=@_;
	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}extraprm (
  			pkey varchar(255) NOT NULL default '',
  			extra varchar(100) NOT NULL default '',
  			value text,
  			PRIMARY KEY  (pkey,extra)
		) TYPE=MyISAM;
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}links (
  			objid varchar(30) NOT NULL default '',
  			pkey varchar(100) NOT NULL default '',
  			vallink varchar(30) NOT NULL default '',
  			PRIMARY KEY  (objid,pkey,vallink),
  			KEY `vll` (`vallink`)
		) TYPE=MyISAM
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}log (
  			session timestamp(14) NOT NULL,
  			dt datetime default NULL,
  			type varchar(50) default NULL,
  			message text
		) TYPE=MyISAM
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}method (
  			id int(11) NOT NULL auto_increment,
  			pname varchar(255) default NULL,
  			objid int(11) default NULL,
  			pkey varchar(255) default NULL,
  			script text,
  			PRIMARY KEY  (id)
		) TYPE=MyISAM
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}lmethod (
  			`id` int(11) NOT NULL auto_increment,
  			`pname` varchar(255) default NULL,
  			`objid` int(11) default NULL,
  			`pkey` varchar(255) default NULL,
  			`script` text,
  			PRIMARY KEY  (`id`)
		) TYPE=MyISAM
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}objects (
  			id int(11) PRIMARY KEY NOT NULL auto_increment ,
  			up int(11) default NULL,
  			upobj int(11) default NULL,
  			keyname varchar(255) default NULL,
  			template int(11) default NULL,
  			indx int,
  			owner varchar(50),
  			KEY upobj (upobj),
  			KEY keyname (keyname),
  			KEY indx (indx)
		) TYPE=MyISAM
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}prm (
  			id int(11) NOT NULL auto_increment,
  			ptype varchar(80) default NULL,
  			pname varchar(255) default NULL,
  			objid int(11) default NULL,
  			pkey varchar(255) default NULL,
  			defval text,
  			upd enum('y','n') default 'y',
  			evaluate enum('y','n') default 'y',
  			self enum('y','n') default 'n',
  			PRIMARY KEY  (id)
		) TYPE=MyISAM
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}tree (
  			id int(11) NOT NULL auto_increment,
  			up int(11) default NULL,
  			keyname varchar(255) default NULL,
  			template int(11) default NULL,
  			ltemplate int(11) default NULL,
  			indx int,
  			lang char(5),
  			nolog tinyint,
  			PRIMARY KEY  (id),
  			KEY up (up),
  			KEY indx(indx),
  			KEY lang(lang)
		) TYPE=MyISAM
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}tvls (
  			id varchar(20) NOT NULL default '',
  			pkey varchar(50) NOT NULL default '',
  			vkey varchar(100) NOT NULL default '',
  			value text,
  			ptkey varchar(50) NOT NULL default '',
  			PRIMARY KEY  (id,pkey,ptkey,vkey)
		) TYPE=MyISAM
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}uvls (
  			`objid` int(11) NOT NULL default '0',
  			`pkey` varchar(255) NOT NULL default '',
  			`value` text,
  			`lang` varchar(20) NOT NULL default '',
  			PRIMARY KEY  (`objid`,`pkey`,`lang`)
		) TYPE=MyISAM
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}vls (
  			`objid` int(11) NOT NULL default '0',
  			`pkey` varchar(255) NOT NULL default '',
  			`value` text,
  			`upobj` int(11) default NULL,
  			`lang` varchar(20) NOT NULL default '',
  			PRIMARY KEY  (`objid`,`pkey`,`lang`),
  			KEY `upobj` (`upobj`)
		) TYPE=MyISAM
	") || die $dbh->errstr();


	$dbh->do("CREATE TABLE IF NOT EXISTS ${DBPREFIX}vlshist (
	  		`objid` varchar(20) default NULL,
  			`pkey` varchar(255) default NULL,
  			`filename` varchar(255) default NULL,
  			`dt` datetime default NULL,
  			`ptype` varchar(255) default NULL,
  			`value` text,
  			`lang` varchar(20) default NULL,
  			KEY `objid` (`objid`),
  			KEY `pkey` (`pkey`),
  			KEY `ptype` (`ptype`),
  			KEY `lang` (`lang`)
		) TYPE=MyISAM
	") || die $dbh->errstr();

	$dbh->do("create table IF NOT EXISTS ${DBPREFIX}cmsprm (
 			id varchar(10) not null,
 			prm varchar(50) not null,
 			value text,
 			primary key (id,prm)
		) TYPE=MyISAM
	") || die $dbh->errstr();


	$dbh->do("create table IF NOT EXISTS ${DBPREFIX}users (
 			`login` varchar(50) unique key,
 			`password` varchar(255),
 			`group` varchar(50)
		) TYPE=MyISAM
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}fs (
  			`id` varchar(20) NOT NULL default '',
  			`prm` varchar(50) NOT NULL default '',
  			`val` varchar(255) default NULL,
  			`lang` varchar(5) NOT NULL default '',
  			PRIMARY KEY  (`id`,`prm`,`lang`),
  			KEY `val` (`val`)
		) TYPE=MyISAM
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}fsint (
  			`id` varchar(20) NOT NULL default '',
  			`prm` varchar(50) NOT NULL default '',
  			`val` integer default 0,
  			`lang` varchar(5) NOT NULL default '',
  			PRIMARY KEY  (`id`,`prm`,`lang`),
  			KEY `val` (`val`)
		) TYPE=MyISAM
	") || die $dbh->errstr();
	
	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}pagescache (
  			`cachekey` varchar(100) NOT NULL default '',
  			`pagetext` mediumtext,
  			`ts` datetime default NULL,
  			`objid` int(11) NOT NULL default '0',
  			`dev` int(11) NOT NULL default '0',
  			PRIMARY KEY  (`cachekey`,`dev`)
		) ENGINE=MyISAM") || die $dbh->errstr();
	
	$dbh->do("
		 CREATE TABLE IF NOT EXISTS ${DBPREFIX}linkscache (
  			`cachekey` varchar(100) NOT NULL default '',
  			`objlink` varchar(12) NOT NULL default '',
  			`dev` int(11) NOT NULL default '0',
  			PRIMARY KEY  (`cachekey`,`objlink`,`dev`)
		) ENGINE=MyISAM") || die $dbh->errstr();
	
	
	
	
}

return 1;

END {}