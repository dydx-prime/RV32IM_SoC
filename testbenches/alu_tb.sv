`timescale 1ns/1ps
module alu_tb;
  logic [31:0] srcA, srcB;
  logic [3:0] sel;

  logic [31:0] aluResult;
  logic resultIsZero;

  alu dut(
    .srcA(srcA),
    .srcB(srcB),
    .sel(sel),
    .aluResult(aluResult),
    .resultIsZero(resultIsZero)
  );

  import pkg::*;

  initial begin
    srcA = -5;
    srcB = 2;

    sel = ALU_ADD;
    #1;
    assert(aluResult == -32'd3);
    assert(resultIsZero == 0);

    sel = ALU_SUB;
    #1;
    assert(aluResult == -32'd7);
    assert(resultIsZero == 0);

    sel = ALU_SLL;
    #1;
    assert(aluResult == -32'd20);
    assert(resultIsZero == 0);

    sel = ALU_SLT;
    #1;
    assert(aluResult == 32'd1);
    assert(resultIsZero == 0);

    sel = ALU_SLTU;
    #1;
    assert(aluResult == 32'd0);
    assert(resultIsZero == 1);

    sel = ALU_XOR;
    #1;
    assert(aluResult == -32'd7);
    assert(resultIsZero == 0);

    sel = ALU_SRL;
    #1;
    assert(aluResult == 32'h3fff_fffe);
    assert(resultIsZero == 0);

    sel = ALU_SRA;
    #1;
    assert(aluResult == 32'hffff_fffe);
    assert(resultIsZero == 0);

    sel = ALU_OR;
    #1;
    assert(aluResult == -32'd5);
    assert(resultIsZero == 0);


    sel = ALU_AND;
    #1;
    assert(aluResult == 32'd2);
    assert(resultIsZero == 0);
    
    $finish;
  end
endmodule
