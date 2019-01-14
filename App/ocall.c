#include "parser.h"
#include "rte_mbuf.h"

int ocall_parser_read_uint32(uint32_t *value, const char *p) {
	return parser_read_uint32(value, p);
}

void ocall_rte_pktmbuf_free(struct rte_mbuf *m) {
	rte_pktmbuf_free(m);
}
