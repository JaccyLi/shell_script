#!/bin/bash
#配置yum源
PWD=`dirname $0`
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/* /etc/yum.repos.d/bak/
mv $PWD/yum/* /etc/yum.repos.d/
yum -y install centos-release-openstack-stein

#安装openstack客户端、openstack SELinux管理包
yum -y install python-openstackclient openstack-selinux
yum -y install python2-PyMySQL mariadb
yum -y install openstack-keystone httpd mod_wsgi python-memcached

tar xf http_conf_d.tar -C /etc/httpd/conf.d

echo "192.168.99.211 openvip.com" >> /etc/hosts
echo "192.168.99.211 controller" >> /etc/hosts

#安装keystone
tar xf $PWD/keystone.tar -C /etc/keystone

systemctl enable httpd.service
systemctl start httpd.service

#安装glance
yum -y install openstack-glance

tar xf $PWD/glance.tar -C /etc/glance
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

#安装placement
yum -y install openstack-placement-api

tar xf $PWD/placement.tar -C /etc/placement


#安装nova
yum -y install openstack-nova-api openstack-nova-conductor   openstack-nova-console openstack-nova-novncproxy  openstack-nova-scheduler openstack-nova-placement-api

tar xf $PWD/nova.tar -C /etc/nova

systemctl restart httpd

systemctl enable openstack-nova-api.service \
openstack-nova-consoleauth.service \
openstack-nova-scheduler.service   \
openstack-nova-conductor.service \
openstack-nova-novncproxy.service

systemctl restart openstack-nova-api.service   \
openstack-nova-consoleauth.service \
openstack-nova-scheduler.service  \
openstack-nova-conductor.service \
openstack-nova-novncproxy.service

cat > /root/nova-restart.sh <<EOF
#!/bin/bash
systemctl restart openstack-nova-api.service   openstack-nova-consoleauth.service openstack-nova-scheduler.service   openstack-nova-conductor.service openstack-nova-novncproxy.service
EOF
chmod  a+x /root/nova-restart.sh

#安装neutron
yum -y install openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-linuxbridge ebtables

tar xf $PWD/neutron.tar -C /etc/neutron

echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl -p

systemctl restart openstack-nova-api.service
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service \
  neutron-dhcp-agent.service \
  neutron-metadata-agent.service

systemctl restart neutron-server.service \
  neutron-linuxbridge-agent.service \
  neutron-dhcp-agent.service \
  neutron-metadata-agent.service

#安装dashboard
yum -y install openstack-dashboard
tar xf $PWD/dashboard.tar -C /etc/openstack-dashboard
systemctl restart httpd.service 

