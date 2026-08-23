/*
 * IMEM and DMEM are physically separate arrays in the Verilog (imem.sv,
 * dataMemory.sv), each indexed starting at word 0 in hardware. GNU ld,
 * however, refuses to let two output sections share the same LMA range
 * (the address it uses for its overlap check), even though .text and
 * .rodata/.data/.bss really do live in two different physical memories.
 *
 * Fix used here: give DMEM a real ORIGIN of 0x00100000 -- comfortably
 * past IMEM's 8K -- so ld sees no overlap. This means _stack_top,
 * __bss_start/__bss_end, and every symbol/pointer into .data/.bss will
 * resolve to addresses like 0x00100xxx, and `sp` and the .bss-zeroing
 * loop in crt0.S will genuinely compute and use those values at runtime.
 *
 * dataMemory.sv therefore MUST subtract 0x00100000 before indexing its
 * array (e.g. `(address - 32'h00100000) >> 2`), OR you widen dmem's
 * address decode to treat 0x00100000..0x00103FFF as the valid dmem
 * range. build.sh's --change-addresses=-0x00100000 step only fixes up
 * the *initial contents* written into data.dat -- it has no effect on
 * what address value crt0.S/main.c actually compute and use at runtime.
 * If dataMemory.sv is not updated to match, loads/stores will silently
 * miss the real array (out-of-range index) and stack/global access
 * will break.
 */

MEMORY
{
  IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 8K    /* imem: 2048 x 32-bit words */
  DMEM (rw) : ORIGIN = 0x00100000, LENGTH = 16K   /* dmem VMA region: fake gap above IMEM, ld-overlap-safe */
}

ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text : {
    *(.text.start)   /* crt0 first, guarantees _start lands at address 0 */
    *(.text*)
  } > IMEM

  .rodata : { *(.rodata*) } > DMEM
  . = ALIGN(4);
  .data   : { *(.data*)   } > DMEM

  . = ALIGN(4);
  .bss : {
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    __bss_end = .;
  } > DMEM

  . = ALIGN(4);
  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM) - 4;

  /DISCARD/ : { *(.comment) *(.riscv.attributes) }
}

