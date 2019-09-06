#!/bin/bash
gecho() {
	echo -e "\e[1;32m${1}\e[0m" && sleep 1
}
recho() {
	echo -e "\e[1;31m${1}\e[0m" && sleep 1
}

vip=192.168.99.211
controller_ip=192.168.99.211

gecho "配置yum源"
PWD=`dirname $0`
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/* /etc/yum.repos.d/bak/
mv $PWD/yum/* /etc/yum.repos.d/

gecho "安装包..."
yum -y install centos-release-openstack-stein
yum -y install python-openstackclient openstack-selinux
yum -y install openstack-nova-compute
yum -y install openstack-neutron-linuxbridge ebtables ipset

cat $PWD/limits.conf > /etc/security/limits.conf
cat $PWD/profile > /etc/profile
cat $PWD/sysctl.conf > /etc/sysctl.conf

gecho "配置nova"
tar xvf $PWD/nova-compute.tar -C /etc/nova/
myip=`ifconfig eth0 | awk '/inet /{print $2}'`
sed -i "/my_ip =/s#.*#my_ip = ${myip}#" /etc/nova/nova.conf

gecho "配置neutron"
tar xf neutron-compute.tar -C /etc/neutron

echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl -p

echo "${vip} openvip.com" >> /etc/hosts
echo "${controller_ip} controller" >> /etc/hosts

vcpu=${egrep -c '(vmx|svm)' /proc/cpuinfo}
if [ vcpu -eq 0 ] ; then
cat >> /etc/nova/nova.conf <<EOF
[libvirt]
virt_type = qemu
EOF
fi

gecho "启动服务..."
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service || recho "libvirtd启动失败"
systemctl restart openstack-nova-compute.service || recho "openstack-nova-compute启动失败"
systemctl enable neutron-linuxbridge-agent.service
systemctl restart neutron-linuxbridge-agent.service


