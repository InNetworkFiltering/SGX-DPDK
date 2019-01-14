#include <stdio.h>
#include <rte_common.h>
#include "io/stdio.h"
#include "Enclave_t.h"

int printf(const char *fmt, ...)
{
    char buf[BUFSIZ] = {'\0'};
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, BUFSIZ, fmt, ap);
    va_end(ap);
    ocall_print_string(buf);
    return 0;
}

int fprintf(FILE __rte_unused *f /* unused */, const char *fmt, ...)
{
    char buf[BUFSIZ] = {'\0'};
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, BUFSIZ, fmt, ap);
    va_end(ap);
    ocall_print_string(buf);
    return 0;
}

int vfprintf(FILE __rte_unused *f /* unused */, const char *fmt, va_list ap)
{
    char buf[BUFSIZ] = {'\0'};
    // va_start(ap, fmt);
    vsnprintf(buf, BUFSIZ, fmt, ap);
    // va_end(ap);
    ocall_print_string(buf);
    return 0;
}
