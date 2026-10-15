//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:44:01 PM
// Design Name: 
// Module Name: branchUnit
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


module branchUnit (
  input resultIsZero,
  input isBranch,
  input [31:0] pc,
  input [31:0] imm,
  input [2:0] funct3,
  
  output reg branchTaken,
  output reg [31:0] branchAddress
);
  import pkg::*;
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