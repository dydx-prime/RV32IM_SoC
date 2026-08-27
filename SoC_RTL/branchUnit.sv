module branchUnit (
  input resultIsZero,
  input isBranch,
  input [31:0] pc,
  input [31:0] imm,
  input [2:0] funct3,
  
  output reg branchTaken,
  output reg [31:0] branchAddress
);
  //import pkg::*;
  localparam [2:0] BEQ = 3'b000;
  localparam [2:0] BNE = 3'b001;
  localparam [2:0] BLT = 3'b100;
  localparam [2:0] BGE = 3'b101;
  localparam [2:0] BLTU = 3'b110;
  localparam [2:0] BGEU = 3'b111;

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
