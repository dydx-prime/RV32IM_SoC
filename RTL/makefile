TEST_MODULES = rv32i.sv
ALL_MODULES = rv32i.sv alu.sv branchUnit.sv controlUnit.sv dataMemory.sv imem.sv instrDecoder.sv pc.sv pc4.sv regfile.sv srcMux.sv
PACKAGES = pkg.sv
TESTBENCH = ./../testbenches/rv32i_tb.sv
TEST_FILE_DATA = ./../testbenches/prog.dat
run:
	iverilog -g2023 -o out ${PACKAGES} ${ALL_MODULES} ${TESTBENCH}
	vvp out
eval:
	iverilog -g2023 -o out ${PACKAGES} ${ALL_MODULES}
wave:
	gtkwave wave.vcd
