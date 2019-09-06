#!/bin/bash

install_discuz(){
cd
wget ftp://192.168.99.1/Magedu37/files/lamp/Discuz_X3.3_SC_UTF8.zip
yum install -y unzip
unzip  Discuz_X3.3_SC_UTF8.zip
mkdir -p /data/httpd24/htdocs/discuz/
mv upload/* /data/httpd24/htdocs/discuz/
chown -R apache.apache /data/httpd24/htdocs/discuz
}

install_discuz