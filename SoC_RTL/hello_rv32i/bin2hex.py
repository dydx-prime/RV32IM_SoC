#!/usr/bin/env python3
"""
Convert a raw binary file into a $readmemh-compatible hex file.

Usage: bin2hex.py <input.bin> <output.dat> <word_count>

Each output line is one 32-bit word, hex, no '0x' prefix, matching what
$readmemh expects. Input bytes are interpreted little-endian per word
(standard for RISC-V). Any words beyond the input file's length are
zero-padded, so the .dat file always has exactly <word_count> lines.
"""
import sys


def bin_to_hex(infile: str, outfile: str, words: int) -> None:
    with open(infile, "rb") as f:
        data = f.read()

    max_bytes = words * 4
    if len(data) > max_bytes:
        raise SystemExit(
            f"ERROR: {infile} is {len(data)} bytes, "
            f"exceeds {words} words ({max_bytes} bytes). "
            f"Program too large for this memory region."
        )

    with open(outfile, "w") as f:
        for i in range(words):
            offset = i * 4
            chunk = data[offset:offset + 4]
            chunk = chunk + b"\x00" * (4 - len(chunk))  # pad final partial word
            word = int.from_bytes(chunk, byteorder="little")
            f.write(f"{word:08x}\n")

    print(f"{infile} ({len(data)} bytes) -> {outfile} ({words} words)")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)
    bin_to_hex(sys.argv[1], sys.argv[2], int(sys.argv[3]))

