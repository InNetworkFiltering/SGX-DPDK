#include "header_copy.h"

#ifdef ENABLE_HEADER_COPY
struct header_cache headers[RTE_PORT_IN_BURST_SIZE_MAX];
#endif
