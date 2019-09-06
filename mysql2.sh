#!/bin/bash
#
#***********************************************************
#Author:                Jibill Chen
#QQ:                    417060833
#Date:                  2019-07-03
#FileName：             mysql.sh
#URL:                   http://www.jibiao.work
#Description：          The test script
#**********************************************************
###准备二进制程序
set -e
cd
wget http://172.16.23.100/mysql/mariadb-10.2.25-linux-x86_64.tar.gz
[ $? -ne 0 ] && exit
tar xf mariadb-10.2.25-linux-x86_64.tar.gz -C /usr/local
cd /usr/local
###创建软连接
ln -s mariadb-10.2.25-linux-x86_64 mysql
####准备用户
groupadd -r -g 306 mysql
useradd -r -g 306 -u 306 -d /data/mysql -s /sbin/nologin mysql
                
###更改权限
chown -R root:mysql /usr/local/mysql/


####准备数据目录，建议使用逻辑卷
mkdir -p /data/mysql
chown -R mysql:mysql /data/mysql

#创建数据库文件
cd /usr/local/mysql/
yum -y install libaio
scripts/mysql_install_db --user=mysql --datadir=/data/mysql


#准备配置文件
mkdir /etc/mysql/
cp support-files/my-huge.cnf /etc/mysql/my.cnf

#中添加三个选项：
sed -i '/mysqld/s#$#\ndatadir = /data/mysql\ninnodb_file_per_table = on\nskip_name_resolve = on #' /etc/mysql/my.cnf


#准备服务脚本，并启动服务
cd /usr/local/mysql
cp ./support-files/mysql.server /etc/rc.d/init.d/mysqld
chkconfig --add mysqld
service mysqld start

#PATH路径
echo PATH='/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh

#安全初始化
echo -e "\ny\ncentos\ncentos\ny\ny\ny\ny\n" | /usr/local/mysql/bin/mysql_secure_installation

echo "your username:root"
echo "your password:centos"
