#!/usr/bin/env python3

import sys
import ipaddress

f = open("firewall-rules.txt", "w+")

src_ip_str = '10.0.0.0/25'      # 2^7
dst_ip_str = '192.168.0.0/25'   # 2^7

src_port_max = 2**3             # 2^3
dst_port_max = 1

rule_str = 'priority 1 ipv4 {} {} {} {} {} {} {} {} 6 0xF port 0\n'

src_net = ipaddress.ip_network(src_ip_str)
dst_net = ipaddress.ip_network(dst_ip_str)

for src_ip in src_net:
    for dst_ip in dst_net:
        for src_port in range(src_port_max):
            for dst_port in range(dst_port_max):
                f.write(rule_str.format(
                    str(src_ip), 32,
                    str(dst_ip), 32,
                    src_port, src_port,
                    dst_port, dst_port));

f.close()

# firewall ACL Information
#
# ACL: Gen phase for ACL "PIPELINE1_a":
# runtime memory footprint on socket 0:
# single nodes/bytes used: 0/0
# quad nodes/vectors/bytes used: 278915/836745/6693960
# DFA nodes/group64/bytes used: 16514/33159/16979464
# match nodes/bytes used: 131072/16777216
# total: 40452848 bytes
# max limit: 18446744073709551615 bytes
# ACL: Build phase for ACL "PIPELINE1_a":
# node limit for tree split: 2048
# nodes created: 426501
# memory consumed: 461373825
# ACL: trie 0: number of rules: 131072, indexes: 4

# pktgen Information
# Pkts/s Max/Rx     :          13177127/0            13177127/0
#        Max/Tx     :          14882877/0            14882877/0
