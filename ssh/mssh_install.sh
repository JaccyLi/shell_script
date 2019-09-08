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
confdir="/etc/mssh"
[ $# -eq 0 ] && echo "不带参数为编辑配置文件，任意键进入编辑" && read -s -n1 && vim $confdir/mssh.conf && exit
[ $# -ne 1 ] && echo "使用格式：mssh [-r] <源路径> <目标路径>
如：mssh -r /etc/example.conf /etc/
	-r   递归目录，用于传输文件夹" && exit

ips=`awk '/^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])[.]){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/{print $1}' $confdir/mssh.conf`
[ -z $ips ] && echo "配置文件没有有效ip，任意键进入编辑" && read -s -n1 && vim $confdir/mssh.conf
for i in $ips ; do
	ssh $i $1
done
