#!/bin/bash

install_wordpress(){
cd
wget ftp://192.168.99.1/Magedu37/files/lamp/wordpress-5.2.2.tar.gz
tar xf wordpress-5.2.2.tar.gz
mkdir -p /data/httpd24/htdocs/wordpress/
mv wordpress/* /data/httpd24/htdocs/wordpress/
chown -R apache.apache /data/httpd24/htdocs/wordpress
}


install_wordpress
