#!/bin/bash
#
#***********************************************************
#Author:                Jibill Chen
#QQ:                    417060833
#Date:                  2019-07-10
#FileName：             sqlperdump.sh
#URL:                   http://www.jibiao.work
#Description：          The test script
#**********************************************************
clear
read -p "your backup PATH(default:/root/backup/):" BACKUPPATH
if [ -z "$BACKUPPATH" ] ; then
	BACKUPPATH="/root/backup/"
fi
if [ `echo $BACKUPPATH|rev|cut -c1` != '/' ];then
	BACKUPPATH="${BACKUPPATH}/"
fi
#define dbecho
dbecho(){
	if [ $1 -eq 0 ] ; then
		echo -n "[ ] "
		echo  "$2. $3"
	else
		echo -n "[*] "
		echo -e "\e[1;32m$2. $3\e[0m"
	fi
}
#init menu
echo  "Select databases you want to dump:"
i=0
for line in  `mysql -e "show databases" | grep -Evi "\<information_schema\>|\<performance_schema\>|\<Database\>"`
do
	let i+=1
	db[$i]=$line
	dbselect[$i]=0
	dbecho ${dbselect[$i]} $i ${db[$i]}
done

#print menu
dbmenu(){
i=0
	echo  "Select databases you want to dump:"
for line in  `mysql -e "show databases" | grep -Evi "\<information_schema\>|\<performance_schema\>|\<Database\>"`
do
	let i+=1
	dbname[$i]=$line
	dbselect[$1]=1
	dbecho ${dbselect[$i]} $i $line
done
}
#begin dump
dbdump(){
j=0
for dbselects in ${dbselect[*]}
do
	let j+=1
	if [ $dbselects -eq 1 ];then
		dbnamedump[$j]=${dbname[$j]}
	fi
done

for dbs in ${dbnamedump[*]}
do
	echo "${dbs}" | sed -r "s#(^.*$)#mysqldump -B \1 --single-transaction --master-data=2 \| gzip \> ${BACKUPPATH}\1_`date +%F`.sql.gz#" | bash
	
done
}

#select menu
while :
do
	echo -n "press 'q' to exit;"
	echo "press 'x' to dump;"
	read -p "Select NUM:" NUM
	tput cup 1 0 
	case $NUM in 
	'q')
		clear
		break
		;;
	'x')
		clear
		dbdump
		break
		;;
	*)
		dbmenu $NUM
	esac
done
