`timescale 1ns/1ps
module pc4_tb;
  logic [31:0] pc, pcPlus4;

  pc4 dut(pc, pcPlus4);
  
  initial begin
    pc = 32'd4;
    #10;
    assert(pcPlus4 == 32'd8) else $fatal(1, "pcPlus4 = %02d, expected = 8", pcPlus4);
    $display("PASSED TEST CASES");
    $finish;
  end


endmodule
