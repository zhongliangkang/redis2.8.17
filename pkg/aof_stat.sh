#!/bin/sh
#
# used to static appendonly.aof file
# INPUT: <aof_file_name>
# OUTPUT: statistic for aof info
# @2016.1.11
#####################################################################


RAK="./redis-aof-keys"


if [ $# -ne 2 ]
then
	echo "usage: $0  <aof_file_name> <id_tag>"
	echo "exit"
	exit 1
fi

filename="$1"
mytag="$2"
rakout="$mytag.rak.log"

#get the key statistic of appendonly
$RAK  $filename  > $rakout

#each type match the string/hash/zset/set/list operation
tags="SET HMSET ZADD SADD RPUSH"

for tag in $tags
do
  grep -w $tag ${rakout}  >$tag.${mytag}
  echo "$tag"
done

#string 
cat SET.${mytag} |awk 'BEGIN{n=0;tlen=0;max="";maxl=0;}{n++;tlen+=$3;if(maxl<$3){maxl=$3;max=$2;}}END{print "string: ",n,tlen,max,maxl,tlen/n}'

#hmset
cat HMSET.${mytag} |awk 'BEGIN{n=0;tlen=0;max="";maxl=0;}{ a[$2]+=$5;b[$2]+=$3; }END{for(i in a){if(maxl<b[i]){max=i;maxl=b[i];} n++; tlen+=a[i];} print "hmset:",n,tlen,max,maxl,tlen/n}'

#ZADD
cat ZADD.${mytag} |awk 'BEGIN{n=0;tlen=0;max="";maxl=0;}{ a[$2]+=$4;b[$2]+=$3; }END{for(i in a){if(maxl<b[i]){max=i;maxl=b[i];} n++; tlen+=a[i];} print "zset:",n,tlen,max,maxl,tlen/n}'
cat ZADD.${mytag} |awk 'BEGIN{n=0;tlen=0;max="";maxl=0;}{ a[$2]+=$4;b[$2]+=$3; }END{for(i in a){if(maxl<b[i]){max=i;maxl=b[i];} n++; tlen+=a[i];print "zset",i,b[i],a[i]}}' |sort -k3nr >ZADD.${mytag}.1

#SADD
cat SADD.${mytag} |awk 'BEGIN{n=0;tlen=0;max="";maxl=0;}{ a[$2]+=$4;b[$2]+=$3; }END{for(i in a){if(maxl<b[i]){max=i;maxl=b[i];} n++; tlen+=a[i];} print "set:",n,tlen,max,maxl,tlen/n}'
cat SADD.${mytag} |awk 'BEGIN{n=0;tlen=0;max="";maxl=0;}{ a[$2]+=$4;b[$2]+=$3; }END{for(i in a){if(maxl<b[i]){max=i;maxl=b[i];} n++; tlen+=a[i];print "set",i,b[i],a[i]}}'  |sort -k3nr >SADD.${mytag}.1
#LIST
cat RPUSH.${mytag} |awk 'BEGIN{n=0;tlen=0;max="";maxl=0;}{ a[$2]+=$4;b[$2]+=$3; }END{for(i in a){if(maxl<b[i]){max=i;maxl=b[i];} n++; tlen+=a[i];} print "set:",n,tlen,max,maxl,tlen/n}'

tot=0;
for tag in $tags
do
	x=`cat $tag.${mytag}|wc -l`
	tot=$((tot+x))
done

exp=`cat $rakout|grep -w PEXPIREAT|wc -l`

echo "total_keys: $tot"
echo "expirekeys: $exp"
per=`echo "scale=4;$exp/$tot"|bc`
echo "percent: $per"
