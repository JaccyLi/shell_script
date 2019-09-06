#!/bin/bash
install_apache(){
cd
wget ftp://192.168.99.1/Magedu37/files/lamp/apr-1.7.0.tar.bz2
wget ftp://192.168.99.1/Magedu37/files/lamp/apr-util-1.6.1.tar.bz2
wget ftp://192.168.99.1/Magedu37/files/lamp/httpd-2.4.39.tar.bz2
yum -y install gcc pcre-devel openssl-devel expat-devel autoconf libtool gcc-c++
tar xf apr-util-1.6.1.tar.bz2 
tar xf apr-1.7.0.tar.bz2  
tar xf httpd-2.4.39.tar.bz2
cp -r apr-1.7.0 httpd-2.4.39/srclib/apr   
cp -r apr-util-1.6.1 httpd-2.4.39/srclib/apr-util 
cd httpd-2.4.39
./configure --prefix=/data/httpd24 --enable-so --enable-ssl --enable-cgi --enable-rewrite --with-zlib --with-pcre --with-included-apr --enable-modules=most --enable-mpms-shared=all --with-mpm=prefork
make && make install
echo 'PATH=/data/httpd24/bin:$PATH' > /etc/profile.d/httpd24.sh
source /etc/profile.d/httpd24.sh
useradd -r -s /sbin/nologin apache
sed -i '/LoadModule proxy_module/s@^#@@' /data/httpd24/conf/httpd.conf
sed -i '/LoadModule proxy_fcgi_module/s@^#@@' /data/httpd24/conf/httpd.conf
sed -i '/User/s#^.*$#User apache#' /data/httpd24/conf/httpd.conf
sed -i '/Group/s#^.*$#Group apache#' /data/httpd24/conf/httpd.conf
sed -i '/^[ ]*DirectoryIndex/s#^.*$#DirectoryIndex index.php index.html#' /data/httpd24/conf/httpd.conf
echo "ProxyRequests off" >> /data/httpd24/conf/httpd.conf
echo "ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/data/httpd24/htdocs/" >> /data/httpd24/conf/httpd.conf
echo "AddType application/x-httpd-php .php" >> /data/httpd24/conf/httpd.conf
echo "AddType application/x-httpd-php-source .phps" >> /data/httpd24/conf/httpd.conf

echo "<? phpinfo(); ?>" > /data/httpd24/htdocs/index.php

touch /usr/lib/systemd/system/httpd24.service
cat > /usr/lib/systemd/system/httpd24.service << EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=forking
ExecStart = /data/httpd24/bin/httpd $OPTIONS -k start
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

systemctl start httpd24
}

install_php(){
cd
yum -y install libxml2-devel bzip2-devel libmcrypt-devel
wget ftp://192.168.99.1/Magedu37/files/lamp/php-7.3.5.tar.bz2
tar xf php-7.3.5.tar.bz2
cd php-7.3.5/
./configure --prefix=/data/php --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-openssl --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --enable-mbstring --enable-xml --enable-sockets --enable-fpm --enable-maintainer-zts --disable-fileinfo
make && make install
cp php.ini-production /data/php/etc/php.ini
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig php-fpm on
cd /data/php/etc
cp php-fpm.conf.default php-fpm.conf
cp php-fpm.d/www.conf.default php-fpm.d/www.conf
sed -i '/user/s#nobody#apache#'  php-fpm.d/www.conf
sed -i '/group/s#nobody#apache#'  php-fpm.d/www.conf
service php-fpm start
}
install_apache
install_php