#!/bin/bash
#配置文件路径
confdir="/etc/mssh"
[ ! -e /etc/mssh ] && mkdir -p $confdir
echo "#格式：每个ip写一行，目前不支持分组" > $confdir/mssh.conf
echo '安装完成，请先完成ssh免密码登录
使用格式：mssh "命令"
如：mssh "hostname"'
#安装
install_dir="/usr/local/sbin"
sed -n '3,$p' $0 | sed -n '/#!\/bin\/bash/,$p' > $install_dir/mssh
chmod +x $install_dir/mssh
exit

#!/bin/bash
#函数
gecho() {
	echo -e "\e[1;4;32m $1 \e[0m"
}
recho() {
	echo -e "\e[1;4;31m $1 \e[0m"
}

confdir="/etc/mssh"

if [ $# -eq 0 ] ;then
	echo "不带参数为编辑配置文件，任意键进入编辑" 
	read -s -n1 
	vim $confdir/mssh.conf 
	exit
fi
#[ $# -ne 1 ] && echo "使用格式：mssh [-r] <源路径> <目标路径>
#如：mssh -r /etc/example.conf /etc/
#	-r   递归目录，用于传输文件夹" && exit

ips=`awk '/^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])[.]){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/{print $1}' $confdir/mssh.conf`
if [ -z "$ips" ] ;then
echo "配置文件没有有效ip，任意键进入编辑" 
read -s -n1 
vi $confdir/mssh.conf
fi

for i in $ips ; do
gecho $i
	ssh $i $@
done
