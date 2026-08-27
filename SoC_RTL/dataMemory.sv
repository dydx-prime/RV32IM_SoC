module dataMemory(
  input clk,
  input isMemRead,
  input isMemWrite,
  input [31:0] address,
  input [31:0] rs2Data,
  input [2:0] funct3,
  output logic [31:0] memoryReadData,
  output wire        uart_valid,
  output wire [7:0]  uart_wdata,
  input  wire        uart_ready
);
  // DMEM lives at VMA 0x00100000..0x00103FFF (see link.ld). This offset
  // exists purely so GNU ld doesn't see .text (IMEM, based at 0x0) and
  // .rodata/.data/.bss (DMEM) as overlapping LMA ranges. sp, __bss_start,
  // __bss_end, and every C pointer into .data/.bss are REAL runtime
  // addresses in this 0x00100000-based range -- so we decode it here
  // rather than pretending dmem is still 0-based.
  localparam DMEM_BASE = 32'h0010_0000;
  localparam DMEM_SIZE = 32'h0000_4000; // 16K bytes = 4096 words

  localparam UART_TX_ADDR   = 32'hFFFF_FFF0;
  localparam UART_STAT_ADDR = 32'hFFFF_FFF4;

  wire is_uart_tx   = (address == UART_TX_ADDR);
  wire is_uart_stat = (address == UART_STAT_ADDR);
  wire is_dmem      = (address >= DMEM_BASE) && (address < (DMEM_BASE + DMEM_SIZE));

  // Word index into the 4096-entry array, using the OFFSET from DMEM_BASE,
  // not the raw address -- this is the actual fix for the aliasing bug.
  wire [31:0] dmem_offset = address - DMEM_BASE;
  wire [11:0] dmem_index  = dmem_offset[13:2]; // 4096 words -> 12-bit index

  assign uart_valid = isMemWrite & is_uart_tx;
  assign uart_wdata  = rs2Data[7:0];

  logic [31:0] memory [0:12]; // 4096
  logic [31:0] word;
  logic [15:0] loadedHalf;
  logic [7:0] loadedByte;
  logic [3:0] byteEnable;
  logic [31:0] memoryWriteData;

  assign word = memory[dmem_index];

  //------ load
  always @(*) begin
    memoryReadData = 32'b0;
    loadedByte = 8'b0;
    loadedHalf = 16'b0;
    if (isMemRead) begin
      if (is_uart_stat) begin
        memoryReadData = {31'b0, uart_ready}; // poll bit 0 before writing UART
      end else if (is_dmem) begin
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
      // else: address matches nothing decoded (out of range) -> reads 0
    end
  end

  //------ store
  always @(*) begin
    byteEnable = 4'b0;
    memoryWriteData = rs2Data;
    if (isMemWrite && is_dmem) begin
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
    if(isMemWrite && is_dmem) begin
      if(byteEnable[0]) memory[dmem_index] [7:0]   <= memoryWriteData[7:0];
      if(byteEnable[1]) memory[dmem_index] [15:8]  <= memoryWriteData[15:8];
      if(byteEnable[2]) memory[dmem_index] [23:16] <= memoryWriteData[23:16];
      if(byteEnable[3]) memory[dmem_index] [31:24] <= memoryWriteData[31:24];
    end
  end
  
  
  // initial begin
  //   $readmemh("data.dat", memory);
  // end
endmodule

