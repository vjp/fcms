package cmlinstall;



BEGIN
{
 	use Exporter();
 	use cmlmain;
 	use Cwd;
 	@ISA    = 'Exporter';
 	@EXPORT = qw(
 		&install_structure &install_mce &install_db 
 		&create_db &create_db_user &populate_db &unpack_file &create_config
 	);
}
sub install_cron ($){
	my $period= shift || 15;
	my $path=cwd();
	system('crontab -r');
	system("echo '$period * * * * cd $path && ./autorun.pl' | crontab -");
}

sub install_structure {
	
addobject({convertname=>1,forced=>1,up=>0,key=>'CONTENT',name=>'���������� �����'});
addobject({convertname=>1,forced=>1,up=>0,key=>'DESIGN',name=>'������ �����'});
addobject({convertname=>1,forced=>1,up=>0,key=>'CMSDESIGN',name=>'������ ���������� �����������������'});
addobject({convertname=>1,forced=>1,up=>0,key=>'TEMPLATES',name=>'�������'});
addobject({convertname=>1,forced=>1,up=>0,key=>'RESTRICTIONS',name=>'����������� �������'});
addobject({convertname=>1,forced=>1,up=>0,key=>'MAINPRM',name=>'���������'});
addobject({convertname=>1,forced=>1,up=>0,key=>'AUTOMATE',name=>'����������'});
addobject({convertname=>1,forced=>1,up=>0,key=>'GATE',name=>'������� ���������'});
addobject({convertname=>1,forced=>1,up=>0,key=>'STAT',name=>'����������'});


addprm({convertname=>1,objkey=>'CONTENT',name=>'���� ������',type=>'FLAG',key=>'OPENSITE',evl=>'n',self=>1});
addprm({convertname=>1,objkey=>'CONTENT',name=>'��������',type=>'LIST',key=>'PICLINKS',upd=>'n',defval=>'backref(0,PICLINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'������ ��������',type=>'LIST',key=>'FIRSTPIC',upd=>'n',defval=>'my @v=sort{p(_INDEX,$a)<=>p(_INDEX,$b)}split(/;/,p(PICLINKS));$v[0]'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'�������� ��� ������� ��������',type=>'LIST',key=>'UPICLINKS',upd=>'n',defval=>'ubackref(id(GALLERY),PICLINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'�����',type=>'LIST',key=>'FILELINKS',upd=>'n',defval=>'backref(0,FILELINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'����� ��� ������� ��������',type=>'LIST',key=>'UFILELINKS',upd=>'n',defval=>'ubackref(id(FILEARCHIVE),FILELINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'������',type=>'LIST',key=>'VIDLINKS',upd=>'n',defval=>'backref(0,VIDLINK)'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'������ �����',type=>'LIST',key=>'FIRSTVIDEO',upd=>'n',defval=>'my @v=sort{p(_INDEX,$a)<=>p(_INDEX,$b)}split(/;/,p(VIDLINKS));$v[0]'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'������ ��� ������� ��������',type=>'LIST',key=>'UVIDLINKS',upd=>'n',defval=>'ubackref(id(VIDEOGALLERY),VIDLINK)'});


addobject({convertname=>1,upkey=>'CONTENT',key=>'SECTIONS',name=>'������� ��������'});
addprm({convertname=>1,objkey=>'CONTENT',name=>'������������',type=>'FILELINK',key=>'CONFFILE',evl=>'n',upd=>'y',self=>1});
setprmextra({pkey=>'CONFFILE',extra=>'cgi',value=>'y'});
setvalue({key=>'CONTENT',pkey=>'CONFFILE',value=>'conf'});

addprm({convertname=>1,objkey=>'SECTIONS',name=>'�������',type=>'LIST',key=>'POSITIONS',evl=>'y',upd=>'n',defval=>'backref(id(ITEMS),SECLINK)'});


addobject({convertname=>1,upkey=>'CONTENT',key=>'ITEMS',name=>'������� ��������'});
addprm({convertname=>1,objkey=>'ITEMS',name=>'������',type=>'LIST',key=>'SECLINK',evl=>'n',upd=>'y'});
setprmextra({pkey=>'SECLINK',extra=>'formula',value=>'lowlist(id(SECTIONS))'});
setprmextra({pkey=>'SECLINK',extra=>'single',value=>'y'});


addobject({convertname=>1,upkey=>'CONTENT',key=>'ARTICLES',name=>'������'});
addprm({convertname=>1,objkey=>'ARTICLES',name=>'����� ������',type=>'LONGTEXT',key=>'ARTICLETEXT',evl=>'n'});
setprmextra({pkey=>'ARTICLETEXT',extra=>'parse',value=>'y'});
setprmextra({pkey=>'ARTICLETEXT',extra=>'visual',value=>'y'});
addprm({convertname=>1,objkey=>'ARTICLES',name=>'���-����',type=>'TEXT',key=>'HRUKEY',evl=>'n'});
addprm({convertname=>1,objkey=>'ARTICLES',name=>'META-keywords',type=>'TEXT',key=>'KEYWORDS',evl=>'n'});
addprm({convertname=>1,objkey=>'ARTICLES',name=>'META-description',type=>'TEXT',key=>'DESCRIPTION',evl=>'n'});
addmethod ({convertname=>1,objkey=>'ARTICLES',key=>'SETHRUKEY',name=>'��������� ���-�����',lflag=>1,script=>q(
my $id=p(_ID);
my $key=p(HRUKEY);
my $rd="/_ARTICLE/$id";
set_hru($key,$rd);
)});
setprmextra({pkey=>'HRUKEY',extra=>'onchange',value=>'SETHRUKEY'});
addobject({convertname=>1,upkey=>'ARTICLES',key=>'SPECARTICLES',name=>'����������� ������'});
addlowobject({convertname=>1,upobjkey=>'SPECARTICLES',key=>'ARTICLE_404',name=>'�������� �� �������'});
setvalue({key=>'ARTICLE_404',pkey=>'ARTICLETEXT',convert=>1,value=>'�������� �� �������'});


addobject({convertname=>1,upkey=>'CONTENT',key=>'NEWS',name=>'�������'});
addprm({convertname=>1,objkey=>'NEWS',name=>'����� �������',type=>'LONGTEXT',key=>'NEWSTTEXT',evl=>'n'});
addprm({convertname=>1,objkey=>'NEWS',name=>'���� �������',type=>'DATE',key=>'NEWSDATE',evl=>'n'});
addprm({convertname=>1,objkey=>'NEWS',name=>'������ �������',type=>'TEXT',key=>'NEWSLINK',evl=>'n'});



addobject({convertname=>1,upkey=>'CONTENT',key=>'LETTERS',name=>'������'});
addprm({convertname=>1,objkey=>'LETTERS',name=>'����� ������',type=>'LONGTEXT',key=>'LETTERTEXT',evl=>'n'});
addprm({convertname=>1,objkey=>'LETTERS',name=>'���������',type=>'LONGTEXT',key=>'LETTERSUBJECT',evl=>'n'});
setprmextra({pkey=>'LETTERSUBJECT',extra=>'rows',value=>'1'});
addprm({convertname=>1,objkey=>'LETTERS',name=>'�����������',type=>'TEXT',key=>'LETTERFROM',evl=>'n'});
addprm({convertname=>1,objkey=>'LETTERS',name=>'HTML',type=>'FLAG',key=>'LETTERHTML',evl=>'n'});
addobject({convertname=>1,upkey=>'LETTERS',key=>'MANLETTERS',name=>'������ ��� �������������'});
addprm({convertname=>1,objkey=>'MANLETTERS',name=>'����������',type=>'TEXT',key=>'LETTERTO',evl=>'n'});

addobject({convertname=>1,upkey=>'CONTENT',key=>'GALLERY',name=>'�����������'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'��������',type=>'PICTURE',key=>'PIC',evl=>'n'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'������',type=>'PICTURE',key=>'SMALLPIC',evl=>'n'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'������ �� ������',type=>'LIST',key=>'PICLINK',evl=>'n'});
addprm({convertname=>1,objkey=>'GALLERY',name=>'��������� ��������',type=>'LIST',key=>'NEXTPIC',upd=>'n',defval=>q(
my @v=reverse sort{p(_INDEX,$a)<=>p(_INDEX,$b)} split(/;/,p(PICLINKS,p(PICLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});
addprm({convertname=>1,objkey=>'GALLERY',name=>'���������� ��������',type=>'LIST',key=>'PREVPIC',upd=>'n',defval=>q(
my @v=sort{p(_INDEX,$a)<=>p(_INDEX,$b)} split(/;/,p(PICLINKS,p(PICLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});




addobject({convertname=>1,upkey=>'CONTENT',key=>'VIDEOGALLERY',name=>'������������'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'�����',type=>'VIDEO',key=>'MOVIE',evl=>'n'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'������ �� ������',type=>'LIST',key=>'VIDLINK',evl=>'n'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'��������',type=>'PICTURE',key=>'PIC',evl=>'n'});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'��������� �����',type=>'LIST',key=>'NEXTVIDEO',upd=>'n',defval=>q(
my @v=reverse sort{p(_INDEX,$a)<=>p(_INDEX,$b)} split(/;/,p(VIDLINKS,p(VIDLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});
addprm({convertname=>1,objkey=>'VIDEOGALLERY',name=>'���������� �����',type=>'LIST',key=>'PREVVIDEO',upd=>'n',defval=>q(
my @v=sort{p(_INDEX,$a)<=>p(_INDEX,$b)} split(/;/,p(VIDLINKS,p(VIDLINK)));
my $id=p(_ID);
my $r=$v[-1];
for (@v) {
   return $r if $_==$id;
   $r=$_;
}
)});




addobject({convertname=>1,upkey=>'CONTENT',key=>'FILEARCHIVE',name=>'�������� �����'});
addprm({convertname=>1,objkey=>'FILEARCHIVE',name=>'����',type=>'FILE',key=>'ARCHIVEFILE',evl=>'n'});
addprm({convertname=>1,objkey=>'FILEARCHIVE',name=>'������ �� ������',type=>'LIST',key=>'FILELINK',evl=>'n'});
addprm({convertname=>1,objkey=>'FILEARCHIVE',name=>'�������� �����',type=>'TEXT',key=>'ARCHIVEFILEDESCR',evl=>'n'});
setprmextra({pkey=>'ARCHIVEFILEDESCR',extra=>'rows',value=>'3'});
setprmextra({pkey=>'ARCHIVEFILEDESCR',extra=>'cols',value=>'50'});





addprm({convertname=>1,objkey=>'DESIGN',name=>'htaccess',type=>'FILELINK',key=>'HTACCESS',evl=>'n',upd=>'y',self=>1});
setvalue({key=>'DESIGN',pkey=>'HTACCESS',value=>'.htaccess'});



addprm({convertname=>1,objkey=>'DESIGN',name=>'��������',type=>'LIST',key=>'PICLINKS',upd=>'n',defval=>'backref(id(GALLERY),PICLINK)'});
addprm({convertname=>1,objkey=>'DESIGN',name=>'�����',type=>'LIST',key=>'FILELINKS',upd=>'n',defval=>'backref(id(FILEARCHIVE),FILELINK)'});
addprm({convertname=>1,objkey=>'DESIGN',name=>'���������',type=>'TEXT',key=>'TITLE',defval=>'p(_NAME,cgi(1)) if cgi(1)'});
addprm({convertname=>1,objkey=>'DESIGN',name=>'META-Keywords',type=>'TEXT',key=>'KEYWORDS',defval=>'p(KEYWORDS,cgi(1)) if cgi(1)'});
addprm({convertname=>1,objkey=>'DESIGN',name=>'META-Description',type=>'TEXT',key=>'DESCRIPTION',defval=>'p(DESCRIPTION,cgi(1)) if cgi(1)'});

addprm({convertname=>1,objkey=>'DESIGN',name=>'���� ��� ������',type=>'TEXT',key=>'SEARCHSITE',upd=>'y',evl=>'n',self=>1});
setvalue({key=>'DESIGN',pkey=>'SEARCHSITE',value=>$ENV{SERVER_NAME}});
addprm({convertname=>1,objkey=>'DESIGN',name=>'����� ��������� ������',type=>'NUMBER',key=>'SEARCHITEMS',upd=>'y',evl=>'n',self=>1});
setvalue({key=>'DESIGN',pkey=>'SEARCHITEMS',value=>10});

addmethod ({convertname=>1,objkey=>'DESIGN',key=>'YSEARCH',name=>'����� ������� �� �����',lflag=>1,script=>q(
use cmlutils;
return 1 unless $cmlcalc::CGIPARAM->{'query'};
my $r=sitesearch($cmlcalc::CGIPARAM->{'query'},{
	site=>p(SEARCHSITE,id(DESIGN)),
	positions=>p(SEARCHITEMS,id(DESIGN)),
});
$cmlcalc::ENV->{FOUND}=scalar @{$r->{result}};
$cmlcalc::ENV->{FOUNDHUMAN}=$r->{foundhuman};
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
   $cmlcalc::ENV->{'v'.$i.'str'}=$_->{string};
   $cmlcalc::ENV->{'v'.$i.'url'}=$_->{url};
   $cmlcalc::ENV->{'v'.$i.'title'}=$_->{title};
}
$cmlcalc::ENV->{LIST}=join(';',@objs);
return 1;
)});


addprm({convertname=>1,objkey=>'DESIGN',name=>'������',type=>'LONGTEXT',key=>'PAGETEMPLATE',evl=>'n'});
setprmextra({pkey=>'PAGETEMPLATE',extra=>'parse',value=>'y'});

addobject({convertname=>1,forced=>1,upkey=>'DESIGN',key=>'INCLUDES',name=>'�������'});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'IFRAMEPARSER',name=>'���������� IFRAME'});
setvalue({key=>'IFRAMEPARSER',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<cml:execute method='BASELPARSER' id='_prm:id_'>
<script>
    var url=parent.location.href;
    <cml:if value="_prm:back_">
     parent.location.href='<cml:text value="_prm:back_"/>';
    </cml:if><cml:else>
     parent.location.href=url; 
    </cml:else> 
</script>
</cml:execute>
)});


addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'INITSCRIPTS',name=>'����������������� ������'});
setvalue({key=>'INITSCRIPTS',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<link rel="stylesheet" href="/css/mce.css" type="text/css" />
<link rel="stylesheet" href="/css/lightbox.css" type="text/css" media="screen" />


<script type="text/javascript" src="/js/swfobject.js"></script>
<script type="text/javascript" src="/js/cookiejar.js"></script>
<script type="text/javascript" src="/js/prototype.js"></script>
<script type="text/javascript" src="/js/base.js"></script>
<script type="text/javascript" src="/js/flowplayer.js"></script>

<script src="/js/scriptaculous.js?load=effects,builder" type="text/javascript"></script>
<script>
  var lbLabelImage="����";
  var lbLabelOf="��";
  var lbError="������";
  var lbSuccess="�����";
  var lbRequired="���������� ��������� ����";
  var lbDigit="������� �������� �������� � ����";   
  var  ajax_url = '/cgi-bin/user/ajax-json.pl';
</script>
<script src="/js/lightbox.js" type="text/javascript"></script>


<script>  
function jsErrHandler(message, url, line)
{
    new Ajax.Request('/cgi-bin/ajax-json.pl', {
            method:'post',  
            parameters: {func: 'JSERROR', data: Object.toJSON({message:message,url:url,line:line,ua:navigator.userAgent})}
        });
     return true;
}
window.onerror = jsErrHandler;
</script>

)});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'SITEHEADER',name=>'�����'});

setvalue({key=>'SITEHEADER',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<html>
<head>
<title>
<cml:use  key='_prm:view_'>
	<cml:text prm='TITLE'/></title>
    <cml:META NAME="keywords" content="_cml:KEYWORDS_"/>
    <cml:META NAME="description" content="_cml:DESCRIPTION_"/>
</cml:use>    
<cml:include key='INITSCRIPTS'/>
</head>
<body>
DEFAULT HEADER
<hr/>
)});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'SITEFOOTER',name=>'������'});
setvalue({key=>'SITEFOOTER',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<hr/>DEFAULT FOOTER
</body>
</html>
)});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'SEARCHBLOCK',name=>'�����'});
setvalue({key=>'SEARCHBLOCK',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<form action='/_SEARCH' method='GET'>
<input name='query'><br><input type='submit' value='�����'>
</form>
)});

