start_server {tags {"bucket"}} {
    test {RCTRANSTAT} {
        catch {r rctranstat} err
        set _ $err
    } {# Transfer stats*redis_trans_flag: *inusing: 420000*transfer_in: 0*transfer_out: 0*transfered: 0*}
}

start_server {tags {"bucket"}} {
    test {rctransserver out success} {
        r rctransserver out
    } {OK}
    
#    test {AUTH succeeds when the right password is given} {
#        r auth foobar
#    } {OK}

    test {Once AUTH succeeded we can actually send commands to the server} {
        r set foo 100
        r incr foo
    } {101}

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

}
