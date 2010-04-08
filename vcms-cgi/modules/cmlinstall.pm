package cmlinstall;

# $Id: cmlinstall.pm,v 1.72 2010-04-08 11:33:48 vano Exp $

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
	
addobject({convertname=>1,forced=>1,up=>0,key=>'CONTENT',name=>'Содержимое сайта'});
addobject({convertname=>1,forced=>1,up=>0,key=>'DESIGN',name=>'Дизайн сайта'});
addobject({convertname=>1,forced=>1,up=>0,key=>'CMSDESIGN',name=>'Дизайн интерфейса администрирования'});
addobject({convertname=>1,forced=>1,up=>0,key=>'TEMPLATES',name=>'Шаблоны'});
addobject({convertname=>1,forced=>1,up=>0,key=>'RESTRICTIONS',name=>'Ограничения доступа'});
addobject({convertname=>1,forced=>1,up=>0,key=>'MAINPRM',name=>'Параметры'});
addobject({convertname=>1,forced=>1,up=>0,key=>'AUTOMATE',name=>'Автозапуск'});



addprm({convertname=>1,objkey=>'CONTENT',name=>'Сайт открыт',type=>'FLAG',key=>'OPENSITE',evl=>'n',self=>1});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Картинки',type=>'LIST',key=>'PICLINKS',upd=>'n',defval=>'backref(0,PICLINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Первая картинка',type=>'LIST',key=>'FIRSTPIC',upd=>'n',defval=>'my @v=split(/;/,p(PICLINKS));$v[0]'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Картинки для верхних объектов',type=>'LIST',key=>'UPICLINKS',upd=>'n',defval=>'ubackref(id(GALLERY),PICLINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Файлы',type=>'LIST',key=>'FILELINKS',upd=>'n',defval=>'backref(0,FILELINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Файлы для верхних объектов',type=>'LIST',key=>'UFILELINKS',upd=>'n',defval=>'ubackref(id(FILEARCHIVE),FILELINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Ролики',type=>'LIST',key=>'VIDLINKS',upd=>'n',defval=>'backref(0,VIDLINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Первый ролик',type=>'LIST',key=>'FIRSTVIDEO',upd=>'n',defval=>'my @v=split(/;/,p(VIDLINKS));$v[0]'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'Ролики для верхних объектов',type=>'LIST',key=>'UVIDLINKS',upd=>'n',defval=>'ubackref(id(VIDEOGALLERY),VIDLINK)'});


addobject({convertname=>1,upkey=>'CONTENT',key=>'SECTIONS',name=>'Разделы каталога'});
addprm({convertname=>1,objkey=>'SECTIONS',name=>'Позиции',type=>'LIST',key=>'POSITIONS',evl=>'y',upd=>'n',defval=>'backref(id(ITEMS),SECLINK)'});

addobject({convertname=>1,upkey=>'CONTENT',key=>'ITEMS',name=>'Позиции каталога'});
addprm({convertname=>1,objkey=>'ITEMS',name=>'Раздел',type=>'LIST',key=>'SECLINK',evl=>'n',upd=>'y'});
setprmextra({pkey=>'SECLINK',extra=>'formula',value=>'lowlist(id(SECTIONS))'});
setprmextra({pkey=>'SECLINK',extra=>'single',value=>'y'});

addobject({convertname=>1,upkey=>'CONTENT',key=>'ARTICLES',name=>'Статьи'});
addprm({convertname=>1,objkey=>'ARTICLES',name=>'Текст статьи',type=>'LONGTEXT',key=>'ARTICLETEXT',evl=>'n'});
setprmextra({pkey=>'ARTICLETEXT',extra=>'parse',value=>'y'});
setprmextra({pkey=>'ARTICLETEXT',extra=>'visual',value=>'y'});

