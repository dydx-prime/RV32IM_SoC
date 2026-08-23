#!/usr/bin/env bash
set -euo pipefail

PREFIX=riscv64-unknown-elf
# If your toolchain uses a different triple (e.g. riscv64-unknown-elf-gcc
# with -march=rv32i), change PREFIX below or export it before running.
PREFIX="${PREFIX:-riscv64-unknown-elf}"

CC=${PREFIX}-gcc
OBJCOPY=${PREFIX}-objcopy
OBJDUMP=${PREFIX}-objdump

# --specs=nosys.specs pulls in newlib's "nosys" stub set as a base, which
# we then override with our own syscalls.c (uart-backed _write, etc).
# Without --specs, ld won't find _exit/_sbrk/etc. at all and link fails
# outright rather than silently misbehaving.
#
# MANDEL_W/H/MAX_ITER let you shrink the render for a fast first test
# without touching mandelbrot.c. Override via environment, e.g.:
#   MANDEL_W=20 MANDEL_H=15 MANDEL_MAX_ITER=30 ./build.sh
MANDEL_W="${MANDEL_W:-600}"
MANDEL_H="${MANDEL_H:-400}"
MANDEL_MAX_ITER="${MANDEL_MAX_ITER:-100}"

CFLAGS="-march=rv32i -mabi=ilp32 -ffreestanding -O2 -Wall"
CFLAGS="$CFLAGS -DMANDEL_W=${MANDEL_W} -DMANDEL_H=${MANDEL_H} -DMANDEL_MAX_ITER=${MANDEL_MAX_ITER}"
LDFLAGS="-T link.ld -Wl,--no-relax --specs=nosys.specs"

SRC="crt0.S mandelbrot.c syscalls.c"
# Point SRC at main.c instead of mandelbrot.c to build the hello-world test:
#   SRC="crt0.S main.c syscalls.c"

echo "== Compiling =="
$CC $CFLAGS $LDFLAGS -o prog.elf $SRC

echo "== Size summary (check against IMEM=8K, DMEM=16K budgets) =="
${PREFIX}-size prog.elf

echo "== Section layout =="
$OBJDUMP -h prog.elf

echo "== Extracting .text =="
$OBJCOPY -O binary --only-section=.text prog.elf prog_text.bin

echo "== Extracting .rodata + .data =="
# .rodata/.data/.bss live at VMA 0x00100000 (see link.ld comment) purely to
# dodge ld's LMA-overlap check against .text. --change-addresses shifts
# everything down by that same amount so the extracted binary is 0-based,
# matching what dataMemory.sv actually indexes with address[31:2].
#
# .rodata and .data are placed back-to-back by link.ld with no gap between
# them, so extracting both together in ONE objcopy call (rather than two
# separate calls concatenated) preserves their correct relative offsets --
# important once a program has both, not just one.
DMEM_BASE=0x00100000
$OBJCOPY -O binary -j .rodata -j .data --change-addresses=-$DMEM_BASE prog.elf prog_data.bin 2>/dev/null || touch prog_data.bin

echo "== Converting to hex (\$readmemh format) =="
python3 bin2hex.py prog_text.bin prog.dat 2048
python3 bin2hex.py prog_data.bin data.dat 4096

echo "== Done =="
echo "  prog.dat  -> load into imem"
echo "  data.dat  -> load into dmem (initial .rodata/.data contents)"
ls -la prog.dat data.dat