addlowobject({convertname=>1,upobjkey=>'INCLUDES',key=>'NOTFOUND',name=>'�������� �� �������'});
setvalue({key=>'NOTFOUND',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<cml:include key='ARTICLE_404' prm='ARTICLETEXT' notfound='1'/>
<cml:execute method='ERR404PARSER'/>
)});

addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'MAINTEMPLATE',name=>'������� ������'});
setvalue({key=>'MAINTEMPLATE',pkey=>'PAGETEMPLATE',value=>qq(
	<cml:include key="SITEHEADER"/> <cml:include name="_prm:view_"/> <cml:include key="SITEFOOTER"/>
)});
addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'UNDERCONSTRUCT',name=>'��������'});
setvalue({convert=>1,key=>'UNDERCONSTRUCT',pkey=>'PAGETEMPLATE',value=>'���� � ����������'});



addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'ARTICLE',name=>'������'});
setvalue({key=>'ARTICLE',pkey=>'PAGETEMPLATE',value=>q(
<cml:use id='_cgi:1_'>
<cml:text param='ARTICLETEXT'/>
</cml:use>
)});


addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'SEARCH',name=>'�����'});
setvalue({key=>'SEARCH',pkey=>'PAGETEMPLATE',convert=>1,value=>q(
<cml:execute method='YSEARCH'>
<br/>

<table width="100%" bgcolor="#CCCCCC" border="0" cellpadding="4" cellspacing="1">
<tr><td valign="middle" align="left" bgcolor="#666666">
<font color="#FFFFFF">�� ������: "<b><cml:text value='_prm:query_'/></b>". � ����� ��� ��� <b><cml:text value="_env:FOUND_" /></b> �������</font>
</td></tr>

<cml:list value="_env:LIST_">
<tr><td valign="middle" align="left" bgcolor="#FFFFFF"><b><cml:a expr="env(p(_ID).url)"><cml:text expr="env(p(_ID).title)"/></cml:a></b><br/>
<cml:text expr="env(p(_ID).str)"/><br/>
<small><cml:a expr="env(p(_ID).url)"><font color="#999999"><cml:text expr="env(p(_ID).url)"/></font></cml:a></small></td></tr>
</cml:list>

<tr><td valign="middle" align="left" bgcolor="#666666"><font color="#FFFFFF">���������� ������: <b><cml:text value='_prm:query_'/></b></font></td></tr>
</table>
<br/>
</cml:execute>
)});

addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'DATAFILES',name=>'�������� �����'});
setvalue({convert=>1,key=>'DATAFILES',pkey=>'PAGETEMPLATE',value=>'����� ����� �������� �����'});



addprm({convertname=>1,objkey=>'AUTOMATE',name=>'���� ����������',type=>'FLAG',key=>'AUTOLOCK',evl=>'n',self=>1});
addprm({convertname=>1,objkey=>'AUTOMATE',name=>'����� ���������� �������',type=>'DATE',key=>'AUTOLOCKTIME',evl=>'n',self=>1});
setprmextra({pkey=>'AUTOLOCKTIME',extra=>'format',value=>'%d.%m.%Y %H:%M'});
addprm({convertname=>1,objkey=>'AUTOMATE',name=>'������������ ������',type=>'NUMBER',key=>'AUTOLOCKPERIOD',evl=>'n',self=>1});
addmethod ({convertname=>1,objkey=>'AUTOMATE',key=>'AUTOSCRIPT',name=>'������ �����������',script=>qq(message ("AUTOSCRIPT STARTED : ".scalar localtime);)});



addobject({convertname=>1,forced=>1,upkey=>'AUTOMATE',key=>'AUTOLOGS',name=>'���� �����������'});
addprm({convertname=>1,objkey=>'AUTOLOGS',name=>'����� �������',type=>'DATE',key=>'EXECDATE',evl=>'n',upd=>'n'});
addprm({convertname=>1,objkey=>'AUTOLOGS',name=>'���',type=>'LONGTEXT',key=>'LOGBODY',evl=>'n',upd=>'n'});



addobject({convertname=>1,upkey=>'RESTRICTIONS',key=>'SYSTEMUSERS',name=>'������������ �������'});
addobject({convertname=>1,upkey=>'SYSTEMUSERS',key=>'SYSTEMUSERS_admin',name=>'��������������'});
addobject({convertname=>1,upkey=>'SYSTEMUSERS',key=>'SYSTEMUSERS_user',name=>'���������'});





addmethod ({convertname=>1,objkey=>'SYSTEMUSERS_user',key=>'CREATEMANAGER',name=>'����� ��������',script=>q(
my $mid=adduser($CGIPARAM->{'login'},$CGIPARAM->{'pwd'},'user');
$result->{'status'}=1;
$result->{'mr_id'}=$mid;
return $result;
)});

addmethod ({convertname=>1,convertscript=>1,lflag=>1,objkey=>'SYSTEMUSERS_user',key=>'DELETEMANAGER',name=>'������� ���������',script=>q(
my $login=p(_NAME);
deluser($login);
$result->{'status'}='������������ ������';
return $result;
)});

addmethod ({convertname=>1,convertscript=>1,lflag=>1,objkey=>'SYSTEMUSERS_user',key=>'CHPASSMAN',name=>'������� ������',script=>q(
my $login=p(_NAME);
edituser($login,$CGIPARAM->{'pwd'},'user');
$result->{'status'}="������ ������������ $login �������";
return $result;
)});


addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'STARTPAGE',name=>'��������� ��������'});
setvalue({convert=>1,key=>'STARTPAGE',pkey=>'PAGETEMPLATE',value=>'��������� ��������'});
addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'ERRORPAGE',name=>'C������� ������'});
setvalue({convert=>1,key=>'ERRORPAGE',pkey=>'PAGETEMPLATE',value=>'������'});
addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'STATPAGE',name=>'�������� ��� ����������'});
setvalue({convert=>1,key=>'STATPAGE',pkey=>'PAGETEMPLATE',value=>'SUCCESS STAT'});
addlowobject({convertname=>1,upobjkey=>'DESIGN',key=>'ERROR404',name=>'C������� �� �������'});
setvalue({convert=>1,key=>'ERROR404',pkey=>'PAGETEMPLATE',value=>qq(<cml:include key='NOTFOUND'/>)});



copyprm({objkey=>'CMSDESIGN',key=>'PAGETEMPLATE'});
copyprm({objkey=>'CMSDESIGN',key=>'TITLE'});

addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'CMSDESIGNADMIN',name=>'��������� ��������������'});
addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'CMSDESIGNUSER',name=>'��������� ������������'});

addobject({convertname=>1,upkey=>'CMSDESIGNADMIN',key=>'CMSMENUADMIN',name=>'������� ����'});
addobject({convertname=>1,upkey=>'CMSDESIGNADMIN',key=>'CMSFORMADMIN',name=>'������� ����'});

addobject({convertname=>1,upkey=>'CMSDESIGNUSER',key=>'CMSMENUUSER',name=>'������� ����'});
addobject({convertname=>1,upkey=>'CMSDESIGNUSER',key=>'CMSFORMUSER',name=>'������� ����'});

addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'BASECMS',name=>'������� �������'});
addobject({convertname=>1,upkey=>'CMSDESIGN',key=>'CMSINCLUDES',name=>'�������'});




addlowobject({convertname=>1,upobjkey=>'CMSDESIGN', key=>'LISTEDIT_ERR404', name=>'���������� ��������'});
setvalue({convert=>1,key=>'LISTEDIT_ERR404',pkey=>'PAGETEMPLATE',value=>q(
<cml:use key='_prm:ukey_'>
������ 404 (�������� �� �������) <cml:actionlink action='CLEAR'>������� ��� ������</cml:actionlink>

<table>
<tr>
    <th></th>
    <th>�����</th>
    <th>URL (��� ������)</th>
    <th>������� (������ ������)</th>    
    <th>UserAgent</th>
</tr>
<cml:list expr='lowlist()' orderby='_ID' ordertype='desc'>
<tr>
<td><cml:deletebutton/></td>
<td><cml:text param='ERRORTIME'/></td>
<td><cml:a prm='ERRORURL' target='_blank'><cml:text param='ERRORURL'/></cml:a></td>
<td><cml:a prm='ERRORPAGE' target='_blank'><cml:text param='ERRORPAGE'/></cml:a></td>
<td><cml:text param='ERRORUA'/></td>
</tr>
</cml:list>
</table>

</cml:use>
)});

