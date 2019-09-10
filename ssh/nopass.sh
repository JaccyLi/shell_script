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

mkdir /etc/mssh

[ ! -e /etc/mssh/ippass.conf ] && echo "#格式：ip  密码" > /etc/mssh/ippass.conf

echo "配置各机器ip和密码"
read -s -n1 -p "任意键继续..."
vim /etc/mssh/ippass.conf
first_char=`awk 'NR>1{print $1}' /etc/mssh/ippass.conf`

if [[ $first_char =~ ".*#.*" ]];then
    recho "你的cluster.txt文件格式有错，
或者没有有效的IP地址"
else
    ips=$first_char
    passs=`awk 'NR>1{print $2}' /etc/mssh/ippass.conf`
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
echo
read -p "输入本机密码:" local_pass
gecho "脚本开始"
gecho "配置免密登录"
yum install -y expect


if [ ! -e /root/.ssh/authorized_keys ] ;then
rm -f /root/.ssh/*
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q

expect<<EOF
spawn ssh-copy-id root@127.0.0.1
expect {
    "yes/no" { send "yes\n";exp_continue }
    "password:" { send "${local_pass}\n" }
}
expect eof
EOF

fi

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