addobject({convertname=>1,upkey=>'CONTENT',key=>'GALLERY',name=>'Фотогалерея'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'Картинка',type=>'PICTURE',key=>'PIC',evl=>'n'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'Превью',type=>'PICTURE',key=>'SMALLPIC',evl=>'n'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'Ссылка на раздел',type=>'LIST',key=>'PICLINK',evl=>'n'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'Следующая картинка',type=>'LIST',key=>'NEXTPIC',upd=>'n',defval=>q(
my @v=reverse split(/;/,p(PICLINKS,p(PICLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});
addprm({convertname=>1,objkey=>'GALLERY',name=>'Предыдущая картинка',type=>'LIST',key=>'PREVPIC',upd=>'n',defval=>q(
my @v=split(/;/,p(PICLINKS,p(PICLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});




addobject({convertname=>1,upkey=>'CONTENT',key=>'VIDEOGALLERY',name=>'Видеогалерея'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'Ролик',type=>'VIDEO',key=>'MOVIE',evl=>'n'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'Ссылка на раздел',type=>'LIST',key=>'VIDLINK',evl=>'n'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'Картинка',type=>'PICTURE',key=>'PIC',evl=>'n'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'Следующий ролик',type=>'LIST',key=>'NEXTVIDEO',upd=>'n',defval=>q(
my @v=reverse split(/;/,p(VIDLINKS,p(VIDLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'Предыдущий ролик',type=>'LIST',key=>'PREVVIDEO',upd=>'n',defval=>q(
my @v=split(/;/,p(VIDLINKS,p(VIDLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});




addobject({convertname=>1,upkey=>'CONTENT',key=>'FILEARCHIVE',name=>'Файловый архив'});
addprm({convertname=>1,objkey=>'FILEARCHIVE',name=>'Файл',type=>'FILE',key=>'ARCHIVEFILE',evl=>'n'});
addprm({convertname=>1,objkey=>'FILEARCHIVE',name=>'Ссылка на раздел',type=>'LIST',key=>'FILELINK',evl=>'n'});
addprm({convertname=>1,objkey=>'FILEARCHIVE',name=>'Описание файла',type=>'TEXT',key=>'ARCHIVEFILEDESCR',evl=>'n'});
setprmextra({pkey=>'ARCHIVEFILEDESCR',extra=>'rows',value=>'3'});
setprmextra({pkey=>'ARCHIVEFILEDESCR',extra=>'cols',value=>'50'});






addprm({convertname=>1,objkey=>'DESIGN',name=>'Картинки',type=>'LIST',key=>'PICLINKS',upd=>'n',defval=>'backref(id(GALLERY),PICLINK)'});
addprm({convertname=>1,objkey=>'DESIGN',name=>'Файлы',type=>'LIST',key=>'FILELINKS',upd=>'n',defval=>'backref(id(FILEARCHIVE),FILELINK)'});
addprm({convertname=>1,objkey=>'DESIGN',name=>'Заголовок',type=>'TEXT',key=>'TITLE',defval=>'$CGIPARAM->{1}?p(_NAME,$CGIPARAM->{1}):p(_NAME)'});

addprm({convertname=>1,objkey=>'DESIGN',name=>'Хост для поиска',type=>'TEXT',key=>'SEARCHSITE',upd=>'y',evl=>'n',self=>1});
setvalue({key=>'DESIGN',pkey=>'SEARCHSITE',value=>$ENV{SERVER_NAME}});
addprm({convertname=>1,objkey=>'DESIGN',name=>'Объем поисковой выдачи',type=>'NUMBER',key=>'SEARCHITEMS',upd=>'y',evl=>'n',self=>1});
setvalue({key=>'DESIGN',pkey=>'SEARCHITEMS',value=>10});

addmethod ({convertname=>1,objkey=>'DESIGN',key=>'YSEARCH',name=>'Поииск яндекса по сайту',lflag=>1,script=>q(
use cmlutils;
my $r=sitesearch($cmlcalc::CGIPARAM->{'query'},{
	site=>p(SEARCHSITE,id(DESIGN)),
	positions=>p(SEARCHITEMS,id(DESIGN)),
});
$cmlcalc::ENV->{FOUND}=scalar @{$r->{result}};
if ($r->{errorcode}) {
    $cmlcalc::ENV->{ERRORCODE}=$r->{errorcode};
    $cmlcalc::ENV->{ERROR}=$r->{error};
    $cmlcalc::ENV->{FOUND}=0;
    return 1;
}

my $i=0;
my @objs;
for (@{$r->{result}}) {
   $i++;
   push(@objs,"v$i");
   $cmlcalc::ENV->{'v'.$i.'str'}=$_->{string}  || 'Найден по ссылке';
   $cmlcalc::ENV->{'v'.$i.'url'}=$_->{url};
   $cmlcalc::ENV->{'v'.$i.'title'}=$_->{title};
}
$cmlcalc::ENV->{LIST}=join(';',@objs);
return 1;
)});


addprm({convertname=>1,objkey=>'DESIGN',name=>'Шаблон',type=>'LONGTEXT',key=>'PAGETEMPLATE',evl=>'n'});
addprm({convertname=>1,objkey=>'DESIGN',name=>'Заголовок',type=>'TEXT',key=>'TITLE'});
setprmextra({pkey=>'PAGETEMPLATE',extra=>'parse',value=>'y'});

addobject({convertname=>1,forced=>1,upkey=>'DESIGN',key=>'INCLUDES',name=>'Вставки'});
addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'INITSCRIPTS',name=>'Инициализационная секция'});
setvalue({key=>'INITSCRIPTS',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<link rel="stylesheet" href="/css/mce.css" type="text/css" />
<link rel="stylesheet" href="/css/lightbox.css" type="text/css" media="screen" />


<script type="text/javascript" src="/js/swfobject.js"></script>
<script type="text/javascript" src="/js/cookiejar.js"></script>
<script type="text/javascript" src="/js/prototype.js"></script>
<script type="text/javascript" src="/js/base.js"></script>

<script src="/js/scriptaculous.js?load=effects,builder" type="text/javascript"></script>
<script>
  var lbLabelImage="Фото";
  var lbLabelOf="из";
</script>
<script src="/js/lightbox.js" type="text/javascript"></script>
)});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'SITEHEADER',name=>'Шапка'});

setvalue({key=>'SITEHEADER',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<html>
<head>
<title>
</title>
<cml:include key='INITSCRIPTS'/>
</head>
<body>
DEFAULT HEADER
<hr/>
)});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'SITEFOOTER',name=>'Подвал'});
setvalue({key=>'SITEFOOTER',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<hr/>DEFAULT FOOTER
</body>
</html>
)});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'SEARCHBLOCK',name=>'Поиск'});
setvalue({key=>'SEARCHBLOCK',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<form action='/_SEARCH' method='GET'>
<input name='query'><br><input type='submit' value='Найти'>
</form>
)});


addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'MAINTEMPLATE',name=>'Базовый шаблон'});
setvalue({key=>'MAINTEMPLATE',pkey=>'PAGETEMPLATE',value=>qq(
	<cml:include key="SITEHEADER"/> <cml:include name="_prm:view_"/> <cml:include key="SITEFOOTER"/>
)});
addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'UNDERCONSTRUCT',name=>'Заглушка'});
setvalue({key=>'UNDERCONSTRUCT',pkey=>'PAGETEMPLATE',value=>'Under construction...'});



addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'ARTICLE',name=>'Статья'});
setvalue({key=>'ARTICLE',pkey=>'PAGETEMPLATE',value=>q(
<cml:use key='ART__cgi:1_'>
<cml:text param='ARTICLETEXT'/>
</cml:use>
)});


addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'SEARCH',name=>'Поиск'});
setvalue({key=>'SEARCH',pkey=>'PAGETEMPLATE',convert=>1,value=>q(
<cml:execute method='YSEARCH'>
<br/>

<table width="100%" bgcolor="#CCCCCC" border="0" cellpadding="4" cellspacing="1">
<tr><td valign="middle" align="left" bgcolor="#666666">
<font color="#FFFFFF">Мы искали: "<b><cml:text value='_prm:query_'/></b>". И нашли для вас <b><cml:text value="_env:FOUND_" /></b> страниц</font>
</td></tr>

<cml:list value="_env:LIST_">
<tr><td valign="middle" align="left" bgcolor="#FFFFFF"><b><cml:a expr="env(p(_ID).url)"><cml:text expr="env(p(_ID).title)"/></cml:a></b><br/>
<cml:text expr="env(p(_ID).str)"/><br/>
<small><cml:a expr="env(p(_ID).url)"><font color="#999999"><cml:text expr="env(p(_ID).url)"/></font></cml:a></small></td></tr>
</cml:list>

<tr><td valign="middle" align="left" bgcolor="#666666"><font color="#FFFFFF">Результаты поиска: <b><cml:text value='_prm:query_'/></b></font></td></tr>
</table>
<br/>
</cml:execute>
)});



