`timescale 1ns/1ps
module regfile_tb;
  logic clk, isRegfileWrite;
  logic [4:0] rs1, rs2, rd;
  logic [31:0] regfileWriteData;
  logic [31:0] rs1Data, rs2Data;

  regfile dut(
    .clk(clk),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .regfileWriteData(regfileWriteData),
    .isRegfileWrite(isRegfileWrite),

    .rs1Data(rs1Data),
    .rs2Data(rs2Data)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1;
    isRegfileWrite = 1;
    // set registers to value zero
    for(int i = 0; i < 32; i++)begin
      rd = i;
      regfileWriteData = 32'd0;
      @(posedge clk);
      @(posedge clk);
    end
      
    rs1 = 5'd0;
    rs2 = 5'd7;
    rd = 5'd7;
    regfileWriteData = 32'd100;
    isRegfileWrite = 0;
    @(posedge clk);
    @(posedge clk);
    assert(rs1Data == 32'd0) else $display(rs1Data);
    assert(rs2Data == 32'd0) else $display(rs2Data);
    isRegfileWrite = 1;
    @(posedge clk);
    @(posedge clk);
    assert(rs2Data == 32'd100) else $display(rs2Data);
    rd = 5'd0;
    @(posedge clk);
    @(posedge clk);
    assert(rs1Data == 32'd000) else $display(rs1Data);
    assert(rs2Data == 32'd100) else $display(rs2Data);
    $finish;
  end


endmodule
