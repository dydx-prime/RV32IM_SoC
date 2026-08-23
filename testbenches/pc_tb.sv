`timescale 1ns/1ps
module pc_tb;
  logic clk, reset;
  logic [31:0] nextPC, pc;
  pc programCounter(
    .clk(clk),
    .reset(reset),
    .nextPC(nextPC),
    .pc(pc)
  );

  always #5 clk = ~clk;

  logic [1:0] count = 2'd0;

  initial begin
    clk = 0;
    reset = 1;
    nextPC = 32'd8;
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    assert (pc == 32'd0) else $fatal(1, "pc = %02d, expected = 0", pc);
    @(posedge clk);
    @(posedge clk);
    assert (pc == 32'd8) else $fatal(1, "pc = %02d, expected = 8", pc);
    $display("PASSED TEST CASES");
    $finish;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, pc_tb);
  end
endmodule

