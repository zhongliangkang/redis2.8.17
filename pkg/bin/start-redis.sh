#!/bin/sh
#start a redis server
#by tencent dba @ 20130724

function usage () {
	echo "usage:"
	echo "$0 3689" 
	echo "$0 3689 + some redis arg like: $0 3689 --slaveof 1.1.1.1 3679" 
}

PORT=$1
CDIR=`dirname $0`

if [ ! -n "$PORT"  ];then
	echo "PORT not set, exit"
	usage;
	exit;
fi

shift


rootdir="/data/redis/$PORT"
datadir="/data/redis/$PORT/data"
confpath="/data/redis/$PORT/redis.conf"

if [ ! -d "$rootdir" ];then
	echo "dir $rootdir not exists"
	usage;
	exit;
fi

if [ ! -f "$confpath" ];then
	echo "file $confpath not exists"
	usage;
	exit;
fi


$CDIR/redis-server $rootdir/redis.conf 
