`timescale 1ns/1ps
module controlUnit_tb;
  logic [6:0] opcode;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [31:0] imm;
 
  logic isBranch;
  logic isJump;
  logic isMemRead;
  logic isMemWrite;
  logic isRegfileWrite;
  logic [2:0] regfileWriteInputSrc;
  logic [2:0] aluInputSrcA;
  logic [2:0] aluInputSrcB;
  logic [3:0] aluSel;

  controlUnit dut(
    .opcode(opcode),
    .funct7(funct7),
    .funct3(funct3),
    .imm(imm),

    .isBranch(isBranch),
    .isJump(isJump),
    .isMemRead(isMemRead),
    .isMemWrite(isMemWrite),
    .isRegfileWrite(isRegfileWrite),
    .regfileWriteInputSrc(regfileWriteInputSrc),
    .aluInputSrcA(aluInputSrcA),
    .aluInputSrcB(aluInputSrcB),
    .aluSel(aluSel)
  );

  int errors = 0;
  int call = 1;
  task automatic output_data(
    logic expected_isBranch,
    logic expected_isJump,
    logic expected_isMemRead,
    logic expected_isMemWrite,
    logic expected_isRegfileWrite,
    logic [2:0] expected_regfileWriteInputSrc,
    logic [2:0] expected_aluInputSrcA,
    logic [2:0] expected_aluInputSrcB,
    logic [3:0] expected_aluSel
  );
    #1; // time to make changes;

    assert(isBranch == expected_isBranch) else begin
      $display("call#%d , reason: isBranch - %b", call, isBranch);
      errors++;
    end

    assert(isJump == expected_isJump) else begin
      $display("call#%d , reason: isJump - %b", call, isJump);
      errors++;
    end

    assert(isMemRead == expected_isMemRead) else begin
      $display("call#%d , reason: isMemRead - %b", call, isMemRead);
      errors++;
    end

    assert(isMemWrite == expected_isMemWrite) else begin 
      $display("call#%d , reason: isMemWrite - %b", call, isMemWrite);
      errors++;
    end

    assert(isRegfileWrite == expected_isRegfileWrite) else begin
      $display("call#%d , reason: isRegfileWrite - %b", call, isRegfileWrite);
      errors++;
    end

    assert(regfileWriteInputSrc == expected_regfileWriteInputSrc) else begin
      $display("call#%d , reason: regfileWriteInputSrc - %b", call, regfileWriteInputSrc);
      errors++;
    end

    assert(aluInputSrcA == expected_aluInputSrcA) else begin
      $display("call#%d , reason: aluInputSrcA - %b", call, aluInputSrcA);
      errors++;
    end

    assert(aluInputSrcB == expected_aluInputSrcB) else begin
      $display("call#%d , reason: aluInputSrcB - %b", call, aluInputSrcB);
      errors++;
    end

    assert(aluSel == expected_aluSel) else begin
      $display("call#%d , reason: aluSel - %b", call, aluSel);
      errors++;
    end

    call++;
  endtask

  import pkg::*;
  initial begin
    // LUI x10,24
    opcode = LUI; funct7 = 7'b0; funct3 = 3'b0; imm = 32'd24;
    output_data(0, 0, 0, 0, 1, REGFILE_LUI, NONE, NONE, ALU_ADD);
   
    // auipc x20, 40
    opcode = AUIPC; funct7 = 7'b0; funct3 = 3'b0; imm = 32'h0002_8000;
    output_data(0, 0, 0, 0, 1, REGFILE_ALURESULT, ALU_INPUT_PC, ALU_INPUT_IMM, ALU_ADD);
    
    // jal x2, 40
    opcode = JAL; funct7 = 7'b0; funct3 = 3'b0; imm = 32'h0000_0028;
    output_data(0, 1, 0, 0, 1, REGFILE_JUMP, ALU_INPUT_PC, ALU_INPUT_IMM, ALU_ADD);

    // beq x18, x12, 16
    opcode = BRANCH; funct7 = 7'b0; funct3 = 3'b0; imm = 32'h0000_0010;
    output_data(1, 0, 0, 0, 0, NONE, ALU_INPUT_RS1, ALU_INPUT_RS2, ALU_SUB);

    // lb x31, 18(x9)
    opcode = LOAD; funct7 = 7'b0; funct3 = 3'b0; imm = 32'h0000_0012;
    output_data(0, 0, 1, 0, 1, REGFILE_DATAMEM, ALU_INPUT_RS1, ALU_INPUT_IMM, ALU_ADD);
    
    // sb x31, 18(x9)
    opcode = STORE; funct7 = 7'b0; funct3 = 3'b0; imm = 32'h0000_0012;
    output_data(0, 0, 0, 1, 0, NONE, ALU_INPUT_RS1, ALU_INPUT_IMM, ALU_ADD);

    // slti x29, x17, 99
    opcode = ITYPE; funct7 = 7'b0; funct3 = 3'b010; imm = 32'h0000_0063;
    output_data(0, 0, 0, 0, 1, REGFILE_ALURESULT, ALU_INPUT_RS1, ALU_INPUT_IMM, ALU_SLT);

    // srai x29, x17, 25
    opcode = ITYPE; funct7 = 7'b0; funct3 = 3'b101; imm = 32'h0000_0419;
    output_data(0, 0, 0, 0, 1, REGFILE_ALURESULT, ALU_INPUT_RS1, ALU_INPUT_SHAMT, ALU_SRA);

    // xor x13, x11, x12
    opcode = RTYPE; funct7 = 7'b0; funct3 = 3'b100; imm = 32'h0;
    output_data(0, 0, 0, 0, 1, REGFILE_ALURESULT, ALU_INPUT_RS1, ALU_INPUT_RS2, ALU_XOR);

    $finish;
  end
endmodule
