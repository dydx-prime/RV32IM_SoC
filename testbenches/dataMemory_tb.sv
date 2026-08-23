`timescale 1ns/1ps
module dataMemory_tb;
  logic clk, isMemRead, isMemWrite;
  logic [31:0] address, rs2Data;
  logic [2:0] funct3;
  
  logic [31:0] memoryReadData;

  dataMemory dut(
    .clk(clk),
    .isMemRead(isMemRead),
    .isMemWrite(isMemWrite),
    .address(address),
    .rs2Data(rs2Data),
    .funct3(funct3),

    .memoryReadData(memoryReadData)
  );

  always #5 clk = ~clk;

  localparam [2:0] LB = 3'b000, LH = 3'b001, LW = 3'b010, LBU = 3'b100, LHU = 3'b101;
  localparam [2:0] SB = 3'b000, SH = 3'b001, SW = 3'b010;

  task automatic store(
    [2:0] store_type
  );
    funct3 = store_type;
    isMemRead = 0;
    isMemWrite = 1;
    repeat(2) @(posedge clk);
  endtask
 
  task automatic load(
    [2:0] load_type
  );
    funct3 = load_type;
    isMemRead = 1;
    isMemWrite = 0;
    repeat(2) @(posedge clk);
  endtask

  task automatic reset();
    rs2Data = 32'h0;
    store(SW);
    repeat(3) @(posedge clk);
    rs2Data = 32'h0001_f400;
    repeat(2) @(posedge clk);
    
  endtask
  initial begin
    clk = 1;
    address = 32'h200;
    rs2Data = 32'h0001_f400;
    store(SW);
    load(LB);
    assert(memoryReadData == 32'd0) else $display(memoryReadData);
    load(LH);
    assert(memoryReadData == 32'hffff_f400) else $display(memoryReadData);
    load(LW);
    assert(memoryReadData == 32'h0001_f400) else $display(memoryReadData);
    load(LBU);
    assert(memoryReadData == 32'h0) else $display(memoryReadData);
    load(LHU);
    assert(memoryReadData == 32'h0000_f400) else $display(memoryReadData);

    reset();

    store(SH);
    load(LB);
    assert(memoryReadData == 32'd0) else $display(memoryReadData);
    load(LH);
    assert(memoryReadData == 32'hffff_f400) else $display(memoryReadData);
    load(LW);
    assert(memoryReadData == 32'h0001_f400) else $display(memoryReadData);
    load(LBU);
    assert(memoryReadData == 32'h0) else $display(memoryReadData);
    load(LHU);
    assert(memoryReadData == 32'h0000_f400) else $display(memoryReadData);
    
    reset();

    store(SB);
    load(LB);
    assert(memoryReadData == 32'd0) else $display(memoryReadData);
    load(LH);
    assert(memoryReadData == 32'hffff_f400) else $display(memoryReadData);
    load(LW);
    assert(memoryReadData == 32'h0001_f400) else $display(memoryReadData);
    load(LBU);
    assert(memoryReadData == 32'h0) else $display(memoryReadData);
    load(LHU);
    assert(memoryReadData == 32'h0000_f400) else $display(memoryReadData);
    $finish;
  end

endmodule
