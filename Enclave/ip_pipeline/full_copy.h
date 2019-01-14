#ifndef _FULL_COPY_H_
#define _FULL_COPY_H_

void init_copy_mempool(void);

int
input_port_make_full_copy(struct rte_pipeline __rte_unused *p,
	struct rte_mbuf **pkts, uint32_t n, void *arg);

int
output_port_free_full_copy(struct rte_pipeline __rte_unused *p,
	struct rte_mbuf **pkts, uint64_t pkts_mask, void *arg);

#endif/*  _FULL_COPY_H_ */
