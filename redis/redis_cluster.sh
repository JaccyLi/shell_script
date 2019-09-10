#!/bin/bash
#函数
secho() {
	cols=`tput cols`
	for i in `seq $cols`;do
	echo -n -e "#"
	done
}
gecho() {
	secho
	echo -e "\e[1;4;32m $1 \e[0m"
	sleep 1
}
recho() {
	secho
	echo -e "\e[1;4;31m $1 \e[0m"
	sleep 1
}

echo "在开始前要确保你的redis已经配置好了，
否则就Ctrl + C 停止运行"

###首次运行


confdir="/etc/mssh"
mkdir -p $confdir &> /dev/null
[ ! -e $confdir/cluster.conf ] && echo -e "\e[1;4;32m初始化需知：\e[0m" && echo "按任意键进入编辑文本
填写其它集群节点的ip，确保已经配置了免密登录" && echo "# 例：192.168.99.11 " > $confdir/cluster.conf 
read -s -n1 -p "按任意键继续 ... "
vim  $confdir/cluster.conf 




ips=`awk '/^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])[.]){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/{print $1}' $confdir/cluster.conf `


gecho "脚本开始"

gecho "开始打包"
kedir=`find / -name redis -type d`
yum -y install tree &> /dev/null
for i in $kedir ; do
	tree $i|grep "bin"
	[ $? -eq 0 ] && echo -e "\n你可能的redis安装目录为: \e[1;32m$i\e[0m" && sleep 1 && install_dir=$i && break
done

cd $install_dir
tmpdir="/root/cluster"
mkdir $tmpdir &> /dev/null
tar zcf $tmpdir/redis.tar.gz *

gecho "开始部署其它集群节点"
for i in $ips;do
#创建用户
	ssh $i "useradd -s /sbin/nologin redis"
#创建目录
	ssh $i "mkdir -p ${install_dir}"
#传送主目录
	scp $tmpdir/redis.tar.gz $i:/root
#解压
	ssh $i "tar xf /root/redis.tar.gz -C ${install_dir}"
#传送启动服务
	scp /usr/lib/systemd/system/redis.service $i:/usr/lib/systemd/system/
#传送软连接
	ssh $i "ln -sv ${install_dir}/bin/redis* /usr/local/sbin/"
#启动服务
	ssh $i "systemctl daemon-reload"
	ssh $i "systemctl restart redis"
	ssh $i "systemctl enable redis"
	
	ssh $i "echo 'net.core.somaxconn = 512' > /etc/sysctl.conf"
	ssh $i "echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf"
	ssh $i "sysctl -p "
	ssh $i "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
	ssh $i "echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local "
	ssh $i "chmod +x /etc/rc.local "
	
done

secho
gecho "配置完成"


