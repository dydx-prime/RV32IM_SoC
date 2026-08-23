#include <stdio.h>
#include "uart.h"

int main() {
    int w = 600, h = 400, max_iter = 100;
    printf("P2\n%d %d\n255\n", w, h);
    
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            double cr = (x - w / 1.5) / (w / 2.5);
            double ci = (y - h / 2.0) / (h / 2.0);
            double zr = 0.0, zi = 0.0;
            int n = 0;
            
            while (zr * zr + zi * zi < 4.0 && n < max_iter) {
                double zr2 = zr * zr - zi * zi + cr;
                zi = 2.0 * zr * zi + ci;
                zr = zr2;
                n++;
            }
            
            //uart_puts("%d ", n == max_iter ? 0 : (n * 255 / max_iter));
        }
        uart_puts("\n");
    }
    return 0;
}
