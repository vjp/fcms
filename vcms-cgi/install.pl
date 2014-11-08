#!/usr/bin/perl


use lib "modules/";
use strict;
use CGI  qw/:standard *Tr *table *td code/;
use Data::Dumper;
use CGI::Carp qw /fatalsToBrowser/;
use DBI;
use Cwd;
use Encode;


use vars qw ($DBHOST $DBPREFIX $DBNAME $DBPASSWORD $DBUSER $DOMAINNAME $ABSPATH $ROOTPATH $UTF $CACHE $MULTIDOMAIN);
 

print "Content-Type: text/html; charset=windows-1251\n\n";
print qq(
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<body>
);

if (param('install')) {
	$DBNAME=param('dbname');
	$DBHOST=param('dbhost');
	$DBUSER=param('dbuser');
	$DBPASSWORD=param('dbpassword');
	$DBPREFIX=param('dbprefix');
	$DOMAINNAME=param('domainname');
	$ABSPATH=param('abspath');
	$UTF=0+param('utf');
	$CACHE=0+param('cache');		
	$ROOTPATH=param('rootpath');
	$MULTIDOMAIN=0+param('multidomain');
	
	if (! -s 'cgi.tar.gz') {
		print "���� cgi.tar.gz �� ������",br();
	} else {
		print "��������� ���������� ������ cgi.tar.gz...",br();
		my $str=`tar -xzf cgi.tar.gz`;
		if (! -s 'conf.template') {
			print "...���������� ��������� :$str",br();
		} else {
			print "...���������� �������",br();
			system "rm cgi.tar.gz";
			chmod (0755, 'viewer.pl');
			chmod (0755, 'ajax-json.pl');
			chmod (0755, 'stat.pl');			
			chmod (0755, 'admin/admin.pl');
			chmod (0755, 'admin/ajax-json.pl');
			chmod (0755, 'user/user.pl');
			chmod (0755, 'gate/gate.pl');
			chmod (0755, 'vcms/autorun.pl');
			chmod (0755, 'vcms/asyncprocessor.pl');
			chmod (0755, 'vcms/cmlsrv.pl');
			chmod (0755, 'vcms/ajax.pl');
			chmod (0755, 'vcms/ajax-json.pl');
		}
	}
	
	if (param('dbname')) {
		print '��������� ����������� � ��...',br();
		my $dbh=DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$DBUSER,$DBPASSWORD);
		if (!$dbh) {
			print "...������ ����������� � ��  [DBI:mysql:$DBNAME:$DBHOST\@$DBUSER]:".$DBI::errstr;
			exit();
		} else {
	        print '...����������� � �� �������...',br();	
		}
	}
	if (param('abspath')) {
		print "�������� ����������� ���������� ��� �������� ����� �������  ($ABSPATH)  ...",br();
		open (FT,">$ABSPATH/.test") || print "Open file error :$!",br();
		print FT 'test';
		close FT || print "Close file error $!",br();
		open (FT,"<$ABSPATH/.test");
		my $tstr=<FT>;
		close FT;
		if ($tstr eq 'test') {
			print '...���������� ��������',br();
		} else {
				print '...������� ���� �� �������',br();
		}
	}
	
	if (param('rootpath')) {
		print "�������� ����������� ���������� ��� ���������� �������� ($ROOTPATH)...",br();
		open (FT,">$ROOTPATH/.test") || print "Open file error :$!",br();
		print FT 'test';
		close FT || print "Close file error $!",br();
		open (FT,"<$ROOTPATH/.test");
		my $tstr=<FT>;
		close FT;
		if ($tstr eq 'test') {
			print '...���������� ��������',br();
			if (! -s 'html.tar.gz') {
				print "���� html.tar.gz �� ������",br();
			} else {
				print "��������� ���������� ������ html.tar.gz...",br();
				my $str=`tar -xzf html.tar.gz -C $ROOTPATH`;
				if (! -s "${ROOTPATH}/.htaccess") {
					print "...���������� ���������:$str",br();
				} else {
					print "...���������� �������",br();
					system "rm html.tar.gz";
				}
			}	
			
			if (-s 'docs.tar.gz' && -s "${ROOTPATH}/.htaccess") {
				print "������ ����� �������, �������������...";
				my $str=`tar -xzf docs.tar.gz -C $ROOTPATH`;
				print "...OK",br();
				system "rm docs.tar.gz";
			}
			
			if (-s 'data.tar.gz' && -e "${ROOTPATH}/data") {
				print "������ ����� ��������, �������������...";
				my $str=`tar -xzf data.tar.gz -C $ROOTPATH/data`;
				print "...OK",br();
				system "rm data.tar.gz";
			}
			
			
		} else {
			print '...������� ���� �� �������',br();
		}
	}
			
	if ( -s 'conf.template') {
		print "�������� ����������������� �����...",br();
		open (CF,'<conf.template');
		my $cnf;
		read(CF,$cnf,-s 'conf.template');
		if (!$cnf) {
			print "... �������� ������ ����������������� �������",br();
		} else {
			my $path=getcwd();
			chomp $path;
			$cnf=~s/<dbname>/$DBNAME/g;
			$cnf=~s/<dbuser>/$DBUSER/g;
			$cnf=~s/<dbpassword>/$DBPASSWORD/g;
			$cnf=~s/<dbhost>/$DBHOST/g;
			$cnf=~s/<dbprefix>/$DBPREFIX/g;
			$cnf=~s/<domainname>/$DOMAINNAME/g;
			$cnf=~s/<abspath>/$ABSPATH/g;
			$cnf=~s/<rootpath>/$ROOTPATH/g;
			$cnf=~s/<thisdir>/$path/g;
			$cnf=~s/<utf>/$UTF/g;
			$cnf=~s/<cache>/$CACHE/g;
			$cnf=~s/<multidomain>/$MULTIDOMAIN/g;
		}	
		close CF;
		
		$cnf=Encode::encode('utf-8',Encode::decode('windows-1251',$cnf)) if $UTF; 
		
		open (CFF,'>conf');
		print CFF $cnf;
		close CFF;
		print "...������������ �������";	
	} else {
		print "������ ����������������� ����� �� ������",br();
	}

	print hr();
	print '<a href="?createdb=1">������� ��</a>',br();
	print '<a href="/vcms">������� � ����������������</a>';
	
	print hr();
	exit;
} elsif (param('createdb')) {
	eval {
		require cmlinstall;
		require cmlmain;
		do "conf";
		$DBHOST='localhost' unless $DBHOST;
		$DBPREFIX.='_' if $DBPREFIX;
		my $dbh=DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$DBUSER,$DBPASSWORD) || die $DBI::errstr;
		print "������� �� ...",br;
		&cmlinstall::install_db($dbh,$DBPREFIX);
		print "... ��������� �� �������",br;

	    if (-s 'db.gz') {
	    	print "����������� ������ �� ������...";
	    	`gzip -d -c db.gz | mysql -h$DBHOST -u$DBUSER -p$DBPASSWORD $DBNAME`;
	    	print "OK",br();
	    	system "rm db.gz"; 
	    } else {
			print "������� ������� ���������...",br;
			&cmlmain::start('.');
			&cmlinstall::install_structure();
	    }	
	
	
	};
	if ($@) {
		print "<br/>������ �������� ��: $@<br>";
	}
	print '<a href="/vcms">������� � ����������������</a>';
	exit();
		
}

