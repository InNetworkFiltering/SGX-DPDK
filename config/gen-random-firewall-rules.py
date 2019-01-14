#!/usr/bin/env python3

import sys
import ipaddress
import random

max_n_rules = 65536

f = open("random-firewall-rules.txt", "w+")

rule_str = 'priority 1 ipv4 {} {} {} {} {} {} {} {} 6 0xF port 1\n'

hit_rule = rule_str.format('10.0.0.0', 32, '192.168.0.0', 32, 0, 0, 0, 0)

f.write(hit_rule)

for i in range(max_n_rules - 1):
    src_ip = ipaddress.ip_address(random.randrange(2**32))
    dst_ip = ipaddress.ip_address(random.randrange(2**32))
    src_port = random.randrange(65536)
    dst_port = random.randrange(65536)

    f.write(rule_str.format(
        str(src_ip), 32,
        str(dst_ip), 32,
        src_port, src_port,
        dst_port, dst_port));

f.close()

# ACL Information
# ACL: Gen phase for ACL "PIPELINE1_a":
# runtime memory footprint on socket 0:
# single nodes/bytes used: 0/0
# quad nodes/vectors/bytes used: 625920/1897121/15176968
# DFA nodes/group64/bytes used: 5478/18853/9654792
# match nodes/bytes used: 65536/8388608
# total: 33222576 bytes
# max limit: 18446744073709551615 bytes
# ACL: Build phase for ACL "PIPELINE1_a":
# node limit for tree split: 2048
# nodes created: 696934
# memory consumed: 922747650
# ACL: trie 0: number of rules: 65536, indexes: 4

