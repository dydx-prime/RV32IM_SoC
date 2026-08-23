module dataMemory(
  input clk,
  input isMemRead,
  input isMemWrite,
  input [31:0] address,
  input [31:0] rs2Data,
  input [2:0] funct3,

  output logic [31:0] memoryReadData
);

  logic [31:0] memory [0:4095];
  logic [31:0] word;
  logic [15:0] loadedHalf;
  logic [7:0] loadedByte;
  logic [3:0] byteEnable;
  logic [31:0] memoryWriteData;

  assign word = memory[address[31:2]];

  //------ load
  always @(*) begin
    memoryReadData = 32'b0;
    loadedByte = 8'b0;
    loadedHalf = 16'b0;
    if (isMemRead) begin
      case(address[1:0]) // find byte region
        2'b00: loadedByte = word[7:0];
        2'b01: loadedByte = word[15:8];
        2'b10: loadedByte = word[23:16];
        2'b11: loadedByte = word[31:24];
      endcase
      case(address[1]) // find half region
        1'b0: loadedHalf = word[15:0];
        1'b1: loadedHalf = word[31:16];
      endcase
      case(funct3) // set based on instruction
        3'b000: memoryReadData = {{24{loadedByte[7]}}, loadedByte}; //LB
        3'b001: memoryReadData = {{16{loadedHalf[15]}}, loadedHalf}; //LH
        3'b010: memoryReadData = word; //LW
        3'b100: memoryReadData = {24'b0, loadedByte}; //LBU
        3'b101: memoryReadData = {16'b0, loadedHalf}; //LHU
      endcase
    end
  end

  //------ store
  always @(*) begin
    byteEnable = 4'b0;
    memoryWriteData = rs2Data;
    if (isMemWrite) begin
      case(funct3)
        3'b000: begin // SB
          byteEnable = 4'b0001 << address[1:0];
          memoryWriteData = {24'b0, rs2Data[7:0]} << (8 * address[1:0]);
        end
        3'b001: begin // SH
          byteEnable = 4'b0011 << address[1:0];
          memoryWriteData = {16'b0, rs2Data[15:0]} << (8 * address[1:0]);
        end
        3'b010: byteEnable = 4'b1111; // SW
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if(isMemWrite) begin
      if(byteEnable[0]) memory[address[31:2]] [7:0]   <= memoryWriteData[7:0];
      if(byteEnable[1]) memory[address[31:2]] [15:8]  <= memoryWriteData[15:8];
      if(byteEnable[2]) memory[address[31:2]] [23:16] <= memoryWriteData[23:16];
      if(byteEnable[3]) memory[address[31:2]] [31:24] <= memoryWriteData[31:24];
    end
  end

endmodule

