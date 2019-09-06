#!/bin/bash

install_phpmyadmin(){
cd /data/httpd24/htdocs
wget ftp://192.168.99.1/Magedu37/files/lamp/phpMyAdmin-4.0.10.20-all-languages.tar.xz
tar xvf phpMyAdmin-4.0.10.20-all-languages.tar.xz 
mv phpMyAdmin-4.0.10.20-all-languages phpmyadmin
rm -f phpMyAdmin-4.0.10.20-all-languages.tar.xz 
cd phpmyadmin
cp config.sample.inc.php config.inc.php
sed -r -i "/cfg\['blowfish_secret/s#(= ')(.*)(')#\1centos\3#" config.inc.php

}
install_phpmyadmin