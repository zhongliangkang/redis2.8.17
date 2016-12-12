#!/bin/sh
#start a redis server
#by tencent dba @ 20130724

function usage () {
	echo "usage:"
	echo "$0 3689" 
}

PORT=$1

if [ ! -n "$PORT"  ];then
	echo "PORT not set, exit"
	usage;
	exit;
fi

shift

#check if this server is docker?!
#docker server mount the disk to /data1, but /data is int the / without mount to any dev

dfinfo=`df -h`
idata1=`echo "$dfinfo"|grep -w  "/data1"|wc -l`
idata=`echo "$dfinfo"|grep -w "/data"|wc -l`
idataredis=` ls -ld /data/redis/ 2>/dev/null|wc -l`
idata1redis=`ls -ld /data1/redis/ 2>/dev/null|wc -l`

if [ $idata -eq 1 ]
then
	echo "data dis found, use it";
elif [ $idata -eq 0 -a $idata1 -eq 1 -a $idataredis -eq 0 ]
then
	echo "new docker found, no redis installed"
	mkdir -p /data1/redis
	mkdir -p /data
	ln -s /data1/redis /data/redis


	#process dbbak dir
	if [ -d /data/dbbak ]
	then
		mv /data/dbbak/ /data/dbbak.bak
	fi
	mkdir -p /data1/dbbak/
	ln -s /data1/dbbak /data/dbbak;

	#chown
	chown -R mysql /data1/dbbak  /data1/redis
fi
	

rootdir="/data/redis/$PORT/"
datadir="/data/redis/$PORT/data"
confpath="/data/redis/$PORT/redis.conf"
instconfpath="/data/redis/$PORT/instance.conf"

mylocalip=`/sbin/ifconfig |  grep -A1 "eth" | grep "inet addr:" | awk -F: '{ print $2 }' | grep -E "^10\.|^192\.|^172\." | awk '{ print $1 }'|head -n 1`

#for support 100.64/10 network special
mylocal100=`/sbin/ifconfig |  grep -A1 "eth" | grep "inet addr:" | awk -F: '{ print $2 }' | grep -E "^100\." | awk '{ print $1 }'|head -n 1`

if [  -d "$rootdir" ];then
	echo "dir $rootdir exists"
	exit;
fi

mkdir -p $datadir

if [ "$mylocalip" != "" ]
then
	sed -e "s/\$PORT/$PORT/g" redis.conf  | sed -e "s/bind\ 127.0.0.1/bind\ 127.0.0.1\ $mylocalip/g" > $confpath
else
	sed -e "s/\$PORT/$PORT/g" redis.conf  | sed -e "s/bind\ 127.0.0.1/bind\ 127.0.0.1\ $mylocal100/g" > $confpath
fi

touch $instconfpath

