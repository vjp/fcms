#!/usr/bin/perl -w

# $Id: install.pl,v 1.4 2010-02-21 20:07:26 vano Exp $

use lib "modules/";
use strict;
use CGI  qw/:standard *Tr *table *td code/;
use Data::Dumper;
use CGI::Carp qw /fatalsToBrowser/;
use DBI;


use vars qw ($DBHOST $DBPREFIX $DBNAME $DBPASSWORD $DBUSER $DOMAINNAME $ABSPATH $ROOTPATH);
 

print "Content-Type: text/html; charset=windows-1251\n\n";
print qq(
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<body>
);

if (param('install')) {
	if (-s 'conf') {
		print "������ ���� ������������, ���������� � ������������� �� �����",br();
	} else {
		$DBNAME=param('dbname');
		$DBHOST=param('dbhost');
		$DBUSER=param('dbuser');
		$DBPASSWORD=param('dbpassword');
		$DBPREFIX=param('dbprefix');
		$DOMAINNAME=param('domainname');
		$ABSPATH=param('abspath');		
		$ROOTPATH=param('rootpath');
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
				chmod (0755, 'admin/admin.pl');
				chmod (0755, 'user/user.pl');
				chmod (0755, 'vcms/autorun.pl');
				chmod (0755, 'vcms/cmlsrv.pl');
				chmod (0755, 'vcms/ajax.pl');
				
			}
		}
		if (param('dbname')) {
			print '��������� ����������� � ��...',br();
			my $dbh=DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$DBUSER,$DBPASSWORD);
			if (!$dbh) {
				print "...������ ����������� � ��  [DBI:mysql:$DBNAME:$DBHOST\@$DBUSER]:".$DBI::errstr;
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
					if (! -s "${ROOTPATH}.htaccess") {
						print "...���������� ���������:$str",br();
					} else {
						print "...���������� �������",br();
						system "rm html.tar.gz";
					}
				}	
			} else {
				print '...������� ���� �� �������',br();
			}
		}
			
		if (-s 'conf.template') {
			print "�������� ����������������� �����...",br();
			open (CF,'<conf.template');
			my $cnf;
			read(CF,$cnf,-s 'conf.template');
			if (!$cnf) {
				print "... �������� ������ ����������������� �������",br();
			} else {
				$cnf=~s/<dbname>/$DBNAME/g;
				$cnf=~s/<dbuser>/$DBUSER/g;
				$cnf=~s/<dbpassword>/$DBPASSWORD/g;
				$cnf=~s/<dbhost>/$DBHOST/g;
				$cnf=~s/<dbprefix>/$DBPREFIX/g;
				$cnf=~s/<domainname>/$DOMAINNAME/g;
				$cnf=~s/<abspath>/$ABSPATH/g;
				$cnf=~s/<rootpath>/$ROOTPATH/g;
			}	
			close CF;
			open (CFF,'>conf');
			print CFF $cnf;
			close CFF;
			print "...������������ �������";	
		} else {
			print "������ ����������������� ����� �� ������",br();
		}
	}
	print hr();
	print '<a href="?createdb=1">������� ��</a>';
	
	print hr();
	exit;
} elsif (param('createdb')) {
	eval {
		require cmlinstall;
		require cmlmain;
		do "conf" || die $!;
		$DBHOST='localhost' unless $DBHOST;
		$DBPREFIX.='_' if $DBPREFIX;
		my $dbh=DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$DBUSER,$DBPASSWORD) || die $DBI::errstr;
		print "������� �� ...",br;
		&cmlinstall::install_db($dbh,$DBPREFIX);
		print "... ��������� �� �������",br;
	
		print "������� ������� ���������...",br;
		&cmlmain::start('.');
		&cmlinstall::install_structure();
	
	
	};
	if ($@) {
		print "<br/>������ �������� ��: $@<br>";
	}
	print '<a href="/vcms">������� � ����������������</a>';
	exit();
		
}

my $path=`pwd`;
$path=~s/cgi-bin\s*//s;


print qq(
<form method='post'>
<table>
  <tr><td>���� ��</td><td><input size='100' name='dbhost'><td></td></tr>
  <tr><td>��� ��</td><td><input size='100' name='dbname'><td></td></tr>
  <tr><td>������������ ��</td><td><input size='100' name='dbuser'><td></td></tr>
  <tr><td>������ ��</td><td><input size='100' type='password' name='dbpassword'><td></td></tr>
  <tr><td>������� ������ ��</td><td><input size='100' name='dbprefix'><td></td></tr>
  <tr><td>��� ������</td><td><input  size='100' name='domainname' value='$ENV{SERVER_NAME}'><td></td></tr>
  <tr><td>���� � ������ ����� � �������</td><td><input size='100' name='abspath' value='$path'><td></td></tr>
  <tr><td>���� � �������� ����������</td><td><input size='100' name='rootpath' value='${path}www/'><td></td></tr>    
</table>
<input type='submit' name='install' value='������ ���������'/>
</form>
</body>
</html> 
);
exit;














