//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:46:42 PM
// Design Name: 
// Module Name: rv32i_notrap
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


module rv32i_notrap #(parameter MEMFILE = "instr.mem")(
  input clk_100_MHz,
  input reset,

 // output logic [31:0] currAddress, // pc
  output uart_txd
);
 
 wire clk;
 // 65 MHz clock
 clk_wiz_0 mcm (.clk_in1(clk_100_MHz), .clk_out1(clk)); 
  
  logic [31:0] nextPC, nextPC_aligned;
  wire [31:0] branchAddress;
  wire branchTaken;
  wire isJump;
  wire [31:0] aluResult;
  wire [31:0] pc;
  wire [31:0] pcPlus4;

  //assign currAddress = pc;
  assign nextPC = branchTaken ? branchAddress: isJump ? aluResult: pcPlus4;
  assign nextPC_aligned = {nextPC[31:1], 1'b0};

  pc programCounter(
    .clk(clk),
    .reset(reset),
    .nextPC(nextPC_aligned),

    .pc(pc)
  );
  
  pc4 pc_4(
    .pc(pc),

    .pcPlus4(pcPlus4)
  );
  
  wire [31:0] instruction;
  imem #(.FILE(MEMFILE))instructionMemory(
    .pc(pc),

    .instruction(instruction)
  );

  wire [6:0] opcode ,funct7;
  wire [2:0] funct3;
  wire [4:0] rs1, rs2, rd;
  wire [31:0] imm;
  instrDecoder decoder(
    .instruction(instruction),
  
    .opcode(opcode),
    .funct7(funct7),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(imm)
  );
  
  wire isBranch, isMemRead, isMemWrite, isRegfileWrite;
  wire [2:0] regfileWriteInputSrc, aluInputSrcA, aluInputSrcB;
  wire [3:0] aluSel;
  controlUnit controlU(
    .opcode(opcode),
    .funct7(funct7),
    .funct3(funct3),
    .imm(imm),
 
    .isBranch(isBranch),
    .isJump(isJump),
    .isMemRead(isMemRead),
    .isMemWrite(isMemWrite),
    .isRegfileWrite(isRegfileWrite),
    .regfileWriteInputSrc(regfileWriteInputSrc),
    .aluInputSrcA(aluInputSrcA),
    .aluInputSrcB(aluInputSrcB),
    .aluSel(aluSel)
  );
  
  wire [31:0] regfileWriteData;
  wire [31:0] memoryReadData;
  srcMux regfileSrc(
    .sel(regfileWriteInputSrc),
    .data0(imm),
    .data1(pcPlus4),
    .data2(memoryReadData),
    .data3(aluResult),

    .srcData(regfileWriteData)
  );
  
  wire [31:0] rs1Data, rs2Data;
  regfile registerFile(
    .clk(clk),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .regfileWriteData(regfileWriteData),
    .isRegfileWrite(isRegfileWrite),

    .rs1Data(rs1Data),
    .rs2Data(rs2Data)
  );
  
  wire [31:0] srcA;
  srcMux aluSrcA(
    .sel(aluInputSrcA),
    .data0(rs1Data),
    .data1(pc),
    .data2(32'b0),
    .data3(32'b0),

    .srcData(srcA)
  );
  
  wire [31:0] srcB;
  srcMux aluSrcB(
    .sel(aluInputSrcB),
    .data0(rs2Data),
    .data1(imm),
    .data2(32'b0),
    .data3(32'b0),

    .srcData(srcB)
  );
  
  wire resultIsZero;
  alu arithmetic(
    .srcA(srcA),
    .srcB(srcB),
    .sel(aluSel),
   
    .aluResult(aluResult),
    .resultIsZero(resultIsZero)
  );

  dataMemory #(.clk_freq_hz(60_000_000), .baud(115200)) dmem(
    .clk(clk),
    .rst(reset),
    .isMemRead(isMemRead),
    .isMemWrite(isMemWrite),
    .address(aluResult),
    .rs2Data(rs2Data),
    .funct3(funct3),

    .memoryReadData(memoryReadData),
    .uart_txd(uart_txd)
  );

  
  branchUnit branch(
    .resultIsZero(resultIsZero),
    .isBranch(isBranch),
    .pc(pc),
    .imm(imm),
    .funct3(funct3),
  
    .branchTaken(branchTaken),
    .branchAddress(branchAddress)
  );

endmodule

