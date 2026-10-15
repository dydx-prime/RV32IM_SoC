//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:46:42 PM
// Design Name: 
// Module Name: regfile
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
