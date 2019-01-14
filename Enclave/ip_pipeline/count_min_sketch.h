#ifndef _COUNT_MIN_SKETCH_
#define _COUNT_MIN_SKETCH_

#include <stdint.h>
#include <string.h>
#include <sgx_trts.h>
#include <immintrin.h>

#include "hash_func.h"

#define CM_W_BITS (16)
#define CM_WIDTH (1 << CM_W_BITS)
// w = ceil(e/epsilon)

#define CM_DEPTH 2
// d = ceil(ln(1/delta))

#define CM_PRIME (4294967231)

struct count_min_t {
    uint64_t counters[CM_DEPTH][CM_WIDTH];

    uint32_t a[CM_DEPTH];
    uint32_t b[CM_DEPTH];
};

extern struct count_min_t input_cm;

struct rte_mbuf;
struct header_cache;

void cm_init(struct count_min_t *cm);

void cm_update(struct count_min_t *cm, struct header_cache *hc, uint64_t d);

void cm_update_bulk_hc(struct count_min_t *cm, struct header_cache *hc, uint16_t *lens, size_t n);

void cm_update_bulk_mbuf(struct count_min_t *cm, struct rte_mbuf **mbufs, size_t n);

uint64_t cm_estimate(struct count_min_t *cm, struct header_cache *hc);

#endif/*  _COUNT_MIN_SKETCH_ */
