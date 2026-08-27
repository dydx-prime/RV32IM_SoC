module alu(
  input [31:0] srcA,
  input [31:0] srcB,
  input [3:0] sel,
    
  output logic [31:0] aluResult,
  output logic resultIsZero
);

  //import pkg::*;
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
