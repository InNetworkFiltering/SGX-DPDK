#ifndef _SKETCH_H_
#define _SKETCH_H_

#include <stdint.h>
#include <rte_log.h>
#include <rte_mbuf.h>
#include <rte_pipeline.h>
#include <rte_ether.h>
#include <rte_ip.h>
#include <rte_tcp.h>

#include "count_min_sketch.h"

struct header_cache {
    uint32_t src_ip;
    uint32_t dst_ip;
    uint16_t src_port;
    uint16_t dst_port;
    uint8_t proto;
    uint8_t dummy;
    uint16_t pkt_len;
    // 32*4 = 128 / 8 = 16
} __rte_cache_aligned;

extern struct header_cache headers[RTE_PORT_IN_BURST_SIZE_MAX];

static inline void
header_cache_clone(struct rte_mbuf* m, struct header_cache *hc, uint16_t *len) {
    struct ether_hdr* eth_hdr = rte_pktmbuf_mtod(m, struct ether_hdr *);

    RTE_ASSERT(eth_hdr->ether_type == rte_cpu_to_be_16(ETHER_TYPE_IPv4));

    struct ipv4_hdr *ipv4_hdr =
        (struct ipv4_hdr*) ((uint8_t *)eth_hdr + sizeof(struct ether_hdr));

    // clone metadata from IP header
    hc->src_ip = rte_be_to_cpu_32(ipv4_hdr->src_addr);
    hc->dst_ip = rte_be_to_cpu_32(ipv4_hdr->dst_addr);

    // user Ethernet frame length
    hc->pkt_len = 0;
    hc->dummy = 0;
    *len = m->pkt_len;

    // or use IP layer length
    /* hc->size = rte_be_to_cpu_16(ipv4_hdr->total_length); */

    hc->proto = ipv4_hdr->next_proto_id;

    struct tcp_hdr *tcp_hdr = (struct tcp_hdr*) \
	((uint8_t *)ipv4_hdr + sizeof(struct ipv4_hdr));

    hc->src_port = rte_be_to_cpu_16(tcp_hdr->src_port);
    hc->dst_port = rte_be_to_cpu_16(tcp_hdr->dst_port);
}

static inline int
input_port_make_header_copy(struct rte_pipeline __rte_unused *p,
	struct rte_mbuf **pkts, uint32_t n, void __rte_unused *arg) {
    uint16_t pkt_lens[RTE_PORT_IN_BURST_SIZE_MAX];

    for(size_t i = 0; i < n; i++) {
	struct rte_mbuf* pkt = pkts[i];
	header_cache_clone(pkt, &headers[i], &pkt_lens[i]);
    }

#ifdef ENABLE_INPUT_SKETCH
    cm_update_bulk_hc(&input_cm, headers, pkt_lens, n);
#endif

    for(size_t i = 0; i < n; i++) {
	headers[i].pkt_len = pkt_lens[i];
    }

    return 0;
}

#endif/*  _SKETCH_H_ */

