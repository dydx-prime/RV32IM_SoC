
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2026 06:13:12 AM
// Design Name: 
// Module Name: top_uart_tb
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

`timescale 1ns / 1ps
module top_uart_tb;
  logic clk, reset, uart_txd;
  logic [31:0] currAddress;
  
  rv32i_notrap#(.MEMFILE ("instr.mem")) dut (.clk(clk), .reset(reset), .currAddress(currAddress), .uart_txd(uart_txd));
  
  always #5 clk = ~clk;
  
  initial begin
    reset = 1;
    clk = 0;
    repeat(2) @(posedge clk);
    reset = 0;
    
    repeat(17) @(posedge clk);
    $display(currAddress);
    $display("instruction: %h", dut.instruction);
  end
endmodule