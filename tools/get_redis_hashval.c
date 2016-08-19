#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <limits.h>
#include <sys/time.h>
#include <stdint.h>
#include <ctype.h>

#ifndef INT64_C
#define INT64_C(c) (c ## LL)
#define UINT64_C(c) (c ## ULL)
#endif

#define     REDIS_HASH_BUCKETS 420000

static uint64_t FNV_64_INIT = UINT64_C(0xcbf29ce484222325);
static uint64_t FNV_64_PRIME = UINT64_C(0x100000001b3);
static uint32_t FNV_32_INIT = 2166136261UL;
static uint32_t FNV_32_PRIME = 16777619;


uint32_t
hash_fnv1a_64(const char *key, size_t key_length)
{   
    uint32_t hash = (uint32_t) FNV_64_INIT;
    size_t x;

    for (x = 0; x < key_length; x++) {
        uint32_t val = (uint32_t)key[x];
        hash ^= val;
        hash *= (uint32_t) FNV_64_PRIME; 
    }

    return hash;
}   

uint32_t get_key_hash(char * key, size_t len){
    
    uint32_t val = hash_fnv1a_64( key, len);
    val %= REDIS_HASH_BUCKETS;
    
    return val;
} 


int main(int argc, char *argv[]){
	if(argc != 2){
		fprintf(stdout,"#######################################################\n");
		fprintf(stdout,"#\n");
		fprintf(stdout,"# Function: Compute the Redis hash for key [keyname]\n");
		fprintf(stdout,"# Sample Input: %s mykey\n",argv[0]);
		fprintf(stdout,"# Sample Output:mykey 9642\n");
		fprintf(stdout,"#\n");
		fprintf(stdout,"#######################################################\n");
		fprintf(stdout,"\n");
		fprintf(stdout,"Usage: %s [keyname]\n",argv[0]);
		fprintf(stdout,"exit..\n");
		return 1;
	}

	long long hashval = get_key_hash(argv[1],strlen(argv[1]));
	fprintf(stdout,"%s %lld\n",argv[1],hashval);
}
