`timescale 1ns/1ps
module instrDecoder_tb;
  logic [31:0] instruction;
  logic [6:0] opcode, funct7;
  logic [2:0] funct3;
  logic [4:0] rs1, rs2, rd;
  logic [31:0] imm;

  instrDecoder dut(
    .instruction(instruction),

    .opcode(opcode),
    .funct7(funct7),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(imm)
  );
  
  int errors = 0;
  task automatic output_data(
    logic [6:0] expected_opcode,
    logic [6:0] expected_funct7,
    logic [2:0] expected_funct3,
    logic [4:0] expected_rs1,
    logic [4:0] expected_rs2,
    logic [4:0] expected_rd,
    logic [31:0] expected_imm
  );
    #1; // time to make changes;

    assert(opcode == expected_opcode) else begin
      $display("instruction: %h failed, reason: opcode - %b", instruction, opcode);
      errors++;
    end

    assert(funct7 == expected_funct7) else begin
      $display("instruction: %h failed reason: funct7 - %b" , instruction, funct7);
      errors++;
    end

    assert(funct3 == expected_funct3) else begin
      $display("instruction: %h failed reason: funct3 - %b", instruction, funct3);
      errors++;
    end

    assert(rs1 == expected_rs1) else begin 
      $display("instruction: %h failed, reason: rs1 - x%d", instruction, rs1);
      errors++;
    end

    assert(rs2 == expected_rs2) else begin
      $display("instruction: %h failed, reason: rs2 - x%d", instruction, rs2);
      errors++;
    end

    assert(rd == expected_rd) else begin
      $display("instruction: %h failed, reason: rd - x%d", instruction, rd);
      errors++;
    end

    assert(imm == expected_imm) else begin
      $display("instruction: %h failed, reason: imm - %h", instruction, imm);
      errors++;
    end
  endtask

  import pkg::*;
  initial begin 
    instruction = 32'h0001_4537; // lui x10, 20
    output_data(LUI, 7'b0, 3'b0, 5'b0, 5'b0, 5'd10, 32'h0001_4000);
    
    instruction = 32'h0002_8a17; // auipc x20, 40
    output_data(AUIPC, 7'b0, 3'b0, 5'b0, 5'b0, 5'd20, 32'h0002_8000);

    instruction = 32'h0280_016f; // jal x2, 40
    output_data(JAL, 7'b0, 3'b0, 5'b0, 5'b0, 5'd2, 32'h0000_0028);

    instruction = 32'h00c9_0863; // beq x18, x12, 16
    output_data(BRANCH, 7'b0, 3'b0, 5'd18, 5'd12, 5'd0, 32'h0000_0010);
 
    instruction = 32'h0124_8f83; // lb x31, 18(x9)
    output_data(LOAD, 7'b0, 3'b0, 5'd9, 5'd0, 5'd31, 32'h0000_0012);
    
    instruction = 32'h01f4_8923; // sb x31, 18(x9)
    output_data(STORE, 7'b0, 3'b0, 5'd9, 5'd31, 5'd0, 32'h0000_0012);
    
    instruction = 32'h0638_ae93; // slti x29, x17, 99
    output_data(ITYPE, 7'b0, 3'b010, 5'd17, 5'd0, 5'd29, 32'h0000_0063);

    instruction = 32'h4198de93; // srai x29, x17, 25
    output_data(ITYPE, 7'b0, 3'b101, 5'd17, 5'd0, 5'd29, 32'h0000_0419);
    
    instruction = 32'h00c5_c6b3; // xor x13, x11, x12
    output_data(RTYPE, 7'b0, 3'b100, 5'd11, 5'd12, 5'd13, 32'h0);

    if(errors == 0) $display("PASSED TEST CASES");
  end

endmodule


    /*
    logic expected_isBranch,
    logic expected_isJump,
    logic expected_isMemRead,
    logic expected_isMemWrite,
    logic expected_isRegfileWrite,
    logic [2:0] expected_regfileWriteInputSrc,
    logic [2:0] expected_aluInputSrcA,
    logic [2:0] expected_aluInputSrcB,
    logic [3:0] aluSel
    */
