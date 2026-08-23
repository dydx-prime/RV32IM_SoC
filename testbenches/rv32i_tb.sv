`timescale 1ns/1ps
module tb_check;
  logic clk = 0;
  logic reset = 1;
  logic [31:0] pc;
  int errors = 0;


  rv32i #(.MEMFILE("./../testbenches/prog.dat"))dut(.clk(clk), .reset(reset), .currAddress(pc));

  always #5 clk = ~clk;

  task automatic check(string name, logic [31:0] actual, logic [31:0] expected);
    if (actual !== expected) begin
      $display("  FAIL: %-6s got=%0d (0x%h) expected=%0d (0x%h)", name, actual, actual, expected, expected);
      errors++;
    end
    else begin
      $display("  PASS: %-6s = %0d", name, actual);
    end
  endtask

  // use for registers/memory that a taken branch or jump should have
  // caused your program to SKIP writing — checks "not the poison value"
  // rather than "equals a specific value", since unwritten regs are X.
  task automatic check_skipped(string name, logic [31:0] actual, logic [31:0] poison_value);
    if (actual === poison_value) begin
      $display("  FAIL: %-6s = %0d -> instruction that should have been skipped WAS executed", name, poison_value);
      errors++;
    end else begin
      $display("  PASS: %-6s was not written with poison value %0d (skipped correctly)", name, poison_value);
    end
  endtask

  // adjust cycle count to cover program length,
  // including any instructions skipped by taken branches/jumps
  localparam int RUN_CYCLES = 60;

  initial begin
    reset = 1;
    repeat(2) @(posedge clk);
    reset = 0;

    repeat(RUN_CYCLES) @(posedge clk);
    #1;

    $display("---- final state check ----");
    check("x0", dut.registerFile.register[0], 32'd0);
    check("x1", dut.registerFile.register[1], 32'd111);
    check("x2", dut.registerFile.register[2], 32'd42);
    check("x3", dut.registerFile.register[3], -32'd1);
    check("x4", dut.registerFile.register[4], 32'd65535);
    check("x5", dut.registerFile.register[5], 32'd77);
    check("x6", dut.registerFile.register[6], 32'd77);
    check("x7", dut.registerFile.register[7], 32'd666);
    check("x8", dut.registerFile.register[8], 32'd555);
    check("x9", dut.registerFile.register[9], 32'd444);
    check("x10", dut.registerFile.register[10], 32'd333);
    check("x11", dut.registerFile.register[11], -32'd1);
    check("x12", dut.registerFile.register[12], 32'd1);
    check("x13", dut.registerFile.register[13], 32'd0);
    check("x14", dut.registerFile.register[14], 32'd105);
    check("x15", dut.registerFile.register[15], 32'd1);

    check("x16", dut.registerFile.register[16], 32'd7);
    check("x17", dut.registerFile.register[17], 32'd0);
    check("x18", dut.registerFile.register[18], 32'd20);
    check("x19", dut.registerFile.register[19], 32'd10);
    check("x20", dut.registerFile.register[20], -32'd4);
    check("x21", dut.registerFile.register[21], 32'd1);
    check("x22", dut.registerFile.register[22], 32'd1);
    check("x23", dut.registerFile.register[23], 32'd305418240);
    check("x24", dut.registerFile.register[24], 32'd92);
    check("x25", dut.registerFile.register[25], -32'd1);
    check("x26", dut.registerFile.register[26], 32'd42);
    check("x27", dut.registerFile.register[27], 32'h078);
    check("x28", dut.registerFile.register[28], 32'd116);
    check("x29", dut.registerFile.register[29], 32'd77);
    check("x30", dut.registerFile.register[30], 32'd0);
    check("x31", dut.registerFile.register[31], 32'd512);
    
    
    check("mem80", dut.dmem.memory[32'h200 >> 2], 32'h2A);
    check("mem81", dut.dmem.memory[32'h204 >> 2], 32'hFFFF);
    check("mem82", dut.dmem.memory[32'h208 >> 2], 32'h4D);
    
    $display(pc);

    if (errors == 0)
      $display("\nALL CHECKS PASSED");
    else
      $display("\n%0d CHECK(S) FAILED", errors);


    $finish;

  end

endmodule

