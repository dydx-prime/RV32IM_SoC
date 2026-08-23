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
