#!/bin/bash
######初始化你的数据######
read -p "输入你的数据库密码" MYSQL_PASSWD
##########################


gecho() {
	echo -e "\e[1;32m${1}\e[0m" && sleep 1
}
recho() {
	echo -e "\e[1;31m${1}\e[0m" && sleep 1
}
gecho "安装数据库..."
yum -y install  mariadb mariadb-server 

gecho "mysql配置文件..."
cat > /etc/my.cnf.d/openstack.cnf <<EOF
[mysqld]
bind-address = 192.168.99.106
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

systemctl enable mariadb.service
systemctl restart mariadb.service || recho "启动mysql失败..."

gecho "mysql安全加固..."
echo -e "\ny\n${MYSQL_PASSWD}\n${MYSQL_PASSWD}\ny\ny\ny\ny" | mysql_secure_installation

gecho "安装memcached..."
yum -y install memcached python-memcached

sed -i '/OPTIONS/s#""#"-l 192.168.99.106"#' /etc/sysconfig/memcached

systemctl enable memcached.service
systemctl restart memcached.service  || recho "memcached启动失败..."

gecho "安装rabbit..."
yum -y install rabbitmq-server
systemctl enable rabbitmq-server
systemctl restart rabbitmq-server || recho "rabbit启动失败..."
rabbitmqctl add_user openstack 123
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
rabbitmq-plugins enable rabbitmq_management

mysql -uroot -p${MYSQL_PASSWD} -e "create database keystone;"
mysql -uroot -p${MYSQL_PASSWD} -e "grant all on keystone.* to keystone@'%' identified by '123';"