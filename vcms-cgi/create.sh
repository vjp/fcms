del cgi.tar.gz
tar -czvf cgi.tar.gz `find -E . -regex '.*(\.pm|\.pl|\.ttf|conf\.template)$'`
cd ../vcms-htdocs
del html.tar.gz
tar -czvf html.tar.gz `find -E . -regex '.*(\.htm|\.gif|\.jpg|\.png|\.css|\.tgz|\.swf|\.js|\.ico|\.htaccess|robots\.txt)$'`

