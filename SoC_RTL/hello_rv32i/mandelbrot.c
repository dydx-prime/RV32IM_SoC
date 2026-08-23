#include <stdio.h>
#include <stdint.h>

/*
 * Q16.16 fixed-point: 32-bit signed integer, low 16 bits are the
 * fractional part. Range is roughly +-32768.0, resolution ~1.5e-5 --
 * comfortably enough for a Mandelbrot render at this zoom level.
 */
typedef int32_t fixed_t;

#define FIX_SHIFT 16
#define FIX_ONE   (1 << FIX_SHIFT)

static inline fixed_t int_to_fix(int i) {
    return (fixed_t)(i << FIX_SHIFT);
}

/* Fixed-point multiply: widen to 64 bits to avoid overflow on the
 * intermediate product, then shift back down. */
static inline fixed_t fix_mul(fixed_t a, fixed_t b) {
    int64_t prod = (int64_t)a * (int64_t)b;
    return (fixed_t)(prod >> FIX_SHIFT);
}

/* Fixed-point divide: widen the numerator before shifting so we don't
 * lose fractional precision. */
static inline fixed_t fix_div(fixed_t a, fixed_t b) {
    int64_t num = (int64_t)a << FIX_SHIFT;
    return (fixed_t)(num / b);
}

int main(void) {
#ifndef MANDEL_W
#define MANDEL_W 600
#endif
#ifndef MANDEL_H
#define MANDEL_H 400
#endif
#ifndef MANDEL_MAX_ITER
#define MANDEL_MAX_ITER 100
#endif
    const int w = MANDEL_W, h = MANDEL_H, max_iter = MANDEL_MAX_ITER;

    /* Constants from the original: w/1.5 and w/2.5, h/2.0 */
    fixed_t w_fix = int_to_fix(w);
    fixed_t h_fix = int_to_fix(h);

    /* Compute divisors directly in fixed point to keep this exact:
     * w/1.5 -> w * (2/3), w/2.5 -> w * (2/5), h/2.0 -> h * (1/2) */
    fixed_t cr_offset = fix_mul(w_fix, fix_div(int_to_fix(2), int_to_fix(3))); /* w/1.5 */
    fixed_t cr_scale  = fix_mul(w_fix, fix_div(int_to_fix(2), int_to_fix(5))); /* w/2.5 */
    fixed_t ci_scale  = fix_mul(h_fix, fix_div(int_to_fix(1), int_to_fix(2))); /* h/2.0 */

    fixed_t four = int_to_fix(4);

    printf("P2\n%d %d\n255\n", w, h);

    for (int y = 0; y < h; y++) {
        fixed_t ci = fix_div(int_to_fix(y) - ci_scale, ci_scale);

        for (int x = 0; x < w; x++) {
            fixed_t cr = fix_div(int_to_fix(x) - cr_offset, cr_scale);

            fixed_t zr = 0, zi = 0;
            int n = 0;

            while (n < max_iter) {
                fixed_t zr2_sq = fix_mul(zr, zr);
                fixed_t zi_sq  = fix_mul(zi, zi);
                if (zr2_sq + zi_sq >= four) break;

                fixed_t zr2 = zr2_sq - zi_sq + cr;
                zi = fix_mul(int_to_fix(2), fix_mul(zr, zi)) + ci;
                zr = zr2;
                n++;
            }

            printf("%d ", n == max_iter ? 0 : (n * 255 / max_iter));
        }
        printf("\n");
    }

    return 0;
}

