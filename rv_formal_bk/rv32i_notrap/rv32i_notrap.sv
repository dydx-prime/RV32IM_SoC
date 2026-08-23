// rv32i_formal.sv
//
// Formal version of the RV32I core.
//
// Important formal changes:

//   - Actual register writes are suppressed when an instruction traps.
//   - Actual memory reads/writes are suppressed for misaligned accesses.

//   - RVFI reports the same effective state changes that the core actually
//     performs.
//   - Register-file initialization covers x0..x31.
//
// This file is intended to be used with the existing wrapper/checks.cfg.

package pkg;
  //------ mux sources 
  localparam [2:0] NONE = 3'b000;
  
  // alu srcA
  localparam [2:0] ALU_INPUT_RS1    = 3'b001;
  localparam [2:0] ALU_INPUT_PC     = 3'b010;
  
  // alu srcB
  localparam [2:0] ALU_INPUT_RS2    = 3'b001;
  localparam [2:0] ALU_INPUT_IMM    = 3'b010;
  
  // register file write data
  localparam [2:0] REGFILE_LUI        = 3'b001;
  localparam [2:0] REGFILE_JUMP       = 3'b010;
  localparam [2:0] REGFILE_DATAMEM    = 3'b011;
  localparam [2:0] REGFILE_ALURESULT  = 3'b100;

  //-----------------
  typedef enum logic [6:0] {
    LUI = 7'b0110111,
    AUIPC = 7'b0010111,
    JAL = 7'b1101111,
    JALR = 7'b1100111,
    BRANCH = 7'b1100011,
    LOAD = 7'b0000011,
    STORE = 7'b0100011,
    ITYPE = 7'b0010011,
    RTYPE = 7'b0110011,
    FENCE_PAUSE = 7'b0001111,
    ECALL_EBREAK = 7'b1110011  
  } ISAopcodes_t;

  //----------------- alu sel
   localparam [3:0] ALU_ADD   = 4'b0001;
   localparam [3:0] ALU_SUB   = 4'b0010;
   localparam [3:0] ALU_SLL   = 4'b0011;
   localparam [3:0] ALU_SLT   = 4'b0100;
   localparam [3:0] ALU_SLTU  = 4'b0101;
   localparam [3:0] ALU_XOR   = 4'b0110;
   localparam [3:0] ALU_SRL   = 4'b0111;
   localparam [3:0] ALU_SRA   = 4'b1000;
   localparam [3:0] ALU_OR    = 4'b1001;
   localparam [3:0] ALU_AND   = 4'b1010;
   localparam [3:0] ALU_NOP   = 4'b1111;
   

  //----------------- branches
  localparam [2:0] BEQ = 3'b000;
  localparam [2:0] BNE = 3'b001;
  localparam [2:0] BLT = 3'b100;
  localparam [2:0] BGE = 3'b101;
  localparam [2:0] BLTU = 3'b110;
  localparam [2:0] BGEU = 3'b111;

  //----------------- opcodes
  localparam [6:0] OPCODE_LUI = 7'b0110111;
  localparam [6:0] OPCODE_AUIPC = 7'b0010111;
  localparam [6:0] OPCODE_JAL = 7'b1101111;
  localparam [6:0] OPCODE_JALR = 7'b1100111;
  localparam [6:0] OPCODE_BRANCH = 7'b1100011;
  localparam [6:0] OPCODE_LOAD = 7'b0000011;
  localparam [6:0] OPCODE_STORE = 7'b0100011;
  localparam [6:0] OPCODE_ITYPE = 7'b0010011;
  localparam [6:0] OPCODE_RTYPE = 7'b0110011;
  localparam [6:0] OPCODE_FENCE_PAUSE = 7'b0001111;
  localparam [6:0] OPCODE_ECALL_EBREAK = 7'b1110011;

endpackage

import pkg::*;

//
// PC
//
module pc(
  input clk,
  input reset,
  input [31:0] nextPC,
  output logic [31:0] pc
);

  always_ff @(posedge clk)begin
    if(reset)
      pc <= 32'b0;
    else
      pc <= nextPC;
  end

endmodule


//
// PC + 4
//
module pc4(
  input [31:0] pc,
  output logic [31:0] pcPlus4
);

  assign pcPlus4 = pc + 32'd4;

