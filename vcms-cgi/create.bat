del cgi.tar.gz
7za a cgi.tar *.pm -r
7za a cgi.tar *.pl -r
7za a cgi.tar conf.template
7za a cgi.tar.gz cgi.tar
del cgi.tar   

cd ..\vcms-htdocs
del html.tar.gz
7za a html.tar *.htm -r
7za a html.tar *.gif -r
7za a html.tar *.jpg -r
7za a html.tar *.png -r
7za a html.tar *.gif -r
7za a html.tar *.css -r
7za a html.tar *.tgz -r
7za a html.tar *.swf -r
7za a html.tar *.js -r
7za a html.tar .htaccess -r
7za a html.tar.gz html.tar
del html.tar   
move html.tar.gz ..\vcms-cgi-bin
