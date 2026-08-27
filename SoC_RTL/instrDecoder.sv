// instruction decoder + imm gen
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


  localparam [6:0] LUI = 7'b0110111;
  localparam [6:0] AUIPC = 7'b0010111;
  localparam [6:0] JAL = 7'b1101111;
  localparam [6:0] JALR = 7'b1100111;
  localparam [6:0] BRANCH = 7'b1100011;
  localparam [6:0] LOAD = 7'b0000011;
  localparam [6:0] STORE = 7'b0100011;
  localparam [6:0] ITYPE = 7'b0010011;
  localparam [6:0] RTYPE = 7'b0110011;
  localparam [6:0] FENCE_PAUSE = 7'b0001111;
  localparam [6:0] ECALL_EBREAK = 7'b1110011;

  assign opcode = instruction[6:0];
  
  always @(*) begin
    funct7 = 7'b0;
    funct3 = 3'b0;
    rs1 = 5'b0;
    rs2 = 5'b0;
    rd = 5'b0;
    imm = 20'b0;

    case(opcode)
      LUI, AUIPC: begin
        imm = {instruction[31:12], 12'b0};
        rd = instruction[11:7];
      end
      JAL: begin
        imm = {{11{instruction[31]}},instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        rd = instruction[11:7];
      end
      JALR, LOAD, ITYPE, FENCE_PAUSE, ECALL_EBREAK: begin
        imm = {{20{instruction[31]}}, instruction[31:20]};
        rs1 = instruction[19:15];
        funct3 = instruction[14:12];
        rd = instruction[11:7];
      end
      BRANCH: begin
        imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        rs2 = instruction[24:20];
        rs1 = instruction[19:15];
        funct3 = instruction[14:12];
      end
      STORE: begin
        imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
        funct3 = instruction[14:12];
      end
      RTYPE: begin
        funct7 = instruction[31:25];
        rs2 = instruction[24:20];
        rs1 = instruction[19:15];
        funct3 = instruction[14:12];
        rd = instruction[11:7];
      end
    endcase
  end
endmodule
