rm cgi.tar.gz
tar -czvf cgi.tar.gz `find -E . -regex '.*(\.pm|\.pl|\.ttf|conf\.template)$'`
cd  ../vcms-htdocs
rm ../vcms-cgi/html.tar.gz
tar -czvf ../vcms-cgi/html.tar.gz `find -E . -regex '.*(\.htm|\.gif|\.jpg|\.map|\.png|\.css|\.tgz|\.swf|\.js|\.ico|\.eot|\.svg|\.ttf|\.woff|\.woff2|\.otf|\.htaccess|robots\.txt)$'`

