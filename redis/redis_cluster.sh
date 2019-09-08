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

clear
[ ! -e cluster.txt ] && echo -e "\e[1;4;32m初始化需知：\e[0m" && echo "按任意键进入编辑文本
填写其它集群节点的ip和密码" && echo "# 例：192.168.99.11 passwd123" > cluster.txt && trap 'vim cluster.txt; bash $0' 0 && read -s -n1 -p "按任意键继续 ... " && exit
read -p "输入本机密码:" local_pass

gecho "脚本开始"
first_char=`awk 'NR>1{print $1}' cluster.txt`
if [[ $first_char =~ ".*#.*" ]];then
    recho "你的cluster.txt文件格式有错，
或者没有有效的IP地址"
else
    ips=$first_char
    passs=`awk 'NR>1{print $2}' cluster.txt`
fi

i=1
for j in $ips ; do
	[ -z $j ] && echo "cluster文件格式有错" && exit
    ip[i]=$j
    let i++
done

i=1
for y in $passs; do
	[ -z $y ] && echo "cluster文件格式有错" && exit
    pass[i]=$y
    let i++
done

gecho "配置免密登录"
yum install -y expect
rm -f /root/.ssh/id*
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q
expect<<EOF
spawn ssh-copy-id root@127.0.0.1
expect {
    "yes/no" { send "yes\n";exp_continue }
    "password:" { send "${local_pass}\n" }
}
expect eof
EOF

for i in `seq ${#ip[*]}`;do
expect<<EOF
spawn scp -r /root/.ssh root@${ip[$i]}:/root/
expect {
    "yes/no" { send "yes\n";exp_continue }
    "password:" { send "${pass[$i]}\n" }
}
expect eof
EOF
done

gecho "开始打包"
kedir=`find / -name redis -type d`
yum -y install tree &> /dev/null
for i in $kedir ; do
	tree $i|grep "bin"
	[ $? -eq 0 ] && echo -e "\n你可能的redis安装目录为: \e[1;32m$i\e[0m" && sleep 1 && install_dir=$i && break
done

cd $install_dir
tmpdir="/root/cluster"
mkdir $tmpdir
tar zcf $tmpdir/redis.tar.gz *

gecho "开始部署其它集群节点"
for i in `seq ${#ip[*]}`;do
#创建用户
	ssh ${ip[$i]} "useradd -s /sbin/nologin redis"
#创建目录
	ssh ${ip[$i]} "mkdir -p ${install_dir}"
#传送主目录
	scp $tmpdir/redis.tar.gz ${ip[$i]}:/root
#解压
	ssh ${ip[$i]} "tar xf /root/redis.tar.gz -C ${install_dir}"
#传送启动服务
	scp /usr/lib/systemd/system/redis.service ${ip[$i]}:/usr/lib/systemd/system/
#传送软连接
	ssh ${ip[$i]} "ln -sv ${install_dir}/bin/redis* /usr/local/sbin/"
#启动服务
	ssh ${ip[$i]} "systemctl daemon-reload"
	ssh ${ip[$i]} "systemctl restart redis"
	ssh ${ip[$i]} "systemctl enable redis"
	
	ssh ${ip[$i]} "echo 'net.core.somaxconn = 512' > /etc/sysctl.conf"
	ssh ${ip[$i]} "echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf"
	ssh ${ip[$i]} "sysctl -p "
	ssh ${ip[$i]} "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
	ssh ${ip[$i]} "echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local "
	ssh ${ip[$i]} "chmod +x /etc/rc.local "
	
done

secho
gecho "配置完成"


