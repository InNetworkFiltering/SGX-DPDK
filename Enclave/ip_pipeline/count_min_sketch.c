#include <rte_mbuf.h>
#include <rte_ether.h>
#include <rte_ip.h>
#include <rte_pipeline.h>

#include "header_copy.h"
#include "count_min_sketch.h"

#ifdef ENABLE_INPUT_SKETCH
struct count_min_t input_cm;
#endif

inline void
cm_init(struct count_min_t *cm) {
    memset(cm, 0, sizeof(struct count_min_t));

    for(size_t i = 0; i < CM_DEPTH; i++) {
        sgx_read_rand((unsigned char *)&cm->a[i], sizeof(cm->a[i]));
        sgx_read_rand((unsigned char *)&cm->b[i], sizeof(cm->b[i]));

        cm->a[i] = cm->a[i] % CM_PRIME;
        cm->b[i] = cm->b[i] % CM_PRIME;
    }
}

inline void
cm_update(struct count_min_t *cm, struct header_cache *hc, uint64_t d) {
    uint64_t h = hash_crc_key16((void *)hc, 0, 0);

    for(size_t i = 0; i < CM_DEPTH; i++) {
        uint64_t j = (cm->a[i] * h + cm->b[i]) & (CM_WIDTH - 1);
        cm->counters[i][j] += d;
    }

}

inline void
cm_update_bulk_hc(struct count_min_t *cm, struct header_cache *hc,
        uint16_t *lens, size_t n) {
    static uint64_t h[RTE_PORT_IN_BURST_SIZE_MAX] __rte_cache_aligned;
    static uint64_t j[RTE_PORT_IN_BURST_SIZE_MAX * CM_DEPTH] __rte_cache_aligned;

    // for(size_t i = 0; i < n; i++) {
        // h[i] = hash_crc_key16((void *)&hc[i], 0, 0);
    // }
    for(size_t i = 0; i < n; i++) {
        h[i] = hc[i].src_ip;
    }

    for(size_t p_i = 0; p_i < n; p_i++) {
        for (size_t i = 0; i < CM_DEPTH; i++) {
            j[p_i * CM_DEPTH + i] = (cm->a[i] * h[p_i] + cm->b[i]) & (CM_WIDTH - 1);
        }
    }

    for(size_t p_i = 0; p_i < n; p_i++) {
        for(size_t i = 0; i < CM_DEPTH; i++) {
            cm->counters[i][j[p_i * CM_DEPTH + i]] += lens[p_i];
        }
    }
}

inline void
cm_update_bulk_mbuf(struct count_min_t *cm, struct rte_mbuf **mbufs, size_t n) {
    static uint64_t h[RTE_PORT_IN_BURST_SIZE_MAX] __rte_cache_aligned;
    static size_t l[RTE_PORT_IN_BURST_SIZE_MAX] __rte_cache_aligned;
    static uint64_t j[RTE_PORT_IN_BURST_SIZE_MAX * CM_DEPTH] __rte_cache_aligned;

    // for(size_t i = 0; i < n; i++) {
        // h[i] = hash_crc_key16((void *)&hc[i], 0, 0);
    // }
    for(size_t i = 0; i < n; i++) {
        struct ether_hdr* eth_hdr = rte_pktmbuf_mtod(mbufs[i], struct ether_hdr *);
        struct ipv4_hdr *ipv4_hdr =
            (struct ipv4_hdr*) ((uint8_t *)eth_hdr + sizeof(struct ether_hdr));

        h[i] = rte_be_to_cpu_32(ipv4_hdr->src_addr);
        l[i] = mbufs[i]->pkt_len;
    }

    for(size_t p_i = 0; p_i < n; p_i++) {
        for (size_t i = 0; i < CM_DEPTH; i++) {
            j[p_i * CM_DEPTH + i] = (cm->a[i] * h[p_i] + cm->b[i]) & (CM_WIDTH - 1);
        }
    }

    for(size_t p_i = 0; p_i < n; p_i++) {
        for(size_t i = 0; i < CM_DEPTH; i++) {
            cm->counters[i][j[p_i * CM_DEPTH + i]] += l[p_i];
        }
    }
}

inline uint64_t
cm_estimate(struct count_min_t *cm, struct header_cache *hc) {
    uint64_t h = hash_crc_key16((void *)hc, 0, 0);
    uint64_t result = UINT64_MAX;

    for(size_t i = 0; i < CM_DEPTH; i++) {
        uint64_t j = (cm->a[i] * h + cm->b[i]) & (CM_WIDTH - 1);
        result = (cm->counters[i][j] < result) ? cm->counters[i][j] : result;
    }

    return result;
}
