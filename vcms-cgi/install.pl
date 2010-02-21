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
		print "Найден файл конфигурации, распаковки и перенастройки не будет",br();
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
			print "Файл cgi.tar.gz не найден",br();
		} else {
			print "Произвожу распаковку архива cgi.tar.gz...",br();
			my $str=`tar -xzf cgi.tar.gz`;
			if (! -s 'conf.template') {
				print "...Распаковка неудачная :$str",br();
			} else {
				print "...Распаковка удачная",br();
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
			print 'Произвожу подключение к БД...',br();
			my $dbh=DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$DBUSER,$DBPASSWORD);
			if (!$dbh) {
				print "...Ошибка подключения к БД  [DBI:mysql:$DBNAME:$DBHOST\@$DBUSER]:".$DBI::errstr;
			} else {
			        print '...Подключение к БД успешно...',br();	
			}
		}
		if (param('abspath')) {
			print "Проверка доступности директории для создания файла паролей  ($ABSPATH)  ...",br();
			open (FT,">$ABSPATH/.test") || print "Open file error :$!",br();
			print FT 'test';
			close FT || print "Close file error $!",br();
			open (FT,"<$ABSPATH/.test");
			my $tstr=<FT>;
			close FT;
			if ($tstr eq 'test') {
				print '...Директория доступна',br();
			} else {
				print '...Создать файл не удалось',br();
			}
		}
		if (param('rootpath')) {
			print "Проверка доступности директории для распаковки шаблонов ($ROOTPATH)...",br();
			open (FT,">$ROOTPATH/.test") || print "Open file error :$!",br();
			print FT 'test';
			close FT || print "Close file error $!",br();
			open (FT,"<$ROOTPATH/.test");
			my $tstr=<FT>;
			close FT;
			if ($tstr eq 'test') {
				print '...Директория доступна',br();
				if (! -s 'html.tar.gz') {
					print "Файл html.tar.gz не найден",br();
				} else {
					print "Произвожу распаковку архива html.tar.gz...",br();
					my $str=`tar -xzf html.tar.gz -C $ROOTPATH`;
					if (! -s "${ROOTPATH}.htaccess") {
						print "...Распаковка неудачная:$str",br();
					} else {
						print "...Распаковка удачная",br();
						system "rm html.tar.gz";
					}
				}	
			} else {
				print '...Создать файл не удалось',br();
			}
		}
			
		if (-s 'conf.template') {
			print "Создание конфигурационного файла...",br();
			open (CF,'<conf.template');
			my $cnf;
			read(CF,$cnf,-s 'conf.template');
			if (!$cnf) {
				print "... Проблема чтения конфигруационного шаблона",br();
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
			print "...Конфигурация создана";	
		} else {
			print "Шаблон конфигурационного файла не найден",br();
		}
	}
	print hr();
	print '<a href="?createdb=1">Создать БД</a>';
	
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
		print "Создаем бд ...",br;
		&cmlinstall::install_db($dbh,$DBPREFIX);
		print "... структура бд создана",br;
	
		print "Создаем базовые структуры...",br;
		&cmlmain::start('.');
		&cmlinstall::install_structure();
	
	
	};
	if ($@) {
		print "<br/>Ошибка создания БД: $@<br>";
	}
	print '<a href="/vcms">Перейти к конфигурированию</a>';
	exit();
		
}

my $path=`pwd`;
$path=~s/cgi-bin\s*//s;


print qq(
<form method='post'>
<table>
  <tr><td>Хост БД</td><td><input size='100' name='dbhost'><td></td></tr>
  <tr><td>Имя БД</td><td><input size='100' name='dbname'><td></td></tr>
  <tr><td>Пользователь БД</td><td><input size='100' name='dbuser'><td></td></tr>
  <tr><td>Пароль БД</td><td><input size='100' type='password' name='dbpassword'><td></td></tr>
  <tr><td>Префикс таблиц БД</td><td><input size='100' name='dbprefix'><td></td></tr>
  <tr><td>Имя домена</td><td><input  size='100' name='domainname' value='$ENV{SERVER_NAME}'><td></td></tr>
  <tr><td>Путь к файлам групп и паролей</td><td><input size='100' name='abspath' value='$path'><td></td></tr>
  <tr><td>Путь к корневой директории</td><td><input size='100' name='rootpath' value='${path}www/'><td></td></tr>    
</table>
<input type='submit' name='install' value='начать установку'/>
</form>
</body>
</html> 
);
exit;














