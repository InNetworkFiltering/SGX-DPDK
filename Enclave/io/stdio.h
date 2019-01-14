#ifndef _IO_STDIO_H_
#define _IO_STDIO_H_

#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

//TODO(Deli): a dummy struct declaration
struct _internal_FILE {
    uint64_t dummy;
};

typedef struct _internal_FILE FILE;
#define stderr NULL
#define stdout NULL

int printf(const char *fmt, ...);
int fprintf(FILE *f, const char *fmt, ...);
int vfprintf(FILE *f, const char *fmt, va_list ap);

#ifdef __cplusplus
};
#endif

#endif /*  _IO_STDIO_H_ */
