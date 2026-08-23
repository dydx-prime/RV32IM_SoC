`timescale 1ns/1ps
module imem_tb;
  logic [31:0] pc, instruction;
  
  imem #(.FILE("./../testbenches/imemTestFile.dat"))dut(pc, instruction);

  initial begin
    pc = 32'd0;
    #1;
    // addi x27, x0, 120
    assert(instruction == 32'h07800d93) else $fatal(1, "instruction = 0x%h, expected = 07800d93", instruction);
    pc = 32'd4;
    #1;
    // beq x20, x13, 120
    assert(instruction == 32'h06da0c63) else $fatal(1, "instruction = 0x%h, expected = 06da0c63", instruction);
    pc = 32'd8;
    #1;
    // jal x1, 10
    assert(instruction == 32'h00a000ef) else $fatal(1, "instruction = 0x%h, expected = 00a000ef", instruction);
    $display("PASSED TEST CASES");
  end

endmodule;
