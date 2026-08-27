`ifndef PKG_SV
`define PKG_SV
package pkg;
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

  //-----------------
  typedef enum logic [6:0] {
    LUI = 7'b0110111,
    AUIPC = 7'b0010111,
    JAL = 7'b1101111,
    JALR = 7'b1100111,
    BRANCH = 7'b1100011,
    LOAD = 7'b0000011,
    STORE = 7'b0100011,
    ITYPE = 7'b0010011,
    RTYPE = 7'b0110011,
    FENCE_PAUSE = 7'b0001111,
    ECALL_EBREAK = 7'b1110011  
  } ISAopcodes_t;

  //----------------- alu sel
   localparam [3:0] ALU_ADD   = 4'b0001;
   localparam [3:0] ALU_SUB   = 4'b0010;
   localparam [3:0] ALU_SLL   = 4'b0011;
   localparam [3:0] ALU_SLT   = 4'b0100;
   localparam [3:0] ALU_SLTU  = 4'b0101;
   localparam [3:0] ALU_XOR   = 4'b0110;
   localparam [3:0] ALU_SRL   = 4'b0111;
   localparam [3:0] ALU_SRA   = 4'b1000;
   localparam [3:0] ALU_OR    = 4'b1001;
   localparam [3:0] ALU_AND   = 4'b1010;
   localparam [3:0] ALU_NOP   = 4'b1111;
   

  //----------------- branches
  localparam [2:0] BEQ = 3'b000;
  localparam [2:0] BNE = 3'b001;
  localparam [2:0] BLT = 3'b100;
  localparam [2:0] BGE = 3'b101;
  localparam [2:0] BLTU = 3'b110;
  localparam [2:0] BGEU = 3'b111;

  //----------------- opcodes


endpackage

`endif
