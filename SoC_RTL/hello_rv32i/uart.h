#ifndef UART_H
#define UART_H

#define UART_TX_ADDR   (*(volatile unsigned int *)0xFFFFFFF0)
#define UART_STAT_ADDR (*(volatile unsigned int *)0xFFFFFFF4)

static inline void uart_putc(char c) {
    while ((UART_STAT_ADDR & 1u) == 0u) { /* spin until o_ready == 1 */ }
    UART_TX_ADDR = (unsigned char)c;
}

static inline void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

#endif

