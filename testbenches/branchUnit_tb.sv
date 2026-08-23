`timescale 1ns/1ps
module branchUnit_tb;
  logic resultIsZero, isBranch;
  logic [31:0] pc, imm;
  logic [2:0] funct3;

  logic branchTaken;
  logic [31:0] branchAddress;

  branchUnit dut(
  .resultIsZero(resultIsZero),
  .isBranch(isBranch),
  .pc(pc),
  .imm(imm),
  .funct3(funct3),

  .branchTaken(branchTaken),
  .branchAddress(branchAddress)
  );

  import pkg::*;

  initial begin
    resultIsZero = 1;
    isBranch = 1;
    pc = 32'd8;
    imm = 32'd12;
    funct3 = BEQ;
    #1;
    assert(branchTaken == 1);
    assert(branchAddress == 32'd20);
    funct3 = BNE;
    #1
    assert(branchTaken == 0);
    assert(branchAddress == 32'd12);
    resultIsZero = 0;
    #1;
    assert(branchTaken == 1);
    assert(branchAddress == 32'd20);
    funct3 = BEQ;
    #1;
    assert(branchTaken == 0);
    assert(branchAddress == 32'd12);
    $finish;
  end

endmodule
