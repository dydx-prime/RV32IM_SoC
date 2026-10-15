// one module definition shared between alu sources and regfile data write
//
// srcA selects between rs1 and pc, so data2 and 3 are tied to zero when instantiated
// srcB selects between rs2, imm so data3 is set to zero when instantiated
// regfile write selects between lui, jump, data memory and alu result
//
// each case has the same values. to increase readability, they are set to
// definitions within pkg.sv
//
// repo may have a better definition for this module
module srcMux(
  input [2:0] sel,
  input [31:0] data0,
  input [31:0] data1,
  input [31:0] data2,
  input [31:0] data3,

  output reg [31:0] srcData
);
  
  import pkg::*;

  always_comb begin
    srcData = 32'b0;
    case(sel)
      NONE: srcData = 32'b0;
      ALU_INPUT_RS1, ALU_INPUT_RS2, REGFILE_LUI: srcData = data0; 
      ALU_INPUT_PC, ALU_INPUT_IMM, REGFILE_JUMP: srcData = data1;
      REGFILE_DATAMEM: srcData = data2;
      REGFILE_ALURESULT: srcData = data3;
      default: srcData = 32'b0;
    endcase
  end

endmodule
