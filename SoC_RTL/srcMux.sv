// one module definition shared between alu sources and regfile data write
//
// srcA selects between rs1 and pc, so data2 and 3 are tied to zero when instantiated
// srcB selects between rs2, imm, shamt so data3 is set to zero when instantiated
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
  
  // import pkg::*;
  
  //------ mux sources 
  localparam [2:0] NONE = 3'b000;
  
  // alu srcA
  localparam [2:0] ALU_INPUT_RS1    = 3'b001;
  localparam [2:0] ALU_INPUT_PC     = 3'b010;
  
  // alu srcB
  localparam [2:0] ALU_INPUT_RS2    = 3'b001;
  localparam [2:0] ALU_INPUT_IMM    = 3'b010;
  
  // register file write data
  localparam [2:0] REGFILE_LUI        = 3'b001;
  localparam [2:0] REGFILE_JUMP       = 3'b010;
  localparam [2:0] REGFILE_DATAMEM    = 3'b011;
  localparam [2:0] REGFILE_ALURESULT  = 3'b100;


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