addprm({convertname=>1,objkey=>'AUTOMATE',name=>'Флаг активности',type=>'FLAG',key=>'AUTOLOCK',evl=>'n',self=>1});
addprm({convertname=>1,objkey=>'AUTOMATE',name=>'Время последнего запуска',type=>'DATE',key=>'AUTOLOCKTIME',evl=>'n',self=>1});
setprmextra({pkey=>'AUTOLOCKTIME',extra=>'format',value=>'%d.%m.%Y %H:%M'});
addprm({convertname=>1,objkey=>'AUTOMATE',name=>'Максимальный период',type=>'NUMBER',key=>'AUTOLOCKPERIOD',evl=>'n',self=>1});
addmethod ({convertname=>1,objkey=>'AUTOMATE',key=>'AUTOSCRIPT',name=>'Скрипт автозапуска',script=>qq(message ("AUTOSCRIPT STARTED : ".scalar localtime);)});



addobject({convertname=>1,forced=>1,upkey=>'AUTOMATE',key=>'AUTOLOGS',name=>'Логи автозапуска'});
addprm({convertname=>1,objkey=>'AUTOLOGS',name=>'Время запуска',type=>'DATE',key=>'EXECDATE',evl=>'n',upd=>'n'});
addprm({convertname=>1,objkey=>'AUTOLOGS',name=>'Лог',type=>'LONGTEXT',key=>'LOGBODY',evl=>'n',upd=>'n'});



addobject({convertname=>1,upkey=>'RESTRICTIONS',key=>'SYSTEMUSERS',name=>'Пользователи системы'});







addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'STARTPAGE',name=>'Стартовая страница'});
setvalue({key=>'STARTPAGE',pkey=>'PAGETEMPLATE',value=>'Here is startpage'});
addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'ERRORPAGE',name=>'Cтраница ошибки'});
setvalue({key=>'ERRORPAGE',pkey=>'PAGETEMPLATE',value=>'Here is errorpage'});

copyprm({objkey=>'CMSDESIGN',key=>'PAGETEMPLATE'});
copyprm({objkey=>'CMSDESIGN',key=>'TITLE'});


addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'CMSMENU',name=>'Шаблоны меню'});
addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'CMSFORM',name=>'Шаблоны форм'});
addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'BASECMS',name=>'Базовые шаблоны'});
addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'CMSINCLUDES',name=>'Вставки'});



addlowobject({convertname=>1,upobjkey=>'CMSFORM', key=>'MAINCMSTEMPL', name=>'Главный шаблон интерфейса'});
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


addlowobject({convertname=>1,upobjkey=>'CMSFORM', key=>'USERCMSTEMPL', name=>'Главный шаблон дополнительного интерфейса'});
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


addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASELIST',name=>'Базовый шаблон списка'});
setvalue({key=>'BASELIST',pkey=>'PAGETEMPLATE',convert=>1,value=>q(
<cml:use key='_prm:ukey_'>
	<cml:text param='_NAME'/><br>
	<cml:list  expr='lowlist()'>
  		<cml:actionlink action='DEL' id='_cml:_ID_'><cml:img src='_cml:_delimg_' alt=DELETE border='0'/></cml:actionlink>
  		<cml:a href='?body=EDIT__prm:ukey_&id=_cml:_ID_' target='adminmb'><cml:text param='_NAME'/></cml:a><br>
  	</cml:list>
  	<hr>
  	<cml:actionlink action='add'>Добавить новый</cml:actionlink>
  	<hr/>
  	<cml:a href='?menu=BASELIST&ukey=_CML:_KEY_'>Обновить</cml:a>
</cml:use>
)});

my $bestr=qq(  
  <cml:use id='_prm:id_'>
  <cml:form parser='BASELPARSER'>
      <table>
          <tr><td>Наименование: </td><td><cml:inputtext param='_NAME'/></td></tr>
          <tr><td colspan=2><input type=submit value='Зафиксировать изменения'></td></tr>
      </table>
  </cml:form>
  </cml:use>
);



addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEEDIT',name=>'Базовый шаблон объекта'});
setvalue({key=>'BASEEDIT',pkey=>'PAGETEMPLATE',value=>$bestr,convert=>1});




addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMENU',name=>'Базовый шаблон меню'});
setvalue({key=>'BASEMENU',pkey=>'PAGETEMPLATE',value=>"
<CML:INCLUDE name='BASEMENUHEADER'/>
<CML:INCLUDE name='CMSHEADMENU'/>
<CML:INCLUDE name='_prm:menu_'/>
<CML:INCLUDE name='BASEMENUFOOTER'/>
"});



addlowobject({convertname=>1,upobjkey=>'CMSMENU',key=>'USERMENU',name=>'Шаблон меню'});
setvalue({key=>'USERMENU',pkey=>'PAGETEMPLATE',value=>"<CML:INCLUDE name='BASEMENU'/>"});

addlowobject({convertname=>1,upobjkey=>'CMSMENU',key=>'USERMAINMENU',name=>'Главное меню пользовательсокго интерфейса'});
setvalue({convert=>1,key=>'USERMAINMENU',pkey=>'PAGETEMPLATE',value=>"... главное меню здесь ..."});



addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMENUHEADER',name=>'Базовый шаблон заголовка меню'});
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
<script language="javascript" type="text/javascript" src="/js/prototype.js"></script>

<CML:INCLUDE name='INITAJAX'/>

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


addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMENUFOOTER',name=>'Базовый шаблон подвала меню'});
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

addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMAIN',name=>'Базовый шаблон правого фрейма'});
setvalue({key=>'BASEMAIN',pkey=>'PAGETEMPLATE',value=>$bm});

addlowobject({convertname=>1,upobjkey=>'CMSFORM',key=>'USERMAIN',name=>'Шаблон страницы'});
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

<cml:include key='MCEINIT'/>
<cml:include key='INITHINTS'/>
<cml:include key='INITAJAX'/>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>

<center><a href="/admin/" target="_top"><img src="/cmsimg/design/topic_110x50.jpg" width="110" height="50" alt="VCMS" border="0"></a></center>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=5 alt="" border=0></td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>);


addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMAINHEADER',name=>'Базовый шаблон заголовка правого фрейма'});
setvalue({key=>'BASEMAINHEADER',pkey=>'PAGETEMPLATE',value=>$bmv});

addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'INITHINTS',name=>'Инициализация всплывающих картинок'});
setvalue({key=>'INITHINTS',pkey=>'PAGETEMPLATE',value=>qq(
<script language="JavaScript" src="/js/tigra_hints.js"></script>
<style>
.hintsClass {
	background-color: white;
	padding: 2px 2px 2px 2px;
}
</style>


<script language="JavaScript">
var HINTS_CFG = {
	'wise' : true,
	'margin' : 10,
	'gap' : 20,
	'align' : 'trbl',
	'css' : 'hintsClass',
	'show_delay' : 200,
	'hide_delay' : 200,
	'follow' : false,
	'z-index' : 100,
	'IEfix' : false,
	'opacity' :100
};
</script>
)});

addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'INITAJAX',name=>'Аякс'});
setvalue({key=>'INITAJAX',pkey=>'PAGETEMPLATE',value=>qq(
<script>
            function alertreload_callback(json){
                    alert(json.status); 
                    window.location.href=window.location.href.sub(/\#$/,'');
            }    
    
            function deleteobject (id) {
                var dt={
                    id: id,
                };
                ajax_call('deleteobject', dt, alertreload_callback);
            }

            function addobject (up,link,linkval,name,upobj) {
                var dt={
                    up: up,
                    link: link,
                    linkval: linkval,
                    upobj: upobj
                };
                ajax_call('addobject', dt, alertreload_callback);
            }
</script>
)});


addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'MCEINIT',name=>'Инициализация визуального редактора'});
setvalue({key=>'MCEINIT',pkey=>'PAGETEMPLATE',value=>qq(
	    <script language="javascript" type="text/javascript" src="/tiny_mce/tiny_mce.js"></script>
    <script language="javascript" type="text/javascript">
    tinyMCE.init({  mode : "specific_textareas",
        editor_selector : "mceEditor",
        convert_urls : false,
        theme : "advanced", 
        theme_advanced_styles : "Заголовок 1=mcheader1;Заголовок 2=mcheader2;Заголовок 3=mcheader3", 
        theme_advanced_disable : "image", 
        plugins : "paste,fullscreen",
        theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,fontsizeselect,|,forecolor,backcolor,|,sub,sup",
        theme_advanced_buttons2 : ",removeformat,visualaid,|,pastetext,pasteword,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code,|,fullscreen",
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

</script>
)});

addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'MCEPHOTO',name=>'Вставка фото в визивиг'});
setvalue({convert=>1,key=>'MCEPHOTO',pkey=>'PAGETEMPLATE',value=>qq(
<table><tr>
    <cml:list prm='PICLINKS'>
        <td><cml:deletebutton/><cml:a href='#' alt='_cml:_NAME_' onclick="javascript:insertimage('_global:FILEURL_/_cml:PIC_')"><cml:img border="0" prm='PIC'/></cml:a></td>
    </cml:list>
</tr></table>
<cml:form insertinto='_id:GALLERY_' link='PICLINK'>
     <cml:inputfile param='PIC'/>
     <input type='submit' value='Новая картинка'>
</cml:form>
)});



my $bmf=qq(
</td></tr></table>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
</body>
</html>
);




addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMAINFOOTER',name=>'Базовый шаблон подвала правого фрейма'});
setvalue({convert=>1,key=>'BASEMAINFOOTER',pkey=>'PAGETEMPLATE',value=>$bmf});


$bm=qq(
<cml:use id='_prm:id_' key='_prm:ukey_'>
<cml:text param='_NAME'/><br>
<cml:form matrix='1' ukey='_prm:ukey_' listprm='_prm:listprm_' link='_prm:link_'>
<table>
<tr><th></th><th>№</th><th>Наименование</th><th></th></tr>
<cml:list expr='p("_prm:listprm_") || lowlist()' orderby='_prm:orderby_' ordertype='_prm:ordertype_'>
<tr>
<td><cml:deletebutton/></td>
<td><cml:inputtext param='_INDEX' value='_LISTINDEX'/></td>
<td><cml:inputtext param='_NAME'/></td>
<td><cml:actionlink action='EDIT'>Редактировать</cml:actionlink></td>
</tr>
</cml:list>
<tr><td/><td><cml:changebutton/></td></tr>
</table>
</cml:form>
<hr>
<cml:actionlink action='add' upkey='_prm:ukey_' link='_prm:link_'>Добавить новый</cml:actionlink>
</cml:use>
);
addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASELISTEDIT',name=>'Базовый шаблон редактирвания списка'});
setvalue({convert=>1,key=>'BASELISTEDIT',pkey=>'PAGETEMPLATE',value=>$bm});




addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMENULIST',name=>'Базовый шаблон меню'});
setvalue({convert=>1,key=>'BASEMENULIST',pkey=>'PAGETEMPLATE',value=>qq(
<cml:use id='_prm:id_'>
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<b><cml:actionlink action='LISTEDIT' ukey='_prm:ukey_' listprm="_prm:listprm_" link="_prm:link_"><cml:text param='_NAME'/></cml:actionlink></b>
<cml:list  expr='p("_prm:listprm_") || lowlist()' orderby='_prm:orderby_' ordertype='_prm:ordertype_'>
  <cml:menuitem action="MENULIST" listprm="_prm:childlistprm_" ukey="_prm:childukey_" link="_prm:childlink_" delete="1"/>
</cml:list>
</table>
<hr>
<cml:actionlink action='add' upkey='_prm:ukey_' link='_prm:link_'>Добавить новый</cml:actionlink>
<hr/>
<cml:a href='#' onclick='window.location.reload()'>Обновить</cml:a>
</cml:use>
)});


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
addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEARTICLE',name=>'Базовый шаблон редактирвания статьи с фотографиями'});
setvalue({key=>'BASEARTICLE',pkey=>'PAGETEMPLATE',value=>$ble,convert=>1});


