start_server {tags {"increx"}} {

    test {Test increx command} {
        r del foo
        r set foo 100
        r increx foo 1
        set mttl [r pttl foo]
        assert {$mttl > 900 && $mttl <= 1000}
        r get foo
    } {101}

    test {Test increx ttl command} {
        r del foo
        r increx foo 1
        set mttl [r pttl foo]
        assert {$mttl > 900 && $mttl <= 1000}
        r get foo
    } {1}

    test {Test increx on key with ttl} {
        r del foo
	r set foo 100
	r expire foo 10
        r debug sleep 5
	r increx foo 10
	set mttl [r pttl foo]
	assert {$mttl <= 50000}
	r get foo
    } {101}

    test {HSET/HLEN - Small hash creation} {
        array set smallhash {}
        for {set i 0} {$i < 8} {incr i} {
            set key [randstring 0 8 alpha]
            set val [randstring 0 8 alpha]
            if {[info exists smallhash($key)]} {
                incr i -1
                continue
            }
            r hset smallhash1 $key $val
            set smallhash($key) $val
        }
        list [r hlen smallhash1]
    } {8}

    test {HSET/HLEN - Small hash creation} {
        array set smallhash {}
        for {set i 0} {$i < 8} {incr i} {
            set key [randstring 0 8 alpha]
            set val [randstring 0 8 alpha]
            if {[info exists smallhash($key)]} {
                incr i -1
                continue
            }
            r hset smallhash2 $key $val
            set smallhash($key) $val
        }
        list [r hlen smallhash2]
    } {8}

    test {HSET/HLEN - Small hash creation} {
        array set smallhash {}
        for {set i 0} {$i < 8} {incr i} {
            set key [randstring 0 8 alpha]
            set val [randstring 0 8 alpha]
            if {[info exists smallhash($key)]} {
                incr i -1
                continue
            }
            r hset smallhash3 $key $val
            set smallhash($key) $val
        }
        list [r hlen smallhash3]
    } {8}


    test {HMGETALL - multi small hash} {
        lsort [r hmgetall smallhash1 smallhash2 smallhash3]
    } [lsort [array get smallhash]]


    test {HMGETALL - test hmgetall wrong type } {
        set value "value12345666"
        set key   "testkey"
        r set tstring $value
        lsort [r hmgetall smallhash1 $key smallhash2 smallhash3]
    } [lsort [array get smallhash]]

    test {HMGETALL - hmgetall with wrong type, later command return should ok} {
        set value "value12345666"
        set key   "testkey"
        r set $key $value
        lsort [r hmgetall smallhash1 $key smallhash2 smallhash3]
        r get $key
    } {value12345666}
}
