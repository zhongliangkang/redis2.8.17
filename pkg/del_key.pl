#!/usr/bin/perl -w
use FindBin qw($Bin);
BEGIN {
    my $cdir = `dirname $0`;
    chomp($cdir);
    my $libPath = "$cdir/lib/";
    unshift( @INC, $libPath );
}
use Redis;
use Data::Dumper;
use Time::HiRes qw( gettimeofday );

my $argc = scalar @ARGV;

if($argc < 4){
	print  "Usage: $0 IP PORT PASSWD FILENAME \n";
	print  "    if no password set, use 1 instead.\n";
	print  "exit\n";
	exit;
}

#get input
my $host = $ARGV[0];
my $port = $ARGV[1];
my $passwd = $ARGV[2];
my $filename = $ARGV[3];


print "input: ./$0  $host $port $passwd $filename\n";

if(! -f $filename){
	print "cannot find file: $filename\n";
	exit;
}


my $redis;
eval{
	$redis  = Redis->new(server => "$host:$port");
};

if( $@ ){
	print "[ERROR] connect to Redis $host:$port failed: $@\n";
	exit;
}


if( "$passwd" ne "1"){
	my $auth_ret = "";
	eval{
		$auth_ret = $redis->auth($passwd);
	};

	if($@ and $@ =~ /Client sent AUTH, but no password is se/){
		print "client setn auth,\n";
	}elsif($auth_ret =~ /OK/){
		print "password set, auth OK\n";
	}else{
		print "auth failed: $@, auth ret:$auth_ret\n";
		exit;
	}
}else{
	print "no password set, skip auth\n";
}

sub del_string{
	my ($r,$key) = @_;
	my $ret = $r->del($key);
	#print "s: $key $ret\n";
}


#delete list by ltrim
sub del_list{
	my ($r,$key) = @_;
	
	my $len = $r->llen($key);
	
	#pop N from list each time
	my $del_once = 1;

	my $del_loop = $len/$del_once + 1;

	my $i =0;
	while($i < $del_loop){
		$r->lpop($key);
		$i++;
	}
	my $len_del = $r->llen($key);
	
	print "l: $key ,key len:$len\n";
}

#delete set by spop
sub del_set{
	my ($r,$key) = @_;
	
	my $len = $r->scard($key);
	
	#pop N from list each time
	my $del_once = 1000;

	my $del_loop = $len/$del_once + 1;

	my $i =0;
	while($i < $len){
		$r->spop($key);
		$i++;
	}
	my $len_del = $r->scard($key);
	
	print "set: $key ,key len:$len\n";
}

#delete zset by ZREMRANGEBYRANK
sub del_zset{
	my ($r,$key) = @_;
	
	my $len = $r->zcard($key);
	
	#pop N from list each time
	my $del_once = 1000;

	my $del_loop = $len/$del_once + 1;

	my $i =0;
	while($i < $del_loop){
		$r->zremrangebyrank($key,0,$del_once-1);
		$i++;
	}
	my $len_del = $r->zcard($key);
	
	print "zset: $key ,key len:$len\n";
}

#delete hash by hscan/hdel
sub del_hash{
	my ($r,$key) = @_;
	
	my $len = $r->hlen($key);
	#pop N from list each time
	my $del_once = 1000;
	my $del_loop = 0;

	#save last scan cursor
	my $cur  =0;
	while($len or $cur){
		my $hscan_ret = $r->hscan($key,$cur,'MATCH',"*","count","$del_once");
		my %hh = @{$hscan_ret->[1]};

		foreach my $k (keys %hh){
			#print "$k $hh->{$k}\n";
			$r->hdel($key,$k);
		}

		$cur = $hscan_ret->[0];
		$len = $r->hlen($key);
		$del_loop ++;
	}
	my $len_del = $r->hlen($key);
	
	print "h: $key ,key len:$len\n";
}
sub del_one_key{
	my ($r,$key) = @_;
	my $type = $r->type($key);

	#print "type of key:$key type:$type.\n";
	if($type eq "none"){
		#print "key not eixsts\n";
		return;
	}elsif ($type eq "string"){
		#print "string found\n";
		del_string($r,$key);
	}elsif ($type eq "list"){
		#print "list found\n";
		del_list($r,$key);
	}elsif ($type eq "hash" ){
		#print "hash found\n";
		del_hash($r,$key);
	}elsif ($type eq "set" ){
		#print "set found\n";
		del_set($r,$key);
	}elsif ($type eq "zset"){
		#print "zset found\n";
		del_zset($r,$key);
	}else{
		print "error type found\n";
	}
}


#main,process keys in file 1by1

open $KFH, "<$filename";
while(<$KFH>){
	my $tk = $_;
	chomp($tk);
	#print "$tk\n";
	my $stime = gettimeofday;
	del_one_key($redis,$tk);
	my $etime = gettimeofday;

	my  $take = $etime-$stime;

	printf("dtime $tk :  %.9f ms\n",$take*1000);
}
	

close($KFH);





#my $key = "FYears_lAcc_14";
#
#my $ret ;
#
#$ret = $redis->hlen($key);
#
#while($ret){
#	print "hlen: $ret\n";
#	my  $hscan_ret = $redis->hscan($key,$ret);
#
#	my $hashn = scalar @{$hscan_ret->[1]};
#	my %hh = @{$hscan_ret->[1]};
#
#	foreach my $k (keys %hh){
#		#print "$k $hh->{$k}\n";
#		$redis->hdel($key,$k);
#	}
#
#	$ret = $hscan_ret->[0];
#}
#
#print "deld\n";
#