addlowobject({convertname=>1,upobjkey=>'CMSDESIGN', key=>'LISTEDIT_SYSTEMUSERS_user', name=>'������ ����������'});
setvalue({convert=>1,key=>'LISTEDIT_SYSTEMUSERS_user',pkey=>'PAGETEMPLATE',value=>q(
<script>
  function managerCreated(json) {

      if (json.status) {
          alert('������������ ������');
          window.location.href=window.location.href.sub(/\#$/,'');
      } else {
          alert('������: '+json.message);
      }   
  }
 
  function createManager() {
     if (!$('login').value) {
         alert('����� �� ����� ���� ������');
         return;
     }
     if (!$('pswn').value || $('pswn').value!=$('rpswn').value) {
         alert('������ �� ���������');
         return;
     }
     var dt = {
       login : $('login').value,
       pwd : $('pswn').value
     };
     execute('CREATEMANAGER',dt,managerCreated);
  }

  function changePass(id) {
     if (!$('psw'+id).value || $('psw'+id).value!=$('rpsw'+id).value) {
         alert('������ �� ���������');
         return;
     }
     var dt = {
         pwd : $('psw'+id).value
     };
     lexec(id,'CHPASSMAN',dt);
  } 
</script>

<cml:use key='_prm:ukey_'>
<cml:text param='_NAME'/><br>
<table>
<tr><th></th><th>�����</th><th>����� ������</th><th>��������� ����� ������</th><th></th></tr>
<cml:list expr='lowlist()'>
<tr>
<td><cml:deletebutton method='DELETEMANAGER'/></td>
<td><cml:text param='_NAME'/></td>
<td><cml:input id='psw_cml:_ID_' type='password'/></td>
<td><cml:input id='rpsw_cml:_ID_' type='password'/></td>
<td><cml:input type='button' value='�������� ������' onclick='changePass(_cml:_ID_)'/></td>
</tr>
</cml:list>
<tr>
<td></td>
<td><input id='login'/></td>
<td><input id='pswn' type='password'/></td>
<td><input id='rpswn' type='password'/></td>
<td><input type='button' value='������� ������' onclick='createManager()'/></td>
</tr>
</table>
</cml:use>
)});

addlowobject({convertname=>1,upobjkey=>'CMSDESIGN', key=>'EDIT_ARTICLES', name=>'�������������� ������'});
setvalue({convert=>1,key=>'EDIT_ARTICLES',pkey=>'PAGETEMPLATE',value=>q(
  <cml:use id='_prm:id_'>
  <cml:form>
      <table>
          <tr><td>������������: </td><td><cml:inputtext param='_NAME' size='100'/> <cml:a href='/_ARTICLE/_cml:_ID_' target='_blank'>�������</cml:a></td></tr>
          <tr><td>���-����: </td><td><cml:inputtext param='HRUKEY' size='100'/> <cml:a href='/_cml:HRUKEY_' target='_blank'>�������������� ���</cml:a></td></tr>
          <tr><td>META Keywords: </td><td><cml:inputtext size='100' param='KEYWORDS'/></td></tr>                    
          <tr><td>META Description: </td><td><cml:inputtext cols='100' rows='3' param='DESCRIPTION'/></td></tr>              
          <tr><td>����� ������: </td><td><cml:inputtext param='ARTICLETEXT'/></td></tr>          
          <tr><td colspan=2><cml:changebutton/></td></tr>
      </table>
  </cml:form>
  <cml:include key='MCEPHOTO'/>
  </cml:use>
)});

addlowobject({convertname=>1,upobjkey=>'CMSDESIGN', key=>'LISTEDIT_ARTICLES', name=>'�������������� ������ ������'});
setvalue({convert=>1,key=>'LISTEDIT_ARTICLES',pkey=>'PAGETEMPLATE',value=>q(
  <cml:use id='_prm:id_' key='_prm:ukey_'>
<cml:text param='_NAME'/><br>
<cml:form matrix='1' ukey='_prm:ukey_' listprm='_prm:listprm_' link='_prm:link_'>
<table>
<tr>
    <th></th>
    <th>�</th>
    <th>������������</th>
    <th>���-����</th>
    <th></th>
</tr>
<cml:list expr='p("_prm:listprm_") || lowlist()' orderby='_prm:orderby_' ordertype='_prm:ordertype_'>
<tr>
<td><cml:deletebutton/></td>
<td><cml:inputtext param='_INDEX' value='_LISTINDEX'/></td>
<td><cml:inputtext param='_NAME' size='50'/></td>
<td><cml:inputtext param='HRUKEY' size='50'/></td>
<td><cml:actionlink action='EDITVIEW'/></td>
</tr>
</cml:list>
<tr><td/><td colspan=2><cml:changebutton/></td></tr>
</table>
</cml:form>
<hr>
<cml:actionlink action='add' upkey='_prm:ukey_' link='_prm:link_'>�������� �����</cml:actionlink>
</cml:use>
)});



addlowobject({convertname=>1,upobjkey=>'CMSDESIGN', key=>'EDIT_LETTERS', name=>'�������������� ������'});
setvalue({convert=>1,key=>'EDIT_LETTERS',pkey=>'PAGETEMPLATE',value=>q(
<cml:use id='_prm:id_'>
  <cml:form parser='BASELPARSER'>
      <table>
          <tr><td>������������: </td><td><cml:inputtext param='_NAME' size='100'/></td></tr>
          <tr><td>����: </td><td><cml:inputtext param='_KEY'/></td></tr>
          <tr><td>���������: </td><td><cml:inputtext param='LETTERSUBJECT'/></td></tr>
          <tr><td>�����������: </td><td><cml:inputtext param='LETTERFROM'/></td></tr>
          <tr><td>HTML: </td><td><cml:inputflag param='LETTERHTML'/></td></tr>
          <tr><td>������ ������ ������: </td><td><cml:inputtext param='LETTERTEXT'/></td></tr>
          <tr><td colspan=2><cml:changebutton/></td></tr>
      </table>
  </cml:form>
  <hr/>
  ����������� ������ ������
  <hr/>
  <cml:text param='LETTERTEXT'/>
  <hr/>
</cml:use>
)});




addlowobject({convertname=>1,upobjkey=>'CMSFORMADMIN', key=>'MAINCMSTEMPL', name=>'������� ������ ����������'});
setvalue({key=>'MAINCMSTEMPL',pkey=>'PAGETEMPLATE',value=>qq(

<html>
<head>
<TITLE>VCMS : ��������� ��������������</TITLE>
</head>
<frameset cols="30%,*" SCROLLING=YES BORDERCOLOR="#770000">
	<frame src="/cgi-bin/admin/admin.pl?menu=CMSMAINMENU" name='adminlm' SCROLLING=YES BORDERCOLOR="#770000">
	<cml:frame src="/cgi-bin/admin/admin.pl?mbframe=1&body=_prm:framebody_&id=_prm:frameid_" name='adminmb' SCROLLING=YES BORDERCOLOR="#770000"/>
</frameset>
</html>
)});


addlowobject({convertname=>1,upobjkey=>'CMSFORMUSER', key=>'USERCMSTEMPL', name=>'������� ������ ��������������� ����������'});
setvalue({key=>'USERCMSTEMPL',pkey=>'PAGETEMPLATE',value=>qq(
<html>
<head>
<TITLE>VCMS : ��������� �����������</TITLE>
</head>
<frameset cols="30%,*" SCROLLING=YES BORDERCOLOR="#770000">
	<frame src="/cgi-bin/user/user.pl?menu=USERMAINMENU" name='adminlm' SCROLLING=YES BORDERCOLOR="#770000">
	<cml:frame src="/cgi-bin/user/user.pl?mbframe=1&body=_prm:framebody_&id=_prm:frameid_" name='adminmb' SCROLLING=YES BORDERCOLOR="#770000"/>
</frameset>
</html>
)});

addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'SPLASH',name=>'��������'});
setvalue({key=>'SPLASH',pkey=>'PAGETEMPLATE',convert=>1,value=>q(
<html>
<head>
<link href="/css/admin.css" rel="stylesheet" type="text/css">
</head>
<body>
<center>
<img src="/cmsimg/design/b-topic_500x100.jpg" width="500" height="100" alt="VCMS" border="0"><br>
<hr size=2>
<img src="/cmsimg/design/vcms_splash_500x400.jpg" width="500" height="400" alt="������������ VCMS" border="0"><br>
</center>
</body>
</html>
)});

addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASELIST',name=>'������� ������ ������'});
setvalue({key=>'BASELIST',pkey=>'PAGETEMPLATE',convert=>1,value=>q(
<cml:use key='_prm:ukey_'>
	<cml:text param='_NAME'/><br>
	<cml:list  expr='lowlist()'>
  		<cml:actionlink action='DEL' id='_cml:_ID_'><cml:img src='_cml:_delimg_' alt=DELETE border='0'/></cml:actionlink>
  		<cml:a href='?body=EDIT__prm:ukey_&id=_cml:_ID_' target='adminmb'><cml:text param='_NAME'/></cml:a><br>
  	</cml:list>
  	<hr>
  	<cml:actionlink action='add'>�������� �����</cml:actionlink>
  	<hr/>
  	<cml:a href='?menu=BASELIST&ukey=_CML:_KEY_'>��������</cml:a>
</cml:use>
)});

my $bestr=qq(  
  <cml:use id='_prm:id_'>
  <cml:form>
      <table>
          <tr><td>������������: </td><td><cml:inputtext param='_NAME'/></td></tr>
          <tr><td colspan=2><cml:changebutton/></td></tr>
      </table>
  </cml:form>
  </cml:use>
);



addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEEDIT',name=>'������� ������ �������'});
setvalue({key=>'BASEEDIT',pkey=>'PAGETEMPLATE',value=>$bestr,convert=>1});




