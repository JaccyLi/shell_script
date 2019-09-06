#!/bin/bash
######初始化你的数据######
read -p "输入你的控制端的IP: " controller_ip
##########################


gecho() {
	echo -e "\e[1;32m${1}\e[0m" && sleep 1
}
recho() {
	echo -e "\e[1;31m${1}\e[0m" && sleep 1
}

gecho "安装keepalived..."
yum -y install keepalived haproxy
sed -i '/virtual_server/,$d' /etc/keepalived/keepalived.conf
sed -i '/smtp_server/s#.*#    smtp_server 127.0.0.1#' /etc/keepalived/keepalived.conf
sed -i '/192.168.200/d' /etc/keepalived/keepalived.conf
sed -i '/virtual_ipaddress/s#$#\n\t192.168.99.211#' /etc/keepalived/keepalived.conf
sed -i '/vrrp_skip/s#$#\n   vrrp_iptables#' /etc/keepalived/keepalived.conf
sed -i '/ router_id/s#.*#   router_id ha_1#' /etc/keepalived/keepalived.conf

systemctl restart keepalived  || recho "keepalived启动失败..."
systemctl enable keepalived

gecho "haproxy配置..."
sed -i.bak '/frontend/,$d' /etc/haproxy/haproxy.cfg
cat >> /etc/haproxy/haproxy.cfg <<EOF
listen stats
        mode http
        bind :9999
        stats enable
        log global
        stats uri /haproxy-status
        stats auth admin:123
listen dashboard
        bind :80
        mode http
        balance source
        server dashboard ${controller_ip}:80 check inter 2000 fall 3 rise 5
listen mysql
        bind :3306
        mode tcp
        balance source
        server mysql ${controller_ip}:3306 check inter 2000 fall 3 rise 5
        
listen memcached
        bind :11211
        mode tcp
        balance source
        server memcached ${controller_ip}:11211 inter 2000 fall 3 rise 5
listen rabbit
        bind :5672
        mode tcp
        balance source
        server rabbit ${controller_ip}:5672 inter 2000 fall 3 rise 5
listen rabbit_web
        bind :15672
        mode http
        server rabbit_web ${controller_ip}:15672 inter 2000 fall 3 rise 5
EOF

systemctl restart haproxy  || recho "haproxy启动失败..."
systemctl enable haproxy

echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p



