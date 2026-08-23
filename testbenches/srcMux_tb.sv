`timescale 1ns/1ps
module srcMux_tb;
  logic [2:0] sel;
  logic [31:0] data0, data1, data2, data3;
  logic [31:0] srcData;

  srcMux dut(
    .sel(sel),
    .data0(data0),
    .data1(data1),
    .data2(data2),
    .data3(data3),

    .srcData(srcData)
  );
  
  import pkg::*;

  initial begin
    sel = NONE;
    data0 = 32'd50;
    data1 = 32'd100;
    data2 = 32'd200;
    data3 = 32'd400;
    #1;
    assert(srcData == 32'd0);
    sel = 3'd1;
    #1;
    assert(srcData == data0);
    sel = 3'd2;
    #1;
    assert(srcData == data1);
    sel = 3'd3;
    #1;
    assert(srcData == data2);
    sel = 3'd4;
    #1;
    assert(srcData == data3);
    $finish;
  end

endmodule