addlowobject({convertname=>1,upobjkey=>'CMSMENUADMIN',key=>'BASEMENU',name=>'������ ����'});
setvalue({key=>'BASEMENU',pkey=>'PAGETEMPLATE',value=>"
<CML:INCLUDE name='BASEMENUHEADER'/>
<CML:INCLUDE name='_prm:menu_'/>
<CML:INCLUDE name='CMSHEADMENU'/>
<CML:INCLUDE name='BASEMENUFOOTER'/>
"});



addlowobject({convertname=>1,upobjkey=>'CMSMENUUSER',key=>'USERMENU',name=>'������ ����'});
setvalue({key=>'USERMENU',pkey=>'PAGETEMPLATE',value=>q(
<CML:INCLUDE name='USERMENUHEADER'/>
<CML:INCLUDE name='_prm:menu_'/>
<CML:INCLUDE name='USERHEADMENU'/>
<CML:INCLUDE name='BASEMENUFOOTER'/>
)});

addlowobject({convertname=>1,upobjkey=>'CMSMENUUSER',key=>'USERMAINMENU',name=>'������� ���� ����������������� ����������'});
setvalue({convert=>1,key=>'USERMAINMENU',pkey=>'PAGETEMPLATE',value=>"... ������� ���� ����� ..."});

addlowobject({convertname=>1,upobjkey=>'CMSMENUUSER',key=>'USERMENUHEADER',name=>'������� ������ ��������� ����'});
setvalue({key=>'USERMENUHEADER',pkey=>'PAGETEMPLATE',value=>qq(
<html>
<head>
<style type=text/css>
<!--
td, body                {font-family: Tahoma,  Arial; font-size: 11px; color: #000000;}
body                    {scrollbar-base-color: #000066; scrollbar-arrow-color: #ffffff; scrollbar-highlight-color: #FFFFFF; scrollbar-shadow-color: #FFFFFF; scrollbar-face-color: #909090; scrollbar-track-color: #f0f0f0; }
a:,a:link, a:visited            {font-family: Tahoma, sans-serif; font-size: 11px; color: #1E609C; text-decoration: underline;}
a:active, a:hover           {font-family: Tahoma, sans-serif; font-size: 11px; color: #9C1E1E; text-decoration: none;}
hr          {border: 0; width: 100%; color: #770000; background-color: #D96926; height: 2px;}
li          {font-family: "Lucida Console", monospace; font-size: 11px; font-weight : bold; list-style : square;}
ul          {font-family: Verdana, Arial, Helvetica, sans-serif; list-style: square; margin-bottom : 0; margin-top : 0;}
input, select       {font-family: Verdana, Arial, sans-serif; font-size: 12px; font-weight : bold;}
small, .small               {font-family: Tahoma, sans-serif; font-size: 9px; color: #565B64; font-weight : normal;}
h1, h2, h3, h4, h5, h6          {font-family: Trebuchet MS, Tahoma, sans-serif; font-size: 18px; color: #00458B; font-weight : bold;}
-->
</style>



<script type="text/javascript" src="/js/base.js"></script>
<script language="javascript" type="text/javascript" src="/js/prototype.js"></script>


</head>
<body bgcolor="#FFFFFF" text="#000000" link="#1E609C"  leftmargin="0" rightmargin="0" marginwidth="0" topmargin="0" marginheight="0">
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>

<center><cml:a href="_prm:_ROOT_" target="_top"><img src="/cmsimg/design/topic_110x50.jpg" width="110" height="50" alt="VCMS" border="0"></cml:a></center>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=5 alt="" border=0></td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>
)});



addlowobject({convertname=>1,upobjkey=>'CMSMENUADMIN',key=>'BASEMENUHEADER',name=>'������� ������ ��������� ����'});
setvalue({key=>'BASEMENUHEADER',pkey=>'PAGETEMPLATE',value=>qq(
<html>
<head>
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
<script language="javascript" type="text/javascript" src="/admin/js/ajax.js"></script>


</head>
<body bgcolor="#FFFFFF" text="#000000" link="#1E609C"  leftmargin="0" rightmargin="0" marginwidth="0" topmargin="0" marginheight="0">
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>

<center><a href="/admin/" target="_top"><img src="/cmsimg/design/topic_110x50.jpg" width="110" height="50" alt="VCMS" border="0"></a></center>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>


�������:
<cml:if expr='dev()'>
<a href="#" onclick="setCookie('dev','0');window.location.reload();return false"><img border='0' src='/cmsimg/save.gif' alt='������� ��������' title='������� ��������'/></a>
</cml:if>
<cml:else>
<a href="#" onclick="setCookie('dev','1');window.location.reload();return false"><img border='0' src='/cmsimg/delete.png' alt='������� ���������' title='������� ���������'/></a>
</cml:else>
<a href="/" target="_top">�� ����</a> 



<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=5 alt="" border=0></td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>
)});


addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMENUFOOTER',name=>'������� ������ ������� ����'});
setvalue({key=>'BASEMENUFOOTER',pkey=>'PAGETEMPLATE',value=>q(
</td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
</body>
</html>
)});



my $bm="
<CML:INCLUDE name='BASEMAINHEADER'/>
<CML:INCLUDE name='_prm:body_'/>
<CML:INCLUDE name='BASEMAINFOOTER'/>
";

addlowobject({convertname=>1,upobjkey=>'CMSFORMADMIN',key=>'BASEMAIN',name=>'������� ������ ������� ������'});
setvalue({key=>'BASEMAIN',pkey=>'PAGETEMPLATE',value=>$bm});

addlowobject({convertname=>1,upobjkey=>'CMSFORMUSER',key=>'USERMAIN',name=>'������ ��������'});
setvalue({key=>'USERMAIN',pkey=>'PAGETEMPLATE',value=>"<CML:INCLUDE name='BASEMAIN'/>"});

my $bmv=qq(<html>
<head>

<link rel="stylesheet" type="text/css" href="/css/admin.css" />
<link rel="stylesheet" type="text/css" href="/css/PopIt.css" />
<link rel="stylesheet" type="text/css" href="/css/calendar_date_select/red.css"  />
<script>
  var lbLabelImage="����";
  var lbLabelOf="��";
  var lbError="������";
  var lbSuccess="�����";
  var lbRequired="���������� ��������� ����";
  var lbDigit="������� �������� �������� � ����"; 
</script>

<script language="javascript" type="text/javascript" src="/js/base.js"></script>
<script language="javascript" type="text/javascript" src="/js/prototype.js"></script>
<script language="javascript" type="text/javascript" src="/js/flowplayer.js"></script>
<script language="javascript" type="text/javascript" src="/js/swfobject.js"></script>
<script language="javascript" type="text/javascript" src="/jscolor/jscolor.js"></script>
<script language="javascript" type="text/javascript" src="/js/scriptaculous.js?load=effects,builder,dragdrop" type="text/javascript"></script>
<script language="javascript" type="text/javascript" src='/js/PopIt.js'></script>
<script language="javascript" type="text/javascript" src="/js/calendar_date_select/calendar_date_select.js"></script>
<script language="javascript" type="text/javascript" src="/js/calendar_date_select/format_db_e.js"></script>
<script>
  _translations = {
    "OK": "OK",
    "Now": "������",
    "Today": "�������",
    "Clear": "��������" 
  };
  Date.weekdays = \$w("�� �� �� �� �� �� ��");
  Date.months = \$w("������ ������� ���� ������ ��� ���� ���� ������ �������� ������� ������ �������" );
</script>

<script language="javascript" type="text/javascript" src="/admin/js/ajax.js"></script>

<cml:include key='MCEINIT'/>
<cml:include key='INITHINTS'/>

</head>

<body bgcolor="#FFFFFF" text="#000000" link="#1E609C" leftmargin="0" rightmargin="0" marginwidth="0" topmargin="0" marginheight="0">



<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>

<center><cml:a href="_prm:_ROOT_/" target="_top"><img src="/cmsimg/design/topic_110x50.jpg" width="110" height="50" alt="VCMS" border="0"></cml:a></center>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=5 alt="" border=0></td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>);


addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMAINHEADER',name=>'������� ������ ��������� ������� ������'});
setvalue({key=>'BASEMAINHEADER',pkey=>'PAGETEMPLATE',value=>$bmv});

addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'INITHINTS',name=>'������������� ����������� ��������'});
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



addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'MCEINIT',name=>'������������� ����������� ���������'});
setvalue({convert=>1,key=>'MCEINIT',pkey=>'PAGETEMPLATE',value=>qq(
	    <script language="javascript" type="text/javascript" src="/tiny_mce/tiny_mce.js"></script>
        <script language="javascript" type="text/javascript" src="/admin/js/mce.js"></script>
        
    <script language="javascript" type="text/javascript">
    tinyMCE.init({  mode : "specific_textareas",
        editor_selector : "mceEditor",
        convert_urls : false,
        theme : "advanced", 
        theme_advanced_styles : "��� �����=imlink;��� �������������=noundlink", 
        plugins : "paste,fullscreen,table,style,advlink,advimage",
        theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontsizeselect,|,forecolor,backcolor,|,sub,sup,|,link,unlink,anchor,image,cleanup,help,code",
        theme_advanced_buttons2 : "fullscreen,|,styleprops,|,tablecontrols,|,hr,removeformat,visualaid,|,pastetext,pasteword,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo",
        theme_advanced_buttons3 : "",
        theme_advanced_toolbar_location : "top", 
        content_css : "/css/mce.css", 
        apply_source_formatting: true,
        extended_valid_elements : "div[id|style|class],img[onload|src|border|onmouseover|onmouseout|title|width|height|alt]",
        language : "ru" 
    
    });
</script>

)});

addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'MCEPHOTO',name=>'������� ���� � �������'});
setvalue({convert=>1,key=>'MCEPHOTO',pkey=>'PAGETEMPLATE',value=>qq(
<table><tr>
    <cml:list prm='PICLINKS'>
        <td><cml:deletebutton/><cml:a href='#' alt='_cml:_NAME_' onclick="javascript:insertimage('_global:FILEURL_/_cml:PIC_')"><cml:img border="0" prm='PIC' width="100"/></cml:a></td>
    </cml:list>
</tr></table>
<cml:form insertinto='_id:GALLERY_' link='PICLINK'>
     <cml:inputfile param='PIC'/>
     <input type='submit' value='����� ��������'>
</cml:form>
)});


addlowobject({convertname=>1,upobjkey=>'CMSINCLUDES',key=>'MCEFILES',name=>'������� ������ � �������'});
setvalue({convert=>1,key=>'MCEFILES',pkey=>'PAGETEMPLATE',value=>qq(
<table><tr>
    <cml:list prm='FILELINKS'>
        <td><cml:deletebutton/><cml:a href='#' alt='_cml:_NAME_' onclick="javascript:insertlink('_global:FILEURL_/_cml:ARCHIVEFILE_','_cml:_NAME_')"><cml:text prm='_NAME'/></cml:a></td>
    </cml:list>
</tr></table>
<cml:form insertinto='_id:FILEARCHIVE_' link='FILELINK'>
     ���  <cml:inputtext prm='_NAME'/> ���� <cml:inputfile param='ARCHIVEFILE'/>
     <input type='submit' value='����� ����'>
</cml:form>
)});



my $bmf=qq(
</td></tr></table>

<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
<script>  setCookie('_jsOK',1); </script>
</body>
</html>
);




addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMAINFOOTER',name=>'������� ������ ������� ������� ������'});
setvalue({convert=>1,key=>'BASEMAINFOOTER',pkey=>'PAGETEMPLATE',value=>$bmf});


$bm=qq(
<cml:use id='_prm:id_' key='_prm:ukey_'>
<cml:text param='_NAME'/><br>
<cml:form matrix='1' ukey='_prm:ukey_' listprm='_prm:listprm_' link='_prm:link_'>
<table>
<tr>
	<th></th>
	<th>�</th>
	<th>������������</th>
	<th></th>
</tr>
<cml:list expr='p("_prm:listprm_") || lowlist()' orderby='_prm:orderby_' ordertype='_prm:ordertype_'>
<tr>
<td><cml:deletebutton/></td>
<td><cml:inputtext param='_INDEX' value='_LISTINDEX'/></td>
<td><cml:inputtext param='_NAME'/></td>
<td><cml:actionlink action='EDITVIEW'/></td>
</tr>
</cml:list>
<tr><td/><td colspan=2><cml:changebutton/></td></tr>
</table>
</cml:form>
<hr>
<cml:actionlink action='add' upkey='_prm:ukey_' link='_prm:link_'>�������� �����</cml:actionlink>
</cml:use>
);
addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASELISTEDIT',name=>'������� ������ �������������� ������'});
setvalue({convert=>1,key=>'BASELISTEDIT',pkey=>'PAGETEMPLATE',value=>$bm});




addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEMENULIST',name=>'������� ������ ����'});
setvalue({convert=>1,key=>'BASEMENULIST',pkey=>'PAGETEMPLATE',value=>qq(
<cml:use id='_prm:id_'>
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<b><cml:actionlink action='LISTEDIT' ukey='_prm:ukey_' listprm="_prm:listprm_" link="_prm:link_"><cml:if value="_prm:listprm_"><cml:text prm='_NAME' key="_PP__prm:listprm_"/></cml:if><cml:else><cml:text param='_NAME'/></cml:else></cml:actionlink></b>
<cml:list  expr='p("_prm:listprm_") || lowlist()' orderby='_prm:orderby_' ordertype='_prm:ordertype_'>
  <cml:menuitem action="MENULIST" listprm="_prm:childlistprm_" ukey="_prm:childukey_" link="_prm:childlink_" delete="_cgi:!readonly_" templatekey='_cgi:templatekey_'/>
</cml:list>
</table>
<cml:if not='1' expr='cgi(readonly)'>
<hr/><cml:actionlink action='add' upkey='_prm:ukey_' link='_prm:link_'>�������� �����</cml:actionlink>
</cml:if>

<hr/>
<cml:a href='#' onclick='window.location.reload()'>��������</cml:a>
</cml:use>
)});


$ble=qq(
<cml:use id='_prm:id_'>

<cml:form parser='BASELPARSER'>
      <table>
          <tr><td>������������: </td><td><cml:text param='_NAME'/></b><br></td></tr>
          <tr><td>�����: </td><td><cml:inputtext prm='_prm:editprm_' class='mceEditor' textareaid='MCEDITOR'/></b><br>
          WYSIWIG<input type='checkbox' checked onClick="javascript:toggleEditor('MCEDITOR');"></a>
</td></tr>
        
          <tr><td colspan=2><cml:changebutton/></td></tr>

       </table>

</cml:form>
<hr>
<table><tr>
<cml:list prm='_prm:piclistprm_'>
<td>
<cml:a href='#' alt='_cml:_NAME_' onclick="javascript:insertimage('_global:FILEURL_/_cml:PIC_')"><cml:image param='PIC' width='100'/></cml:a> <br>
<cml:actionlink action='delete'>�������</cml:actionlink>
</td>
</cml:list>
</tr>
</table>





<cml:form insertinto='_id:GALLERY_' link='PICLINK'>
������������ <cml:inputtext param='_NAME' value=''/><br>
���� <cml:inputfile param='PIC'/>

<input type='submit' value='����� ��������'>
</cml:form>



<hr/>
<table><tr>
<cml:list prm='_prm:vidlistprm_'>
<td>
<cml:video/> <br>
<cml:a href='#' alt='_cml:_NAME_'  onclick="javascript:insertvideo('player_cml:_ID_','_global:FILEURL_/_cml:PIC_')">��������</cml:a> 
<cml:actionlink action='delete'>�������</cml:actionlink>
</td>
</cml:list>
</tr>
</table>





<cml:form insertinto='_id:VIDEOGALLERY_' link='VIDLINK'>
������������ <cml:inputtext param='_NAME' value=''/> <br/>
����� <cml:inputfile param='MOVIE'/> <br>
������ <cml:inputfile param='PIC'/><br>

<input type='submit' value='����� �����'>
</cml:form>



<hr>
<table><tr>
<cml:list prm='_prm:filelistprm_'>
<td>
<cml:a href='#' alt='_cml:_NAME_' onclick="javascript:insertlink('_global:FILEURL_/_cml:ARCHIVEFILE_','_CML:_NAME_')"><cml:text param='_NAME'/></cml:a> <br>
<cml:text param='ARCHIVEFILEDESCR'/><br>
<cml:actionlink action='delete'>�������</cml:actionlink>
</td>
</cml:list>
</tr>
</table>



<cml:form insertinto='_id:FILEARCHIVE_' link='FILELINK'>
������������ <cml:inputtext param='_NAME' value=''/> <br>
�������� <cml:inputtext param='ARCHIVEFILEDESCR' value=''/> <br>
<cml:inputfile param='ARCHIVEFILE'/>

<input type='submit' value='����� ����'>
</cml:form>

</cml:use>




);
addlowobject({convertname=>1,upobjkey=>'BASECMS',key=>'BASEARTICLE',name=>'������� ������ ������������� ������ � ������������'});
setvalue({key=>'BASEARTICLE',pkey=>'PAGETEMPLATE',value=>$ble,convert=>1});


addlowobject({convertname=>1,upobjkey=>'CMSMENUADMIN',key=>'CMSHEADMENU',name=>'����������� ����� �������� ����'});
setvalue({key=>'CMSHEADMENU',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<cml:menuitem action='MENULIST' key='ARTICLES'>������</cml:menuitem>
<cml:menuitem action='MENULIST' key='SECTIONS' childlink='SECLINK' childukey='ITEMS' childlistprm='POSITIONS'>�������</cml:menuitem>
<cml:menuitem action='LISTEDIT' key='SYSTEMUSERS_user'>���������� �������� ����������</cml:menuitem>
<cml:menuitem action='LISTEDIT' key='ERR404'>������ �������� �� �������</cml:menuitem>
</table>
</td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>
)});


addlowobject({convertname=>1,upobjkey=>'CMSMENUUSER',key=>'USERHEADMENU',name=>'����������� ����� �������� ���� ����������������� ����������'});
setvalue({key=>'USERHEADMENU',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<tr><td>...</td></tr>
</table>
</td></tr></table>
<img src="/i/0.gif" width=1 height=3 alt="" border=0><br>
<table width=100% bgcolor=#770000 cellspacing=3 cellpadding=0><tr align=left valign=middle><td class=atoptext><img src="/i/0.gif" width=1 height=10 alt="" border=0></td></tr></table>
<table width=100% cellspacing=10 cellpadding=0><tr align=left valign=top><td>
)});



addlowobject({convertname=>1,upobjkey=>'CMSMENUADMIN',key=>'CMSMAINMENU',name=>'������ �������� ����'});
setvalue({key=>'CMSMAINMENU',pkey=>'PAGETEMPLATE',convert=>1,value=>qq(
<cml:use key='ARTICLES'>
<b><cml:actionlink action='LISTEDIT' ukey='ARTICLES'><cml:text param='_NAME'/></cml:actionlink></b>
<table width="100%" border="0" cellspacing="1" cellpadding="2">
<cml:list expr='lowlist()'>
  <cml:menuitem action="MENULIST" delete="1"/>
</cml:list>
</table>
<hr/>
<cml:actionlink action='add'>�������� �����</cml:actionlink>
<hr/>
<cml:a href='#' onclick='window.location.reload()'>��������</cml:a>
</cml:use>
)});

my $addscript=q(
	
	my $newid;
	my $name=$CGIPARAM->{name} || '�����';
	if ($CGIPARAM->{upobj}) {   
			$newid=addlowobject({name=>$name,upobj=>$CGIPARAM->{upobj},up=>$CGIPARAM->{up}});
	} else {   
			$newid=addlowobject({name=>$name,upobj=>$CGIPARAM->{up}});
	}
	if ($CGIPARAM->{link}) {    
		my $lv=$CGIPARAM->{linkval}?$CGIPARAM->{linkval}:$CGIPARAM->{id};    
		setvalue ({id=>$newid,prm=>$CGIPARAM->{link},value=>$lv});
	}alert("����� ������ ������");
	
);
addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEADDMETHOD',name=>'������� ����� ����������',lflag=>1,script=>$addscript});
addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEADDMETHOD',name=>'������� ����� ����������',script=>$addscript});


addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEDELMETHOD',name=>'������� ����� ��������',script=>q(
	my $id=$CGIPARAM->{parseid} || $CGIPARAM->{id};
	deletelowobject($id);
	alert('������ ������');
)});
addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEDELMETHOD',name=>'������� ����� ��������',lflag=>1,script=>q(
	my $id=$CGIPARAM->{parseid} || $CGIPARAM->{id};
	deletelowobject($id);
	alert('������ ������');
)});

addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEDELPARAMMETHOD',name=>'������� ����� ������� ���������',lflag=>1,script=>q(
my $id=$CGIPARAM->{parseid}?$CGIPARAM->{parseid}:$CGIPARAM->{id};
setvalue({id=>$id,param=>$CGIPARAM->{prm},value=>\'\'});
alert('������');
)});



addmethod ({convertname=>1,convertscript=>1,objkey=>'BASECMS',key=>'BASEPARSER',name=>'������ ������ ���������',script=>q(
	my $id=$CGIPARAM->{id};
	update({id=>$id,name=>$CGIPARAM->{name},indx=>$CGIPARAM->{indx}});
	alert('���������� ��������');
)});


addmethod ({convertname=>1,objkey=>'BASECMS',key=>'BASELPARSER',name=>'����������',lflag=>1,script=>'baselparser()'});
addmethod ({convertname=>1,objkey=>'BASECMS',key=>'BASELPARSER',name=>'����������',script=>'baselparser()'});


addmethod ({convertname=>1,convertscript=>1,lflag=>1,objkey=>'BASECMS',key=>'BASESAVEMETHOD',name=>'������� ����� ���������� ���������',script=>q(
my $id=p(_ID);
set ($id,$CGIPARAM->{prm},$CGIPARAM->{value});
my $result;
$result->{'status'}=1;
$result->{'newvalue'}=$CGIPARAM->{value};
$result->{'prm'}=$CGIPARAM->{prm};
return $result;
)});


