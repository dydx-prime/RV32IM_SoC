// CSRRW rd, csr, rs1	    rd = old CSR; CSR = rs1
// CSRRS rd, csr, rs1	    rd = old CSR; CSR = CSR | rs1
// CSRRC rd, csr, rs1	    rd = old CSR; CSR = CSR & ~rs1
// CSRRWI rd, csr, uimm	  rd = old CSR; CSR = uimm
// CSRRSI rd, csr, uimm	  rd = old CSR; CSR = CSR | uimm
// CSRRCI rd, csr, uimm	  rd = old CSR; CSR = CSR & ~uimm

module csr #(parameter MXLEN = 32)(
  input clk,
  input reset,
  input csrWrEn,
  input csrReadEn,
  input [11:0] csrAddress,
  input [31:0] csrWriteData,

  output [31:0] csrReadData
);

  logic [MXLEN-1:0] misa; 
  logic [31:0] mvendorid; 
  logic [MXLEN-1:0] marchid;
  logic [MXLEN-1:0] mimpid;
  logic [MXLEN-1:0] mhartid;

  logic [MXLEN-1:0] mstatus;
  logic [MXLEN-1:0] mstatush;

  logic [63:0] mcycle;
  logic [63:0] minstret;
  logic [MXLEN-1:0] mscratch;
  logic [MXLEN-1:0] mepc;
  logic [MXLEN-1:0] mcause;
  


endmodule
