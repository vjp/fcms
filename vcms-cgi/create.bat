del cgi.tar.gz
7za a cgi.tar *.pm -r
7za a cgi.tar *.pl -r
7za a cgi.tar *.ttf -r
7za a cgi.tar conf.template
7za a cgi.tar.gz cgi.tar
del cgi.tar   

cd ..\vcms-htdocs
del html.tar.gz
..\vcms-cgi\7za a html.tar *.htm -r
..\vcms-cgi\7za a html.tar *.gif -r
..\vcms-cgi\7za a html.tar *.jpg -r
..\vcms-cgi\7za a html.tar *.png -r
..\vcms-cgi\7za a html.tar *.gif -r
..\vcms-cgi\7za a html.tar *.css -r
..\vcms-cgi\7za a html.tar *.tgz -r
..\vcms-cgi\7za a html.tar *.swf -r
..\vcms-cgi\7za a html.tar *.js  -r
..\vcms-cgi\7za a html.tar *.ico -r
..\vcms-cgi\7za a html.tar .htaccess -r
..\vcms-cgi\7za a html.tar robots.txt -r
..\vcms-cgi\7za a ..\vcms-cgi\html.tar.gz html.tar
del html.tar   

