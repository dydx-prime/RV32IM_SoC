//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:46:42 PM
// Design Name: 
// Module Name: instrDecoder
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

  import pkg::*;

  assign opcode = instruction[6:0];
  
  always @(*) begin
    funct7 = 7'b0;
    funct3 = 3'b0;
    rs1 = 5'b0;
    rs2 = 5'b0;
    rd = 5'b0;
    imm = 32'b0;

    case(opcode)
      LUI, AUIPC, SYSTEM: begin // system refers to ZICSR
        imm = {instruction[31:12], 12'b0};
        rd = instruction[11:7];
        rs1 = (opcode == SYSTEM && funct3[2]) ? 5'b0: instruction[19:15];
      end
      JAL: begin
        imm = {{11{instruction[31]}},instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        rd = instruction[11:7];
      end
      JALR, LOAD, ITYPE, FENCE_PAUSE, SYSTEM: begin // system refers to ECALL_EBREAK
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