addlowobject({convertname=>1,upobjkey=>'CMSMENU',key=>'CMSHEADMENU',name=>'Статическая часть главного меню'});
setvalue({key=>'CMSHEADMENU',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<cml:menuitem action='MENULIST' key='SECTIONS' childlink='SECLINK' childukey='ITEMS' childlistprm='POSITIONS'>Каталог</cml:menuitem>
</table>
</td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>
)});




addlowobject({convertname=>1,upobjkey=>'CMSMENU',key=>'CMSMAINMENU',name=>'Шаблон главного меню'});
setvalue({key=>'CMSMAINMENU',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<cml:use key='SECTIONS'>
<b><cml:actionlink action='LISTEDIT' ukey='SECTIONS'><cml:text param='_NAME'/></cml:actionlink></b>
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<cml:list expr='lowlist()'>
  <cml:menuitem action="MENULIST" listprm="POSITIONS" ukey="ITEMS" link="SECLINK" delete="1"/>
</cml:list>
</table>
</cml:use>
)});

my $addscript=q(
	
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
addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEADDMETHOD',name=>'Базовый метод добавления',lflag=>1,script=>$addscript});
addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEADDMETHOD',name=>'Базовый метод добавления',script=>$addscript});


addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEDELMETHOD',name=>'Базовый метод удаления',script=>q(
	my $id=$CGIPARAM->{parseid} || $CGIPARAM->{id};
	deletelowobject($id);
	alert('Объект удален');
)});
addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEDELMETHOD',name=>'Базовый метод удаления',lflag=>1,script=>q(
	my $id=$CGIPARAM->{parseid} || $CGIPARAM->{id};
	deletelowobject($id);
	alert('Объект удален');
)});

addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEDELPARAMMETHOD',name=>'Базовый метод очистки параметра',lflag=>1,script=>q(
my $id=$CGIPARAM->{parseid}?$CGIPARAM->{parseid}:$CGIPARAM->{id};
setvalue({id=>$id,param=>$CGIPARAM->{prm},value=>\'\'});
alert('Удален');
)});



addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEPARSER',name=>'Шаблон метода обработки',script=>q(
	my $id=$CGIPARAM->{id};
	update({id=>$id,name=>$CGIPARAM->{name},indx=>$CGIPARAM->{indx}});
	alert('Информация изменена');
)});


addmethod ({convertname=>1,objkey=>'BASECMS',key=>'BASELPARSER',name=>'обработчик',lflag=>1,script=>'baselparser()'});
addmethod ({convertname=>1,objkey=>'BASECMS',key=>'BASELPARSER',name=>'обработчик',script=>'baselparser()'});


my $sscript='
my $name=$CGIPARAM->{name};
my $value=$CGIPARAM->{value};
$SETSITEVARS->{$name}=$value;
';
addmethod ({convertname=>1,objkey=>'BASECMS',key=>'BASESETVARMETHOD',name=>'Установка сессионной переменной',lflag=>1,script=>$sscript});


createcmsmethod({key=>'SECTIONS'},'listedittemplate');
createcmsmethod({key=>'ITEMS'},'listedittemplate');
createcmsmethod({key=>'SECTIONS'},'edittemplate');
createcmsmethod({key=>'ITEMS'},'edittemplate');


alert(enc('Структура создана успешно'));

	
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
  			`val` varchar(500) default NULL,
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
  			`lang` varchar(20) NOT NULL default '',
  		PRIMARY KEY  (`cachekey`,`dev`,`lang`)
  		) ENGINE=MyISAM") || die $dbh->errstr();
	
	$dbh->do("
		 CREATE TABLE IF NOT EXISTS ${DBPREFIX}linkscache (
  			`cachekey` varchar(100) NOT NULL default '',
  			`objlink` varchar(12) NOT NULL default '',
  			`dev` int(11) NOT NULL default '0',
  			`lang` varchar(20) NOT NULL default '',
  			PRIMARY KEY  (`cachekey`,`objlink`,`dev`,`lang`)
		) ENGINE=MyISAM") || die $dbh->errstr();
	
	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}captcha (
  			`id` int(11) NOT NULL AUTO_INCREMENT,
  			`ckey` int(11) NOT NULL,
  			`tm` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  			PRIMARY KEY (`id`),
  			KEY `ck` (`ckey`)
		) ENGINE=MyISAM") || die $dbh->errstr();

	
	
}

return 1;

END {}