endmodule



//
// Instruction decoder + immediate generator
//
module instrDecoder(
  input [31:0] instruction,
  
  output logic [6:0] opcode,
  output logic [6:0] funct7,
  output logic [2:0] funct3,
  output logic [4:0] rs1,
  output logic [4:0] rs2,
  output logic [4:0] rd,
  output logic [31:0] imm
);

  assign opcode = instruction[6:0];
  
  always @(*) begin
    funct7 = 7'b0;
    funct3 = 3'b0;
    rs1 = 5'b0;
    rs2 = 5'b0;
    rd = 5'b0;
    imm = 20'b0;

    case(opcode)
      OPCODE_LUI, OPCODE_AUIPC: begin
        imm = {instruction[31:12], 12'b0};
        rd = instruction[11:7];
      end
      OPCODE_JAL: begin
        imm = {{11{instruction[31]}},instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        rd = instruction[11:7];
      end
      OPCODE_JALR, OPCODE_LOAD, OPCODE_ITYPE, OPCODE_FENCE_PAUSE, OPCODE_ECALL_EBREAK: begin
        imm = {{20{instruction[31]}}, instruction[31:20]};
        rs1 = instruction[19:15];
        funct3 = instruction[14:12];
        rd = instruction[11:7];
      end
      OPCODE_BRANCH: begin
        imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        rs2 = instruction[24:20];
        rs1 = instruction[19:15];
        funct3 = instruction[14:12];
      end
      OPCODE_STORE: begin
        imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
        funct3 = instruction[14:12];
      end
      OPCODE_RTYPE: begin
        funct7 = instruction[31:25];
        rs2 = instruction[24:20];
        rs1 = instruction[19:15];
        funct3 = instruction[14:12];
        rd = instruction[11:7];
      end
    endcase
  end
endmodule

// Control unit
//
module controlUnit(
  input [6:0] opcode,
  input [6:0] funct7,
  input [2:0] funct3,
  input [31:0] imm,
 
  output logic isBranch,
  output logic isJump,
  output logic isMemRead,
  output logic isMemWrite,
  output logic isRegfileWrite,
  output logic [2:0] regfileWriteInputSrc,
  output logic [2:0] aluInputSrcA,
  output logic [2:0] aluInputSrcB,
  output logic [3:0] aluSel
);

  // SRAI, SRLI, SLLI
  
  always @(*) begin
    isBranch              = 1'b0;
    isJump                = 1'b0;
    isMemRead             = 1'b0;
    isMemWrite            = 1'b0;
    isRegfileWrite        = 1'b0;
    regfileWriteInputSrc  = NONE;
    aluInputSrcA          = NONE;
    aluInputSrcB          = NONE;

    case(opcode) 
      LUI: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_LUI;
      end
      AUIPC: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_ALURESULT;
        aluInputSrcA = ALU_INPUT_PC;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      JAL: begin 
        isJump = 1'b1;
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_JUMP;
        aluInputSrcA = ALU_INPUT_PC;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      JALR: begin
        isJump = 1'b1;
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_JUMP;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      BRANCH: begin
        isBranch = 1'b1;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_RS2;
      end
      LOAD: begin
        isMemRead = 1'b1;
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_DATAMEM;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
      end
      STORE: begin
        isMemWrite = 1'b1;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
       end
      ITYPE: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_ALURESULT;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_IMM;
        //aluInputSrcB = immLogicalShift ? ALU_INPUT_SHAMT: ALU_INPUT_IMM;
      end
      RTYPE: begin
        isRegfileWrite = 1'b1;
        regfileWriteInputSrc = REGFILE_ALURESULT;
        aluInputSrcA = ALU_INPUT_RS1;
        aluInputSrcB = ALU_INPUT_RS2;
      end
      FENCE_PAUSE, ECALL_EBREAK:/* keep signals at zero */ ;
    endcase 
  end

  always @(*) begin
    aluSel = ALU_NOP;
    case(opcode)
      LUI, AUIPC, JAL, JALR, LOAD, STORE: aluSel = ALU_ADD;
      
      BRANCH: begin
        case(funct3)
          BEQ, BNE: aluSel = ALU_SUB; //BEQ, BNE
          BLT, BGE: aluSel = ALU_SLT; // BLT, BGE
          BLTU, BGEU: aluSel = ALU_SLTU; // BLTU, BGEU
          default: aluSel = ALU_NOP;
        endcase
      end

      ITYPE, RTYPE: begin
        case(funct3)
          3'b000: aluSel = funct7[5] ? ALU_SUB: ALU_ADD;
          3'b001: aluSel = ALU_SLL;
          3'b010: aluSel = ALU_SLT;
          3'b011: aluSel = ALU_SLTU;
          3'b100: aluSel = ALU_XOR;
          3'b101: aluSel = (imm[10] || funct7[5]) ? ALU_SRA : ALU_SRL;
          3'b110: aluSel = ALU_OR;
          3'b111: aluSel = ALU_AND;
          default: aluSel = ALU_NOP;
        endcase
      end
    endcase
  end

endmodule


//
// Generic source mux
//
module srcMux(
  input [2:0] sel,
  input [31:0] data0,
  input [31:0] data1,
  input [31:0] data2,
  input [31:0] data3,

  output reg [31:0] srcData
);
  
  always_comb begin
    srcData = 32'b0;
    case(sel)
      NONE: srcData = 32'b0;
      ALU_INPUT_RS1, ALU_INPUT_RS2, REGFILE_LUI: srcData = data0; 
      ALU_INPUT_PC, ALU_INPUT_IMM, REGFILE_JUMP: srcData = data1;
      REGFILE_DATAMEM: srcData = data2;
      REGFILE_ALURESULT: srcData = data3;
      default: srcData = 32'b0;
    endcase
  end

endmodule


//
// Register file
//
module regfile(
  input clk,
  input [4:0] rs1,
  input [4:0] rs2,
  input [4:0] rd,
  input [31:0] regfileWriteData,
  input isRegfileWrite,

  output logic [31:0] rs1Data,
  output logic [31:0] rs2Data
);

  logic [31:0] register [0:31];


  always_ff @(posedge clk) begin
    if(isRegfileWrite && rd != 5'b0)
      register[rd] <= regfileWriteData;
  end

  assign rs1Data = (rs1 == 5'b0) ? 32'b0 : register[rs1];
  assign rs2Data = (rs2 == 5'b0) ? 32'b0 : register[rs2];

endmodule


//
// ALU
//
module alu(
  input [31:0] srcA,
  input [31:0] srcB,
  input [3:0] sel,
    
  output logic [31:0] aluResult,
  output logic resultIsZero
);

  always_comb begin
    case(sel)
      ALU_ADD: aluResult = srcA + srcB;
      ALU_SUB: aluResult = srcA - srcB;
      ALU_SLL: aluResult = srcA << {27'b0, srcB[4:0]};
      ALU_SLT: aluResult = $signed(srcA) < $signed(srcB);
      ALU_SLTU:aluResult = srcA < srcB;
      ALU_XOR: aluResult = srcA ^ srcB;
      ALU_SRL: aluResult = srcA >> {27'b0, srcB[4:0]};
      ALU_SRA: aluResult = $signed(srcA) >>> {27'b0, srcB[4:0]};
      ALU_OR:  aluResult = srcA | srcB;
      ALU_AND: aluResult = srcA & srcB;
      default: aluResult = 32'b0;
    endcase
  end
  
  assign resultIsZero = (aluResult == 32'b0); 

endmodule




//
// Data memory
//

module dataMemory(
  input clk,
  input isMemRead,
  input isMemWrite,
  input [31:0] address,
  input [31:0] rs2Data,
  input [2:0] funct3,
  output logic [31:0] memoryReadData,
  output logic [31:0] rawWord
);

  logic [31:0] memory [0:4095];
  logic [31:0] word;
  logic [15:0] loadedHalf;
  logic [7:0]  loadedByte;
  logic [3:0]  byteEnable;
  logic [31:0] memoryWriteData;

  assign word = memory[address[31:2]];
  assign rawWord = word;


  // Load path
  always @(*) begin
    memoryReadData = 32'b0;
    loadedByte = 8'b0;
    loadedHalf = 16'b0;
    if (isMemRead) begin
      case (address[1:0])
        2'b00: loadedByte = word[7:0];
        2'b01: loadedByte = word[15:8];
        2'b10: loadedByte = word[23:16];
        2'b11: loadedByte = word[31:24];
      endcase
      case (address[1])
        1'b0: loadedHalf = word[15:0];
        1'b1: loadedHalf = word[31:16];
      endcase
      case (funct3)
        3'b000: memoryReadData = {{24{loadedByte[7]}}, loadedByte};
        3'b001: memoryReadData = {{16{loadedHalf[15]}}, loadedHalf};
        3'b010: memoryReadData = word;
        3'b100: memoryReadData = {24'b0, loadedByte};
        3'b101: memoryReadData = {16'b0, loadedHalf};
      endcase
    end
  end


  // Store path

  always @(*) begin
    byteEnable = 4'b0;
    memoryWriteData = rs2Data;
    if (isMemWrite) begin
      case (funct3)
        3'b000: begin
          byteEnable = 4'b0001 << address[1:0];
          memoryWriteData = {24'b0, rs2Data[7:0]} << (8 * address[1:0]);
        end
        3'b001: begin
          byteEnable = 4'b0011 << address[1:0];
          memoryWriteData = {16'b0, rs2Data[15:0]} << (8 * address[1:0]);
        end
        3'b010: byteEnable = 4'b1111;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (isMemWrite) begin
      if (byteEnable[0]) memory[address[31:2]][7:0] <= memoryWriteData[7:0];
      if (byteEnable[1]) memory[address[31:2]][15:8] <= memoryWriteData[15:8];
      if (byteEnable[2]) memory[address[31:2]][23:16] <= memoryWriteData[23:16];
      if (byteEnable[3]) memory[address[31:2]][31:24] <= memoryWriteData[31:24];
    end
  end
endmodule


//

// Branch unit
//

module branchUnit(
  input resultIsZero,
  input isBranch,
  input [31:0] pc,
  input [31:0] imm,
  input [2:0] funct3,

  output reg branchTaken,
  output reg [31:0] branchAddress
);

  always_comb begin
    branchTaken = 1'b0;
    branchAddress = pc + imm;
    if(isBranch) begin
      case(funct3)
        BEQ, BGE, BGEU: branchTaken = resultIsZero; 
        BNE, BLT, BLTU: branchTaken = ~resultIsZero;
      endcase
    end
  end

endmodule


//
// Formal instruction memory.
//
// Intentionally undriven so the instruction is unconstrained under
// formal verification.
//

module imem_formal(
  input [31:0] pc,
  output logic [31:0] instruction

);

  // Intentionally empty.

endmodule


//
// Formal RV32I core
//


module rv32i_formal(
  input clk,
  input reset,

  output logic [31:0] currAddress,

  // RVFI
  output logic        rvfi_valid,
  output logic [63:0] rvfi_order,
  output logic [31:0] rvfi_insn,
  output logic        rvfi_trap,
  output logic        rvfi_halt,
  output logic        rvfi_intr,
  output logic [1:0]  rvfi_mode,
  output logic [1:0]  rvfi_ixl,
  output logic [4:0]  rvfi_rs1_addr,
  output logic [4:0]  rvfi_rs2_addr,
  output logic [31:0] rvfi_rs1_rdata,
  output logic [31:0] rvfi_rs2_rdata,
  output logic [4:0]  rvfi_rd_addr,
  output logic [31:0] rvfi_rd_wdata,
  output logic [31:0] rvfi_pc_rdata,
  output logic [31:0] rvfi_pc_wdata,
  output logic [31:0] rvfi_mem_addr,
  output logic [3:0]  rvfi_mem_rmask,
  output logic [3:0]  rvfi_mem_wmask,
  output logic [31:0] rvfi_mem_rdata,
  output logic [31:0] rvfi_mem_wdata

);

  logic [31:0] nextPC;
  logic [31:0] nextPC_aligned;
  wire instrMisaligned;
  wire branchTaken;
  wire isJump;
  wire [31:0] aluResult;
  wire [31:0] pc;
  wire [31:0] pcPlus4;
  assign currAddress = pc;

  //
  // Main next-PC logic
  //
  assign nextPC = branchTaken ? branchAddress : isJump ? aluResult : pcPlus4;


  //
  // Instruction-address misalignment
  //
  // This core implements RV32I without compressed instructions, so
  // instructions must be 4-byte aligned.
  //
  assign instrMisaligned = (branchTaken || isJump) && nextPC[1];

  //
  // On an instruction-address-misalignment trap, this simple core
  // holds PC rather than committing the invalid target.
  //
  assign nextPC_aligned = instrMisaligned ? pc : {nextPC[31:1], 1'b0};

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


  //
  // Instruction memory
  //
  wire [31:0] instruction;
  imem_formal instructionMemory(
    .pc(pc),

    .instruction(instruction)
  );

  //
  // Decode
  //
  wire [6:0] opcode;
  wire [6:0] funct7;
  wire [2:0] funct3;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
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

  //
  // Control
  //
  wire isBranch;
  wire isMemRead;
  wire isMemWrite;
  wire isRegfileWrite;
  wire [2:0] regfileWriteInputSrc;
  wire [2:0] aluInputSrcA;
  wire [2:0] aluInputSrcB;
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


  //
  // Register-file write data
  //
  wire [31:0] regfileWriteData;
  wire [31:0] memoryReadData;
  wire [31:0] dmem_rawWord;
  wire [31:0] rs1Data;
  wire [31:0] rs2Data;
  //
  // ALU
  //
  wire [31:0] srcA;
  wire [31:0] srcB;
  wire resultIsZero;

  srcMux aluSrcA(
    .sel(aluInputSrcA),
    .data0(rs1Data),
    .data1(pc),
    .data2(32'b0),
    .data3(32'b0),

    .srcData(srcA)
  );


  srcMux aluSrcB(
    .sel(aluInputSrcB),
    .data0(rs2Data),
    .data1(imm),
    .data2(32'b0),
    .data3(32'b0),

    .srcData(srcB)
  );

  alu arithmetic(
    .srcA(srcA),
    .srcB(srcB),
    .sel(aluSel),

    .aluResult(aluResult),
    .resultIsZero(resultIsZero)
  );

  //
  // Branch logic
  //
  wire [31:0] branchAddress;
  branchUnit branch(
    .resultIsZero(resultIsZero),
    .isBranch(isBranch),
    .pc(pc),
    .imm(imm),
    .funct3(funct3),

    .branchTaken(branchTaken),
    .branchAddress(branchAddress)
  );


  //
  // Data alignment checking
  //
  // With RISCV_FORMAL_ALIGNED_MEM:
  //
  //   byte  = always aligned
  //   half  = address[0] == 0
  //   word  = address[1:0] == 0
  //
  wire memMisaligned;
  assign memMisaligned =
      (isMemRead || isMemWrite) &&
      ((funct3 == 3'b010 && aluResult[1:0] != 2'b00) || 
      ((funct3 == 3'b001 || funct3 == 3'b101) && aluResult[0] != 1'b0));

  //
  // IMPORTANT:
  //
  // These are the enables that the ACTUAL state elements see.
  //
  // Previously RVFI would report that a trapped instruction did not
  // write a register, while the actual register file could still write
  // the register. That creates exactly the kind of architectural
  // mismatch that reg_ch0 detects.
  //
  wire trap_instruction;
  assign trap_instruction = instrMisaligned || memMisaligned;
  wire effectiveRegfileWrite;
  wire effectiveMemRead;
  wire effectiveMemWrite;
  assign effectiveRegfileWrite = isRegfileWrite && !trap_instruction;
  assign effectiveMemRead = isMemRead && !trap_instruction;
  assign effectiveMemWrite = isMemWrite && !trap_instruction;

  //
  // Register file
  //
  regfile registerFile(
    .clk(clk),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),


    .regfileWriteData(regfileWriteData),
    // IMPORTANT: use the effective enable.
    .isRegfileWrite(effectiveRegfileWrite),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data)
  );

  //
  // Register-file write-data mux
  //
  // This remains based on the normal datapath. The actual write is
  // prevented by effectiveRegfileWrite when the instruction traps.
  //
  srcMux regfileSrc(
    .sel(regfileWriteInputSrc),
    .data0(imm),
    .data1(pcPlus4),
    .data2(memoryReadData),
    .data3(aluResult),
    .srcData(regfileWriteData)
  );

  //
  // Data memory
  //
  // IMPORTANT: use effective enables so a misaligned load/store does
  // not modify architectural state.
  //
  dataMemory dmem(
    .clk(clk),
    .isMemRead(effectiveMemRead),
    .isMemWrite(effectiveMemWrite),
    .address(aluResult),
    .rs2Data(rs2Data),
    .funct3(funct3),

    .memoryReadData(memoryReadData),
    .rawWord(dmem_rawWord)
  );

  //
  // RVFI
  //
  function automatic [3:0] rvfi_mask(
    input [2:0] funct3_in,
    input [1:0] addr_lo
  );

    case (funct3_in)
      3'b000: rvfi_mask = 4'b0001 << addr_lo; // LB/SB
      3'b001: rvfi_mask = 4'b0011 << addr_lo; // LH/SH
      3'b010: rvfi_mask = 4'b1111;            // LW/SW
      3'b100: rvfi_mask = 4'b0001 << addr_lo; // LBU
      3'b101: rvfi_mask = 4'b0011 << addr_lo; // LHU
      default:
        rvfi_mask = 4'b0000;
    endcase
  endfunction

  //
  // RVFI valid/order
  //
  always @(posedge clk) begin
    if (reset) begin
      rvfi_valid <= 1'b0;
      rvfi_order <= 64'b0;
    end
    else begin
      rvfi_valid <= 1'b1;
      rvfi_order <= rvfi_order + rvfi_valid;
    end
  end
  wire [1:0] mem_addr_lo = aluResult[1:0];

  //
  // Combinational RVFI packet
  //
  always @(*) begin
    rvfi_insn = instruction;
    rvfi_pc_rdata = pc;
    rvfi_pc_wdata = nextPC_aligned;

    //
    // Source registers
    //
    rvfi_rs1_addr = rs1;
    rvfi_rs2_addr = rs2;
    rvfi_rs1_rdata = (rs1 == 5'b0) ? 32'b0 : rs1Data;
    rvfi_rs2_rdata = (rs2 == 5'b0) ? 32'b0 : rs2Data;

    //
    // Destination register
    //
    // Match the actual effective register-file write enable.
    //
    if (effectiveRegfileWrite && rd != 5'b0) begin
      rvfi_rd_addr  = rd;
      rvfi_rd_wdata = regfileWriteData;
    end
    else begin
      rvfi_rd_addr  = 5'b0;
      rvfi_rd_wdata = 32'b0;
    end

    //
    // Memory address
    //
    // Under RISCV_FORMAL_ALIGNED_MEM this is the aligned word address.
    //
    if (effectiveMemRead || effectiveMemWrite) begin
      rvfi_mem_addr = {aluResult[31:2], 2'b00};
    end
    else begin
      rvfi_mem_addr = 32'b0;
    end

    //
    // Memory masks
    //
    if (effectiveMemRead)
      rvfi_mem_rmask = rvfi_mask(funct3, mem_addr_lo);
    else
      rvfi_mem_rmask = 4'b0;
    if (effectiveMemWrite)
      rvfi_mem_wmask = rvfi_mask(funct3, mem_addr_lo);
    else
      rvfi_mem_wmask = 4'b0;


    //
    // Raw memory read data.
    //
    // This is deliberately dmem_rawWord rather than memoryReadData.
    //
    rvfi_mem_rdata = dmem_rawWord;

    //
    // Store data.
    //
    case (funct3)
      3'b000: rvfi_mem_wdata = {24'b0, rs2Data[7:0]} << (8 * mem_addr_lo);
      3'b001: rvfi_mem_wdata = {16'b0, rs2Data[15:0]} << (8 * mem_addr_lo);
      3'b010: rvfi_mem_wdata = rs2Data;
      default:
        rvfi_mem_wdata = 32'b0;
    endcase

    //
    // Trap information
    //
    rvfi_trap = trap_instruction;
    rvfi_halt = 1'b0;
    rvfi_intr = 1'b0;
    rvfi_mode = 2'b11; // M-mode
    rvfi_ixl  = 2'b01; // RV32
  end

endmodule

