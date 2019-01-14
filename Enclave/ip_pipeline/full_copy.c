#include <rte_mempool.h>
#include <rte_mbuf.h>
#include <rte_pipeline.h>
#include <rte_ether.h>
#include <rte_ip.h>
#include <rte_tcp.h>

#include "count_min_sketch.h"
#include "full_copy.h"

struct rte_mempool *enclave_mempool;

struct rte_mbuf* saved_mbufs[RTE_PORT_IN_BURST_SIZE_MAX] __rte_cache_aligned;

void init_copy_mempool(void) {
    enclave_mempool = rte_pktmbuf_pool_create("enclave_mempool",
	    RTE_PORT_IN_BURST_SIZE_MAX, 0, 0,
	    RTE_MBUF_DEFAULT_BUF_SIZE, SOCKET_ID_ANY);
    if (enclave_mempool == NULL) {
	RTE_LOG(ERR, APP, "enclave_mempool cannot be allocated\n");
	abort();
    }
    RTE_LOG(DEBUG, APP, "enclave mempool available count %" PRIu32 "\n",
	    rte_mempool_avail_count(enclave_mempool));
}

void print_pkt_detail(struct rte_mbuf *m);

void print_pkt_detail(struct rte_mbuf *m) {
    struct ether_hdr* eth_hdr = rte_pktmbuf_mtod(m, struct ether_hdr *);

    RTE_ASSERT(eth_hdr->ether_type == rte_cpu_to_be_16(ETHER_TYPE_IPv4));

    struct ipv4_hdr *ipv4_hdr =
        (struct ipv4_hdr*) ((uint8_t *)eth_hdr + sizeof(struct ether_hdr));

    // clone metadata from IP header
    uint32_t src_ip = rte_be_to_cpu_32(ipv4_hdr->src_addr);
    uint32_t dst_ip = rte_be_to_cpu_32(ipv4_hdr->dst_addr);

    RTE_LOG(DEBUG, APP, "pkt(%p) src_ip:%u dst_ip:%u\n", m, src_ip, dst_ip);

    uint8_t proto = ipv4_hdr->next_proto_id;
    RTE_LOG(DEBUG, APP, "pkt(%p) proto %d\n", m, proto);

    struct tcp_hdr *tcp_hdr = (struct tcp_hdr*) \
	((uint8_t *)ipv4_hdr + sizeof(struct ipv4_hdr));

    uint16_t src_port = rte_be_to_cpu_16(tcp_hdr->src_port);
    uint16_t dst_port = rte_be_to_cpu_16(tcp_hdr->dst_port);

    RTE_LOG(DEBUG, APP, "pkt(%p) src_port:%u dst_port:%u\n", m, src_port, dst_port);
}

inline int
input_port_make_full_copy(struct rte_pipeline __rte_unused *p,
	struct rte_mbuf __rte_unused  **pkts, uint32_t n, void __rte_unused *arg) {

    for(size_t i = 0; i < n; i++) {
	// FIXME: not work after classification
	/* saved_mbufs[i] = pkts[i]; */
	/* pkts[i] = rte_pktmbuf_copy(saved_mbufs[i], enclave_mempool); */
	saved_mbufs[i] = rte_pktmbuf_copy(pkts[i], enclave_mempool);
	if (unlikely(saved_mbufs[i] == NULL)) {
	    rte_panic("enclave mempool exhausted\n");
	}
    }

#ifdef ENABLE_INPUT_SKETCH
    cm_update_bulk_mbuf(&input_cm, pkts, n);
#endif

    return 0;
}

inline int
output_port_free_full_copy(struct rte_pipeline __rte_unused *p,
	struct rte_mbuf __rte_unused **pkts, uint64_t pkts_mask, void __rte_unused *arg) {

    uint64_t pkts_i = 1;
    for(size_t i = 0; i < 64; i++, pkts_i <<= 1) {
	if (pkts_mask & pkts_i) {
	    // FIXME: need to check input_port_make_full_copy
	    /* rte_pktmbuf_free(pkts[i]); */
	    /* pkts[i] = saved_mbufs[i]; */
	    rte_pktmbuf_free(saved_mbufs[i]);
	}
    }

    return 0;
}
