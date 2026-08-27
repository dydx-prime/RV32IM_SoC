module controlUnit(
  input [6:0] opcode,
  input [6:0] funct7,
  input [2:0] funct3,
  input [31:0] imm,
 
  output logic isBranch,
  output logic isJump,
  output logic isMemRead,
  output logic isMemWrite,
  output logic isRegfileWrite,
  output logic [2:0] regfileWriteInputSrc,
  output logic [2:0] aluInputSrcA,
  output logic [2:0] aluInputSrcB,
  output logic [3:0] aluSel
);

  //import pkg::*;
  localparam [6:0] LUI = 7'b0110111;
  localparam [6:0] AUIPC = 7'b0010111;
  localparam [6:0] JAL = 7'b1101111;
  localparam [6:0] JALR = 7'b1100111;
  localparam [6:0] BRANCH = 7'b1100011;
  localparam [6:0] LOAD = 7'b0000011;
  localparam [6:0] STORE = 7'b0100011;
  localparam [6:0] ITYPE = 7'b0010011;
  localparam [6:0] RTYPE = 7'b0110011;
  localparam [6:0] FENCE_PAUSE = 7'b0001111;
  localparam [6:0] ECALL_EBREAK = 7'b1110011;

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

  //----------------- branches
  localparam [2:0] BEQ = 3'b000;
  localparam [2:0] BNE = 3'b001;
  localparam [2:0] BLT = 3'b100;
  localparam [2:0] BGE = 3'b101;
  localparam [2:0] BLTU = 3'b110;
  localparam [2:0] BGEU = 3'b111;
  
  // SRAI, SRLI, SLLI
  
  always @(*) begin
    isBranch              = 1'b0;
    isJump                = 1'b0;
    isMemRead             = 1'b0;
    isMemWrite            = 1'b0;
    isRegfileWrite        = 1'b0;
    regfileWriteInputSrc  = NONE;
    aluInputSrcA          = NONE;
    aluInputSrcB          = NONE;

    case(opcode) 
      LUI: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_LUI;
      end
      AUIPC: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_ALURESULT;
        aluInputSrcA = ALU_INPUT_PC;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      JAL: begin 
        isJump = 1'b1;
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_JUMP;
        aluInputSrcA = ALU_INPUT_PC;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      JALR: begin
        isJump = 1'b1;
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_JUMP;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      BRANCH: begin
        isBranch = 1'b1;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_RS2;
      end
      LOAD: begin
        isMemRead = 1'b1;
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_DATAMEM;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      STORE: begin
        isMemWrite = 1'b1;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
       end
      ITYPE: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_ALURESULT;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
        //aluInputSrcB = immLogicalShift ? ALU_INPUT_SHAMT: ALU_INPUT_IMM;
      end
      RTYPE: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_ALURESULT;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_RS2;
      end
      FENCE_PAUSE, ECALL_EBREAK:/* keep signals at zero */ ;
    endcase 
  end

  always @(*) begin
    aluSel = ALU_NOP;
    case(opcode)
      LUI, AUIPC, JAL, JALR, LOAD, STORE: aluSel = ALU_ADD;
      
      BRANCH: begin
        case(funct3)
          BEQ, BNE: aluSel = ALU_SUB; //BEQ, BNE
          BLT, BGE: aluSel = ALU_SLT; // BLT, BGE
          BLTU, BGEU: aluSel = ALU_SLTU; // BLTU, BGEU
          default: aluSel = ALU_NOP;
        endcase
      end

      ITYPE, RTYPE: begin
        case(funct3)
          3'b000: aluSel = funct7[5] ? ALU_SUB: ALU_ADD;
          3'b001: aluSel = ALU_SLL;
          3'b010: aluSel = ALU_SLT;
          3'b011: aluSel = ALU_SLTU;
          3'b100: aluSel = ALU_XOR;
          3'b101: aluSel = (imm[10] || funct7[5]) ? ALU_SRA : ALU_SRL;
          3'b110: aluSel = ALU_OR;
          3'b111: aluSel = ALU_AND;
          default: aluSel = ALU_NOP;
        endcase
      end
    endcase
  end

endmodule