my $path=getcwd();
$path=~s/cgi-bin\s*//s;

my $wpath="${path}www/";
$wpath=$path unless -s $wpath;

chomp $path;
chomp $wpath;

print qq(
<form method='post'>
<table>
  <tr><td>���� ��</td><td><input size='100' name='dbhost'></td></tr>
  <tr><td>��� ��</td><td><input size='100' name='dbname'></td></tr>
  <tr><td>������������ ��</td><td><input size='100' name='dbuser'></td></tr>
  <tr><td>������ ��</td><td><input size='100' type='password' name='dbpassword'></td></tr>
  <tr><td>������� ������ ��</td><td><input size='100' name='dbprefix'></td></tr>
  <tr><td>��� ������</td><td><input  size='100' name='domainname' value='$ENV{SERVER_NAME}'></td></tr>
  <tr><td>���� � ������ ����� � �������</td><td><input size='100' name='abspath' value='$path'></td></tr>
  <tr><td>���� � �������� ���������� (WWWROOT)</td><td><input size='100' name='rootpath' value='$wpath'></td></tr>
  <tr><td>Unicode (UTF8)</td><td><input type='checkbox' name='utf' value='1'  checked='checked'></td></tr>
  <tr><td>�����������</td><td><input type='checkbox' name='cache' value='1' checked='checked'></td></tr>
  <tr><td>�����������</td><td><input type='checkbox' name='multidomain' value='1'></td></tr>  
  <tr><td>����������</td>
  	<td>
  		/     <input type='checkbox' name='i_site' value='1' checked='checked'>
  		/vcms <input type='checkbox' name='i_vcms' value='1' checked='checked'>
  		/admin <input type='checkbox' name='i_admin' value='1' checked='checked'>
  		/user <input type='checkbox' name='i_user' value='1' checked='checked'>
  	</td>
  </tr>  
</table>
<input type='submit' name='install' value='������ ���������'/>
</form>
</body>
</html> 
);
exit;














