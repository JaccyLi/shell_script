#!/bin/bash
#参数修改
#└----1.安装目录
install_dir="/apps/redis"
echo "安装目录：$install_dir"
echo "否则请停止，修改脚本"
read -s -n1 -p "按任意键继续 ... "

#函数
secho() {
	cols=`tput cols`
	for i in `seq $cols`;do
	echo -n -e "#"
	done
}
gecho() {
	echo -e "\e[1;32m $1 \e[0m"
	secho
	sleep 1
}
recho() {
	echo -e "\e[1;31m $1 \e[0m"
	secho
	sleep 1
}

############下载解压redis4.0.14################
curl http://download.redis.io/releases/ > re.txt
grep -o 'href=.*gz"' re.txt &> /dev/null || { echo "下载失败" ; exit ; }
relea=`grep -o 'href=.*gz"' re.txt | cut -d\" -f2 | awk -F"[-|.]" '{
print $2}' | uniq`
clear
for i in $relea;do
[[ $i =~ [0-9] ]] && echo $i
done

redir=`ls -1d redis*|grep "redis.*[0-9]$"`
rm -rf $redir
echo "0: 选择本地(同目录下)"
read -p "选择大版本：" version
if [ "$version" -eq 0 ] ; then
line=`ls -1 redis*tar*|wc -l`
refile=`ls -1 redis*tar*`
	if [ "$line" -eq 1 ];then
		echo -ne "安装${refile} [y/n]: "
		read yesorno
		[[ "$yesorno" =~ [yY] ]] && tar xf ${refile} && dir=`echo ${refile} | sed -r 's#(^.*)\.tar.*$#\1#'`
	else
		echo "你目录下有多个版本" && exit
	fi

else
[[ "$version" =~ [0-9]+ ]] || exit
rel=`grep -o 'href=.*gz"' re.txt | cut -d\" -f2 | grep redis-$version`
j=1
for i in $rel ;do
echo -e "\e[1;32m${j}\e[0m : $i"
ver[$j]=$i
let j++
done
read -p "选择要下载的版本：" down_ver
[[ "$down_ver" =~ [0-9]+ ]] || exit

gecho "脚本开始"
gecho "下载解压redis4.0.14"
wget http://download.redis.io/releases/${ver[down_ver]}
tar xf ${ver[down_ver]}
dir=`echo ${ver[down_ver]} | sed -r 's#(^.*)\.tar.*$#\1#'`
fi

cd $dir
###############################################

rm -f re.txt




#环境安装
gecho "环境安装"
yum -y install gcc gcc-c++  || { recho "安装环境失败" ; exit ; }

#编译redis
gecho "编译redis"
make PREFIX=${install_dir} install  
if [ $? -ne 0 ] ; then
	recho "编译失败" 
	exit
fi

gecho "拷贝配置文件"
mkdir -p ${install_dir}/{etc,log,data,run}
cp redis.conf ${install_dir}/etc/
cp sentinel.conf ${install_dir}/etc/

#配置环境
gecho "配置环境"
echo "net.core.somaxconn = 512" >> /etc/sysctl.conf
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
sysctl -p || recho "sysctl执行失败"
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local 
chmod +x /etc/rc.local 

#配置启动脚本
gecho "配置启动脚本"
cat > /usr/lib/systemd/system/redis.service << EOF
[Unit]
Description=Redis persistent key-value database
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=${install_dir}/bin/redis-server ${install_dir}/etc/redis.conf --supervised systemd
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Type=notify
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755
[Install]
WantedBy=multi-user.target
EOF

#启动服务
gecho "启动服务"
useradd -s /sbin/nologin redis  || recho "redis用户已存在"
chown redis.redis -R ${install_dir}
systemctl daemon-reload
systemctl enable redis
ln -sv ${install_dir}/bin/redis* /usr/local/sbin

#修改配置文件
gecho "修改配置文件"
sed -i "s@^dir.*@dir \"${install_dir}/data\"@" ${install_dir}/etc/redis.conf
sed -i "/^logfile/s#^.*\$#logfile \"${install_dir}/log/redis.log\"#" ${install_dir}/etc/redis.conf
sed -i '/^bind/s#^.*$#bind 0.0.0.0#' ${install_dir}/etc/redis.conf
systemctl restart redis