my $sscript='
my $name=$CGIPARAM->{name};
my $value=$CGIPARAM->{value};
$SETSITEVARS->{$name}=$value;
';
addmethod ({convertname=>1,objkey=>'BASECMS',key=>'BASESETVARMETHOD',name=>'��������� ���������� ����������',lflag=>1,script=>$sscript});


createcmsmethod({key=>'SECTIONS'},'listedittemplate');
createcmsmethod({key=>'ITEMS'},'listedittemplate');
createcmsmethod({key=>'SECTIONS'},'edittemplate');
createcmsmethod({key=>'ITEMS'},'edittemplate');


addobject({convertname=>1,upkey=>'STAT',key=>'STATCOUNTERS',name=>'��������'});
addobject({convertname=>1,upkey=>'STAT',key=>'CLICKS',name=>'�����'});

addprm({convertname=>1,objkey=>'CLICKS',name=>'URL',type=>'TEXT',key=>'CLURL',evl=>'n'});
addprm({convertname=>1,objkey=>'CLICKS',name=>'IP',type=>'TEXT',key=>'CLIP',evl=>'n'});
addprm({convertname=>1,objkey=>'CLICKS',name=>'�����',type=>'DATE',key=>'CLTIME',evl=>'n'});
addprm({convertname=>1,objkey=>'CLICKS',name=>'�������',type=>'LIST',key=>'CLLINK',evl=>'n'});


addobject({convertname=>1,upkey=>'STAT',key=>'ERRORS',name=>'������'});
addprm({convertname=>1,objkey=>'ERRORS',name=>'URL',type=>'TEXT',key=>'ERRORURL',evl=>'n'});
addprm({convertname=>1,objkey=>'ERRORS',name=>'IP',type=>'TEXT',key=>'ERRORIP',evl=>'n'});
addprm({convertname=>1,objkey=>'ERRORS',name=>'�������� ������',type=>'TEXT',key=>'ERRORPAGE',evl=>'n'});
addprm({convertname=>1,objkey=>'ERRORS',name=>'������',type=>'TEXT',key=>'ERRORMESSAGE',evl=>'n'});
addprm({convertname=>1,objkey=>'ERRORS',name=>'UserAgent',type=>'TEXT',key=>'ERRORUA',evl=>'n'});
addprm({convertname=>1,objkey=>'ERRORS',name=>'�����',type=>'DATE',key=>'ERRORTIME',evl=>'n'});
setprmextra({pkey=>'ERRORTIME',extra=>'format',value=>'%d.%m.%Y %H:%M:%S'});
addprm({convertname=>1,objkey=>'ERRORS',name=>'���������� �����',type=>'LONGTEXT',key=>'ERRORENV',evl=>'n'});
addobject({convertname=>1,upkey=>'ERRORS',key=>'JSERRORS',name=>'JS-������'});

addmethod ({convertname=>1,objkey=>'ERRORS',key=>'JSERROR',name=>'��������� js ������',,script=>q(
if ($CGIPARAM->{url}=~/^http/) {
	staterror("E:$CGIPARAM->{message} L:$CGIPARAM->{line}",$CGIPARAM->{url},$CGIPARAM->{ua},"JSERRORS");
	return {status=>1};
}	
)});

addobject({convertname=>1,upkey=>'ERRORS',key=>'ERR404',name=>'������ - �������� �� �������'});

addmethod ({convertname=>1,objkey=>'ERRORS',key=>'ERR404PARSER',name=>'���������� �������� �� �������',,script=>q(
staterror("$ENV{REQUEST_URI} - $ENV{HTTP_REFERER}",$ENV{REQUEST_URI},$ENV{HTTP_USER_AGENT},"ERR404");
return 1;
)});

alert(enc('��������� ������� �������'));

	
}

sub create_db ($$$;$)
{
	my ($db_name,$db_user,$db_password,$db_host)=@_;
	my $dbh=DBI->connect("DBI:mysql:mysql:$db_host",$db_user,$db_password) || die $DBI::errstr;
	$dbh->do("CREATE DATABASE $db_name") || die $dbh->errstr;
}

