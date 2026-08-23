/*
 * Minimal newlib syscall stubs for a bare-metal RV32I target with no OS.
 * newlib's printf/etc. eventually call these; we only implement what's
 * needed to make _write() reach the UART. Everything else either no-ops
 * or reports failure in the way newlib expects.
 */

#include <sys/stat.h>
#include <errno.h>
#include "uart.h"

/* Provided by the linker script (see link.ld):a end of .bss, start of the
 * free region used for the heap. _stack_top bounds it from the top. */
extern char __bss_end;
extern char _stack_top;

static char *heap_ptr = &__bss_end;

void *_sbrk(int incr) {
    char *prev = heap_ptr;
    if (heap_ptr + incr > &_stack_top) {
        errno = ENOMEM;
        return (void *)-1;
    }
    heap_ptr += incr;
    return prev;
}

int _write(int fd, const char *buf, int len) {
    (void)fd; /* stdout and stderr both just go to the UART */
    for (int i = 0; i < len; i++) {
        uart_putc(buf[i]);
    }
    return len;
}

int _read(int fd, char *buf, int len) {
    (void)fd; (void)buf; (void)len;
    return 0; /* no stdin */
}

int _close(int fd) {
    (void)fd;
    return -1;
}

int _fstat(int fd, struct stat *st) {
    (void)fd;
    st->st_mode = S_IFCHR; /* pretend everything is a character device */
    return 0;
}

int _isatty(int fd) {
    (void)fd;
    return 1;
}

int _lseek(int fd, int offset, int whence) {
    (void)fd; (void)offset; (void)whence;
    return 0;
}

void _exit(int status) {
    (void)status;
    while (1) { /* spin forever, no OS to return to */ }
}

int _kill(int pid, int sig) {
    (void)pid; (void)sig;
    errno = EINVAL;
    return -1;
}

int _getpid(void) {
    return 1;
}

