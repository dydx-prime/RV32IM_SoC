//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:45:04 PM
// Design Name: 
// Module Name: controlUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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

  import pkg::*;
  
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
      FENCE_PAUSE: /* keep signals at zero */;

      SYSTEM: begin // or environment
        //isCSR = (funct3 != 3'b0);
        aluInputSrcA = funct3[2] ? ALU_INPUT_UIMM : ALU_INPUT_RS1;
        aluInputSrcB = (funct3 == CSRRS || funct3 == CSRRC || funct3 == CSRRSI || funct3 == CSRRCI) ?
                       ALU_INPUT_CSR : NONE;
      end
    endcase 
  end
  
  always @(*) begin
    aluSel = ALU_NOP;
    case(opcode)
      LUI, AUIPC, JAL, JALR, LOAD, STORE: aluSel = ALU_ADD;
      
      BRANCH: begin
        case(funct3)
          BEQ, BNE: aluSel = ALU_SUB; 
          BLT, BGE: aluSel = ALU_SLT;
          BLTU, BGEU: aluSel = ALU_SLTU; 
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