sub populate_db ($$$$;$)
{
	my ($db_file,$db_name,$db_user,$db_password,$db_host)=@_;
	my $hstr=$db_host?"-h$db_host":'';
	`gzip -d -c $db_file | mysql $hstr -u$db_user -p$db_password $db_name`;
}

sub create_db_user ($$$$$;$)
{
	my ($db_name,$admin_db_user,$admin_db_password,$db_user,$db_password,$db_host)=@_;
	my $dbh=DBI->connect("DBI:mysql:mysql:$db_host",$admin_db_user,$admin_db_password) || die $DBI::errstr;
	$db_host='localhost' unless $db_host;
	$dbh->do("GRANT ALL PRIVILEGES ON ${db_name}.* TO ${db_user}\@'$db_host' IDENTIFIED BY '${db_password}'") || die $dbh->errstr;
	$dbh->do("FLUSH PRIVILEGES") || die $dbh->errstr;		
}

sub unpack_file ($$)
{
	my ($fname,$dir)=@_;
    `tar -xzf $fname -C $dir`;	
}

sub create_config ($$)
{
	my ($cgidir,$attrs)=@_;
	open (CF,"<$cgidir/conf.template") || return (0,"cant open conf.template $!");
	my $cnf;
	read(CF,$cnf,-s "$cgidir/conf.template");
	return (0,'no conf.template') unless $cnf;
	close (CF);
	$cnf=~s/<thisdir>/$cgidir/g;
	
	$attrs->{UTF}=0 unless defined $attrs->{UTF};
	$attrs->{CACHE}=1 unless defined $attrs->{CACHE};
	$attrs->{MULTIDOMAIN}=0 unless defined $attrs->{MULTIDOMAIN};
	$attrs->{DBPREFIX}='' unless defined $attrs->{DBPREFIX};
	$attrs->{DBHOST}='localhost' unless defined $attrs->{DBHOST};
	
	$cnf=~s/<dbhost>/$attrs->{DBHOST}/g;
	$cnf=~s/<utf>/$attrs->{UTF}/g;
	$cnf=~s/<cache>/$attrs->{CACHE}/g;
	$cnf=~s/<multidomain>/$attrs->{MULTIDOMAIN}/g;
	$cnf=~s/<dbprefix>/$attrs->{DBPREFIX}/g;	
	
	
	return (0,'no attr DBNAME') unless $attrs->{DBNAME};
	$cnf=~s/<dbname>/$attrs->{DBNAME}/g;
	
	return (0,'no attr DBUSER') unless $attrs->{DBUSER};
	$cnf=~s/<dbuser>/$attrs->{DBUSER}/g;
	
	return (0,'no attr DBPASSWORD') unless $attrs->{DBPASSWORD};
	$cnf=~s/<dbpassword>/$attrs->{DBPASSWORD}/g;
	
	
	$cnf=~s/<domainname>/$attrs->{DOMAINNAME}/g;
	$cnf=~s/<abspath>/$attrs->{ABSPATH}/g;
	$cnf=~s/<rootpath>/$attrs->{ROOTPATH}/g;
	
	open (CW,">$cgidir/conf");
	print CW $cnf;
	close CW;
	return 1;
	
}



sub install_db ($$) {
	my ($dbh,$DBPREFIX)=@_;
	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}extraprm (
  			pkey varchar(255) NOT NULL default '',
  			extra varchar(100) NOT NULL default '',
  			value text,
  			PRIMARY KEY  (pkey,extra)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}links (
  			objid varchar(30) NOT NULL default '',
  			pkey varchar(100) NOT NULL default '',
  			vallink varchar(30) NOT NULL default '',
  			PRIMARY KEY  (objid,pkey,vallink),
  			KEY `vll` (`vallink`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}log (
  			session timestamp(14) NOT NULL,
  			dt datetime default NULL,
  			type varchar(50) default NULL,
  			message text
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}method (
  			id int(11) NOT NULL auto_increment,
  			pname varchar(255) default NULL,
  			objid int(11) default NULL,
  			pkey varchar(255) default NULL,
  			script text,
  			PRIMARY KEY  (id)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}lmethod (
  			`id` int(11) NOT NULL auto_increment,
  			`pname` varchar(255) default NULL,
  			`objid` int(11) default NULL,
  			`pkey` varchar(255) default NULL,
  			`script` text,
  			PRIMARY KEY  (`id`)
		) DEFAULT CHARSET=cp1251
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
		) DEFAULT CHARSET=cp1251
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
		) DEFAULT CHARSET=cp1251
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
		)DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}tvls (
  			id varchar(20) NOT NULL default '',
  			pkey varchar(50) NOT NULL default '',
  			vkey varchar(100) NOT NULL default '',
  			value mediumtext,
  			ptkey varchar(50) NOT NULL default '',
  			PRIMARY KEY  (id,pkey,ptkey,vkey)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}uvls (
  			`objid` int(11) NOT NULL default '0',
  			`pkey` varchar(255) NOT NULL default '',
  			`value` mediumtext,
  			`lang` varchar(20) NOT NULL default '',
  			PRIMARY KEY  (`objid`,`pkey`,`lang`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}vls (
  			`objid` int(11) NOT NULL default '0',
  			`pkey` varchar(255) NOT NULL default '',
  			`value` mediumtext,
  			`upobj` int(11) default NULL,
  			`lang` varchar(20) NOT NULL default '',
  			PRIMARY KEY  (`objid`,`pkey`,`lang`),
  			KEY `upobj` (`upobj`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();


	$dbh->do("CREATE TABLE IF NOT EXISTS ${DBPREFIX}vlshist (
	  		`objid` varchar(20) default NULL,
  			`pkey` varchar(255) default NULL,
  			`filename` varchar(255) default NULL,
  			`dt` datetime default NULL,
  			`ptype` varchar(255) default NULL,
  			`value` mediumtext,
  			`lang` varchar(20) default NULL,
  			KEY `objid` (`objid`),
  			KEY `pkey` (`pkey`),
  			KEY `ptype` (`ptype`),
  			KEY `lang` (`lang`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();

	$dbh->do("create table IF NOT EXISTS ${DBPREFIX}users (
 			`login` varchar(50) unique key,
 			`password` varchar(255),
 			`group` varchar(50),
 			`objid` int
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();

	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}fs (
  			`id` varchar(20) NOT NULL default '',
  			`prm` varchar(50) NOT NULL default '',
  			`val` varchar(500) default NULL,
  			`lang` varchar(5) NOT NULL default '',
  			PRIMARY KEY  (`id`,`prm`,`lang`),
  			KEY `val` (`val`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();


	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}fsint (
  			`id` varchar(20) NOT NULL default '',
  			`prm` varchar(50) NOT NULL default '',
  			`val` integer default 0,
  			`lang` varchar(5) NOT NULL default '',
  			PRIMARY KEY  (`id`,`prm`,`lang`),
  			KEY `val` (`val`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();
	
	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}pagescache (
 			`cachekey` varchar(950) NOT NULL default '',
  			`pagetext` mediumtext,
  			`ts` datetime default NULL,
  			`objid` int(11) NOT NULL default '0',
  			`dev` int(11) NOT NULL default '0',
  			`lang` varchar(20) NOT NULL default '',
  			PRIMARY KEY  (`cachekey`,`dev`,`lang`)
  		) DEFAULT CHARSET=cp1251
  	") || die $dbh->errstr();
	
	$dbh->do("
		 CREATE TABLE IF NOT EXISTS ${DBPREFIX}linkscache (
  			`cachekey` varchar(950) NOT NULL default '',
  			`objlink` varchar(12) NOT NULL default '',
  			`dev` int(11) NOT NULL default '0',
  			`lang` varchar(20) NOT NULL default '',
  			PRIMARY KEY  (`cachekey`,`objlink`,`dev`,`lang`),
  			KEY `ol` (`objlink`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();
	
	$dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}captcha (
  			`id` int(11) NOT NULL AUTO_INCREMENT,
  			`ckey` int(11) NOT NULL,
  			`tm` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  			PRIMARY KEY (`id`),
  			KEY `ck` (`ckey`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();
    $dbh->do("
		CREATE TABLE IF NOT EXISTS ${DBPREFIX}auth (
   			`login` varchar(50)  NOT NULL,
  			`pwd` char(32) NOT NULL,
  			`flag` int(11) NOT NULL default '0',
  			`objid` int(11) NOT NULL,
  			`scookie` varchar(50),
  			`authtime` datetime,
  			PRIMARY KEY  (`login`),
  			UNIQUE KEY `objid` (`objid`)
		) DEFAULT CHARSET=cp1251
	") || die $dbh->errstr();
}

return 1;

END {}