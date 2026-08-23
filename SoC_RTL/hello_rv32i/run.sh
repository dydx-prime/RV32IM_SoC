#!/usr/bin/env bash
set -euo pipefail

# Run from the sim/ directory. Adjust SRC_DIR if your .sv files live
# somewhere else relative to this script.
SRC_DIR="${SRC_DIR:-..}"

PKG_FILE="${SRC_DIR}/pkg.sv"

TOP=SoC

echo "== Verilating =="
# Globs every .sv file in SRC_DIR -- if your modules are split across
# multiple directories, add more -I/glob lines or list files explicitly.
verilator \
  --cc \
  --exe \
  --build \
  -j 0 \
  --trace \
  -Wall \
  -Wno-DECLFILENAME \
  -Wno-fatal\
  --top-module ${TOP} \
  -I"${SRC_DIR}" \
  "$PKG_FILE"\
  $(find "${SRC_DIR}" -maxdepth 1 -name '*.sv' ! -name "$(basename "$PKG_FILE")") \
  tb_soc.cpp \
  -o Vsoc_sim

echo "== Running =="
# imem.sv / dataMemory.sv load prog.dat / data.dat via relative $readmemh
# paths, so those files must exist in the CURRENT directory at runtime.
# Copy them in from the build output if they're not already here.
if [ ! -f prog.dat ] && [ -f "${SRC_DIR}/../hello_rv32i/prog.dat" ]; then
  cp "${SRC_DIR}/../hello_rv32i/prog.dat" .
fi
if [ ! -f prog.dat ] && [ -f "${SRC_DIR}/prog.dat" ]; then
  cp "${SRC_DIR}/prog.dat" .
fi
if [ ! -f data.dat ] && [ -f "${SRC_DIR}/data.dat" ]; then
  cp "${SRC_DIR}/data.dat" .
fi
if [ ! -f prog.dat ] || [ ! -f data.dat ]; then
  echo "ERROR: prog.dat and/or data.dat not found in $(pwd) or ${SRC_DIR}."
  echo "Run build.sh first, or copy the .dat files into sim/ manually."
  exit 1
fi

./obj_dir/Vsoc_sim

echo "== Waveform written to waveform.vcd (open with gtkwave) =="

