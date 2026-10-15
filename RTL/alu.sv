module alu(
  input [31:0] srcA,
  input [31:0] srcB,
  input [3:0] sel,
    
  output logic [31:0] aluResult,
  output logic resultIsZero
);

  import pkg::*;

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
